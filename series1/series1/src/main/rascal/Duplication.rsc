module Duplication

import IO;
import List;
import String;

import lang::java::m3::Core;
import lang::java::m3::AST;


// Declaration getAST(str line) {
//     return createAstFromString(|project://smallsql0.21_src/|, line, true);
// }

// Check if 2 lines are the same
bool repeatedLine(str line1, str line2){
    return line1 == line2 ? true : false;
}

// Loop through the whole file
// return: list of [repeated lines of code]
list[list[str]] findDuplicates(list[list[str]] sourceCode){
    list[list[str]] final = [];
    totalRepeatedLines = [];

    for (file <- sourceCode){
        for (line <- file){
            int count = 0;
            list [str] repearedLines = [];

            // Iterate again
            for (file2 <- sourceCode){
                for (line2 <- file2){

                    if (repeatedLine(line, line2)){
                        count += 1;
                    }
                    else{
                        if (count >= 6){
                            final += repearedLines;
                            totalRepeatedLines += size(repearedLines);
                        }
                        count = 0;
                        repearedLines += [];
                    }
                }
            }
        }
    }

    return final
}


list[list[str]] findDuplicateBlocksInfile(list[str] lines){}
