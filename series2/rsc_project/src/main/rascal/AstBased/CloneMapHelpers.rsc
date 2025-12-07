module AstBased::CloneMapHelpers

import IO;
import Location;
import List;
import Map;
import Node;

import AstBased::Location;

// Storing clone groups
alias CloneMap = map[node, list[node]];

CloneMap addNodeToCloneMap(CloneMap m, node origNode) {
    // Remove location data (and hopefully not anything important)
    node cleanNode = unsetRec(origNode);

    if (cleanNode notin m) {
        m[cleanNode] = [origNode];
        return m;
    }

    // Add node to class iff it doesn't overlap with an existing clone in that class
    otherCloneCandidates = m[cleanNode];
    origSrc = getSrc(origNode);
    for (cand <- otherCloneCandidates) {
        if (isOverlapping(getSrc(cand), origSrc)) return m;
    }
    m[cleanNode] = m[cleanNode] + [origNode];

    return m;
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

/**
 * Removes a child clone class from the bucket if it's actually a child of the parent,
 * but keeps it in case one of the targeted code segments is not extended, to prevent
 * loss of partial clones
 */
set[node] removeIfTrueParentClass(CloneMap bucket, node cleanNode, node n){
    set[node] nodesToRemove = {};
    return n in bucket && size(bucket[cleanNode]) == size(bucket[n]) ? {n} : nodesToRemove;
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

