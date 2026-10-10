# paper_figures_new

Panel-reduced redraws of the RQ2, RQ3, RQ5, RQ8 and RQ9 figures. Every figure
here keeps the Real-world panel where the figure has one, and the 5-Key and
6-Key panels; the 5-Key\* panel, drawn by the versions in `paper_figures/`, is
not drawn in this set.

Eight PDFs are produced, from eight gnuplot scripts:

| Script (`gnuplot/`) | Panels | Series |
|---|---|---|
| `RQ2-Experiment-Effectiveness.plt` | Real-world, 5-Key, 6-Key | Intents before / after reducing |
| `RQ3-Experiment-Scalability-Mining.plt` | 5-Key, 6-Key | Z3, CVC5, AccessRefinery (W/O All), AccessRefinery (W/ All) |
| `RQ3-Experiment-Scalability-Reducing.plt` | 5-Key, 6-Key | Z3, CVC5, AccessRefinery (W/O All), AccessRefinery (W/ All) |
| `RQ5-Experiment-MicroBenchmark-Mining.plt` | 5-Key, 6-Key | AccessRefinery with MiniSAT / with JavaBDD |
| `RQ5-Experiment-MicroBenchmark-Reducing.plt` | 5-Key, 6-Key | AccessRefinery with MiniSAT / with JavaBDD |
| `RQ8-MiningPruning-PruningReducer-IncrementalMCP.plt` | Real-world, 5-Key, 6-Key | Intent miner, original / Incremental MCP |
| `RQ8-ReducingPruning-Original-PruningReducer.plt` | Real-world, 5-Key, 6-Key | Intent reducer, original / Pruning Reducer |
| `RQ9-Optimization-Overview-Bars-Percentage.plt` | 5-Key, 6-Key | Per-stage encoding share, policies 1-15 |

## Running

```
sh draw.sh
```

The scripts write into `results/` and read their inputs from `data/`, both
relative to this directory, so `draw.sh` enters it first. gnuplot 6 is enough;
no other tool is needed to produce the PDFs.

## Layout

The canvas is 26 cm x 9 cm throughout, and the panel geometry comes from the
three-panel RQ2 figure for the RQ2 and RQ8 figures and from the two-panel RQ3
figure for the RQ3, RQ5 and RQ9 figures, so a panel lands where it lands in
those figures. The curves, axis ranges, line styles and legend entries are the
ones the full versions of these figures draw.

Two notes on the scripts:

- A `set multiplot` with a layout redraws every figure-level label, key and
  object on each panel's `plot`, and each of them here sits at an absolute
  `screen` position, so the second and later panels print a second copy on top
  of the first and the text reads as if it were set in a heavier weight. Each
  script therefore draws them on the first panel that needs them and unsets
  them immediately after.
- gnuplot silently drops key entries that do not fit on the canvas, so the keys
  are anchored where their whole box lands inside it.

## Data

| File in `data/` | Read by | Origin |
|---|---|---|
| `Experiment-Effectiveness-{RealWorld,Synthetic-K2,Synthetic-K3}.dat` | RQ2 | `paper_figures/archive_data/` |
| `Experiment-Scalability-MCI-K{2,3}[-WAll].dat` | RQ3-Mining, RQ5-Mining | `paper_figures/archive_data/` |
| `Experiment-Scalability-RRI-K{2,3}[-WAll].dat` | RQ3-Reducing, RQ5-Reducing | `paper_figures/archive_data/` |
| `rw_p1.dat`, `rw_p2.dat` | RQ8, Real-world panels | `paper_figures/archive_data_journal/` |
| `p1_05.dat`, `p1_06.dat` | RQ8-ReducingPruning | `paper_figures/archive_data_journal/` |
| `p2_05.dat`, `p2_06.dat` | RQ8-MiningPruning | `paper_figures/archive_data_journal/10rs/` |
| `enc_05.dat`, `enc_06.dat` | RQ9 | regenerated, see below |

`enc_05.dat` and `enc_06.dat` are reproduced with
`tools/figures/extract_optimization_pipeline_10rs.sh`, except that the script
takes policies 3, 6, 9, 12 and 15 (`PICK='NR==3||NR==6||NR==9||NR==12||NR==15'`)
and these two files carry all fifteen. For the five policies the script keeps,
the two percentages here are the two it writes; only the leading policy index
differs, since the files here number all fifteen policies 0-14 and the script's
files number its five 0-4.
