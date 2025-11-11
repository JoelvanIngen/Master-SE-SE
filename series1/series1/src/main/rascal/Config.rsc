module Config

// https://softwareimprovementgroup.com/wp-content/uploads/SIG-TUViT-Evaluation-Criteria-Trusted-Product-Maintainability-Guidance-for-producers.pdf?_gl=1*syaptg*_gcl_au*MTI0MTM4NDk4OS4xNzYyMDg5MDMw
tuple[int, int, int] UNIT_SIZE_RISK_BOUNDRIES(){
    return <15, 30, 60>;
}

// From the main paper
tuple[int, int, int] COMPLEXITY_RISK_BOUNDRIES(){
    return <10, 20, 50>;
}

// From the main paper
tuple[int, int, int, int] VOLUME_SCORE_BOUNDRIES(){
    return <66000, 246000, 665000, 1310000>;
}

// Not sure this is the best way to do it
// If it is, make sure to explain this constant
tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]] COMPLEXITY_SCORE_BOUNDRIES(){
    return <<25, 0, 0>, <30, 5, 0>, <40, 10, 0>, <50, 15, 5>>;
}

