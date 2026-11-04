# Brief: docs-writer — 39
Goal: Update user and operational docs for factory release 1.0.0 (the hansei record) before merge.
Inputs: slice #39 (`gh issue view 39 --comments`); `docs/requirements/39-hansei-record.md`; `contracts/39-*.md`; `docs/adr/0011-*.md`, `docs/adr/0012-*.md`; the plugin under `plugins/factory/` (read-only for you); developer results `work/39/06-result-developer.md`, `16-`, `20-`, `26-` (their "for docs-writer" notes); current `README.md`, `CHANGELOG.md` (create if absent), `plugins/factory/README.md` if present (owned by developer — propose changes in your result instead), and this repo's `docs/agents/issue-tracker.md`.
Constraints:
- `CHANGELOG.md`: a `factory 1.0.0` entry: release numbers and `factory-v<semver>` tags, the bump rule (≥minor for standard work, ≥patch for tooling) and the Lead's refusal, the hansei record and stage log, the two fingerprints, the three scripts, the pre-1.0.0 fallback for projects (replace their Factory operations section via `/factory:setup-factory-skill` step 6).
- `README.md`: whatever part describes the factory gets a short section on measurement (hansei record, where data lives: only in the project's own tracker) and versioning/updates (installs update only on a version bump).
- `docs/agents/issue-tracker.md`: replace its `## Factory operations` section with the one from `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`, keeping this repo's other sections.
- No project data (no paths under /Users, no session ids). Plain prose.
Output: those files; result `work/39/28-result-docs-writer.md`. Commit `#39 docs-writer: docs for factory 1.0.0`.
Done: your role's Done list.
