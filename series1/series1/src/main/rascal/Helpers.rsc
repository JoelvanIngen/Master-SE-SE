module Helpers

import String;


/**
 * Translates metric to risk category.
 *
 * @param metric: unit size/complexity/volume
 * @param boundries: edge val for risk categories (per metric) from Config.rsc
 * @return: a risk category - low (0), medium (1), high (2), very high (3)
 */
int getRiskCategory(int unitSize, tuple[int, int, int] boundries) {
    if (unitSize <= (boundries[0])) return 0;
    if (unitSize <= (boundries[1])) return 1;
    if (unitSize <= (boundries[2])) return 2;
    return 3;
}

