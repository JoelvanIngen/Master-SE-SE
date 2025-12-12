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

void printCloneAmount(list[Declaration] asts) {
    fileLocs = genFileList(asts);
    cleanedLines = [cleanLines(l) | l <- fileLocs];
    filePaths = [l.path | l <- fileLocs];
    findClones(cleanedLines, filePaths);
}

void testCloneAmount() {
    cleanedLines = [["1", "2", "3", "4", "5", "6", "1", "2", "3", "4", "5", "6"]];
    filePaths = ["file1"];
    findClones(cleanedLines, filePaths);
}

void main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    testCloneAmount();
    // println(asts);
}
