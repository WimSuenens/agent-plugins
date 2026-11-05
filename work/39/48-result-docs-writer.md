# Result: docs-writer — 39
Status: done (Done item 2, "setup, run and deploy steps executed", is open; see Summary)
Progress:
  Done: start result (a562d4d); docs for schema v2 (b83d5a5): CHANGELOG.md 1.0.0 entry rewritten for v2, README factory section and status line, docs/factory/reference.md (4 of 4 contracts, v2); CHANGELOG known limitation for --require-end (67cbffa); CHANGELOG names the open v2 skips F1 to F3 (1172936); read-only quick starts run (see Summary); this result
  Next: none. Lead: schedule the open Done item (install and setup in a scratch project after the freeze), and re-check the README status line and the CHANGELOG acceptance paragraph when QA's v2 verdict lands
Summary:
  - Docs now describe schema v2: marker `<!-- factory:hansei v2 -->`, measure 1 in five parts, `pass first time (<n> low)`, four wait kinds with the Agent column, truncated spend as `not captured`, `token-spend.sh --require-end` (exit 6), done-then-stopped, the two-commit close.
  - CHANGELOG.md: the 1.0.0 entry (kept as the one entry for #39, not a second one) carries the restart note, the five-part lead time, the new wait kinds, `--require-end`, and the known limitations as the verdicts stand: security v2 pass with L8 to L10 (low); QA v2 F1 to F3 (named skips in the suite: stall start, the Lead's API-error stop, `--require-end` mid-run). The round-3 "not re-verified" limitation is gone: QA's and security's round-3 re-checks passed.
  - README.md: status line per the brief; measurement and stage-log text at v2; restart note; deploy step 2 now installs `factory@wimsuenens` (the newcomer gap); `/factory:setup-factory-skill` and the demo's label gap; `claude --plugin-dir` route for trying a checkout; links to the runbook; "What was tested" updated, with the `ALL PASSED` claim replaced by a pointer to QA's verdict.
  - docs/factory/reference.md: v2 record entry; stage-log entry with the four waits and done-then-stopped; plugin-scripts entry with `--require-end`; maintainer step 9 (restart after release).
  - Run read-only, today: `claude plugin list --json` (freeze holds: factory 9147301f75c3, user scope); `claude plugin validate .` (pass, the four known version warnings), `./plugins/factory` and `./plugins/factory/skills` (pass); `fingerprint.sh plugins/factory` (exit 0, release 1.0.0; values not written into docs); `git fetch origin main` then `check-bump.sh` (pass, 0.0.0 -> 1.0.0, exit 0); `token-spend.sh -- <PO transcript of #39>` (spend 387472, peak 53942, messages 11: the contract's figures); `token-spend.sh --require-end` on that transcript (exit 0); `bash tests/run.sh` (ALL PASSED with three named skips: QA v2 F1 stall-start-is-last-entry-before-gap, F2 lead-api-error-detected, F3 require-end-sleep-mid-run-exit-6). The first run showed only F3; QA's tests are still moving.
  - Not run, on purpose: deploy step 1 (`git init`, `gh repo create`: the repo exists at origin; re-running would touch it); deploy step 2 and the Iterating `marketplace add`, `install`, `uninstall`, `marketplace update` (they change the user-scope install the freeze holds); `/factory:setup-factory-skill`, `/factory:run` and the `claude --plugin-dir` session (interactive; this repo is already set up); the runbook's Tag steps and *Post/Edit hansei* (writes). Open Done item 2 for the first two groups: the factory install and a project setup are documented but not executed.
  - Newcomer test, from the docs only: the README covers install, setup, run, the measurement, the release and the runbook link. The gaps the docs cannot close are the executed steps above.
Artifacts:
  CHANGELOG.md (factory 1.0.0 entry)
  README.md (status, factory section, Deploy, Iterating, What was tested)
  docs/factory/reference.md
  Commits: a562d4d (start result), b83d5a5 (docs for schema v2), 67cbffa and 1172936 (CHANGELOG limitations), this result
Decisions:
  - CHANGELOG: the 1.0.0 entry is rewritten in place for v2. Rejected: a second entry for v2, since 1.0.0 is not tagged and v2 is part of it. Cost to undo: one entry split.
  - README status says the demo's AC-17 "is accepted on QA's verification of the fix, without a demo re-run", as the brief states, ahead of QA's v2 verdict. Rejected: waiting for the verdict and leaving "drafted". Cost to undo: one line, if QA demands a re-run.
  - The demo is named "a scratch project": no sandbox repo name, issue or record link. Rejected: linking the demo record. Cost to undo: one line.
  - Deploy step 1 is scoped to "a directory that is not a repo yet" instead of removed. Cost: none.
  - Deploy step 2 installs `factory@wimsuenens`, and the Iterating section gains the `--plugin-dir` route. Rejected: leaving the factory install out (a newcomer could not install it from the docs). Not run (freeze). Cost to undo: one line each.
  - README "What was tested": the `bash tests/run.sh` row points at QA's verdict file instead of claiming `ALL PASSED` for good. Cost: none.
  - Known limitations include the demo's setup-label gap, the shared `../wt/` collision, the merge style (#48), security L8 to L10, and QA v2 F1 to F3. The round-3 limitation is dropped (both round-3 re-checks passed). Cost to undo: edit.
  - The brief cites contracts at 9f7825b: `git log 9f7825b..HEAD -- contracts/` is empty, so that is the current contract text. No conflict.
Open questions:
  - QA's v2 verdict is not in reviews/qa-39.md yet (work/39/44 reads `Status: working`; the verdict file still says round 3). Once it lands: if QA demands a demo re-run, the README status line and the CHANGELOG *Acceptance demo* paragraph change; if QA's verdict names findings, the CHANGELOG *Known limitations* list changes with it.
  - AC-17 wording: the brief asks for "fixed in v2". QA's v2 F1 to F3 are still named skips, and F1 and F2 touch the stall and interruption cases the demo failed on. If QA leaves any of them open at the verdict, the README status line and the CHANGELOG acceptance paragraph must say so instead of "fixed".
  - Open Done item 2: who runs the factory install and a project setup in a scratch project, and when (after the freeze; the install is a user-scope change). I did not run them.
  - Runbook proposals, devops-owned, not edited (devops to apply):
    1. Line 81, *What happens to hansei records already posted*: `<!-- factory:hansei v1 -->` should read `v2`. 1.0.0 writes v2; v1 is only the acceptance demo's record.
    2. Line 52 and roll-forward step 5: "(then a `/reload-plugins` in running sessions)". Propose: restart the running sessions. The demo's first `--plugin-dir` session kept the pre-1.0.0 run skill until it was restarted. Whether `/reload-plugins` reloads skill text was not tested.
    3. *Facts the steps rest on*: add a bullet: a session keeps the skill text it read at start, so an update reaches a running session only after a restart.
    4. *Monitoring*, `token-spend.sh` row: name exit 6 (`not captured (transcript truncated by <kind>)`) with the non-zero exits.
    5. *Release checks* 4: `ALL PASSED` holds today with three named skips (QA v2 F1 to F3). Propose: a tag is cut only with no named skip left, stated in the check.
    6. Merge style: the runbook's `gh pr merge item/39 --merge` keeps `work/` in history (#48, open). Decide before the 1.0.0 merge, and note it in the runbook.
    7. Consistency (optional): *Post-merge checks* use `gh pr view 40`, the *Tag* step uses `gh pr view item/39`. PR #40 is item/39's PR and is open, so both work now; `item/39` is the one that survives a re-numbering.
Missing: none
