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

# The same stage colours as Optimization-Overview-Bars-3Stage. This figure has a
# use for two of them: the green solid fill that figure's Incremental MCP bars
# use, for the first bar of a group, and the hatched blue its Pruning Reducer
# bars use, for the second. Its Original colour and its real-world reference line
# have no series in this figure and are not defined.
set style line 2 lt rgb "#2b8cbe" lw 2
set style line 3 lt rgb "#00A000" lw 2

set xtics font ", 11"
set ytics font ", 11"
# The axis stops at 120 so the tallest bars - the miner shares sit at 95-100 for
# most policies - have headroom instead of touching the top of the panel. 120 is
# not a label: the last labelled step stays 100, so the extra 20% is blank grid.
set ytics (0, 20, 40, 60, 80, 100)
set boxwidth 0.22

set bmargin screen 0.30
set tmargin at screen 0.90
set rmargin screen 0.86

# Output settings
set output 'results_new/Optimization-Overview-Bars-Percentage.pdf'

# Same canvas as the 3-Stage figure, but three panels instead of four, and the
# panels are the wider for it: 6.75 cm against that figure's 6.17 cm, with 47 mm
# of white between them instead of 17 mm. The height is the shared 4.41 cm, so
# the two figures still print at one width and their axes still start on the
# same line down the left; only the three columns here do not line up with the
# four there. The spacing is what buys the width, the outer margins being the
# ones every figure of this family uses.
set multiplot layout 1,3 margins 0.08, 0.96, 0.31, 0.80 spacing 0.14

# vertical y-axis title on the far left, inside the canvas. It says percentage
# where the 3-Stage figure says time: the two bars of a group are both shares of
# their own pair, not durations.
set label "Percentage (%)" rotate by 90 at screen 0.025, 0.55 center font ",11.77"

# centred on the three panels
set label "# of allow statements" at screen 0.52, 0.05 center font ",11.77"

# Manual legend for the two shares, one row, the only legend of the figure: the
# blocks are the same shape and spacing as the 3-Stage figure's. Each label names
# its bar on its own - both bars are shares of their own pair, which the y-axis
# title already says, so "Ratio of labels to" was only repeating it. With the
# short labels the row is much narrower than the two-block one it replaced, so it
# is placed as a whole: its two ends are centred on 0.52, the same centre the
# panels have and "# of allow statements" below them uses, rather than each block
# keeping the position it had under the longer text.
set object 1 rect from screen 0.264, 0.934 to screen 0.292, 0.960 fc rgb "#00A000" fs solid noborder
set object 2 rect from screen 0.608, 0.934 to screen 0.636, 0.960 fc rgb "#2b8cbe" fillstyle pattern 5 border lc rgb "#2b8cbe" lw 1
set label 20 "Intent Miner"   at screen 0.301, 0.948 left font ",11.77"
set label 21 "Intent Reducer" at screen 0.645, 0.948 left font ",11.77"

# ------------------------------------------------------------------
# Panels: two adjacent bars per policy, the left one the share of the intent
# miner's window that goes to c6 - the parse, the ECs and the label tree, i.e.
# everything the mining BFS runs on but does not itself do - and the right one
# the share of the intent reducer's window that goes to c8, the encoding of the
# findings into EC indices, i.e. everything the ILP solve is handed rather than
# does. The pair is centred on its tick, its two bars touching at 0.23 apart -
# a wider bar than the 3-Stage figure draws, this one having a wider panel and
# only two bars in it. Policies 3/6/9/12/15 sit at 0/1/2/3/4. Every bar is a
# share of its own pair, so 100% is the ceiling of what a bar can mean - the
# axis is drawn 20% past it for headroom, see set ytics above.
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder

# --- Panel 1 (5-Keys) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Keys" at screen 0.134, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/enc_05.dat' using ($1-0.115):2 w boxes ls 3 fs solid 1.0 noborder title 'Intent Miner', \
     '' using ($1+0.115):3                   w boxes ls 2 fs pattern 5 border title 'Intent Reducer'

# --- Panel 2 (6-Keys) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Keys" at screen 0.474, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/enc_06.dat' using ($1-0.115):2 w boxes ls 3 fs solid 1.0 noborder notitle, \
     '' using ($1+0.115):3                   w boxes ls 2 fs pattern 5 border notitle

# --- Panel 3 (7-Keys) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "7-Keys" at screen 0.814, 0.76 center font ",11.77"
plot 'archive_data_new/rerun10b/enc_07.dat' using ($1-0.115):2 w boxes ls 3 fs solid 1.0 noborder notitle, \
     '' using ($1+0.115):3                   w boxes ls 2 fs pattern 5 border notitle

unset multiplot
