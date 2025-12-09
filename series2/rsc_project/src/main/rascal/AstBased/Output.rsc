module AstBased::Output

import IO;
import Location;
import Map;
import List;

alias CloneLocs = list[loc];
alias CloneMap  = map[node, CloneLocs];

// Helper to turn a loc into "path:beginLine-endLine"
str formatLoc(loc l) {
    return "<l.path>:<l.begin.line>-<l.end.line>";
}

// Writes clone classes to a text file.
void writeCloneClasses(CloneMap groups) {
    loc outFile = |project://rsc_project/src/main/rascal/AstBased/Results/results.txt|;
    str content = "";

    // Making sure the output file exists
    if (!exists(outFile)) throw "Output file does not exist at <outFile>";

    int classId = 1;
    for (node key <- groups) {
        list[loc] members = groups[key];

        content += "Clone class <classId> (size: <size(members)>)\n";

        for (loc m <- members) {
            content += "  <formatLoc(m)>\n";
        }

        content += "\n";
        classId += 1;
    }

    writeFile(outFile, content);
    println("Results saved to file: <outFile>");
}