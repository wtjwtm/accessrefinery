#!/bin/bash

# Compare AccessAnalyzer reimplementation outputs with AccessRefinery BDD outputs.
# Results are stored in `results/accessanalyzer_miner_compare_results_with_refinery/`.

mkdir -p results/accessanalyzer_miner_compare_results_with_refinery

# Compare CVC5 miner outputs with AccessRefinery BDD outputs
bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_miner_1rs/Correctness \
    results/accessrefinery_bdd_miner_10rs/Correctness \
    results/accessanalyzer_miner_compare_results_with_refinery/Correctness_AccessRefinery_with_AccessAnalyzerCVC5Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_miner_1rs/Scalability_05Keys/ \
    results/accessrefinery_bdd_miner_10rs/Scalability_05Keys/ \
    results/accessanalyzer_miner_compare_results_with_refinery/Scalability_05Keys_AccessRefinery_with_AccessAnalyzerCVC5Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_miner_1rs/Scalability_06Keys/ \
    results/accessrefinery_bdd_miner_10rs/Scalability_06Keys/ \
    results/accessanalyzer_miner_compare_results_with_refinery/Scalability_06Keys_AccessRefinery_with_AccessAnalyzerCVC5Miner.log

# Compare Z3 miner outputs with AccessRefinery BDD outputs
bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_miner_1rs/Correctness/ \
    results/accessrefinery_bdd_miner_10rs/Correctness/ \
    results/accessanalyzer_miner_compare_results_with_refinery/Correctness_AccessRefinery_with_AccessAnalyzerZ3Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_miner_1rs/Scalability_05Keys/ \
    results/accessrefinery_bdd_miner_10rs/Scalability_05Keys/ \
    results/accessanalyzer_miner_compare_results_with_refinery/Scalability_05Keys_AccessRefinery_with_AccessAnalyzerZ3Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_miner_1rs/Scalability_06Keys/ \
    results/accessrefinery_bdd_miner_10rs/Scalability_06Keys/ \
    results/accessanalyzer_miner_compare_results_with_refinery/Scalability_06Keys_AccessRefinery_with_AccessAnalyzerZ3Miner.log
