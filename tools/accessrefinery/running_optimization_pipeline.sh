#!/bin/bash

# The optimization-pipeline runs behind the journal-extension figures: the two
# 20-round stages that Figure 18 reads, and the four 10-round folders that
# Figures 19 and 20 read.
#
# The stage is selected on the command line (see README, "Using AccessRefinery");
# nothing is on by default, so a run's flags are exactly the stages it adds:
#
#   (no stage flag)   Original        - batch engine, no optimization
#   -p                Pruning Reducer - Original + the essential-finding pre-filter
#                                       in the intent reducer
#   -o                MiningOptimized - the intent-mining optimization alone
#   -p -i             Incremental MCP - Pruning Reducer + the miner's refinement-DAG
#                                       node construction and BFS early-exit, and
#                                       the incremental EC engine below it
#
# What is run, and what reads each folder:
#
#   results/accessrefinery_bdd_reducer_Original_20rs/        (no flag)  20 rounds
#   results/accessrefinery_bdd_reducer_PruningReducer_20rs/  (-p)       20 rounds
#   results/accessrefinery_bdd_reducer_Original_10rs/        (no flag)  10 rounds
#   results/accessrefinery_bdd_reducer_PruningReducer_10rs/  (-p)       10 rounds
#   results/accessrefinery_bdd_reducer_IncrementalMCP_10rs/  (-p -i)    10 rounds
#   results/accessrefinery_bdd_reducer_MiningOptimized_10rs/ (-o)       10 rounds
#                                       -> tools/figures/extract_optimization_pipeline.sh
#                                          (Figure 18: p1_05.dat, p1_06.dat, rw_p1.dat;
#                                           Figure 19: p2_05.dat, p2_06.dat, rw_p2.dat;
#                                           Figure 20: enc_05.dat, enc_06.dat;
#                                           Figures 14 and 15 read the 10-round
#                                           Original and Incremental MCP folders)
#
# Only the folder sizes differ between the two round counts: a 10-round run is
# about half the wall clock of a 20-round one, which is why the 20-round pair is
# kept to the two stages Figure 18 needs.
#
# Every run covers the same datasets and writes its `result/` tree to
# results/<folder>/, the working directory the extraction script above reads.
#
# The shipped copies of these six folders live in archive_results_journal/, which
# this script never touches; check the regenerated results/ against them.
#
# The real-world corpus is stored under the folder name "RW" inside each stage's
# results directory. The corpus itself is not public, for commercial reasons, so
# data/RW/ ships empty and the RW run below is skipped unless the folder has been
# restored locally.

# JVM options, which must precede -jar. Only the Incremental MCP stage below sets
# any; the stage flags, by contrast, are passed to run_stage and land after -jar.
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
# Original - batch engine, no optimization
run_stage accessrefinery_bdd_reducer_Original_20rs 20

# Pruning Reducer - Original + essential-finding pre-filter
run_stage accessrefinery_bdd_reducer_PruningReducer_20rs 20 -p

# --- 10 rounds -----------------------------------------------------------------
# Original - batch engine, no optimization. No figure reads this folder today; it
# is run so that the 10-round set is complete.
run_stage accessrefinery_bdd_reducer_Original_10rs 10

run_stage accessrefinery_bdd_reducer_PruningReducer_10rs 10 -p

# ADD_BEGIN_JOURNAL
# Incremental MCP - Pruning Reducer + the refinement-DAG miner and the incremental
# EC engine with the cross-policy shared factory.
# -Dinc.independent=false is pinned because this stage's archive was measured with
# the cross-policy shared factory: as of 2026-10-09 a plain run gives every policy
# its own fresh factory, which would make the regenerated stage disagree with
# archive_results_journal/accessrefinery_bdd_reducer_IncrementalMCP_10rs/ on every
# timing column (on 05Keys the labels column alone is 2-8x).
JAVA_OPTS="-Dinc.independent=false"
run_stage accessrefinery_bdd_reducer_IncrementalMCP_10rs 10 -p -i
# END_BEGIN_JOURNAL

# MiningOptimized - the intent-mining optimization alone, the configuration Figure
# 20 reads. -o turns on the miner's refinement-DAG node construction and BFS
# early-exit without the incremental EC engine below it, so the property pinned
# above does not apply and is cleared here.
JAVA_OPTS=""
run_stage accessrefinery_bdd_reducer_MiningOptimized_10rs 10 -o
