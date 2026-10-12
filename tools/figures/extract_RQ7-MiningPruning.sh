#!/bin/bash
# Plotting data of RQ7-MiningPruning-PruningReducer-IncrementalMCP.plt (Figure 18).
#
# The figure isolates the intent miner: the intent-mining cost with the two
# reduce/solve columns (c8 RRIOperationsTimeAverage, c9 RRIILPSolvingTimeAverage)
# taken out, i.e. c6+c7.
#
# Input: results/<stage folder>/<dataset>/summary.txt, from the two folders
# README's second `cp -r` step copies in from archive_results_journal/. Where each
# was taken:
#
#   results/accessrefinery_bdd_reducer_IntentPruning_20rs/  AR, Pruning Reducer
#   results/accessrefinery_bdd_reducer_Optimized_10rs/       Pruning Reducer +
#                                                            Incremental MCP
#
# Both are journal runs of the 10- and 20-round sets described in
# running_optimization_pipeline.sh. The optimized stage was taken with
# -Dmcp.labelinc=true, so its c6 column times the single computeLabels() call that
# absorbs the synthesized label instead of the whole parse+preprocessing window the
# archives time. Measured against the Incremental MCP 20-round archive (wide
# window), the two differ by 5-7% at the median - below this figure's resolution on
# a log axis, but the difference is real and is why c6 is the only column of the
# pair that this script's provenance differs on.
#
# Output, one file per key count k (05 = Scalability_05Keys, 06 = Scalability_06Keys):
#
#   p2_$k.dat   Policy A B - c6+c7 of AR vs the optimized stage, one row per
#               policy 1..15. The panel titles AR's curve *Intent Miner
#               (Original)*: it is the pipeline before the miner's own optimization.
#
# The real-world panel rw_p2.dat is NOT written here: it ships with the artifact
# and the corpus it summarises is withheld for commercial reasons, so no run of
# this script can replace it. It holds the same quantity as the synthetic panels,
# c6+c7 of Pruning Reducer vs Incremental MCP.
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

# The dataset directory of a key count. The files and the k suffix keep their
# historical 05/06 numbering; only the directory names follow the paper's, and the
# panel-reduced set here draws 05 and 06.
ds_of() {
    case "$1" in
        05) echo Scalability_05Keys ;;
        06) echo Scalability_06Keys ;;
    esac
}

# readcol <summary.txt> <spec> : one value per policy, in file order.
# <spec> is a 1-based column number, or a "+" sum such as 6+7.
readcol() {
    awk -v spec="$2" 'NR>1 {
        n = split(spec, p, "+"); s = 0
        for (i = 1; i <= n; i++) s += $p[i]
        printf "%.2f\n", s
    }' "$1"
}

echo "Note: the real-world corpus is not shipped (commercial reasons)."
echo "      rw_p2.dat ships as it is and is never written by this script."

# --- Figure 18: RQ7-MiningPruning-PruningReducer-IncrementalMCP, mining c6+c7 ---
for k in 05 06; do
    ds=$(ds_of "$k")
    for f in "$ROOT/accessrefinery_bdd_reducer_IntentPruning_20rs/$ds/summary.txt" \
             "$ROOT/accessrefinery_bdd_reducer_Optimized_10rs/$ds/summary.txt"; do
        [ -f "$f" ] || echo "Warning: $f not found; the column that reads it comes out empty" >&2
    done
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' <(readcol "$ROOT/accessrefinery_bdd_reducer_IntentPruning_20rs/$ds/summary.txt" 6+7) \
                   <(readcol "$ROOT/accessrefinery_bdd_reducer_Optimized_10rs/$ds/summary.txt" 6+7) \
        | awk '{ printf "%d\t%s\t%s\r\n", NR, $1, $2 }'
    } > "$OUT/p2_$k.dat"
done

echo "Done extracting RQ7-MiningPruning data into $OUT/"
ls -1 "$OUT"/p2_05.dat "$OUT"/p2_06.dat
