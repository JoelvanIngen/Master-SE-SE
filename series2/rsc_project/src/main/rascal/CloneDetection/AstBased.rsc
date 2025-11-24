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

// Storing clone groups
// alias CloneMap = map[node, list[loc]];
alias CloneMap = map[node, list[node]];

// Collects all fragments and groups them
CloneMap findClones(list[node] asts) {
    CloneMap groups = ();

    visit (asts) {
        case node n: {
            groups = hashAddNode(groups, n);
        }
    }

    groups = filterRealCloneGroups(groups);
    groups = filterStartingLinesMoreThanSix(groups);
    set[Location] lines = findAffectedLines(groups);
    println(toList(groups)[0]);

    println("Amount of duplicate lines: <size(lines)>");

    println(toList(lines)[0..10]);

    // return groups;
    return ();
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
