#!/bin/bash

# Compare AccessAnalyzer reducer outputs (CVC5/Z3) with AccessRefinery BDD reducer.
# Outputs are written to `results/accessanalyzer_reducer_compare_result/`.

mkdir -p results/accessanalyzer_reducer_compare_result

# Compare CVC5 reducer outputs
bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_reducer_1rs/Correctness/ \
    results/accessrefinery_bdd_reducer_10rs/Correctness/ \
    results/accessanalyzer_reducer_compare_result/Correctness_AccessRefinery_with_AccessAnalyzerCVC5Reducer.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_reducer_1rs/Scalability_05Keys/ \
    results/accessrefinery_bdd_reducer_10rs/Scalability_05Keys/ \
    results/accessanalyzer_reducer_compare_result/Scalability_05Keys_AccessRefinery_with_AccessAnalyzerCVC5Reducer.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_reducer_1rs/Scalability_06Keys/ \
    results/accessrefinery_bdd_reducer_10rs/Scalability_06Keys/ \
    results/accessanalyzer_reducer_compare_result/Scalability_06Keys_AccessRefinery_with_AccessAnalyzerCVC5Reducer.log

# Compare Z3 reducer outputs
bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_reducer_1rs/Correctness/ \
    results/accessrefinery_bdd_reducer_10rs/Correctness/ \
    results/accessanalyzer_reducer_compare_result/Correctness_AccessRefinery_with_AccessAnalyzerZ3Reducer.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_reducer_1rs/Scalability_05Keys/ \
    results/accessrefinery_bdd_reducer_10rs/Scalability_05Keys/ \
    results/accessanalyzer_reducer_compare_result/Scalability_05Keys_AccessRefinery_with_AccessAnalyzerZ3Reducer.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_reducer_1rs/Scalability_06Keys/ \
    results/accessrefinery_bdd_reducer_10rs/Scalability_06Keys/ \
    results/accessanalyzer_reducer_compare_result/Scalability_06Keys_AccessRefinery_with_AccessAnalyzerZ3Reducer.log
