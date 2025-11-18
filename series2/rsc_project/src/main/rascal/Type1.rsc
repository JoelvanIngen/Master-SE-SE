module Type1

import IO;
import List;
import Map;
import Node;
import lang::java::m3::AST;
import lang::java::m3::Core;

// Storing clone groups
alias CloneMap = map[node, list[loc]];

// Collects all fragments and groups them
CloneMap findClones(list[node] asts) {
    CloneMap groups = ();

    visit (asts) {
        case node n: {
            groups = hashAddNode(groups, n);
        }
    }

    return groups;
}

CloneMap hashAddNode(CloneMap m, node origNode) {
    // Only process nodes with src data
    if (!origNode.src?) return m;

    switch (origNode.src) {
        case loc src: {
            // Remove location data (and hopefully not anything important)
            node cleanNode = unsetRec(origNode);
            m[cleanNode] = (m[cleanNode] ? []) + [src];
        }
    }

    return m;
}
