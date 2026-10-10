set terminal pdfcairo font "Times New Roman,11.27" linewidth 1 rounded fontscale 1.35 size 26cm, 11cm

set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

set style line 1 lt rgb "#253494" lw 7 pt 8 ps 1.5
set style line 2 lt rgb "#2b8cbe" lw 7 pt 6 ps 1.5 dt 2
set style line 3 lt rgb "#74c476" lw 7 pt 2 ps 1.5 dt 3
set style line 4 lt rgb "#00A000" lw 7 pt 9 ps 1.5
set style line 5 lt rgb "#d4b9da" lw 7 pt 12 ps 1.5
set style line 6 lt rgb "#4F4F4F" lw 7
set style line 7 lt rgb "#bd0026" lw 7 pt 10 ps 1.5 dt 4

set xtics font ", 13"
set xlabel "Dataset ID"
set log y
set format y "10^{%L}"
# Lower bound is 0.05 ms, not 0.5: the AI series of the RRI panel is a component
# (c8+c9, med 0.20 ms), which a 0.5 ms floor would clip away entirely.
set yrange [0.05:*]
set xrange [0:520]
set xtics offset 0
set key width -0.9 Left vertical maxrows 4 maxcols 1 reverse samplen 1 at screen 0.50, 1.0 font ',11.27' spacing 0.95
set bmargin screen 0.3
set tmargin at screen 0.82
set rmargin screen 0.96

set output 'results/RQ4-Experiment-Scalabiliy-RealWorld.pdf'
set size 1, 0.9

set multiplot layout 1,2 margins 0.13, 0.96, 0.31, 0.711 spacing 0.20

# Plot the first subplot: MCI experiment results
set ylabel "Time (ms)"
set ytics (1e1, 1e3, 1e5, 1e7) font ", 13"
set key width -0.9 Left vertical maxrows 4 maxcols 1 reverse samplen 1 at screen 0.50, 1.0 font ',11.27' spacing 0.95
plot 'data/Experiment-Scalability-MCI-RealWorld.dat' \
     using ($0+1):($1*1000) smooth cumulative with lines ls 1 title 'Access Analyzer(Z3)', \
     '' using ($0+1):($2*1000) smooth cumulative with lines ls 2 title 'Access Analyzer(CVC5)', \
     '' using ($0+1):($4*1000) smooth cumulative with lines ls 3 title 'AccessRefinery(Original)', \
     'data/Experiment-Scalability-MCI-RealWorld-WAll.dat' using ($0+1):($1*1000) smooth cumulative with lines ls 7 title 'AccessRefinery(Optimized)'

# Plot the second subplot: RRI experiment results
unset ylabel
set key width -0.9 Left vertical maxrows 4 maxcols 1 reverse samplen 1 at screen 1.0, 1.0 font ',11.27' spacing 0.95
plot 'data/Experiment-Scalability-RRI-RealWorld.dat' \
     using ($0+1):($1*1000) smooth cumulative with lines ls 1 title 'Baseline(Z3)', \
     '' using ($0+1):($2*1000) smooth cumulative with lines ls 2 title 'Baseline(CVC5)', \
     '' using ($0+1):($4*1000) smooth cumulative with lines ls 3 title 'AccessRefinery(Original)', \
     'data/Experiment-Scalability-RRI-RealWorld-WAll.dat' using ($0+1):($1*1000) smooth cumulative with lines ls 7 title 'AccessRefinery(Optimized)'