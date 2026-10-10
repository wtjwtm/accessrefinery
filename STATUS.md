
# Status

We are claiming 3 badges (Functional, Reusable, and Available) as follows:

## Evaluated - Functional

We believe this artifact satisfies the Functional criteria based on the following evidence:

- **Documented:** The artifact is well-documented and includes:
  - System requirements
  - Installation instructions
  - Project structure overview
  - Usage examples
  - Reproduction scripts and step-by-step instructions
  - API documentation generated via Javadoc
  - Developer instructions (develop AccessRefinery in VS Code)

- **Exercisable:** The system can be built and executed from source using standard Maven workflows with JDK 17.

- **Complete:** The artifact includes all necessary components to reproduce the extension experiment reported in the paper (RQ7-RQ8, the three-stage optimization pipeline):
  - Source code of *AccessRefinery*, including the three-stage optimization pipeline
  - Three synthetic scalability datasets — `Scalability_05Keys/`, `Scalability_06Keys/` and `Scalability_05Keys∗/`, the paper's `5-Key`, `6-Key` and `5-Key*` — plus the `Correctness/` set used to check that the mined intents cover the policies
  - The real-world corpus (`RW/`, 506 policies) is **not public**, for commercial reasons: the raw real-world policies are not publicly available due to commercial restrictions
  - Archived results, extraction scripts, plotting scripts and rendered figures for the pipeline (Figures 18-21)

  The experiments of the original submission (RQ1-RQ6 and the two claims of the paper's setup section) are not part of this repository: the reimplemented *Access Analyzer* baseline, the scripts for invoking *AWS Access Analyzer* via CLI, and the archived results and plotting material of those experiments are not shipped.

- **Consistent with the paper:** The artifact includes archived experimental results and provides instructions to reproduce the claims of the extension experiment (RQ7-RQ8) reported in the paper. The real-world `RW` corpus is not public, for commercial reasons, so the claims whose evidence rests on it — among them RQ8's add-label claim — are not reproduced here.

## Evaluated - Reusable

We believe this artifact satisfies the Reusable criteria for the following reasons:

- **Modular and extensible design:**
  AccessRefinery is designed with clear modular boundaries. In particular, it separates the low-level data structure (*MCP*) from the higher-level analysis tool. This separation enables users to reuse or extend individual components independently.

- **Reusable library (MCP):**
*MCP* is implemented as a standalone Java library. Running `mvn package` generates a reusable JAR file (`mcp-1.0.jar`) that can be directly integrated into other projects.
  - It provides a concise and expressive API (e.g., `policy.not().and(intent1.or(intent2))`).
  - It supports multiple variable types (e.g., regex, prefix, range, and set) through a unified abstraction, making it straightforward to extend to new types.

- **Reusable tool (AccessRefinery):**
  AccessRefinery provides a command-line interface with flexible options for different analysis tasks.
  - Users can easily run experiments or adapt workflows via configurable parameters.
  - The tool supports interchangeable backends (using BDD or SAT solver to represent bitvector constraints), enabling support for additional backends.

- **Ease of extension:**
  The system is designed to facilitate incremental extensions. For example, adding support for new policy languages only requires extending specific components without modifying the entire system.

- **Documentation and examples:**
  The artifact includes API documentation (via Javadoc) and usage examples.

## Available

We believe this artifact satisfies the Available criteria because it is publicly available on GitHub.
