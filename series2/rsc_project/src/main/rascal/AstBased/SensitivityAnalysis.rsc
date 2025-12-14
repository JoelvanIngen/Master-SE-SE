module AstBased::SensitivityAnalysis

import IO;
import List;
import Location;
import Map;
import String;

import util::Benchmark;            // getMilliTime() :contentReference[oaicite:1]{index=1}

import lang::java::m3::AST;
import lang::java::m3::Core;

import Aliases;
import AstBased::Detector;
import AstBased::Output;           // calculateTotalLOC, calculateCloneLines, calculateLines, formatLoc

/**
  The sensitivity analysis module was implemented with the assistance
  of ChatGPT (OpenAI), which was used to generate an initial version of the
  code. The final implementation was reviewed, corrected, and
  integrated by the authors of this project.”
 */


/**
 * Load Java ASTs like Main.rsc does (Maven project).
 */
list[Declaration] getASTs(loc projectLocation) {
  M3 model = createM3FromMavenProject(projectLocation);
  return [ createAstFromFile(f, true)
         | f <- files(model.containment), isCompilationUnit(f) ];
}

/**
 * CSV header row.
 */
str csvHeader() =
  "massThreshold,minWindow,cloneType,"
  + "cloneClasses,clonesTotal,biggestCloneLines,biggestClassMembers,"
  + "totalLOC,clonedLOC,clonedPct,runtimeMs";


/**
 * Convert stats to a CSV row.
 */
str csvRow(int massThreshold, int minWindow, str cloneType,
           int cloneClasses, int clonesTotal, int biggestCloneLines, int biggestClassMembers,
           int totalLOC, int clonedLOC, num clonedPct, int runtimeMs) {
  return "<massThreshold>,<minWindow>,<cloneType>,"
       + "<cloneClasses>,<clonesTotal>,<biggestCloneLines>,<biggestClassMembers>,"
       + "<totalLOC>,<clonedLOC>,<clonedPct>,<runtimeMs>";
}


/**
 * Compute the same style of stats as Output.writeCloneClasses, but returned as scalars.
 */
tuple[int cloneClasses,
      int clonesTotal,
      int biggestCloneLines,
      int biggestClassMembers] computeCloneStats(CloneMap groups) {

  int clonesTotal = 0;
  int biggestCloneLines = 0;
  int biggestClassMembers = 0;

  for (node key <- groups) {
    list[loc] members = groups[key];
    int classSize = size(members);
    clonesTotal += classSize;

    if (classSize > biggestClassMembers)
      biggestClassMembers = classSize;

    if (classSize > 0) {
      int cloneLines = calculateLines(members[0]); // from Output.rsc
      if (cloneLines > biggestCloneLines)
        biggestCloneLines = cloneLines;
    }
  }

  return <size(groups), clonesTotal, biggestCloneLines, biggestClassMembers>;
}


/**
 * Run sensitivity analysis for fixed massThreshold values and write results to CSV.
 *
 * cloneType must be "I", "II", or "III".
 */
void runMassThresholdSensitivity(loc projectLocation,
                                 bool isMaven = true,
                                 str cloneType = "I",
                                 int minWindow = 3,
                                 loc outFile =
                                   |project://rsc_project/src/main/rascal/AstBased/Results/sensitivity_mass_threshold.csv|) {

  // fixed thresholds as requested
  list[int] thresholds = [5, 10, 25, 50, 80, 100];

  // ensure output location exists
  if (!exists(outFile)) {
    mkDirectory(outFile.parent);
    touch(outFile);
  }

  // build ASTs once
  list[Declaration] asts = getASTs(projectLocation);

  // compute total LOC once (expensive IO)
  int totalLOC = calculateTotalLOC(asts);

  str csv = csvHeader() + "\n";

  for (int t <- thresholds) {
    CloneMap clones = ();

    int t0 = getMilliTime();       // Rascal timing API :contentReference[oaicite:2]{index=2}

    if (cloneType == "I") {
      clones = detectClonesI(asts, t, minWindow);
    }
    else if (cloneType == "II") {
      clones = detectClonesII(asts, t, minWindow);
    }
    else if (cloneType == "III") {
      clones = detectClonesIII(asts, t, minWindow);
    }
    else {
      throw "Unknown cloneType <cloneType>. Use \"I\", \"II\", or \"III\".";
    }

    int t1 = getMilliTime();
    int runtimeMs = t1 - t0;

    tuple[int, int, int, int] stats = computeCloneStats(clones);
    int cloneClasses        = stats[0];
    int clonesTotal         = stats[1];
    int biggestCloneLines   = stats[2];
    int biggestClassMembers= stats[3];


    int clonedLOC = calculateCloneLines(clones);
    num clonedPct = (totalLOC == 0) ? 0 : (clonedLOC / totalLOC) * 100;

    csv += csvRow(t, minWindow, cloneType,
                  cloneClasses, clonesTotal, biggestCloneLines, biggestClassMembers,
                  totalLOC, clonedLOC, clonedPct, runtimeMs) + "\n";

    println("massThreshold=<t>: classes=<cloneClasses>, clonedPct=<clonedPct>, runtimeMs=<runtimeMs>");
  }

  writeFile(outFile, csv);
  println("Sensitivity results saved to: <outFile>");
}


/**
 * Convenience entrypoint (adjust project path as needed).
 */
void main() {
  runMassThresholdSensitivity(
    |project://smallsql0.21_src/|,
    isMaven = true,
    cloneType = "I",
    minWindow = 3
  );
}
