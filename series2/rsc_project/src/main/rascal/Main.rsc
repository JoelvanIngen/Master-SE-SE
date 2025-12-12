module Main

import IO;
import lang::java::m3::AST;
import lang::java::m3::Core;

import LineBased::LineBased;


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

list[Declaration] getASTsFromDirectory(loc projectLocation) {
    M3 model = createM3FromDirectory(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

void main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    // Get total # of (cleaned) lines
    fileLocs = genFileList(asts);
    cleanedLines = [cleanLines(l) | l <- fileLocs];
}
