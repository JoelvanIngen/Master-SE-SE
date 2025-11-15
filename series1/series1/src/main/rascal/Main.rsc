module Main

import Complexity;
import Content;
import HashDuplication;
import Helpers;
import IO;
import List;
import Location;
import Map;
import Set;
import String;
import UnitSize;
import Volume;
import lang::java::m3::AST;
import lang::java::m3::Core;
import vis::Charts;

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
    println("Unit size  : <scoreToStr(astsUnitSizeRisk(asts))>");
    println("Complexity : <scoreToStr(calcComplexity(asts))>");
    println("Duplication: <scoreToStr(duplicationScore(asts))>");
}

Content pieChartRisk(map[int, num] riskMap){
    list[str] riskCategory = ["low risk", "medium risk", "high risk", "very high risk"];
    // FIX IT [0..4] not [3..-1](TEMPORARY SOLUTION TO KEEP THE COLORS NICE)
    input = [<"<riskCategory[risk]>", riskMap[risk]> | risk <- [3..-1]];
    return pieChart(input , title="Risk Chart");
}
