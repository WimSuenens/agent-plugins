# Result: docs-writer — 286

Status: done
Abnormality: none
Progress:
  Done: CHANGELOG 3.10.0 entry (dbaca1c); README line 177 and reference line 84 marker v4, reference page header and count, three reference entries for the 286 contracts (dbaca1c); release runbook 3.10.0 section (dbaca1c, 4fad3b9 skip wording); role file knowledge line on named skips; read-only release checks; `bash tests/run.sh` ALL PASSED; link check
  Next: none. Lead: merge gate, tag and install stay with the Lead and the person
Summary:
- CHANGELOG: `## factory 3.10.0 (#286)` above 3.9.1, with the Release line, five user-facing bullets, Tests, Unverified (AC-C6, `${CLAUDE_SESSION_ID}`, AC-A1/AC-B4 live, AC-C5) and the fingerprint line (standard 0c646b0d…, tooling 0ea7c2e5…, computed 2026-11-28 by fingerprint.sh; no plugin change since 5ad4dac).
- README line 177 and reference.md line 84: A3 marker v4 from 3.10.0, v1 to v3 still read; reference header now release 3.10.0, count 34, entries for 286-run-timing, 286-a3-v4-and-runs and 286-release.
- Runbook: `## Release 3.10.0` note (no migration, open-run `not captured` line, v4 skip in 3.9.x, release checks, tag steps, post-merge, frozen install, rollback).
- Ran read-only: `claude plugin validate` on plugins/factory and plugins/factory/skills (pass, one pre-existing `domain` warning); `scripts/check-bump.sh` pass 3.9.1 -> 3.10.0; fingerprint.sh; `git ls-remote` (no factory-v3.10.0; newest 3.9.1); `claude plugin list --json` (factory 3.9.1, user scope); `bash tests/run.sh` ALL PASSED.
- Claims: reread C1 (plugin.json, dependencies unchanged) and C6 (run SKILL.md step 1, unchanged).
- Not run: merge, tag, push, install, update (Lead and person; the install is frozen).
Artifacts: CHANGELOG.md, README.md, docs/factory/reference.md, docs/factory/release-runbook.md, docs/agents/roles/docs-writer.md, work/286/19-result-docs-writer.md
Decisions:
- Added three reference entries for the 286 contracts. Contract 286-release §2 says nothing else in reference.md is required, but the Done list requires every contract to have an entry; the Done list was followed. Cost to undo: delete the three entries and restore "Thirty-one contracts".
- README: marker sentence only (contract §2), no list of the four run lines. Cost to undo: one sentence.
- Runbook: the 3.10.0 section adds Frozen install and Rollback paragraphs, following the 2.3.0 section. Cost to undo: delete them.
- Reference page header changed from release 2.3.0 to 3.10.0. Cost to undo: one line.
Open questions:
1. Named skips: `bash tests/run.sh` prints ALL PASSED with 21 `skip` lines (retired-row checks, `worked-example-frozen`, and `ac25-every-search-hit-is-an-allowed-one`, `ac11-real-draft`, `ac8-no-pr-without-check`). The runbook's *Release checks* say a tag waits for any named skip. Lead: ask the person to accept them by name, or change the rule. The runbook text states the current rule.
2. Freeze: the lead state says "frozen on factory 3.9.1", the map's FREEZE line says 3.9.0 (lead state line 9, "see A1"). The live install reads 3.9.1, user scope; the runbook quotes the live read. Lead to reconcile.
3. `plugins/factory/.claude-plugin/plugin.json` `domain` gives a validate warning on main too (developer's file; not this slice).
4. README contains two site-route links (`/reference/`, `/nl/getting-started/`) that the local link check cannot resolve; they predate this slice and I did not touch them.
Missing: none
