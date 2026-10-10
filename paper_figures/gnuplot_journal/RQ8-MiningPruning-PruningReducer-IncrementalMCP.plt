set terminal pdfcairo font "Times New Roman,11.77" linewidth 1 rounded fontscale 1.35 size 33.8cm, 8.5cm

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
set style line 1 lt rgb "#2b8cbe" lw 3 pt 6 ps 1.0   # A: blue circle
set style line 2 lt rgb "#74c476" lw 3 pt 2 ps 1.0   # B: green cross

# Set axis and font properties
set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.9

set bmargin screen 0.258824
set tmargin at screen 0.894118
set rmargin screen 0.86

# Output settings
set output 'results_journal/RQ8-MiningPruning-PruningReducer-IncrementalMCP.pdf'

# The canvas is 8.5 cm, half a centimetre shorter than the 9 cm it was, and the
# half centimetre came off the bottom edge with nothing else: the panels keep the
# 4.41 cm height, the fonts their size, and everything that is not below the
# panels the height it had above the canvas' top edge, which is why the vertical
# coordinates read as fractions of 8.5 and are no longer the round 0.31 and 0.80.
# The x title is the one thing that moved, up by that half centimetre and so
# towards the panels, and it keeps the 0.45 cm it leaves below itself to the
# canvas' bottom edge, so the gap from the axis down to it is 1.84 cm instead of
# 2.34 cm.
#
# The real-world panel's label moved right and down with them - 0.68 cm right,
# 0.17 cm down - and its position is the figure's rule: all four panel labels sit
# at one place within their own panel, 2.54 cm in from the panel's left edge and
# 0.53 cm below its top edge, screen 0.075 and 0.062 on this canvas, so the four
# are evenly spaced one panel pitch apart, at 0.155, 0.3875, 0.62 and 0.8525, and
# read as one row across the figure. The other three were moved to it; they sat
# 0.0425, 0.04 and 0.0375 of the canvas in from their panel's left edge, 0.36 cm
# below its top edge.

set multiplot layout 1,4 margins 0.08, 0.96, 0.269412, 0.788235 spacing 0.05

# vertical y-axis title on the far left, inside the canvas
set label "Time (ms)" rotate by 90 at screen 0.025, 0.523529 center font ",11.77"

set label "The ID of datasets" at screen 0.171, 0.052941 center font ",11.77"
set label "# of allow statements" at screen 0.636, 0.052941 center font ",11.77"

# --- Panel 1 (Real-world) ---
set log y
set format y "10^{%L}"
set xrange[0: 506]
set xtics 0,150,450
set yrange[1e-2: 1e5]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "Real-world" at screen 0.155, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/rw_p2.dat' using 1:2 w l ls 1 lw 4 notitle, \
     '' using 1:3 w l ls 2 lw 4 notitle

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label on each panel's plot, and each of them here sits at absolute
# screen coordinates, so a second pass lands on top of the first and prints as
# if the text were set in a heavier weight. The first panel draws them above;
# the panels after it must not.
unset label

# --- Panel 2 (5-Key): show key here -> legend over 1&2 ---
unset yrange
set log y
set format y "10^{%L}"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key width -0.9 Left vertical maxrows 1 reverse samplen 1 at screen 0.50, 0.984118 font ',11.77' spacing 1.2
set label "5-Key" at screen 0.3875, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/p2_05.dat' using 1:2 w lp ls 1 title 'Intent Miner (original)', \
     '' using 1:3       w lp ls 2 notitle

unset label

# --- Panel 3 (6-Key) ---
set log y
set format y "10^{%L}"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key off
unset ylabel
set label "6-Key" at screen 0.62, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/p2_06.dat' using 1:2 w lp ls 1 notitle, \
     '' using 1:3       w lp ls 2 notitle

unset label

# --- Panel 4 (5-Key*): show key here -> legend over 3&4 ---
set log y
set format y "10^{%L}"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key width -0.9 Left vertical maxrows 1 reverse samplen 1 at screen 0.95, 0.984118 font ',11.77' spacing 1.2
set label "5-Key*" at screen 0.8525, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/p2_07.dat' using 1:2 w lp ls 1 notitle, \
     '' using 1:3       w lp ls 2 title 'Intent Miner (Incremental MCP)'

unset multiplot
