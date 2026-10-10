# RQ9 - Share of each stage's window that goes to its encoding step, as a
# percentage of that stage's own pair.
#
# The five-policy version: same figure as
# RQ9-Optimization-Overview-Bars-Percentage.plt in everything but the policies it
# draws and the layout it is drawn on. That one draws all fifteen of the dataset,
# this one only the five (3/6/9/12/15) the three-panel version of this figure drew,
# taken out of the same data files with `every 3::3` (the third record of every
# three, the first data line after the header being policy 1). The bars then go on
# slots 0..4 rather than on the policies' own 2, 5, 8, 11 and 14. The axis runs
# -0.5 to 4.5 for the five of them.
#
# The layout is the RQ3 figure's: the 31 by 11 cm canvas, margins 0.13, 0.96, 0.31,
# 0.711 and spacing 0.20, so a panel is 9.765 cm by 4.41 cm; Times at 13 pt with
# 1.35 fontscale, and the tick numbers one step smaller at 11 pt as there; the two
# panel labels just inside their panels' top-left corner, one "# of allow
# statements" under each panel, and the rotated axis title at the vertical centre
# of the band. The bars, the percentage axis, the y title ("Percentage (%)" in place
# of RQ3's "Time (ms)") and the legend are this figure's own.
#
# A policy's slot on that band is 1.953 cm. The two bars of its pair are centred a
# quarter of a bar's width either side of its tick, so at 0.175 unit each and each
# 0.35 unit wide, 0.684 cm: the pair spans 0.70 unit, its two bars touch at the
# tick, and 0.30 unit - 0.586 cm - of blank is left between one policy's pair and
# the next's.

set terminal pdfcairo font "Times New Roman, 13" linewidth 1 rounded fontscale 1.35 size 31cm, 11cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt 0 lc rgb "#808080"

# Remove top and right borders for clarity
set grid back linestyle 81
set border 3 back linestyle 80
set xtics nomirror
set ytics nomirror

# The two bar styles of the outermost bars of the 3-Stage overview, taken over as
# they are there: the miner's bar and the reducer's bar are the two shares of
# their own window, which the labels name, so the colour carries no stage. Both
# bars carry a border, each in its own colour: the miner's hatch in the dark blue
# of its pattern, the reducer's solid fill in the green of the fill itself.
set style line 2 lt rgb "#00A000" lw 2
set style line 3 lt rgb "#253494" lw 2

# Five policies on a 9.765 cm panel give a tick every 1.95 cm, so the numbers have
# room at the 11 pt the rest of the figure uses; both axes are set at it.
set xtics font ", 11"
set ytics font ", 11"
# The axis stops at 120 so the tallest bars - the miner shares sit at 95-100 for
# most policies - have headroom instead of touching the top of the panel. 120 is
# not a label: the last labelled step stays 100, so the extra 20% is blank grid.
set ytics (0, 20, 40, 60, 80, 100)
set boxwidth 0.35

set bmargin screen 0.33
set tmargin at screen 0.9
set rmargin screen 0.87

# Output settings
set output 'results/RQ9-Optimization-Overview-Bars-Percentage-5policies.pdf'

set label "Percentage (%)" rotate by 90 at screen 0.0526, 0.5105 center font ", 13"

# Manual legend for the two shares, one row above the panels, each block a
# rectangle of its bar's style followed by the bar's name.
set object 1 rect from screen 0.297, 0.830 to screen 0.321, 0.855 fc rgb "#253494" fillstyle pattern 1 border lc rgb "#253494" lw 1
set object 2 rect from screen 0.550, 0.830 to screen 0.574, 0.855 fc rgb "#00A000" fs solid noborder
set label 20 "Intent Miner"   at screen 0.327, 0.8425 left font ", 13"
set label 21 "Intent Reducer" at screen 0.580, 0.8425 left font ", 13"

set multiplot layout 1,2 margins 0.13, 0.96, 0.31, 0.711 spacing 0.20

# ------------------------------------------------------------------
# Panels: two adjacent bars per policy, the left one the share of the intent
# miner's window that goes to the parse, the ECs and the label tree - everything
# the mining BFS runs on but does not itself do - and the right one the share of
# the intent reducer's window that goes to the encoding of the findings into EC
# indices, everything the ILP solve is handed rather than does. Every bar is a
# share of its own pair, so 100% is the ceiling of what a bar can mean; the axis
# is drawn 20% past it for headroom.
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder

# --- Panel 1 (5-Key) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0 offset screen 0, 0
set xrange[-0.5: 4.5]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Key" at screen 0.1758, 0.6665 center font ", 13"
set label "# of allow statements" at screen 0.2875, 0.158 center font ", 13"
plot 'data/enc_05.dat' every 3::3 using ($0-0.175):2 w boxes ls 3 fs pattern 1 border title 'Intent Miner', \
     '' every 3::3 using ($0+0.175):3                w boxes ls 2 fs solid 1.0 border title 'Intent Reducer'

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label, every object and every key on each panel's plot, and each of them here
# sits at absolute screen coordinates, so a second pass lands on top of the first
# and prints as if the text were set in a heavier weight. The first panel draws
# them above; the panel after it must not. The panel's own labels are set just
# before that panel's plot and unset again after it.
unset label
unset object
unset key

# --- Panel 2 (6-Key) ---
set xtics ( "3" 0, "6" 1, "9" 2, "12" 3, "15" 4 ) scale 0 offset screen 0, 0
set xrange[-0.5: 4.5]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Key" at screen 0.7042, 0.6665 center font ", 13"
set label "# of allow statements" at screen 0.8025, 0.158 center font ", 13"
plot 'data/enc_06.dat' every 3::3 using ($0-0.175):2 w boxes ls 3 fs pattern 1 border notitle, \
     '' every 3::3 using ($0+0.175):3                w boxes ls 2 fs solid 1.0 border notitle

unset multiplot
