# Claims that hand-written pages make about the plugins

This list covers the behaviour and relation claims in the hand-written pages, the getting-started page in English and Dutch. Names and paths in backticks are not listed: the test run checks them (`tests/site/names.test.mjs`). Generated pages (Skills, Agents, counts) are not listed either, because they cannot drift. Source: [the drift research](../research/hand-written-pages-drift.md).

Each row names the file that owns the claim. When a pull request changes that file, the docs-writer rereads the row before merge (rule in [the docs-writer role file](roles/docs-writer.md)). Claude Code rows (kind `Claude Code`) are re-verified when the minimum Claude Code version moves.

| ID | Claim, as the page words it | Pages | Owner | Kind | Re-verify when |
|---|---|---|---|---|---|
| C1 | The factory builds on wayfinding and on `mattpocock-skills`. | getting-started EN and NL | `plugins/factory/.claude-plugin/plugin.json`, `dependencies` | relation | the `dependencies` list changes, or the sentence changes |
| C2 | The first setup command wires the planning conventions into your issue tracker doc. | getting-started EN and NL | `plugins/wayfinding/skills/setup-wayfinding-skill/SKILL.md`, step 3 | behaviour | step 3 changes where or what it writes |
| C3 | The second setup command writes `docs/agents/factory.md` and prepares the GitHub Project board. | getting-started EN and NL | `plugins/factory/skills/setup-factory-skill/SKILL.md`, steps 5 and 7 | behaviour and path | steps 5 or 7 change, or the file path changes |
| C4 | Only GitHub trackers are supported for the factory for now. | getting-started EN and NL | `plugins/factory/skills/setup-factory-skill/SKILL.md`, step 2 | behaviour | step 2 changes, or another tracker is supported |
| C5 | The factory needs a GitHub repository and the `gh` tool. | getting-started EN and NL | `plugins/factory/skills/setup-factory-skill/SKILL.md`, steps 2 and 7 | behaviour | steps 2 or 7 change their `gh` calls or their tracker check |
| C6 | The factory asks a few questions about the destination, then works. | getting-started EN and NL | `plugins/factory/skills/run/SKILL.md`, step 1 | behaviour | step 1 changes how the destination is asked |
| C7 | If the install says `Run /reload-plugins to activate.`, run it, then start a new session. | getting-started EN and NL | Claude Code docs; the repo echoes it in `README.md` (Versions and updates) | Claude Code | the minimum Claude Code version moves |
| C8 | A session keeps the skill text it read when it started, so an old session runs the old text. | getting-started EN and NL | Claude Code docs; the repo echoes it in `CHANGELOG.md` entries | Claude Code | the minimum Claude Code version moves |
| C9 | GitHub shorthand sources clone over SSH by default; set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` to use HTTPS. | getting-started EN and NL | Claude Code docs; the repo echoes it in `README.md` (install commands) | Claude Code | the minimum Claude Code version moves |

## Open

- No minimum Claude Code version is recorded in this repository. The `Run against Claude Code 2.1.287` lines in `README.md` are test records, not a minimum. So C7 to C9 have no version to watch.
- Rows C7 to C9 are not checked against Claude Code's own docs by this list. They are checked when the minimum version is known.
