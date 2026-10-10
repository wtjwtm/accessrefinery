#!/bin/bash
# Regenerate the plotting data of every figure that reads the pipeline stage
# folders under results/ - the two RQ3 scalability figures included, whose
# AccessRefinery series come from those same folders.
#
# Input layout: results/accessrefinery_bdd_reducer_<STAGE>_<N>rs/<dataset>/summary.txt,
# i.e. the same result/<dataset>/summary.txt shape the tool writes, with <STAGE> one
# of Original / PruningReducer / IncrementalMCP / MiningOptimized and <N> the round
# count. Only the summary.txt is read; the archive of the same directories under
# archive_results_journal/, named identically, also carries the per-policy outputs of
# the same runs (01..15_allow_result.json and 01..15_allow_time.csv).
#
# What this script writes, and what reads it:
#
#   p1_05.dat, p1_06.dat        RQ7-ReducingPruning-Original-PruningReducer (18)
#   p2_05.dat, p2_06.dat        RQ7-MiningPruning-PruningReducer-IncrementalMCP (19)
#   enc_05.dat, enc_06.dat      RQ8-Optimization-Overview-Bars-Percentage (20)
#   rw_p1.dat, rw_p2.dat        the RW panels of the two RQ7 figures - shipped as
#                               they are; this script writes neither of them, so no
#                               run of it can replace them
#   Experiment-Scalability-MCI-K{2,3}[-WAll].dat    RQ3-Experiment-Scalability-Mining (14)
#   Experiment-Scalability-RRI-K{2,3}[-WAll].dat    RQ3-Experiment-Scalability-Reducing (15)
#
# The six pair/share files are written whole. The four RQ3 `.dat` files are edited column by
# column, and only in the columns their two figures draw: the two AccessRefinery series
# of each come from the pipeline stages under results/, and the Access Analyzer Z3 series
# from the conference-version measurement archive that README's
# `cp -r archive_results/... results/` step puts there. A column whose source is missing
# keeps the value it already has, so the shipped files survive a run of this script
# without that archive (see the RQ3 note before that block).
#
# summary.txt columns (1-based):
#   1 NumberStatement          2 NumberMCI                   3 NumberRRI
#   4 MCISolvingRoundAverage   5 TotalTimeAverage            6 MCILabelsTimeAverage
#   7 MCIOperationsTimeAverage 8 RRIOperationsTimeAverage    9 RRIILPSolvingTimeAverage
#
# ------------------------------------------------------------------------------
# The 20-round stages (Figures 18)
# ------------------------------------------------------------------------------
#
#   accessrefinery_bdd_reducer_Original_20rs/        Original         (no stage flag)
#   accessrefinery_bdd_reducer_PruningReducer_20rs/  Pruning Reducer  (-p)
#
# The Pruning Reducer folder was re-taken on 2026-09-26 - same four datasets, same flags,
# the jar built from the tree that times the reducer's single-finding shortcut - so its four
# datasets are from a later session than the Original folder, which is still the 2026-09-01 run.
#
# The real-world dataset of that same folder was re-taken once more, on 2026-09-28,
# again at 20 rounds but with the jar built from the tree that removes the reducer's
# single-finding shortcut instead of timing it, so that a policy of at most one finding
# is charged the reduction it actually costs rather than the ~0 ms the shortcut took.
# The RW pair of RQ7-ReducingPruning-Original-PruningReducer is therefore one session
# later than the three Scalability datasets of the folder. That RW re-take is not read
# here: this script takes only the two Scalability datasets of the folder.
#
# Each stage isolates one optimization, so the figure compares the one column
# that stage changes:
#
#   RQ7-ReducingPruning-Original-PruningReducer
#                               p1_05/p1_06.dat
#                                     RRIOperationsTimeAverage + RRIILPSolvingTimeAverage
#                                     (c8+c9), Original vs Pruning Reducer - the
#                                     reducer's set-cover cost
#                               (its rw_p1.dat panel is shipped, not written here)
#
# The Scalability_* files keep summary.txt row order and number the policies 1..15.
#
# All outputs are CRLF, no BOM, one header line, matching the checked-in files.
#
# Floor on the pair files. The synthetic pair files are drawn on a log y-axis whose
# lower bound is 1e-2 ms, so a cell that the summaries print as 0.00 has no place on
# the curve: gnuplot drops it and the line simply starts one point later. Those files
# therefore render such a cell at the axis floor, 0.01, which is the smallest value
# the axis can show. Only RQ7-ReducingPruning-Original-PruningReducer has cells of
# this kind: the policies that yield no finding at all, so the reducer is never entered
# and neither side is timed, which leaves both sides at 0.00. The Pruning Reducer side
# of a synthetic policy with a single finding used to print 0.00 the same way, the
# reducer's shortcut having consumed no recordable time; since that folder was re-taken
# on 2026-09-26 that shortcut is timed, so those cells are measurements now (0.02 for
# policy 1 of Scalability_05Keys) and no longer need the floor.
#
# The RW pair needs no floor. Its figure draws the two columns cumulatively, so a cell
# the summaries print as 0.00 adds nothing and leaves the curve where it was instead of
# punching a hole in it; the 506 rows keep their measured zeros.
#
# ------------------------------------------------------------------------------
# The 10-round stages (Figures 19 and 20)
# ------------------------------------------------------------------------------
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
#                    ~/exp/amonly/result/<dataset>/              2026-09-26 (05Keys)
#
# Original was re-taken on 2026-10-09 with the jar built after the reducingIntents
# set-cover fix (docs/NumberRRI-ILP-bug.md): the 09-23 run wrote NumberRRI = 0 for
# 06Keys policies 1 and 3, and the 10-09 tree, before the fix, also zeroed 05Keys∗
# policy 6. Same command line as the 09-23 run (-m -r --round 10, the three BR
# switches), so only the jar differs. MiningOptimized was re-taken for 06Keys, the
# one dataset whose archived copy carried a zero (policy 1); its other dataset is
# still the 09-26 run.
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
# Outputs, one set per key count k = 05 / 06:
#
#   p2_$k.dat   Figure "RQ7-MiningPruning-PruningReducer-IncrementalMCP"
#                 Policy A B - the intent-mining cost with the two reduce/solve
#                 columns (c8 RRIOperationsTimeAverage, c9 RRIILPSolvingTimeAverage)
#                 taken out, i.e. c6+c7, of Pruning Reducer vs Incremental MCP,
#                 one row per policy 1..15.
#
#   enc_$k.dat    Figure "RQ8-Optimization-Overview-Bars-Percentage"
#                 idx Miner Reducer - the MiningOptimized configuration alone, and
#                 how much of each of its two stages goes to the encoding step that
#                 stage starts with, as a percentage of that stage's own pair:
#                 Miner = 100*c6/(c6+c7), the intent miner's window up to the end
#                 of the label tree (parse + ECs + label tree), i.e. everything
#                 before the mining BFS itself; Reducer = 100*c8/(c8+c9), the
#                 intent reducer's window up to the end of the EC encoding of the
#                 findings, i.e. everything before the ILP solve.  One row per
#                 policy, numbered 0..14.
#
# MiningOptimized, the extra configuration this script reads: the mining-phase search
# optimization alone, without the essential-finding pre-filter and without the
# incremental EC engine. It is not one of the three pipeline stages; it is selected
# by -o/--mining-optimized on the command line, and this folder is a run of it.
# results/accessrefinery_bdd_reducer_MiningOptimized_10rs/ was taken 2026-09-26 on the
# same server as the three stages, with the same jar (exp/rerun10/refinery_sw.jar) and
# the same command line, so it differs from them in the switches alone. Only the
# Percentage figure reads it.
#
# Real-world files. Neither `rw_*.dat` panel is produced here: both ship with the
# artifact and this script never writes either of them, so no run of it can replace
# the RW panels of the two RQ7 figures. The corpus they summarise is withheld, so they
# are not reproducible from this repository in the first place. For the record, the
# shipped files hold
#
#   rw_p1.dat   the RW panel of Figure "RQ7-ReducingPruning-Original-PruningReducer"
#                 Policy A B - c8+c9 of Original vs Pruning Reducer
#   rw_p2.dat   the RW panel of Figure "RQ7-MiningPruning-PruningReducer-IncrementalMCP"
#                 Policy A B - c6+c7 of Pruning Reducer vs Incremental MCP, i.e. the
#                 same quantity as that figure's synthetic panels
#
# one row per RW policy, in the corpus' own order and numbered 0..505, both columns
# paired policy by policy: the panels draw them with `smooth cumulative`, whose x axis
# is the corpus position.
#
# The Pruning Reducer columns of every summary this script reads - the two Scalability
# sets - were re-taken on 2026-09-26, same
# flags and same corpus, with the jar built from the tree that times the reducer's
# single-finding shortcut; the Incremental MCP column is still that run. The incremental
# one was taken with -Dmcp.labelinc=true, so its c6 column times the single
# computeLabels() call that absorbs the synthesized label instead of the whole
# parse+preprocessing window the archives time. Measured against the Incremental
# MCP 20-round archive (wide window), the two differ by 5-7% at the median — below
# this figure's resolution on a log axis, but the difference is real and is why c6 is
# the only column of the pair that this script's provenance differs on.
#
# ------------------------------------------------------------------------------
# RQ3 (Figures 14 and 15)
# ------------------------------------------------------------------------------
#
# Figures 14 and 15 compare the same two stages of the 10-round run, BR (the Original
# stage, results/accessrefinery_bdd_reducer_Original_10rs) and AI (the Incremental MCP
# stage, results/accessrefinery_bdd_reducer_IncrementalMCP_10rs), and differ only in the
# quantity they plot:
#
#   RQ3-Experiment-Scalability-Mining (14)    c6+c7, the intent miner's own two columns
#   RQ3-Experiment-Scalability-Reducing (15)  c5, TotalTimeAverage
#
# Of the columns of those two files, this script writes the ones Figures 14 and 15 draw,
# and leaves the others as they are. Those written are the Access Analyzer Z3 series,
# which comes from the conference-version measurement archive that README's
# `cp -r archive_results/... results/` step restores under results/, and the two
# AccessRefinery series, which come from the pipeline stages above:
#
#   Experiment-Scalability-MCI-K{2,3}.dat, tab separated
#     1  policy index             the file's own
#     2  Access Analyzer, Z3      results/accessanalyzer_z3_miner_1rs/<dataset>/summary.csv
#     5  AccessRefinery(Original) the BR stage, c6+c7
#
#   Experiment-Scalability-RRI-K{2,3}.dat, space separated
#     1  Access Analyzer, Z3      results/accessanalyzer_z3_reducer_1rs/<dataset>/summary.csv
#     4  AccessRefinery(Original) the BR stage, c5
#
# The CVC5 series of the same files and the MiniSAT one are drawn by no figure of this
# set - they belong to the conference version, where RQ5's micro-benchmark plots the
# MiniSAT column - so they are left alone.
#
# The Access Analyzer summary.csv of those folders carries the total time of the run in
# seconds; the column here is in milliseconds, so it is scaled by 1000, held at the
# 3600000 ms timeout sentinel and printed with one decimal, the shape the archived file
# has - a policy the baseline did not finish has no row and takes the sentinel. The MCI
# file trims the trailing zeros of the columns it writes (466.8, not 466.80); the RRI
# file, being space separated, keeps the two decimals.
#
# The series each figure calls AccessRefinery(Optimized) is the file's own one-column
# W/All companion, taken from the Incremental MCP stage of the same 10 rounds.
#
# Every column above is replaced only when its source is there. A source that is missing
# is reported and that column keeps the value the shipped file already has, so a run
# without the conference-version folders still refreshes the two AccessRefinery series
# instead of inventing numbers for the archived ones.

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

# ---------------------------------------------------------------- 20 rounds ----
ORIG_20="$ROOT/accessrefinery_bdd_reducer_Original_20rs"
PRUN_20="$ROOT/accessrefinery_bdd_reducer_PruningReducer_20rs"

# The real-world corpus is withheld for commercial reasons, and the two `rw_*.dat`
# panels ship as they are: this script writes neither of them, so no run of it can
# replace the RW panels of the two RQ7 figures. Every output on its list is synthetic
# and regenerates unconditionally.
echo "Note: the real-world corpus is not shipped (commercial reasons)."
echo "      rw_p1.dat and rw_p2.dat ship as they are and are never written by this script."

# --- Figure 19: RQ7-ReducingPruning-Original-PruningReducer, reducer (c8+c9) ----
pair_by_row "$ORIG_20/Scalability_05Keys/summary.txt" 8+9 "$PRUN_20/Scalability_05Keys/summary.txt" 8+9 "$OUT/p1_05.dat"
pair_by_row "$ORIG_20/Scalability_06Keys/summary.txt" 8+9 "$PRUN_20/Scalability_06Keys/summary.txt" 8+9 "$OUT/p1_06.dat"

# ---------------------------------------------------------------- 10 rounds ----
# The stage folders the two figure blocks below read: PruningReducer and
# IncrementalMCP for p2_*.dat, MiningOptimized for enc_*.dat. A missing summary.txt
# is reported here; the output that reads it then comes out empty.
for s in PruningReducer IncrementalMCP MiningOptimized; do
    for k in 05 06; do
        f="$ROOT/accessrefinery_bdd_reducer_${s}_10rs/$(ds_of "$k")/summary.txt"
        [ -f "$f" ] || echo "Warning: $f not found" >&2
    done
done

# --- Figure 18: RQ7-MiningPruning-PruningReducer-IncrementalMCP, mining c6+c7 ---
for k in 05 06; do
    ds=$(ds_of "$k")
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' <(readcol "$ROOT/accessrefinery_bdd_reducer_PruningReducer_10rs/$ds/summary.txt" 6+7) \
                   <(readcol "$ROOT/accessrefinery_bdd_reducer_IncrementalMCP_10rs/$ds/summary.txt" 6+7) \
        | awk '{ printf "%d\t%s\t%s\r\n", NR, $1, $2 }'
    } > "$OUT/p2_$k.dat"
done

# --- Figure 20: encoder share within each pair, MiningOptimized configuration ---
# The two shares are of different denominators on purpose: the left bar of a pair
# says how much of the miner's window the label side takes, the right bar how much
# of the reducer's window the EC encoding takes.  A policy whose pair is entirely
# zero prints 0 rather than dividing by it.
for k in 05 06; do
    ds=$(ds_of "$k")
    { printf 'idx\tMiner\tReducer\r\n'
      awk 'NR>1 {
              m = $6 + $7; r = $8 + $9
              printf "%.2f\t%.2f\n", (m > 0 ? 100*$6/m : 0), (r > 0 ? 100*$8/r : 0)
           }' "$ROOT/accessrefinery_bdd_reducer_MiningOptimized_10rs/$ds/summary.txt" \
        | awk '{ printf "%d\t%s\t%s\r\n", NR-1, $1, $2 }'
    } > "$OUT/enc_$k.dat"
done

# --- RW panel of Figure 18 -----------------------------------------------------
# Not produced here: rw_p2.dat ships as it is and the corpus it summarises is
# withheld, so no run of this script may write it. See the note above the Figure 19
# block.

# ------------------------------------------------------------------- RQ3 -------
# rq3_col_in <file> <sep> <col> <values> : replace column <col> of <file> with the
# lines of <values>, keeping that file's separator, line ending and every other
# column byte for byte.
rq3_col_in() {
    local file=$1 sep=$2 col=$3 vals=$4
    # The record's own trailing CR is stripped before the split (this awk may have
    # done it already) and re-added on output, since these files are CRLF.
    awk -v sep="$sep" -v col="$col" -v vf="$vals" '
        NR == FNR { v[FNR] = $0; next }
        {
            line = $0
            sub(/\r$/, "", line)
            n = split(line, f, sep)
            f[col] = v[FNR]
            out = f[1]
            for (i = 2; i <= n; i++) out = out sep f[i]
            printf "%s\r\n", out
        }
    ' "$vals" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
}

# rq3_wall <values> <file> : write the one-column W/All companion, CRLF, as it is.
rq3_wall() {
    awk '{ printf "%s\r\n", $0 }' "$1" > "$2"
}

# rq3_src_col <src> <mode> <spec> : the values of one source column, one per row of
# that source, in file order. Mode `aa` is an Access Analyzer summary.csv, whose fifth
# column is the total time of the run in seconds: it is printed in milliseconds, the
# unit of the `.dat` files, and held at the 3600000 ms timeout sentinel. Mode `txt` is
# a tool summary.txt, <spec> being a column number or a "+" sum such as 6+7.
rq3_src_col() {
    case "$2" in
        aa)  awk -F',' 'NR>1 { t = $5 * 1000; printf "%.1f\n", (t > 3600000 ? 3600000 : t) }' "$1" ;;
        txt) awk -v spec="$3" 'NR>1 {
                 n = split(spec, p, "+"); s = 0
                 for (i = 1; i <= n; i++) s += $p[i]
                 printf "%.2f\n", s
             }' "$1" ;;
    esac
}

# rq3_pad <sentinel> : read one value per row and write the 15 policies of a `.dat`
# file, a policy the source has no row for taking <sentinel>.
rq3_pad() {
    awk -v sent="$1" '{ v[NR] = $0 }
        END { for (i = 1; i <= 15; i++) printf "%s\n", (i in v ? v[i] : sent) }'
}

# rq3_fill_col <file> <sep> <col> <src> <mode> <spec> <sentinel> [trim]
# Put the values of <src> into column <col> of <file>. `trim` cuts the trailing zeros
# of the column, which is how the MCI file carries every one of its own; the RRI file
# keeps the two decimals. A source that is not there is reported and the column keeps
# the value it already has - see the note above.
rq3_fill_col() {
    local file=$1 sep=$2 col=$3 src=$4 mode=$5 spec=$6 sent=$7 trim=$8
    if [ ! -f "$file" ]; then
        echo "Warning: $file not found; nothing written" >&2
        return 0
    fi
    if [ ! -f "$src" ]; then
        echo "Warning: $src not found; column $col of $(basename "$file") keeps the value it has" >&2
        return 0
    fi
    rq3_src_col "$src" "$mode" "$spec" > "$TMP/src"
    rq3_pad "$sent" < "$TMP/src" > "$TMP/col"
    if [ "$trim" = trim ]; then
        sed -e '/\./!b' -e 's/0*$//' -e 's/\.$//' "$TMP/col" > "$TMP/col.t"; mv "$TMP/col.t" "$TMP/col"
    fi
    rq3_col_in "$file" "$sep" "$col" "$TMP/col"
}

# rq3_fill_wall <src> <spec> <file> : the one-column W/All companion of an RQ3 file,
# the series the figure calls AccessRefinery(Optimized). It keeps the two decimals.
rq3_fill_wall() {
    local src=$1 spec=$2 file=$3
    if [ ! -f "$src" ]; then
        echo "Warning: $src not found; $(basename "$file") keeps the column it has" >&2
        return 0
    fi
    rq3_src_col "$src" txt "$spec" > "$TMP/src"
    rq3_pad 3600000.00 < "$TMP/src" > "$TMP/col"
    rq3_wall "$TMP/col" "$file"
}

# The index the file name of a key count carries; the two RQ3 figures number their
# datasets 2 and 3, after the paper's K2 and K3.
k_index() {
    case "$1" in
        05) echo 2 ;;
        06) echo 3 ;;
    esac
}

# Figure 14: mining, c6+c7 of the BR stage in the file's column 5 (tab separated), and
# of the AI stage in its W/All companion.
rq3_mci() {
    local k=$1 ds n dat wall
    ds=$(ds_of "$k"); n=$(k_index "$k")
    dat="$OUT/Experiment-Scalability-MCI-K$n.dat"
    wall="$OUT/Experiment-Scalability-MCI-K$n-WAll.dat"
    rq3_fill_col "$dat" "$(printf '\t')" 2 "$ROOT/accessanalyzer_z3_miner_1rs/$ds/summary.csv" aa "" 3600000 trim
    rq3_fill_col "$dat" "$(printf '\t')" 5 "$ROOT/accessrefinery_bdd_reducer_Original_10rs/$ds/summary.txt" txt 6+7 3600000 trim
    rq3_fill_wall "$ROOT/accessrefinery_bdd_reducer_IncrementalMCP_10rs/$ds/summary.txt" 6+7 "$wall"
}

# Figure 15: reduction, c5 (TotalTimeAverage) of the BR stage in the file's column 4
# (space separated), and of the AI stage in its W/All companion.
rq3_rri() {
    local k=$1 ds n dat wall
    ds=$(ds_of "$k"); n=$(k_index "$k")
    dat="$OUT/Experiment-Scalability-RRI-K$n.dat"
    wall="$OUT/Experiment-Scalability-RRI-K$n-WAll.dat"
    rq3_fill_col "$dat" " " 1 "$ROOT/accessanalyzer_z3_reducer_1rs/$ds/summary.csv" aa "" 3600000.0
    rq3_fill_col "$dat" " " 4 "$ROOT/accessrefinery_bdd_reducer_Original_10rs/$ds/summary.txt" txt 5 3600000.00
    rq3_fill_wall "$ROOT/accessrefinery_bdd_reducer_IncrementalMCP_10rs/$ds/summary.txt" 5 "$wall"
}

rq3_mci 05
rq3_mci 06
rq3_rri 05
rq3_rri 06

echo "Done extracting optimization-pipeline data into $OUT/"
ls -1 "$OUT"/p1_*.dat "$OUT"/p2_*.dat "$OUT"/enc_*.dat \
      "$OUT"/Experiment-Scalability-MCI-K{2,3}*.dat \
      "$OUT"/Experiment-Scalability-RRI-K{2,3}*.dat
