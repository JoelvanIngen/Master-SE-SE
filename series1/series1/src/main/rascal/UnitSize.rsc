
module UnitSize

import IO;
import List;
import String;
import Map;

import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;

import LinesOfCode;

map[int, real] astsUnitSizeRisk(list[Declaration] asts){
    // Unit Size Metrics
    println("\nUnit Size metrics:");
    sizes = calculateUnitSizes(asts);
    locRisk = linesOfCodePerUnitSizeRiskCategory(sizes);
    percentageRisk = percentageCodePerUnitSizeRiskCategory(locRisk);
    println("Risk category LOC (line of code) \t<locRisk>");
    println("Risk category percentage \t\t <percentageRisk>");
    return percentageRisk;
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
 * Translates unit size to risk category.
 *
 * @param unitSize: LOC per method (Java)
 * @return: a risk category - low (0), medium (1), high (2), very high (3)
 * https://softwareimprovementgroup.com/wp-content/uploads/SIG-TUViT-Evaluation-Criteria-Trusted-Product-Maintainability-Guidance-for-producers.pdf?_gl=1*syaptg*_gcl_au*MTI0MTM4NDk4OS4xNzYyMDg5MDMw
 */
int getRiskCategory(int unitSize) {
    if (unitSize <= 15) return 0;
    if (unitSize <= 30) return 1;
    if (unitSize <= 60) return 2;
    return 3;
}


/**
 * Calculates how many LOC (lines of code) belong to a given (unit size) risk category
 *
 * @param linesOfCodePerUnit: A list of sizes (LOC) of units of a source code
 * @return: a map of (int _riskCategory(0-3)_: int _LOC_)
 */
map[int, int] linesOfCodePerUnitSizeRiskCategory(list[int] linesOfCodePerUnit) =
    (category : sum([unitSize | unitSize <- linesOfCodePerUnit, getRiskCategory(unitSize) == category])
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
