# RQ3 - Scalability of the intent reducing phase.
#
# Two panels: 5-Key, 6-Key. The 5-Key* panel of the three-panel version of this
# figure is not drawn in this set.
#
# Layout: the canvas, the two-panel multiplot band, the two panel labels and the
# key are the ones this figure used before the 5-Key* panel was added. The four
# curves, their axes and their colours are the ones the three-panel version draws.

set terminal pdfcairo font "Times New Roman, 13" linewidth 1 rounded fontscale 1.35 size 26cm, 9cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

# Remove top and right borders for clarity
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# The panels' y axis is a log axis, so gnuplot would put a tic on every decade
# by itself, on top of the four that `set ytics 10, 100` in each panel asks for.
# Those extra ones are the axis' minor tics and they are off here, which leaves
# the y axis showing the odd powers and nothing else: no mark, no line and no
# label at 10^2, 10^4, 10^6 or 10^8. Only the y axis: the x axis keeps its own
# minor tics between the majors `set xtics 3` spaces out.
unset mytics

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
set key width 0 Left maxrows 2 reverse samplen 1 at screen 0.98, 0.97 font ',13' spacing 0.80
set bmargin screen 0.33
set tmargin at screen 0.9
set rmargin screen 0.87

# Output settings
set output 'results/RQ3-Experiment-Scalability-Reducing.pdf'

set label "Time (ms)" rotate by 90 at screen 0.0586, 0.555 center font ", 13"
set label "# of allow statements" at screen 0.54, 0.06 center font ", 13"

set multiplot layout 1,2 margins 0.13, 0.96, 0.31, 0.80 spacing 0.09

# --- Panel 1 (5-Key) ---
set log y
set format y "10^{%L}"
set xrange[-1: 16]
set xtics 3
set yrange[10: 1e8]
set ytics 10, 100
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "5-Key" at screen 0.21, 0.75 center font ", 13"
plot 'data/Experiment-Scalability-RRI-K2.dat' using ($0+1):1 w lp ls 1 title 'Baseline(Z3)', \
     '' using ($0+1):2  w lp ls 2 title 'Baseline(CVC5)', \
     '' using ($0+1):4  w lp ls 3 title 'AccessRefinery(W/O All)', \
     'data/Experiment-Scalability-RRI-K2-WAll.dat' using ($0+1):1 w lp ls 7 title 'AccessRefinery(W/ All)'

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
set yrange[10: 1e8]
set ytics 10, 100
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "6-Key" at screen 0.67, 0.75 center font ", 13"
plot 'data/Experiment-Scalability-RRI-K3.dat' using ($0+1):1 w lp ls 1 notitle, \
     '' using ($0+1):2  w lp ls 2 notitle, \
     '' using ($0+1):4  w lp ls 3 notitle, \
     'data/Experiment-Scalability-RRI-K3-WAll.dat' using ($0+1):1 w lp ls 7 notitle

unset multiplot

