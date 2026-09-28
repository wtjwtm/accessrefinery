set terminal pdfcairo font "Times New Roman,12.67" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9cm

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
set style line 1 lt rgb "#2b8cbe" lw 3 pt 6 ps 1.0   # Before Reducing: blue circle
set style line 2 lt rgb "#74c476" lw 3 pt 2 ps 1.0   # After Reducing: green cross

# Set axis and font properties
set xtics font ", 11"
set ytics font ", 11"
set boxwidth 0.9

set key width -0.05 Left vertical maxrows 1 reverse samplen 1 at screen 0.815, 1.02 font ',12.67' spacing 2
set bmargin screen 0.30
set tmargin at screen 0.90
set rmargin screen 0.86

# Output settings
set output 'results/RQ2-Experiment-Effectiveness.pdf'

set multiplot layout 1,4 margins 0.08, 0.96, 0.31, 0.80 spacing 0.05

# vertical y-axis title on the far left, inside the canvas
set label "# of Intents" rotate by 90 at screen 0.025, 0.55 center font ",12.67"

set label "The ID of datasets" at screen 0.171, 0.05 center font ",12.67"
set label "# of allow statements" at screen 0.636, 0.05 center font ",12.67"

# --- Panel 1 (Real-world): lines only, no point markers ---
set yrange[0: 90]
set ytics 20
set xrange[0: 520]
set xtics 150
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "Real-world" at screen 0.135, 0.76 center font ",12.67"
plot 'archive_data/Experiment-Effectiveness-RealWorld.dat' using 2 w l ls 1 t'Before Reducing', \
	'' using 3 w l ls 2 t'After Reducing'

# --- Panel 2 (5-Keys) ---
set log y
set format y "10^{%L}"
unset yrange
set xrange[0: 15]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "5-Keys" at screen 0.355, 0.76 center font ",12.67"
plot 'archive_data/Experiment-Effectiveness-Synthetic-K2.dat' using ($0+1):2 w lp ls 1 t'Before Reducing', \
	'' using ($0+1):1 w lp ls 2 t'After Reducing'

# --- Panel 3 (6-Keys) ---
set log y
set format y "10^{%L}"
set xrange[0: 15]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "6-Keys" at screen 0.585, 0.76 center font ",12.67"
plot 'archive_data/Experiment-Effectiveness-Synthetic-K3.dat' using ($0+1):2 w lp ls 1 t'Before Reducing', \
	'' using ($0+1):1 w lp ls 2 t'After Reducing'

# --- Panel 4 (7-Keys) ---
set log y
set format y "10^{%L}"
set xrange[0: 15]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
set label "7-Keys" at screen 0.815, 0.76 center font ",12.67"
plot 'archive_data/Experiment-Effectiveness-Synthetic-K4.dat' using ($0+1):2 w lp ls 1 t'Before Reducing', \
	'' using ($0+1):1 w lp ls 2 t'After Reducing'

unset multiplot
