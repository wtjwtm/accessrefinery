#!/bin/bash

# Only gnuplot_journal/ is drawn: these are the figures of the extension experiment
# (the three-stage optimization pipeline, Figures 18-21). The figures of the
# original submission lived in gnuplot/ with their PDFs in results/, and both
# directories were moved out of this artifact.

[ -d results_journal ] || mkdir results_journal

set -e

# generate data
#python3 helper.py

# draw
for file in gnuplot_journal/*.plt
do
    echo "draw figure of ${file}..."
    gnuplot "$file"
done
