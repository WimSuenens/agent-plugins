# Brief: architect — 36
Goal: Record the person's decision on #36 "Plugin version and this run's baseline" as an ADR, and add the terms it settles to CONTEXT.md.
Inputs: #36 with its comments (`gh issue view 36 --comments`): the card and the person's decision comment (the last "Decision:" comment); your own options file `work/frontier-36/02-options-architect.md`; #35 findings; ADR 0011 and `CONTEXT.md` in this worktree.
Constraints:
- Cite the #36 decision comment URL (get it with `gh api repos/WimSuenens/agent-plugins/issues/36/comments --jq '.[-1].html_url'`), never a path under `work/`.
- Content: option A (semver in plugins/factory/.claude-plugin/plugin.json only, bump levels, `factory-v<semver>` tags, resets on major/minor, 1.0.0 first); the fingerprint, now covering the four standard-work paths plus `hooks/` and `scripts/` — the interaction with patch bumps is left to the slice; the poka-yoke (Lead refuses to open a PR touching standard-work paths without a version bump); the freeze of this run on `9147301f75c3` as "Calibration (pre-baseline)", its machine-wide reach (user-scope install; marketplace update also pins other plugins), the item-start sha check with an andon on mismatch, and that an urgent mid-run fix ends calibration and is recorded as such. Your two-way sub-decisions stay as decided-inside, overturnable.
- Terms for CONTEXT.md only where they crystallise (e.g. Standard fingerprint, Baseline, Calibration).
- No tracker writes.
Output: `docs/adr/0012-<slug>.md`, `CONTEXT.md` edit; result `work/frontier-36/08-result-architect.md`. Commit: `#36 architect: ADR for plugin version and baseline`.
Done: the ADR states context, decision, consequences, and cites the decision comment; glossary updated.
