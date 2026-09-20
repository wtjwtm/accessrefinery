# AccessRefinery: Fast Mining Concise Access Control Intents on Public Cloud

by [Ning Kang](https://xjtu-netverify.github.io/people/nkang/), [Peng Zhang](https://xjtu-netverify.github.io/people/pzhang/), [Jianyuan Zhang](https://xjtu-netverify.github.io/people/jyzhang/), Hao Li, Dan Wang, Zhenrong Gu, Weibo Lin, Shibiao Jiang, Zhu He, Xu Du, Longfei Chen, Jun Li and Xiaohong Guan.

![Java](https://img.shields.io/badge/Java-17-007396?logo=java&logoColor=white) ![Tests](https://img.shields.io/badge/tests-passing-brightgreen?logo=java) ![Paper](https://img.shields.io/badge/paper-FSE2026-orange) ![License](https://img.shields.io/badge/license-Apache--2.0-green)

## About AccessRefinery

*AccessRefinery* automatically mines access control intents from IAM (Identity and Access Management) policies. Compared with [AWS Access Analyzer](https://link.springer.com/content/pdf/10.1007/978-3-030-53288-8_9.pdf), *AccessRefinery* accelerates mining by about 10-100x and reduces the number of intents by up to 10x.

- To accelerate intent mining, *AccessRefinery* uses our Multi-Theory Constraint Preprocessor (*MCP*) to speed up multi-round SMT solving by preprocessing constraints into bit-vector form. We also designed *MCP* as a reusable data structure that may benefit other studies.
- For intent reduction, *AccessRefinery* computes a compact set that covers all mined intents by solving a minimum set-cover problem.

Moreover, the artifact includes the full implementations of *AccessRefinery* and the baseline reimplementation of *Access Analyzer*, along with datasets, archived results, experiment scripts, and plotting scripts to reproduce the results reported in the paper. For technical details, see our [FSE 2026 paper](https://xjtu-netverify.github.io/papers/AccessRefinery/accessrefinery_final_version.pdf).

## Optimization Pipeline

Beyond the original batch engine, this artifact implements a four-stage optimization pipeline, **BR → AR → AM → AI**, in which each stage removes the cost left by the previous one:

- **BR → AR (essential-finding pre-filter, intent reducer).** A BDD prefix/suffix scan identifies the intents already covering the policy space and removes non-essential intents before reduction, so the reducer avoids solving ILP for candidates that cannot contribute a new essential finding.
- **AR → AM (refinement DAG and BFS early-exit in the intent miner).** The miner derives, via `getRestBDD`, the residual BDD of each finding — the region it covers but none of its children do — by subtracting its children's nodes one after another (`((findingNode \ c₁) \ c₂) \ …`), so the remaining policy space is maintained locally instead of being re-materialized from the full decision tree. AM makes that reduction cheap in two ways: each child's node is built as `parentNode ∧ var(refinedKey)` along a refinement DAG rather than by re-conjoining every domain of the intent, which replaces a conjunction over all domains with a single `and` against one refinement variable; and a finding disjoint from the remaining policy space is dropped before its subtree is expanded, so the reduction is never reached for intents that cannot contribute a new finding.
- **AM → AI (incremental EC engine).** The EC engine is replaced by an incremental one based on Delta-net's atom-splitting approach (`ECEngine`), which splits only the ECs intersecting with newly added labels rather than re-enumerating the full label set on every update. Its incremental state is shared and carried forward across policies through a single `MCPFactory` mounted on the policy model, so the structure accumulated for one policy is extended by the next instead of being rebuilt from scratch.

Each optimization is validated in the paper by a two-stage comparison (e.g. BR vs. AR, AR vs. AM, AM vs. AI) over the `Scalability_05/06/07Keys` datasets and the real-world `RW` dataset. The `RW` policies themselves are not public (see [Project Structure](#project-structure)), but the per-stage `summary.txt` files the runs produced are, and only re-running the pipeline over `RW` is not possible.

All four stages are selectable from a single build through three cumulative system properties. Each defaults to `true`, so an invocation with no switches at all is the fully optimized **AI** stage:

| Switch | Stage disabled | Optimization turned off |
|---|---|---|
| `-Dopt.ar=false` | AR | essential-finding pre-filter in the intent reducer |
| `-Dopt.am=false` | AM | refinement-DAG node construction and BFS early-exit in the intent miner |
| `-Dopt.ai=false` | AI | incremental EC engine and cross-policy shared `MCPFactory` |

The switches must precede `-jar`, and they compose: `-Dopt.am=false -Dopt.ai=false` gives **AR**, all three off gives **BR**. `tools/accessrefinery/running_bdd_reducer_20rs.sh` runs all four stages this way. Turning a switch off restores the pre-optimization algorithm, not the archived numbers — the four configurations must, however, produce semantically equivalent findings; their textual intent representations can differ where cross-policy factory sharing contributes additional fully permissive domains (see [Using AccessRefinery](#using-accessrefinery)).

## Getting AccessRefinery

You can download the AccessRefinery FSE 2026 artifact from the [GitHub repository](https://github.com/XJTU-NetVerify/accessrefinery.git):

```shell
git clone https://github.com/XJTU-NetVerify/accessrefinery.git
```

## Installing AccessRefinery

Because this repository includes a baseline reimplementation of AWS Access Analyzer that depends on the SMT solvers `CVC5` and `Z3`, we provide automated installation steps. We recommend using Linux Ubuntu system because path-related dependency issues may occur on Windows and macOS.

see [REQUIREMENTS.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/REQUIREMENTS.md)  and [INSTALL.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/INSTALL.md) for details.

## Project Structure

Since *AWS Access Analyzer* is not open source and provides only a Command-Line Interface (CLI), we also reimplement *Access Analyzer* for evaluation.

- `data/`: Dataset for experiments.
  - `Scalability_05Keys/`, `Scalability_06Keys/`, `Scalability_07Keys/`: Synthetic scalability sets of 15 policies each, used for the statement-count sweeps.
  - `RW/`: **Not public.** The real-world corpus of 506 policies, in the labeled version in which the synthesized label `s3:::886499mir` is added to every statement so that each policy contains at least one label to be mined. The raw real-world policies are not publicly available due to commercial restrictions, so the corpus itself is not released. What the runs over it produced — the aggregated per-stage `summary.txt` (nine numeric columns per policy, no policy text) and the plotting data derived from it — is public, in the stage folders and in `paper_figures/archive_data/` and `paper_figures/archive_data_new/`. Only the experiments themselves cannot be re-run. See [REPRODUCTION.md](REPRODUCTION.md).
  - `Correctness/`: Correctness set used to check that the mined intents cover the policies.
- `accessrefinery/`: Implementation of *AccessRefinery*.
  - `bdd/`: Implementation of the binary decision diagram backend used by *MCP*.
  - `mcp/`: Implementation of the *Multi-Theory Constraint Preprocessor* (*MCP*).
  - `refinery/`: Implementation of intent mining and reduction.
- `baselines/`:
  - `accessanalyzer-reimpl`: Reimplementation of *Access Analyzer*.
  - `accessanalyzer-cli`: Scripts for invoking *AWS Access Analyzer* via CLI.
- `pom.xml`: Maven root configuration.
- `tools/`: Scripts for running the experiments.
- `docs/`:
  - `mcp-javadoc`: Javadoc for *MCP*.
  - `accessrefinery-javadoc`: Javadoc for *AccessRefinery*.
- `paper_figures/`: Scripts and inputs for plotting the figures in the paper.
  - `gnuplot/`, `archive_data/`, `results/`: the figures of the original submission.
  - `gnuplot_new/`, `archive_data_new/`, `results_new/`: the four figures of the extension experiment, the BR → AR → AM → AI optimization pipeline.
- `archive_results/`: Archived experimental results of the experiments reported in the original submission.
- `archive_results_new/`: Archived experimental results of the extension experiment (the BR → AR → AM → AI optimization pipeline), one folder per stage:
  - `accessrefinery_bdd_reducer_20rs/`: BR (the original stage).
  - `accessrefinery_bdd_reducer_AR_20rs/`: AR.
  - `accessrefinery_bdd_reducer_AM_20rs/`: AM.
  - `accessrefinery_bdd_reducer_AI_20rs/`: AI.

  Each stage folder holds the dataset folders `Scalability_05Keys/`, `Scalability_06Keys/`, `Scalability_07Keys/` and `RW/`; each dataset folder holds the per-policy `*_result.json`, `*_time.csv` and the aggregated `summary.txt`. The three scalability folders contain 15 policies each; `RW/` covers the 506 policies of the labeled real-world corpus (`data/RW/`, see above), but only its aggregated `summary.txt` is public — the per-policy `*_result.json` and `*_time.csv` are not, because the policies they would reveal are not public. All four stages were run with `--round 20` (`tools/accessrefinery/running_bdd_reducer_20rs.sh`). `summary.txt` has a header row followed by one row per policy, with the columns `NumberStatement, NumberMCI, NumberRRI, MCISolvingRoundAverage, TotalTimeAverage, MCILabelsTimeAverage, MCIOperationsTimeAverage, RRIOperationsTimeAverage, RRIILPSolvingTimeAverage` (times in ms).

Additionally, the `mcp` and `refinery` directories include Maven test cases that can be used to verify our code's correctness and to help developers run tests.

- The `accessrefinery/mcp/src/test/java/org/iam/` directory contains all test cases for the MCP Java code.
- The `accessrefinery/refinery/src/test/java/org/iam/` directory contains all test cases for the AccessRefinery Java code.

## Usages

### Build

In the root directory, run:

```shell
mvn clean package
```

The build generates the following JAR packages in `target/`:

- `mcp-1.0.jar` for *MCP*, which can be reused in other projects for fast multi-round SMT solving.
- `accessrefinery-1.0.jar` for *AccessRefinery*.
- `accessanalyzer-1.0.jar` for the *reimplemented Access Analyzer*.

### Using Multi-Theory Constraint Preprocessor (MCP)

*MCP* is a data structure for fast multi-round SMT solving. It supports regular expressions, IP prefixes/bit-vectors, ranges, and sets.

#### Reuse in Another Project

Install `target/mcp-1.0.jar` into your local Maven repository:

```shell
mvn install:install-file \
    -Dfile=target/mcp-1.0.jar \
    -DgroupId=org.ants \
    -DartifactId=accessrefinery \
    -Dversion=1.0 \
    -Dpackaging=jar \
    -DgeneratePom=true
```

Then add the dependency to your `pom.xml`:

```xml
<dependencies>
    <dependency>
        <groupId>org.ants</groupId>
        <artifactId>accessrefinery</artifactId>
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

The code is included in [MCPFactoryTest.java](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/accessrefinery/mcp/src/test/java/org/iam/core/MCPFactoryTest.java), and *MCP* is imported as a Maven dependency. Running the following command automatically executes this example.

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

In addition, the incremental EC engine can be switched between cross-policy and per-policy behavior with a JVM property:

- `-Dinc.independent=false` (default): one shared `MCPFactory` drives all policies within a round, so the incremental EC/BDD state is carried forward across policies.
- `-Dinc.independent=true`: each policy gets its own fresh `MCPFactory`, so no state accumulates across policies.

The shared factory is a whole-corpus optimization: it is what makes the large corpora fast (on `Scalability_05Keys/` it is about 7x faster than the per-policy configuration), but it is a net loss on a small corpus whose policies do not all use the same condition keys, and it changes the intents that are written out. Every policy's intent is seeded from the domains the factory holds, so on such a corpus a policy also receives condition keys declared only by its neighbours. Those extra keys carry a fully permissive value, so they denote the same requests, but they make the intent differ textually from the per-policy run. Use per-policy factories for correctness checking: on `data/Correctness/` that yields the reference intents and cuts SMT solving from 1859 to 314 rounds (summing the `MCISolvingRoundAverage` column of `summary.txt` over the twelve policies; a round count is reproducible, unlike wall-clock time).

Setting `-Dopt.ai=false` (see [Optimization Pipeline](#optimization-pipeline)) disables both the incremental EC engine and the cross-policy shared `MCPFactory`, restoring the original per-policy EC construction; it forces this per-policy behavior whatever `inc.independent` says.

**Example:**

```shell
java -Dinc.independent=true -jar target/accessrefinery-1.0.jar -m -r --round 1 -f data/Correctness
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

### Using reimplemented Access Analzyer (Baseline)

see [AccessAnalyzerUsage.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/docs/AccessAnalyzerUsage.md)

## Running Experiments

This section describes (1) how to reproduce the results in `results/`, and (2) how to reproduce to the corresponding figures, tables, and conclusions in the paper from `results/`.

*In this artifact we additionally report results on the real-world `RW` dataset; the corpus used here is the labeled version described above (see `data/RW/`). The raw real-world policies are not publicly available due to commercial restrictions, so the corpus itself is not released — but the per-stage `summary.txt` files and the plotting data they produced are.*

### Reproducing  Results

- **Reproducing AccessRefinery Results**

`archive_results/` and `archive_results_new/` hold the immutable results shipped with the artifact — the first for the experiments of the original submission, the second for the extension experiment (the four-stage optimization pipeline); `results/` is the working directory that the experiment scripts write to and that the extraction scripts read from. Every experiment below can therefore either be run or skipped by copying the corresponding archive folder into `results/`.

Running *AccessRefinery* with MiniSAT backend takes a long time. You can skip it by running the following commands to directly reuse the data in the `archive_results/` directory.

```shell
# skip running AccessRefinery with the MiniSAT backend
mkdir -p results/ 
cp -r archive_results/accessrefinery_sat_*rs results/

# skip running AccessRefinery with the BDD backend
mkdir -p results/ 
cp -r archive_results/accessrefinery_bdd_*rs results/

# skip running the four-stage optimization pipeline (BR -> AR -> AM -> AI)
mkdir -p results/
for stage in "" _AR _AM _AI; do
  cp -r archive_results_new/accessrefinery_bdd_reducer${stage}_20rs results/
done
```

The following scripts invoke `target/accessrefinery-1.0.jar`.

```shell
# The execution takes about 7 minutes.
sh tools/accessrefinery/running_bdd_miner.sh

# The execution takes about 8 minutes.
sh tools/accessrefinery/running_bdd_reducer.sh

# The execution takes about 80 minutes.
sh tools/accessrefinery/running_sat_miner.sh

# The execution takes >12 hours.
sh tools/accessrefinery/running_sat_reducer.sh

# The four-stage optimization pipeline, 20 rounds: one build, four cumulative
# switch configurations, each archived under its own folder name.
sh tools/accessrefinery/running_bdd_reducer_20rs.sh
```

Expected Output:

- `results/`: All experiments are run for 10 rounds, and average time is reported.

  - `accessrefinery_bdd_miner_10rs/`: intent mining using JavaBDD.
  - `accessrefinery_sat_miner_10rs/`: intent mining using MiniSAT.
  - `accessrefinery_bdd_reducer_10rs/`: intent mining and reduction using JavaBDD.
  - `accessrefinery_sat_reducer_3rs/`: intent mining and reduction using MiniSAT (limited to 3 rounds due to slow execution).
  - `accessrefinery_bdd_reducer_20rs/`, `accessrefinery_bdd_reducer_AR_20rs/`, `accessrefinery_bdd_reducer_AM_20rs/`, `accessrefinery_bdd_reducer_AI_20rs/`: intent mining and reduction at each stage of the four-stage pipeline (BR → AR → AM → AI), 20 rounds.

- **Reproducing Reimplemented Access Analyzer Results**

This section takes a long time to run. You can skip it by running the following commands to directly reuse the data in the `archive_results/` directory.

```shell
mkdir -p results/ 
cp -r archive_results/accessanalyzer_*rs results/
```

The following scripts invoke `target/accessanalyzer-1.0.jar`.

```shell
# The execution takes about 5 hours.
bash tools/accessanalyzer-reimpl/mining_miner_cvc5.sh

# The execution takes about 4 hours.
# The time is less than that of AccessRefinery, because of an early timeout.
bash tools/accessanalyzer-reimpl/mining_reducer_cvc5.sh

# The execution takes about 4 hours
bash tools/accessanalyzer-reimpl/mining_miner_z3.sh

# The execution takes about 4 hours
bash tools/accessanalyzer-reimpl/mining_reducer_z3.sh
```

*Note: `Ctrl + C` or `Ctrl + Z` end the scripts*

Expected Output:

- `results/`: All results run for one round due to limited execution time.
  - `accessanalyzer_z3_miner_1rs/`: intent mining using Z3 Solver.
  - `accessanalyzer_cvc5_miner_1rs/`: intent mining using CVC5 Solver.
  - `accessanalyzer_z3_reducer_1rs/`: intent mining and reduction using Z3 Solver.
  - `accessanalyzer_cvc5_reducer_1rs/`: intent mining and reduction using CVC5 Solver.

- **Reproducing AWS Access Analyzer via CLI Results**

Because invoking Access Analyzer via CLI requires a private AWS account, we do not provide this step. However, we still provide scripts for developers; see [AccessAnalyzerCLI.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/baselines/accessanalyzer-cli/AccessAnalyzerCLI.md) for details.

 We strongly recommend skipping this step and directly using the results in `archive_results/accessanalyzer_cli/`, since the setup is complex and requires AWS account registration, billing configuration, and CLI credential setup.

```shell
mkdir -p results/
cp -r archive_results/accessanalyzer_cli/ results/accessanalyzer_cli/
```

### Reproducing Claims in the Paper

After generating `results/`, we show how to reproduce the claims in the paper with scripts.

Although we provide automated scripts that extract results from the `results/` directory to reproduce the claims in the paper, we also document, for each claim, the specific data used from results. See [REPRODUCTION.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/REPRODUCTION.md) for full details.

<!-- Although we provide automated scripts to extract results from the `results/` directory and generate plotting data files, we also document the exact data sources used for each figure and table in the paper (for example, which file and which column were used). Detailed mappings are available on our GitHub Pages: [REPRODUCTION.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/REPRODUCTION.md). -->

Before plotting, we recommend clearing previously rendered PDFs so that every figure below is regenerated rather than reused:

```shell
sh tools/clean_plotting.sh
```

This clears `paper_figures/results/` and `paper_figures/results_new/` only. The plotting inputs in `paper_figures/archive_data/` and `paper_figures/archive_data_new/` are never touched — three of them cannot be regenerated from anything in the artifact.

#### Verifying Correctness of MCP (Section 6.1)

```shell
# The complete workflow (build plus test) takes about 3 minutes.
mvn install
mvn test -pl ./accessrefinery/mcp -Dtest=MCPTest#testComplexSATOperations
```

```text
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.212 s
[INFO] Finished at: 2026-04-10T17:10:38+08:00
[INFO] ------------------------------------------------------------------------
```

#### Plotting Figure 10（Section 6.1）

```shell
bash ./tools/figures/extract_correctness_synthetic.sh
(cd paper_figures && gnuplot gnuplot/RQ1-Experiment-Correctness.plt)
```

Expected Output:

- `paper_figures/results/RQ1-Experiment-Correctness.pdf`

#### Verifying Correctness of Intent Miner (Section 6.1)

```shell
# Compare AccessRefinery and AWS Access Analyzer via CLI
sh tools/running_batch_compare.sh

# Compare AccessRefinery and reimplemented Access Analyzer
sh tools/accessanalyzer-reimpl/running_accessanalyzer_compare_with_refinery.sh
```

Expected Output:

- `results/`
  - `accessrefinery_miner_compare_results/*.log`
  - `accessanalyzer_miner_compare_results_with_refinery/*.log`

#### Verifying Correctness of Intent Reducer (Section 6.1)

```shell
# The execution takes about 5 hour.
bash ./tools/accessanalyzer-reimpl/check_coverage.sh
```

Expected Output:

- `results/coverage_check/`
  - `Correctness/*_coverage.log`
  - `Scalability_05Keys/*_coverage.log`
  - `Scalability_06Keys/*_coverage.log`

#### Plotting Figure 11 (Section 6.2)

```shell
bash tools/figures/extract_effectiveness_synthetic.sh
(cd paper_figures && gnuplot gnuplot/RQ2-Experiment-Effectiveness.plt)
```

Expected Output:

- `paper_figures/results/RQ2-Experiment-Effectiveness.pdf`

#### Plotting Figure 12 (Section 6.3)

```shell
bash tools/figures/extract_scalability_MCI.sh
(cd paper_figures && gnuplot gnuplot/RQ3-Experiment-Scalability-Mining.plt)
```

Expected Output:

- `paper_figures/results/RQ3-Experiment-Scalability-Mining.pdf`

#### Plotting Figure 13 (Section 6.3)

```shell
bash tools/figures/extract_scalability_RRI.sh
(cd paper_figures && gnuplot gnuplot/RQ3-Experiment-Scalability-Reducing.plt)
```

Expected Output:

- `paper_figures/results/RQ3-Experiment-Scalability-Reducing.pdf`

#### Plotting Figure 15 (Section 6.5)

```shell
bash tools/figures/extract_scalability_RRI.sh
(cd paper_figures && gnuplot gnuplot/RQ5-Experiment-MicroBenchmark-Reducing.plt)
```

Expected Output:

- `paper_figures/results/RQ5-Experiment-MicroBenchmark-Reducing.pdf`

#### Plotting Table 2 (Section 6.6)

```shell
bash tools/figures/generate_table.sh
```

Expected Output:

```text
# statements    # intents    Z3         CVC5       MCP        MCP preprocessing
3    9     192.1ms    28.0ms    77.5μs    54.5ms
6    36    756.3ms    245.3ms   64.4μs    189.7ms
9    81    1517.3ms   987.0ms   104.1μs   394.3ms
12   144   3122.2ms   4979.3ms  190.2μs   1011.7ms
15   225   4545.8ms   N/A ms    274.5μs   1741.5ms
```

#### Plotting the Optimization Pipeline Figures (Extension Experiment)

The four-stage optimization pipeline (BR → AR → AM → AI) is the extension experiment of this revision. Its data lives apart from the rest of the artifact: `paper_figures/archive_data_new/`, extracted from the per-policy `summary.txt` of the corresponding stage folders under `archive_results_new/` (`accessrefinery_bdd_reducer_20rs/` for BR, `..._AR_20rs/`, `..._AM_20rs/`, `..._AI_20rs/`), with the `.plt` files in `paper_figures/gnuplot_new/` and the rendered PDFs in `paper_figures/results_new/`.

```shell
cd paper_figures

# BR vs AR (essential-finding pre-filter in the intent reducer)
gnuplot gnuplot_new/RQ7-ReducingPruning-BR-AR.plt

# AR vs AM (BFS early-exit and refinement DAG in the intent miner)
gnuplot gnuplot_new/RQ8-MiningPruning-AR-AM.plt

# AM vs AI (incremental EC engine)
gnuplot gnuplot_new/RQ9-Incremental-AM-AI.plt

# All four stages, total execution time
gnuplot gnuplot_new/Optimization-Overview-Bars.plt
```

Expected Output (in `paper_figures/results_new/`):

- `Optimization-Overview-Bars.pdf`: total execution time of all four stages (Figure 16).
- `RQ7-ReducingPruning-BR-AR.pdf`: BR vs. AR on `5-Keys`/`6-Keys`/`7-Keys`/`RW` (Figure 17, all four panels).
- `RQ8-MiningPruning-AR-AM.pdf`: AR vs. AM (Figure 18).
- `RQ9-Incremental-AM-AI.pdf`: AM vs. AI (Figure 19).

Preview images of these four figures are kept in `docs/figures/` as `figure16.png`--`figure19.png`. Each of the four has a real-world `RW` panel of 506 datasets in addition to the three synthetic ones.

## For Developers

- We develop *AccessRefinery* in VS Code, see [VSCODE.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/docs/vscode-develop/VSCODE.md).

- We provide Javadoc documentation (automatically generated by `Microsoft Copilot`) for *MCP* in `docs/mcp-javadoc/`, available on [GitHub Pages](https://916267142.github.io/mcp.github.io/), and for *AccessRefinery* in `docs/accessrefinery-javadoc/`, available on [GitHub Pages](https://916267142.github.io/accessrefinery.github.io/).

## License

Apache-2.0 License, see [LICENSE](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/LICENSE).

## Contact

Feel free to contact us if you have any questions.

- Ning Kang (<kangning2018@foxmail.com>)
- Jianyuan Zhang (<jyzhang0281@foxmail.com>)
</content>
