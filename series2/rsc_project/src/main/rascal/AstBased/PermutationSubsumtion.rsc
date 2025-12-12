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

bool findIfIncluded(list[loc] parent, list[loc] child){
  if (size(child) != size(parent)) return false;

  for (loc c <- child) {
    bool ok = false;
    for (loc p <- parent) {
      if (isContainedIn(c, p)) { ok = true; break; }
    }
    if (!ok) return false;
  }
  return true;
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
        // To make it fast, exclude size 1;
        if (groupSize <= 1) continue;
        sizeMap[groupSize] = (groupSize in sizeMap) ? sizeMap[groupSize] + [g] : [g];
  }

    return sizeMap;
}
