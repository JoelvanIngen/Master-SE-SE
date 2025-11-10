module Main

import IO;
import List;
import String;
import Map;

import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;

import LinesOfCode;
import UnitSize;

///////////////////////////////////////////
////////         CORE            //////////
///////////////////////////////////////////

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
    | f <- files(model.containment), isCompilationUnit(f)];
return asts;
}

///////////////////////////////////////////
////////         CODE            //////////
///////////////////////////////////////////


void main() {
    asts = getASTs(|project://smallsql0.21_src/|);

    // Unit Size Metrics
    astsUnitSizeRisk(asts);
}
