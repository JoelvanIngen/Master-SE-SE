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
int MASSTHRESHOLD = 100;

int MIN_WINDOW_SIZE = 2;

// Storing clone groups
// alias CloneMap = map[node, list[loc]];
alias CloneMap = map[node, list[node]];

// Collects all fragments and groups them
CloneMap findClones(list[node] asts) {
    CloneMap groups = ();
    map[node, int] sizeMap = constructSizeMap(asts);

    visit (asts) {
        case node n: {
            // Filtering based on subtree mass (Ira Baxter paper)
            if (sizeMap[n] >= MASSTHRESHOLD){
                groups = hashAddNode(groups, n);
            }
        }
        case list[node] nodes: {
            if (size(nodes) == 0) fail;

            for (node window <- generateSlidingWindows(nodes)) {
                if (slidingWindowSize(sizeMap, window) >= MASSTHRESHOLD) {
                    node n = unsetRec(window);
                    groups[n] ? [] += [n];
                }
            }
        }
    }

    groups = filterRealCloneGroups(groups);
    println("Duplicate blocks found: <size(groups)>");
    // groups = filterStartingLinesMoreThanSix(groups);
    // I think this is not doing what we think it is right?
    set[Location] lines = findAffectedLines(groups);
    println("Amount of duplicate lines: <size(lines)>");

    // println(toList(lines)[0..10]);
    // println(toList(groups)[0]);

    // return groups;
    return ();
}

int slidingWindowSize(SizeMap masses, node window) {
    int mass = 0;

    switch (getChildren(window)[0]) {
        case list[node] children: {
            for (child <- children) {
                mass += masses[child];
            }
        }
        default: {
            println("wtf");
            fail;
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
list[node] generateSlidingWindows(list[node] nodes) {
    list[node] acc = [];

    int maxWindowSize = MIN_WINDOW_SIZE + 4;

    if (maxWindowSize < MIN_WINDOW_SIZE) return acc;

    for (windowSize <- [MIN_WINDOW_SIZE..maxWindowSize]) {
        for (startIdx <- [0..maxWindowSize-windowSize+1]) {
            acc += "slice"([*nodes[startIdx..startIdx+windowSize]]);

            // // DEBUGGING
            // println("\n--- SLICE START ---");
            // for (n <- nodes[startIdx..startIdx+windowSize]) {
            //     switch (n.src) {
            //         case loc src: {
            //             println("src"(<src.begin.line, src.begin.column>, <src.end.line, src.end.column>));
            //         }
            //     }
            // }
            // // /DEBUGGING
        }
    }

    // println("\n\n\n\n\n");

    return acc;
}

CloneMap hashAddNode(CloneMap m, node origNode) {
    // Only process nodes with src data
    if (!origNode.src?) return m;

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
 * Constructs a new CloneMap, keeping only clones that affect 6 or more lines
 */
CloneMap filterStartingLinesMoreThanSix(CloneMap gs) {
    CloneMap filteredGs = ();

    for (g <- gs) {
        // Only take first clone segment, they'll all be comparable anyways
        startingLines = getStartingLines(gs[g]);
        if (size(startingLines) >= 6) {
            filteredGs[g] = gs[g];
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
