#!/usr/bin/env python3
"""Write a label-free copy of the RW corpus.

The RW corpus shipped in `data/RW/` is the labeled version: the synthesized
resource value `s3:::886499mir` is added to the `Resource` list of every
statement. This script writes the same 506 policies with that one value removed,
which is the priming input of the incremental add-label measurement
(`tools/accessrefinery/running_rw_label_inc.sh`): the label-free policy is built
first, so the factory already holds the processed data by the time the labeled
policy is built and the new label is added on top of it.

Usage: make_label_free_rw.py <src-dir> <dst-dir>
"""

import json
import os
import sys
import glob

LABEL = "s3:::886499mir"


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__.strip())
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)

    files = sorted(
        p for p in glob.glob(os.path.join(src, "*.json"))
        if not os.path.basename(p).endswith("_result.json")
    )
    if not files:
        sys.exit("no policy JSON files found in " + src)

    policies = statements = removed = 0
    for path in files:
        with open(path, encoding="utf-8-sig") as f:
            policy = json.load(f)
        for statement in policy.get("Statement", []):
            for key, value in list(statement.items()):
                if isinstance(value, list) and LABEL in value:
                    statement[key] = [x for x in value if x != LABEL]
                    removed += 1
            statements += 1
        with open(os.path.join(dst, os.path.basename(path)), "w", encoding="utf-8") as f:
            json.dump(policy, f, indent=2)
        policies += 1

    print("label-free corpus: %d policies, %d statements, %d %s value(s) removed -> %s"
          % (policies, statements, removed, LABEL, dst))


if __name__ == "__main__":
    main()
