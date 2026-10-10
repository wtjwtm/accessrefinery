# RQ3 - Scalability of the intent mining phase.
#
# Two panels: 5-Key, 6-Key. The 5-Key* panel of the three-panel version of this
# figure is not drawn in this set.
#
# Layout: the canvas, the two-panel multiplot band, the two panel labels and the
# key are the ones this figure used before the 5-Key* panel was added. The four
# curves, their axes and their colours are the ones the three-panel version draws.

set terminal pdfcairo font "Times New Roman, 13" linewidth 1 rounded fontscale 1.35 size 31cm, 11cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt 0 lc rgb "#808080"

# Remove top and right borders for clarity
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# The panels' y axis is a log axis and gnuplot marks every decade on it by
# itself, minor tics and all: the reference figure shows a tic, a line and a
# label at 10^1 through 10^7, with the 2..9 tics between them. That is what
# `set ytics 10, 10` in each panel asks for.
set mytics

# Set line styles with distinct colors and thickness
set style line 1 lt rgb "#253494" lw 3 pt 8 ps 1.5
set style line 2 lt rgb "#2b8cbe" lw 3 pt 6 ps 1.5
set style line 3 lt rgb "#74c476" lw 3 pt 2 ps 1.5
set style line 4 lt rgb "#00A000" lw 3 pt 9 ps 1.5
set style line 5 lt rgb "#d4b9da" lw 3 pt 12 ps 1.5
set style line 6 lt rgb "#4F4F4F" lw 3
set style line 7 lt rgb "#bd0026" lw 3 pt 10 ps 1.5

# Set axis and font properties
set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.9

# One key, its four entries in two columns in two rows, above the panels.
#
# The left column (the two Access Analyzer entries) sits 0.1 of the canvas width
# further left than an auto-width key would put it; the right column and every
# other label of the figure stay where they were. gnuplot has no per-column
# offset for a key, so the two knobs that do move the columns are used together:
# a wider `width` widens the key box, which slides the left column 2 cm left for
# every 1 cm the right column moves, and the anchor then slides the box back to
# the right. width 7.5 + anchor 1.0801 cancel exactly on the right column and
# leave the left column 3.10 cm (= 0.1 x 31 cm) further left.
set key width 7.5 Left maxrows 2 reverse samplen 1 at screen 1.0801, 0.95 font ',13' spacing 1.2
set bmargin screen 0.33
set tmargin at screen 0.9
set rmargin screen 0.87

# Output settings
set output 'results/RQ3-Experiment-Scalability-Mining.pdf'

set label "Time (ms)" rotate by 90 at screen 0.0526, 0.5105 center font ", 13"
set multiplot layout 1,2 margins 0.13, 0.96, 0.31, 0.711 spacing 0.20

# --- Panel 1 (5-Key) ---
set log y
set format y "10^{%L}"
set xrange[-1: 16]
set xtics 3
set yrange[1e1: 1e7]
set ytics 10, 10
set size 1, 0.9
set label "5-Key" at screen 0.1758, 0.6665 center font ", 13"
set label "# of allow statements" at screen 0.2875, 0.158 center font ", 13"
plot 'data/Experiment-Scalability-MCI-K2.dat' using ($0+1):2 w lp ls 1 title 'Access Analyzer(Z3)', \
     '' using ($0+1):3  w lp ls 2 title 'Access Analyzer(CVC5)', \
     '' using ($0+1):5  w lp ls 3 title 'AccessRefinery(Original)', \
     'data/Experiment-Scalability-MCI-K2-WAll.dat' using ($0+1):1 w lp ls 7 title 'AccessRefinery(Optimized)'

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label and every key on each panel's plot, and each of them here sits at absolute
# screen coordinates, so a second pass lands on top of the first and prints as
# if the text were set in a heavier weight. The first panel draws them above;
# the panels after it must not. Each panel's own label is therefore set just
# before that panel's plot and unset again after it.
unset label
unset key

# --- Panel 2 (6-Key) ---
set log y
set format y "10^{%L}"
set xrange[-1: 16]
set xtics 3
set yrange[1e1: 1e7]
set ytics 10, 10
set size 1, 0.9
set label "6-Key" at screen 0.7042, 0.6665 center font ", 13"
set label "# of allow statements" at screen 0.8025, 0.158 center font ", 13"
plot 'data/Experiment-Scalability-MCI-K3.dat' using ($0+1):2 w lp ls 1 notitle, \
     '' using ($0+1):3  w lp ls 2 notitle, \
     '' using ($0+1):5  w lp ls 3 notitle, \
     'data/Experiment-Scalability-MCI-K3-WAll.dat' using ($0+1):1 w lp ls 7 notitle

unset multiplot

