# Extraction survey: what a docs site can read from the plugins

Scope: main checkout `plugins/` (design, discover, factory, toolkit, wayfinding) and `.claude-plugin/marketplace.json`. There are no `commands/` directories in any plugin. Slash commands are the skills.

## 1. Manifests

Marketplace (`.claude-plugin/marketplace.json`): top-level `name`, `owner{name,url}`, `description`, `plugins[]`. Each plugin entry has `name`, `source`, `description`, `category`, `keywords`. The `mattpocock-skills` entry differs: `source` is an object `{source:"github", repo:"mattpocock/skills"}`, and it has no `category` or `keywords`. The other five use a string path `./plugins/<name>`. Marketplace descriptions differ from plugin.json descriptions for every local plugin (shorter). Marketplace `keywords` for wayfinding is not the same as plugin.json (plugin.json also has "engineering").

plugin.json (`plugins/*/.claude-plugin/plugin.json`), all five:
- Always present: `name`, `description`, `domain`, `author{name,url}`, `license` ("MIT"), `keywords`.
- `version`: only factory ("2.12.2"). README says this is deliberate ("Why plugin.json has no version"). Other plugins are versioned by git SHA.
- `dependencies`: only factory (`["wayfinding","mattpocock-skills"]`).
- `domain` is present in all five, one sentence, ASCII, ends with a period. Good page-intro field.
- Inconsistencies: `keywords` is formatted inline in design, multi-line in the others (irrelevant to a JSON parser). The `category` field is in the marketplace only. `description` in design and wayfinding says "over mattpocock/skills" (upstream mention). The marketplace `description` and the plugin.json `description` are two independent strings to keep in sync.

## 2. Skills (`plugins/*/skills/*/SKILL.md`, 18 files)

Skills per plugin: design 5 (design-system, direction, setup-design-skill, ux-psychology, ux-review), discover 1 (debrief), factory 4 (idea, obeya, run, setup-factory-skill), toolkit 1 (source-to-pptx), wayfinding 7 (ask-me, beachhead, dbml, model-playground, reversibility, setup-wayfinding-skill, wayfinder).

Frontmatter is single-line `key: value` YAML between `---` fences, on line 1.
- `name`: present in all 18, equals the directory name in all. Invocation is `/<plugin>:<name>`.
- `description`: present in all 18, single line, no wrapping. Lengths vary a lot (about 100 to 600 chars; source-to-pptx and run are longest). Quotes are not used, yet some contain `: `-free text so plain-scalar parsing works. Several contain backticks and `/` (obeya, run). Parse with a real YAML parser, not regex on `:`.
- `disable-model-invocation: true`: 12 of 18 (3 setup-*, design-system, direction, idea, obeya, run, ask-me, dbml, model-playground). Useful to label a page "manual command" vs "model-invoked". Absent means model-invocable.
- `argument-hint`: only factory idea, obeya, run (quoted strings like `"[start | stop] [--login-token]"`).
- `license`: only toolkit source-to-pptx.
- No `allowed-tools`, `version` or `metadata` keys anywhere.
- Description style: "Use when ..." trigger sentence is present in the model-invoked skills (ux-psychology, ux-review, debrief, beachhead, reversibility, wayfinder, source-to-pptx) and absent from manual ones. A generator may split on " Use when" but should not rely on it.
- Non-ASCII in frontmatter: em dashes in descriptions of design-system, direction, setup-design-skill, setup-factory-skill, setup-wayfinding-skill, beachhead, reversibility, wayfinder, run and others; toolkit source-to-pptx uses " - " hyphens instead (ASCII). Ellipsis and "…" appear in ux-psychology. So write files as UTF-8 and do not assume ASCII. Inconsistent dash style between plugins (em dash vs hyphen).
- Bodies: free-form Markdown, no fixed section schema. Skill-local `references/`, `assets/`, `scripts/` exist for design-system, direction, ux-psychology, setup-* and toolkit source-to-pptx. Those have no frontmatter (plain Markdown, JSON, py, sh, ps1).
- Gap: `.DS_Store` in plugins/toolkit (ignore dotfiles in globs).

## 3. Agents (`plugins/factory/agents/*.md`, 8 files)

architect, developer, devops, docs-writer, integrator, product-owner, qa-engineer, security-reviewer.

Frontmatter keys (all 8): `name` (equals filename), `description`, `tools` (comma-separated string, not a YAML list), `model` (inherit | sonnet | haiku). Optional `skills:` as a YAML list, in 3 files: architect and product-owner (`wayfinding:reversibility`), developer (`mattpocock-skills:tdd`). Description pattern: "<Role noun>. Use ..." - the first sentence is a one-word-ish role label (Architecture., Implementation., Delivery., Documentation., Dispatch and merge train., Requirements., Verification., Security review.). Plugin-qualified invocation name is `factory:<name>`.

Body: starts with "Start every task by reading `${CLAUDE_PLUGIN_ROOT}/references/protocol.md`." then a role-knowledge paragraph, then H2 sections. Section names are only partially consistent:
- `## Inputs needed` in 7 of 8 (integrator uses `## Input`).
- `## Done` in all 8.
- `## Authority` in architect, product-owner, qa-engineer, security-reviewer; `## Output` in architect, docs-writer, product-owner; `## Steps` in developer, qa-engineer, security-reviewer; others have role-specific sections (Environment, Principles, Plan, Merge train).
- Body has an introduction sentence before the first H2 (line ~1-17) that is a candidate summary but is not delimited. Use frontmatter `description` for summaries and body headings only for a section list.
- Gap: the integrator and the lead are special. The lead is not an agent file; it is `skills/run/SKILL.md` ("the lead"). marketplace says "seven role agents" while there are 8 agent files (integrator is the eighth). Do not hardcode the count; derive it.

`hooks/hooks.json` (factory only): one PreToolUse hook (matcher `Read|Grep|Glob|Bash|Edit|Write`) running `scripts/guard-memory.sh`. Readable JSON, describable on the factory page.

## 4. Factory references and scripts

`plugins/factory/references/*.md` (a3, baseline, decision-card, hansei, protocol): no frontmatter. Each starts with an H1 and a one-line audience statement ("For the lead. Read it at ..."; protocol: "Every role reads this ..."; decision-card: "How a one-way door reaches the person ..."). H1 is the title; first paragraph is a usable blurb. Numbered `## 1.` section headings in some, not others.

`plugins/factory/scripts/*.sh` (23 files): each starts with a shebang then comment lines: line 2 is a one-sentence purpose, `# Usage:` lines follow (multi-line, with continuation lines `#        bash x.sh ...`), often `# Exit:` codes. Exceptions: `protected-areas.sh` and `guard-memory.sh` have no `# Usage:` ("Sourced, not run" / hook). `protected-areas.sh` has no shebang (line 1 is a comment, "# Sourced, not run"). `obeya/compose.yml` is not a script. Header format is consistent enough to extract "purpose" (first comment line after shebang) and "Usage" (lines starting `# Usage:` plus following `#        bash` lines). Some purpose lines refer to internal spec/slice numbers ("spec #108, slice 118" in skip.sh); a public page should not expose these blindly.

Other plugins: design has `scripts/contrast.py`; toolkit source-to-pptx has 17 scripts in .py/.ps1/.sh with varying docstring styles (not uniform). Page generation for those is not recommended beyond a file list.

Also: `plugins/factory/skills/setup-factory-skill/assets/factory.md` and `plugins/design/skills/*/assets/*.md` are templates, no frontmatter.

## 5. Upstream mattpocock-skills credit

- `marketplace.json`: the `mattpocock-skills` plugin entry (`repo: mattpocock/skills`, description "Upstream, unmodified.").
- plugin.json descriptions: design ("A design layer over mattpocock/skills") and wayfinding ("A wayfinding layer over mattpocock/skills"). factory lists it under `dependencies`.
- agents: developer.md `skills: mattpocock-skills:tdd`.
- Skills mention `/setup-matt-pocock-skills`, `/ask-matt`, `mattpocock-skills:ask-matt` in the body (design setup, wayfinding setup, ask-me, factory run, factory setup).
- `README.md` is the main place: line 5 bullet, install commands (~233-246), "Both wayfinders coexist" (~278), pinning (~340). No LICENSE/credit/NOTICE file in the repo root listing (README only). No structured "credit" field exists. A site credit block must either be hardcoded or derived from marketplace.json `source.repo` of the entry named `mattpocock-skills`, plus the plugin.json `dependencies`.
- Upstream skills are not in this repo (fetched), so their reference pages cannot be generated from the checkout.

## 6. Discovery globs

- Plugins: `plugins/*/.claude-plugin/plugin.json`, cross-checked against marketplace `plugins[].source` that begins with `./`. The marketplace is the authority on ordering and `category`.
- Skills: `plugins/*/skills/*/SKILL.md` (non-recursive in the skill folder so nested references are never matched).
- Agents: `plugins/*/agents/*.md` (only factory today).
- Commands: `plugins/*/commands/*.md` (none exist; handle absent folder).
- Hooks: `plugins/*/hooks/hooks.json`.
- Factory references: `plugins/factory/references/*.md`; scripts: `plugins/factory/scripts/*.sh`.
- Exclude `.claude/worktrees/**`, `.DS_Store`, `node_modules`. Do not scan `contracts/`, `tests/`, `reviews/`; they contain "mattpocock" mentions but are internal.

## 7. Recommended extraction contract

| Page type | Source glob | Fields used |
|---|---|---|
| Plugin index / landing | `.claude-plugin/marketplace.json` | `plugins[].name,description,category,keywords,source` |
| Plugin page | `plugins/*/.claude-plugin/plugin.json` | `name`, `domain` (lead), `description`, `keywords`, `license`, `author`, `version` (optional), `dependencies` (optional) |
| Skill page | `plugins/*/skills/*/SKILL.md` | frontmatter `name`, `description`, `disable-model-invocation` (default false), `argument-hint`, `license`; body H1/H2 list optional; command = `/<plugin>:<name>` |
| Agent page | `plugins/*/agents/*.md` | `name`, `description`, `model`, `tools` (split on comma), `skills` (list); H2 headings of body; `factory:<name>` |
| Hooks section | `plugins/*/hooks/hooks.json` | `hooks.<event>[].matcher`, command basename |
| Factory reference page | `plugins/factory/references/*.md` | H1 title, first paragraph blurb, H2 headings |
| Factory script page | `plugins/factory/scripts/*.sh` | first comment line after shebang (purpose), `# Usage:` block, `# Exit:` line |
| Credits block | `.claude-plugin/marketplace.json` entry `mattpocock-skills` + `plugins/*/.claude-plugin/plugin.json` `dependencies` | `source.repo`, description |

## 8. Gaps that would break or degrade generation

1. Marketplace entry `mattpocock-skills` has a different `source` type (object vs string) and no `category`/`keywords`; a generator must branch on type, and its plugin has no local plugin.json.
2. Descriptions contain em dashes, ellipses, backticks, slashes; write/read UTF-8 and use a YAML parser. Dash style differs (toolkit uses " - ").
3. `tools` in agents is a comma string; `skills` is a YAML list; `model` is `inherit` for some (resolve label, do not treat as a model id).
4. Agent body headings are inconsistent (`Input` vs `Inputs needed`); do not require a fixed section set.
5. Only 3 of 18 skills have `argument-hint`; `license` only on one; `version` only on factory. All must be optional.
6. Marketplace description and plugin.json description differ per plugin; pick one source (suggest marketplace for cards, plugin.json for the plugin page) and accept the drift.
7. Marketplace says "seven role agents" while eight agent files exist; counts must be computed.
8. Script headers: `protected-areas.sh` has no shebang or Usage; `guard-memory.sh` has no Usage; some purpose lines cite internal spec/slice numbers. Make Usage optional and filter internal ids.
9. No `commands/` folders exist: command pages equal skill pages; the commands glob must tolerate an empty result.
10. Upstream skills are not in the repo, so upstream reference pages need a hardcoded link to `github.com/mattpocock/skills`; no structured credit field exists.
11. Worktrees under `.claude/worktrees` contain full copies of `plugins/`; a naive `**/SKILL.md` glob would duplicate every page.
12. `.DS_Store` under plugins/toolkit; ignore dotfiles.
