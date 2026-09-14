#!/bin/bash

# Intent mining and reduction with the BDD backend, 20 rounds, for all four
# stages of the BR -> AR -> AM -> AI optimization pipeline.
#
# Each stage is selected with three cumulative switches, all of which default to
# true (i.e. no switches at all is the fully optimized AI stage):
#
#   -Dopt.ar=false   disable the essential-finding pre-filter in the reducer
#   -Dopt.am=false   disable the miner's BFS early-exit and refinement DAG
#   -Dopt.ai=false   disable the incremental EC engine + cross-policy factory
#
# The -D flags must precede -jar. Every stage runs the same four datasets and
# archives its `result/` tree under its own directory name.
#
# The RW archive (data/RW/) is the real-world corpus with the synthesized label
# s3:::886499mir added to every statement; it is stored under the folder name
# "RW" inside each stage's archive directory.

run_stage() {
  local archive=$1; shift
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/RW/
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/Scalability_05Keys/
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/Scalability_06Keys/
  java "$@" -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/Scalability_07Keys/
  mv result/ "$archive"
}

# BR - original batch engine, no optimization
run_stage accessrefinery_bdd_reducer_20rs/ -Dopt.ar=false -Dopt.am=false -Dopt.ai=false

# AR - BR + essential-finding pre-filter
run_stage accessrefinery_bdd_reducer_AR_20rs/ -Dopt.am=false -Dopt.ai=false

# AM - AR + miner early-exit and refinement DAG
run_stage accessrefinery_bdd_reducer_AM_20rs/ -Dopt.ai=false

# AI - AM + incremental EC engine and cross-policy shared factory (all defaults)
run_stage accessrefinery_bdd_reducer_AI_20rs/
