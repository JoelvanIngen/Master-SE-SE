module Text::LineCleaning

import IO;
import String;

/**
 * Cleans the code lines.
 * Excludes:
 *         comments (single-line & multi-line)
 *         empty lines
 *         empty leading & trailing spaces
 * returns: a list of all cleaned lines from a source location, which remained
 */
list[str] cleanLines(loc location){
    list[str] lines = readFileLines(location);
    return cleanLinesFromList(lines);
}


list[str] cleanLinesFromList(list[str] lines){
    list[str] clean = [];
    bool openComment = false;

    for (line <- lines){
        str newLine = "";
        int i = 0;

        // Iterate through the line
        while (i < size(line)){
            // Multi line comment open
            if (!openComment && line[i..i+2] == "/*"){
                openComment = true;
                i += 2;
                continue;
            }

            // Multi line comment close
            if (openComment && line[i..i+2] == "*/"){
                openComment = false;
                i += 2;
                continue;
            }

            // Single line comment
            if (!openComment && line[i..i+2] == "//"){
                break;
            }

            // Regular code
            if (!openComment){
                newLine += line[i];
            }
            i += 1;
        }
        // Removing leading & training whitespaces (& indendation)
        clean += trim(newLine);
    }
    return [ cleanLine | cleanLine <- clean, cleanLine != ""];
}