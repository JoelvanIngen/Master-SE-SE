module Main

import IO;
import List;
import Set;
import String;
import Map;

import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;

///////////////////////////////////////////
////////         CORE            //////////
///////////////////////////////////////////

void main(int testArgument=0) {
    println("\nUnit Size metrics:");
    asts = getASTs(|project://smallsql0.21_src/|);
    sizes = calculateUnitSizes(asts);
    locRisk = linesOfCodePerUnitSizeRiskCategory(sizes);
    percentageRisk = percentageCodePerUnitSizeRiskCategory(locRisk);
    println("Risk category LOC (line of code) \t<locRisk>");
    println("Risk category percentage \t <percentageRisk>");
}


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
    | f <- files(model.containment), isCompilationUnit(f)];
return asts;
}

///////////////////////////////////////////
////////         CODE            //////////
///////////////////////////////////////////


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
    }
    return sizes;
}



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


/**
 * Searches the strings to find start nomenclature of the multi line comment
 * Removes multiline comments embedded in a SINGLE codeline.
 * Leaves opened multiline comments, but not closed in the same line.
 */
str startMultiLineComment(str line){
    int index = findFirst(line, "/*");
    if (index >= 0){
        str head = line[0..index];
        str tail = line[index+2..];
        return trim(head) + endMultiLineComment(tail);
    }
    return line;

}


/**
 * Searches the strings to find closing of the multi line comment
 */
str endMultiLineComment(str line){
    int index = findFirst(line, "*/");
    if (index >= 0 ){
        str tail = line[index+2..];
        return startMultiLineComment(trim(tail));
    }
    // If multi line comment was not closed in the same line, add "/*"
    // which was removed in startMultiLineComment()
    return "/*" + line;
}


/**
 * Filters a list of code lines and removes multi-line comments
 */
list[str] skipMultilineComments(list[str] linesWithComments){
    list[str] lines = [];
    bool openComment = false;
    for (lineWithComments <- linesWithComments) {

        // Removes multiline comments embedded in a SINGLE code line
        // example: "int a=4; /* text */" ---> "int a=4;"
        str line = startMultiLineComment(trim(lineWithComments));

        // Opening of the multi-line comment
        if (!openComment && containsMultilineCommentOpen(line)){
            openComment = true;
            // If line starts with "/*", don't include it in the line count
            // If line does not start with "/*", include it
            if (!startsWith(line, "/*")){
                lines += line;
            }
        }

        // Closing of the multi-line comment
        if (openComment && containsMultilineCommentClosure(line)){
            openComment = false;
            // If line ends with "*/", include it in the line count
            // If line does not ends with "*/", don't include it
            if (endsWith(line, "*/")){
                continue;
            }
        }

        // Include lines, which are not inside of open multi-line comment
        if (!openComment){
            lines += line;
        }
    }
    return lines;
}


/**
 * Count the number of lines at a given location.
 * Excludes comments & empty lines
 */
int countLines(loc location) {
    int nLines = 0;
    list[str] lines = readFileLines(location);
    list[str] cleanedLines = skipMultilineComments(lines);

    for (line <- cleanedLines) {
        if (lineIsEmpty(line)) continue;
        if (startsWithSinglelineComment(line)) continue;
        nLines += 1;
    }

    return nLines;
}


/**
 * Determines whether a line is empty
 */
bool lineIsEmpty(str line) {
    return line == "";
}


/**
 * Determines whether a line starts with a single-line comment (//)
 */
bool startsWithSinglelineComment(str line) {
    return startsWith(line, "//");
}


/**
 * Determines whether an LOC contains a comment opening (/*)
 */
bool containsMultilineCommentOpen(str line) {
    return contains(line, "/*");
}


/**
 * Determines whether an LOC contains a comment closure (* /)
 */
bool containsMultilineCommentClosure(str line) {
    return contains(line, "*/");
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
