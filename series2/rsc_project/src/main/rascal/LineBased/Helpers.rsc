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

/**
 * Translates metric to risk category.
 *
 * @param metric: unit size/complexity/volume
 * @param boundaries: edge val for risk categories (per metric) from Config.rsc
 * @return: a risk category - low (0), medium (1), high (2), very high (3)
 */
int getRiskCategory(int unitSize, tuple[int, int, int] boundaries) {
    if (unitSize <= (boundaries[0])) return 0;
    if (unitSize <= (boundaries[1])) return 1;
    if (unitSize <= (boundaries[2])) return 2;
    return 3;
}

str scoreToStr(int score) {
    switch (score) {
        case 1: return "--";
        case 2: return "-";
        case 3: return "o";
        case 4: return "+";
        case 5: return "++";
    }

    throw "Unexpected score of <score> which is outside range of 1-5";
}
