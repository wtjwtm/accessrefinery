#!/bin/sh

# Reset both plotting directories of paper_figures_journal/ to the state a run of
# the extraction scripts and of draw.sh afterwards expects, so that every figure is
# produced from that run and nothing is silently carried over.
#
# data/ holds the plotting inputs of the six figures. Only six of them cannot be
# built by anything in this tree - the real-world `RW` corpus is not public, so the
# runs that read it cannot be repeated and no script of this repository writes those
# files - and those six are what archive_data_journal/ keeps and what the `cp` below
# restores:
#
#   archive_data_journal/  rw_p1.dat and rw_p2.dat, the real-world panels of Figures
#                          18 and 19, and the four
#                          Experiment-Scalability-{MCI,RRI}-RealWorld{,-WAll}.dat of
#                          Figure 16.
#   tools/figures/         extract_RQ3-Mining.sh, extract_RQ3-Reducing.sh,
#                          extract_RQ7-MiningPruning.sh,
#                          extract_RQ7-ReducingPruning.sh and
#                          extract_RQ8-OverviewBars.sh build the other fourteen
#                          `.dat` files of data/ whole, from the stage folders under
#                          results/.
#
# So after a clean, data/ holds those six files and nothing else: a figure whose
# sources have not been extracted yet has no data file to draw from, and one whose
# sources have been extracted again picks up the new numbers.
#
# results/ holds only rendered PDFs, and every .plt in gnuplot/ regenerates its
# output, so it can be emptied outright.

echo "Clearing paper_figures_journal/data"
rm -rf paper_figures_journal/data
mkdir -p paper_figures_journal/data
for f in rw_p1.dat rw_p2.dat \
         Experiment-Scalability-MCI-RealWorld.dat \
         Experiment-Scalability-MCI-RealWorld-WAll.dat \
         Experiment-Scalability-RRI-RealWorld.dat \
         Experiment-Scalability-RRI-RealWorld-WAll.dat; do
    cp "paper_figures_journal/archive_data_journal/$f" paper_figures_journal/data/ ||
        echo "Warning: paper_figures_journal/archive_data_journal/$f is missing" >&2
done

echo "Clearing paper_figures_journal/results"
rm -rf paper_figures_journal/results
mkdir -p paper_figures_journal/results
