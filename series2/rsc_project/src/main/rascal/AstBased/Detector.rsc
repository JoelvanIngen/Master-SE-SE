module AstBased::Detector

import Aliases;
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

import AstBased::AstTools;
import AstBased::CloneMapHelpers;
import AstBased::Location;

// Arbitrary number
int MASSTHRESHOLD = 50;

int MIN_WINDOW_SIZE = 2;

/**
 * Removes a child clone class from the bucket if it's actually a child of the parent,
 * but keeps it in case one of the targeted code segments is not extended, to prevent
 * loss of partial clones
 */
set[node] removeIfTrueParentClass(CloneMap bucket, node cleanNode, node n){
    set[node] nodesToRemove = {};
    return n in bucket && size(bucket[cleanNode]) == size(bucket[n]) ? {n} : nodesToRemove;
}

tuple[CloneMap, int] findClonesBasic(CloneMap groups, SizeMap sizeMap, list[node] asts) {
    int biggestList = 0;

    visit (asts) {
        case node n: {
            // Filtering based on subtree mass (Ira Baxter paper)
            if ((n has src) && (sizeMap[n] >= MASSTHRESHOLD)){
                groups = addNodeToCloneMap(groups, n);
            }
        }
        // Used to determine max window size (used later for sequences)
        case list[node] ns: {
            int s = size(ns);
            if (s > biggestList) biggestList = s;
        }
    }

    return <groups, biggestList>;
}

CloneMap findClonesSequence(CloneMap groups, SizeMap sizeMap, list[node] asts, int sequenceLength) {
    visit (asts) {
        case list[node] statements: {
        // case \block(list[Statement] statements):{
        // an alternative to previous approach, but removes some valid clones ...
            for (node window <- generateSlidingWindows(statements, sequenceLength)) {
                if (slidingWindowMass(sizeMap, window) >= MASSTHRESHOLD) {
                    groups = addNodeToCloneMap(groups, window);
                }
            }
        }
    }

    return groups;
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

    printCloneLocs(groups);

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