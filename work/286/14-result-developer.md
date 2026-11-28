# Result: developer — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (WimSuenens, marker developer 2); L1 and L2 fixed, both probes red before and exit 2 after (964bc25); five targeted tests exit 0; `bash tests/run.sh` run; check-bump pass
  Next: none (QA adds the regression tests)
Summary:
- L1: `run-timing.sh gaps` refuses a cut-offs line whose markers column fails `^[a-z_:-]+(,[a-z_:-]+)*$` (existing exit 2, `a cut-offs line not in its format`); the security probe line now exits 2.
- L2: `run-state.sh lead-sessions` exits 2 when an id fails `^[A-Za-z0-9-]{1,64}$`; stderr names the id by place only (`id 1 of 3 not in its format`), never echoing it. `none yet`, valid ids and an empty value print as before.
- Header comments of both scripts state the new grammar and exit. No other text changed (see open questions).
- Targeted tests (run_timing, run_state, a3_v4, baseline_runs, run_text 286): all exit 0. check-bump: pass (3.10.0).
- `bash tests/run.sh`: FAILURES. The four expected reds ac17-docs-say-v4-README/-reference and ac19 fingerprints 1, 2; plus test_release64 ac45-no-home-path-or-token-in-changed-files, hit `reviews/security-286.md:31` (the L1 probe text quotes a home-shaped path): security-reviewer's file, not this change.
Artifacts: plugins/factory/scripts/run-timing.sh, plugins/factory/scripts/run-state.sh
How to run: `for t in run_timing_286 run_state_286 a3_v4_286 baseline_runs_286 run_text_286; do bash tests/factory/test_$t.sh; done`; `bash tests/run.sh`. Probes: a cut-offs line with markers `$(id) /x @who` into `gaps` (exit 2); a body `- lead sessions: ../../x, $(touch pwned), abc` into `lead-sessions` (exit 2).
Decisions:
- the bad lead-sessions id is named by its position (`id <i> of <n>`), not echoed / rejected: echoing it quoted / cost to undo: one line.
- an empty `lead sessions:` value prints empty with exit 0 as before / rejected: exit 2 / cost to undo: one condition.
- run-close-run.md step 9.2 b is left unchanged: its line is pinned by tests/factory/fixtures/split/slice286-added.txt, so an edit turns test_run_split red / rejected: editing it now / cost to undo: one sentence plus QA's allow-file.
Open questions:
- Contract 286-run-timing section 2.4 says `lead-sessions` prints the value "as is"; it now also exits 2 on an id out of format. Architect to add that exit.
- Step 9.2 b (run-close-run.md:13) and contract line 227 route only exits 3 and 4 and `none yet` to `not captured`; a `lead-sessions` exit 2 has no reason text yet (suggest `lead sessions line not in its format`, which also needs hansei.md section 8 and QA's split allow-file). Optional per L1: tell 9.2 c to single-quote `--what`.
- ac45 hit in reviews/security-286.md:31 (security-reviewer to reword the probe path).
Missing: none
