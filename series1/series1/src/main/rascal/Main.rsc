module Main

import IO;
import List;
import Location;
import Set;
import String;
import Map;
import Content;
import vis::Charts;
import lang::java::m3::AST;
import lang::java::m3::Core;

import UnitSize;
import Complexity;
import Volume;

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}


Content main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    // TO BE FIXED (input type):
    // set[loc] locations = genFileList(asts);
    // println(locations);
    // println(size(locations));
    // println(countLines(locations));
    // println(astsUnitSizeRisk(asts));
    unitSizeRisk = astsUnitSizeRisk(asts, percentage = false);
    return pieChartRisk(unitSizeRisk);
}


Content pieChartRisk(map[int, num] riskMap){
    list[str] riskCategory = ["low risk", "medium risk", "high risk", "very high risk"];
    input = [<"<riskCategory[risk]>", riskMap[risk]> | risk <- [0..4]];
    return pieChart(input , title="Risk Chart");
}
