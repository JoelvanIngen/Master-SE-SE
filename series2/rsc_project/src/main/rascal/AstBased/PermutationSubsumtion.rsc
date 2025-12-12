module AstBased::PermutationSubsumtion

import List;
import Location;
import Node;

alias CloneLocs = list[loc];
alias CloneMap = map[node, CloneLocs];

int cloneLines(loc l) {
    return l.end.line - l.begin.line + 1;
}

CloneMap removeOverlaps(CloneMap groups){

    map[int, list[node]] sizeMap = sizeCloneMap(groups);
    set[node] toRemove = {};

    for (sizeGroup <- sizeMap){
        list[node] nodes = sizeMap[sizeGroup];
        toRemove += {
            nodes[j] |
            int i <- [0 .. size(nodes) - 1],
            int j <- [0 .. size(nodes) - 1],
            i != j,
            findIfIncluded(groups[nodes[i]], groups[nodes[j]])
        };
    }

    return (g : groups[g] | g <- groups, g notin toRemove);
}

bool findIfIncluded(list[loc] members1, list[loc] members2){

    if (size(members1) != size(members2)) return false;

    list[tuple[loc, loc]] pairs = [];
    pairs = [<m, n> | m <- members1, n <- members2, isContainedIn(n, m)];

    return size(pairs) == size(members1);
}

// Assumes all members in a class have the same line length
int classCloneLines(list[loc] members) {
    return isEmpty(members) ? 0 : cloneLines(members[0]);
}

/**
 * Construct a map, which categorizes clone classes with respect to their
 * number of class members
 */
map[int, list[node]] sizeCloneMap(CloneMap groups){
    map[int, list[node]] sizeMap = ();

    for (node g <- groups) {
        int groupSize = size(groups[g]);
        sizeMap[groupSize] = (groupSize in sizeMap) ? sizeMap[groupSize] + [g] : [g];
  }

    return sizeMap;
}
