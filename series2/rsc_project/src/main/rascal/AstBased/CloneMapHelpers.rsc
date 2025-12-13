module AstBased::CloneMapHelpers

import Aliases;
import Configuration;
import IO;
import Location;
import List;
import Map;
import Node;
import lang::java::m3::AST;
import lang::java::m3::Core;

import AstBased::Location;
import AstBased::PermutationSubsumtion;
import AstBased::SequenceHelpers;

CloneMap addNodeToCloneMap(CloneMap groups, node origNode) {
    // Remove location data (and hopefully not anything important)
    node cleanNode = unsetRec(origNode);
    loc origSrc = getSrc(origNode);

    if (cleanNode notin groups) {
        groups[cleanNode] = [origSrc];
        return groups;
    }

    // Add node to class iff it doesn't overlap with an existing clone in that class
    otherCloneCandidates = groups[cleanNode];
    for (candSrc <- otherCloneCandidates) {
        if (isOverlapping(candSrc, origSrc)) {
            return groups;
        }
    }
    groups[cleanNode] += [origSrc];

    return groups;
}

/**
 * Cleans the created groups by filtering non-clone groups and removing subclones
 * Returns the cleaned groups, and the amount of groups after non-clone group
 * filtering, allowing for early exit if no new detections will take place
 */
tuple[CloneMap, int] cleanGroups(CloneMap groups, int currWindowSize,
                                 list[node](list[node], int) sequenceGenerator) {

    println("\nENTERING CLEANING: WINDOW SIZE <currWindowSize> | CLONE GROUPS: <size(groups)>");
    groups = filterRealCloneGroups(groups, currWindowSize);
    int earlyExitCloneNumber = size(groups);
    println("AFTER \"REAL CLONES\" FILTER | CLONE GROUPS: <size(groups)>");
    groups = removeSubClones(groups, currWindowSize, sequenceGenerator);
    println("AFTER REMOVING SUBCLONES | CLONE GROUPS: <size(groups)>");
    groups = removeOverlaps(groups);
    println("AFTER REMOVING OVERLAP | CLONE GROUPS: <size(groups)>");

    return <groups, earlyExitCloneNumber>;
}

/**
 * Constructs a new clonegroup map, only keeping groups with more than 1
 * member, as a one-membered group will only contain an original.
 */
CloneMap filterRealCloneGroups(CloneMap gs, int currWindowSize) {
    return (g: (gs[g]) | g <- gs, size(gs[g]) > 1 || sequenceLength(g) == currWindowSize);
}

/**
 * Determines the length of the sequence of any custom-generated nodes.
 * Returns 1 for any default AST nodes
 */
int sequenceLength(node n) {
    if (isSequenceNode(n)) {
        // Case for custom node
        if (list[node] ns := getChildren(n)[0]) return size(ns);
        throw "Error: Custom sequence parent node <n> did not seem to contain list[node] as type of first child";
    }

    // Case for any AST node
    return 1;
}

// Removes all subclone groups by checking all children
CloneMap removeSubClones(CloneMap groups, int currWindowSize,
                         list[node](list[node], int) sequenceGenerator){

    set[node] groupsToRemove = {};
    for (parent <- groups){
        visit (getChildren(parent)) {
            case node child: {
                groupsToRemove += removeIfSubsumed(groups, parent, child);
            }
            case list[Statement] statements: {
                windowsToRemove = sequenceGenerator(statements, currWindowSize - 1);
                for (child <- windowsToRemove) {
                    groupsToRemove += removeIfSubsumed(groups, parent, child);
                }
            }
        }
    }
    groups = (n: groups[n] | n <- groups, n notin groupsToRemove);
    return groups;
}

// WIP, experimenting (if I decide to keep it -> remove removeIfTrueParentClass)
set[node] removeIfSubsumed(CloneMap groups, node potentialParent, node potentialChild) {
    return classIsSubsumed(groups, potentialParent, potentialChild) ? {potentialChild} : {};
}


// WIP, working on integrating it & improving
bool classIsSubsumed(CloneMap groups, node parent, node child) {

    // Check if both in groups
    if (child notin groups || parent notin groups) return false;

    // Check if groups have equal size
    list[loc] parentLocs = groups[parent];
    list[loc] childLocs  = groups[child];
    if (size(parentLocs) != size(childLocs)) return false;

    // for every child location, there must be a strictly containing parent location
    // Potential improvement: sort both lists and then search linearly until either both lists reach end or either comparison fails?
    for (loc c <- childLocs) {
        bool covered = false;
        for (loc p <- parentLocs) {
            if (isContainedIn(c, p)) {
                covered = true;
                break;
            }
        }
        if (!covered) return false;
    }
    return true;
}

/**
 * Permutates a sliding window by creating new windows where one of the items
 * is removed each time
 */
list[node] permutateSlidingWindow(list[node] nodes) =
    (
        []
        | it + "<confPermutatedSequenceNodeName()>"(remove(nodes, removeIndex))
        | removeIndex <- [1 .. size(nodes) - 1]
    );

/** PERMUTATED VERSION
 * Generates all possible slices over a list of nodes with given length.
 * Creates a new 'ghost' parent node containing only the slice as children
 * @param nodes: list of all nodes to slice over
 * @param length: length of slices to create
 * @return: list of newly created 'ghost' parent nodes
 */
list[node] generateSlidingWindowsWithPerm(list[node] nodes, int length) =
    (size(nodes) <= length || length <= 1) ? [] : (
        []
        | it
            + "<confFullSequenceNodeName>"(nodes[startIdx..startIdx+length])
            + permutateSlidingWindow(nodes[startIdx..startIdx+length])
        | startIdx <- [0..size(nodes)-length+1]
    );

/** ORIGINAL VERSION
 * Generates all possible slices over a list of nodes with given length.
 * Creates a new 'ghost' parent node containing only the slice as children
 * @param nodes: list of all nodes to slice over
 * @param length: length of slices to create
 * @return: list of newly created 'ghost' parent nodes
 */
list[node] generateSlidingWindows(list[node] nodes, int length) =
    (size(nodes) <= length || length <= 1) ? [] : (
        []
        | it + "<confFullSequenceNodeName>"(nodes[startIdx..startIdx+length])
        | startIdx <- [0..size(nodes)-length+1]
    );
