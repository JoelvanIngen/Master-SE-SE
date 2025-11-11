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

// map(list[str], int) findDuplicateBlocksInfile(list[str] lines){
//     int b = 0;
//     int c = 1;
//     while(b < size(lines)){
//         int b_def = b;

//         while(c < size(lines)){

//         }
//     }
// }

tuple[list[str], set[int]] iterateTillTheSame(list[str] lines, int b0, int c0){
    set[int] indexDuplicated = {};
    list[str] linesDuplicates = [];

    int b = b0;
    int c = c0;

    while ((b < size(lines)) && c < size(lines) && (repeatedLine(lines[b], lines[c]))){
        indexDuplicated += {c};
        linesDuplicates += [lines[c]];
        b += 1;
        c += 1;
    }

<<<<<<< HEAD
    println(indexDuplicated);
    println(linesDuplicates);
    int blockLength = b - b0;
    println(blockLength);

    // Last index increment did not meet the condition line1==line2:
    // b -= 1;
    // c -= 1;

    return <linesDuplicates, indexDuplicated>;

=======
    return final;
>>>>>>> main
}

