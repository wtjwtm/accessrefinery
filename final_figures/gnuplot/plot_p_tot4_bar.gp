set terminal pdfcairo font "Times New Roman,13" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9cm

set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# four stage colors (BR/AR/AM/AI)
set style line 1 lt rgb "#253494" lw 7
set style line 2 lt rgb "#2b8cbe" lw 2
set style line 3 lt rgb "#74c476" lw 2
set style line 4 lt rgb "#00A000" lw 2

set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.16

set bmargin screen 0.30
set tmargin at screen 0.90
set rmargin screen 0.86

set output 'results/AB-BR-AR-AM-AI-Total-Bars.pdf'

set multiplot layout 1,4 margins 0.08, 0.96, 0.31, 0.80 spacing 0.05

set label "Time (ms)" rotate by 90 at screen 0.025, 0.55 center font ",13"
set label "# of allow statements" at screen 0.42, 0.05 center font ",13"
set label "The ID of datasets" at screen 0.87, 0.05 center font ",13"

# ------------------------------------------------------------------
# Panels 1-3: manual boxes, explicit x offsets, policy 5/10/15 at 0/1/2
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder
set log y
set format y "10^{%L}"
unset xtics
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.30: 4.30]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
# Manual legend: one row, color swatch + short name (size matches AB-AR-AM legend)
set object 1 rect from screen 0.078, 0.956 to screen 0.106, 0.982 fc rgb "#253494" fs solid noborder
set object 2 rect from screen 0.218, 0.956 to screen 0.246, 0.982 fc rgb "#2b8cbe" fillstyle pattern 5 border lc rgb "#2b8cbe" lw 1
set object 3 rect from screen 0.450, 0.956 to screen 0.478, 0.982 fc rgb "#74c476" fillstyle pattern 4 border lc rgb "#74c476" lw 1
set object 4 rect from screen 0.710, 0.956 to screen 0.738, 0.982 fc rgb "#00A000" fillstyle pattern 1 border lc rgb "#00A000" lw 1
set label 20 "Original"          at screen 0.114, 0.970 left font ",13"
set label 21 "Purning Reducer"   at screen 0.254, 0.970 left font ",13"
set label 22 "Incremental Miner" at screen 0.486, 0.970 left font ",13"
set label 23 "Incremental MCP"   at screen 0.746, 0.970 left font ",13"

# --- Panel 1 (5-Keys) ---
set label "5-Keys" at screen 0.155, 0.78 center font ",10"
plot 'data/p_bar_ix_05.dat' using ($1-0.235):2 w boxes ls 1 fs solid 1.0 noborder title 'BR', \
     '' using ($1-0.075):3                    w boxes ls 2 fs pattern 5 border title 'AR', \
     '' using ($1+0.085):4                    w boxes ls 3 fs pattern 4 border title 'AM', \
     '' using ($1+0.245):5                    w boxes ls 4 fs pattern 1 border title 'AI'

# --- Panel 2 (6-Keys) ---
set log y
set format y "10^{%L}"
set xrange[-0.30: 4.30]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Keys" at screen 0.385, 0.78 center font ",10"
plot 'data/p_bar_ix_06.dat' using ($1-0.235):2 w boxes ls 1 fs solid 1.0 noborder notitle, \
     '' using ($1-0.075):3                    w boxes ls 2 fs pattern 5 border notitle, \
     '' using ($1+0.085):4                    w boxes ls 3 fs pattern 4 border notitle, \
     '' using ($1+0.245):5                    w boxes ls 4 fs pattern 1 border notitle

# --- Panel 3 (7-Keys) ---
set log y
set format y "10^{%L}"
set xrange[-0.30: 4.30]
set yrange[1: 100000]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "7-Keys" at screen 0.61, 0.78 center font ",10"
plot 'data/p_bar_ix_07.dat' using ($1-0.235):2 w boxes ls 1 fs solid 1.0 noborder notitle, \
     '' using ($1-0.075):3                    w boxes ls 2 fs pattern 5 border notitle, \
     '' using ($1+0.085):4                    w boxes ls 3 fs pattern 4 border notitle, \
     '' using ($1+0.245):5                    w boxes ls 4 fs pattern 1 border notitle


# ------------------------------------------------------------------
# Panel 4 (RW): BR vs AI total time, line chart (BR-AR RW subplot format)
# ------------------------------------------------------------------
set log y
set format y "10^{%L}"
set xrange[0: 506]
set xtics 0,150,450
set yrange[1e-2: 1e5]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "RW" at screen 0.85, 0.78 center font ",10"
plot 'data/rw_br_ai.dat' using 1:2 w l ls 1 lw 2 notitle, \
     '' using 1:3 w l ls 4 lw 2 notitle

unset multiplot
