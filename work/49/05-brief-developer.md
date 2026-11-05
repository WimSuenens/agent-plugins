# Brief: developer — 49
Goal: Build the standard changes of #49 (Andon) in plugins/factory/ exactly as contracts/49-standard-changes.md places them, tracer bullet first, so that AC-1..AC-30 can be checked.
Inputs: docs/requirements/49-andon.md; contracts/49-abnormality-list.md, 49-andon-process.md, 49-overrides.md, 49-records.md, 49-standard-changes.md (and contracts/39-* where they refer); work/49/04-result-architect.md; docs/adr/0011, 0012, 0013
Constraints:
- Contract text wins. Where the text is unclear or wrong, ask the architect a Question and keep building on the agreed text.
- Tracer bullet: the thinnest end-to-end path first, i.e. one abnormality raised through `Abnormality:`, paused, 5 Whys, an override written under `## Overrides` with the fence check, andon comment, hansei line; then widen.
- Files in your ownership only (plugins/). The ownership-table row, README/CHANGELOG, docs/factory/reference.md and the release runbook belong to docs-writer and devops: do not touch them; list what they need in your result.
- plugin.json version to 1.1.0 (minor); the bump check must pass: `git fetch origin main`, then bash plugins/factory/scripts/check-bump.sh in this worktree.
- No new script (contract decision 12). No absolute home paths anywhere in the files. Do not run /plugin marketplace update or /reload-plugins; the frozen install stays.
- Plugin text is read by agents, not people: obey the repo's writing-for-agents conventions already used in plugins/factory/.
- Fixtures and the AC-3 replay are QA's (tests/); do not write them. Leave the repo's own test and lint commands green (run them if any exist; say if none).
Output: edits under plugins/factory/ (protocol.md, skills/run/SKILL.md, references/hansei.md, the setup-skill ownership row, .claude-plugin/plugin.json); result in work/49/06-result-developer.md with changed files, how to check, open questions
Done: every criterion that applies to the plugin text is satisfied by it; test and lint commands exit 0; result lists changed files and open questions.
