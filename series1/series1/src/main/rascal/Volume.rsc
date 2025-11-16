
module Volume

import IO;
import List;
import Set;
import lang::java::m3::Core;
import lang::java::m3::AST;

import Config;
import Helpers;


/**
 * Generates a set containing all files in the AST
 */
set[loc] genFileList(list[Declaration] asts) {
    return {decl.src | decl <- asts};
}

/**
 * Counts (cleaned) lines in files
 * @param locs: list of loc of all the files to read and process
 * @return: total amount of lines in all files
 */
int countLines(set[loc] locs) {
    int counter = 0;
    for (loc l <- locs) counter += size(cleanLines(l));
    return counter;
}

/**
 * Assigns the score for the determined code volume
 * @param n: amount of code lines
 * @return 1 - 5 for -- to ++ respectively
 */
int scoreVolume(int n) {
    <pp, p, z, m> = VOLUME_SCORE_BOUNDARIES();
    if (n <= pp) return 5;
    if (n <= p) return 4;
    if (n <= z) return 3;
    if (n <= m) return 2;
    return 1;
}

/**
 * Determines the volume score for a list of ASTs
 * @param asts: list of Declaration (list of ASTs)
 * @param verbose: optional boolean to print debug output
 * @return: 1 - 5 for -- to ++ respectively
 */
int calcVolumeScore(list[Declaration] asts, bool verbose = false) {
    println("Computing Volume metric");

    fileLocs = genFileList(asts);
    int numLines = countLines(fileLocs);

    if (verbose) println("Total LOC in codebase: <numLines>");

    return scoreVolume(numLines);
}
