module Main

import IO;
import List;
import Set;
import String;
import Map;
import lang::java::m3::AST;
import lang::java::m3::Core;

int main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    calcVolumeMetric(asts);
    return 0;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}
