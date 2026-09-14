#!/bin/bash

mkdir -p results/accessrefinery_miner_compare_results

# compare Web Access Analyzer with AccessRefinery
sh tools/compare.sh archive_results/accessanalyzer_cli/Correctness/ \
    archive_results/accessrefinery_bdd_miner_10rs/Correctness/ \
    results/accessrefinery_miner_compare_results/Correctness_AccessRefinery_with_WebAccessAnalyzer.log

sh tools/compare.sh archive_results/accessanalyzer_cli/Scalability_05Keys/ \
    archive_results/accessrefinery_bdd_miner_10rs/Scalability_05Keys/ \
    results/accessrefinery_miner_compare_results/Scalability_05Keys_AccessRefinery_with_WebAccessAnalyzer.log

sh tools/compare.sh archive_results/accessanalyzer_cli/Scalability_06Keys/ \
    archive_results/accessrefinery_bdd_miner_10rs/Scalability_06Keys/ \
    results/accessrefinery_miner_compare_results/Scalability_06Keys_AccessRefinery_with_WebAccessAnalyzer.log

# compare Web AccessRefinery Irefinery BDD with AccessRefinery Irefinery SAT
sh tools/compare.sh archive_results/accessrefinery_bdd_miner_10rs/Correctness/  \
    archive_results/accessrefinery_sat_miner_10rs/Correctness/ \
    results/accessrefinery_miner_compare_results/Correctness_MCI_AccessRefinery_BDD_with_AccessRefinery_SAT.log

sh tools/compare.sh archive_results/accessrefinery_bdd_miner_10rs/Scalability_05Keys/  \
    archive_results/accessrefinery_sat_miner_10rs/Scalability_05Keys/ \
    results/accessrefinery_miner_compare_results/Scalability_05Keys_MCI_AccessRefinery_BDD_with_AccessRefinery_SAT.log

sh tools/compare.sh archive_results/accessrefinery_bdd_miner_10rs/Scalability_06Keys/  \
    archive_results/accessrefinery_sat_miner_10rs/Scalability_06Keys/ \
    results/accessrefinery_miner_compare_results/Scalability_06Keys_MCI_AccessRefinery_BDD_with_AccessRefinery_SAT.log

# compare Web AccessRefinery IReducer BDD with AccessRefinery IReducer SAT
sh tools/compare.sh archive_results/accessrefinery_bdd_reducer_10rs/Correctness/  \
    archive_results/accessrefinery_sat_reducer_3rs/Correctness/ \
    results/accessrefinery_miner_compare_results/Correctness_RRI_AccessRefinery_BDD_with_AccessRefinery_SAT.log

sh tools/compare.sh archive_results/accessrefinery_bdd_reducer_10rs/Scalability_05Keys/  \
    archive_results/accessrefinery_sat_reducer_3rs/Scalability_05Keys/ \
    results/accessrefinery_miner_compare_results/Scalability_05Keys_RRI_AccessRefinery_BDD_with_AccessRefinery_SAT.log

sh tools/compare.sh archive_results/accessrefinery_bdd_reducer_10rs/Scalability_06Keys/  \
    archive_results/accessrefinery_sat_reducer_3rs/Scalability_06Keys/ \
    results/accessrefinery_miner_compare_results/Scalability_06Keys_RRI_AccessRefinery_BDD_with_AccessRefinery_SAT.log
