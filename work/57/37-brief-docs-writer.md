# Brief: docs-writer — 57 (Documentation)

Goal: Document release 1.2.0 for the people who use the factory: the baseline issue, the per-run A3 with its countermeasure experiment, and the changed run close (the A3 replaces the batch-at-the-end step 9).

Inputs:
- `docs/requirements/57-per-run-a3-and-baseline.md` (31 ACs) and the contracts `contracts/57-*.md`.
- The built text: `plugins/factory/references/baseline.md`, `references/a3.md`, `references/hansei.md` (v4), `skills/run/SKILL.md` (steps 5, 8.10, 9), and the tracker template `skills/setup-factory-skill/references/issue-tracker-github.factory.md`.
- `reviews/qa-57.md` (pass) and `reviews/security-57.md` (pass; info I1, I2).
- The demo outcome comment on issue #57 (what was and was not exercised: say so plainly where a doc would otherwise promise it).
- Current `README.md`, `CHANGELOG.md`, `docs/factory/reference.md`, `docs/agents/issue-tracker.md`, `docs/factory/release-runbook.md` (already updated by devops; link to it, do not edit it).

Constraints:
- Edit only `README.md`, `CHANGELOG.md`, `docs/factory/reference.md` and `docs/agents/issue-tracker.md`. Nothing under `plugins/`, `hooks/`, `scripts/`, `tests/`, `contracts/`.
- CHANGELOG: one entry "1.2.0" in the file's existing style: baseline issue, per-run A3, one experiment per run, series (release versus calibration), hansei v4, `not captured` never 0; the freeze means the install is unchanged until someone updates it.
- reference.md: the baseline issue (title, marker, who finds it), the A3 comment (marker, fields in order), the settle answers (keep, promote, drop) and that promote is a decision card; step 9 now offers only what the A3 lists and the person approves.
- issue-tracker.md: the new tracker bullets for the baseline and the A3 (this repository's section predates them; the run skill's fallback covers it until then).
- Do not claim what the demo did not exercise: AC-9 of #49 (paused agent keeps context) and AC-28 (keep, promote or drop on a real override) were not exercised; the cancelled-agent rule held but the harness enforced it. Say "not yet exercised" where a doc touches these.
- No sandbox project names, issue numbers or URLs in any file; no absolute home path. Commit subjects start `#57 docs-writer: `.

Output: the edited files and `work/57/38-result-docs-writer.md` (start with `Status: working`, protocol result template, Done checked point by point).

Done:
- Each of the four files says what 1.2.0 changed in words a new factory user follows.
- Nothing promises behaviour the demo did not show.
