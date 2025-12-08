module AstBased::AstTools

import Aliases;
import IO;
import Location;
import Node;
import Type;
import List;

// Relates unique node (with src) to its size including (nested) children
alias SizeMap = map[node, int];

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


/**
 * Builds a map of all AST nodes to their sizes (mass) for quick lookup.
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
 * Computes the size of a single AST node, including its children.
 */
int constructSize(SizeMap m, node n) {
    return arity(n) == 0
        ? 1
        : constructSizeFromChildren(m, n);
}


/**
 * Computes the total mass of a sequence of nodes using the size map.
 */
int slidingWindowMass(SizeMap masses, node window) {
    int mass = 0;

    switch (getChildren(window)[0]) {
        case list[node] children: {
            mass = sum([masses[child] | node child <- children]);
        }
    }

    return mass;
}

Location getStartingLine(loc src) = <src.path, src.begin.line>;

/**
 * Extracts the starting line number as integer from a node
 * Node must have been checked for existence of src attribute
 * If it doesn't have an src attribute, function will error
 */
Location getStartingLine(node n) {
    switch (n.src) {
        case loc src: return getStartingLine(src);
        default: throw "Node <n> does not have src field";
    }
}

set[Location] getStartingLines(node n) = getStartingLines([n]);

set[Location] getStartingLines(list[loc] srcs) =
    {getStartingLine(src) | src <- srcs};

set[Location] getStartingLines(list[node] nodes) {
    set[Location] s = {};

    visit(nodes) {
        case node child: {
            if (child.src?) {
                s += {getStartingLine(child)};
            }
        }
    }

    return s;
}
