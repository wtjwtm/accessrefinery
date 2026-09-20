#!/bin/bash
mkdir -p paper_figures/archive_data/
process_dir() {
    local dir_name=$1
    local out_file=$2
    local f2="results/accessanalyzer_z3_miner_1rs/${dir_name}/summary.csv"
    local f3="results/accessanalyzer_cvc5_miner_1rs/${dir_name}/summary.csv"
    local f4="results/accessrefinery_sat_miner_10rs/${dir_name}/summary.txt"
    local f5="results/accessrefinery_bdd_miner_10rs/${dir_name}/summary.txt"
    local val2=()
    local val3=()
    local val4=()
    local val5=()
    # A missing input falls back to the 3600000 s timeout sentinel below, so a
    # run without the `cp -r archive_results/... results/` step would silently
    # produce a plausible-looking but entirely fake column. Warn instead.
    for f in "$f2" "$f3" "$f4" "$f5"; do
        [ -f "$f" ] || echo "Warning: $f not found; its column will be all timeout values" >&2
    done
    # Read f2 (CSV, 5th col = Total Time (s), needs * 1000)
    if [ -f "$f2" ]; then
        mapfile -t val2 < <(awk -F',' 'NR>1 {printf "%.1f\n", $5 * 1000}' "$f2")
    fi
    # Read f3 (CSV, 5th col = Total Time (s), needs * 1000)
    if [ -f "$f3" ]; then
        mapfile -t val3 < <(awk -F',' 'NR>1 {printf "%.1f\n", $5 * 1000}' "$f3")
    fi
    # Read f4 (TXT, whitespace delimited, 5th col = TotalTimeAverage)
    if [ -f "$f4" ]; then
        mapfile -t val4 < <(awk 'NR>1 {printf "%.2f\n", $5}' "$f4")
    fi
    # Read f5 (TXT, whitespace delimited, 5th col = TotalTimeAverage)
    if [ -f "$f5" ]; then
        mapfile -t val5 < <(awk 'NR>1 {printf "%.2f\n", $5}' "$f5")
    fi
    > "$out_file"
    for i in {0..14}; do
        local v2=${val2[$i]:-3600000.0}
        local v3=${val3[$i]:-3600000.0}
        local v4=${val4[$i]:-3600000.00}
        local v5=${val5[$i]:-3600000.00}
        echo "$((i+1)) $v2 $v3 $v4 $v5" >> "$out_file"
    done
}

# The `AccessRefinery(W/ All)` series of Figure 12: the same mining work with all
# three optimizations on. It comes from the AI stage of the four-stage pipeline,
# whose runs reduce as well as mine. The reduction is the last two columns of
# that summary (RRIOperationsTimeAverage + RRIILPSolvingTimeAverage), so the sum
# of the two before them (MCILabelsTimeAverage + MCIOperationsTimeAverage) is the
# mining cost the figure compares.
#
# This is written to its own single-column file rather than appended as another
# column of the `.dat` above, so that the columns of that file stay as they are.
ai_series() {
    local dir_name=$1
    local out_file=$2
    local spec=$3
    local src="results/accessrefinery_bdd_reducer_AI_20rs/${dir_name}/summary.txt"
    local vals=()
    [ -f "$src" ] || echo "Warning: $src not found; the AI series will be all timeout values" >&2
    if [ -f "$src" ]; then
        mapfile -t vals < <(awk -v spec="$spec" 'NR>1 {
            n = split(spec, p, "+"); s = 0
            for (i = 1; i <= n; i++) s += $p[i]
            printf "%.2f\n", s
        }' "$src")
    fi
    > "$out_file"
    for i in {0..14}; do
        echo "${vals[$i]:-3600000.00}" >> "$out_file"
    done
}

process_dir "Scalability_05Keys" "paper_figures/archive_data/Experiment-Scalability-MCI-K2.dat"
process_dir "Scalability_06Keys" "paper_figures/archive_data/Experiment-Scalability-MCI-K3.dat"
ai_series "Scalability_05Keys" "paper_figures/archive_data/Experiment-Scalability-MCI-K2-AI.dat" "6+7"
ai_series "Scalability_06Keys" "paper_figures/archive_data/Experiment-Scalability-MCI-K3-AI.dat" "6+7"
echo "Done extracting scalability MCI data."
