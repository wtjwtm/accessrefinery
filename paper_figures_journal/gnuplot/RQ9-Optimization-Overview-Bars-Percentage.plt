# RQ9 - Share of each stage's window that goes to its encoding step, as a
# percentage of that stage's own pair.
#
# Two panels: 5-Key, 6-Key. The 5-Key* panel of the three-panel version of this
# figure is not drawn in this set.
#
# Each panel draws all fifteen policies of its dataset, against the five
# (3/6/9/12/15) the three-panel version drew, and takes the two-panel RQ3 band:
# margins 0.13, 0.96, 0.31, 0.7544 and spacing 0.09 of the 26 by 9 cm canvas, so a
# panel is 9.62 cm by 4.00 cm. The band is 0.41 cm shorter than RQ3's: the panels
# were asked for shorter, and the canvas, the legend and the x label are where
# they were, so the whole 0.41 cm comes off the top of the panels and shows up as
# a wider gap between them and the legend. The two labels that sit on the band
# itself - the rotated y title at its vertical centre, the two panel labels just
# inside its top edge - moved down with it.
#
# A policy's slot on that band is 1.00 unit - the axis runs -0.5 to 14.5 for the
# fifteen of them. The two bars of its pair are centred a quarter of a bar's width
# either side of its tick, so at 0.175 unit each and each 0.35 unit wide, 0.224 cm:
# the pair spans 0.70 unit, its two bars touch at the tick, and 0.30 unit - 0.192
# cm - of blank is left between one policy's pair and the next's.
#
# The range is -0.5 to 14.5 rather than the -0.30 to 14.30 it was, because a bar
# reaches half its own width past its tick: 14.30 cut the first policy's miner bar
# off at the panel's left edge, narrowing it by a quarter, while the rest of the
# bars fell inside the range and kept their width.
#
# The two panel labels keep their place within their panel - 0.08 of the canvas in
# from its left edge - which on this band is 0.21 and 0.67.
#
# Panels, margins and labels are therefore the RQ3 figure's; the two bar styles,
# the axis and the legend are this figure's own.

set terminal pdfcairo font "Times New Roman, 9.06" linewidth 1 rounded fontscale 1.35 size 26cm, 9cm

# Set background and axes styles
set style line 80 lt rgb "#808080"
set style line 81 lt 0
set style line 81 lt rgb "#808080"

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

# Fifteen policies on a 9.62 cm panel give a tick every 0.64 cm. The two-digit
# labels 10..15 are about 0.55 cm wide at the 11 pt the rest of the figure uses,
# which leaves them touching, so the axis numbers are set one step smaller - both
# axes, so that the y numbers are the same size as the x numbers.
set xtics font ", 9"
set ytics font ", 9"
# The axis stops at 120 so the tallest bars - the miner shares sit at 95-100 for
# most policies - have headroom instead of touching the top of the panel. 120 is
# not a label: the last labelled step stays 100, so the extra 20% is blank grid.
set ytics (0, 20, 40, 60, 80, 100)
set boxwidth 0.35

set bmargin screen 0.33
set tmargin at screen 0.9
set rmargin screen 0.87

# Output settings
set output 'results/RQ9-Optimization-Overview-Bars-Percentage.pdf'

set label "Percentage (%)" rotate by 90 at screen 0.0586, 0.5322 center font ", 9.06"
set label "# of allow statements" at screen 0.54, 0.16 center font ", 9.06"

# Manual legend for the two shares, one row above the panels, each block a
# rectangle of its bar's style followed by the bar's name.
set object 1 rect from screen 0.297, 0.830 to screen 0.321, 0.855 fc rgb "#253494" fillstyle pattern 1 border lc rgb "#253494" lw 1
set object 2 rect from screen 0.550, 0.830 to screen 0.574, 0.855 fc rgb "#00A000" fs solid noborder
set label 20 "Intent Miner"   at screen 0.327, 0.8425 left font ", 9.06"
set label 21 "Intent Reducer" at screen 0.580, 0.8425 left font ", 9.06"

set multiplot layout 1,2 margins 0.13, 0.96, 0.31, 0.7544 spacing 0.09

# ------------------------------------------------------------------
# Panels: two adjacent bars per policy, the left one the share of the intent
# miner's window that goes to the parse, the ECs and the label tree - everything
# the mining BFS runs on but does not itself do - and the right one the share of
# the intent reducer's window that goes to the encoding of the findings into EC
# indices, everything the ILP solve is handed rather than does. The bar indices
# 0..14 are policies 1..15. Every bar is a share of its own pair, so 100% is the
# ceiling of what a bar can mean; the axis is drawn 20% past it for headroom.
# ------------------------------------------------------------------
set style data boxes
set style fill solid 1.0 noborder

# --- Panel 1 (5-Key) ---
set xtics ( "1" 0, "2" 1, "3" 2, "4" 3, "5" 4, "6" 5, "7" 6, "8" 7, "9" 8, "10" 9, "11" 10, "12" 11, "13" 12, "14" 13, "15" 14 ) scale 0 offset screen 0, 0
set xrange[-0.5: 14.5]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "5-Key" at screen 0.21, 0.7144 center font ", 9.06"
plot 'data/enc_05.dat' using ($1-0.175):2 w boxes ls 3 fs pattern 1 border title 'Intent Miner', \
     '' using ($1+0.175):3                   w boxes ls 2 fs solid 1.0 border title 'Intent Reducer'

# Figure-level text is written once, not once per panel: gnuplot redraws every
# label, every object and every key on each panel's plot, and each of them here
# sits at absolute screen coordinates, so a second pass lands on top of the first
# and prints as if the text were set in a heavier weight. The first panel draws
# them above; the panel after it must not. The panel's own label is set just
# before that panel's plot and unset again after it.
unset label
unset object
unset key

# --- Panel 2 (6-Key) ---
set xtics ( "1" 0, "2" 1, "3" 2, "4" 3, "5" 4, "6" 5, "7" 6, "8" 7, "9" 8, "10" 9, "11" 10, "12" 11, "13" 12, "14" 13, "15" 14 ) scale 0 offset screen 0, 0
set xrange[-0.5: 14.5]
set yrange[0: 120]
set size 1, 0.9
set offsets 0,0,0,0
set key off
set label "6-Key" at screen 0.67, 0.7144 center font ", 9.06"
plot 'data/enc_06.dat' using ($1-0.175):2 w boxes ls 3 fs pattern 1 border notitle, \
     '' using ($1+0.175):3                   w boxes ls 2 fs solid 1.0 border notitle

unset multiplot
