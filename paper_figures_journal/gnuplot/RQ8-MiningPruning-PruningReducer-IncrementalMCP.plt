set terminal pdfcairo font "Times New Roman, 13" linewidth 1 rounded fontscale 1.35 size 35cm, 9cm

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
set style line 2 lt rgb "#2b8cbe" lw 3 pt 6 ps 1.5
set style line 3 lt rgb "#74c476" lw 3 pt 2 ps 1.5
set style line 4 lt rgb "#00A000" lw 3 pt 9 ps 1.5
set style line 5 lt rgb "#d4b9da" lw 3 pt 12 ps 1.5
set style line 6 lt rgb "#4F4F4F" lw 3

# Set axis and font properties
set xtics font "Times New Roman, 13"
set ytics font "Times New Roman, 13"
set boxwidth 0.9

set key width -0.05 Left vertical maxrows 1 reverse samplen 1 at screen 0.9065, 0.995 font ',13' spacing 2
set bmargin screen 0.33
set tmargin at screen 0.9
set rmargin screen 0.87

# Output settings
set output 'results/RQ8-MiningPruning-PruningReducer-IncrementalMCP.pdf'

set label "The ID of datasets" at screen 0.196, 0.096 center font ",13"
set label "# of allow statements" at screen 0.666, 0.096 center font ",13"
set label "Real-world" at screen 0.173, 0.735 center font ",13"
set label "5-Keys" at screen 0.488, 0.735 center font ",13"
set label "6-Keys" at screen 0.824, 0.735 center font ",13"

set multiplot layout 1,3 margins 0.10, 0.96, 0.31, 0.80 spacing 0.13

set log y
set format y "10^{%L}"
set yrange[1e0: 1e6]
set ytics (1e1, 1e3, 1e5)
set ylabel "Time (ms)" offset 0.65,0
set xrange[0: 506]
set xtics 0,150,450
set size 1, 0.9
set offsets 0.5,0.5,0,0
# The two key entries carry their marker: the cumulative curves are drawn
# `with lines`, so an entry taken from a curve is a bare segment; each curve is
# `notitle` and its entry is drawn by a NaN-valued `with linespoints` element of
# the same style line, which puts nothing on the plot.
plot 'data/rw_p2.dat' using 1:2 smooth cumulative w l ls 2 notitle, \
	'' using 1:3 smooth cumulative w l ls 3 notitle, \
	NaN w lp ls 2 t'Intent Miner (Original)', \
	NaN w lp ls 3 t'Intent Miner (Incremental MCP)'

# Figure-level text is drawn once, on panel 1: gnuplot redraws every label and the
# key on each panel's plot, and they sit at absolute screen coordinates, so a second
# pass lands on top of the first and prints as if the text were set in a heavier
# weight. Each panel after the first therefore sets only its own labels.
unset label
unset key

set log y
set format y "10^{%L}"
unset ylabel
unset yrange
set ytics auto
set label "# of allow statements" at screen 0.666, 0.096 center font ",13"
set label "5-Keys" at screen 0.488, 0.735 center font ",13"
set label "6-Keys" at screen 0.824, 0.735 center font ",13"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
plot 'data/p2_05.dat' using ($0+1):2 w lp ls 2 t'Intent Miner (Original)', \
	'' using ($0+1):3 w lp ls 3 t'Intent Miner (Incremental MCP)'

unset label

set log y
set format y "10^{%L}"
set label "6-Keys" at screen 0.824, 0.735 center font ",13"
set xrange[0: 16]
set xtics 3
set size 1, 0.9
set offsets 0.5,0.5,0,0
plot 'data/p2_06.dat' using ($0+1):2 w lp ls 2 t'Intent Miner (Original)', \
	'' using ($0+1):3 w lp ls 3 t'Intent Miner (Incremental MCP)'

# End of output
