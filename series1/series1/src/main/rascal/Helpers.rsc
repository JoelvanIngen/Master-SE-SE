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



///////////////////////////////////////////
////////        Checkers         //////////
///////////////////////////////////////////

/**
 * Removes singleline comments and cleans lines for a list of code lines.
 * Returns a list of cleaned lines.
 */
list[str] removeSinglelineComments(list[str] lines) {
    return [removeSinglelineCommentFromLine(line) | line <- lines];
}


/**
 * Removes singleline comments (//) from a single line. Returns the clean
 * line. Ensures comment syntax inside a string ("//") is ignored.
 */
str removeSinglelineCommentFromLine(str line) {
    str cleanLine = "";

    // Comments are not started if `//` is within a string
    list[str] strParts = splitStringLiterals(line);

    bool isString = false;
    for (part <- strParts) {
        // If not string, check if line part contains comment
        if (!isString && contains("//", line)) {
            // If it does, remove the comment part and stop here
            cleanLine += removeSinglelineComment(part);
            break;
        }

        // Otherwise, add part
        cleanLine += part;

        // Next part will have string flag flipped
        isString = !isString;
    }

    return cleanLine;
}


/**
 * Splits a line of code into string parts, and everything else.
 * Any even-numbered index will be not-string-literal, and any
 * odd-numbered index will be a string literal.
 */
list[str] splitStringLiterals(str line) {
    return split("\"", line);
}


/**
 * Takes a line or part of a line, and returns the part that is not within
 * a singleline comment. This might be the entire string.
 */
str removeSinglelineComment(str line) {
    return split("//", line)[0];
}
