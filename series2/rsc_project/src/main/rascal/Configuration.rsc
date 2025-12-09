module Configuration

str confFullSequenceNodeName() = "CUSTOM_slice";
str confPermutatedSequenceNodeName() = "CUSTOM_permutation";

int confMinimumSequenceLengthIterationsBeforeStop() = 10;

/**
 * Tests some basic config settings for validity
 */
test bool testConfigValidity() {
    return confFullSequenceNodeName() != confPermutatedSequenceNodeName();
}
