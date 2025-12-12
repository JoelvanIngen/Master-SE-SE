module AstBased::SequenceHelpers

import Configuration;
import Node;

import AstBased::Location;

bool isSequenceNode(node n) = isFullSequence(n) || isPermutationSequence(n);
bool isFullSequence(node n) = getName(n) == confFullSequenceNodeName();
bool isPermutationSequence(node n) = getName(n) == confPermutatedSequenceNodeName();

/**
 * Checks whether the second argument is a permutated version of the first argument.
 * Ensures first argument is a full sequence and second argument is permutation
 * Then checks whether the two sequences span the same location
 */
bool isPermutationOfSequence(node seq, node perm) =
    isFullSequence(seq) && isPermutationSequence(perm) && getSrc(seq) == getSrc(perm);
