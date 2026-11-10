# Result: developer — 94
Status: done
Abnormality: none
Progress:
  Done: security finding fixed (relative file operand to awk now gets ./ so a name=value file is read as a file)
  Next: none
Summary: a3-check.sh passes ./$1 for a relative operand (absolute and - unchanged); exit codes and output lines unchanged.
  Same awk operand pattern fixed in post-text.sh (draft and in operands of render, elide, split) and board.sh (table_get operand, factory_md and tracker_md operands, via a dotslash helper).
  Other awk calls take no file operand from the caller (cut-offs.sh comment only, token-spend.sh pipes stdin).
  tests/factory/test_a3_check.sh: fail=0 (299 passed). tests/run.sh: ALL PASSED. A name=value file given to a3-check.sh is read as a file (exit 3, normal skip).
  New fingerprints (plugins/factory, release 2.3.0): standard 99f1c24c685fc0cfd5fb9b9134596ed2b031bfe2b4f7b40844beb9d389be1930, tooling 3ed5f8f0181bb0207d92ad24f3fbe1dd3556e49edadd7a3d390fef09ae1e6656
Artifacts: plugins/factory/scripts/a3-check.sh, plugins/factory/scripts/post-text.sh, plugins/factory/scripts/board.sh
Decisions: fixed the other scripts with the same pattern too (cost to undo: revert two small hunks) / rejected rejecting operands containing = (would change contract behaviour)
Open questions: none
