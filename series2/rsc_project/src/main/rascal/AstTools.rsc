module AstTools

import IO;
import Node;

// Relates unique node (with src) to its size including (nested) children
alias SizeMap = map[node, int];

list[node] getAllSubtrees(list[node] asts) {
    list[node] subtrees = [];
    for (ast <- asts) {
        subtrees += getSubtrees(ast);
    }
    return subtrees;
}

list[node] getSubtrees(node ast) {
    list[node] subtrees = [];
    visit(ast) {
        case node n: subtrees += n;
    }
    return subtrees;
}

/**
 * Calculates the size of the node, all it's children, and further nested children.
 * Nodes must contain src information, else node hashes will collide
 * Seems bugged atm?
 */
tuple[SizeMap, int] nestedSize(SizeMap m, node n) {
    // Node without src info = size 0?
    if (!n.src?) return <m, 0>;

    // If size already in map from previous search, return that
    if (n in m) return <m, m[n]>;

    // Size is 1 (self) + size of children
    int s = 1;
    for (node child <- getChildren(n)) {
        <m, childSize> = nestedSize(m, child);
        s += childSize;
        println(childSize);
    }

    // Add size to map for cheap retrieval later
    m[n] = s;

    return <m, s>;
}
