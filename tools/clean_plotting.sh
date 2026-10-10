#!/bin/sh

# The data directories are the inputs, not outputs: gnuplot reads them, and the
# real-world columns they carry cannot be regenerated from anything in the tree
# (the corpus itself is withheld). So they are never touched here.
#
# Only the rendered PDFs are cleared. Every .plt in gnuplot_journal/ regenerates its
# output, so results_journal/ can be emptied safely.

echo "Clearing paper_figures/results_journal"
rm -f paper_figures/results_journal/*

mkdir -p paper_figures/results_journal
