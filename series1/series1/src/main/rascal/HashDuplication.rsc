module HashDuplication

import Config;
import IO;
import LinesOfCode;
import List;
import Map;
import Set;
import String;
import Volume;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::Math;
import util::Progress;

alias line_t = str;
alias file_t = list[line_t];
alias line_loc_t = tuple[str, int];  // file path and index

/**
 * Determines and grades code duplication in the given codebase
 * @param asts: a list of ASTs to analyse
 * @param printDetails: optional boolean to print more debug information
 * @return: the final grade for the codebase: 1-5 for --, -, 0, +, ++ respectively
 */
int duplicationScore(list[Declaration] asts, bool printDetails=false) {
    fileLocs = genFileList(asts);

    list[str] fileNames = [];
    list[file_t] filesContents = [];

    int totalLOC = 0;

    for (loc fileLoc <- fileLocs) {
        file_t fileContents = cleanLines(fileLoc);

        fileNames += [fileLoc.path];
        filesContents += [fileContents];

        totalLOC += size(fileContents);
    }

    int numDuplicates = numberOfDuplicateLines(filesContents, fileNames);
    real fraction = toReal(numDuplicates) / toReal(totalLOC);

    int grade = gradeDuplicateFraction(fraction);

    if (printDetails) {
        println("TOTAL LOC     : <totalLOC>");
        println("DUPLICATE LOC : <numDuplicates>");
        println("FRACTION DUP  : <fraction>");
        println("GRADE 1-5     : <grade>");
    }

    return grade;  // TODO: Return final score instead
}

/**
 * Handles a single file, adding new detected duplicated lines and
 * comparing both against the current file and the previous files.
 * @param file: a list of strings that represent all file lines
 * @param filePath: the path to the file, used as identifier
 * @param cmap: content map, containing lines and their locations from previous files
 * @param duplicatesStorage: previously found matches
 */
tuple[map[line_t, set[line_loc_t]], set[line_loc_t]] duplicatesHandleSingleFile(file_t file, str filePath, map[line_t, set[line_loc_t]] cmap, set[line_loc_t] duplicatesStorage) {
    int index = 0;

    // Maps the locations of the code lines of found matches to the ongoing match length
    map[line_loc_t, int] tracker = ();

    for (line <- file) {
        line = removeWhitespace(line);

        if (!(line in cmap)) {
            // Add line to contents map so it can be found in later iterations
            cmap[line] = {<filePath, index>};

            // Add ongoing matches because all streaks ended
            duplicatesStorage = appendToResults(filePath, index, duplicatesStorage, tracker);

            // Reset tracker
            tracker = ();

            index += 1;
            continue;
        }

        // If code reaches here, these line contents are already in the map

        // Find the identical lines that occurred earlier
        // and retrieve their locations
        set[line_loc_t] earlierOccurrences = cmap[line];

        // Handle partial matches that were already being tracked
        if (size(tracker) > 0) {
            // For all streaks that still matche this iteration, we increment and keep tracking them
            map[line_loc_t, int] newTracker = ();
            for (candidate:<candPath, int candIndex> <- tracker) {
                nextCand = <candPath, candIndex + 1>;
                if (nextCand in earlierOccurrences) {
                    // Lines are still matching; add to new tracker and
                    // increment match length
                    newTracker[nextCand] = tracker[candidate] + 1;
                }
            }

            // Find duplication lengths of previous candidates that
            // no longer match, count them if they exceed threshold
            terminatedStreaks = findTerminated(tracker, newTracker);
            duplicatesStorage = appendToResults(filePath, index, duplicatesStorage, terminatedStreaks);

            // Update tracker with renewed candidates
            tracker = newTracker;
        }

        // Add new matches with length = 1 (single matching line so far)
        for (matchLocation <- earlierOccurrences) {
            // Skip partial matches that already have been incremented
            if (matchLocation in tracker) continue;

            tracker[matchLocation] = 1;
        }

        // Add location of current line to set
        cmap[line] += {<filePath, index>};

        index += 1;
    }

    // Add ongoing matches
    duplicatesStorage = appendToResults(filePath, index, duplicatesStorage, tracker);

    return <cmap, duplicatesStorage>;
}

/**
 * Finds and counts the amount of duplicate lines in the entire codebase
 * @param files: a list containing all file contents, which itself are lists of strings
 * @param filePaths: a list of all the paths to the files, used to distinghuish between files
 * @return: the amount of duplicates across the entire codebase
 */
int numberOfDuplicateLines(list[file_t] files, list[str] filePaths) {
    // Create progressbar so the script doesn't seem frozen for ages on big codebases
    int fileCount = size(files);
    <pbarUpdate, pbarTerminate> = progressBar(fileCount, prefix="File: ");

    map[line_t, set[line_loc_t]] cmap = ();

    // Stores all lines that have been marked as `duplicate`
    set[line_loc_t] duplicatesStorage = {};

    for (<index, file, filePath> <- zip3([1 .. size(files)+1], files, filePaths)) {
        <cmap, duplicatesStorage> = duplicatesHandleSingleFile(file, filePath, cmap, duplicatesStorage);

        // Spaces are necessary so the line is fully overwritten if filepath is shorter than previous
        pbarUpdate("File <index>/<fileCount>: <filePath>                            ");
    }

    pbarTerminate();

    return size(duplicatesStorage);
}

/**
 * Adds a found duplicate range to the results set, ensuring uniqueness.
 * Only adds ranges that exceed threshold.
 * @param filePath: the path of the file that is currently being processed
 * @param currIndex: the current index in the currently processed file
 * @param acc: the existing, previously found results
 * @param foundMatches: the terminated streaks that need to be added if they pass the threshold
 * @return: the results map updated with the new, eligable results
 */
set[line_loc_t] appendToResults(str filePath, int currIndex, set[line_loc_t] acc, map[line_loc_t, int] foundMatches) {
    for (candidate <- foundMatches) {
        int length = foundMatches[candidate];
        if (length >= DUPLICATION_LENGTH_TRESHOLD()) {
            // Add all duplicate-marked lines
            for (i <- [currIndex - length .. currIndex]) {
                acc += {<filePath, i>};
            }
        }
    }

    return acc;
}

/**
 * Finds and returns any streak that was valid previous iteration, but no
 * longer matches on this iteration.
 * @param oldTracker: the previous iteration's tracker map
 * @param newTracker: this iteration's tracker map
 * @return: all matches from previous iteration that are no longer found in current iteration
 */
map[line_loc_t, &V] findTerminated(map[line_loc_t, &V] oldTracker,
                                   map[line_loc_t, &V] newTracker) {
    return (location : oldTracker[location]
            | location <- oldTracker,
            !(<location[0], location[1] + 1> in newTracker));
}

/**
 * Takes the fraction of duplicated code and returns a score.
 * ++, +, 0, -, -- are returned as 5, 4, 3, 2, 1 respectively.
 * @param f: fraction of duplicated code
 * @return: score
 */
int scoreDuplicateFraction(real f) {
    <pp, p, z, m> = DUPLICATION_FRACTIONS_BOUNDARIES();

    if (f <= pp) return 5;
    if (f <= p) return 4;
    if (f <= z) return 3;
    if (f <= m) return 2;
    return 1;
}

/**
 * Removes whitespace from a string
 * @param s: string to remove whitespace from
 * @return: string without whitespace
 */
str removeWhitespace(str s) {
    return replaceAll(s, " ", "");
}
