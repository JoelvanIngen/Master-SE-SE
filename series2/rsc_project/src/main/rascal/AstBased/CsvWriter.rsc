module AstBased::CsvWriter

import Aliases;
import IO;
import List;
import String;

loc RESULTSFILE = |project://rsc_project/src/main/rascal/AstBased/Results/results.csv|;

void writeCsv(CloneMap groups, loc resultsFile = RESULTSFILE) =
    writeFile(resultsFile, constructCsv(groups));

str constructCsv(CloneMap groups) =
    (
        ""
        | it + processCloneGroup(groups[group])
        | group <- groups
    );

str processCloneGroup(CloneLocs locs) =
    (
        ""
        | it + processClonePair(loc1, loc2) + "\n"
        | loc1Idx <- [0..size(locs)-1],
          loc2Idx <- [loc1Idx+1..size(locs)],
          loc1 := locs[loc1Idx],
          loc2 := locs[loc2Idx]
    );

str processClonePair(loc loc1, loc loc2) =
    "<constructLocCsvEntry(loc1)>,<constructLocCsvEntry(loc2)>";

str constructLocCsvEntry(loc l) =
    "<determineCloneEvalDir(l.path)>,<l.file>,<l.begin.line>,<l.end.line>";

str determineCloneEvalDir(str filePath) {
    /* I hope there is a better way to achieve this since one of these could
     * accidentally be in the file path/name. However, since the path contains
     * scary nested folders, that would require annoying splitting and matching.
     * Maybe some sort of checking when the path starts diverging? And only
     * check if it's either the first diverging immediately after, between the next / /,
     * or in the equal bit? */
    if (contains(filePath, "selected")) return "selected";
    if (contains(filePath, "sample")) return "sample";
    if (contains(filePath, "default")) return "default";

    throw "Path <filePath> did not include any of the search-keywords.";
}

void _testManualLocs() {
    CloneMap tMap = (
        "test"(): [
            |java+compilationUnit:///src/smallsql/default/TestOperatoren.java|(10110,336,<217,8>,<225,41>),
            |java+compilationUnit:///src/smallsql/sample/TestOperatoren.java|(10450,324,<226,2>,<234,41>),
            |java+compilationUnit:///src/smallsql/selected/TestOperatoren.java|(10913,326,<238,2>,<246,40>)
        ]
    );

    writeCsv(tMap);
}
