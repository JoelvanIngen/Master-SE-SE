module Main

import IO;
import List;
import Set;
import String;
import Map;

import lang::java::m3::Core;
import lang::java::m3::AST;

///////////////////////////////////////////
////////         CORE            //////////
///////////////////////////////////////////

int main(int testArgument=0) {
    println("argument: <testArgument>");
    return testArgument;
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
 * @return: a list of tuples for each unit (method) of the program, with
 *          location & its size
 */
list[tuple[loc, int]] calculateUnitSize(list[Declaration] asts){
    list[tuple[loc, int]] size = [];
    visit(asts){
        case \method(_, _, _, _, _, _, Statement impl):
            size += <impl.src, countLines(impl.src)>;
    }
    return size;
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
