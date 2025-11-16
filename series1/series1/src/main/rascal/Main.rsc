module Main

import Content;
import IO;
import List;
import Location;
import Map;
import Set;
import String;
import lang::java::m3::AST;
import lang::java::m3::Core;
import vis::Charts;

import Complexity;
import Duplication;
import Helpers;
import UnitSize;
import Volume;


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}


int main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    pprintScores(asts);
    return 0;
}

/**
 * Pretty prints the scores for each category
 */
void pprintScores(list[Declaration] asts) {
    println("Volume     : <scoreToStr(calcVolumeScore(asts))>");
    println("Unit size  : <scoreToStr(calcUnitSizeScore(asts))>");
    println("Complexity : <scoreToStr(calcComplexityScore(asts))>");
    println("Duplication: <scoreToStr(calcDuplicationScore(asts))>");
}

Content pieChartRisk(map[int, num] riskMap){
    list[str] riskCategory = ["low risk", "medium risk", "high risk", "very high risk"];
    // FIX IT [0..4] not [3..-1](TEMPORARY SOLUTION TO KEEP THE COLORS NICE)
    input = [<"<riskCategory[risk]>", riskMap[risk]> | risk <- [3..-1]];
    return pieChart(input , title="Risk Chart");
}
