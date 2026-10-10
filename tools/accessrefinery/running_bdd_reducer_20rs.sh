#!/bin/bash

# Intent mining and reduction with the BDD backend, 20 rounds, for the three
# stages of the optimization pipeline: Original, +Pruning Reducer, +Incremental MCP.
#
# Each stage is selected with cumulative switches, all of which default to
# ADD_BEGIN_JOURNAL
# true (i.e. none of the three opt switches is the fully optimized Incremental
# MCP stage; that stage additionally pins -Dinc.independent, see the bottom):
# END_BEGIN_JOURNAL
#
#   -Dopt.pruner=false   disable the essential-finding pre-filter in the reducer
#   -Dopt.refinement=false   disable the miner's refinement-DAG node construction and BFS early-exit
#   -Dopt.incremental=false   disable the incremental EC engine + cross-policy factory
#
# The -D flags must precede -jar. Every stage runs the same four datasets and
# writes its `result/` tree to results/<stage>/, the working directory that
# tools/figures/extract_optimization_pipeline.sh reads.
#
# The shipped copies of these three folders live in archive_results_journal/, which
# this script never touches; check the regenerated results/ against them.
#
# The real-world corpus is stored under the folder name "RW" inside each stage's
# results directory. The corpus itself is not public, for commercial reasons, so
# data/RW/ ships empty and the RW run below is skipped unless the folder has been
# restored locally.

run_stage() {
  local name=$1; shift
  if [ -d data/RW/ ]; then
    java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/RW/
  fi
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/Scalability_05Keys/
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/Scalability_06Keys/
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/Scalability_05Keys∗/
  # Replace the previous working copy; the pristine one stays in
  # archive_results_journal/. `mv result dst` would nest the tree inside dst.
  rm -rf "results/$name"
  mv result "results/$name"
}

# Original - batch engine, no optimization
run_stage accessrefinery_bdd_reducer_Original_20rs -Dopt.pruner=false -Dopt.refinement=false -Dopt.incremental=false

# Pruning Reducer - Original + essential-finding pre-filter
run_stage accessrefinery_bdd_reducer_PruningReducer_20rs -Dopt.refinement=false -Dopt.incremental=false

# ADD_BEGIN_JOURNAL
# Incremental MCP - Pruning Reducer + incremental EC engine and cross-policy
# shared factory. The two stages above pass -Dopt.incremental=false, which forces the
# per-policy behaviour, so this is the only stage where the flag matters.
# -Dinc.independent=false is pinned because this stage's archive was measured with
# the cross-policy shared factory: as of 2026-10-09 a plain run gives every policy
# its own fresh factory, which would make the regenerated stage disagree with
# archive_results_journal/accessrefinery_bdd_reducer_IncrementalMCP_20rs/ on every
# timing column (on 05Keys the labels column alone is 2-8x).
run_stage accessrefinery_bdd_reducer_IncrementalMCP_20rs -Dinc.independent=false
# END_BEGIN_JOURNAL
