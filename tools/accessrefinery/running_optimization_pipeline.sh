#!/bin/bash

# The optimization-pipeline runs behind the journal-extension figures: the 20-round
# Pruning Reducer folder that Figures 18 and 19 read, and the two 10-round folders
# that Figures 18 and 20 read.
#
# The stage is selected on the command line (see README, "Using AccessRefinery");
# nothing is on by default, so a run's flags are exactly the stages it adds:
#
#   -p                Pruning Reducer - Original + the essential-finding pre-filter
#                                       in the intent reducer
#   -o                MiningOptimized - the intent-mining optimization alone
#   -p -i             Incremental MCP - Pruning Reducer + the miner's refinement-DAG
#                                       node construction and BFS early-exit, and
#                                       the incremental EC engine below it
#   -c                Cross-policy shared MCPFactory - with -i on, one factory
#                                       drives every policy of a round instead of
#                                       one per policy. Run here because the
#                                       archived Incremental MCP folder was measured
#                                       that way; it selects no stage of its own.
#
# The Baseline these stages are compared against is not run here: it is the
# conference-version BR run, which ships as
# archive_results/accessrefinery_bdd_reducer_10rs/ and which README's
# `cp -r archive_results/accessrefinery_bdd_*rs results/` step copies in.
#
# What is run, and what reads each folder:
#
#   results/accessrefinery_bdd_reducer_PruningReducer_20rs/  (-p)       20 rounds
#   results/accessrefinery_bdd_reducer_optimized_10rs/       (-p -i -c) 10 rounds
#   results/accessrefinery_bdd_reducer_ECPercentage_10rs/    (-o)       10 rounds
#                                       -> tools/figures/extract_RQ7-ReducingPruning.sh
#                                          (Figure 19: p1_05.dat, p1_06.dat, rw_p1.dat)
#                                       -> tools/figures/extract_RQ7-MiningPruning.sh
#                                          (Figure 18: p2_05.dat, p2_06.dat, rw_p2.dat)
#                                       -> tools/figures/extract_RQ8-OverviewBars.sh
#                                          (Figure 20: enc_05.dat, enc_06.dat)
#                                       -> tools/figures/extract_RQ3-{Mining,Reducing}.sh
#                                          (Figures 14 and 15 read the BR run copied in
#                                           from archive_results/ and this optimized
#                                           folder)
#
# Only the folder sizes differ between the two round counts: a 10-round run is
# about half the wall clock of a 20-round one, which is why the 20-round folder is
# kept to the single stage Figures 18 and 19 read.
#
# Every run covers the same datasets and writes its `result/` tree to
# results/<folder>/, the working directory the extraction script above reads.
#
# The shipped copies of these three folders live in archive_results_journal/, which
# this script never touches; check the regenerated results/ against them.
#
# The real-world corpus is stored under the folder name "RW" inside each stage's
# results directory. The corpus itself is not public, for commercial reasons, so
# data/RW/ ships empty and the RW run below is skipped unless the folder has been
# restored locally.

# JVM options, which must precede -jar. None is needed by the stages below; the stage
# flags, by contrast, are passed to run_stage and land after -jar.
JAVA_OPTS=""

run_stage() {
  local name=$1 round=$2; shift 2
  if [ -d data/RW/ ]; then
    java $JAVA_OPTS -jar target/accessrefinery-1.0.jar -m -r --round "$round" "$@" -f data/RW/
  fi
  java $JAVA_OPTS -jar target/accessrefinery-1.0.jar -m -r --round "$round" "$@" -f data/Scalability_05Keys/
  java $JAVA_OPTS -jar target/accessrefinery-1.0.jar -m -r --round "$round" "$@" -f data/Scalability_06Keys/
  # Replace the previous working copy; the pristine one stays in
  # archive_results_journal/. `mv result dst` would nest the tree inside dst.
  rm -rf "results/$name"
  mv result "results/$name"
}

# --- 20 rounds -----------------------------------------------------------------
# Pruning Reducer - Original + essential-finding pre-filter
run_stage accessrefinery_bdd_reducer_PruningReducer_20rs 20 -p

# --- 10 rounds -----------------------------------------------------------------
# ADD_BEGIN_JOURNAL
# Incremental MCP - Pruning Reducer + the refinement-DAG miner and the incremental
# EC engine with the cross-policy shared factory.
# -c is pinned because this stage's archive was measured with the cross-policy
# shared factory: without it every policy gets its own fresh factory, which would
# make the regenerated stage disagree with
# archive_results_journal/accessrefinery_bdd_reducer_optimized_10rs/ on every
# timing column (on 05Keys the labels column alone is 2-8x).
run_stage accessrefinery_bdd_reducer_optimized_10rs 10 -p -i -c
# END_BEGIN_JOURNAL

# ECPercentage - the intent-mining optimization alone, the configuration Figure
# 20 reads. -o turns on the miner's refinement-DAG node construction and BFS
# early-exit without the incremental EC engine below it, so the cross-policy
# shared factory of the stage above does not apply and no -c is passed.
run_stage accessrefinery_bdd_reducer_ECPercentage_10rs 10 -o
