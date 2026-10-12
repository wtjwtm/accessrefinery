#!/bin/bash

# Extract the plotting data of every figure of paper_figures_journal/ from results/.
#
# This is the entry point the README's "Reproducing Claims in the Paper" uses. It
# runs the five per-figure scripts in turn, each of which reads the stage folders
# under results/ and overwrites the files its own figure reads under
# paper_figures_journal/data/:
#
#   extract_RQ3-Mining.sh         Figure 14  Experiment-Scalability-MCI-K{2,3}*.dat
#   extract_RQ3-Reducing.sh       Figure 15  Experiment-Scalability-RRI-K{2,3}*.dat
#   extract_RQ7-MiningPruning.sh  Figure 18  p2_05.dat, p2_06.dat
#   extract_RQ7-ReducingPruning.sh Figure 19 p1_05.dat, p1_06.dat
#   extract_RQ8-OverviewBars.sh   Figure 20  enc_05.dat, enc_06.dat
#
# Figure 16 and the real-world panels of Figures 18 and 19 have no script here:
# they read the files the artifact ships, whose corpus is withheld for commercial
# reasons. Run tools/clean_plotting.sh first to put those shipped files back.
#
# Every path inside the per-figure scripts is relative to the repository root, so
# run this from the root, as the README does:
#
#   bash tools/figures/extract_optimization_pipeline.sh

set -e

for script in RQ3-Mining RQ3-Reducing RQ7-MiningPruning RQ7-ReducingPruning RQ8-OverviewBars
do
    echo "Extracting ${script}..."
    bash "tools/figures/extract_${script}.sh"
done
