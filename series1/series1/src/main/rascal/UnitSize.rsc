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

int calcUnitSizeScore(list[Declaration] asts, bool verbose = false){
    println("Computing Unit Size metric");

    list[int] sizes = calculateUnitSizes(asts);
    list[num] percentageRisk = unitSizeRiskCategory(sizes, percentage = true);
    int score = scoreUnitSize(percentageRisk);

    if (verbose) println("Risk categories: \t\t <percentageRisk>");
    
    return score;
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
            sizes += size(cleanLines(impl.src));
        case \initializer(_, Statement impl):
            sizes += size(cleanLines(impl.src));
        case \constructor(_, _, _, _, Statement impl):
            sizes += size(cleanLines(impl.src));
    }
    return sizes;
}


/**
 * Translates risk categories Metric Score
 *
 * @param risk: a list of relative volume of LOC per risk category
 * @return: Unit Size Metric Score
 */
int scoreUnitSize(list[real] risk){
    threshold = COMPLEXITY_SCORE_BOUNDARIES();
    real mid = risk[1];
    real high = risk[2];
    real vhigh = risk[3];

    for (i <- [0..4]){
        if (mid <= threshold[i][0] && high <= threshold[i][1] && vhigh <= threshold[i][2]) return (5 - i);
    }
    return 1;
}

/**
 * Calculates how many LOC (lines of code) belong to a given (unit size) risk category
 *
 * @param linesOfCodePerUnit: A list of sizes (LOC) of units of a source code
 * @return: a list of total lines of code per risk category (0-3)
 */
list[num] unitSizeRiskCategory(list[int] sizePerUnit, bool percentage = false){
    list[int] riskCategories = [0, 0, 0, 0];

    for (size <- sizePerUnit){
        riskCategories[getRiskCategory(size, UNIT_SIZE_RISK_BOUNDARIES())] += size;
    }

    // Convert to % results if required
    if (percentage){
        total = sum(sizePerUnit);
        return [toReal(riskSize)/total| riskSize <- riskCategories];
    }
    return riskCategories;
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
list[tuple[loc, int]] unitSizeAndLocation(list[Declaration] asts){
    list[tuple[loc, int]] info = [];
    visit(asts){
        case \method(_, _, _, _, _, _, Statement impl):
            info += <impl.src, size(cleanLines(impl.src))>;
        case \initializer(_, Statement impl):
            info += <impl.src, size(cleanLines(impl.src))>;
        case \constructor(_, _, _, _, Statement impl):
            info += <impl.src, size(cleanLines(impl.src))>;
    }
    return info;
}
