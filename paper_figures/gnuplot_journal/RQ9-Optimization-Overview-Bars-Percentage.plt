set terminal pdfcairo font "Times New Roman,11.77" linewidth 1 rounded fontscale 1.35 size 33.8cm, 9.5cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

# Remove top and right borders for clarity
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# The two bar styles of the outermost bars of RQ7-Optimization-Overview-Bars-3Stage,
# taken over as they are: that figure's first bar - its dark blue #253494, pattern
# 1, border - on the miner's bar here, and that figure's last bar - its green
# #00A000, solid - on the reducer's bar. So a pair here is the 3-Stage figure's
# first and last bar with the middle one taken out, not a pair of one pipeline's
# stages: the two bars are the miner's share and the reducer's share of their own
# window, which the labels name, so the colour carries no stage. That figure's
# medium blue, its real-world reference line and the fill styles it uses for its
# middle bar have no series in this figure and are not defined.
set style line 2 lt rgb "#00A000" lw 2
set style line 3 lt rgb "#253494" lw 2

set xtics font ", 11"
set ytics font ", 11"
# The axis stops at 120 so the tallest bars - the miner shares sit at 95-100 for
# most policies - have headroom instead of touching the top of the panel. 120 is
# not a label: the last labelled step stays 100, so the extra 20% is blank grid.
set ytics (0, 20, 40, 60, 80, 100)
set boxwidth 0.22

set bmargin screen 0.241263
set tmargin at screen 0.705895
set rmargin screen 0.86

# Output settings
set output 'results_journal/RQ9-Optimization-Overview-Bars-Percentage.pdf'

# The RQ3 canvas and the RQ3 layout: 33.8cm x 9.5cm with margins 0.11355, 0.88645,
# 0.241263, 0.705895 and spacing 0.05355, which is what makes a panel 7.501 x
# 4.416 cm here exactly as it is there, with 1.81 cm of white between neighbours.
# Every label below is at its RQ3 screen position for that reason, the x title
# with them and so also keeping the 0.45 cm it leaves below itself to the canvas'
# bottom edge; only the manual legend, which RQ3 has no counterpart of, is placed
# as it was, shifted left by the 0.02 the block's centre moved and its y the 9 cm
# value scaled by 0.9, so that the taller canvas of that figure does not move it -
# it sits 1.77 cm below the canvas' top edge, which the half centimetre since
# taken off the bottom edge leaves alone. The axis
# box therefore starts on the same line down the
# left and ends on the same line up as RQ3's, and a panel of this figure can be
# read against a panel of that one column by column.
set multiplot layout 1,3 margins 0.11355, 0.88645, 0.241263, 0.705895 spacing 0.05355

# vertical y-axis title on the far left, inside the canvas. It says percentage
# where the 3-Stage figure says time: the two bars of a group are both shares of
# their own pair, not durations.
set label "Percentage (%)" rotate by 90 at screen 0.0586, 0.468421 center font ",11.77"

# centred on the three panels
set label "# of allow statements" at screen 0.5, 0.047368 center font ",11.77"

# Manual legend for the two shares, one row, the only legend of the figure: the
# blocks are the same shape and spacing as the 3-Stage figure's. Each label names
# its bar on its own - both bars are shares of their own pair, which the y-axis
# title already says, so "Ratio of labels to" was only repeating it. With the
# short labels the row is much narrower than the two-block one it replaced, so it
# is placed as a whole: its two ends are centred on 0.5, the same centre the
# panels have and "# of allow statements" below them uses, rather than each block
# keeping the position it had under the longer text.
set object 1 rect from screen 0.244, 0.801053 to screen 0.272, 0.825263 fc rgb "#253494" fillstyle pattern 1 border lc rgb "#253494" lw 1
set object 2 rect from screen 0.588, 0.801053 to screen 0.616, 0.825263 fc rgb "#00A000" fs solid noborder
set label 20 "Intent Miner"   at screen 0.281, 0.813684 left font ",11.77"
set label 21 "Intent Reducer" at screen 0.625, 0.813684 left font ",11.77"

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

# --- Panel 1 (5-Key) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Key" at screen 0.1476, 0.667368 center font ",11.77"
plot 'archive_data_journal/10rs/enc_05.dat' using ($1-0.115):2 w boxes ls 3 fs pattern 1 border title 'Intent Miner', \
     '' using ($1+0.115):3                   w boxes ls 2 fs solid 1.0 noborder title 'Intent Reducer'

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label and every object on each panel's plot, and each of them here sits at absolute
# screen coordinates, so a second pass lands on top of the first and prints as
# if the text were set in a heavier weight. The first panel draws them above;
# the panels after it must not.
unset label
unset object

# --- Panel 2 (6-Key) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Key" at screen 0.423, 0.667368 center font ",11.77"
plot 'archive_data_journal/10rs/enc_06.dat' using ($1-0.115):2 w boxes ls 3 fs pattern 1 border notitle, \
     '' using ($1+0.115):3                   w boxes ls 2 fs solid 1.0 noborder notitle

unset label
unset object

# --- Panel 3 (5-Key*) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0
set xrange[-0.40: 4.40]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Key*" at screen 0.6985, 0.667368 center font ",11.77"
plot 'archive_data_journal/10rs/enc_07.dat' using ($1-0.115):2 w boxes ls 3 fs pattern 1 border notitle, \
     '' using ($1+0.115):3                   w boxes ls 2 fs solid 1.0 noborder notitle

unset multiplot
