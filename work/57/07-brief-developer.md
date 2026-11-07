# Brief: developer — 57

Goal: Build the standard change of slice #57 from the contracts: the baseline issue, the per-run A3, and the new run close, as plugin text, tracer bullet first.

Inputs:
- `contracts/57-standard-changes.md` (read first: the paths you may change, release 1.2.0, fingerprints, the AC-26 exception, the decisions), then `contracts/57-baseline.md`, `contracts/57-a3.md`, `contracts/57-run-close.md`, `contracts/57-records-and-overrides.md`.
- `docs/requirements/57-per-run-a3-and-baseline.md` (31 criteria; it is being amended by the product-owner in parallel for AC-3, 7, 11, 12, 13, 16, 20, 26 to match the contracts: where they differ, the contract wins).
- The current standard: `plugins/factory/skills/run/SKILL.md`, `plugins/factory/references/*.md`, `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`, `plugins/factory/.claude-plugin/plugin.json`.
- ADRs 0011, 0012, 0013; `CONTEXT.md`; `docs/agents/factory.md`.

Constraints:
- Change only the paths the standard-changes contract lists for you. Not `contracts/`, `docs/requirements/`, `docs/adr/`, `CONTEXT.md`, `tests/` or `reviews/`.
- Tracer bullet first: one commit that carries the thinnest end-to-end path (a run that reaches its close, reads the baseline, posts one A3 with its marker), then the rest in commits that each leave the text consistent.
- Bump `version` in `plugins/factory/.claude-plugin/plugin.json` to 1.2.0 in the commit that first changes standard work. No script is added (contract §4); if you think one is needed, ask, do not add it.
- Hansei v4: the new standard reads v3 and v4 and skips v1 and v2, as the records contract says. Roles read the protocol too: keep it to the one bullet the contract allows.
- Honesty rule: a measure not captured reads `not captured`, never 0. No project data and no absolute home path in any file (`~/` or relative). The fence of ADR 0011 stays; promoting an experiment is a decision card.
- Run the existing tests before you finish (`bash tests/run.sh` from the worktree); tests/ belongs to QA, so do not edit it. If a test fails because the standard's text moved, report it, do not edit the test.
- Commit subjects start `#57 developer: `. Do not open the PR; the Lead does after its bump check.

Output: the changed plugin files; `work/57/08-result-developer.md` (start with `Status: working`; update Progress at each checkpoint commit).

Done:
- Every file the contracts name is changed, each clause of the four contracts and the AC-to-contract map is covered, and `plugin.json` reads 1.2.0.
- `bash tests/run.sh` result stated (pass count, any failure with its cause).
- A short list of anything in the contracts you could not build as written.
