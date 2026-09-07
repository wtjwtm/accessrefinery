set terminal pdfcairo font "Times New Roman,13" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9cm

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

set bmargin screen 0.30
set tmargin at screen 0.90
set rmargin screen 0.86

# Output settings
set output 'results/AB-BR-AR.pdf'

set multiplot layout 1,4 margins 0.08, 0.96, 0.31, 0.80 spacing 0.05

# vertical y-axis title on the far left, inside the canvas
set label "Time (ms)" rotate by 90 at screen 0.025, 0.55 center font ",13"

set label "# of allow statements" at screen 0.42, 0.05 center font ",13"
set label "The ID of datasets" at screen 0.87, 0.05 center font ",13"

set log y
set format y "10^{%L}"
set yrange[1e-2: 1e5]
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0

# --- Panel 1 (5-Keys): show key here -> legend over 1&2 ---
set key width -0.9 Left vertical maxrows 1 reverse samplen 1 at screen 0.50, 0.985 font ',13' spacing 1.2
set label "5-Keys" at screen 0.125, 0.76 center font ",10"
plot 'data/p1_05.dat' using 1:2 w lp ls 1 title 'Intent Reducer (orginal)', \
     '' using 1:3       w lp ls 2 notitle

# --- Panel 2 (6-Keys) ---
set log y
set format y "10^{%L}"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key off
unset ylabel
set label "6-Keys" at screen 0.355, 0.76 center font ",10"
plot 'data/p6_br_am.dat' using 1:2 w lp ls 1 notitle, \
     '' using 1:3       w lp ls 2 notitle

# --- Panel 3 (7-Keys): show key here -> legend over 3&4 ---
set log y
set format y "10^{%L}"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set key width -0.9 Left vertical maxrows 1 reverse samplen 1 at screen 0.95, 0.985 font ',13' spacing 1.2
set label "7-Keys" at screen 0.585, 0.76 center font ",10"
plot 'data/p1_07.dat' using 1:2 w lp ls 1 notitle, \
     '' using 1:3       w lp ls 2 title 'Intent Reducer (reducing purning)'

# --- Panel 4 (RW) ---
set log y
set format y "10^{%L}"
set xrange[0: 506]
set xtics 0,150,450
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "RW" at screen 0.815, 0.76 center font ",10"
plot 'data/rw_p1.dat' using 1:2 w l ls 1 notitle, \
     '' using 1:3 w l ls 2 notitle

unset multiplot
