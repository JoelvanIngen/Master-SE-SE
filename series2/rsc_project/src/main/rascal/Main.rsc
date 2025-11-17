module Main

import IO;
import lang::java::m3::AST;
import lang::java::m3::Core;

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}


void main() {
    println(":)");
}
