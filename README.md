# AccessRefinery: Fast Mining Concise Access Control Intents on Public Cloud

by [Ning Kang](https://xjtu-netverify.github.io/people/nkang/), [Peng Zhang](https://xjtu-netverify.github.io/people/pzhang/), [Yijia Wang](), [Jianyuan Zhang](https://xjtu-netverify.github.io/people/jyzhang/), Hao Li, Dan Wang, Zhenrong Gu, Weibo Lin, Shibiao Jiang, Zhu He, Xu Du, Longfei Chen, Jun Li and Xiaohong Guan.

![Java](https://img.shields.io/badge/Java-17-007396?logo=java&logoColor=white) ![Tests](https://img.shields.io/badge/tests-passing-brightgreen?logo=java) ![Paper](https://img.shields.io/badge/paper-TOSEM2026-orange) ![License](https://img.shields.io/badge/license-Apache--2.0-green)

## About AccessRefinery

### Conference Version

*AccessRefinery* automatically mines access control intents from IAM (Identity and Access Management) policies. Compared with [AWS Access Analyzer](https://link.springer.com/content/pdf/10.1007/978-3-030-53288-8_9.pdf), *AccessRefinery* accelerates mining by about 10-100x and reduces the number of intents by up to 10x.

- To accelerate intent mining, *AccessRefinery* uses our Multi-Theory Constraint Preprocessor (*MCP*) to speed up multi-round SMT solving by preprocessing constraints into bit-vector form. We also designed *MCP* as a reusable data structure that may benefit other studies.
- For intent reduction, *AccessRefinery* computes a compact set that covers all mined intents by solving a minimum set-cover problem.

Moreover, the artifact includes the full implementations of *AccessRefinery* and the baseline reimplementation of *Access Analyzer*, along with datasets, archived results, experiment scripts, and plotting scripts to reproduce the results reported in the paper. For technical details, see our [FSE 2026 paper](https://xjtu-netverify.github.io/papers/AccessRefinery/accessrefinery_final_version.pdf).

> The [source code](https://github.com/XJTU-NetVerify/accessrefinery) for the conference version has received the **Available** and **Reusable** badges.

### Journal Version

We observe that EC partitioning dominates the overall time for both intent mining and intent reduction, accounting for 71-98% and 16-93% of the total time, respectively.
We further extend our previous work published at FSE 2026 by accelerating EC partitioning for both intent mining and intent reduction. The proposed optimizations provide an additional about 10× speedup for *AccessRefinery*.

- For intent mining, we propose *Incremental MCP*, which extends MCP to support incremental preprocessing, enabling EC partitions to be efficiently updated as new variables or values are added.

- For intent reduction, we propose *Intent Pruning* to identify necessary intents and reduce the number of intents participating in EC partitioning.

> In this README and the source code, journal extensions are marked with **`[Journal Extension]`** and `//ADD_BEGIN_JOURNAL` / `//ADD_END_JOURNAL`, respectively.

## Installing AccessRefinery

see [REQUIREMENTS.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/REQUIREMENTS.md)  and [INSTALL.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/INSTALL.md) for details.

## Project Structure

Since *AWS Access Analyzer* is not open source and provides only a Command-Line Interface (CLI), we also reimplement *Access Analyzer* for evaluation.

- `data/`: Dataset for experiments.
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
- `paper_figures_journal/`: Scripts for plotting the figures in the paper.
- **`[Journal Extension]`** `archive_results_journal/`:  Archived experimental result of journal version.


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
# The execution takes about 3 minutes.
mvn install
mvn test -pl ./accessrefinery/mcp -Dtest=MCPFactoryTest.java#testMCPFactory
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
- **`[Journal Extension]`** `-p, --pruning` : Enable *Intent Pruning*.
- **`[Journal Extension]`** `-o, --mining-optimized` : Enable the intent-mining optimization alone.
- **`[Journal Extension]`** `-i, --increment` : Enable *Incremental MCP*.

**Example:**

```shell
java -jar target/accessrefinery-1.0.jar -m -r --round 1 -f data/Correctness
```

Expected output:

```text
[INFO] 2026-04-05 22:51:33 : ----------[ AccessRefinery Mode ]-------------
[INFO] 2026-04-05 22:51:33 : input  path: data/Correctness
[INFO] 2026-04-05 22:51:33 : output path: result/Correctness
[INFO] 2026-04-05 22:51:33 : ----------< 1th policy - 11_allow_allow_equal.json >-----------
[INFO] 2026-04-05 22:51:33 : [1/6]  finish parser policy
[INFO] 2026-04-05 22:51:33 : [2/6]  finish ECs calculation
```

Results are generated in the `result/Correctness/` directory and include:

- `xxx.json`: The intents for each policy.
- `xxx.csv`: Statistics for multi-round SMT solving for each policy.
- `summary.txt`: Summary statistics for all policies in a folder.

In addition, one file is generated in the current path:

- `accessrefinery.log` : Records the running log.

## Running Experiments

This section describes (1) how to reproduce the results in `results/`, and (2) how to reproduce the corresponding figures, tables, and conclusions in the paper from `results/`.

*We omit the results for the real-world datasets because of commercial restrictions.*

**`[Journal Extension]`** Here, we present only the experiments about the journal version: the redraws of the scalability figures (RQ3 and RQ4, Figures 14-16) together with the three-stage optimization pipeline **Original → Pruning Reducer → Incremental MCP** (RQ7 and RQ8, Figures 18-20). For the experiments about the conference version, see [README-FSE26.md](README-FSE26.md).

`archive_results_journal/` holds the immutable results shipped with this artifact, and `results/` is the working directory that the experiment scripts write to and that the extraction scripts read from. Every experiment below can therefore either be run or skipped by copying the corresponding archive folder into `results/`.

### Reproducing Results

First, we need to copy the archived results of Access Analyzer and AccessRefinery without optimizations. For instructions on how to obtain these results, see README-FSE26.

```shell
mkdir -p results/ 
# copy results if Access Analzyer with CVC5 and Z3 backend
cp -r archive_results/accessanalyzer_*rs results/
# copy results of AccessRefinery with the MiniSAT backend
cp -r archive_results/accessrefinery_sat_*rs results/
# copy results of AccessRefinery with the BDD backend
cp -r archive_results/accessrefinery_bdd_*rs results/
```

You can skip running AccessRefinery with Incremental MCP and Intent Pruning by running the following commands to directly reuse the data in the archive_results_journal/ directory.

```shell
cp -r archive_results_journal/accessrefinery_bdd_reducer_*rs results/
```

The optimization pipeline is run by one script, which invokes `target/accessrefinery-1.0.jar` once per stage, with the stage selected on the command line — no stage flag is *Original*, `-p` is *Pruning Reducer*, `-o` is *MiningOptimized* and `-p -i` is *Incremental MCP* (see [Using AccessRefinery](#using-accessrefinery)). It takes the two 20-round runs that Figure 18 reads and the four 10-round runs that Figures 19 and 20 read:

```shell
# The execution takes about 110 minutes.
bash tools/accessrefinery/running_optimization_pipeline.sh
```

*Note: `Ctrl + C` or `Ctrl + Z` end the scripts.*

Expected Output:

- `results/`: one folder per stage and per round count, each holding the same two datasets, `Scalability_05Keys` and `Scalability_06Keys`, with one `summary.txt` per dataset, reporting the average over the run's rounds. The real-world `RW` folder the script also reads is not shipped, for the reason above.
  - `accessrefinery_bdd_reducer_Original_{10,20}rs/`: the pipeline with no optimization.
  - `accessrefinery_bdd_reducer_PruningReducer_{10,20}rs/`: *Original* + *Intent Pruning*, the essential-finding pre-filter in the intent reducer.
  - `accessrefinery_bdd_reducer_IncrementalMCP_10rs/`: *Pruning Reducer* + *Incremental MCP*, the miner's refinement-DAG node construction and the incremental EC engine below it.
  - `accessrefinery_bdd_reducer_MiningOptimized_10rs/`: the mining-phase search optimization alone, without the essential-finding pre-filter and without the incremental EC engine. It is not one of the three stages — on the command line it is `-o` on its own — and it is the configuration Figure 20 reads.

### Reproducing Claims in the Paper

After generating `results/`, we show how to reproduce the claims in the paper with scripts. The claims covered here are the scalability of intent mining and reduction (RQ3, RQ4) and the three-stage optimization pipeline (RQ7, RQ8), i.e. Figures 14, 15, 16, 18, 19 and 20. [REPRODUCTION.md](REPRODUCTION.md) documents, claim by claim, the exact data each figure reads and the script that extracts it.

The real-world `RW` corpus is not public, for commercial reasons, so the pipeline cannot be re-run over it. Its plotting data ships with the artifact, and the extraction script below skips it, leaving the archived files in place.

The plotting data of these figures is extracted from `results/` by one script. It **overwrites** the files it writes into `paper_figures_journal/data/`: the six figure files of Figures 18, 19 and 20 whole, and Figures 14 and 15 in place. Running it therefore replaces the shipped copies with numbers from your own run.

Before plotting, we recommend clearing previously rendered PDFs so that every figure below is regenerated rather than reused:

```shell
sh tools/clean_plotting.sh
```

Then extract the plotting data:

```shell
bash tools/figures/extract_optimization_pipeline.sh
```

The parts of `data/` it leaves alone are the ones that cannot be regenerated: the real-world panels `rw_p1.dat` and `rw_p2.dat` and the `Experiment-*-RealWorld.dat` files, whose corpus is withheld, and the `Experiment-Effectiveness-*` files, which belong to the conference-version archive.

To draw the whole set in one go, from the repository root:

```shell
bash paper_figures_journal/draw.sh
```

The six figures are drawn one at a time below.

#### Plotting Figure 14 (Section 7.3)

```shell
(cd paper_figures_journal && gnuplot gnuplot/RQ3-Experiment-Scalability-Mining.plt)
```

Expected Output:

- `paper_figures_journal/results/RQ3-Experiment-Scalability-Mining.pdf`

#### Plotting Figure 15 (Section 7.3)

```shell
(cd paper_figures_journal && gnuplot gnuplot/RQ3-Experiment-Scalability-Reducing.plt)
```

Expected Output:

- `paper_figures_journal/results/RQ3-Experiment-Scalability-Reducing.pdf`

#### Plotting Figure 16 (Section 7.4)

```shell
(cd paper_figures_journal && gnuplot gnuplot/RQ4-Experiment-Scalabiliy-RealWorld.plt)
```

Expected Output:

- `paper_figures_journal/results/RQ4-Experiment-Scalabiliy-RealWorld.pdf`

#### Plotting Figure 18 (Section 7.7)

```shell
(cd paper_figures_journal && gnuplot gnuplot/RQ7-ReducingPruning-Original-PruningReducer.plt)
```

Expected Output:

- `paper_figures_journal/results/RQ7-ReducingPruning-Original-PruningReducer.pdf`

#### Plotting Figure 19 (Section 7.7)

```shell
(cd paper_figures_journal && gnuplot gnuplot/RQ7-MiningPruning-PruningReducer-IncrementalMCP.plt)
```

Expected Output:

- `paper_figures_journal/results/RQ7-MiningPruning-PruningReducer-IncrementalMCP.pdf`

#### Plotting Figure 20 (Section 7.8)

```shell
(cd paper_figures_journal && gnuplot gnuplot/RQ8-Optimization-Overview-Bars-Percentage.plt)
```

Expected Output:

- `paper_figures_journal/results/RQ8-Optimization-Overview-Bars-Percentage.pdf`

Figures 18 and 19 each carry a real-world `RW` panel besides their two synthetic ones; as the note above says, the archived plotting data of those panels cannot be regenerated.

## For Developers

- We develop *AccessRefinery* in VS Code, see [VSCODE.md](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/docs/vscode-develop/VSCODE.md).

- We provide Javadoc documentation for *MCP* in `docs/mcp-javadoc/`, available on [GitHub Pages](https://916267142.github.io/mcp.github.io/), and for *AccessRefinery* in `docs/accessrefinery-javadoc/`, available on [GitHub Pages](https://916267142.github.io/accessrefinery.github.io/).

> Note: The comments and Javadoc were generated by GitHub Copilot; the source code was not AI-generated.

## License

Apache-2.0 License, see [LICENSE](https://github.com/XJTU-NetVerify/accessrefinery/blob/main/LICENSE).

## Contact

Feel free to contact us if you have any questions.


- Ning Kang (<kangning2018@foxmail.com>)
- Yijia Wang (<wyjia0610@foxmail.com>)
- Jianyuan Zhang (<jyzhang0281@foxmail.com>)