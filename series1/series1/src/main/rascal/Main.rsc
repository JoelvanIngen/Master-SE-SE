module Main

import IO;
import List;
import Set;
import String;
import Map;

import lang::java::m3::Core;
import lang::java::m3::AST;

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

list[loc] calculateUnitSize(list[Declaration] asts){
    list[loc] locs = [];
    visit(asts){
        case \method(_, _, _, Expression name, _, _, Statement impl): locs += impl.src;
        // Not including these because they are just declarations without the body
        // case \method(_, _, _, _ , _, _): locs += name.src;
    }
    return locs;
}

int getLineNumber(list[Declaration] asts){
    list[loc] locs = calculateUnitSize(asts);
    loc location = locs[0];
    // int lines = countLinesSingleFile(location);
    // list[str] lines = skipMultilineComments(location);
    list[str] lines = readFileLines(location);
    list[str] cleanedLines = skipMultilineComments(lines);
    return size(cleanedLines);
}

/*
 * Removes embedded multiline comments in singular line
 */
str removeLineEmbeddedMultilineComments(str line){
    return multilineOpen(line);
}

str multilineOpen(str line){
    // Check if contains (*/) at all
    if (size(findAll(line, "/*")) > 0 ){
        // Splits "aaa /* something */ bbb" into ["aaa ", " something */ bbb"]
        list[str] division = split("/*",line);
        println(division);
        if (size(division) != 0){
            if (trim(division[0]) != ""){
                println(division);
                // add part to deal somehow with closing multiliner
                return trim(division[0]) + multilineClose(division[1]);
            }
        }
        return "";
    }
    return line;

}

str multilineClose(str line){
    if (size(findAll(line, "*/")) > 0 ){
        // Splits "something */ bbb" into ["something  ", " bbb"]
        list[str] division = split("*/",line);
        if (size(division) != 0){
            if (trim(division[1]) != ""){
                // add part to deal somehow with another opening multiliner
                return multilineOpen(trim(division[1]));
            }
        }
        return "";
    }
    return line;
}

str checkLine(str raw_line, bool openComment){

    str line = trim(raw_line);
    // Check for (/*)
    if (!openComment && containsMultilineCommentOpen(line)){
        openComment = true;
        str string = multilineOpen(line);
        if (size(string) == 0){
            return checkLine(string, openComment);
        }
    }
    // Check for (*/)
    if (openComment && containsMultilineCommentClosure(line)){
        openComment = false;
        str string = multilineClose(line);
        if (size(string) == 0){
            return checkLine(string, openComment);
        }
    }
    return line;
}

// str replaceClosedComments(str initial) {
//   return replaceFirst(initial, /\/\*.*?\*\//, "");
// }

list[str] skipMultilineComments(list[str] raw_lines){
    list[str] lines = [];
    bool openComment = false;
    for (raw_line <- raw_lines) {
        str line = trim(raw_line);
        line = checkLine(line, openComment);
        println(line);
        lines += line;

    }
    return lines;
}

//

int countLinesSingleFile(loc location) {
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
 * Trims leading whitespace
 */
bool startsWithSinglelineComment(str line) {
    return startsWith(line, "//");
}

/**
 * Determines whether an LOC starts with a comment opening (/*)
 * Trims leading whitespace
 * Should NOT count as a line of code for counting purposes,
 * and subsequent lines should also not count until comment closure (* /)
 */
bool startsWithMultilineCommentOpen(str line) {
    return startsWith(line, "/*");
}

/**
 * Determines whether an LOC contains a comment opening (/*)
 * SHOULD count as a line of code for counting purposes,
 * but subsequent lines should not count until comment closure (* /)
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
