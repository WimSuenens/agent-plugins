# Result: developer — 39
Status: done
Progress:
  Done: hansei.md v2, run/SKILL.md, token-spend.sh --require-end (see commit below)
  Next: none
Summary:
  hansei.md: marker v2, measure 1 with six parts, four wait kinds with detection rules, Agent column in Waits, Done-then-stopped, FPY by severity, truncated spend with --require-end and exit 6, close step 6 in two commits, worked examples copied from the contracts.
  run/SKILL.md: Interruptions (kinds, Agent column, done-then-stopped), step 8.6 close order. Kept the old sentences "The last commit on item/<id> removes work/<id>/" and "The record is posted before this commit." so ac18 tests still pass.
  token-spend.sh: --require-end and `--`, exit 6; checked by hand against ok/cut/handback/interrupted fixtures.
  bash tests/run.sh: only v1-era assertions fail (QA to update): test_standard_text.sh ac11-waits-kinds, ac11-limits-wait, ac11-interruption-limits-wait, ac14-marker-first-line, ac14-example-marker, ac15-m1-split, example-lead-time. No test covers --require-end yet (QA). check-bump passes (minor, 0.0.0 -> 1.0.0).
Artifacts: plugins/factory/references/hansei.md, plugins/factory/skills/run/SKILL.md, plugins/factory/scripts/token-spend.sh
Decisions: none
Open questions: none
