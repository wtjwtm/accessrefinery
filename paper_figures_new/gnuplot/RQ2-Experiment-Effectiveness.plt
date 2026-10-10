# RQ2 - Experiment Effectiveness.
#
# Three panels: Real-world, 5-Key, 6-Key. The 5-Key* panel of the four-panel
# version of this figure is not drawn in this set.
#
# Layout: the canvas, the fonts, the three-panel band, the keys and the labels are
# the RQ5 Reducing figure's, taken over as they are - 33.8 cm by 9.5 cm, Times New
# Roman 11.77, margins 0.11355, 0.88645, 0.241263, 0.705895, spacing 0.05355, so a
# panel is 7.501 cm by 4.414 cm, and the key right-anchored at 0.85, 0.891579. That
# figure's third panel is labelled 5-Key* and this figure's is 6-Key, and this
# figure's first panel is Real-world rather than synthetic, which is the only place
# the two differ: the curves and their two colours are the ones the four-panel
# version of this figure draws.

set terminal pdfcairo font "Times New Roman,11.77" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9.5cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

# Remove top and right borders for clarity
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# Set line styles with distinct colors and thickness
set style line 1 lt rgb "#253494" lw 3 pt 8 ps 1.5
set style line 2 lt rgb "#2b8cbe" lw 3 pt 6 ps 1.5   # Before Reducing: blue circle
set style line 3 lt rgb "#74c476" lw 3 pt 2 ps 1.5   # After Reducing: green cross
set style line 4 lt rgb "#00A000" lw 3 pt 9 ps 1.5
set style line 5 lt rgb "#d4b9da" lw 3 pt 12 ps 1.5
set style line 6 lt rgb "#4F4F4F" lw 3

# Set axis and font properties
set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.9

# The one legend of the figure, its two entries in one row across the top of the
# canvas: a key this wide cannot be fitted into a single 7.50 cm panel, and gnuplot
# drops entries it cannot fit rather than warning. The box is right-anchored, its
# right edge at 0.75, 1.76 cm above the top of the panels.
set key width 1.5 Left vertical maxrows 1 reverse samplen 1 at screen 0.75, 0.891579 font ',11.77' spacing 2
set bmargin screen 0.241263
set tmargin at screen 0.705895
set rmargin screen 0.86

# Output settings
set output 'results/RQ2-Experiment-Effectiveness.pdf'

set label "# of Intents" rotate by 90 at screen 0.0586, 0.468421 center font ",11.77"
set label "The ID of datasets" at screen 0.5, 0.047368 center font ",11.77"

set multiplot layout 1,3 margins 0.11355, 0.88645, 0.241263, 0.705895 spacing 0.05355

# --- Panel 1 (Real-world): lines only, no point markers ---
set yrange[0: 90]
set ytics 20
set xrange[0: 520]
set xtics 150
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "Real-world" at screen 0.1676, 0.647368 center font ",11.77"
plot 'data/Experiment-Effectiveness-RealWorld.dat' using 2 w l ls 2 t'Before Reducing', \
	'' using 3 w l ls 3 t'After Reducing'

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label, every key and the y axis title on each panel's plot, and each of them
# here sits at absolute screen coordinates, so a second pass lands on top of the
# first and prints as if the text were set in a heavier weight. The first panel
# draws them above; the panels after it must not. Each panel's own label is
# therefore set just before that panel's plot and unset again after it.
unset label
unset key

# --- Panel 2 (5-Key) ---
set log y
set format y "10^{%L}"
unset yrange
set xrange[0: 15]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "5-Key" at screen 0.443, 0.647368 center font ",11.77"
plot 'data/Experiment-Effectiveness-Synthetic-K2.dat' using ($0+1):2 w lp ls 2 t'Before Reducing', \
	'' using ($0+1):1 w lp ls 3 t'After Reducing'

unset label

# --- Panel 3 (6-Key) ---
set log y
set format y "10^{%L}"
set xrange[0: 15]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "6-Key" at screen 0.7185, 0.647368 center font ",11.77"
plot 'data/Experiment-Effectiveness-Synthetic-K3.dat' using ($0+1):2 w lp ls 2 t'Before Reducing', \
	'' using ($0+1):1 w lp ls 3 t'After Reducing'

unset multiplot
