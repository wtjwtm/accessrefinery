#!/bin/sh

# Only the rendered PDFs are cleared. Every .plt in paper_figures_journal/gnuplot/
# regenerates its output, so paper_figures_journal/results/ can be emptied safely.

echo "Clearing paper_figures_journal/results"
rm -f paper_figures_journal/results/*

mkdir -p paper_figures_journal/results
