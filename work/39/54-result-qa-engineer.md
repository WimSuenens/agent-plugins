# Result: qa-engineer — 39
Status: done
Progress:
  Done: start (72f6038); 13 standard-text assertions moved, both skips enabled and made behavioural, guarded close run verbatim in scratch repos (901c72f); cut-offs.sh fixture tests and --require-end rule-1 tests (fa1b94d); demo replay, measure-1 rebuild, mutation check, verdict (bf41112)
  Next: none. A re-run is needed only if F4/F5 are fixed: bash tests/run.sh (F5's skip becomes a plain check)
Summary:
  Verdict: pass. Round-4 F1, F2, F3 are fixed and re-verified. Suite: 556 passed, 1 skipped (F5), 0 failed; same in a clean git-archive export of HEAD.
  Replay (read-only) of cut-offs.sh on factory-sandbox #2 matches the architect's table line for line: developer 23:50:46Z open; QA five recovered gaps 00:08Z-01:21Z plus 01:25:07Z open; Lead limits 22:02-23:49Z and interrupted 01:43-06:49Z. --require-end exits 6 for the 2 cut agents and 0 for the other 5.
  Measure 1 of the demo, rebuilt under round-5 rules: total 9h11m; agent working 22m (v1 said 7h15m); person 9m; limits 1h47m; stalled 0m; interrupted 6h53m.
  AC-17: PASS. Demo re-run: NOT DEMANDED.
  New test_cut_offs.sh (63 checks): every marker kind, silent gap at 600/599s, strongest kind wins, --sleep-log (file, stdin, offsets, hansei.md's exact filter with a stand-in pmset), --since/--until, exit 3 with empty stdout, exit 2, exit 4. 16 mutants, all caught.
  The close commands were extracted verbatim from hansei.md and run in scratch repos. The dirty, untracked-brief, .env and .DS_Store case runs clean, with no stray file in history. Both symlink cases, a non-numeric or empty id, and a missing worktree all stop at the guard.
  F4 minor (does not block): the close's $w does not survive into a separate Bash call; the text should say "one shell call" and use ${w:?}.
  F5 low: cut-offs.sh counts a lone Wake line inside a gap as asleep; the contract says only a Sleep line.
  Fingerprint at HEAD: release 1.0.0; standard 8caf11c1a4c9248f93a8a7c537713678bb1bf433713f871bc59d33fad286f2d3; tooling a0e7216f42c0b6c325c92542afa07dd5db3547e213ac57fe6d96e9a910837c86
Artifacts: tests/factory/test_cut_offs.sh (new), tests/factory/test_standard_text.sh, tests/factory/test_token_spend.sh, tests/factory/lib.sh, reviews/qa-39.md
Decisions:
  - Close-order tests extract the guard and git commands from hansei.md and run them / rejected: hand-copied commands / cost to undo: one test block.
  - Demo replay in test_cut_offs.sh runs the real transcripts while they exist, else a named skip / rejected: no real-data check in the suite / cost to undo: one if-block.
  - F4 graded minor, not a block (it fails safe because of && and pathspec errors) / rejected: major / cost to undo: the lead may upgrade it.
  - F5 kept as a named skip / rejected: a failing check / cost to undo: none.
  - AC-17 judged by rebuilding the demo's measure 1 from replayed lines and git times (the demo's lead state stops at Open PR) / rejected: fixtures only / cost to undo: none.
Open questions:
  - Developer, F4: hansei.md §5 step 6 and SKILL.md 8.6 should say to run guard + 6.1 + 6.2 as one shell call, with "${w:?}/work/<id>" in the rm.
  - Developer or architect, F5: either add the .k == "Sleep" filter, or word the contract to match.
  - Lesson for the lead and docs: Claude Code's built-in removal safety check blocked this QA's own rm -rf "$var" scratch cleanups twice. The close's rm -rf -- "$w/work/<id>" may prompt in a real session, and an AFK prompt times out. It is listed as an AC-18 human-only check. Two scratch dirs under the QA session's scratchpad were left in place (not removed).
