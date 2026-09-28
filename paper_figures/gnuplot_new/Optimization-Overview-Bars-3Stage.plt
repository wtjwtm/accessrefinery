set terminal pdfcairo font "Times New Roman,11.77" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

# Remove top and right borders for clarity
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# three stage colors (BR/AR/AI)
set style line 1 lt rgb "#253494" lw 7
set style line 2 lt rgb "#2b8cbe" lw 2
set style line 3 lt rgb "#00A000" lw 2
# W/O All reference curve of the real-world panel: dashed grey, no bar uses it
set style line 4 lt rgb "#7f7f7f" lw 2 dt 2
# Original's hatched bars are outlined: its own style line is the thick one, and
# an outline at that width spills outside the box and makes the bars bigger than
# the other two stages'. They are drawn with this same colour, thin, instead.
set style line 5 lt rgb "#253494" lw 2

set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.16

set bmargin screen 0.30
set tmargin at screen 0.90
set rmargin screen 0.86

# Output settings
set output 'results_new/Optimization-Overview-Bars-3Stage.pdf'

set multiplot layout 1,4 margins 0.08, 0.96, 0.31, 0.80 spacing 0.05

# vertical y-axis title on the far left, inside the canvas
set label "Time (ms)" rotate by 90 at screen 0.025, 0.55 center font ",11.77"

set label "The ID of datasets" at screen 0.171, 0.05 center font ",11.77"
set label "# of allow statements" at screen 0.636, 0.05 center font ",11.77"

# Manual legend for the three stages of the bar panels, one row, the only legend of
# the figure: the row is placed so that it sits about the middle of the canvas, its
# three blocks spanning roughly 0.22 to 0.79.
set object 1 rect from screen 0.220, 0.956 to screen 0.248, 0.982 fc rgb "#253494" fillstyle pattern 1 border lc rgb "#253494" lw 1
set object 2 rect from screen 0.420, 0.956 to screen 0.448, 0.982 fc rgb "#2b8cbe" fillstyle pattern 5 border lc rgb "#2b8cbe" lw 1
set object 3 rect from screen 0.650, 0.956 to screen 0.678, 0.982 fc rgb "#00A000" fs solid noborder
set label 20 "Original"          at screen 0.256, 0.970 left font ",11.77"
set label 21 "Pruning Reducer"   at screen 0.456, 0.970 left font ",11.77"
set label 22 "Incremental MCP"   at screen 0.686, 0.970 left font ",11.77"

# ------------------------------------------------------------------
# Panel 1 (Real-world): three total-time curves, each sorted on its own value, so
# the panel reads as three sorted distributions rather than as one policy per row.
# All three are whole-run totals per policy: AR and W/ All are this re-run's AR and
# AI stages, W/O All is the original run's mining and reducing columns added
# together, so the three are the same quantity;
# tools/figures/extract_optimization_pipeline_10b.sh says where each comes from. No key is drawn here: the figure keeps one legend only, the three
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
set label "Real-world" at screen 0.135, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/rw_bar3.dat' using 1:2 w l ls 4 lw 4 title 'W/O All', \
     '' using 1:3 w l ls 2 lw 4 title 'AR', \
     '' using 1:4 w l ls 3 lw 4 title 'W/ All'

# ------------------------------------------------------------------
# Panels 2-4: manual boxes, explicit x offsets, policy 3/6/9/12/15 at 0/1/2/3/4.
# The three stage names are carried by the manual legend at the top of the canvas;
# the plots still name their series, but no key is drawn for them.
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder

# --- Panel 2 (5-Keys) ---
set log y
set format y "10^{%L}"
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Keys" at screen 0.355, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/bar3_05.dat' using ($1-0.17):2 w boxes ls 5 fs pattern 1 border title 'BR', \
     '' using ($1):3                         w boxes ls 2 fs pattern 5 border title 'AR', \
     '' using ($1+0.17):4                    w boxes ls 3 fs solid 1.0 noborder title 'AI'

# --- Panel 3 (6-Keys) ---
set log y
set format y "10^{%L}"
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Keys" at screen 0.585, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/bar3_06.dat' using ($1-0.17):2 w boxes ls 5 fs pattern 1 border notitle, \
     '' using ($1):3                         w boxes ls 2 fs pattern 5 border notitle, \
     '' using ($1+0.17):4                    w boxes ls 3 fs solid 1.0 noborder notitle

# --- Panel 4 (7-Keys) ---
set log y
set format y "10^{%L}"
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "7-Keys" at screen 0.815, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/bar3_07.dat' using ($1-0.17):2 w boxes ls 5 fs pattern 1 border notitle, \
     '' using ($1):3                         w boxes ls 2 fs pattern 5 border notitle, \
     '' using ($1+0.17):4                    w boxes ls 3 fs solid 1.0 noborder notitle

unset multiplot
