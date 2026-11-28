# Result: developer — 286
Status: done
Abnormality: 1 — the release contract's pin table (286-release section 3) names no move for test_run_split.sh a1, a2 and a2b, which the contract-required lines in the router and run-close-run.md fail (architect, contract; QA, fixture) — tests/factory/test_run_split.sh:46
Progress:
  Done: brief checked (WimSuenens, marker developer 1); targeted tests red first; run-state.sh (44aa253); run-timing.sh (8df3bba); a3-check.sh v4 (fc67eda, 6acd22e); a3.md (bdbae48 and earlier); baseline.md (8e2c0c6); standard text (a9ea8a5, 775b879); version 3.10.0 (14cf3ff); role knowledge (0424f61)
  Next: none (QA moves the test_run_split fixture, question 10; the docs-writer writes CHANGELOG, README, reference.md)
Summary:
- run-state.sh: `start` prints `lead sessions: none yet` and the empty Run waits table; new `add-session`, `add-run-wait`, field `lead-sessions`.
- New run-timing.sh: `gaps` (the run-close scan, clipped to the run and outside the item windows) and `line` (the minute grid, not captured, --lite); bash 3.2, awk only, no clock.
- a3-check.sh knows v4: the four lines, their grammars and arithmetic, the two order tracks; v1 to v3 unchanged; v5 skipped.
- Text: a3.md section 2.3 plus version lines; baseline.md section 9 (Runs) plus the section 1, 6, 7 and 8.1 edits; hansei.md section 8; step 9.0 and 9.2; router Session line, step 0, 2, 4; Run identity; Escalation. plugin.json 3.10.0, check-bump pass.
- Targeted tests: all five exit 0. `bash tests/run.sh`: FAILURES, only in QA's or the docs-writer's checks:
  - test_run_split a1, a2, a2b: new lines need QA's allow-file (question 10).
  - test_lean_rules ac17-docs-say-v4-README and -reference (expected-red, per the lead), and ac19 changelog fingerprints 1 and 2: the docs-writer's.
- The router is 66,948 bytes (cap 70,000). Whether `${CLAUDE_SESSION_ID}` is substituted is unverified until the runtime proof; the fallback is written in step 0.
Artifacts: plugins/factory/scripts/run-state.sh, plugins/factory/scripts/run-timing.sh (new), plugins/factory/scripts/a3-check.sh, plugins/factory/references/a3.md, plugins/factory/references/baseline.md, plugins/factory/references/hansei.md, plugins/factory/references/run-close-run.md, plugins/factory/references/run-overrides.md, plugins/factory/references/run-route.md, plugins/factory/skills/run/SKILL.md, plugins/factory/.claude-plugin/plugin.json, docs/agents/roles/developer.md, work/286/10-question-developer.md
How to run: `for t in run_timing_286 run_state_286 a3_v4_286 baseline_runs_286 run_text_286; do bash tests/factory/test_$t.sh; done`; `bash tests/run.sh`; `bash scripts/check-bump.sh origin/main`.
Decisions:
- run-timing.sh order of exits: no `started:` (5) first, then the usage exits (close before started, a ledger not of the run, a cut-offs line out of format: 2), then the other not-captured reasons in the contract's order / rejected: all usage exits first (a section without `started:` cannot check close against start) / cost to undo: a few lines in END.
- `gaps` runs the same not-captured checks as `line` (exit 5) / rejected: only the started check / cost to undo: one line.
- A cut-offs line that leaves no minute is `outside the run` when its clip to the run window is empty, else `inside items` (a sub-minute gap inside the run reads `outside the run`) / rejected: a third stderr form / cost to undo: one branch.
- Two ledgers of the same item exit 2; a ledger file without `## Ledger: #<n>` exits 2 / rejected: last one wins / cost to undo: two lines.
- add-run-wait reads `--what` through the environment (no backslash escapes) / rejected: `awk -v` / cost to undo: one line.
- add-session's exit 3 (neither FREEZE nor started) is checked on every call, also when the line is already there, as the contract lists it / rejected: only on insert / cost to undo: one line.
- The `${CLAUDE_SESSION_ID}` fallback in the step-0 prose says "when that line shows no id": a literal variable written in the router's prose would be substituted too / rejected: quoting the variable / cost to undo: one sentence.
- Step 9.2 keeps its heading `2. **Write the experiment's before/after reading and post the A3**` (pinned by test_baseline_a3 ac22) with the run timing a to e inside it, first.
Open questions:
- Question 10 (for QA through the lead): the test_run_split allow-file for this slice's lines.
- The runtime proof must show whether `Session: ${CLAUDE_SESSION_ID}` is substituted in the person's Claude Code (contract 286-run-timing section 1.3); I could not run it in this task.
- Docs-writer: README.md:177 and docs/factory/reference.md:84 (A3 marker); docs/factory/reference.md:210 describes the 2.3.0 A3 v2 as history and may want a v4 note; CHANGELOG 3.10.0 with fingerprints from `bash plugins/factory/scripts/fingerprint.sh plugins/factory`.
Missing: none
