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

# three stage colors (Original / Pruning Reducer / Incremental MCP)
set style line 1 lt rgb "#253494" lw 7
set style line 2 lt rgb "#2b8cbe" lw 2
set style line 3 lt rgb "#00A000" lw 2
# W/O All curve of the real-world panel: the Original stage, drawn in that
# stage's own colour - the #253494 the Original bars of the three key panels are
# outlined in - so the one stage the real-world panel shares with those panels
# reads as one colour across the figure, as the legend swatch at the top and the
# other two curves of the panel already had it. The dash stands for the bars'
# hatch and is kept: this curve runs close to the Pruning Reducer one over most of its range,
# and the pattern is what tells the two apart. No bar uses this style line.
set style line 4 lt rgb "#253494" lw 2 dt 2
# Original's hatched bars are outlined: its own style line is the thick one, and
# an outline at that width spills outside the box and makes the bars bigger than
# the other two stages'. They are drawn with this same colour, thin, instead.
set style line 5 lt rgb "#253494" lw 2

set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.16

set bmargin screen 0.258824
set tmargin at screen 0.894118
set rmargin screen 0.86

# Output settings
set output 'results_journal/RQ7-Optimization-Overview-Bars-3Stage.pdf'

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
# The four panel labels are the exception besides the x title: they moved right
# and down by 2% of the canvas - 0.68 cm right, 0.17 cm down - so they sit
# further into their panels than the rest of the family's do.

set multiplot layout 1,4 margins 0.08, 0.96, 0.269412, 0.788235 spacing 0.05

# vertical y-axis title on the far left, inside the canvas
set label "Time (ms)" rotate by 90 at screen 0.025, 0.523529 center font ",11.77"

set label "The ID of datasets" at screen 0.171, 0.052941 center font ",11.77"
set label "# of allow statements" at screen 0.636, 0.052941 center font ",11.77"

# Manual legend for the three stages of the bar panels, one row, the only legend of
# the figure: the row is placed so that it sits about the middle of the canvas, its
# three blocks spanning roughly 0.22 to 0.79.
set object 1 rect from screen 0.220, 0.953412 to screen 0.248, 0.980941 fc rgb "#253494" fillstyle pattern 1 border lc rgb "#253494" lw 1
set object 2 rect from screen 0.420, 0.953412 to screen 0.448, 0.980941 fc rgb "#2b8cbe" fillstyle pattern 5 border lc rgb "#2b8cbe" lw 1
set object 3 rect from screen 0.650, 0.953412 to screen 0.678, 0.980941 fc rgb "#00A000" fs solid noborder
set label 20 "Original"          at screen 0.256, 0.968235 left font ",11.77"
set label 21 "Pruning Reducer"   at screen 0.456, 0.968235 left font ",11.77"
set label 22 "Incremental MCP"   at screen 0.686, 0.968235 left font ",11.77"

# ------------------------------------------------------------------
# Panel 1 (Real-world): three total-time curves, each sorted on its own value, so
# the panel reads as three sorted distributions rather than as one policy per row.
# All three are whole-run totals per policy: Pruning Reducer and W/ All are this
# re-run's Pruning Reducer and Incremental MCP stages, W/O All is the original
# run's mining and reducing columns added
# together, so the three are the same quantity;
# tools/figures/extract_optimization_pipeline_10rs.sh says where each comes from. No key is drawn here: the figure keeps one legend only, the three
# stages of the bar panels.
# ------------------------------------------------------------------
set log y
set format y "10^{%L}"
set xrange[0: 506]
set xtics 0,150,450
set yrange[1e-2: 1e5]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "Real-world" at screen 0.155, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/rw_bar3.dat' using 1:2 w l ls 4 lw 4 title 'W/O All', \
     '' using 1:3 w l ls 2 lw 4 title 'Pruning Reducer', \
     '' using 1:4 w l ls 3 lw 4 title 'W/ All'

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label and every object on each panel's plot, and each of them here sits at absolute
# screen coordinates, so a second pass lands on top of the first and prints as
# if the text were set in a heavier weight. The first panel draws them above;
# the panels after it must not.
unset label
unset object

# ------------------------------------------------------------------
# Panels 2-4: manual boxes, explicit x offsets, policy 3/6/9/12/15 at 0/1/2/3/4.
# The three stage names are carried by the manual legend at the top of the canvas;
# the plots still name their series, but no key is drawn for them.
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder

# --- Panel 2 (5-Key) ---
set log y
set format y "10^{%L}"
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Key" at screen 0.375, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/bar3_05.dat' using ($1-0.17):2 w boxes ls 5 fs pattern 1 border title 'Original', \
     '' using ($1):3                         w boxes ls 2 fs pattern 5 border title 'Pruning Reducer', \
     '' using ($1+0.17):4                    w boxes ls 3 fs solid 1.0 noborder title 'Incremental MCP'

unset label
unset object

# --- Panel 3 (6-Key) ---
set log y
set format y "10^{%L}"
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Key" at screen 0.605, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/bar3_06.dat' using ($1-0.17):2 w boxes ls 5 fs pattern 1 border notitle, \
     '' using ($1):3                         w boxes ls 2 fs pattern 5 border notitle, \
     '' using ($1+0.17):4                    w boxes ls 3 fs solid 1.0 noborder notitle

unset label
unset object

# --- Panel 4 (5-Key*) ---
set log y
set format y "10^{%L}"
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Key*" at screen 0.835, 0.725882 center font ",11.77"
plot 'archive_data_journal/10rs/bar3_07.dat' using ($1-0.17):2 w boxes ls 5 fs pattern 1 border notitle, \
     '' using ($1):3                         w boxes ls 2 fs pattern 5 border notitle, \
     '' using ($1+0.17):4                    w boxes ls 3 fs solid 1.0 noborder notitle

unset multiplot
