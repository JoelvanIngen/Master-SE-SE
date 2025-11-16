module Helpers

import IO;
import List;
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

str scoreToStr(int score) {
    switch (score) {
        case 1: return "--";
        case 2: return "-";
        case 3: return "0";
        case 4: return "+";
        case 5: return "++";
    }

    throw "Unexpected score of <score> which is outside range of 1-5";
}

/**
 * Cleans the code lines.
 * Excludes:
 *         comments (single-line & multi-line)
 *         empty lines
 *         empty leading & trailing spaces
 * returns: a list of all cleaned lines from a source location, which remained
 */
list[str] cleanLines(loc location){
    list[str] lines = readFileLines(location);
    return cleanLinesFromList(lines);
}


list[str] cleanLinesFromList(list[str] lines){
    list[str] clean = [];
    bool openComment = false;

    for (line <- lines){
        str newLine = "";
        int i = 0;

        // Iterate through the line
        while (i < size(line)){
            // Multi line comment open
            if (!openComment && line[i..i+2] == "/*"){
                openComment = true;
                i += 2;
                continue;
            }

            // Multi line comment close
            if (openComment && line[i..i+2] == "*/"){
                openComment = false;
                i += 2;
                continue;
            }

            // Single line comment
            if (!openComment && line[i..i+2] == "//"){
                break;
            }

            // Regular code
            if (!openComment){
                newLine += line[i];
            }
            i += 1;
        }
        // Removing leading & training whitespaces (& indendation)
        clean += trim(newLine);
    }
    return [ cleanLine | cleanLine <- clean, cleanLine != ""];
}
