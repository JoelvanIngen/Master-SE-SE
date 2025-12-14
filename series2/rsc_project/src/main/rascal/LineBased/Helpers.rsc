module LineBased::Helpers

import IO;
import List;
import String;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::Math;

/**
 * Pretty prints a map
 */
void pprintMap(map[&K, &V] m) {
    for (&K k <- m) {
        &V v = m[k];
        println("<k>: <v>");
    }
}


list[loc] genFileList(list[Declaration] asts) {
    return [ast.src | ast <- asts];
}


int averageInt(list[int] xs) {
    return round(toReal(sum(xs)) / size(xs));
}
