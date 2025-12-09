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
import AstBased::Location;
import AstBased::Normalise;

// Arbitrary number
int MASSTHRESHOLD = 50;
int MIN_WINDOW_SIZE = 2;

// Detects Type I clones
CloneMap detectClonesI(list[node] asts){
    return findClones(asts);
}


// Detects Type II clones
CloneMap detectClonesII(list[node] asts) {
    return findClones(normaliseAst(asts));
}


// Detects Type III clones
CloneMap detectClonesIII(list[node] asts){
    // TODO: implement
    return ();
}


/**
 * Detects duplicated code fragments across the given ASTs by performing basic
 * and sequence-based clone detection then cleaning intermediate results, and
 * returning the final CloneMap containing all discovered clone groups.
 */
CloneMap findClones(list[node] asts) {
    CloneMap groups = ();
    map[node, int] sizeMap = constructSizeMap(asts);

    // BASIC CLONE SEARCH
    <groups, maxWindowSize> = findClonesBasic(groups, sizeMap, asts);
    <groups, _> = cleanGroups(groups, 1);
    int basicCloneBlocks = size(groups);

    // SEQUENCE CLONE SEARCH
    for (int windowSize <- [MIN_WINDOW_SIZE..maxWindowSize]) {
        int earlyExitOldClones = size(groups);

        groups = findClonesSequence(groups, sizeMap, asts, windowSize);
        <groups, earlyExitNewClones> = cleanGroups(groups, windowSize);

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
    // set[Location] lines = findAffectedLines(groups);
    // println("Amount of duplicate lines: <size(lines)>");
    printCloneLocs(groups);

    return groups;
}


/**
 * Adds heavy enough AST nodes to clone map
 * return: <CloneMap, MaxSequenceSize>
 *         returns updated cloneMap (groups) and max list size
 */
tuple[CloneMap, int] findClonesBasic(CloneMap groups, SizeMap sizeMap, list[node] asts) {
    int biggestList = 0;

    visit (asts) {
        case node n: {
            // Filters based on subtree mass
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

/**
 * Finds clones in sequences of given length
 * Adds windows above threshold to clone map
 * return: updated CloneMap
 */
CloneMap findClonesSequence(CloneMap groups, SizeMap sizeMap, list[node] asts, int sequenceLength) {
    visit (asts) {
        // case list[node] statements: {
        case \block(list[Statement] statements):{
        // an alternative to previous approach, but removes some valid clones ...
            for (node window <- generateSlidingWindows(statements, sequenceLength)) {
                // println(generateSlidingWindows(statements, sequenceLength));
                // throw "Deliberate exit";
                if (slidingWindowMass(sizeMap, window) >= MASSTHRESHOLD) {
                    groups = addNodeToCloneMap(groups, window);
                }
            }
        }
        case \switch(_, list[Statement] statements):{
        // COPY PASTED FROM BLOCK ABOVE
            for (node window <- generateSlidingWindows(statements, sequenceLength)) {
                if (slidingWindowMass(sizeMap, window) >= MASSTHRESHOLD) {
                    groups = addNodeToCloneMap(groups, window);
                }
            }
        }
    }

    return groups;
}

// /**
//  * Finds all lines that belong to clone class
//  */
// set[Location] findAffectedLines(CloneMap groups) {
//     return { line | group <- groups, clone <- groups[group],
//                      line <- getStartingLine(clone) };
// }


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