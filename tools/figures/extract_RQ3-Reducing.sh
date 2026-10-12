#!/bin/bash
# Plotting data of RQ3-Experiment-Scalability-Reducing.plt (Figure 15).
#
# Figure 15 compares the same two stages of the 10-round set as Figure 14 does -
# BR (the conference-version run with no optimization,
# results/accessrefinery_bdd_reducer_10rs) and the optimized stage (Pruning
# Reducer + Incremental MCP, results/accessrefinery_bdd_reducer_Optimized_10rs) -
# but plots the per-policy total execution time instead: c5, TotalTimeAverage.
#
# Input: results/<stage folder>/<dataset>/summary.txt. The two folders it reads
# come from README's `cp -r` steps: BR from archive_results/ (the conference
# version's archive) and the optimized stage from archive_results_journal/.
#
# Output, one pair per key count k (05 = K2, 06 = K3):
#
#   Experiment-Scalability-RRI-K{2,3}.dat        the two-panel figure's own file
#   Experiment-Scalability-RRI-K{2,3}-WAll.dat   its one-column companion
#
# The `.dat` file is space separated and carries four columns; of them this script
# writes the ones the figure draws and leaves the others as they are:
#
#   1  Access Analyzer, Z3      results/accessanalyzer_z3_reducer_1rs/<dataset>/summary.csv
#   4  AccessRefinery(Original) the BR stage, c5
#
# There is no index column in this file. The CVC5 series (column 2) and the MiniSAT
# one (column 3) are drawn by no figure of this set - they belong to the conference
# version - so they are left alone.
#
# Column 1 is the Access Analyzer summary.csv's total time of the run in seconds,
# scaled to milliseconds and held at the 3600000 ms timeout sentinel, the shape the
# archived file has: a policy the baseline did not finish has no row and takes the
# sentinel. The file is space separated, so its two decimals are kept.
#
# The series the figure calls AccessRefinery(Optimized) is the file's own W/All
# companion, taken from the optimized stage of the same 10 rounds.
#
# Every column above is replaced only when its source is there. A source that is
# missing is reported and that column keeps the value the shipped file already has.
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
# Put the values of <src> into column <col> of <file>. The RRI file, being space
# separated, keeps the two decimals and passes no `trim`. A source that is not there
# is reported and the column keeps the value it already has.
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

# rq3_fill_wall <src> <spec> <file> : the one-column W/All companion, the series the
# figure calls AccessRefinery(Optimized). It keeps the two decimals.
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

# Figure 15: reduction, c5 (TotalTimeAverage) of the BR stage in the file's column 4
# (space separated), and of the optimized stage in its W/All companion.
rq3_rri() {
    local k=$1 ds n dat wall
    ds=$(ds_of "$k"); n=$(k_index "$k")
    dat="$OUT/Experiment-Scalability-RRI-K$n.dat"
    wall="$OUT/Experiment-Scalability-RRI-K$n-WAll.dat"
    rq3_fill_col "$dat" " " 1 "$ROOT/accessanalyzer_z3_reducer_1rs/$ds/summary.csv" aa "" 3600000.0
    rq3_fill_col "$dat" " " 4 "$ROOT/accessrefinery_bdd_reducer_10rs/$ds/summary.txt" txt 5 3600000.00
    rq3_fill_wall "$ROOT/accessrefinery_bdd_reducer_Optimized_10rs/$ds/summary.txt" 5 "$wall"
}

rq3_rri 05
rq3_rri 06

echo "Done extracting RQ3-Reducing data into $OUT/"
ls -1 "$OUT"/Experiment-Scalability-RRI-K{2,3}*.dat
