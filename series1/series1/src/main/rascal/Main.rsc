module Main

import IO;
import List;
import Location;
import Set;
import String;
import Map;
import lang::java::m3::AST;
import lang::java::m3::Core;

import LinesOfCode;
import UnitSize;
import Complexity;
import Volume;


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}


void main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    // TO BE FIXED (input type):
    // set[loc] locations = genFileList(asts);
    // println(locations);
    // println(size(locations));
    // println(countLines(locations));
    println(astsUnitSizeRisk(asts));
}
