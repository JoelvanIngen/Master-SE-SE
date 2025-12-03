module CloneDetection::AstBased

import Aliases;
import AstTools;
import IO;
import List;
import Location;
import Map;
import Node;
import Set;
import String;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::Progress;

// Arbitrary number
int MASSTHRESHOLD = 50;

int MIN_WINDOW_SIZE = 2;

// Storing clone groups
alias CloneMap = map[node, list[node]];

/**
 * Removes a child clone class from the bucket if it's actually a child of the parent,
 * but keeps it in case one of the targeted code segments is not extended, to prevent
 * loss of partial clones
 */
set[node] removeIfTrueParentClass(CloneMap bucket, node cleanNode, node n){
    set[node] nodesToRemove = {};
    return n in bucket && size(bucket[cleanNode]) == size(bucket[n]) ? {n} : nodesToRemove;
}

// Removes all subclone buckets by checking all children
CloneMap removeSubClones(CloneMap bucket, int currWindowSize){
    set[node] nodesToRemove = {};
    for (cleanNode <- bucket){
        visit (getChildren(cleanNode)) {
            case node n: {
                nodesToRemove += removeIfTrueParentClass(bucket, cleanNode, n);
            }
            case list[node] nodes: {
                windowsToRemove = generateSlidingWindows(nodes, currWindowSize - 1);
                for (n <- windowsToRemove) {
                    nodesToRemove += removeIfTrueParentClass(bucket, cleanNode, n);
                }
            }
        }
    }
    bucket = (n: bucket[n] | n <- bucket, n notin nodesToRemove);
    return bucket;
}

tuple[CloneMap, int] findClonesBasic(CloneMap groups, SizeMap sizeMap, list[node] asts) {
    int biggestList = 0;

    visit (asts) {
        case node n: {
            // Filtering based on subtree mass (Ira Baxter paper)
            if ((n has src) && (sizeMap[n] >= MASSTHRESHOLD)){
                groups = hashAddNode(groups, n);
            }
        }
        case list[node] ns: {
            int s = size(ns);
            if (s > biggestList) biggestList = s;
        }
    }

    return <groups, biggestList>;
}

CloneMap findClonesSequence(CloneMap groups, SizeMap sizeMap, list[node] asts, int sequenceLength) {
    visit (asts) {
        case list[node] nodes: {
            for (node window <- generateSlidingWindows(nodes, sequenceLength)) {
                if (slidingWindowMass(sizeMap, window) >= MASSTHRESHOLD) {
                    groups = hashAddNode(groups, window);
                }
            }
        }
    }

    return groups;
}

/**
 * Cleans the created groups by filtering non-clone groups and removing subclones
 * Returns the cleaned groups, and the amount of groups after non-clone group
 * filtering, allowing for early exit if no new detections will take place
 */
tuple[CloneMap, int] cleanGroups(CloneMap groups, int currWindowSize) {
    println("\nENTERING CLEANING: WINDOW SIZE <currWindowSize> | CLONE GROUPS: <size(groups)>");
    groups = filterRealCloneGroups(groups);
    int earlyExitCloneNumber = size(groups);
    println("AFTER \"REAL CLONES\" FILTER | CLONE GROUPS: <size(groups)>");
    groups = removeSubClones(groups, currWindowSize);
    println("AFTER REMOVING SUBCLONES | CLONE GROUPS: <size(groups)>");

    return <groups, earlyExitCloneNumber>;
}

// Collects all fragments and groups them
CloneMap findClones(list[node] asts) {
    CloneMap groups = ();
    map[node, int] sizeMap = constructSizeMap(asts);

    <groups, maxWindowSize> = findClonesBasic(groups, sizeMap, asts);
    <groups, _> = cleanGroups(groups, 1);
    println("Duplicate blocks found after basic: <size(groups)>");

    println("MAXWINDOWSIZE <maxWindowSize>");
    for (int windowSize <- [2..maxWindowSize]) {
        int earlyExitOldClones = size(groups);

        groups = findClonesSequence(groups, sizeMap, asts, windowSize);

        <groups, earlyExitNewClones> = cleanGroups(groups, windowSize);

        if (earlyExitOldClones == earlyExitNewClones) {
            println("Terminating early; no new clones have been found and no existing groups were extended");
            break;
        }
    }

    set[Location] lines = findAffectedLines(groups);
    println("Amount of duplicate lines: <size(lines)>");

    return groups;
}

int slidingWindowMass(SizeMap masses, node window) {
    int mass = 0;

    switch (getChildren(window)[0]) {
        case list[node] children: {
            mass = sum([masses[child] | node child <- children]);
        }
    }

    return mass;
}

/**
 * Generates all possible slices over a list of nodes with given length.
 * Creates a new 'ghost' parent node containing only the slice as children
 * @param nodes: list of all nodes to slice over
 * @param length: length of slices to create
 * @return: list of newly created 'ghost' parent nodes
 */
list[node] generateSlidingWindows(list[node] nodes, int length) =
    (size(nodes) <= length || length <= 1) ? [] : (
        []
        | it + "slice"(nodes[startIdx..startIdx+length])
        | startIdx <- [0..size(nodes)-length+1]
    );

CloneMap hashAddNode(CloneMap m, node origNode) {
    // Remove location data (and hopefully not anything important)
    node cleanNode = unsetRec(origNode);
    m[cleanNode] = (m[cleanNode] ? []) + [origNode];

    return m;
}

/**
 * Constructs a new clonegroup map, only keeping groups with more than 1
 * member, as a one-membered group will only contain an original.
 */
CloneMap filterRealCloneGroups(CloneMap gs) {
    return (g: (gs[g]) | g <- gs, size(gs[g]) > 1);
}

/**
 * Finds all lines that belong to clone class
 */
set[Location] findAffectedLines(CloneMap groups) {
    return { line | group <- groups, clone <- groups[group],
                     line <- getStartingLines(clone) };
}


// Only for quick testing purposes
void printCloneLocs(CloneMap m) {
    int i = 0;
    for (class <- m) {
        println("\nCLASS <i>:");
        for (clone <- m[class]) {
            value location = getSrc(clone);
            if (!(contains("<location>", "Language"))) println("\t<location>");
        }
        i += 1;
    }
}


// Only for quick testing purposes
loc getSrc(node n) {
    if (n has src) {
        return castLoc(n);
    }

    switch (getChildren(n)[0]) {
        case list[node] ns: {
            f = getSrc(ns[0]);
            l = getSrc(ns[-1]);

            // TEMPORARY FIX FOR DIFFERENT FILES
            if (!isSameFile(f, l)) return f;

            return cover([f, l]);
        }
    }

    throw "what";
}


// Ugly function should be rewritten
CloneMap removeOverlap(CloneMap m) {
    // Remove overlapping
    <pbarUpdate, pbarTerminate> = progressBar(size(m), prefix="Class:");

    int i = 0;
    for (class <- m) {
        i += 1;
        clones = m[class];
        pbarUpdate("Class <i>/<size(m)> | Amount of clones in class: <size(clones)    >");
        set[int] idxsToDelete = {};
        for (testCloneIdx <- [1 .. size(clones)]) {
            testClone = clones[testCloneIdx];
            for (compareCloneIdx <- [0 .. testCloneIdx]) {
                compareClone = clones[compareCloneIdx];

                if (isOverlapping(getSrc(testClone), getSrc(compareClone))) {
                    idxsToDelete += {testCloneIdx};
                    break;
                }
            }
        }
        
        list[node] newClones = [];
        for (<i, clone> <- zip2([0..size(clones)], clones)) {
            if (i notin idxsToDelete) newClones += [clone];
        }

        m[class] = newClones;
    }

    // Drop clones that were only overlapping parts
    // filter function ??
    for (class <- m) {
        if (size(m[class]) == 1) delete(m, class);
    }

    return m;
}
