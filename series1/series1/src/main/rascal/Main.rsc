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
    int howMany = countLinesSingleFile(location);
    return howMany;
}

/*
 * Removes embedded multiline comments in singular line
 */
str removeLineEmbeddedMultilineComments(str line){
    return multilineOpen(line);
}

str multilineOpen(str line){
    if (size(findAll(line, "/*")) > 0 ){
        // Splits "aaa /* something */ bbb" into ["aaa ", " something */ bbb"]
        int index = findFirst(line, "/*");
        str before = line[0..index];
        str after = line[index+2..];

        // Look for "*/"
        return trim(before) + multilineClose(after);
    }
    return line;

}

str multilineClose(str line){
    if (size(findAll(line, "*/")) > 0 ){
        int index = findFirst(line, "*/");
        str after = line[index+2..];
        return multilineOpen(trim(after));
    }
    else{
        // If there is no closing "*/" add "*/" we removed before in multilineOpen()
        return "/*" + line;
    }
}

// str replaceClosedComments(str initial) {
//   return replaceFirst(initial, /\/\*.*?\*\//, ""); /* something */
// }

list[str] skipMultilineComments(list[str] raw_lines){
    list[str] lines = [];
    bool openComment = false;
    for (raw_line <- raw_lines) {
        str line0 = trim(raw_line);
        str line = multilineOpen(line0);
        // Check for (/*)
        if (!openComment && containsMultilineCommentOpen(line)){
            openComment = true;
            if (!startsWith(line, "/*")){
                lines += line;
            }
        }
        // Check for (*/)
        if (openComment && containsMultilineCommentClosure(line)){
            openComment = false;
            if (endsWith(line, "*/")){
                continue;
            }
        }
        if (!openComment){
            lines += line;
        }
    }
    return lines;
}

//

int countLinesSingleFile(loc location) {
    int nLines = 0;
    list[str] lines = readFileLines(location);
    list[str] cleanedLines = skipMultilineComments(lines);
    // for (l <- cleanedLines){
    //     println(l);
    // }

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
