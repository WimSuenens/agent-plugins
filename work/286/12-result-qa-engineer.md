# Result: qa-engineer — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (WimSuenens, marker qa-engineer 3; 468e278); split allow-file, andon A4 option A (beea31e); run-size cap re-measured (2c75672, 454a218); full suite and CI steps; runtime proof scenario; verdict (8af05be, bdacb13); paths check clean; role knowledge (a25fb2d)
  Next: re-run `bash tests/run.sh` after the docs-writer (the four test_lean_rules checks named in the verdict)
Summary:
- Verdict pass (reviews/qa-286.md) on build e271040; AC-A1 to AC-C4 each a check and a scenario-transcript proof; AC-C5 (live #62) and AC-C6 are Human-only, post-merge.
- Andon A4: slice286-added.txt holds the 17 contract lines (each checked against 286-run-timing 1.1, 1.3, 5.2 to 5.4 and 286-a3-v4-and-runs 5); the #230 Run identity line moved out of slice230-added.txt; 2 lines in allowed-missing.txt; caps a0 35 to 51 and a3 13 to 15. test_run_split 110 of 110.
- Runtime proof: sandbox scenario on three factory.md variants gives identical bytes, ok v4, person rows for both questions, hand count agrees (adjusted 2h16m).
- `${CLAUDE_SESSION_ID}`: unset in this session and no skill loaded, so substitution is not observable here; it is on the Human-only list.
- CI step 1: bash 3.2.57, BWK awk, BSD sed, git 2.39.5, jq 1.8.1, en_NZ.UTF-8. Step 2 `bash tests/run.sh`: red only in four test_lean_rules checks (ac17 README and reference, ac19 two fingerprints), waiting on Documentation.
- Run-size cap: 160,432 bytes built, cap 162,000 stays. paths.sh check: no off-list path.
Artifacts: reviews/qa-286.md (verdict, with the P1 scenario and P2 targeted transcripts as sections), tests/factory/fixtures/split/slice286-added.txt, tests/factory/fixtures/split/slice230-added.txt, tests/factory/fixtures/split/allowed-missing.txt, tests/factory/test_run_split.sh, tests/factory/test_slice3_table.sh, docs/agents/roles/qa-engineer.md
Decisions:
- the reworded #230 Run identity line moved from slice230-added.txt to slice286-added.txt / rejected: keep it in both (a2b fails) / cost to undo: two fixture lines
- a3 allow-list cap raised 13 to 15 besides a0 (the brief named a0 only) / rejected: none possible, the two LOST lines must be allowed / cost to undo: one number
- proof transcripts kept inside reviews/qa-286.md, not a separate reviews file / rejected: reviews/qa-286-scenario.md (off-list in paths.sh check) / cost to undo: one file move
- AC-C5 and AC-C6 kept out of the gate's Criteria list and put on the Human-only list / rejected: a pass on a post-merge criterion / cost to undo: two lines
Open questions: none
Missing: none
