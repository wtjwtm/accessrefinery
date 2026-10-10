# AccessAnalyzer: Stratified Intent Mining Tool
A reimplemented version of AWS AccessAnalyzer for automatically discovering and organizing stratified intent structures from IAM policies.

## Setup

### Prerequisites
- Ubuntu 22.04
- Java JDK >= 17
- Maven 3.6.3
- jq 1.6
- bc 1.07.1
- Z3 4.14.1
- CVC5 1.2.1

### Install Z3 and add to PATH
```bash
$ cd baselines/accessanalyzer-reimpl
$ echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'$(pwd)'/lib/z3-4.14.1/bin' >> ~/.bashrc
$ source ~/.bashrc
```

### Build the project

Run from the repository root, where the assembled jar is written to `target/accessanalyzer-1.0.jar`; on Linux the root POM's `accessanalyzer-baseline` profile adds this module to the build automatically.

```bash
$ mvn clean package
```

## Run

Also run from the repository root.

```bash
$ java -jar target/accessanalyzer-1.0.jar <options>
```

### Command-line options:
- `-r, --reduce`: Reduce the number of intents.
- `-s, --solver <Z3/CVC5>`: Select the solver to use (Z3 or CVC5), default is Z3.
- `-f, --file <DATA_PATH>`: Path to the input policy (a single JSON file).
- `-c, --cover <policy_file> <findings_file>`: Check whether the findings cover the policy.
- `-h, --help`: Show help message and exit.

Example:
```bash
$ java -jar target/accessanalyzer-1.0.jar -r -s Z3 -f data/Correctness/11_allow_allow_equal.json
``` 

Then the result will be output to the `result/` folder.

For the file `<file_name>.json` of the dataset `<dataset>`, the tool will output a folder named `result/<dataset>/<file_name>.json/`, containing the following files:
- `<file_name>_<solver>_findings.json`: The mined intents in JSON format.
- `<file_name>_<solver>_time.csv`: The time spent in mining the intents.

## Project Structure
```bash
baselines/accessanalyzer-reimpl
|
|----lib                      # third-party libraries (Z3 4.14.1, CVC5 1.2.1)
|----src
|       |---main/java/org/aws # mining tool source code
|       |---assembly          # Maven assembly configuration
|       |---test              # tests
|----pom.xml                  # Maven module configuration
```

The datasets live in `data/` at the repository root, and the scripts that run this tool in `tools/accessanalyzer-reimpl/`.

## Reproduction
All experimental results are archived in `archive_results/` at the repository root.

### Result of AccessAnalyzer

- `accessanalyzer_z3_miner_1rs`: Results of intent mining using Z3
- `accessanalyzer_z3_reducer_1rs`: Results of intent mining and reduction using Z3
- `accessanalyzer_cvc5_miner_1rs`: Results of intent mining using CVC5
- `accessanalyzer_cvc5_reducer_1rs`: Results of intent mining and reduction using CVC5

Scripts are provided to generate these results.

#### Generate preliminary results

**Note**: Each script processes the datasets `data/Correctness`, `data/Scalability_05Keys` and `data/Scalability_06Keys`. A 1-hour timeout is set per policy file.

```bash
$ bash tools/accessanalyzer-reimpl/mining_miner_z3.sh
$ bash tools/accessanalyzer-reimpl/mining_reducer_z3.sh
$ bash tools/accessanalyzer-reimpl/mining_miner_cvc5.sh
$ bash tools/accessanalyzer-reimpl/mining_reducer_cvc5.sh
```
The four scripts above will take 10 to 20 hours to run. Alternatively, the result can be acquired from the archived data using the following command.

```bash
$ for d in accessanalyzer_z3_miner_1rs accessanalyzer_z3_reducer_1rs \
           accessanalyzer_cvc5_miner_1rs accessanalyzer_cvc5_reducer_1rs; do
      cp -r "archive_results/$d" results/
  done
```

#### Organize and categorize the results

Each mining script already does this at the end of its run: it flattens every per-policy output folder into `<file_name>_result.json` and `<file_name>_time.csv`, and writes one `summary.csv` per dataset. That step needs `jq` and `bc`.

### Results of AccessRefinery

- `accessrefinery_bdd_miner_10rs`: Results of intent mining for 10 rounds using JavaBDD backend
- `accessrefinery_bdd_reducer_10rs`: Results of intent mining and reduction for 10 rounds using JavaBDD

These results are archived alongside the AccessAnalyzer ones, in `archive_results/` at the repository root.

### Results of Comparing AccessRefinery with AWS AccessAnalyzer

- `results/accessrefinery_miner_compare_results`: Results of comparison

The following instructions can be used to reproduce the results:

```bash
$ bash tools/running_batch_compare.sh
```

---

Thank you for reading AccessAnalyzer! 
