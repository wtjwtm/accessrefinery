#!/bin/sh

# The two data directories are the inputs, not outputs: gnuplot reads them, and
# nothing in this artifact can put back three of the files in archive_data/
# (Experiment-Effectiveness-RealWorld.dat, Experiment-Scalability-MCI-RealWorld.dat
# and Experiment-Scalability-RRI-RealWorld.dat have no generator script anywhere
# in the tree). So they are never touched here.
#
# Only the rendered PDFs are cleared. Every .plt in gnuplot/ and gnuplot_new/
# regenerates its output, so both results directories can be emptied safely.

echo "Clearing paper_figures/results"
rm -f paper_figures/results/*

echo "Clearing paper_figures/results_new"
rm -f paper_figures/results_new/*

mkdir -p paper_figures/results paper_figures/results_new
