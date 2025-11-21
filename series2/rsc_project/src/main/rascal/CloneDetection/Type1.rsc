module CloneDetection::Type1

import Aliases;
import Helpers;
import IO;
import List;
import Map;
import Set;
import String;
import util::Progress;
import util::Math;

int THRESHOLD = 6;

/**
 * @param codebase: entire codebase with comments and empty lines removed
 * @param filePaths: all file paths of the code base in same order
 */
void findClones(list[File] codebase, list[str] filePaths, bool verbose = true) {
    HistoryMap hmap = ();

    int fileCount = size(filePaths);
    <pbarUpdate, pbarTerminate> = progressBar(fileCount, prefix="File:");

    for (<idx, File f, str fPath> <- zip3([1..size(codebase)+1], codebase, filePaths)) {
        // Spaces are necessary so the line is fully overwritten if filepath is shorter than previous
        pbarUpdate("File <idx>/<fileCount>: <fPath>                            ");

        hmap = processFile(hmap, f, fPath);
    }

    pbarTerminate();

    if (verbose) {
        int totalLOC = sum([size(f) | f <- codebase]);
        int totalDUP = size(allDuplicates(hmap));
        real fraction = toReal(totalDUP) / totalLOC;

        println("TOTAL LOC     : <totalLOC>");
        println("DUPLICATE LOC : <totalDUP>");
        println("FRACTION DUP  : <fraction>");
    }
}

HistoryMap processFile(HistoryMap hmap, File f, str fPath) {
    f = removeWhitespace(f);

    int fSize = size(f);

    // If file length is less than threshold, do nothing
    if (fSize < THRESHOLD) return hmap;

    // Iterate through lines, sliding window, and save location
    for (int idx <- [0 .. fSize - THRESHOLD + 1]) {
        Section s = f[idx .. idx + THRESHOLD];
        str key = concatSlices(s);
        hmap[key] = (hmap[key] ? []) + [<fPath, idx>];
    }

    return hmap;
}

/**
 * Somehow necessary because Rascal can hash two identical lists as
 * different hashes. Thank 5 hours of debugging for figuring that out
 */
str concatSlices(Section xs) {
    str s = "";

    for (x <- xs) {
        s += x;
        s += "|-split-|";  // For readability during debugging
    }

    return s;
}

File removeWhitespace(File f) {
    return [removeWhitespaceLine(l) | l <- f];
}

Line removeWhitespaceLine(Line l) {
    // De-escape necessary for correct replacing of \t
    l = replaceAll(deescape(l), "\t", "");
    l = replaceAll(l, " ", "");
    return l;
}

/**
 * Constructs a set of all duplicates (not originals)
 * For now mainly to test against old algorithm, maybe useful in future
 * Does not take relation between duplicates into account, just merges all
 */
set[Location] allDuplicates(HistoryMap hmap) {
    set[Location] dupLocs = {};

    for (k <- hmap) {
        list[Location] locs = hmap[k];

        if (size(locs) == 1) continue;  // No duplicates

        list[Location] dups = locs[1..];
        for (dup <- dups) {
            dupLocs += getDuplicateRanges(dup);
        }
    }

    return dupLocs;
}

/**
 * Constructs a set of duplicate locations by adding the entire threshold range
 */
set[Location] getDuplicateRanges(Location dup) {
    set[Location] dups = {};
    <fPath, line> = dup;

    for (idx <- [line .. line + THRESHOLD]) {
        dups += {<fPath, idx>};
    }

    return dups;
}
