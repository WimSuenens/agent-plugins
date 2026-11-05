# Result: docs-writer — 39
Status: done
Progress:
  Done: tracker doc Merge PR reason (9cfa93e); CHANGELOG 1.0.0 (merge style, path rule, known limitations, four scripts); README status, scripts and tests rows; docs/factory/reference.md (four scripts, standard-changes §9); tests/run.sh ALL PASSED; quick start run as far as the freeze allows
  Next: none; open questions below go to the lead
Summary:
- Tracker doc: the `## Factory operations` section is now byte-identical to the setup template (only *Merge PR* differed, by the `--merge` reason clause).
- CHANGELOG 1.0.0: "merge style is open (#48)" replaced by the decision (ADR 0013); path rule added; limitations trimmed to the final verdicts. Removed the F1–F3 skip bullet (QA round 5 closed them; no skips in test_cut_offs or test_token_spend) and the L8–L10 bullet (security final: fixed). Kept: I6 (close 6.1 not chained, deferred) and the AC-18 live-session check (open).
- README: status line reworded (AC-17 replay, close check open, ADRs 0001–0013); "three scripts" corrected to four with a cut-offs.sh line; tests row now cites the run.
- docs/factory/reference.md: the plugin-scripts entry covers four scripts; the standard-changes entry covers the merge style and §9 path rule.
- `bash tests/run.sh`: ALL PASSED, 0 skipped (before my edits: 616 passed, 2 skipped, both F1 docs checks).
- Quick start: the read-only and validate-only steps ran and match the docs; install, marketplace, setup, init and deploy steps were skipped (freeze), so the Done item "setup/run/deploy executed" is open for those.
Artifacts: docs/agents/issue-tracker.md, CHANGELOG.md, README.md, docs/factory/reference.md, work/39/76-result-docs-writer.md
Decisions:
- Tracker doc: copy the template's *Merge PR* line verbatim (whole section now identical to the template). Chosen: template text. Rejected: a shorter reason. Cost to undo: revert one line.
- CHANGELOG known limitations: dropped F1–F3 and L8–L10 as closed by the final verdicts; kept I6 and AC-18 open. Cost to undo: a text edit; if the lead wants F1–F3 listed as closed history, add them under a "closed" line.
- README status: replaced "all provisional" with "each with the status line it carries there", because every ADR 0001–0013 reads `status: proposed` (0006 superseded). Cost to undo: text.
- README and reference: counted four scripts, not three (cut-offs.sh is in contract 39-plugin-scripts §4). Cost to undo: none, the file exists.
Open questions:
1. Brief says all human-only criteria passed; QA's table (reviews/qa-39.md, AC-18) leaves the live close session open, and the demo ran on an earlier close text. I wrote the open state into README and CHANGELOG. Lead: confirm, or tell me which wording to use.
2. docs/factory/release-runbook.md (devops-owned, not edited) is stale in two places: the Tag section says the merge style is "still --merge … open as #48, decide before the merge", and Release checks item 4 says "today QA v2 F1 to F3" are named skips (they are not; the only skips were the two docs checks I fixed). Proposed for devops: drop the #48 clause, and state that a tag waits only on a non-empty skip list.
3. docs/adr/0013 (architect-owned, on main) cites `work/39/09-…` and `work/39/60-…`. The protocol's citation rule says docs that land on main never cite a path under `work/`; the ADR should cite the tracker comment or the security review instead. Proposed for architect.
4. Freeze: the Deploy steps 1–3 of README (git init, gh repo create, marketplace add, plugin install, `/factory:setup-factory-skill`, `/wayfinding:setup-wayfinding-skill`) and the `--plugin-dir` session were not run. Reasons: user-scope plugin commands are frozen; git init and gh repo create change repo state; setup and run are interactive. The Done item stays open until someone with a shell runs them after the freeze, on a scratch HOME or a scratch repo.
5. README (Factory section) still says the setup left only `wayfinder:slice` among the wayfinder labels. Not re-verified in this item (wayfinding setup is out of scope); left as the demo's finding.
Verification run (2026-11-05):
- `bash tests/run.sh`: ALL PASSED. check-bump 86, cut-offs 74, fingerprint 77, standard text 288 (0 skipped), token-spend 93.
- `claude plugin list --json`: factory@wimsuenens still at 9147301f75c3, user scope (freeze holds).
- `claude plugin validate` on `.`, `./plugins/factory`, `./plugins/factory/skills`, `./plugins/wayfinding`, `./plugins/wayfinding/skills`: all exit 0 (warnings on `.` for the four unversioned plugins, as the README says).
- `fingerprint.sh plugins/factory`: release 1.0.0, values match QA's final round (computed 2026-11-05; not written into any doc).
- `git fetch origin main` then `check-bump.sh`: `pass: minor bump needed, 0.0.0 -> 1.0.0`, exit 0.
- `token-spend.sh -- <PO transcript of #39>` and with `--require-end`: `spend 387472 …; peak 53942; messages 11`, exit 0 (matches the contract's worked example).
- `cut-offs.sh -- <same transcript>`: no output, exit 0.
- Relative links in README, CHANGELOG, reference.md and the tracker doc resolve.
- No absolute home path written into any file I touched.
Missing: none
