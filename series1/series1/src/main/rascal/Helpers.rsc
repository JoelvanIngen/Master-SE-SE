module Helpers

import String;

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
 * Removes singleline comments and cleans lines for a list of code lines.
 * Returns a list of cleaned lines.
 */
list[str] removeSinglelineComments(list[str] lines) {
    return [removeSinglelineCommentFromLine(line) | line <- lines];
}

// list[str] skipMultilineComments(list[str] lines){
//     list[str] lines = [];
//     bool openComment = false;
//     for (line <- readFileLines(location)) {
//         str line = trim(rawLine);
//         // Check for (/*)
//         if (!openComment && containsMultilineCommentOpen(line)){
//             openComment = true;
//             if (!(startsWith("/*",line))){
//                 list[str] division = split("/*",line);
//                 if (trim(division[0]) != ""){
//                     line = trim(division[0]);
//                     print("non-empty line pre-(/*)");
//                     // lines += trim(division[0]);
//                 }
//                 else{
//                     continue;
//                 }
//             }

//         }
//         // Check for (*/)
//         if (openComment && containsMultilineCommentClosure(line)){
//             println("cond2");
//             openComment = false;
//             list[str] division = split("*/",line);
//             println(division);
//             if (trim(division[1]) != ""){
//                 print("non-empty line post-(*/)");
//                 lines += trim(division[1]);
//             }
//         }

//         lines += line;

//     }
//     return lines;
// }
