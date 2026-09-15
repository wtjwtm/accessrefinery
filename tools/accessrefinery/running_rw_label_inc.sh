#!/bin/bash

# Incremental add-label measurement on the real-world RW corpus.
#
# For each of the 506 RW policies, this reports the cost of the ONE
# computeLabels() call that absorbs the synthesized label `s3:::886499mir`, on
# top of data that has already been processed. See `REPRODUCTION.md` claim 14.
#
# Two phases per policy, on one fresh factory (-Dinc.independent=true):
#
#   1. prime   - build the policy from its label-free form, taken from
#                results/RW_label_free/ (generated below). This fills the factory
#                with the processed data. Untimed.
#   2. measure - build the labeled policy. Exactly one computeLabels() call then
#                finds a label it has not processed; that call — and nothing else
#                in the pipeline — is what the MCILabelsTimeAverage column reports.
#
# The two phases run on the same MCPFactory, so "the original data has already
# been processed" holds. The metric is off by default (-Dmcp.labelinc=true turns
# it on), so a plain run of running_bdd_reducer_20rs.sh is unaffected.
#
# The -D flags must precede -jar.

set -e

# 1. Priming input: the RW corpus with the synthesized label removed.
python3 tools/accessrefinery/make_label_free_rw.py data/RW results/RW_label_free

# 2. Measure. Output goes to result/RW/ (input data/RW/ -> result/RW/), which is
#    the layout of the RW folder inside each archive_results stage directory.
java -Dinc.independent=true \
     -Dmcp.labelinc=true \
     -Dmcp.labelinc.prime=results/RW_label_free \
     -jar target/accessrefinery-1.0.jar -m -r --round 20 -f data/RW/

echo
echo "incremental add-label results: result/RW/summary.txt (MCILabelsTimeAverage column)"
