module AstBased::Output

import IO;
import Map;
import List;
import Location;
import Set;
import lang::java::m3::AST;
import lang::java::m3::Core;

import Aliases;
import AstBased::Location;

// Writes clone statistics + clone classes to a text file.
void writeCloneClasses(CloneMap groups,
        int massThreshold,
        int minWindow,
        int cloneType,
        list[Declaration] asts,
        loc outFile = |project://rsc_project/src/main/rascal/AstBased/Results/results.txt|) 
    {
    str header = "";
    str content = "";
    int numberOfClones = 0;
    tuple[int, list[loc]] biggestClone = <0, [|unknown:///|]>;
    tuple[int, list[loc]] biggestClass = <0, [|unknown:///|]>;

    // Making sure the output file exists
    if (!exists(outFile)) {
        mkDirectory(outFile.parent);
        touch(outFile);
    }

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
    header += "Algorithm: AST-based Clone Detection Type <cloneType>\n";
    header += "Mass Threshold: <massThreshold>\n";
    header += "Mininum Window Size (Sequences): <minWindow>\n";
    header += "--------------------------------------------------\n";
    header += "Found <numberOfClones> clones total\n";
    header += "\nBiggest clone has <biggestClone[0]> lines\n";
    header += addMembers(biggestClone[1]);
    header += "\nFound <classId - 1> clone classes\n";
    header += "\nBiggest clone class has <biggestClass[0]> members\n";
    header += addMembers(biggestClass[1]);

    num totalLines = calculateTotalLOC(asts);
    num cloneLines = calculateCloneLines(groups);
    header += "\nTotal Lines of code <totalLines>\n";
    header += "\nTotal Cloned Lines of code <cloneLines>\n";
    header += "\nTotal percentage of clone lines <cloneLines/totalLines * 100>\n";

    header += "\n--------------------------------------------------\n";
    header += "CLONE CLASSES:\n";
    header += "--------------------------------------------------\n";


    writeFile(outFile, header + content);
    println("Results saved to file: <outFile>");
}


/**
 * Calculate total number code lines which can be considered clones
 * (which belong to a clone group)
 */
int calculateCloneLines(CloneMap groups){
    set[Location] uniqueLines = {};
    for (g <- groups){
        for (member <- groups[g]) {
            uniqueLines += locationsFromLoc(member);
        }
    }
    return size(uniqueLines);
}

set[Location] locationsFromLoc(loc l) {
    set[Location] acc = {};
    for (i <- [l.begin.line .. l.end.line + 1]) {
        acc += {<l.path, i>};
    }
    return acc;
}


/**
 * Calculate total number code lines of a project
 * (unprocessed/uncleaned, thus including empty times, comments)
 */
int calculateTotalLOC(list[Declaration] asts){
    list[loc] fileLocs = genFileList(asts);
    list[str] lines = [];
    for (f <- fileLocs){
        println(f);
        lines += readFileLines(f);
    }
    return size(lines);
}

list[loc] genFileList(list[Declaration] asts) {
    return [ast.src | ast <- asts];
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
