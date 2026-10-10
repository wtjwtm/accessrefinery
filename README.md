# AccessRefinery: Fast Mining Concise Access Control Intents on Public Cloud

by [Ning Kang](https://xjtu-netverify.github.io/people/nkang/), [Peng Zhang](https://xjtu-netverify.github.io/people/pzhang/), [Jianyuan Zhang](https://xjtu-netverify.github.io/people/jyzhang/), Hao Li, Dan Wang, Zhenrong Gu, Weibo Lin, Shibiao Jiang, Zhu He, Xu Du, Longfei Chen, Jun Li and Xiaohong Guan.

![Java](https://img.shields.io/badge/Java-17-007396?logo=java&logoColor=white) ![Tests](https://img.shields.io/badge/tests-passing-brightgreen?logo=java) ![Paper](https://img.shields.io/badge/paper-FSE2026-orange) ![License](https://img.shields.io/badge/license-Apache--2.0-green)

## About AccessRefinery

*AccessRefinery* automatically mines access control intents from IAM (Identity and Access Management) policies. Compared with [AWS Access Analyzer](https://link.springer.com/content/pdf/10.1007/978-3-030-53288-8_9.pdf), *AccessRefinery* accelerates mining by about 10-100x and reduces the number of intents by up to 10x.

- To accelerate intent mining, *AccessRefinery* uses our Multi-Theory Constraint Preprocessor (*MCP*) to speed up multi-round SMT solving by preprocessing constraints into bit-vector form. We also designed *MCP* as a reusable data structure that may benefit other studies.
- For intent reduction, *AccessRefinery* computes a compact set that covers all mined intents by solving a minimum set-cover problem.

Moreover, the artifact ships the full implementation of *AccessRefinery* together with the datasets, archived results and plotting scripts of the extension experiment reported in the paper: the three-stage optimization pipeline behind RQ7-RQ9. The experiments of the original submission — RQ1-RQ6 and the *Access Analyzer* baseline — are not part of this repository.

## Optimization Pipeline

Beyond the original batch engine, this artifact implements a three-stage optimization pipeline, in which each stage removes the cost left by the previous one. The three stages are the paper's **Original**, **Pruning Reducer** and **Incremental MCP**.

| Stage | Optimization added |
|---|---|
| **Original** | — |
| **Pruning Reducer** | essential-finding pre-filter in the intent reducer |
| **Incremental MCP** | the miner's refinement-DAG node construction and BFS early-exit, the incremental EC engine and the cross-policy shared `MCPFactory` |

All three stages are selectable from a single build through three cumulative system properties. Each defaults to `true`, so an invocation with no switches at all is the fully optimized **Incremental MCP** stage:

| Switch | Optimization turned off |
|---|---|
| `-Dopt.pruner=false` | the *Pruning Reducer* (essential-finding pre-filter in the intent reducer) |
| `-Dopt.refinement=false` | the miner's refinement-DAG node construction and BFS early-exit |
| `-Dopt.incremental=false` | the *Incremental MCP* (incremental EC engine and cross-policy shared `MCPFactory`) |

The switches must precede `-jar` and compose: all three off gives **Original**, `-Dopt.refinement=false -Dopt.incremental=false` gives **Pruning Reducer**, and the default gives **Incremental MCP** — the three configurations `tools/accessrefinery/running_bdd_reducer_20rs.sh` runs. Turning a switch off restores the pre-optimization algorithm, not the archived numbers.

The archived *Incremental MCP* runs were produced with the incremental EC/BDD state shared across policies, i.e. with `-Dinc.independent=false`, which is one step away from the default; `running_bdd_reducer_20rs.sh` pins that property so the stage reproduces them.

## Getting AccessRefinery

You can download the AccessRefinery FSE 2026 artifact from the [GitHub repository](https://github.com/XJTU-NetVerify/accessrefinery.git):

```shell
git clone https://github.com/XJTU-NetVerify/accessrefinery.git
```

## Installing AccessRefinery

*AccessRefinery* builds with JDK 17 and Maven and needs no SMT solver of its own. We recommend using a Linux Ubuntu system because path-related dependency issues may occur on Windows and macOS.

see [REQUIREMENTS.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/REQUIREMENTS.md)  and [INSTALL.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/INSTALL.md) for details.

## Project Structure

- `data/`: Dataset for experiments.
  - `Scalability_05Keys/`, `Scalability_06Keys/`, `Scalability_05Keys∗/`: Synthetic scalability sets of 15 policies each, used for the statement-count sweeps. These are the paper's `5-Key`, `6-Key` and `5-Key*` datasets, in that order.
  - `RW/`: The real-world corpus of 506 policies. **Not public**, for commercial reasons, so the folder is absent and the run scripts skip it.
  - `Correctness/`: Correctness set used to check that the mined intents cover the policies.
- `accessrefinery/`: Implementation of *AccessRefinery*.
  - `bdd/`: Implementation of the binary decision diagram backend used by *MCP*.
  - `mcp/`: Implementation of the *Multi-Theory Constraint Preprocessor* (*MCP*).
  - `refinery/`: Implementation of intent mining and reduction.
- `pom.xml`: Maven root configuration.
- `tools/`: Scripts for running the experiments.
  - `accessrefinery/running_bdd_reducer_20rs.sh`: runs the three-stage optimization pipeline, 20 rounds.
  - `figures/extract_optimization_pipeline.sh`, `figures/extract_optimization_pipeline_10rs.sh`: extract the plotting data of Figures 18-21 from the per-stage `summary.txt` of the runs under `results/`.
  - `clean_plotting.sh`: clears the rendered PDFs under `paper_figures/results_journal/`.
- `docs/`:
  - `mcp-javadoc`: Javadoc for *MCP*.
  - `accessrefinery-javadoc`: Javadoc for *AccessRefinery*.
  - `figures/`: preview images of the paper figures, `figure18.png`-`figure21.png`.
- `paper_figures/`: Scripts and inputs for plotting the figures in the paper.
  - `gnuplot_journal/`, `archive_data_journal/`, `results_journal/`: the figures of the extension experiment, the three-stage optimization pipeline - the four figures that appear in the paper (Figures 18-21). `archive_data_journal/` also carries the real-world `RW` panels of Figures 18-20 as `rw_*.dat`; those come from the withheld corpus and are not regenerated.
  - `draw.sh`: redraws all four figures.
- `archive_results_journal/`: Archived experimental results of the extension experiment (the three-stage optimization pipeline), one folder per stage and per round count:
  - `accessrefinery_bdd_reducer_Original_20rs/`: **Original** (all three switches off), 20 rounds.
  - `accessrefinery_bdd_reducer_PruningReducer_20rs/`: **Pruning Reducer**, 20 rounds.
  - `accessrefinery_bdd_reducer_IncrementalMCP_20rs/`: **Incremental MCP** (the default build), 20 rounds.
  - `accessrefinery_bdd_reducer_Original_10rs/`, `..._PruningReducer_10rs/`, `..._IncrementalMCP_10rs/`: the same three stages run with `--round 10`, behind Figures 18, 20 and 21.
  - `accessrefinery_bdd_reducer_MiningOptimized_10rs/`: the 10-round `MiningOptimized` measurement configuration (`-Dopt.pruner=false -Dopt.refinement=true -Dopt.incremental=false`) behind Figure 21; it is not one of the three pipeline stages.

Each folder holds the dataset folders `Scalability_05Keys/`, `Scalability_06Keys/` and `Scalability_05Keys∗/`, 15 policies each, with an aggregated `summary.txt` beside the per-policy outputs. The `_20rs` stages were run with `--round 20`, the `_10rs` ones with `--round 10`.

Additionally, the `mcp` and `refinery` directories include Maven test cases under `src/test/java/org/iam/`, one set per module, to verify our code's correctness.

## Usages

### Build

In the root directory, run:

```shell
mvn clean package
```

The build generates the following JAR packages in `target/`:

- `mcp-1.0.jar` for *MCP*, which can be reused in other projects for fast multi-round SMT solving.
- `accessrefinery-1.0.jar` for *AccessRefinery*.

### Using Multi-Theory Constraint Preprocessor (MCP)

*MCP* is a data structure for fast multi-round SMT solving. It supports regular expressions, IP prefixes/bit-vectors, ranges, and sets.

#### Reuse in Another Project

Install `target/mcp-1.0.jar` into your local Maven repository:

```shell
mvn install:install-file \
    -Dfile=target/mcp-1.0.jar \
    -DgroupId=org.iam \
    -DartifactId=mcp \
    -Dversion=1.0 \
    -Dpackaging=jar \
    -DgeneratePom=true
```

Then add the dependency to your `pom.xml`:

```xml
<dependencies>
    <dependency>
        <groupId>org.iam</groupId>
        <artifactId>mcp</artifactId>
        <version>1.0</version>
    </dependency>
</dependencies>
```

#### Example

This section illustrates how to use *MCP* with the example in the paper (line 414). Suppose we have the following IAM policy and a target intent, `Intent_6` (`Resource`: `dept*/user1.txt`, `IpAddress`: `112.0.0.0/24`).

```json
{
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": ["dept*/user1.txt", "dept1/user*.txt"],
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": ["112.0.0.0/24", "113.0.0.0/24"]
                }
            }
        },
        {
            "Effect": "Deny",
            "NotResource": "dept*/user1.txt",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "112.0.0.0/24"
                }
            }
        },
        {
            "Effect": "Deny",
            "NotResource": "dept1/user*.txt",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp" : "113.0.0.0/24"
                }
            }
        }
    ]
}
```

To check the satisfiability of three formulas, ¬I6∧P, I6∧¬P, and I6∧P, we use the following code based on *MCP*.

```java
public class Main {
    public static void main(String[] args) {
        MCPFactory mcp = new MCPFactory(MCPType.BDD);
        mcp.addVar("Res", LabelType.REGEXP, "dept*/user1.txt");
        mcp.addVar("Res", LabelType.REGEXP, "dept1/user*.txt");
        mcp.addVar("IP", LabelType.PREFIX, Prefix.parse("112.0.0.0/24"));
        mcp.addVar("IP", LabelType.PREFIX, Prefix.parse("113.0.0.0/24"));
        mcp.updates();

        MCPBitVector res1 = mcp.getVar("Res", "dept*/user1.txt");
        MCPBitVector res2 = mcp.getVar("Res", "dept1/user*.txt");
        MCPBitVector ip1 = mcp.getVar("IP", Prefix.parse("112.0.0.0/24"));
        MCPBitVector ip2 = mcp.getVar("IP", Prefix.parse("113.0.0.0/24"));
        MCPBitVector s1 = (res1.or(res2)).and(ip1.or(ip2));
        MCPBitVector s2 = res1.not().and(ip1);
        MCPBitVector s3 = res2.not().and(ip2);
        MCPBitVector policy = s1.diff(s2).diff(s3);
        MCPBitVector intent6 = res1.and(ip1);

        // ¬I6∧P is satisfiable.
        Assert.assertTrue(!policy.and(intent6.not()).isZero());
        // I6∧¬P is unsatisfiable.
        Assert.assertTrue(policy.not().and(intent6).isZero());
        // I6∧P is satisfiable.
        Assert.assertTrue(!policy.and(intent6).isZero());
    }
}
```

A shortened form of this example is implemented in [MCPFactoryTest.java](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/accessrefinery/mcp/src/test/java/org/iam/core/MCPFactoryTest.java), inside the `mcp` module: the test builds the same *MCP* and checks the first of the three results above, that ¬I6∧P is satisfiable. Running the following command executes it.

```shell
# The complete workflow (build plus test) takes about 3 minutes.
mvn install
mvn test -pl ./accessrefinery/mcp -Dtest=MCPFactoryTest#testMCPFactory
```

Expected output:

```text
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.579 s
[INFO] Finished at: 2026-04-10T22:58:08+08:00
[INFO] ------------------------------------------------------------------------
```

### Using AccessRefinery

*AccessRefinery* builds on *MCP* for IAM intent mining and reduction. In this repository, *MCP* is already integrated into *AccessRefinery*, so you can use it directly without a separate installation.

```shell
java -jar target/accessrefinery-1.0.jar [options]
```

Command-line options:

- `-h, --help` : Show help information.
- `-m, --mine` : Enable intent mining.
- `-r, --reduce` : Enable intent reduction.
- `-f, --file <path>` : Input path for policy files (must be under `data/`).
- `-s, --sat` : Use SAT to encode bit-vectors (default is BDD).
- `--round <number>` : Number of mining rounds (to reduce experimental bias).
- `--rest` : Enable REST mode, which maintains the remaining policy space incrementally across findings.
- `--merge` : Merge intents in the output.
- `--zelkova` : Run in Zelkova mode.

In addition, the incremental EC engine can be switched between per-policy and cross-policy behavior with a JVM property:

- `-Dinc.independent=true` (default): each policy gets its own fresh `MCPFactory`, so no state accumulates across policies.
- `-Dinc.independent=false`: one shared `MCPFactory` drives all policies within a round, so the incremental EC/BDD state is carried forward across policies.

Setting `-Dopt.incremental=false` (see [Optimization Pipeline](#optimization-pipeline)) disables both the incremental EC engine and the cross-policy shared `MCPFactory`, restoring the original per-policy EC construction; it forces this per-policy behavior whatever `inc.independent` says.

**Example:**

```shell
java -jar target/accessrefinery-1.0.jar -m -r --round 1 -f data/Correctness
```

Expected output:

```text
[INFO] 2026-04-05 22:51:33 : ----------[ AccessRefinery Mode ]-------------
[INFO] 2026-04-05 22:51:33 : logger path: /path/to/accessrefinery.log
[INFO] 2026-04-05 22:51:33 : input  path: data/Correctness
[INFO] 2026-04-05 22:51:33 : output path: result/Correctness
[INFO] 2026-04-05 22:51:33 : [1/6]  finish parser policy
[INFO] 2026-04-05 22:51:33 : [2/6]  finish ECs calculation
```

In `AccessRefinery` mode the log prints no per-policy header line: each policy contributes its own `[1/6]`–`[6/6]` group. Timestamps and paths above are illustrative.

Results are generated in the `result/Correctness/` directory and include:

- `xxx.json`: The intents for each policy.
- `xxx.csv`: Statistics for multi-round SMT solving for each policy.
- `summary.txt`: Summary statistics for all policies in a folder.

In addition, one file is generated in the current path:

- `accessrefinery.log` : Records the running log.

## Running Experiments

This section describes (1) how to reproduce the results in `results/`, and (2) how to reproduce the corresponding figures and conclusions in the paper from `results/`.

*In this artifact we additionally report results on the real-world `RW` dataset. The real-world policies are not publicly available due to commercial restrictions, so the corpus itself is not released.*

### Reproducing Results

`archive_results_journal/` holds the immutable results shipped with this artifact, and `results/` is the working directory that the experiment scripts write to and that the extraction scripts read from. Every experiment below can therefore either be run or skipped by copying the corresponding archive folder into `results/`.

- **Reproducing AccessRefinery Results**

The three-stage optimization pipeline is run by one script, which invokes `target/accessrefinery-1.0.jar` once per stage with the cumulative switch configurations described under [Optimization Pipeline](#optimization-pipeline):

```shell
# The execution takes about 80 minutes.
sh tools/accessrefinery/running_bdd_reducer_20rs.sh
```

The 10-round run behind Figures 18, 20 and 21 has no script in this artifact; populate `results/` from the archive instead.

```shell
mkdir -p results/

# the 10-round stage folders behind Figures 18, 20 and 21
for stage in _Original _PruningReducer _IncrementalMCP _MiningOptimized; do
  cp -r archive_results_journal/accessrefinery_bdd_reducer${stage}_10rs results/
done

# the 20-round run behind Figure 19
for stage in _Original _PruningReducer _IncrementalMCP; do
  cp -r archive_results_journal/accessrefinery_bdd_reducer${stage}_20rs results/
done
```

Expected Output:

- `results/`: one folder per stage and per round count — the three pipeline stages (`Original`, `PruningReducer`, `IncrementalMCP`) at 20 rounds and, behind Figures 18, 20 and 21, at 10 rounds, plus `..._MiningOptimized_10rs/`, the non-stage configuration behind Figure 21.

### Reproducing Claims in the Paper

After generating `results/`, we show how to reproduce the claims in the paper with scripts.

Although we provide automated scripts that extract results from the `results/` directory to reproduce the claims in the paper, we also document, for each claim, the specific data used from results. See [REPRODUCTION.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/REPRODUCTION.md) for full details. The claims covered here are RQ7-RQ9, the three-stage optimization pipeline; the material behind RQ1-RQ6 is not shipped in this repository, and neither is the AWS Access Analyzer baseline.

Before plotting, we recommend clearing previously rendered PDFs so that every figure below is regenerated rather than reused:

```shell
sh tools/clean_plotting.sh
```

This clears `paper_figures/results_journal/` only. The plotting inputs in `paper_figures/archive_data_journal/` are never touched: they carry the real-world `RW` panels, which cannot be regenerated from anything in the artifact.

#### Plotting Figures 18-21 (RQ7-RQ9)

The three-stage optimization pipeline (Original → Pruning Reducer → Incremental MCP) is the extension experiment of this revision. Its data lives in `paper_figures/archive_data_journal/`, extracted from the per-policy `summary.txt` of the corresponding stage folders under `archive_results_journal/` (`accessrefinery_bdd_reducer_Original_20rs/`, `..._PruningReducer_20rs/` and `..._IncrementalMCP_20rs/`), with the `.plt` files in `paper_figures/gnuplot_journal/` and the rendered PDFs in `paper_figures/results_journal/`.

Three of the four figures below read a second data set instead, `paper_figures/archive_data_journal/10rs/`, which `tools/figures/extract_optimization_pipeline_10rs.sh` extracts from the per-stage `summary.txt` of the 10-round stage folders under `results/accessrefinery_bdd_reducer_*_10rs/`; the remaining one, Figure 19, reads `archive_data_journal/` itself, which `tools/figures/extract_optimization_pipeline.sh` extracts from the 20-round stage folders under `results/`.

The real-world `RW` corpus is not public, for commercial reasons, so the pipeline cannot be re-run over it; this reproduction covers the `05Keys`, `06Keys` and `05Keys∗` datasets.

```shell
bash tools/figures/extract_optimization_pipeline_10rs.sh   # Figures 18, 20, 21
bash tools/figures/extract_optimization_pipeline.sh        # Figure 19

cd paper_figures

# Original vs Pruning Reducer (essential-finding pre-filter in the intent reducer)
gnuplot gnuplot_journal/RQ8-ReducingPruning-Original-PruningReducer.plt

# Pruning Reducer vs Incremental MCP (incremental EC engine, shared MCPFactory)
gnuplot gnuplot_journal/RQ8-MiningPruning-PruningReducer-IncrementalMCP.plt

# All three stages, total execution time
gnuplot gnuplot_journal/RQ7-Optimization-Overview-Bars-3Stage.plt

# Share of each phase's window spent on the encoding side
gnuplot gnuplot_journal/RQ9-Optimization-Overview-Bars-Percentage.plt
```

Expected Output (in `paper_figures/results_journal/`):

- `RQ7-Optimization-Overview-Bars-3Stage.pdf`: total execution time of all three stages, i.e. the paper's **Figure 18** (RQ7).
- `RQ8-ReducingPruning-Original-PruningReducer.pdf`: the intent reducer with and without the *Pruning Reducer*, on `5-Key`/`6-Key`/`5-Key*`/`RW`, i.e. the paper's **Figure 19**, the first of RQ8's two figures (all four panels).
- `RQ8-MiningPruning-PruningReducer-IncrementalMCP.pdf`: the intent mining time per policy of the *Pruning Reducer* stage and of the *Incremental MCP* stage, on `5-Key`/`6-Key`/`5-Key*`/`RW`, i.e. the paper's **Figure 20**, the second of RQ8's two figures.
- `RQ9-Optimization-Overview-Bars-Percentage.pdf`: the share of each phase's window spent on the encoding side, i.e. the paper's **Figure 21** (RQ9). It reads its own configuration, labelled `MiningOptimized` under `results/accessrefinery_bdd_reducer_MiningOptimized_10rs/`.

All four figures above are the ones the paper prints. Two further renderings of the first of them were withdrawn from this revision: `Optimization-Overview-Bars.pdf`, the same three stages drawn from the 20-round archive (`paper_figures/archive_data_journal/p_bar_ix_*.dat` and `rw_bar_ix.dat`) rather than from the 10-round run, and `Optimization-Overview-Bars-Segmented.pdf`, which splits each stage's bar into its mining and reducing parts and which the paper never printed. Their plotting data stays checked in — `rw_bar_ix.dat` needs the withheld real-world corpus and could not be regenerated.

Preview images of the paper figures are kept in `docs/figures/` as `figure18.png`--`figure21.png`. Figures 18-20 each carry a real-world `RW` panel of 506 policies in addition to the three synthetic ones.

## For Developers

- We develop *AccessRefinery* in VS Code, see [VSCODE.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/docs/vscode-develop/VSCODE.md).

- We provide Javadoc documentation (automatically generated by `Microsoft Copilot`) for *MCP* in `docs/mcp-javadoc/`, available on [GitHub Pages](https://916267142.github.io/mcp.github.io/), and for *AccessRefinery* in `docs/accessrefinery-javadoc/`, available on [GitHub Pages](https://916267142.github.io/accessrefinery.github.io/).

## License

Apache-2.0 License, see [LICENSE](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/LICENSE).

## Contact

Feel free to contact us if you have any questions.

- Ning Kang (<kangning2018@foxmail.com>)
- Jianyuan Zhang (<jyzhang0281@foxmail.com>)
- Yijia Wang (<wyjia0610@foxmail.com>)