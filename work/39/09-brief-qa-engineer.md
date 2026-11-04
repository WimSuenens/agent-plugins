# Brief: qa-engineer — 39
Goal: Verify slice #39 against its requirement and give a release verdict; list the human-only criteria for the acceptance demo.
Inputs: slice #39 (`gh issue view 39 --comments`); PR for item/39 (`gh pr view item/39`, `gh pr diff item/39`); `docs/requirements/39-hansei-record.md`; `contracts/39-*.md`; developer result `work/39/06-result-developer.md`; the developer's fixture tests in `/private/tmp/claude-501/-Users-wimsuenens-Projects-portfolio-agent-plugins/b3146b4a-f9f3-49bc-a33a-9f3c202be9b0/scratchpad/` (`t_fp.sh`, `t_cb.sh`, `t_ts.sh`) — adopt them into `tests/` if they serve.
Constraints:
- Test against temp copies, fixture transcripts and throwaway git repos only; never push a throwaway branch; never modify the installed factory or run `/plugin` commands.
- The architect is aligning two contract conflicts in parallel (check-bump path listing in example 2; `n/a` in measure 3); the developer's resolution is the expected behaviour.
- For the human-only list: the demo runs in `WimSuenens/factory-sandbox` (private, empty) via `claude --plugin-dir /Users/wimsuenens/Projects/portfolio/wt/39/plugins/factory`; AC-9 runs on a local, never-pushed agent-plugins throwaway branch. Include as a human-only prep check whether a `--plugin-dir` session actually loads the 1.0.0 skills rather than the installed 9147301f75c3 (same plugin name).
Output: tests under `tests/`, verdict `reviews/qa-39.md`; result `work/39/10-result-qa-engineer.md`. Commits `#39 qa-engineer: <what>`.
Done: your role's Done list; the verdict names `pass` or the findings, and lists Human-only criteria (or `none`).
