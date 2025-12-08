module AstBased::Location

import Location;
import Node;
import lang::java::m3::AST;
import lang::java::m3::Core;

/**
 * Retrieves the location from a node and returns it as loc type.
 * The target node must contain a src attribute
 */
loc castLoc(node n) {
    if (!n.src?) throw "Node <n> does not have a src field";
    switch (n.src) {
        case loc src: return src;
        default: throw "Node <n> has a src but it is not a loc type";
    }
}

/**
 * Constructs location from list of window nodes
 */
loc constructLocForWindow(node n) {
    switch (getChildren(n)[0]) {
        case list[node] nodes: {
            firstLoc = getSrc(nodes[0]);
            lastLoc = getSrc(nodes[-1]);

            if (!isSameFile(firstLoc, lastLoc)) throw "Node window spanning multiple files";

            return cover([firstLoc, lastLoc]);
        }
        default: throw "First child of window parent node was not list of nodes";
    }
}

/**
 * Gets the location attribute from a node that contains a src
 * OR
 * Constructs a loc for a "ghost" node for a window slice
 */
loc getSrc(node n) {
    if (n has src) return castLoc(n);
    return constructLocForWindow(n);
}
