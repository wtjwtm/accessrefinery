#!/bin/bash

[ -d results ] || mkdir results

set -e

# generate data
#python3 helper.py

# draw
for file in gnuplot/*.plt
do
    echo "draw figure of ${file#gnuplot/}..."
    gnuplot "$file"
done