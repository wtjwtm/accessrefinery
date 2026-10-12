#!/bin/bash
# Plotting data of RQ7-ReducingPruning-Original-PruningReducer.plt (Figure 19).
#
# The figure isolates the intent reducer, so the files it reads carry the one
# quantity the two stages are compared on: RRIOperationsTimeAverage +
# RRIILPSolvingTimeAverage (c8+c9), the reducer's set-cover cost.
#
# Input: results/<stage folder>/<dataset>/summary.txt, from the two folders
# README's `cp -r` steps put under results/:
#
#   results/accessrefinery_bdd_reducer_10rs/                 BR  (no stage flag)
#   results/accessrefinery_bdd_reducer_PruningReducer_20rs/  AR  (-p)
#
# BR is the conference-version run of the tool with no optimization, copied in
# from archive_results/accessrefinery_bdd_reducer_10rs/ by README's first
# `cp -r` step; it is the run the conference figures draw, and it is the Baseline
# the journal's stages are compared against. AR is the journal's Pruning Reducer
# stage, copied in from archive_results_journal/ by the second `cp -r` step.
#
# The two folders differ in round count and in session - BR 10 rounds from the
# conference campaign, AR 20 rounds re-taken on 2026-09-26 - so this figure pairs
# the conference-version measurement with the journal's Pruning Reducer
# measurement. The re-take matters to AR's side: the same folder read by Figure
# 18 was measured with the jar built from the tree that times the reducer's
# single-finding shortcut, where the 2026-09-23 run charged that shortcut no time
# at all.
#
# Output, one file per key count k (05 = Scalability_05Keys, 06 = Scalability_06Keys):
#
#   p1_$k.dat   Policy A B - c8+c9 of BR vs AR, one row per policy 1..15. The
#               panel titles BR's curve *Intent Reducer (Original)*.
#
# The real-world panel rw_p1.dat is NOT written here: it ships with the artifact
# and the corpus it summarises is withheld for commercial reasons, so no run of
# this script can replace it.
#
# Floor. The synthetic panel is drawn on a log y-axis whose lower bound is 1e-2 ms,
# so a cell that the summaries print as 0.00 has no place on the curve: gnuplot
# drops it and the line simply starts one point later. This file therefore renders
# such a cell at the axis floor, 0.01, which is the smallest value the axis can
# show. This is the one figure with cells of that kind: the policies that yield no
# finding at all, so the reducer is never entered and neither side is timed, which
# leaves both sides at 0.00.
#
# summary.txt columns (1-based):
#   1 NumberStatement          2 NumberMCI                   3 NumberRRI
#   4 MCISolvingRoundAverage   5 TotalTimeAverage            6 MCILabelsTimeAverage
#   7 MCIOperationsTimeAverage 8 RRIOperationsTimeAverage    9 RRIILPSolvingTimeAverage
#
# All outputs are CRLF, no BOM, one header line, matching the checked-in files.

set -e

ROOT=results
OUT=paper_figures_journal/data
mkdir -p "$OUT"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# readcol <summary.txt> <spec> : one value per policy, in file order.
# <spec> is a 1-based column number, or a "+" sum such as 8+9.
readcol() {
    awk -v spec="$2" 'NR>1 {
        n = split(spec, p, "+"); s = 0
        for (i = 1; i <= n; i++) s += $p[i]
        printf "%.2f\n", s
    }' "$1"
}

# fl(v) raises a cell that renders as 0.00 to the axis floor, 0.01, so that the
# curve has a point there instead of a gap (see the note at the top).
FLOOR='function fl(v) { return (v == "0.00") ? "0.01" : v }
'

# pair_by_row <summaryA> <specA> <summaryB> <specB> <out> : rows 1..N, both columns
# taken from the same summary row.
pair_by_row() {
    readcol "$1" "$2" > "$TMP/a"
    readcol "$3" "$4" > "$TMP/b"
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' "$TMP/a" "$TMP/b" \
        | awk "$FLOOR"' { printf "%d\t%s\t%s\r\n", NR, fl($1), fl($2) }'
    } > "$5"
}

BR="$ROOT/accessrefinery_bdd_reducer_10rs"
PRUN_20="$ROOT/accessrefinery_bdd_reducer_PruningReducer_20rs"

echo "Note: the real-world corpus is not shipped (commercial reasons)."
echo "      rw_p1.dat ships as it is and is never written by this script."

# --- Figure 19: RQ7-ReducingPruning-Original-PruningReducer, reducer (c8+c9) ----
pair_by_row "$BR/Scalability_05Keys/summary.txt" 8+9 "$PRUN_20/Scalability_05Keys/summary.txt" 8+9 "$OUT/p1_05.dat"
pair_by_row "$BR/Scalability_06Keys/summary.txt" 8+9 "$PRUN_20/Scalability_06Keys/summary.txt" 8+9 "$OUT/p1_06.dat"

echo "Done extracting RQ7-ReducingPruning data into $OUT/"
ls -1 "$OUT"/p1_05.dat "$OUT"/p1_06.dat
