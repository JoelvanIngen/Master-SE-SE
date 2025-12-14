module Main

import IO;
import Location;
import lang::java::m3::AST;
import lang::java::m3::Core;

import LineBased::LineBased;
import AstBased::Detector;
import AstBased::Output;


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
    int massThreshold = 50;
    int minWindow = 3;

    list[Declaration] asts = getASTs(|project://smallsql0.21_src/|);

    // AST-based detectors
    clones = detectClonesI(asts, massThreshold, minWindow);
    // clones = detectClonesII(asts, massThreshold, minWindow);
    // clones = detectClonesIII(asts, massThreshold, minWindow);

    writeCloneClasses(clones, massThreshold, minWindow, 1, asts);

}
