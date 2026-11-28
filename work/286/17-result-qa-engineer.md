# Result: qa-engineer — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (WimSuenens, marker qa-engineer 4); 9.2 b and c re-pinned (bc7e206); L1 and L2 tests (4ba73e1); run size re-measured (92de2b9); full suite and CI steps; verdict round 2 (b672d34); paths check clean; role knowledge
  Next: re-run `bash tests/run.sh` after the docs-writer and the security reviewer's reword
Summary:
- Verdict pass, round 2 (reviews/qa-286.md), build 5ad4dac; proof P1 (scenario re-run, same output) and P2 (targeted transcript) updated.
- L1: 18 checks `l1-*` in test_run_timing_286.sh; L2: 8 checks `l2-*` in test_run_state_286.sh (contract section 6 rows). On e271040 every refusal check fails and every control passes; at 964bc25 L1's line-number and no-echo checks still fail; all pass at 5ad4dac.
- slice286-added.txt lines 4 and 5 re-pinned to the new 9.2 b and c, checked against 5.2 and 6.1; test_run_split 110 of 110.
- CI step 1: bash 3.2.57, BWK awk, BSD sed, git 2.39.5, jq 1.8.1, en_NZ.UTF-8. Step 2 `bash tests/run.sh`: red only on the four Documentation checks of test_lean_rules.sh and test_release64 ac45 (one hit, reviews/security-286.md:31).
- Run size 160,631 bytes, cap 162,000 stays. paths.sh check: no off-list path.
Artifacts: reviews/qa-286.md, tests/factory/test_run_timing_286.sh, tests/factory/test_run_state_286.sh, tests/factory/fixtures/split/slice286-added.txt, tests/factory/test_slice3_table.sh, docs/agents/roles/qa-engineer.md
Decisions:
- the L1 cases add a bad 4th line to the section 3 fixture lead.tsv (plus one bad first line) / rejected: a new fixture file / cost to undo: one block
- the empty lead-sessions value is tested by a section whose line is `- lead sessions:` with nothing after it / rejected: a trailing space / cost to undo: one line
Open questions: none
Missing: none
