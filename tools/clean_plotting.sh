#!/bin/sh

# Reset both plotting directories of paper_figures_journal/ to their shipped
# state, so that a run of the extraction scripts and of draw.sh afterwards
# produces every figure from that run and nothing is silently carried over.
#
# data/ holds the plotting inputs of the six figures. Every file in it is either
# kept in archive_data_journal/ or recomputed from results/ by the per-figure
# extraction scripts under tools/figures/, which is what makes the `rm -rf`
# below safe:
#
#   archive_data_journal/  the shipped copy of every file data/ starts with,
#                          including the ones no script of this tree can
#                          regenerate - the real-world panels rw_p1.dat /
#                          rw_p2.dat and the Experiment-*-RealWorld.dat files,
#                          whose corpus is withheld, and the
#                          Experiment-Effectiveness-* files, which belong to the
#                          conference-version archive.
#   tools/figures/         extract_RQ3-Mining.sh, extract_RQ3-Reducing.sh,
#                          extract_RQ7-MiningPruning.sh,
#                          extract_RQ7-ReducingPruning.sh and
#                          extract_RQ8-OverviewBars.sh overwrite the rest from
#                          the stage folders under results/.
#
# So after a clean, data/ is exactly the shipped set again: a figure whose
# sources have not been regenerated draws the numbers it shipped with, and one
# whose sources have been drawn again picks up the new ones.
#
# results/ holds only rendered PDFs, and every .plt in gnuplot/ regenerates its
# output, so it can be emptied outright.

echo "Clearing paper_figures_journal/data"
rm -rf paper_figures_journal/data
mkdir -p paper_figures_journal/data
cp paper_figures_journal/archive_data_journal/*.dat paper_figures_journal/data/

echo "Clearing paper_figures_journal/results"
rm -rf paper_figures_journal/results
mkdir -p paper_figures_journal/results
