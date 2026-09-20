#!/bin/bash

# Re-run the incremental add-label measurement of REPRODUCTION.md claim 18 and
# check it against the archived AI column it is quoted from.
#
# The claim compares two ways of handling one newly added label on the 506
# policies of `data/RW/`, given that the original data has already been
# processed:
#
#   full         - the EC partition is recomputed over the policy's entire label
#                  set. This is the `-Dopt.ai=false` (AM) stage, and its cost is
#                  the MCILabelsTimeAverage column of
#                  archive_results_new/accessrefinery_bdd_reducer_AM_20rs/RW/summary.txt
#   incremental  - the new label is added on top of the already processed data,
#                  touching only the ECs it can belong to.
#
# The incremental path is what this script measures. Note that its
# MCILabelsTimeAverage is NOT the same quantity as the column of that name in
# the BR/AR/AM archives: here it is the cost of the single computeLabels() call
# that absorbs the new label, not of the whole preprocessing pipeline. The two
# are only comparable across the AM and AI archives of the RW dataset, which is
# where claim 18 reads them from.
#
# Two phases per policy, on one fresh factory (-Dinc.independent=true):
#
#   prime    - build the policy from its label-free form, taken from the folder
#              this script writes below. Fills the factory with the processed
#              data. Untimed.
#   measure  - build the labeled policy. Exactly one computeLabels() call then
#              finds a label it has not processed; that call, and nothing else,
#              is what the reported column holds.
#
# The metric is off by default (-Dmcp.labelinc=true turns it on), so a plain run
# of running_bdd_reducer_20rs.sh is unaffected.
#
# Timings vary from run to run, so this script reports the statistics rather
# than asserting equality: what it checks is that the measured column lands in
# the incremental regime (around 1 ms per policy) and not in the full-rebuild
# regime (around 30 ms, which is what the same command line reports without
# the two labelinc properties).
#
# The -D flags must precede -jar.

set -e

JAR=target/accessrefinery-1.0.jar
PRIME=results/RW_label_free
AM_ARCHIVE=archive_results_new/accessrefinery_bdd_reducer_AM_20rs/RW/summary.txt
AI_ARCHIVE=archive_results_new/accessrefinery_bdd_reducer_AI_20rs/RW/summary.txt
OUT=result/RW/summary.txt

PY=$(command -v python3 || command -v python || true)
if [ -z "$PY" ]; then
    echo "python3 not found; it is needed to write the label-free priming corpus" >&2
    exit 1
fi

if [ ! -f "$JAR" ]; then
    echo "building $JAR"
    mvn -q clean package -DskipTests
fi

# 1. Priming input: the RW corpus with the synthesized label removed.
"$PY" tools/accessrefinery/make_label_free_rw.py data/RW "$PRIME"

# 2. Measure. Input data/RW/ -> output result/RW/, the layout of the RW folder
#    inside each archive_results_new stage directory.
rm -f "$OUT"
java -Dinc.independent=true \
     -Dmcp.labelinc=true \
     -Dmcp.labelinc.prime="$PRIME" \
     -jar "$JAR" -m -r --round 20 -f data/RW/

if [ ! -f "$OUT" ]; then
    echo "expected $OUT to be written" >&2
    exit 1
fi

# column <summary.txt> <col> : column values, one per policy, header skipped.
column() {
    awk -v c="$2" 'NR > 1 && NF >= c { print $c }' "$1"
}

stat() {
    column "$1" "$2" | sort -g | awk '
        { v[NR] = $1; s += $1 }
        END {
            if (NR == 0) { print "0 0 0 0"; exit }
            mid = (NR % 2) ? v[(NR + 1) / 2] : (v[NR / 2] + v[NR / 2 + 1]) / 2
            printf "%.2f %.2f %.2f %d\n", s / NR, mid, v[NR], NR
        }'
}

# 3. Compare with the archived columns the claim is quoted from.
read -r AM_MEAN AM_MED AM_MAX AM_N <<<"$(stat "$AM_ARCHIVE" 6)"
read -r AI_MEAN AI_MED AI_MAX AI_N <<<"$(stat "$AI_ARCHIVE" 6)"
read -r NEW_MEAN NEW_MED NEW_MAX NEW_N <<<"$(stat "$OUT" 6)"

printf 'MCILabelsTimeAverage over %d policies\n\n' "$NEW_N"
printf '%-34s %10s %10s %10s\n' 'path' 'mean' 'median' 'max'
printf '%-34s %10s %10s %10s\n' 'full (AM archive)'   "$AM_MEAN"  "$AM_MED"  "$AM_MAX"
printf '%-34s %10s %10s %10s\n' 'incremental (AI archive)' "$AI_MEAN" "$AI_MED" "$AI_MAX"
printf '%-34s %10s %10s %10s\n' 'incremental (this run)'   "$NEW_MEAN" "$NEW_MED" "$NEW_MAX"

echo
awk -v a="$NEW_MEAN" -v b="$AI_MEAN" -v f="$AM_MEAN" '
    BEGIN {
        printf "this run is %.2fx the archived incremental mean (%.2f ms x %.2f ms)\n", \
               a / b, b, a / b
        printf "full path is %.2fx this run (%.2f ms vs %.2f ms)\n", f / a, f, a
        if (a > 0 && a / b <= 3 && f / a >= 5)
            print "OK: inside the incremental regime, an order of magnitude below the full path"
        else
            print "WARNING: outside the expected regime -- this looks like a full-rebuild measurement" \
                  "\n         (check that -Dmcp.labelinc and -Dmcp.labelinc.prime are in effect)"
    }'

echo
echo "per-policy values: $OUT (MCILabelsTimeAverage column)"
