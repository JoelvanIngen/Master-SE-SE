module UnitSize

import IO;
import List;
import String;
import Map;
import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;

import Config;
import Helpers;

/**
 * Finds all the 'units' in the source code (Java: methods) and calculates their
 * size (LOC) (excluding comments and empty lines) & assigns to a Risk Category
 *
 * @param asts
 * @param percentage: If true (default), the results will be percentage of
 *                    the source code,
 *                    if false results are in absolute lines of code (LOC)
 * @return: a map[_riskCategory_: int _LOC_ or real _%OfSourceCode_]
 */
map[int, num] astsUnitSizeRisk(list[Declaration] asts, bool percentage = true){
    // Unit Size Metrics
    println("\nUnit Size metrics:");
    sizes = calculateUnitSizes(asts);
    locRisk = linesOfCodePerUnitSizeRiskCategory(sizes);
    percentageRisk = percentageCodePerUnitSizeRiskCategory(locRisk);
    println("Risk category LOC (line of code) \t<locRisk>");
    println("Risk category percentage \t\t <percentageRisk>");
    return percentage ? percentageRisk : locRisk;
}


/**
 * Finds all the 'units' in the source code (Java: methods) and calculates
 * the size of the unit (LOC) excluding comments & empty lines
 *
 * @param asts
 * @return: a list of unit sizes (LOC)
 */
list[int] calculateUnitSizes(list[Declaration] asts){
    list[int] sizes = [];
    visit(asts){
        case \method(_, _, _, _, _, _, Statement impl):
            sizes += countLines(impl.src);
        case \initializer(_, Statement impl):
            sizes += countLines(impl.src);
        case \constructor(_, _, _, _, Statement impl):
            sizes += countLines(impl.src);
    }
    return sizes;
}

///////////////////////////////////////////
////////      Risk Category      //////////
///////////////////////////////////////////


/**
 * Calculates how many LOC (lines of code) belong to a given (unit size) risk category
 *
 * @param linesOfCodePerUnit: A list of sizes (LOC) of units of a source code
 * @return: a map of (int _riskCategory(0-3)_: int _LOC_)
 */
map[int, int] linesOfCodePerUnitSizeRiskCategory(list[int] linesOfCodePerUnit) =
    (category : sum([unitSize | unitSize <- linesOfCodePerUnit, getRiskCategory(unitSize, UNIT_SIZE_RISK_BOUNDRIES()) == category])
     | category <- [0,1,2,3]);


/**
 * Calculates % of LOC (lines of code) belonging to a given (unit size) risk category
 *
 * @param
 * @return: a map of (int _riskCategory(0-3)_: int _LOC_)
 */
map[int, real] percentageCodePerUnitSizeRiskCategory(map[int, int] locPerRiskCategory){
    total = sum([locPerRiskCategory[category] | category <- [0,1,2,3]]);
    return (category : (toReal(locPerRiskCategory[category])/total) | category <- [0,1,2,3]);
}

///////////////////////////////////////////
////////   USEFUL FOR DEBUGGING  //////////
///////////////////////////////////////////


/**
 * Finds all the 'units' in the source code (Java: methods) and calculates
 * the size of the unit (LOC) excluding comments & empty lines
 *
 * @param asts
 * @return: a list of tuples for each unit (method) of the program, with
 *          location & its size
 */
list[tuple[loc, int]] calculateUnitSizePerMethod(list[Declaration] asts){
    list[tuple[loc, int]] size = [];
    visit(asts){
        case \method(_, _, _, _, _, _, Statement impl):
            size += <impl.src, countLines(impl.src)>;
    }
    return size;
}
