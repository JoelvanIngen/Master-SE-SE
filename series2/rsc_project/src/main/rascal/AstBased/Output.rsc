module AstBased::Output

import Aliases;
import IO;
import Location;
import Map;
import List;

// Writes clone statistics + clone classes to a text file.
void writeCloneClasses(CloneMap groups, loc outFile = |project://rsc_project/src/main/rascal/AstBased/Results/results.txt|) {
    str header = "";
    str content = "";
    int numberOfClones = 0;
    tuple[int, list[loc]] biggestClone = <0, [|unknown:///|]>;
    tuple[int, list[loc]] biggestClass = <0, [|unknown:///|]>;

    // Making sure the output file exists
    if (!exists(outFile)) throw "Output file does not exist at <outFile>";

    int classId = 1;
    for (node key <- groups) {
        list[loc] members = groups[key];

        // Update statistics
        int classSize = size(members);
        numberOfClones += classSize;

        if (biggestClass[0] < classSize) biggestClass = <classSize, members>;

        // assumption: all clones in a class have the same size (line-wise)
        int cloneSize = calculateLines(members[0]);
        if (biggestClone[0] < cloneSize) biggestClone = <cloneSize, members>;

        // Output per class
        content += "Clone class <classId> (size: <classSize>)\n";
        content += addMembers(members);
        content += "\n";

        classId += 1;
    }
    header += "--------------------------------------------------\n";
    header += "REPORT ON CLONE DETACTION RESULTS\n";
    header += "--------------------------------------------------\n";
    header += "Found <numberOfClones> clones total\n";
    header += "\nBiggest clone has <biggestClone[0]> lines\n";
    header += addMembers(biggestClone[1]);
    header += "\nFound <classId - 1> clone classes\n";
    header += "\nBiggest clone class has <biggestClass[0]> members\n";
    header += addMembers(biggestClass[1]);

    header += "\n--------------------------------------------------\n";
    header += "CLONE CLASSES:\n";
    header += "--------------------------------------------------\n";


    writeFile(outFile, header + content);
    println("Results saved to file: <outFile>");
}


// Helper to turn a loc into "path:beginLine-endLine"
str formatLoc(loc l) {
    return "<l.path>:<l.begin.line>-<l.end.line>";
}


// Number of source lines covered by a clone (clone size)
int calculateLines(loc l) {
    return l.end.line - l.begin.line + 1;
}

// Add all members of a clone class as indented lines (into content str)
str addMembers(list[loc] members){
    str s = "";
    for (loc m <- members) {
            s += "  <formatLoc(m)>\n";
    }
    return s;
}
