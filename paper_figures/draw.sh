#!/bin/bash

[ -d results ] || mkdir results
[ -d results_new ] || mkdir results_new

set -e

# generate data
#python3 helper.py

# draw
for file in gnuplot/*.plt gnuplot_new/*.plt
do
    echo "draw figure of ${file}..."
    gnuplot "$file"
done
