#!/bin/bash
# Regenerate the plotting data of the 10-round pipeline figures from the 10-round
# stage folders (three stages from one jar via the -Dopt.pruner/refinement/incremental switches,
# --round 10, 05/06/05Keys∗).
#
# Input layout: results/accessrefinery_bdd_reducer_<STAGE>_10rs/<dataset>/summary.txt,
# i.e. the same result/<dataset>/summary.txt shape the tool writes, with <STAGE> one
# of Original / PruningReducer / IncrementalMCP, plus the separate MiningOptimized
# configuration (see the enc_$k.dat entry below; only the Percentage figure reads
# it). Only the summary.txt is read; the archive of the same directories under
# archive_results_journal/, named identically, also carries the per-policy outputs of
# the same runs (01..15_allow_result.json and 01..15_allow_time.csv).
#
# One campaign, four directories. The four stages of the archive do not all come
# from the same server directory, though they are all --round 10 runs of the same
# jar with the same command line, and each stage's per-policy files are the ones
# the summary next to them was rolled up from. These are the sources:
#
#   Original         ~/exp/rerun10b_fix/BR/result/<dataset>/    2026-10-09
#   PruningReducer   ~/exp/noshortcut/ar10/<dataset>/result/<dataset>/  2026-09-26
#   IncrementalMCP   ~/exp/noshortcut/ai10/<dataset>/result/<dataset>/  2026-09-26
#   MiningOptimized  ~/exp/rerun10b_fix/AM/result/Scalability_06Keys/  2026-10-09 (06Keys only)
#                    ~/exp/amonly/result/<dataset>/              2026-09-26 (05Keys, 05Keys∗)
#
# Original was re-taken on 2026-10-09 with the jar built after the reducingIntents
# set-cover fix (docs/NumberRRI-ILP-bug.md): the 09-23 run wrote NumberRRI = 0 for
# 06Keys policies 1 and 3, and the 10-09 tree, before the fix, also zeroed 05Keys∗
# policy 6. Same command line as the 09-23 run (-m -r --round 10, the three BR
# switches), so only the jar differs. MiningOptimized was re-taken for 06Keys, the
# one dataset whose archived copy carried a zero (policy 1); its other two datasets
# are still the 09-26 run.
#
# PruningReducer and IncrementalMCP are the `noshortcut` re-takes rather than
# ~/exp/rerun10b/AR and ~/exp/rerun10b/AI: in the 09-23 run the reducer's
# single-finding shortcut was charged no time at all, and these 09-26 re-takes
# charge it the reduction it actually costs. MiningOptimized is ~/exp/amonly, not
# ~/exp/rerun10b/AM, for the same reason. The pairing is checkable: the md5 of each
# archived summary.txt is the md5 of the summary.txt in the directory the
# per-policy files came from, and each 01_allow_result.json's GeneratedTime is
# that directory's summary.txt mtime to the second (e.g. Original/Scalability_05Keys
# 2026-09-23 23:18:28, PruningReducer 2026-09-26 01:08:55, IncrementalMCP
# 2026-09-26 01:16:04, MiningOptimized 2026-09-26 00:33:12).
#
# This is the 10-round companion of extract_optimization_pipeline.sh, which
# reads the 20-round archives under results/accessrefinery_bdd_reducer_*_20rs/.
# The two scripts write to different directories on purpose, so neither can
# overwrite the other's inputs.
#
# summary.txt columns (1-based):
#   1 NumberStatement          2 NumberMCI                   3 NumberRRI
#   4 MCISolvingRoundAverage   5 TotalTimeAverage            6 MCILabelsTimeAverage
#   7 MCIOperationsTimeAverage 8 RRIOperationsTimeAverage    9 RRIILPSolvingTimeAverage
#
# Outputs, one set per key count k = 05 / 06 / 07:
#
#   bar3_$k.dat   Figure "RQ7-Optimization-Overview-Bars-3Stage"
#                 idx Original PruningReducer IncrementalMCP - TotalTimeAverage
#                 (c5) of the three stages, for the
#                 policies of 3/6/9/12/15 statements, numbered 0..4.
#
#   p2_$k.dat   Figure "RQ8-MiningPruning-PruningReducer-IncrementalMCP"
#                 Policy A B - the intent-mining cost with the two reduce/solve
#                 columns (c8 RRIOperationsTimeAverage, c9 RRIILPSolvingTimeAverage)
#                 taken out, i.e. c6+c7, of Pruning Reducer vs Incremental MCP,
#                 one row per policy 1..15.
#
#   (no figure)   seg_$k.dat
#                 idx Original_miner Original_total PruningReducer_miner
#                 PruningReducer_total IncrementalMCP_miner IncrementalMCP_total -
#                 how each stage's time splits between the intent miner (c6+c7)
#                 and the intent reducer (c8+c9), in milliseconds, for the same
#                 five policies as bar3.  Original_total is c5, the stage's whole
#                 run, so the bars of this figure and of bar3 have the same heights;
#                 the reducer segment is c5 - (c6+c7), which is c8+c9 up to the
#                 per-column rounding of summary.txt.
#
#                 These files fed "Optimization-Overview-Bars-Segmented", which is
#                 no longer shipped - the paper does not print it.  The block below
#                 still writes them and they stay checked in, as the archive of that
#                 measurement.
#
#   enc_$k.dat    Figure "RQ9-Optimization-Overview-Bars-Percentage"
#                 idx Miner Reducer - the MiningOptimized configuration alone, and
#                 how much of each of its two stages goes to the encoding step that
#                 stage starts with, as a percentage of that stage's own pair:
#                 Miner = 100*c6/(c6+c7), the intent miner's window up to the end
#                 of the label tree (parse + ECs + label tree), i.e. everything
#                 before the mining BFS itself; Reducer = 100*c8/(c8+c9), the
#                 intent reducer's window up to the end of the EC encoding of the
#                 findings, i.e. everything before the ILP solve.  One row per
#                 policy 3/6/9/12/15, numbered 0..4.
#
#   rw_enc.dat    the RW panel of the same figure, the same two shares over the
#                 MiningOptimized configuration's 506 real-world policies, one row
#                 per policy, each column sorted on its own value ascending. Written
#                 only when results/accessrefinery_bdd_reducer_MiningOptimized_10rs/RW/summary.txt
#                 is present.
#
# MiningOptimized, the extra configuration this script reads: -Dopt.pruner=false
# -Dopt.refinement=true -Dopt.incremental=false, i.e. the mining-phase search optimization alone,
# without the essential-finding pre-filter and without the incremental EC engine.
# It is not one of the three pipeline stages; the switches are read independently,
# see Parameter.java. results/accessrefinery_bdd_reducer_MiningOptimized_10rs/ was
# taken
# 2026-09-26 on the same server as the three stages, with the same jar
# (exp/rerun10/refinery_sw.jar) and the same command line, so it differs from
# them in the switches alone. Only the Percentage figure reads it. Its real-world
# companion, results/accessrefinery_bdd_reducer_MiningOptimized_10rs/RW/summary.txt,
# is a later run of the
# same three switches and the same jar on the RW corpus, --round 10 as well, taken
# 2026-09-28; it exists only for the real-world panel of the Percentage figure.
#
# Real-world output. The synthetic re-run above covers the scalability datasets
# only; the RW panel of "RQ8-MiningPruning-PruningReducer-IncrementalMCP" needs the two real-world
# summaries of the same round, results/accessrefinery_bdd_reducer_<STAGE>_10rs/RW/summary.txt,
# which
# this script then turns into
#
#   rw_p2.dat   the RW panel of Figure "RQ8-MiningPruning-PruningReducer-IncrementalMCP"
#                 Policy A B - c6+c7 of Pruning Reducer vs Incremental MCP, i.e.
#                 the same quantity as the figure's synthetic panels, one row per RW
#                 policy. Each column is
#                 sorted on its own value, ascending, like rw_p1.dat of Figure
#                 "RQ8-ReducingPruning-Original-PruningReducer": the panel shows two sorted
#                 distributions, so a row is no longer one policy.
#
#   rw_bar3.dat   the RW panel of Figure "RQ7-Optimization-Overview-Bars-3Stage".
#                 NOT regenerated by this script: its Policy WO PruningReducer W
#                 curves are three total-time curves in milliseconds, and the
#                 W/O All one adds the two per-phase columns of the real-world
#                 baseline together, from source files that are not shipped (see
#                 the note further down). The archived copy under $OUT is left
#                 untouched; the figure reads it there.
#
# W/O All predates this re-run, so it is the one curve that does not come from the
# same run as the other two: it is the reference that the pipeline's stages are
# read against.
#
# Both RW summaries are 10-round runs of the same round as the synthetic data
# (2026-09-25 for the RW pair, 2026-09-23/26/10-09 for the synthetic one, see the
# re-take note above). The Pruning
# Reducer columns of every summary this script reads - the three Scalability sets
# and RW - were re-taken on 2026-09-26, same flags and same corpus, with the jar
# built from the tree that times the reducer's single-finding shortcut; the
# Incremental MCP column is still that run. The incremental
# one was
# taken with -Dmcp.labelinc=true, so its c6 column times the single
# computeLabels() call that absorbs the synthesized label instead of the whole
# parse+preprocessing window the archives time. Measured against the Incremental
# MCP 20-round
# archive (wide window), the two differ by 5-7% at the median — below this
# figure's resolution on a log axis, but the difference is real and is why c6 is
# the only column of the pair that this script's provenance differs on.

set -e

# One directory per stage, named as its archive copy under archive_results_journal/.
ROOT=results
OUT=paper_figures/archive_data_journal/10rs
mkdir -p "$OUT"
TMPSEG=$(mktemp -d)
trap 'rm -rf "$TMPSEG"' EXIT

# The dataset directory of a key count. The third set is the 5-Key* one, so the 07
# slot is not Scalability_07Keys: the files and the k suffix keep their historical
# 05/06/07 numbering, only the directory name follows the paper's.
ds_of() {
    case "$1" in
        05) echo Scalability_05Keys ;;
        06) echo Scalability_06Keys ;;
        07) echo 'Scalability_05Keys∗' ;;
    esac
}

for s in Original PruningReducer IncrementalMCP MiningOptimized; do
    for k in 05 06 07; do
        f="$ROOT/accessrefinery_bdd_reducer_${s}_10rs/$(ds_of "$k")/summary.txt"
        [ -f "$f" ] || echo "Warning: $f not found" >&2
    done
done

# readcol <summary.txt> <spec> : one value per policy, in file order.
# <spec> is a 1-based column number, or a "+" sum such as 6+7.
readcol() {
    awk -v spec="$2" 'NR>1 {
        n = split(spec, p, "+"); s = 0
        for (i = 1; i <= n; i++) s += $p[i]
        printf "%.2f\n", s
    }' "$1"
}

# The policies of 3/6/9/12/15 statements are rows 3/6/9/12/15 of the column
# stream below, which drops the summary.txt header line.
PICK='NR==3||NR==6||NR==9||NR==12||NR==15'

# --- Figure 3Stage: all three stages, c5 --------------------------------------
for k in 05 06 07; do
    ds=$(ds_of "$k")
    { printf 'idx\tOriginal\tPruningReducer\tIncrementalMCP\r\n'
      paste -d'\t' <(readcol "$ROOT/accessrefinery_bdd_reducer_Original_10rs/$ds/summary.txt" 5) \
                   <(readcol "$ROOT/accessrefinery_bdd_reducer_PruningReducer_10rs/$ds/summary.txt" 5) \
                   <(readcol "$ROOT/accessrefinery_bdd_reducer_IncrementalMCP_10rs/$ds/summary.txt" 5) \
        | awk "$PICK"'{ printf "%d\t%s\t%s\t%s\r\n", n++, $1, $2, $3 }'
    } > "$OUT/bar3_$k.dat"
done

# --- Figure RQ8-MiningPruning-PruningReducer-IncrementalMCP: mining c6+c7 ------
for k in 05 06 07; do
    ds=$(ds_of "$k")
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' <(readcol "$ROOT/accessrefinery_bdd_reducer_PruningReducer_10rs/$ds/summary.txt" 6+7) \
                   <(readcol "$ROOT/accessrefinery_bdd_reducer_IncrementalMCP_10rs/$ds/summary.txt" 6+7) \
        | awk '{ printf "%d\t%s\t%s\r\n", NR, $1, $2 }'
    } > "$OUT/p2_$k.dat"
done

# --- miner (c6+c7) under reducer (c8+c9), in ms -------------------------------
# Archive only: the Segmented figure these files fed is no longer shipped.
for k in 05 06 07; do
    ds=$(ds_of "$k")
    { printf 'idx\tOriginal_miner\tOriginal_total\tPruningReducer_miner\tPruningReducer_total\tIncrementalMCP_miner\tIncrementalMCP_total\r\n'
      for s in Original PruningReducer IncrementalMCP; do
          paste -d'\t' <(readcol "$ROOT/accessrefinery_bdd_reducer_${s}_10rs/$ds/summary.txt" 6+7) \
                       <(readcol "$ROOT/accessrefinery_bdd_reducer_${s}_10rs/$ds/summary.txt" 5) > "$TMPSEG/$s"
      done
      paste -d'\t' "$TMPSEG/Original" "$TMPSEG/PruningReducer" "$TMPSEG/IncrementalMCP" \
        | awk 'NR==3||NR==6||NR==9||NR==12||NR==15 {
              printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\r\n",
                     n++, $1, $2, $3, $4, $5, $6
          }'
    } > "$OUT/seg_$k.dat"
done

# --- Figure Percentage: encoder share within each pair, MiningOptimized config -
# The two shares are of different denominators on purpose: the left bar of a pair
# says how much of the miner's window the label side takes, the right bar how much
# of the reducer's window the EC encoding takes.  A policy whose pair is entirely
# zero prints 0 rather than dividing by it.
for k in 05 06 07; do
    ds=$(ds_of "$k")
    { printf 'idx\tMiner\tReducer\r\n'
      awk 'NR>1 {
              m = $6 + $7; r = $8 + $9
              printf "%.2f\t%.2f\n", (m > 0 ? 100*$6/m : 0), (r > 0 ? 100*$8/r : 0)
           }' "$ROOT/accessrefinery_bdd_reducer_MiningOptimized_10rs/$ds/summary.txt" \
        | awk "$PICK"'{ printf "%d\t%s\t%s\r\n", n++, $1, $2 }'
    } > "$OUT/enc_$k.dat"
done

# The real-world panel of the same figure: the same two shares over the 506 RW
# policies, each column sorted on its own value ascending, like every other
# real-world panel of this family, so the panel reads as two sorted distributions
# rather than as one policy per row. The four policies that yield no finding have
# no reducer window to take a share of, so their encoding share prints 0, the same
# convention the synthetic file above uses.
if [ -f "$ROOT/accessrefinery_bdd_reducer_MiningOptimized_10rs/RW/summary.txt" ]; then
    TMPE=$(mktemp -d)
    awk 'NR>1 { m = $6 + $7
                printf "%.2f\n", (m > 0 ? 100*$6/m : 0) }' "$ROOT/accessrefinery_bdd_reducer_MiningOptimized_10rs/RW/summary.txt" \
        | LC_ALL=C sort -s -g > "$TMPE/m"
    awk 'NR>1 { r = $8 + $9
                printf "%.2f\n", (r > 0 ? 100*$8/r : 0) }' "$ROOT/accessrefinery_bdd_reducer_MiningOptimized_10rs/RW/summary.txt" \
        | LC_ALL=C sort -s -g > "$TMPE/r"
    { printf 'Policy\tMiner\tReducer\r\n'
      paste -d'\t' "$TMPE/m" "$TMPE/r" \
        | awk '{ printf "%d\t%s\t%s\r\n", NR-1, $1, $2 }'
    } > "$OUT/rw_enc.dat"
    rm -rf "$TMPE"
else
    echo "Note: skipping rw_enc.dat ($ROOT/accessrefinery_bdd_reducer_MiningOptimized_10rs/RW/summary.txt not found)." >&2
fi

# --- RQ8 RW panel, and the Incremental MCP series of Figure RQ4 ----------------
# Only when both real-world summaries of this round are in place; the synthetic
# outputs above regenerate unconditionally.
HAVE_RW=1
for s in PruningReducer IncrementalMCP; do
    [ -f "$ROOT/accessrefinery_bdd_reducer_${s}_10rs/RW/summary.txt" ] || HAVE_RW=0
done

# rw_bar3.dat, the RW panel of Figure "RQ7-Optimization-Overview-Bars-3Stage", is
# never regenerated by this script. Its W/O All curve adds the real-world
# baseline's two per-phase columns together; those two baseline datasets are not
# shipped, for commercial reasons like the corpus itself. The archived
# rw_bar3.dat under paper_figures/archive_data_journal/10rs/ is left in place; the
# figure reads it there, unchanged.
echo "Note: skipping rw_bar3.dat (the real-world baseline data is not shipped)." >&2

if [ "$HAVE_RW" = 1 ]; then
    TMPRW=$(mktemp -d)
    # Each column sorted on its own value, like rw_p1.dat in
    # extract_optimization_pipeline.sh.
    readcol "$ROOT/accessrefinery_bdd_reducer_PruningReducer_10rs/RW/summary.txt" 6+7 | LC_ALL=C sort -s -g > "$TMPRW/a"
    readcol "$ROOT/accessrefinery_bdd_reducer_IncrementalMCP_10rs/RW/summary.txt" 6+7 | LC_ALL=C sort -s -g > "$TMPRW/b"
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' "$TMPRW/a" "$TMPRW/b" \
        | awk '{ printf "%d\t%s\t%s\r\n", NR-1, $1, $2 }'
    } > "$OUT/rw_p2.dat"
    rm -rf "$TMPRW"
else
    echo "Note: $ROOT/accessrefinery_bdd_reducer_{PruningReducer,IncrementalMCP}_10rs/RW/summary.txt not found." >&2
    echo "      Skipping rw_p2.dat (RW panel of RQ8-MiningPruning-PruningReducer-IncrementalMCP)" >&2
fi

echo "Done extracting optimization-pipeline 10-round data into $OUT/"
ls -1 "$OUT"
