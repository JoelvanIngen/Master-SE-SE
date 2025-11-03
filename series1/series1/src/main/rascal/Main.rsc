module Main

import IO;

int main(int testArgument=0) {
    println("argument: <testArgument>");
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
    | f <- files(model.containment), isCompilationUnit(f)];
return asts;
}
