module Aliases

// Represents a line of text
alias Line = str;

// Represents a section of multiple lines
alias Section = list[Line];

// Represents a file as list of Line
alias File = list[Line];

// Represents a (by definition unique) pair of file path, line number
// Not to be confused with built-in loc
alias Location = tuple[str, int];

// Represents all file lines that have been encountered before
// and the location on which the section starts
alias HistoryMap = map[str, list[Location]];

// Storing clone groups
alias CloneLocs = list[loc];
alias CloneMap = map[node, CloneLocs];
