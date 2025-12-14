module AstBased::PermutationSubsumtion

import Aliases;
import List;
import Location;
import Node;

import AstBased::SequenceHelpers;

/**
 * Removes classes, which fully overlap from the CloneMap
 * by fully overlap we mean all members of the child class are contained
 * inside of the members (locations) of the parent class
 */
CloneMap removeOverlaps(CloneMap groups){
    map[set[str], list[node]] fileSetMap = fileSetCloneMap(groups);
    set[node] toRemove = {};

    for (sizeGroup <- fileSetMap){
        list[node] nodes = fileSetMap[sizeGroup];
        toRemove += {
            nodes[j] |
            int i <- [0 .. size(nodes) - 1],
            int j <- [0 .. size(nodes) - 1],
            i != j,
            node parentNode := nodes[i],
            node childNode := nodes[j],
            shouldSubsumeAndRemove(parentNode, childNode, groups[parentNode], groups[childNode], i, j)
        };
    }

    return (g : groups[g] | g <- groups, g notin toRemove);
}

/**
 * determines if the child group j should be removed based on its relationship
 * with the parent group i
 */
bool shouldSubsumeAndRemove(node parentNode, node childNode, list[loc] parentLocs, list[loc] childLocs, int i, int j) {
    bool childInParent = findIfIncluded(parentLocs, childLocs);
    bool parentInChild = findIfIncluded(childLocs, parentLocs);


    if (childInParent && !parentInChild) {
        // Case 1: Strict containment, parent strictly covers child, remove child
        return true;
    }

    if (childInParent && parentInChild) {
        // Case 2: Identical locations, mutual coverage

        // 2a: Prefer full sequence over permutation sequence
        if (isFullSequence(parentNode) && isPermutationSequence(childNode)) {
            // Keep Parent (full), Remove Child (permutation)
            return true;
        }

        // 2b: If the child is full and parent is permutation, we must keep the child
        // (same situation but other way around, the permuted sequence will be removed
        //     in future iteration)
        if (isPermutationSequence(parentNode) && isFullSequence(childNode)) {
            return false;
        }

        // 2c: Arbitrary tie-breaker.
        // To prevent removing both, we enforce an arbitrary order: higher index loses
        if (j > i) {
            return true;
        }
    }

    // Case 3, child strictly covers parent, do not remove child
    // Parent will be removed in future iteration
    return false;
}

/**
 * Checks if child location is include in parent location
 */
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


/**
 * Construct a map which categorizes clone classes with respect to the
 * set of files they occur in (anchor = file set).
 */
map[set[str], list[node]] fileSetCloneMap(CloneMap groups){
    map[set[str], list[node]] fileMap = ();

    for (node g <- groups) {
        set[str] key = { l.path | l <- groups[g] };
        fileMap[key] = (key in fileMap) ? fileMap[key] + [g] : [g];
    }

    return fileMap;
}
