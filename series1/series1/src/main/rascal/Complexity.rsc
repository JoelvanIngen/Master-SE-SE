module Complexity

import IO;
import Node;
import LinesOfCode;
import List;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::Math;

import Helpers;
import Config;

/**
 * Receives ASTs, and returns complexity score defined by the paper.
 * The output score is range 1 (--) to 5 (++).
 */
int calcComplexity(list[Declaration] asts) {
    list[tuple[int, int]] complexities = [];

    // Retrieve CC and LOC for each unit
    visit(asts) {
        case m:\constructor(_, _, _, _, Statement impl): complexities += calcMethodComplexity(m, impl);
        case m:\initializer(_, Statement impl): complexities += calcMethodComplexity(m, impl);
        case m:\method(_, _, _, _, _, _, Statement impl): complexities += calcMethodComplexity(m, impl);
    }

    // Convert results into list of LOC per severity index
    list[int] severities = locPerSeverity(complexities);

    // Convert to fractions
    list[real] fracSeverities = convertToFractions(severities, sum(severities));

    // Grade results
    return gradeComplexity(fracSeverities);
}

/**
 * Calculates cyclomatic complexity using the method described at
 * https://jellyfish.co/library/cyclomatic-complexity/
 * using the `Counting decision points` method.
 * Returns a tuple of this complexity and the LOC of this unit.
 */
tuple[int, int] calcMethodComplexity(node n, Statement impl) {
    // Counter starts at one as according to methodology
    int cc = 1;

    visit(n) {
        case \foreach(_, _, _): cc += 1;
        case \for(_, _, _, _): cc += 1;
        case \for(_, _, _): cc += 1;
        case \if(_, _): cc += 1;
        case \if(_, _, _): cc += 1;

        // For switch statements, we count each option as a complexity path
        // despite fallthrough, since it is difficult to know if any path
        // executes code before the fallthrough. Err on the side of caution
        // Maybe we can change this line to \case, and add one for each?
        case \case(_): cc += 1;
        // Do we need `caseRule` or whatever that is?
        case defaultCase(): cc += 1;

        case \try(_, _): cc += 1;
        case \try(_, _, _): cc += 1;
        case \while(_, _): cc += 1;
    }

    return <cc, countLines(impl.src)>;
}

/**
 * Determines the LOC per severity.
 * Output list has size 4 for each severity: low, medium, high, very high.
 */
list[int] locPerSeverity (list[tuple[int, int]] cc) {
    list[int] severities = [0, 0, 0, 0];
    for (unit <- cc) severities[getRiskCategory(unit[0], COMPLEXITY_RISK_BOUNDRIES())] += unit[1];

    return severities;
}

/**
 * Takes a list of total lines of code per severity
 *   Severities in this order: low, medium, high, very high
 * and the total amount of lines, and returns fractions of
 * LOC per severity
 */
list[real] convertToFractions(list[int] severities, int total_loc) {
    return [toReal(v) / total_loc | v <- severities];
}

// TODO:  COMPLEXITY_SCORE_VALUES from Config.rsc
/**
 * Determines and returns the final code grade regarding detected complexities
 * Inputs: severities: loc percentage per severity level
 *   Expects severity level order: low, medium, high, very high
 * Outputs: 5 (++), 4 (+), 3 (0), 2 (-), 1 (--)
 */
int gradeComplexity(list[real] severities) {
    real med = severities[1];
    real hi = severities[2];
    real vhi = severities[3];

    // ++ case
    if (med <= 0.25 && hi == 0.0 && vhi == 0.0) return 5;

    // + case
    if (med <= 0.3 && hi <= 0.05 && vhi == 0.0) return 4;

    // 0 case
    if (med <= 0.4 && hi <= 0.1 && vhi == 0.0) return 3;

    // - case
    if (med <= 0.5 && hi <= 0.15 && vhi <= 0.05) return 2;

    // -- case otherwise
    return 1;
}
