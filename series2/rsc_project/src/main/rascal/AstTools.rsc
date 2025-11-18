module AstTools

import IO;
import Node;
import Type;

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

int constructSizeMapFindSizeFromChildren(SizeMap m, node n) {
    int s = 1;

    for (childElement <- getChildren(n)) {
        switch (childElement) {
            case node child: {
                s += m[child];
            }
            case list[node] childList: {
                for (node child <- childList) {
                    int childSize = m[child];
                    s += childSize;
                }
            }
            /* Ignore default cases, they are either str (such as identifier
             * name) or loc, neither of which are nodes that should be counted
             * for node mass purposes */
        }
    }

    return s;
}

/**
 * Constructs a cache with all sizes of all relevant nodes in an AST

 * NEEDS TESTING
 */
SizeMap constructSizeMap(node n) {
    SizeMap m = ();

    // This works because visits are breadth-first bottom-up by default
    visit (n) {
        case node subtree: {
            if (arity(subtree) == 0) {
                m[subtree] = 1;
            } else {
                m[subtree] = constructSizeMapFindSizeFromChildren(m, subtree);
            }
        }
    }

    return m;
}
