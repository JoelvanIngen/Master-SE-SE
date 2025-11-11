
module Volume

import IO;
import Set;

import lang::java::m3::Core;
import lang::java::m3::AST;


/**
 * Generates a set containing all files in the AST
 */
set[loc] genFileList(list[Declaration] asts) {
    return {decl.src | decl <- asts};
}

// use VOLUME_SCORE_VALUES from Config.rsc