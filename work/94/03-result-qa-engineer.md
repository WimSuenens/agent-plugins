# Result: qa-engineer — 94
Status: done
Abnormality: none
Progress:
  Done: tests stage complete. Commits `#94 qa-engineer: ...` on item/94: version pins to 2.3.0; A3 template and example pins to v2/v1 and settle-line pin; test_a3_check.sh with fixtures; lean_replay.py with fixtures; test_lean_rules.sh; layout pins that allow the two derived sub-lines.
  Next: nothing in this task. Verification (reviews/qa-94.md) runs after the build.
Summary: Tests stage done; nothing under plugins/ touched.
  Added test_a3_check.sh (299 checks, fixtures/a3/), test_lean_rules.sh with lean_replay.py and fixtures (percent, per-stage, waste, target), and moved the existing pins to 2.3.0 behaviour.
  Control check: a throwaway reference script and minimal text edits in a scratch copy (not committed) turn the suite green except one pin the scratch text lacked, so today's reds are the missing build.
  Targeted test: `bash tests/factory/test_a3_check.sh`; fails now with `FAIL a3check-script-exists` and exit 127 (plugins/factory/scripts/a3-check.sh missing).
  Suite: `bash tests/run.sh` prints FAILURES (was ALL PASSED before); 9 files red until the build and the 2.3.0 bump.
  Changelog, runbook and README/reference.md checks are named skips until the docs-writer; required in the verification pass.
  Path check against the item list: no off-list line. Details, the 19-criterion map and four contract findings are below the fields.
Artifacts: tests/factory/test_a3_check.sh, tests/factory/test_lean_rules.sh, tests/factory/lean_replay.py, tests/factory/fixtures/a3/
Decisions: pins on exact text are limited to formats (markers, line keys, check output lines, sub-line templates, percent and minute worked examples, andon last line, skip line, settle bullet) / rejected: broad prose assertions on the walk and tagging instructions, which are a scenario read / cost to undo: edit the pins. Changelog and docs checks are named skips until the docs-writer lands them / rejected: red until then / cost: the verification pass must turn them into passes.
Open questions: none
Missing: none

## Details

Targeted test: `bash tests/factory/test_a3_check.sh` from the item worktree root. Expected failure now: `FAIL a3check-script-exists` (want 1, got 0) and every check that runs the script, exit 127 (`plugins/factory/scripts/a3-check.sh` does not exist). It must end `fail=0` once the script and the a3.md examples exist. Its three `standard-example-*` checks also need the new a3.md (section 3: v2 block first, then the v1 block).
Red now, green at the developer's Done: test_a3_check.sh, test_lean_rules.sh, and in test_baseline_a3.sh (ac16-*, ac12-skill-experiment-keys, ac23-experiment-line, ac12-settle-*), test_baseline_replay.sh (v5-a3-md-gemba-targeted-line-is-presence-checked), test_andon_text.sh (ac26-one-line-experiment, ac29 version), test_gemba.sh (t13 version), test_standard_text.sh (ac1 version), test_ownership_tdd.sh (rel version), test_fingerprint.sh (release lines). These need the plugin edits and the `plugin.json` bump; no test needs a docs file.
Stay skipped until the docs-writer (named skips, required in the verification pass): CHANGELOG `## factory 2.3.0 (#94)` entry with the four changes and the two fingerprints (ac19-changelog-*), release-runbook 2.3.0 note, README/reference.md saying v2 (ac17-docs-say-v2).
Current state: `bash tests/run.sh` prints FAILURES (red: 9 files, all for the reasons above); before my changes it printed ALL PASSED. Path check against the item list: no off-list line.
Criteria map (19):
  AC-1 test_a3_check.sh `ac1-*` (three missing, blank, out of order, repeated, each naming its key).
  AC-2 test_a3_check.sh `ac2-*` (bare none, none (), reason not in table, allowed reasons) plus test_baseline_a3.sh `ac16-v2-reason-*`.
  AC-3 test_lean_rules.sh `ac3-*` (replay on fixtures waste/c1..c6: counts, tie order, untagged, bad tag named, problem rule reads no tag).
  AC-4 test_lean_rules.sh `ac4-*` (2.2.0 ledger unchanged; andon last line, Findings sixth column, kind 2 row).
  AC-5 test_lean_rules.sh `ac5-*` (eight names, "Tag it when" column in `### Tagging waste`).
  AC-6 test_lean_rules.sh `ac6-*`, `ac7-item*-flow-efficiency` (13%, 58%, 75%, half up, total 0 never 0%).
  AC-7 test_lean_rules.sh `ac7-*` (three worked examples, both sums, 352m on Merge approval only, worked-example lines in hansei.md).
  AC-8 test_lean_rules.sh `ac8-*` (v5 marker, header keys, sub-lines under measure 1 only, baseline replay equal with and without sub-lines on x5v3/x5v4/x5v5), test_gemba.sh `t6-*` (layout equals main but for the two sub-lines).
  AC-9 test_lean_rules.sh `ac9-*` (measure 1 line and seven measures unchanged).
  AC-10 test_lean_rules.sh `ac10-*`, test_baseline_a3.sh `ac12-skill-experiment-keys`.
  AC-11 test_lean_rules.sh `ac11-*` (four contract cases, inclusive, not captured, not comparable), a3.md example `- target: 0 — reached`.
  AC-12 test_baseline_a3.sh `ac23-experiment-line`, `ac12-settle-*`; test_andon_text.sh `ac26-one-line-experiment`; test_lean_rules.sh `ac12-step-9-3-shows-target`.
  AC-13 test_lean_rules.sh `ac13-*` (text pins) + QA scenario pass (human review of the walk instructions, reviews/qa-94.md).
  AC-14 test_a3_check.sh `ac14-*` (cite line, no-walk line, never found-nothing/0), test_lean_rules.sh `ac14-*`; QA scenario pass for the chain.
  AC-15 test_a3_check.sh `ac15-*`, `v1-example-ok`, `standard-example-v1-passes`; existing baseline replay.
  AC-16 test_a3_check.sh `ac16-*`, `marker-v*` (v1 with three lines: not part of v1 x3; v2 without: missing x3; v3/v0/v01 skipped, exit 3).
  AC-17 test_lean_rules.sh `ac17-*`, test_baseline_a3.sh `ac16-v1-*`; QA scenario pass for an interrupted close with a v1 found.
  AC-18 `bash tests/run.sh` prints ALL PASSED (verification).
  AC-19 plugin.json pins in 5 files, test_lean_rules.sh `ac19-*` (changelog, fingerprints equal `fingerprint.sh`, skipped until docs); check-bump from 2.2.0 and fingerprint release line in the verification pass.
  Human-only: none by the requirement; AC-13, AC-14 and AC-17 (instruction-following) get a scenario read in the verification.
Findings for the architect (contract text, not defects in the build; none blocks):
  1. 94-a3-v2 section 10 says `a3-check.sh` exits 0 `ok v1` on `tests/factory/fixtures/baseline/records/a3-3.md`. That file is a four-line stub (marker, run, answer) that v1 correctly refuses (`missing`). The test uses the full 2.2.0 example (`fixtures/a3/v1-ok.md`) and the v1 block of a3.md; a3-3.md stays a baseline fixture. Low.
  2. The existing pin `v5-no-script-or-hook-mentions-gemba` would fail on `a3-check.sh` (it names `gemba (targeted)`). I relaxed it to exempt that one script. Not listed in the contract's pins. Low.
  3. Contract section 7 leaves the "any other override" settle bullet unchanged; the brief listed `ac23-other-line` and `ac26-one-line-other`. I left both pins as they are.
  4. `test_gemba.sh` `t6-*` and `test_standard_text.sh` `ac14-example-matches-template` also pinned the record layout; both changed to allow the two sub-lines (not in the contract's list).
