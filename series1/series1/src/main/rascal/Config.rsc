module Config

/**
 * From: "SIG/TÜV NORD CERT EVALUATION CRITERIA TRUSTED PRODUCT MAINTAINABILITY: 
 * GUIDANCE FOR PRODUCERS" Version 17.0
 * https://softwareimprovementgroup.com/wp-content/uploads/SIG-TUViT-Evaluation-Criteria-Trusted-Product-Maintainability-Guidance-for-producers.pdf?_gl=1*syaptg*_gcl_au*MTI0MTM4NDk4OS4xNzYyMDg5MDMw
 */
tuple[int, int, int] UNIT_SIZE_RISK_BOUNDRIES(){
    return <15, 30, 60>;
}

/**
 * From: "A PracticCOal Model for Measuring Maintainability"
 * doi: 10.1109/QUATIC.2007.8
 */
tuple[int, int, int] COMPLEXITY_RISK_BOUNDRIES(){
    return <10, 20, 50>;
}

/**
 * From: "A Practical Model for Measuring Maintainability"
 * doi: 10.1109/QUATIC.2007.8
 */
tuple[int, int, int, int] VOLUME_SCORE_BOUNDRIES(){
    return <66000, 246000, 665000, 1310000>;
}

/**
 * From: "A Practical Model for Measuring Maintainability"
 * doi: 10.1109/QUATIC.2007.8
 *
 * Where:
 * in each inner tuple numbers represent maximum relative LOC in a given
 * risk category: <moderate, high, very high>
 * each outer tuple represents score: < ++, +, o, ->
 */
tuple[tuple[num, num, num], tuple[num, num, num], tuple[num, num, num], tuple[num, num, num]] COMPLEXITY_SCORE_BOUNDRIES(){
    return <<0.25, 0.0, 0.0>,
            <0.30, 0.5, 0.0>,
            <0.40, 0.10, 0.0>,
            <0.50, 0.15, 0.05>>;
}

int DUPLICATION_LENGTH_TRESHOLD() {
    return 6;
}

/**
 * From: "A Practical Model for Measuring Maintainability"
 * doi: 10.1109/QUATIC.2007.8
 *
 * The maximum fractions, inclusive, for each scoring category.
 * <= 0.03:   ++
 * <= 0.05:   +
 * <= 0.10:   0
 * <= 0.20:   -
 * otherwise: --
 */
tuple[real, real, real, real] DUPLICATION_FRACTIONS_BOUNDARIES() {
    return <0.03, 0.05, 0.10, 0.20>;
}
