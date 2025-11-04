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

list[str] skipMultilineComments(list[str] raw_lines){
    list[str] lines = [];
    bool openComment = false;
    for (line <- raw_lines) {
        str line = trim(line);
        // Check for (/*)
        if (!openComment && containsMultilineCommentOpen(line)){
            openComment = true;
            if (!(startsWith("/*",line))){
                list[str] division = split("/*",line);
                if (trim(division[0]) != ""){
                    line = trim(division[0]);
                    print("non-empty line pre-(/*)");
                    // lines += trim(division[0]);
                }
                else{
                    continue;
                }
            }

        }
        // Check for (*/)
        if (openComment && containsMultilineCommentClosure(line)){
            println("cond2");
            openComment = false;
            list[str] division = split("*/",line);
            println(division);
            if (trim(division[1]) != ""){
                print("non-empty line post-(*/)");
                lines += trim(division[1]);
            }
        }

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
        // str line = trim(rawLine);
        // Skip empty lines ("")
        if (lineIsEmpty(line)) continue;
        // Skip lines if they start with a comment (//)
        if (startsWithSinglelineComment(line)) continue;

        // // Skip lines starting with a multiline comment
        // if (startsWithMultilineCommentOpen(line)) {
        //     // Don't skip subsequent lines if comment also closes
        //     if (containsMultilineCommentClosure(line)) continue;

        //     // But do skip subsequent lines if it doesn't
        //     multilineComment = true;
        //     continue;
        // }

        // // Handle case of inline multiline comment opening
        // if (containsMultilineCommentOpen(line)) {
        //     // Do count towards total
        //     nLines += 1;

        //     // Don't skip subsequent lines if comment also closes
        //     if (containsMultilineCommentClosure(line)) continue;

        //     // But do skip subsequent lines if it doesn't
        //     multilineComment = true;
        //     continue;
        // }

        // // Handle case of ongoing multiline comment
        // if (multilineComment) {
        //     if (containsMultilineCommentClosure(line)) {
        //         // Count subsequent lines again starting from next line
        //         multilineComment = false;
        //     }
        //     continue;
        // }

        // Any non-comment, non-empty case
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
