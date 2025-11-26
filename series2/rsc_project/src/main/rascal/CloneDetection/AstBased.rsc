module CloneDetection::AstBased

import Aliases;
import AstTools;
import IO;
import List;
import Map;
import Node;
import Set;
import lang::java::m3::AST;
import lang::java::m3::Core;

// Arbitrary number
int MASSTHRESHOLD = 50;

int MIN_WINDOW_SIZE = 2;

// Storing clone groups
alias CloneMap = map[node, list[node]];

// Removes all subclone buckets by checking all children
CloneMap removeSubClones(CloneMap bucket, int currWindowSize){
    for (cleanNode <- bucket){
        visit (getChildren(cleanNode)) {
            case node n: {
                if (n in bucket) bucket = delete(bucket, n);
            }
            case list[node] nodes: {
                windowsToRemove = generateSlidingWindows(nodes, currWindowSize - 1);
                for (n <- windowsToRemove) {
                    if (n in bucket) bucket = delete(bucket, n);
                }
            }
        }
    }
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

CloneMap cleanGroups(CloneMap groups, int currWindowSize) {
    println("\nENTERING CLEANING: WINDOW SIZE <currWindowSize> | CLONE GROUPS: <size(groups)>");
    groups = filterRealCloneGroups(groups);
    println("AFTER \"REAL CLONES\" FILTER | CLONE GROUPS: <size(groups)>");
    groups = removeSubClones(groups, currWindowSize);
    println("AFTER REMOVING SUBCLONES | CLONE GROUPS: <size(groups)>");

    return groups;
}

// Collects all fragments and groups them
CloneMap findClones(list[node] asts) {
    CloneMap groups = ();
    map[node, int] sizeMap = constructSizeMap(asts);

    <groups, maxWindowSize> = findClonesBasic(groups, sizeMap, asts);
    groups = cleanGroups(groups, 1);
    println("Duplicate blocks found after basic: <size(groups)>");

    println("MAXWINDOWSIZE <maxWindowSize>");
    for (int windowSize <- [2..maxWindowSize]) {
        groups = findClonesSequence(groups, sizeMap, asts, windowSize);

        groups = cleanGroups(groups, windowSize);

        println("Duplicate blocks found after window size <windowSize>: <size(groups)>");
        // for (bucket <- groups){
        //     cloneNodes = groups[bucket];
        //     cloneNodesLoc = [n.src | n <- cloneNodes];
        //     println(cloneNodesLoc);
        // }
    }

    // I think this is not doing what we think it is right?
    set[Location] lines = findAffectedLines(groups);
    println("Amount of duplicate lines: <size(lines)>");

    // println(toList(lines)[0..10]);
    // println(toList(groups)[0]);

    // return groups;
    return ();
}

int slidingWindowMass(SizeMap masses, node window) {
    int mass = 0;

    switch (getChildren(window)[0]) {
        case list[node] children: {
            for (child <- children) {
                mass += masses[child];
            }
        }
    }
    
    return mass;
}

/**
 * Generates all sliding windows over a list of nodes
 * @param nodes: list of all nodes to slide lists over
 * @return: newly created 'ghost' parent nodes that include nothing except
 *          all nodes in the sliding window
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
    CloneMap filteredGs = ();

    for (g <- gs) {
        targets = gs[g];
        if (size(targets) >= 2) {
            filteredGs[g] = targets;
        }
    }

    return filteredGs;
}

/**
 * Finds all lines that belong to clones (not originals)
 */
set[Location] findAffectedLines(CloneMap gs) {
    set[Location] affectedLines = {};

    for (g <- gs) {
        // Skip original
        for (clone <- gs[g][1..]) {
            affectedLines += getStartingLines(clone);
        }
    }

    return affectedLines;
}
