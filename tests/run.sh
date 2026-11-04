#!/bin/bash
# Runs every test file under tests/. Exit 0 when none fails; skips name a QA finding or a missing optional input.
# Usage: bash tests/run.sh     (bash 3.2 or later; needs git, jq, and sha256sum or shasum)
# FACTORY_ROOT=<plugin root> tests another copy of the factory plugin.
dir="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$dir"/factory/test_*.sh; do
  echo "== ${t#$dir/}"
  bash "$t" || rc=1
done
[ $rc = 0 ] && echo "ALL PASSED" || echo "FAILURES"
exit $rc
