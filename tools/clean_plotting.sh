#!/bin/sh

# Only files that a script or archive_data/ can put back are removed. The
# optimization-pipeline inputs (p*_*.dat, rw_*.dat) are versioned in git and
# have no source in archive_data/, so they must survive; hence no `rm -rf`.
echo "Clearing paper_figures/data"
rm -f paper_figures/data/Experiment-*.dat
cp paper_figures/archive_data/Experiment-*.dat paper_figures/data/

# Every .plt in gnuplot/ regenerates its output, so this dir can be emptied.
echo "Clearing paper_figures/results"
rm -f paper_figures/results/*

mkdir -p paper_figures/data paper_figures/results
