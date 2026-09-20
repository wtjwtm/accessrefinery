#!/bin/bash
# Regenerate the plotting data of the four optimization-pipeline figures
# (Figures 16-19) from the per-policy summary.txt of the four stage archives.
#
# Stage folders under results/, one per stage of the BR -> AR -> AM -> AI pipeline:
#
#   accessrefinery_bdd_reducer_20rs/     BR  (-Dopt.ar=false -Dopt.am=false -Dopt.ai=false)
#   accessrefinery_bdd_reducer_AR_20rs/  AR  (-Dopt.am=false -Dopt.ai=false)
#   accessrefinery_bdd_reducer_AM_20rs/  AM  (-Dopt.ai=false)
#   accessrefinery_bdd_reducer_AI_20rs/  AI  (defaults)
#
# The shipped copies of these four folders are in archive_results_new/.
#
# summary.txt columns (1-based):
#   1 NumberStatement          2 NumberMCI                   3 NumberRRI
#   4 MCISolvingRoundAverage   5 TotalTimeAverage            6 MCILabelsTimeAverage
#   7 MCIOperationsTimeAverage 8 RRIOperationsTimeAverage    9 RRIILPSolvingTimeAverage
#
# Each stage isolates one optimization, so each figure compares the one column
# that stage changes:
#
#   Figure 16  p_bar_ix_05/06/07.dat  TotalTimeAverage (c5) of all four stages, for
#                                     the policies of 3/6/9/12/15 statements
#              rw_br_ai.dat           TotalTimeAverage (c5, BR) vs MCILabelsTimeAverage (c6, AI)
#   Figure 17  p1_05/p6_br_ar/p1_07.dat, rw_p1.dat
#                                     RRIOperationsTimeAverage + RRIILPSolvingTimeAverage
#                                     (c8+c9), BR vs AR - the reducer's set-cover cost
#   Figure 18  p2_05/06/07.dat, rw_p2.dat
#                                     MCIOperationsTimeAverage (c7), AR vs AM - the miner's
#                                     node-computation cost
#   Figure 19  p3_05/06/07.dat, rw_p3.dat
#                                     MCILabelsTimeAverage (c6), AM vs AI - the EC cost
#
# The Scalability_* files keep summary.txt row order and number the policies 1..15.
# The RW files are sorted by their first data column, ascending, ties in file order,
# and number the rows 0..505; both columns of a row come from the same policy. The
# sort uses the computed value, not its two-decimal rendering in summary.txt: two
# policies that both print as 1.32 are still ordered by their exact sums.
#
# All outputs are CRLF, no BOM, one header line, matching the checked-in files.

set -e

BR=results/accessrefinery_bdd_reducer_20rs
AR=results/accessrefinery_bdd_reducer_AR_20rs
AM=results/accessrefinery_bdd_reducer_AM_20rs
AI=results/accessrefinery_bdd_reducer_AI_20rs

OUT=paper_figures/archive_data_new
mkdir -p "$OUT"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The real-world corpus is withheld for commercial reasons, so the four `rw_*`
# outputs are produced only when the archives are present. Every other output on
# this script's list is synthetic and regenerates unconditionally.
HAVE_RW=1
for s in "$BR" "$AR" "$AM" "$AI"; do
    [ -f "$s/RW/summary.txt" ] || HAVE_RW=0
done
if [ "$HAVE_RW" = 0 ]; then
    echo "Note: the real-world corpus is not shipped (commercial reasons)."
    echo "      Skipping rw_p1.dat, rw_p2.dat, rw_p3.dat, rw_br_ai.dat."
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

# pair_by_row <summaryA> <specA> <summaryB> <specB> <out> : rows 1..N, both columns
# taken from the same summary row.
pair_by_row() {
    readcol "$1" "$2" > "$TMP/a"
    readcol "$3" "$4" > "$TMP/b"
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' "$TMP/a" "$TMP/b" | awk '{ printf "%d\t%s\t%s\r\n", NR, $1, $2 }'
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

# pair_sorted <summaryKey> <specKey> <summaryB> <specB> <out> : sorted by the key
# column ascending, stable; column B comes from the same policy row.
pair_sorted() {
    rawcol "$1" "$2" > "$TMP/k"
    readcol "$1" "$2" > "$TMP/a"
    readcol "$3" "$4" > "$TMP/b"
    { printf 'Policy\tA\tB\r\n'
      paste -d'\t' "$TMP/k" "$TMP/a" "$TMP/b" \
        | LC_ALL=C sort -s -g -k1,1 \
        | awk -F'\t' '{ printf "%d\t%s\t%s\r\n", NR-1, $2, $3 }'
    } > "$5"
}

# --- Figure 17: BR vs AR, reducer (c8+c9) -------------------------------------
pair_by_row "$BR/Scalability_05Keys/summary.txt" 8+9 "$AR/Scalability_05Keys/summary.txt" 8+9 "$OUT/p1_05.dat"
pair_by_row "$BR/Scalability_06Keys/summary.txt" 8+9 "$AR/Scalability_06Keys/summary.txt" 8+9 "$OUT/p6_br_ar.dat"
pair_by_row "$BR/Scalability_07Keys/summary.txt" 8+9 "$AR/Scalability_07Keys/summary.txt" 8+9 "$OUT/p1_07.dat"
if [ "$HAVE_RW" = 1 ]; then
    pair_sorted "$BR/RW/summary.txt" 8+9 "$AR/RW/summary.txt" 8+9 "$OUT/rw_p1.dat"
fi

# --- Figure 18: AR vs AM, miner (c7) ------------------------------------------
pair_by_row "$AR/Scalability_05Keys/summary.txt" 7 "$AM/Scalability_05Keys/summary.txt" 7 "$OUT/p2_05.dat"
pair_by_row "$AR/Scalability_06Keys/summary.txt" 7 "$AM/Scalability_06Keys/summary.txt" 7 "$OUT/p2_06.dat"
pair_by_row "$AR/Scalability_07Keys/summary.txt" 7 "$AM/Scalability_07Keys/summary.txt" 7 "$OUT/p2_07.dat"
if [ "$HAVE_RW" = 1 ]; then
    pair_sorted "$AR/RW/summary.txt" 7 "$AM/RW/summary.txt" 7 "$OUT/rw_p2.dat"
fi

# --- Figure 19: AM vs AI, EC engine (c6) --------------------------------------
pair_by_row "$AM/Scalability_05Keys/summary.txt" 6 "$AI/Scalability_05Keys/summary.txt" 6 "$OUT/p3_05.dat"
pair_by_row "$AM/Scalability_06Keys/summary.txt" 6 "$AI/Scalability_06Keys/summary.txt" 6 "$OUT/p3_06.dat"
pair_by_row "$AM/Scalability_07Keys/summary.txt" 6 "$AI/Scalability_07Keys/summary.txt" 6 "$OUT/p3_07.dat"
if [ "$HAVE_RW" = 1 ]; then
    pair_sorted "$AM/RW/summary.txt" 6 "$AI/RW/summary.txt" 6 "$OUT/rw_p3.dat"
fi

# --- Figure 16: all four stages -----------------------------------------------
for k in 05 06 07; do
    ds="Scalability_${k}Keys"
    { printf 'idx\tBR\tAR\tAM\tAI\r\n'
      paste -d'\t' <(readcol "$BR/$ds/summary.txt" 5) <(readcol "$AR/$ds/summary.txt" 5) \
                   <(readcol "$AM/$ds/summary.txt" 5) <(readcol "$AI/$ds/summary.txt" 5) \
        | awk 'NR==3||NR==6||NR==9||NR==12||NR==15 { printf "%d\t%s\t%s\t%s\t%s\r\n", n++, $1, $2, $3, $4 }'
    } > "$OUT/p_bar_ix_$k.dat"
done
if [ "$HAVE_RW" = 1 ]; then
    {
        printf 'Policy\tBR\tAI\r\n'
        paste -d'\t' <(rawcol "$BR/RW/summary.txt" 5) <(readcol "$BR/RW/summary.txt" 5) \
                     <(readcol "$AI/RW/summary.txt" 6) \
          | LC_ALL=C sort -s -g -k1,1 \
          | awk -F'\t' '{ printf "%d\t%s\t%s\r\n", NR-1, $2, $3 }'
    } > "$OUT/rw_br_ai.dat"
fi

echo "Done extracting optimization-pipeline data into $OUT/"
if [ "$HAVE_RW" = 1 ]; then
    ls -1 "$OUT"/p*.dat "$OUT"/rw_*.dat
else
    ls -1 "$OUT"/p*.dat
fi
