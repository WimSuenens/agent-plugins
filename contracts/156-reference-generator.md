# Contract 156 — Reference generator: skills from SKILL.md

Issue [#156](https://github.com/WimSuenens/agent-plugins/issues/156) · Source survey: [#149](https://github.com/WimSuenens/agent-plugins/issues/149) · Page: [site skeleton](156-site-skeleton.md) section 9

## Paths

Paths:
- apps/site/src/lib/skills.mjs
- apps/site/src/pages/reference/index.astro
- apps/site/test/skills.test.mjs
- tests/site/

shared: none

Read-only over `plugins/`; the slice changes no file there.

## 1. Seam

`apps/site/src/lib/skills.mjs` exports one function:

```js
loadSkills(pluginsDir = process.env.PLUGINS_DIR ?? path.resolve(process.cwd(), "../../plugins"))
  // -> Array<{ plugin, name, command, description, argumentHint, manual }>
```

`process.cwd()` is `apps/site/` when the build runs (npm scripts). `PLUGINS_DIR` lets QA and unit tests point at a fixture folder with the same shape. The Reference page calls it at build time; its result is never written to a file in the repository (AC-16): no generated data is committed and none is read back.

## 2. Discovery

- A source is a file `<pluginsDir>/<plugin>/skills/<skill>/SKILL.md`, exactly these two levels (no recursion), read with `fs`, not a repo-wide glob. Because the root is `plugins/`, copies under `.claude/worktrees/` and files outside `plugins/` are never reached.
- A directory or file whose name starts with `.` (`.DS_Store`) is ignored. A plugin with no `skills/` folder, or a skill folder with no `SKILL.md`, is skipped silently (nothing to list).
- `<plugin>` is the folder name under `plugins/`.
- Zero sources found is an error (`reference: no SKILL.md files found under <pluginsDir>`), so a moved folder cannot produce an empty page.

## 3. Parsing

- The file is UTF-8. Frontmatter starts at line 1 (`---`) and ends at the next line that is exactly `---`. No frontmatter is an error.
- The block is parsed with the `yaml` npm package (a real YAML parser; no regular expression on `:`). The body is ignored.

Fields:

| Key | Rule | Output |
|---|---|---|
| `name` | required, non-empty string | `name` |
| `description` | required, non-empty string; kept in full, unchanged | `description` |
| `argument-hint` | optional string; absent or empty gives `null` | `argumentHint` |
| `disable-model-invocation` | optional; `manual = (value === true)`, so absent, `false` or a string is not manual | `manual` |
| `license`, `version`, anything else | ignored | none |

`command` is `/<plugin>:<name>`, using the frontmatter `name`. A frontmatter name that differs from the folder name is not an error; the frontmatter name wins.

## 4. Failure (AC-17)

A source with a missing or empty `name` or `description`, a non-string `name`, `description` or `argument-hint`, bad YAML, or no frontmatter makes `loadSkills` throw. The message holds the source path as `<plugin>/skills/<skill>/SKILL.md` (a substring; any prefix is allowed) and the reason, for example:

```
reference: factory/skills/broken/SKILL.md: missing required field "description"
```

The build then exits non-zero and the output contains that line. No entry is skipped to hide a broken source.

## 5. Order and counts

Entries are sorted by `plugin` (code-point order), then by `name`. The page's entry count is whatever `loadSkills` returns; no number is written in the code or the page. (18 at the time of writing; the count in a test is computed from the files.) The marketplace file is not read in this slice.

## 6. Worked example

Source `plugins/factory/skills/run/SKILL.md`:

```
---
name: run
description: Run the software factory as its lead — one cycle over a standing backlog, `/factory:run` ...
argument-hint: "[idea | #map | #slice]"
disable-model-invocation: true
---
# body ignored
```

gives

```js
{ plugin: "factory", name: "run", command: "/factory:run",
  description: "Run the software factory as its lead — one cycle over a standing backlog, `/factory:run` ...",
  argumentHint: "[idea | #map | #slice]", manual: true }
```

and the entry markup of the [site skeleton](156-site-skeleton.md) section 9. A skill like `debrief` (no `argument-hint`, no `disable-model-invocation`) gives `argumentHint: null`, `manual: false`, and an entry with neither `data-field="argument-hint"` nor `data-field="manual"`.

Rebuild cases (AC-16), all by editing only a source: a changed `description` shows after `npm run build:site`; a new folder `plugins/<p>/skills/<s>/SKILL.md` adds an entry; a removed folder removes it. A fixture with `description` removed fails with the message of section 4 naming the file.

## 7. Behaviour QA can test

- With `PLUGINS_DIR` set to a fixture tree and `SITE_OUT_DIR` set to a scratch folder, `npm run build:site` yields a Reference page whose `[data-skill-entry]` count equals the fixture's `SKILL.md` count and each `data-field="description"` equals the YAML-parsed text (em dash, ` - `, ellipsis, backticks, slashes, quotes and colons included).
- The same run against the real `plugins/` yields one entry per `plugins/*/skills/*/SKILL.md` (count computed by the test with a directory listing, excluding `.claude/worktrees`).
- A fixture source with no `name` or no `description` makes the command exit non-zero with the file named; a source without `argument-hint`, `license`, `version`, `disable-model-invocation` builds.
- `git status` after a build shows no new tracked or untracked file outside ignored paths.

## 8. Acceptance criteria map

AC-13 (section 2, 5), AC-14 (3, page markup), AC-15 (3, plain-text rendering), AC-16 (1, 6), AC-17 (3, 4).
