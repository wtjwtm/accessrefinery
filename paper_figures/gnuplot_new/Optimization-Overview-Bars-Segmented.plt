set terminal pdfcairo font "Times New Roman,13" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9cm

set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# One color per pipeline stage, the same three as Optimization-Overview-Bars.
# Within a bar the two time segments are told apart by the fill: the intent
# miner is solid, the intent reducer is the hatched one on top.
set style line 1 lt rgb "#253494" lw 7
set style line 2 lt rgb "#2b8cbe" lw 2
set style line 3 lt rgb "#00A000" lw 2

set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.26

set bmargin screen 0.30
set tmargin at screen 0.90
set rmargin screen 0.86

set output 'results_new/Optimization-Overview-Bars-Segmented.pdf'

set multiplot layout 1,4 margins 0.08, 0.96, 0.31, 0.80 spacing 0.05

set label "Time (ms)" rotate by 90 at screen 0.025, 0.55 center font ",13"
set label "# of allow statements" at screen 0.42, 0.05 center font ",13"
set label "The ID of datasets" at screen 0.87, 0.05 center font ",13"

# ------------------------------------------------------------------
# Panels 1-3: one bar per pipeline stage, the three of a point touching:
# Original (BR), Pruning Reducer (AR), Incremental MCP (AI). Each bar runs
# from the bottom of the axis up to that stage's TotalTimeAverage (c5), and
# is split at its intent-mining cost (c6+c7): solid below, hatched above.
# The split is drawn by painting the full-height bar first and the miner
# over its lower part, which under a log axis is what makes the two share
# one bar instead of starting from zero.
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder
set log y
set format y "10^{%L}"
unset xtics
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.60: 4.60]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
# Manual legend: one swatch per stage, solid under hatched, then what the two
# fills mean
set object 1 rect from screen 0.080, 0.958 to screen 0.108, 0.972 fc rgb "#253494" fs solid noborder
set object 2 rect from screen 0.080, 0.972 to screen 0.108, 0.986 fc rgb "#253494" fillstyle pattern 4 border lc rgb "#253494" lw 1
set object 3 rect from screen 0.250, 0.958 to screen 0.278, 0.972 fc rgb "#2b8cbe" fs solid noborder
set object 4 rect from screen 0.250, 0.972 to screen 0.278, 0.986 fc rgb "#2b8cbe" fillstyle pattern 4 border lc rgb "#2b8cbe" lw 1
set object 5 rect from screen 0.520, 0.958 to screen 0.548, 0.972 fc rgb "#00A000" fs solid noborder
set object 6 rect from screen 0.520, 0.972 to screen 0.548, 0.986 fc rgb "#00A000" fillstyle pattern 4 border lc rgb "#00A000" lw 1
set label 20 "Original"          at screen 0.116, 0.972 left font ",13"
set label 21 "Pruning Reducer"   at screen 0.286, 0.972 left font ",13"
set label 22 "Incremental MCP"   at screen 0.556, 0.972 left font ",13"
set label 23 "Solid = intent miner (c6+c7);  hatched = intent reducer (c8+c9)" \
    at screen 0.080, 0.868 left font ",12"

# --- Panel 1 (5-Keys) ---
set label "5-Keys" at screen 0.155, 0.78 center font ",13"
plot 'archive_data_new/rerun10b/seg_05.dat' using ($1-0.26):3 w boxes ls 1 fs pattern 4 border notitle, \
     '' using ($1-0.26):2 w boxes ls 1 fs solid 1.0 noborder notitle, \
     '' using ($1):5      w boxes ls 2 fs pattern 4 border notitle, \
     '' using ($1):4      w boxes ls 2 fs solid 1.0 noborder notitle, \
     '' using ($1+0.26):7 w boxes ls 3 fs pattern 4 border notitle, \
     '' using ($1+0.26):6 w boxes ls 3 fs solid 1.0 noborder notitle

# --- Panel 2 (6-Keys) ---
set log y
set format y "10^{%L}"
set xrange[-0.60: 4.60]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Keys" at screen 0.385, 0.78 center font ",13"
plot 'archive_data_new/rerun10b/seg_06.dat' using ($1-0.26):3 w boxes ls 1 fs pattern 4 border notitle, \
     '' using ($1-0.26):2 w boxes ls 1 fs solid 1.0 noborder notitle, \
     '' using ($1):5      w boxes ls 2 fs pattern 4 border notitle, \
     '' using ($1):4      w boxes ls 2 fs solid 1.0 noborder notitle, \
     '' using ($1+0.26):7 w boxes ls 3 fs pattern 4 border notitle, \
     '' using ($1+0.26):6 w boxes ls 3 fs solid 1.0 noborder notitle

# --- Panel 3 (7-Keys) ---
set log y
set format y "10^{%L}"
set xrange[-0.60: 4.60]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "7-Keys" at screen 0.61, 0.78 center font ",13"
plot 'archive_data_new/rerun10b/seg_07.dat' using ($1-0.26):3 w boxes ls 1 fs pattern 4 border notitle, \
     '' using ($1-0.26):2 w boxes ls 1 fs solid 1.0 noborder notitle, \
     '' using ($1):5      w boxes ls 2 fs pattern 4 border notitle, \
     '' using ($1):4      w boxes ls 2 fs solid 1.0 noborder notitle, \
     '' using ($1+0.26):7 w boxes ls 3 fs pattern 4 border notitle, \
     '' using ($1+0.26):6 w boxes ls 3 fs solid 1.0 noborder notitle


# ------------------------------------------------------------------
# Panel 4 (RW): left empty for now - the 10-round re-run covers the
# synthetic scalability datasets only.
# ------------------------------------------------------------------
set log y
set format y "10^{%L}"
set xrange[0: 506]
set xtics 0,150,450
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "RW" at screen 0.86, 0.78 center font ",13"
plot 1e-9 w l ls 1 lw 2 notitle

unset multiplot
