module TESTS

import IO;

import lang::java::m3::AST;
import lang::java::m3::Core;

import Main;

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