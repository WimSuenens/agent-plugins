# Brief: developer — 39
Goal: Build slice #39 against its requirement and contracts: release 1.0.0, the hansei record and stage log in the standard, and the three scripts. Tracer bullet first: fingerprint.sh + the release line, end to end, before the rest.
Inputs: slice #39 (`gh issue view 39`); `docs/requirements/39-hansei-record.md`; `contracts/39-hansei-record.md`, `contracts/39-stage-log.md`, `contracts/39-plugin-scripts.md`, `contracts/39-standard-changes.md`; `docs/adr/0011-*.md`, `docs/adr/0012-*.md`; `CONTEXT.md`; the plugin under `plugins/factory/` (your path).
Constraints:
- Change only `plugins/` (your path). Doc changes outside `plugins/` (README, CHANGELOG, this repo's `docs/agents/issue-tracker.md`) belong to docs-writer later — list them in your result.
- Scripts: POSIX/bash that run on macOS and Linux; test them against temp copies, fixture transcripts, and throwaway git repos only. No shared resources.
- `plugin.json` gets `"version": "1.0.0"`. Do not create the tag — the Lead does at merge.
- The installed factory (`~/.claude/plugins/cache/...`) is frozen for this run: read it if useful, never modify it, never run `/plugin` commands.
- Pending in parallel: product-owner is amending AC-12 (cross-check on commits + stage-summary comments only) and AC-4/Terms (standard work = `references/*.md`); build to the contracts, which already say so.
Output: changes under `plugins/factory/`; result `work/39/06-result-developer.md`. Commits `#39 developer: <what>` at every checkpoint.
Done: your role's Done list.
