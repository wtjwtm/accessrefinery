#!/bin/bash

# Wrapper to compare AccessAnalyzer reimplementation miner outputs with
# the original AccessAnalyzer CLI outputs. Results written to
# `results/accessanalyzer_miner_compare_results/` as per-dataset log files.

mkdir -p results/accessanalyzer_miner_compare_results

# Compare AccessAnalyzer CVC5 miner outputs with AccessAnalyzer CLI
bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_miner_1rs/Correctness \
    results/accessanalyzer_cli/Correctness \
    results/accessanalyzer_miner_compare_results/Correctness_AccessRefinery_with_AccessAnalyzerCVC5Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_miner_1rs/Scalability_05Keys/ \
    results/accessanalyzer_cli/Scalability_05Keys/ \
    results/accessanalyzer_miner_compare_results/Scalability_05Keys_AccessRefinery_with_AccessAnalyzerCVC5Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_cvc5_miner_1rs/Scalability_06Keys/ \
    results/accessanalyzer_cli/Scalability_06Keys/ \
    results/accessanalyzer_miner_compare_results/Scalability_06Keys_AccessRefinery_with_AccessAnalyzerCVC5Miner.log

# Compare AccessAnalyzer Z3 miner outputs with AccessAnalyzer CLI
bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_miner_1rs/Correctness/ \
    results/accessanalyzer_cli/Correctness/ \
    results/accessanalyzer_miner_compare_results/Correctness_AccessRefinery_with_AccessAnalyzerZ3Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_miner_1rs/Scalability_05Keys/ \
    results/accessanalyzer_cli/Scalability_05Keys/ \
    results/accessanalyzer_miner_compare_results/Scalability_05Keys_AccessRefinery_with_AccessAnalyzerZ3Miner.log

bash tools/accessanalyzer-reimpl/compare.sh results/accessanalyzer_z3_miner_1rs/Scalability_06Keys/ \
    results/accessanalyzer_cli/Scalability_06Keys/ \
    results/accessanalyzer_miner_compare_results/Scalability_06Keys_AccessRefinery_with_AccessAnalyzerZ3Miner.log
