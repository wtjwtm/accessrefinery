#!/bin/bash

# Draw the figures of paper_figures_journal/.
#
# This set is the panel-reduced variant of the conference-version figures: every
# figure here drops the 5-Key* panel and keeps only Real-world (where the figure has
# one), 5-Key and 6-Key. The six .plt files write their PDFs into results/ and read
# their inputs from data/; the .plt paths are relative to this directory, so the
# script enters it first.

cd "$(dirname "$0")" || exit 1

[ -d results ] || mkdir results

set -e

for file in gnuplot/*.plt
do
    echo "draw figure of ${file}..."
    gnuplot "$file"
done
