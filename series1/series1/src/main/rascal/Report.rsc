module Report

import Complexity;
import Config;
import Duplication;
import Helpers;
import IO;
import String;
import UnitSize;
import Volume;
import lang::java::m3::AST;
import lang::java::m3::Core;

/**
 * Pretty prints the score for each metric
 * @param v: volume score
 * @param u: unit size score
 * @param c: complexity score
 * @param d: duplication score
 */
void pprintMetrics(int v, int u, int c, int d) {
    println("\nMetrics:");
    println("Volume     : <scoreToStr(v)>");
    println("Unit size  : <scoreToStr(u)>");
    println("Complexity : <scoreToStr(c)>");
    println("Duplication: <scoreToStr(d)>");
}

/**
 * Pretty prints the score for each ISO metric
 * @param a: analysability score
 * @param c: changeability score
 * @param t: testability score
 */
void pprintISO(int a, int c, int t) {
    println("\nISO:");
    println("Analysability: <scoreToStr(a)>");
    println("Changeability: <scoreToStr(c)>");
    println("Testability  : <scoreToStr(t)>");
}

/**
 * Pretty prints the final maintainability score
 * @param m: score as integer
 */
void pprintMaintainability(int m) {
    println("\nMaintability Score: <scoreToStr(m)>");
}

/**
 * Gathers scores for all metrics
 */
tuple[int, int, int, int] gatherScores(list[Declaration] asts) {
    return <
        calcVolumeScore(asts, verbose=VERBOSE()),
        calcUnitSizeScore(asts, verbose=VERBOSE()),
        calcComplexityScore(asts, verbose=VERBOSE()),
        calcDuplicationScore(asts, verbose=VERBOSE())
    >;
}

/**
 * Calculates the ISO 9126 metric according to the paper's method
 * @param v: volume score
 * @param i: unit size score
 * @param c: complexity score
 * @param d: duplication score
 * @return: tuple containing analysability, changeability, testability
 */
tuple[int, int, int] calcISO9126(int v, int u, int c, int d) {
    return <
        averageInt([v, d, u]),
        averageInt([c, d]),
        averageInt([c, u])
    >;
}

/**
 * Computes the final maintainability score
 * @param a: analysability score
 * @param c: changeability score
 * @param t: testability score
 * @return: final maintainability
 */
int calcMaintainability(int a, int c, int t) {
    return averageInt([a, c, t]);
}
