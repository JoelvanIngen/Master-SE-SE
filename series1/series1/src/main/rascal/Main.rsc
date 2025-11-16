module Main

import Content;
import IO;
import List;
import Location;
import Map;
import Report;
import Set;
import String;
import lang::java::m3::AST;
import lang::java::m3::Core;
import vis::Charts;

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}


void main() {
    asts = getASTs(|project://smallsql0.21_src/|);

    s = gatherScores(asts);
    pprintMetrics(s[0], s[1], s[2], s[3]);

    iso = calcISO9126(s[0], s[1], s[2], s[3]);
    pprintISO(iso[0], iso[1], iso[2]);

    maintainability = calcMaintainability(iso[0], iso[1], iso[2]);
    pprintMaintainability(maintainability);
}



Content pieChartRisk(map[int, num] riskMap){
    list[str] riskCategory = ["low risk", "medium risk", "high risk", "very high risk"];
    // FIX IT [0..4] not [3..-1](TEMPORARY SOLUTION TO KEEP THE COLORS NICE)
    input = [<"<riskCategory[risk]>", riskMap[risk]> | risk <- [3..-1]];
    return pieChart(input , title="Risk Chart");
}
