module AstTools

import Aliases;
import IO;
import Location;
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

int constructSizeFromChildren(SizeMap m, node n) {
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

int constructSize(SizeMap m, node n) {
    return arity(n) == 0
        ? 1
        : constructSizeFromChildren(m, n);
}

/**
 * Constructs a cache with all sizes of all relevant nodes in an AST

 * NEEDS TESTING
 */
SizeMap constructSizeMap(list[node] nodes) {
    SizeMap m = ();

    // This works because visits are breadth-first bottom-up by default
    visit (nodes) {
        case node subtree: m[subtree] = constructSize(m, subtree);
    }

    return m;
}



/**
 * Extracts the starting line number as integer from a node
 * Node must have been checked for existence of src attribute
 * If it doesn't have an src attribute, function will error
 */
Location extractStartingLine(node n) {
    switch (n.src) {
        case loc src: return <src.path, src.begin.line>;
    }

    fail;
}

set[Location] getStartingLines(node n) = getStartingLines([n]);

set[Location] getStartingLines(list[node] nodes) {
    set[Location] s = {};

    visit(nodes) {
        case node child: {
            if (child.src?) {
                s += {extractStartingLine(child)};
            }
        }
    }

    return s;
}
