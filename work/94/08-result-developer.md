# Result: developer — 94
Status: done
Abnormality: none
Progress:
  Done: post-text.sh and board.sh restored to origin/main content; a3-check.sh fix kept
  Next: none
Summary: plugins/factory/scripts/post-text.sh and board.sh are byte-identical to origin/main; the diff against origin/main names neither.
  a3-check.sh keeps the ./ guard for a relative file operand. Nothing else changed.
  tests/factory/test_a3_check.sh: fail=0 (299 passed). tests/run.sh: ALL PASSED.
  New fingerprints (plugins/factory, release 2.3.0): standard 99f1c24c685fc0cfd5fb9b9134596ed2b031bfe2b4f7b40844beb9d389be1930 (unchanged), tooling d1147172c1056068edc50a8a7b44bc45d16215e98229d585c83309aba48ac070
Artifacts: plugins/factory/scripts/a3-check.sh
Decisions: none
Open questions: The same pattern exists in plugins/factory/scripts/post-text.sh (draft and the in operands of render, elide, split: a relative file operand named like name=value is taken by awk as an assignment) and plugins/factory/scripts/board.sh (table_get operand, factory_md and tracker_md operands). Fixed in rework 1 and reverted here as out of scope; the lead can file it as a follow-up issue.
