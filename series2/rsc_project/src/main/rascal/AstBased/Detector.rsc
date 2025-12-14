module AstBased::Detector

import Aliases;
import Configuration;
import IO;
import List;
import Location;
import Map;
import Node;
import Set;
import String;
import lang::java::m3::AST;
import lang::java::m3::Core;

import AstBased::AstTools;
import AstBased::CloneMapHelpers;
import AstBased::CsvWriter;
import AstBased::Location;
import AstBased::Normalise;
import AstBased::PermutationSubsumtion;

// Detects Type I clones
CloneMap detectClonesI(list[node] asts, int massThreshold, int minWindow){
    return findClones(asts, massThreshold, minWindow, generateSlidingWindows);
}


// Detects Type II clones
CloneMap detectClonesII(list[node] asts, int massThreshold, int minWindow) {
    return findClones(normaliseAst(asts), massThreshold, minWindow, generateSlidingWindows);
}


// Detects Type III clones
CloneMap detectClonesIII(list[node] asts, int massThreshold, int minWindow) {
    return findClones(normaliseAst(asts), massThreshold, minWindow, generateSlidingWindowsWithPerm);
}


/**
 * Detects duplicated code fragments across the given ASTs by performing basic
 * and sequence-based clone detection then cleaning intermediate results, and
 * returning the final CloneMap containing all discovered clone groups.
 */
CloneMap findClones(list[node] asts, int massThreshold, int minWindow, list[node](list[node], int) sequenceGenerator) {
    CloneMap groups = ();
    map[node, int] sizeMap = constructSizeMap(asts);

    // BASIC CLONE SEARCH
    <groups, maxWindowSize> = findClonesBasic(groups, sizeMap, asts, massThreshold);
    <groups, _> = cleanGroups(groups, 1, sequenceGenerator);
    int basicCloneBlocks = size(groups);

    // SEQUENCE CLONE SEARCH
    for (int windowSize <- [minWindow..maxWindowSize]) {
        int earlyExitOldClones = size(groups);

        groups = findClonesSequence(groups, sizeMap, asts, windowSize, sequenceGenerator, massThreshold);
        <groups, earlyExitNewClones> = cleanGroups(groups, windowSize, sequenceGenerator);

        if (earlyExitOldClones == earlyExitNewClones
                && windowSize >= confMinimumSequenceLengthIterationsBeforeStop()) {
            println("Terminating early; no new clones have been found and no existing groups were extended");
            break;
        }
    }
    int totalCloneBlocks = size(groups);

    // RESULTS
    println("--- Duplicate blocks found after basic: <basicCloneBlocks> ---");
    println("--- Duplicate blocks found after sequence + basic: <totalCloneBlocks> ---");
    printCloneLocs(groups);

    return groups;
}


/**
 * Adds heavy enough AST nodes to clone map
 * return: <CloneMap, MaxSequenceSize>
 *         returns updated cloneMap (groups) and max list size
 */
tuple[CloneMap, int] findClonesBasic(CloneMap groups, SizeMap sizeMap, list[node] asts, int massThreshold) {
    int biggestList = 0;

    visit (asts) {
        case node n: {
            // Filters based on subtree mass
            if ((n has src) && (sizeMap[n] >= massThreshold)){
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

/**
 * Finds clones in sequences of given length
 * Adds windows above threshold to clone map
 * return: updated CloneMap
 */
CloneMap findClonesSequence(CloneMap groups, SizeMap sizeMap, list[node] asts, int sequenceLength,
                             list[node](list[node], int) sequenceGenerator, int massThreshold) {

    visit (asts) {
        case list[Statement] statements: {
            for (node window <- sequenceGenerator(statements, sequenceLength)) {
                if (slidingWindowMass(sizeMap, window) >= massThreshold) {
                    groups = addNodeToCloneMap(groups, window);
                }
            }
        }
    }

    return groups;
}


// Only for quick testing purposes
set[value] printCloneLocs(CloneMap m) {
    set[value] locations = {};
    int i = 0;
    for (class <- m) {
        println("\nCLASS <i>:");
        for (location <- m[class]) {
            // TODO: this is hardcoded, find a way to deal with it
            if (!(contains("<location>", "Language"))){
                println("\t<location>");
                locations += location;
            }
        }
        i += 1;
    }
    return locations;
}

// For debugging:
// clonemap_list = findClones(asts);
// clonemap_stmt_switch = findClones(asts); // AFTER ALGORITHM CHANGES
// showDifference(clonemap_stmt_switch, clonemap_list);
void showDifference(CloneMap m1, CloneMap m2){
    set[value] set1 = printCloneLocs(m1);
    set[value] set2 = printCloneLocs(m2);
    set[value] difference = set1 - set2;
    for (value location <- difference){
        println("\t<location>");
    }
}