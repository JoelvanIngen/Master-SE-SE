module Main

import IO;
import List;
import Location;
import Set;
import String;
import Map;
import lang::java::m3::AST;
import lang::java::m3::Core;

int main() {
    asts = getASTs(|project://smallsql0.21_src/|);
    set[loc] locations = genFileList(asts);
    println(locations);
    println(size(locations));
    println(countLines(locations));
    astsUnitSizeRisk(asts);
    return 0;
}



list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

/**
 * Generates a set containing all files in the AST
 */
set[loc] genFileList(list[Declaration] asts) {
    return {decl.src | decl <- asts};
}

/**
 * Counts and adds lines for all files in a set of locations
 */
int countLines(set[loc] locations) {
    return sum([countLinesSingleFile(l) | l <- locations]);
}

/**
 * Counts the amount of lines in a single file
 *
 *  TODO:
 *  - Account for comment opening (/*) starting inside a string, and thus not
 *    actually opening a comment
 *  - Account for comment closure (* /) starting before a (/*) on the same
 *    line, (is atm counted as a multiline comment being terminated on the
 *    same line as it is opened)
 *  - Account for a line starting with a multiline comment, having that
 *    comment closed on the same line, and then writing code after that.
 *    This should be considered a war crime, but is technically possible
 *  - Actually, same thing goes for any line containing code after closure
 *  - Account for a comment closure happening, and then a comment opening on
 *    the same line
 */
int countLinesSingleFile(loc location) {
    int nLines = 0;
    bool multilineComment = false;

    for (line <- readFileLines(location)) {
        // Skip empty lines
        if (lineIsEmpty(line)) continue;

        // Skip lines if they start with a comment
        if (startsWithSinglelineComment(line)) continue;

        // Skip lines starting with a multiline comment
        if (startsWithMultilineCommentOpen(line)) {
            // Don't skip subsequent lines if comment also closes
            if (containsMultilineCommentClosure(line)) continue;

            // But do skip subsequent lines if it doesn't
            multilineComment = true;
            continue;
        }

        // Handle case of inline multiline comment opening
        if (containsMultilineCommentOpen(line)) {
            // Do count towards total
            nLines += 1;

            // Don't skip subsequent lines if comment also closes
            if (containsMultilineCommentClosure(line)) continue;

            // But do skip subsequent lines if it doesn't
            multilineComment = true;
            continue;
        }

        // Handle case of ongoing multiline comment
        if (multilineComment) {
            if (containsMultilineCommentClosure(line)) {
                // Count subsequent lines again starting from next line
                multilineComment = false;
            }
            continue;
        }

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
    return startsWith(trim(line), "//");
}

/**
 * Determines whether an LOC starts with a comment opening (/*)
 * Trims leading whitespace
 * Should NOT count as a line of code for counting purposes,
 * and subsequent lines should also not count until comment closure (* /)
 */
bool startsWithMultilineCommentOpen(str line) {
    return startsWith(trim(line), "/*");
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


/// TESTS

test bool test_genFileList_noDuplicateFiles() {
    asts = getASTs(|project://smallsql0.21_src/|);
    set[loc] locations = genFileList(asts);

    for (loc1 <- locations, loc2 <- locations) {
        if (loc1 == loc2) {
            // The for loop will also pair each location with itself, we skip
            // identical locs (only interested in identical file).
            // The properties of a `set` should already guarantee
            // no identical locs exist
            continue;
        }

        if (isSameFile(loc1, loc2)) {
            println("Duplicate file found for locations <loc1> and <loc2>");
            return false;
        }
    }

    return true;
}
