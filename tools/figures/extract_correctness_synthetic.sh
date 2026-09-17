#!/bin/bash
# Generate plot data for Experiment-Correctness-Synthetic.dat

SUMMARY_FILE="results/accessrefinery_bdd_miner_10rs/Correctness/summary.txt"
OUTPUT_FILE="paper_figures/data/Experiment-Correctness-Synthetic.dat"

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Skip the header (NR>1)
# $2 is the NumberMCI column
#
# A missing input used to leave a zero-byte $OUTPUT_FILE behind while still
# printing "Extracted", which blanks the figure silently. Warn and leave the
# previous file alone instead:
#   cp -r archive_results/accessrefinery_bdd_miner_10rs/Correctness results/accessrefinery_bdd_miner_10rs/
if [ -f "$SUMMARY_FILE" ]; then
    awk 'NR>1 {print NR-1 "\t" $2}' "$SUMMARY_FILE" > "$OUTPUT_FILE"
    echo "Extracted $OUTPUT_FILE from $SUMMARY_FILE"
else
    echo "Warning: File $SUMMARY_FILE not found" >&2
fi
