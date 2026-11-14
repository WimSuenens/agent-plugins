# Contract 225 — Agent loader and derived counts: agents from `plugins/*/agents/*.md`

Issue [#225](https://github.com/WimSuenens/agent-plugins/issues/225) · Requirement `docs/requirements/225-reference-agents.md` · Builds on [156 reference generator](156-reference-generator.md) (the skills loader, unchanged) · Sibling: [Reference section](225-reference-section.md)

## Paths

Paths:
- apps/site/src/lib/agents.mjs
- apps/site/src/components/registry.mjs
- apps/site/test/agents.test.mjs
- tests/site/
shared: none

Read-only over `plugins/`; the slice changes no file there. `lib/skills.mjs` is not touched: the agent loader has its own small frontmatter reader (two-way door, section 6).

## 1. Seam

`apps/site/src/lib/agents.mjs` exports one function:

```js
loadAgents(pluginsDir = process.env.PLUGINS_DIR ?? path.resolve(process.cwd(), "../../plugins"))
  // -> Array<{ plugin, name, description, model, tools }>
  //    model: string | null      tools: string[]  (empty array when absent)
```

Same root and the same `PLUGINS_DIR` override as `loadSkills`, so QA and unit tests point at a fixture tree with the same shape. The result is built in memory at build time, never written to a file in the repository, and no generated agent data is committed (AC-7).

## 2. Discovery (AC-1, AC-6)

- A source is a regular file `<pluginsDir>/<plugin>/agents/<file>.md`, exactly these two levels, read with `fs` (no repo-wide glob; copies under `.claude/worktrees/` and files outside `plugins/` are never reached).
- Names starting with `.` are ignored at both levels. In `agents/`, a file whose name does not end in `.md`, and a directory, is ignored.
- A plugin with no `agents/` folder, or an `agents/` folder with no `.md` file, is skipped silently: no group, no error, no special case by plugin name.
- **Zero sources under the whole tree is an error**: `reference: no agent files found under <pluginsDir>` (as for skills), so an empty Agents page cannot ship by accident.

## 3. Parsing (AC-2, AC-3, AC-4, AC-5)

Frontmatter starts at line 1 (`---`) and ends at the next line that is exactly `---`; the block goes to the `yaml` package (already a dependency); the body is ignored.

| Key | Rule | Output |
|---|---|---|
| `name` | required, non-empty string (trimmed non-empty) | `name` |
| `description` | required, non-empty string, kept in full; the page shows it trimmed, as the Skills page does | `description` |
| `model` | optional string, shown as written (`inherit`, `sonnet`, `haiku`); absent, empty or blank gives `null` | `model` |
| `tools` | optional. A string: split on `,`, each piece trimmed, empty pieces dropped. A YAML list of strings: each trimmed, empty dropped. Absent, empty or blank gives `[]`. Both forms of the same names give the same array, in file order (no sorting, no de-duplication) | `tools` |
| `skills`, anything else | ignored (not shown, requirement out of scope) | none |

A `model` that is not a string, a `tools` that is neither a string nor a list of strings, or a non-string `name` or `description` is an error (`field "<key>" must be a string` / `field "tools" must be a string or a list of strings`).

## 4. Failure (AC-4, AC-5)

`loadAgents` throws for: no frontmatter, bad YAML, frontmatter that is not a mapping, a missing or empty `name` or `description`, and the type faults above. The message holds the source as `<plugin>/agents/<file>.md` and the reason, with the `reference:` prefix the skills loader uses:

```
reference: factory/agents/broken.md: missing required field "description"
reference: factory/agents/broken.md: no frontmatter
reference: factory/agents/broken.md: bad YAML: <first line of the parser message>
```

The build exits non-zero and the output contains that line. No entry is skipped to hide a broken source. Every real file under `plugins/factory/agents/` must pass (AC-4); if one does not, the fault is in that file, and the developer writes a question instead of loosening the loader.

## 5. Order, ids and derived counts (AC-7, AC-8, AC-15)

- Sorted by `plugin` then `name`, code-point order (as for skills). Group id `<plugin>`, entry id `<plugin>-<name>`, built by the registry (section 5.1 of the section contract), using the frontmatter `name` (not the file name).
- **Counts are computed, never typed.** `registry.mjs` holds one function (not exported as a seam for QA) that returns `{ skills, skillPlugins, agents, agentPlugins }` from `loadSkills()` and `loadAgents()`: `skills` and `agents` are the array lengths, `skillPlugins` and `agentPlugins` the number of distinct `plugin` values. Overview, Skills page and Agents page and their `headings` all read it; no page source (`pages.mjs`, content file, `ui.mjs`) holds a digit that counts skills, agents or plugins. UI strings carry no number; the count is inserted at render.

## 6. Two-way decisions

- **Where the data shape lives:** `lib/agents.mjs` beside `lib/skills.mjs`, one module per source kind, same root. Rejected: one generic `loadReference()` (rewrites tested skills code for no gain now; hooks and manifests may need other shapes). Cost to undo: merge two files, an hour.
- **Own frontmatter reader, duplicated from `skills.mjs` (about ten lines):** leaves the tested skills loader and its tests untouched. Rejected: extract `lib/frontmatter.mjs` now (touches 156 code). Cost to undo: extract it later; the third source kind (hooks) is the trigger.
- **Error prefix `reference:`** for both loaders, so one grep finds every generator fault.

## 7. Worked example

Source `plugins/factory/agents/integrator.md` frontmatter:

```
---
name: integrator
description: Merge train. Use to merge approved slices (rebase, bump, merge, tag, clean up).
tools: Read, Grep, Glob, Bash
model: sonnet
---
```

gives `{ plugin: "factory", name: "integrator", description: "Merge train. Use to merge approved slices (rebase, bump, merge, tag, clean up).", model: "sonnet", tools: ["Read","Grep","Glob","Bash"] }`. The same file with `tools:` as a YAML list `[Read, Grep, Glob, Bash]` gives the identical value. A file with neither `model` nor `tools` gives `model: null, tools: []` and builds; the page shows neither label. A file with no `description` fails with `reference: factory/agents/integrator.md: missing required field "description"`.

Fixture, rebuild only (AC-7): add `plugins/design/agents/x.md` (a plugin with no `agents/`): the page gains a group `design` with entry `design-x`, and the counts `agents` and `agentPlugins` rise by one each; remove it and they fall back. Change `model: sonnet` to `haiku` in one file: that entry's model shows `haiku`; no other source changed.

## 8. Behaviour QA can test

With `PLUGINS_DIR` at a fixture tree and `SITE_OUT_DIR` at a scratch folder, `npm run build:site` yields `[data-agent-entry]` count equal to the fixture's `agents/*.md` count (listing computed by the test, excluding hidden and non-`.md` names); each `data-field="description"` equals the YAML-parsed text; faults of section 4 exit non-zero naming the file; zero agent files under the whole fixture exits non-zero with the message of section 2. Markup: see the section contract.

## 9. Acceptance criteria map

AC-1 (2, 5), AC-2 (3), AC-3 (3, 7), AC-4 (4), AC-5 (3, 4), AC-6 (2), AC-7 (1, 5, 7), AC-8 (5).
