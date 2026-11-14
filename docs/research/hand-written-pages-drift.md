# Hand-written pages against changed plugins: what can be checked for drift

Answers [#240](https://github.com/WimSuenens/agent-plugins/issues/240) (part of #146). The deferral is in [docs/requirements/188-wiki-shell.md](../requirements/188-wiki-shell.md) (lines 203 and 212): "deeper drift detection of narrative pages stays deferred".

## What is hand-written today

Only [getting-started.md](../../apps/site/src/content/pages/en/getting-started.md) (EN, with a NL twin) and the prose strings in [ui.mjs](../../apps/site/src/i18n/ui.mjs) (Home and the Reference intros). The Skills and Agents pages, and the counts in them, are generated from `plugins/*/skills/*/SKILL.md` and the agent files, so they cannot drift. The page tree ([pages.mjs](../../apps/site/src/data/pages.mjs)) names pages, not plugins.

## What Getting started claims, and whether it can be checked

| Claim | Kind | Checked today? | Source of truth |
|---|---|---|---|
| marketplace source `WimSuenens/agent-plugins` | name | yes, [getting-started.test.mjs](../../tests/site/getting-started.test.mjs) (AC-19) | repo |
| marketplace name `wimsuenens` | name | yes | `.claude-plugin/marketplace.json` `name` |
| installed plugins `mattpocock-skills`, `wayfinding`, `factory` exist | name | yes (`unknownCommands`: marketplace.json list or `plugins/<name>` folder) | marketplace.json |
| `/wayfinding:setup-wayfinding-skill`, `/factory:setup-factory-skill`, `/wayfinding:wayfinder`, `/factory:run` exist | name | yes (skill folder or frontmatter `name`) | `plugins/*/skills/*/SKILL.md` |
| EN and NL code blocks identical | structure | yes (AC-20) | the two pages |
| "The factory builds on wayfinding and on mattpocock-skills" | relation | **no** | `plugins/factory/.claude-plugin/plugin.json` `dependencies` (currently `["wayfinding","mattpocock-skills"]`, true) |
| "The first wires planning conventions into your issue tracker doc" | behaviour | no | `setup-wayfinding-skill/SKILL.md` (true: writes `## Wayfinding operations` in `docs/agents/issue-tracker.md`) |
| "The second writes `docs/agents/factory.md` and prepares the GitHub Project board" | behaviour + path | no | `setup-factory-skill/SKILL.md` step 5 and 7 (true). The path `docs/agents/factory.md` is a checkable literal. |
| "Only GitHub trackers are supported for the factory" | behaviour | no | `setup-factory-skill/SKILL.md` step 1 (true) |
| "needs a GitHub repository and the `gh` tool" | behaviour | no | same skill (true) |
| "The factory asks a few questions about the destination … comes back only for one-way doors" | behaviour | no | `skills/run`, prose only |
| `/reload-plugins`, `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, "a session keeps the skill text it read" | Claude Code behaviour | no | Claude Code docs, not this repo |
| Home: "Agents do the work; you decide only what can't be undone" | slogan | no | judgement |

Findings:

1. **The names are already covered.** Every slash command and install target in a code block is verified against the plugin files, in both languages, and the check has a control test. The deferral line is therefore half-true: names in code blocks no longer drift. Not covered are names written in prose (backticks outside code fences) and file paths.
2. **No count, version or agent name appears on a hand-written page.** Counts (`{skills}`, `{agents}`, `{plugins}`) are generated. The factory 2.15.0 → 3.2.0 change did not touch any claim in the pages; the page makes no versioned claim, which is the cheapest drift defence there is.
3. **The remaining claims are relations and behaviours.** Some have a checkable literal inside (`docs/agents/factory.md`, `gh`, `wimsuenens`, plugin dependency), but whether "the second writes X" is still *true* needs a reader. A string match would only prove the skill still mentions the string.
4. **Claude Code behaviour claims** (`/reload-plugins`, the HTTPS variable) have no source in this repo. No build check can see them; they age with Claude Code.

## What a check would have to read

- Backticked tokens in the page prose: `/plugin:skill` forms and plugin names, checked with the existing `unknownCommands` logic (extend input from code blocks to inline code).
- Inline-code file paths that start with `docs/` or `plugins/`, checked against what the setup skills write (the skill text names them: grep `SKILL.md` for the literal).
- `plugin.json` `dependencies` for the "builds on" sentence, only if the sentence is turned into data.

## Recommendation

Two layers, cheapest first, neither needing new infrastructure:

1. **Widen the existing check (a small slice).** Run `unknownCommands` over *all* backticked tokens in the content files, not only fenced blocks, and add one rule: a backticked `docs/agents/*.md` path must appear verbatim in some `plugins/**/SKILL.md`. This turns the two checkable prose classes (names, paths) into build failures at the cost of a few lines in the test that already exists.
2. **A reviewed list for the rest, owned by the docs-writer.** Put a short `Verified against` header comment in no page; instead keep one list in `docs/agents/` (or the docs-writer role file) of the behaviour claims above, each with the plugin file that owns it. When a PR touches `plugins/<p>/skills/**` or `plugins/<p>/.claude-plugin/plugin.json`, the docs-writer (which already runs "before merge") rereads the claims whose owning file changed. The list is about a dozen lines and is the only way to judge prose.

Not recommended: a build check that hashes the plugin files a claim depends on and fails on any change. It would fire on every factory release (many), and a reviewer would learn to ignore it; the factory has changed 17 minor versions without making one page claim false.

Also advisable and free: keep versions, counts and agent or skill lists out of hand-written pages (link to Reference instead), as Getting started does now. Behaviour sentences about Claude Code should be re-verified when the minimum Claude Code version moves; mark them in the reviewed list.
