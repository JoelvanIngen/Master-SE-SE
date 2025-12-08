module AstBased::CloneMapHelpers

import IO;
import Location;
import List;
import Map;
import Node;

import AstBased::Location;

// Storing clone groups
alias CloneLocs = list[loc];
alias CloneMap = map[node, CloneLocs];

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
tuple[CloneMap, int] cleanGroups(CloneMap groups, int currWindowSize) {
    println("\nENTERING CLEANING: WINDOW SIZE <currWindowSize> | CLONE GROUPS: <size(groups)>");
    groups = filterRealCloneGroups(groups);
    int earlyExitCloneNumber = size(groups);
    println("AFTER \"REAL CLONES\" FILTER | CLONE GROUPS: <size(groups)>");
    groups = removeSubClones(groups, currWindowSize);
    println("AFTER REMOVING SUBCLONES | CLONE GROUPS: <size(groups)>");

    return <groups, earlyExitCloneNumber>;
}

/**
 * Constructs a new clonegroup map, only keeping groups with more than 1
 * member, as a one-membered group will only contain an original.
 */
CloneMap filterRealCloneGroups(CloneMap gs) {
    return (g: (gs[g]) | g <- gs, size(gs[g]) > 1);
}

// Removes all subclone groups by checking all children
CloneMap removeSubClones(CloneMap groups, int currWindowSize){
    set[node] nodesToRemove = {};
    for (cleanNode <- groups){
        visit (getChildren(cleanNode)) {
            case node n: {
                nodesToRemove += removeIfSubsumed(groups, cleanNode, n);
            }
            case list[node] nodes: {
                windowsToRemove = generateSlidingWindows(nodes, currWindowSize - 1);
                for (n <- windowsToRemove) {
                    nodesToRemove += removeIfSubsumed(groups, cleanNode, n);
                }
            }
        }
    }
    groups = (n: groups[n] | n <- groups, n notin nodesToRemove);
    return groups;
}


/**
 * Removes a child clone class from the groups if it's actually a child of the parent,
 * but keeps it in case one of the targeted code segments is not extended, to prevent
 * loss of partial clones
 */
set[node] removeIfTrueParentClass(CloneMap groups, node cleanNode, node n){
    set[node] emptySet = {};
    // TODO: what if size(groups[cleanNode]) < size(groups[n])...? Does it happen? Do we want to do anything about it?
    return n in groups && size(groups[cleanNode]) == size(groups[n]) ? {n} : emptySet;
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

