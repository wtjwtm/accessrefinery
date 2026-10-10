# RQ8 - Intent reducing: Original vs Pruning Reducer.
#
# Three panels: Real-world, 5-Key, 6-Key. The 5-Key* panel of the four-panel
# version of this figure is not drawn in this set.
#
# Layout: the canvas, the fonts, the three-panel band, the keys and the labels are
# the RQ5 Reducing figure's, taken over as they are - 33.8 cm by 9.5 cm, Times New
# Roman 11.77, margins 0.11355, 0.88645, 0.241263, 0.705895, spacing 0.05355, so a
# panel is 7.501 cm by 4.414 cm, and the key right-anchored at 0.95, 0.891579. That
# figure's third panel is labelled 5-Key* and this figure's is 6-Key, and this
# figure's first panel is Real-world rather than synthetic, which is the only place
# the two differ: the curves, their axes and their two colours are the ones the
# four-panel version of this figure draws. The two series carry titles, so the one
# key is drawn on the first panel that has them - panel 2 - and unset again right
# after, so it is not redrawn on panel 3.

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
set style line 2 lt rgb "#2b8cbe" lw 3 pt 6 ps 1.5   # A: blue circle
set style line 3 lt rgb "#74c476" lw 3 pt 2 ps 1.5   # B: green cross
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
# right edge at 0.95, 1.76 cm above the top of the panels.
set key width 1.5 Left vertical maxrows 1 reverse samplen 1 at screen 0.95, 0.891579 font ',11.77' spacing 2
set bmargin screen 0.241263
set tmargin at screen 0.705895
set rmargin screen 0.86

# Output settings
set output 'results/RQ8-ReducingPruning-Original-PruningReducer.pdf'

# The x axis of the first panel is a policy id and the other two are statement
# counts, so the row carries two x titles: one over the first panel, one over the
# pair behind it.
set label "Time (ms)" rotate by 90 at screen 0.0586, 0.468421 center font ",11.77"
set label "The ID of datasets" at screen 0.2245, 0.047368 center font ",11.77"
set label "# of allow statements" at screen 0.6377, 0.047368 center font ",11.77"

set multiplot layout 1,3 margins 0.11355, 0.88645, 0.241263, 0.705895 spacing 0.05355

# --- Panel 1 (Real-world): two running totals over the corpus' own order - one
# row per policy, row 0 is rw_001.json and row 505 is rw_506.json - drawn as
# lines only, the height at the right edge being the sum over all 506 policies ---
set log y
set format y "10^{%L}"
# The running totals span 0.19 ms to 8.3e2 ms, four decades with the top curve just
# inside the last one, so the axis is drawn out to 10^4 and 10^4 is left unlabelled:
# the labels run 10^-1..10^3, five of them, fewer than the eight the sorted version
# carried on 10^-2..10^5, so the every-other-decade rule that existed to thin those
# eight out is not needed here. The last decade is empty of data and carries no
# label, so the top of the panel reads as the top of the drawn range and not as a
# value the curves reach.
set yrange[1e-1: 1e4]
set ytics (1e-1, 1e0, 1e1, 1e2, 1e3)
set xrange[0: 506]
set xtics 0,150,450
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "Real-world" at screen 0.1676, 0.657368 center font ",11.77"
plot 'data/rw_p1.dat' using 1:2 smooth cumulative w l ls 2 lw 4 notitle, \
     '' using 1:3 smooth cumulative w l ls 3 lw 4 notitle

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label, every key and the y axis title on each panel's plot, and each of them
# here sits at absolute screen coordinates, so a second pass lands on top of the
# first and prints as if the text were set in a heavier weight. The first panel
# draws them above; the panels after it must not. Each panel's own label is
# therefore set just before that panel's plot and unset again after it.
unset label
unset key

# --- Panel 2 (5-Key): the panel that carries the key ---
# Each panel carries its own y axis: this one and the next take the range their
# own data spans. The first panel named the decades it wanted for its own range,
# and that list would persist into these two, so the automatic tics are asked for
# here instead. (They had been turned off for this panel, which left 5-Key and
# 6-Key with no y labels at all and - grid lines being drawn at the tics - no
# horizontal grid lines either.)
set log y
set format y "10^{%L}"
unset yrange
set ytics auto
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key width 1.5 Left vertical maxrows 1 reverse samplen 1 at screen 0.95, 0.891579 font ',11.77' spacing 2
set label "5-Key" at screen 0.443, 0.657368 center font ",11.77"
plot 'data/p1_05.dat' using 1:2 w lp ls 2 title 'Intent Reducer (original)', \
     '' using 1:3       w lp ls 3 title 'Intent Reducer (Pruning Reducer)'

unset label
unset key

# --- Panel 3 (6-Key) ---
set log y
set format y "10^{%L}"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key off
set label "6-Key" at screen 0.7185, 0.657368 center font ",11.77"
plot 'data/p1_06.dat' using 1:2 w lp ls 2 notitle, \
     '' using 1:3       w lp ls 3 notitle

unset multiplot
