module Clone::CloneMap

import Ast::Node;
import Location;
import Node;

// Storing clone groups
alias CloneMap = map[node, list[node]];

CloneMap cloneMapHashNode(CloneMap m, node origNode) {
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
    m[cleanNode] += [origNode];

    return m;
}
