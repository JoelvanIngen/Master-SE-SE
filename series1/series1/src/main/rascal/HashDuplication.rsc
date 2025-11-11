module HashDuplication

import IO;
import List;
import Map;
import Set;
import Volume;
import lang::java::m3::AST;
import lang::java::m3::Core;

alias line_t = str;
alias file_t = list[line_t];
alias line_loc_t = tuple[str, int];  // file path and index

int THRESHOLD = 2;

/**
 * Determines and grades code duplication in the given codebase
 */
int duplicationScore(list[Declaration] asts) {
    fileLocs = genFileList(asts);

    list[str] fileNames = [];
    list[list[str]] filesContents = [];

    int counter = 0;
    for (loc fileLoc <- fileLocs) {
        str fileName = fileLoc.path;
        fileNames += [fileName];
        list[str] fileContents = readFileLines(fileLoc);
        filesContents += [fileContents];
        counter += size(fileContents);
    }

    return numberOfDuplicateLines(filesContents, fileNames);
}

tuple[map[line_t, set[line_loc_t]], set[line_loc_t]] duplicatesHandleSingleFile(file_t file, str filePath, map[line_t, set[line_loc_t]] cmap, set[line_loc_t] duplicatesStorage) {
    int index = 0;

    // Maps the locations of the code lines of found matches to the ongoing match length
    map[line_loc_t, int] tracker = ();

    for (line <- file) {
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

        // Handle case in which we already found at least one partial match
        if (size(tracker) > 0) {
            // Find all streaks that we were tracking, and check if they still
            // match for this iteration. If so, we increment them and keep tracking them
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

int numberOfDuplicateLines(list[file_t] files, list[str] filePaths) {
    map[line_t, set[line_loc_t]] cmap = ();
    int index = 0;

    // Stores all lines that have been marked as `duplicate`
    set[line_loc_t] duplicatesStorage = {};

    for (<file, filePath> <- zip2(files, filePaths)) {
        <cmap, duplicatesStorage> = duplicatesHandleSingleFile(file, filePath, cmap, duplicatesStorage);
        index += 1;
    }

    return size(duplicatesStorage);
}

/**
 * Adds a found duplicate range to the results set, ensuring uniqueness.
 * Only adds ranges that exceed threshold.
 */
set[line_loc_t] appendToResults(str filePath, int currIndex, set[line_loc_t] acc, map[line_loc_t, int] newRes) {
    for (candidate <- newRes) {
        int length = newRes[candidate];
        if (length >= THRESHOLD) {
            // Add all duplicate-marked lines
            for (i <- [currIndex - length .. currIndex]) {
                acc += {<filePath, i>};
            }
        }
    }

    return acc;
}

map[line_loc_t, &V] findTerminated(map[line_loc_t, &V] oldTracker, map[line_loc_t, &V] newTracker) {
    map[line_loc_t, &V] terminatedStreaks = ();
    for (<filePath, index> <- oldTracker) {
        if (!(<filePath, index + 1> in newTracker)) {
            terminatedStreaks[<filePath, index>] = oldTracker[<filePath, index>];
        }
    }
    return terminatedStreaks;
}
