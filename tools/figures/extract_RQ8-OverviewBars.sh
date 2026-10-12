#!/bin/bash
# Plotting data of RQ8-Optimization-Overview-Bars-Percentage.plt (Figure 20).
#
# The figure reports how much of each phase's window goes to the encoding side.
# Its two shares are read from one configuration's own summary.txt: the intent
# miner's share is 100*c6/(c6+c7), its window up to the end of the label tree
# (parse + ECs + label tree), i.e. everything before the mining BFS itself; the
# intent reducer's is 100*c8/(c8+c9), its window up to the end of the EC encoding
# of the findings, i.e. everything before the ILP solve.
#
# Input: results/accessrefinery_bdd_reducer_ECPercentage_10rs/, with a summary.txt
# for Scalability_05Keys and Scalability_06Keys, copied in from
# archive_results_journal/ by README's second `cp -r` step.
#
# ECPercentage is the mining-phase search optimization alone, without the
# essential-finding pre-filter and without the incremental EC engine. It is not one
# of the three pipeline stages; it is selected by -o/--mining-optimized on the
# command line, and this folder is a run of it. It was taken 2026-09-26 on the same
# server as the two 10-round stages, with the same jar (exp/rerun10/refinery_sw.jar)
# and the same command line, so it differs from them in the switches alone. Only
# this figure reads it, and it is optional: without that folder the two files below
# come out empty while every other figure still reproduces.
#
# Output, one file per key count k (05 = Scalability_05Keys, 06 = Scalability_06Keys):
#
#   enc_$k.dat   idx Miner Reducer - the two shares, in percent, one row per policy
#                of the dataset numbered 0..14.
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

# The dataset directory of a key count. The files and the k suffix keep their
# historical 05/06 numbering; only the directory names follow the paper's, and the
# panel-reduced set here draws 05 and 06.
ds_of() {
    case "$1" in
        05) echo Scalability_05Keys ;;
        06) echo Scalability_06Keys ;;
    esac
}

# --- Figure 20: encoder share within each pair, ECPercentage configuration ---
# The two shares are of different denominators on purpose: the left bar of a pair
# says how much of the miner's window the label side takes, the right bar how much
# of the reducer's window the EC encoding takes. A policy whose pair is entirely
# zero prints 0 rather than dividing by it.
for k in 05 06; do
    ds=$(ds_of "$k")
    src="$ROOT/accessrefinery_bdd_reducer_ECPercentage_10rs/$ds/summary.txt"
    [ -f "$src" ] || echo "Warning: $src not found; enc_$k.dat comes out empty" >&2
    { printf 'idx\tMiner\tReducer\r\n'
      awk 'NR>1 {
              m = $6 + $7; r = $8 + $9
              printf "%.2f\t%.2f\n", (m > 0 ? 100*$6/m : 0), (r > 0 ? 100*$8/r : 0)
           }' "$src" \
        | awk '{ printf "%d\t%s\t%s\r\n", NR-1, $1, $2 }'
    } > "$OUT/enc_$k.dat"
done

echo "Done extracting RQ8-OverviewBars data into $OUT/"
ls -1 "$OUT"/enc_05.dat "$OUT"/enc_06.dat
