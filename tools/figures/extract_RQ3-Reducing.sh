#!/bin/bash
# Plotting data of RQ3-Experiment-Scalability-Reducing.plt (Figure 15).
#
# Figure 15 compares the same two stages of the 10-round set as Figure 14 does -
# BR (the conference-version run with no optimization,
# results/accessrefinery_bdd_reducer_10rs) and the optimized stage (Pruning
# Reducer + Incremental MCP, results/accessrefinery_bdd_reducer_Optimized_10rs) -
# but plots the per-policy total execution time instead: c5, TotalTimeAverage.
#
# Output, one pair per key count k (05 = K2, 06 = K3):
#
#   Experiment-Scalability-RRI-K{2,3}.dat        the two-panel figure's own file
#   Experiment-Scalability-RRI-K{2,3}-WAll.dat   its one-column companion
#
# The `.dat` file is space separated, carries four columns and is written whole: every
# one of them is built here, so nothing of it has to be shipped with the artifact.
# There is no index column in this file.
#
#   1  Access Analyzer, Z3      results/accessanalyzer_z3_reducer_1rs/<dataset>/summary.csv
#   2  Access Analyzer, CVC5    results/accessanalyzer_cvc5_reducer_1rs/<dataset>/summary.csv
#   3  MiniSAT                  results/accessrefinery_sat_reducer_3rs/<dataset>/summary.txt
#   4  AccessRefinery(Original) the BR stage, c5
#
# Columns 1 and 2 of the Access Analyzer summary.csv are the total time of the run in
# seconds, scaled to milliseconds and held at the 3600000 ms timeout sentinel, the
# shape the archived file has: a policy the baseline did not finish has no row and
# takes the sentinel. Columns 3 and 4 are that run's TotalTimeAverage (c5), held at
# the same sentinel. The file being space separated, its two decimals are kept.
#
# The series the figure calls AccessRefinery(Optimized) is the file's own W/All
# companion, taken from the optimized stage of the same 10 rounds.
#
# Every source has to be there. The file is built from scratch, so a source that is
# missing means the figure's data cannot be produced at all: the script reports it and
# writes no file, rather than one with invented numbers in place of the missing series.
#
# Input: the four folders above under results/, all of which come from README's
# `cp -r` steps (the Access Analyzer ones and the BR stage from archive_results/, the
# optimized stage from archive_results_journal/).
#
# summary.txt columns (1-based):
#   1 NumberStatement          2 NumberMCI                   3 NumberRRI
#   4 MCISolvingRoundAverage   5 TotalTimeAverage            6 MCILabelsTimeAverage
#   7 MCIOperationsTimeAverage 8 RRIOperationsTimeAverage    9 RRIILPSolvingTimeAverage
#
# All outputs are CRLF, no BOM, matching the checked-in files.

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

# The index the file name of a key count carries; the figure numbers its datasets
# 2 and 3, after the paper's K2 and K3.
k_index() {
    case "$1" in
        05) echo 2 ;;
        06) echo 3 ;;
    esac
}

# rq3_src_col <src> <mode> <spec> [cap] : the values of one source column, one per row
# of that source, in file order. Mode `aa` is an Access Analyzer summary.csv, whose
# fifth column is the total time of the run in seconds: it is printed in milliseconds,
# the unit of the `.dat` files. Mode `txt` is a tool summary.txt, <spec> being a column
# number or a "+" sum such as 6+7. A value past <cap> is held at it, the run having hit
# the 3600000 ms timeout.
rq3_src_col() {
    local src=$1 mode=$2 spec=$3 cap=$4
    case "$mode" in
        aa)
            awk -F',' -v cap="$cap" 'NR>1 {
                t = $5 * 1000
                if (cap != "" && t > cap) t = cap
                printf "%.1f\n", t
            }' "$src" ;;
        txt)
            awk -v spec="$spec" -v cap="$cap" 'NR>1 {
                n = split(spec, p, "+"); s = 0
                for (i = 1; i <= n; i++) s += $p[i]
                if (cap != "" && s > cap) s = cap
                printf "%.2f\n", s
            }' "$src" ;;
    esac
}

# rq3_pad <sentinel> : read one value per row and write the 15 policies of a `.dat`
# file, a policy the source has no row for taking <sentinel>.
rq3_pad() {
    awk -v sent="$1" '{ v[NR] = $0 }
        END { for (i = 1; i <= 15; i++) printf "%s\n", (i in v ? v[i] : sent) }'
}

# rq3_col <src> <mode> <spec> <sentinel> [trim] [cap] : the 15 lines of one column
# of the file. The RRI file, being space separated, keeps the two decimals and passes
# no `trim`.
rq3_col() {
    local src=$1 mode=$2 spec=$3 sent=$4 trim=$5 cap=$6
    rq3_src_col "$src" "$mode" "$spec" "$cap" > "$TMP/src"
    rq3_pad "$sent" < "$TMP/src" > "$TMP/col"
    if [ "$trim" = trim ]; then
        sed -e '/\./!b' -e 's/0*$//' -e 's/\.$//' "$TMP/col" > "$TMP/col.t"
        mv "$TMP/col.t" "$TMP/col"
    fi
    cat "$TMP/col"
}

# Figure 15: reduction. The four series of the file: the two Access Analyzer backends,
# the MiniSAT one and the BR stage. A source that is not there takes the whole file
# down with a report; the W/All companion is written on its own, so a missing
# optimized stage costs the Optimized series and nothing else.
rq3_rri() {
    local k=$1 ds n dat wall
    ds=$(ds_of "$k"); n=$(k_index "$k")
    dat="$OUT/Experiment-Scalability-RRI-K$n.dat"
    wall="$OUT/Experiment-Scalability-RRI-K$n-WAll.dat"

    local s_z3="$ROOT/accessanalyzer_z3_reducer_1rs/$ds/summary.csv"
    local s_cvc5="$ROOT/accessanalyzer_cvc5_reducer_1rs/$ds/summary.csv"
    local s_sat="$ROOT/accessrefinery_sat_reducer_3rs/$ds/summary.txt"
    local s_bdd="$ROOT/accessrefinery_bdd_reducer_10rs/$ds/summary.txt"
    local s_opt="$ROOT/accessrefinery_bdd_reducer_Optimized_10rs/$ds/summary.txt"

    local missing=
    local f
    for f in "$s_z3" "$s_cvc5" "$s_sat" "$s_bdd"; do
        [ -f "$f" ] || missing="$missing $f"
    done
    if [ -n "$missing" ]; then
        echo "Warning: $(basename "$dat") is not written; source(s) missing:$missing" >&2
    else
        rq3_col "$s_z3"  aa ""   3600000.0  "" 3600000 > "$TMP/c1"
        rq3_col "$s_cvc5" aa ""  3600000.0  "" 3600000 > "$TMP/c2"
        rq3_col "$s_sat" txt 5   3600000.00 "" 3600000 > "$TMP/c3"
        rq3_col "$s_bdd" txt 5   3600000.00 ""         > "$TMP/c4"
        paste -d' ' "$TMP/c1" "$TMP/c2" "$TMP/c3" "$TMP/c4" \
            | awk '{ printf "%s\r\n", $0 }' > "$dat"
    fi

    if [ ! -f "$s_opt" ]; then
        echo "Warning: $(basename "$wall") is not written; source $s_opt is missing" >&2
    else
        rq3_col "$s_opt" txt 5 3600000.00 > "$TMP/wall"
        awk '{ printf "%s\r\n", $0 }' "$TMP/wall" > "$wall"
    fi
}

rq3_rri 05
rq3_rri 06

echo "Done extracting RQ3-Reducing data into $OUT/"
ls -1 "$OUT"/Experiment-Scalability-RRI-K{2,3}*.dat
