#!/bin/bash
# Regenerate the plotting data of the optimization-pipeline figures that read the
# 20-round stage archives, from their per-policy summary.txt.
#
# Stage folders under results/, one per stage of the pipeline:
#
#   accessrefinery_bdd_reducer_Original_20rs/        Original         (-Dopt.pruner=false -Dopt.refinement=false -Dopt.incremental=false)
#   accessrefinery_bdd_reducer_PruningReducer_20rs/  Pruning Reducer  (-Dopt.refinement=false -Dopt.incremental=false)
#   accessrefinery_bdd_reducer_IncrementalMCP_20rs/  Incremental MCP  (defaults)
#
# The shipped copies of these three folders are in archive_results_journal/.
#
# The Pruning Reducer folder was re-taken on 2026-09-26 - same four datasets, same flags,
# the jar built from the tree that times the reducer's single-finding shortcut - so its four
# datasets are from a later session than the other two, which are still the 2026-09-01 run.
#
# The real-world dataset of that same folder was re-taken once more, on 2026-09-28,
# again at 20 rounds but with the jar built from the tree that removes the reducer's
# single-finding shortcut instead of timing it, so that a policy of at most one finding
# is charged the reduction it actually costs rather than the ~0 ms the shortcut took.
# The RW pair of RQ8-ReducingPruning-Original-PruningReducer is therefore one session
# later than the three Scalability datasets of the folder; no other output of this script
# is affected by that re-take.
#
# summary.txt columns (1-based):
#   1 NumberStatement          2 NumberMCI                   3 NumberRRI
#   4 MCISolvingRoundAverage   5 TotalTimeAverage            6 MCILabelsTimeAverage
#   7 MCIOperationsTimeAverage 8 RRIOperationsTimeAverage    9 RRIILPSolvingTimeAverage
#
# Each stage isolates one optimization, so each figure compares the one column
# that stage changes:
#
#   (no figure)                 p_bar_ix_05/06/07.dat
#                                     TotalTimeAverage (c5) of the three stages, for
#                                     the policies of 3/6/9/12/15 statements
#                               rw_bar_ix.dat
#                                     TotalTimeAverage (c5, Original) vs
#                                     MCILabelsTimeAverage (c6, Incremental MCP)
#
#                               These five files fed the 20-round four-bar
#                               "Optimization-Overview-Bars" rendering, which is no
#                               longer shipped: the paper prints that figure from the
#                               10-round data instead, as
#                               "RQ7-Optimization-Overview-Bars-3Stage" (see
#                               extract_optimization_pipeline_10rs.sh). The block below
#                               still writes them, and they stay checked in, because
#                               rw_bar_ix.dat needs the withheld real-world corpus and
#                               can never be regenerated here.
#   RQ8-ReducingPruning-Original-PruningReducer
#                               p1_05/p1_06/p1_07.dat, rw_p1.dat
#                                     RRIOperationsTimeAverage + RRIILPSolvingTimeAverage
#                                     (c8+c9), Original vs Pruning Reducer - the
#                                     reducer's set-cover cost
#
# The Scalability_* files keep summary.txt row order and number the policies 1..15.
# The RW files number the rows 0..505 and sort every column on its own value, ascending,
# so that each curve is monotone and the two curves of a panel are read as two sorted
# distributions rather than as one policy-per-row pairing. The sort uses the computed
# value, not its two-decimal rendering in summary.txt: policies that both print as 1.32
# are still ordered by their exact sums.
#
# All outputs are CRLF, no BOM, one header line, matching the checked-in files.
#
# Floor on the pair files. The figures draw these files on a log y-axis whose lower
# bound is 1e-2 ms, so a cell that the summaries print as 0.00 has no place on the
# curve: gnuplot drops it and the line simply starts one point later. The pair files
# below therefore render such a cell at the axis floor, 0.01, which is the smallest
# value the axis can show. Only RQ8-ReducingPruning-Original-PruningReducer has cells of
# this kind, and today only on the RW corpus: the policies that yield no finding at all, so
# the reducer is never entered and neither side is timed, which leaves both sides at 0.00.
# The Pruning Reducer side of a synthetic policy with a single finding used to print 0.00
# the same way, the reducer's shortcut having consumed no recordable time; since that folder
# was re-taken on 2026-09-26 that shortcut is timed, so those cells are measurements now
# (0.02 for policy 1 of Scalability_05Keys) and no longer need the floor.

set -e

ORIGINAL=results/accessrefinery_bdd_reducer_Original_20rs
PRUNING_REDUCER=results/accessrefinery_bdd_reducer_PruningReducer_20rs
INCREMENTAL_MCP=results/accessrefinery_bdd_reducer_IncrementalMCP_20rs

OUT=paper_figures/archive_data_journal
mkdir -p "$OUT"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The real-world corpus is withheld for commercial reasons, so the `rw_*` outputs
# are produced only when the archives are present. Every other output on this
# script's list is synthetic and regenerates unconditionally.
HAVE_RW=1
for s in "$ORIGINAL" "$PRUNING_REDUCER" "$INCREMENTAL_MCP"; do
    [ -f "$s/RW/summary.txt" ] || HAVE_RW=0
done
if [ "$HAVE_RW" = 0 ]; then
    echo "Note: the real-world corpus is not shipped (commercial reasons)."
    echo "      Skipping rw_p1.dat, rw_bar_ix.dat."
fi

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

# rawcol <summary.txt> <spec> : the same values as readcol, but at full double
# precision. This is the sort key: the figures sort on the computed value, and two
# policies whose values round to the same two decimals are still ordered by their
# exact sums, so sorting on the printed values would scramble the ties.
rawcol() {
    awk -v spec="$2" 'NR>1 {
        n = split(spec, p, "+"); s = 0
        for (i = 1; i <= n; i++) s += $p[i]
        printf "%.17g\n", s
    }' "$1"
}

# pair_sorted_each <summaryA> <specA> <summaryB> <specB> <out> : the two columns are
# sorted on their own values, independently of each other.
pair_sorted_each() {
    readcol "$1" "$2" | LC_ALL=C sort -s -g > "$TMP/a"
    readcol "$3" "$4" | LC_ALL=C sort -s -g > "$TMP/b"
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' "$TMP/a" "$TMP/b" \
        | awk "$FLOOR"' { printf "%d\t%s\t%s\r\n", NR-1, fl($1), fl($2) }'
    } > "$5"
}

# --- RQ8-ReducingPruning-Original-PruningReducer: reducer (c8+c9) --------------
pair_by_row "$ORIGINAL/Scalability_05Keys/summary.txt" 8+9 "$PRUNING_REDUCER/Scalability_05Keys/summary.txt" 8+9 "$OUT/p1_05.dat"
pair_by_row "$ORIGINAL/Scalability_06Keys/summary.txt" 8+9 "$PRUNING_REDUCER/Scalability_06Keys/summary.txt" 8+9 "$OUT/p1_06.dat"
pair_by_row "$ORIGINAL/Scalability_05Keys∗/summary.txt" 8+9 "$PRUNING_REDUCER/Scalability_05Keys∗/summary.txt" 8+9 "$OUT/p1_07.dat"
if [ "$HAVE_RW" = 1 ]; then
    pair_sorted_each "$ORIGINAL/RW/summary.txt" 8+9 "$PRUNING_REDUCER/RW/summary.txt" 8+9 "$OUT/rw_p1.dat"
fi

# --- Total time of the three stages, c5 ----------------------------------------
# Kept for the archive only: the figure these files fed, the 20-round
# Optimization-Overview-Bars, is no longer shipped (see the header).
# The 07 case holds the 5-Key* dataset, whose directory keeps that name.
for k in 05 06 07; do
    case $k in
        05) ds=Scalability_05Keys ;;
        06) ds=Scalability_06Keys ;;
        07) ds=Scalability_05Keys∗ ;;
    esac
    { printf 'idx\tOriginal\tPruningReducer\tIncrementalMCP\r\n'
      paste -d'\t' <(readcol "$ORIGINAL/$ds/summary.txt" 5) \
                   <(readcol "$PRUNING_REDUCER/$ds/summary.txt" 5) \
                   <(readcol "$INCREMENTAL_MCP/$ds/summary.txt" 5) \
        | awk 'NR==3||NR==6||NR==9||NR==12||NR==15 { printf "%d\t%s\t%s\t%s\r\n", n++, $1, $2, $3 }'
    } > "$OUT/p_bar_ix_$k.dat"
done
if [ "$HAVE_RW" = 1 ]; then
    {
        printf 'Policy\tOriginal\tIncrementalMCP\r\n'
        paste -d'\t' <(rawcol "$ORIGINAL/RW/summary.txt" 5) <(readcol "$ORIGINAL/RW/summary.txt" 5) \
                     <(readcol "$INCREMENTAL_MCP/RW/summary.txt" 6) \
          | LC_ALL=C sort -s -g -k1,1 \
          | awk -F'\t' '{ printf "%d\t%s\t%s\r\n", NR-1, $2, $3 }'
    } > "$OUT/rw_bar_ix.dat"
fi

echo "Done extracting optimization-pipeline data into $OUT/"
if [ "$HAVE_RW" = 1 ]; then
    ls -1 "$OUT"/p*.dat "$OUT"/rw_*.dat
else
    ls -1 "$OUT"/p*.dat
fi
