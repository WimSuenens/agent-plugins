# Contract 244 — Inline names check: every backticked name and path on a hand-written page is verified

Issue [#244](https://github.com/WimSuenens/agent-plugins/issues/244) · Requirement `docs/requirements/244-inline-names-check.md` · Widens AC-19 of `docs/requirements/188-wiki-shell.md` · Research `docs/research/hand-written-pages-drift.md`

## Paths

Paths:
- tests/site/names.mjs
- tests/site/names.test.mjs
- tests/site/getting-started.test.mjs
- docs/requirements/244-inline-names-check.md
- docs/requirements/188-wiki-shell.md
- apps/site/src/content/pages/en/getting-started.md
- apps/site/src/content/pages/nl/getting-started.md
shared: none

Notes on the list. Every file under `tests/` is qa-engineer's; the slice has no application code. The two page files are listed because AC-6 says a real drift found by the check is fixed in the page: the architect searched both pages and found none (every `/plugin:skill`, `install` target and the one `docs/agents/factory.md` path exists), so the developer edits a page only if the check reports something. `docs/requirements/188-wiki-shell.md` already carries the two rewritten deferral lines (203, 212). A `grep -rn` for `unknownCommands`, `commandsIn` and `marketplaceNames` finds them only in `tests/site/getting-started.test.mjs`; no other text states the rule. No `plugins/`, `.github/` or release-hook path is touched, so the release class is no bump.

## 1. Decisions on the two open questions (two-way doors)

**Q1: token source = the raw Markdown of each page, not the rendered HTML.** Rejected: rendered `code` elements. The HTML needs a site build and a browser per run, couples the rule to the highlighter's markup, and loses what the author wrote; the raw text needs one `readFileSync` and so also lets a control test feed a string. Cost to undo: swap the tokenizer (section 3.1); about an hour. The edge cases fall inside the raw source as follows (CommonMark rules, restated so QA can write the control from this text):

| Edge case | Result |
|---|---|
| inline span inside link text, `[`/factory:idea`](/x/)` | the span is a token; the link destination is not |
| double-backtick span, ``` ``a `b` c`` ``` | one token, content ``a `b` c``: a span opened by a run of N backticks closes at the next run of exactly N |
| backslash-escaped backtick outside a span, `` \`/x:y\` `` | no span opens; nothing is a token. Inside a span a backslash is literal (a span `` `a\` `` closes at the second backtick) |
| span wrapped over a line | one token; the line break becomes a single space |
| one leading and one trailing space when both are present (``` `` `x` `` ```) | stripped, as CommonMark does |
| backtick run with no matching closer | literal text, not a token |
| fenced block, ``` or ~~~ (3 or more, any indent), info string ignored | one token holding the block body; closes at a line of the same character at least as long; unclosed runs to end of text. Spans inside a fence are not read again |
| front matter (`---` first line to next `---`) | skipped |
| indented (4-space) code, HTML blocks, autolinks, link destinations | not tokens (no page uses them; stated so no one adds a rule for them) |

**Q2: the check lives in its own test file, `tests/site/names.test.mjs`, with its rules in `tests/site/names.mjs`.** Rejected: beside AC-19 in `getting-started.test.mjs`, which builds the site and starts a browser in `before()` and is about one page. The new check reads files only, so it runs without a build, and it reads every page. Importing from `getting-started.test.mjs` would run that file's `before()`, so the shared rules move: `commandsIn`, `marketplaceNames` and `unknownCommands` move **byte-identical** from `getting-started.test.mjs` into `names.mjs`, and `getting-started.test.mjs` imports them from there and re-exports them under the same names (`export { commandsIn, marketplaceNames, unknownCommands } from "./names.mjs"` plus the import it needs). Its test bodies and assertions do not change (AC-7). Cost to undo: move the three functions back; minutes.

## 2. The seams: signatures QA tests against

All in `tests/site/names.mjs`, ES module, named exports. `REPO`, `PLUGINS`, `SITE`, `skillSources`, `parseFrontmatter` come from `lib.mjs`. `CONTENT` is `apps/site/src/content/pages`.

| Export | Signature | Behaviour |
|---|---|---|
| `commandsIn`, `marketplaceNames`, `unknownCommands` | unchanged from `getting-started.test.mjs` | the AC-19 rules, same patterns, same results. Not re-specified here; AC-7 pins them |
| `fencedBlocks(markdown)` | `string -> string[]` | the body of each fenced block (section 1 table), in order, without the fence lines and without the final newline |
| `inlineSpans(markdown)` | `string -> string[]` | the content of each inline span outside fences, in order, after the space and line-break normalisation of section 1 |
| `backtickedTokens(markdown)` | `string -> string[]` | the in-scope tokens of one page: all of `inlineSpans` and `fencedBlocks`, in order of appearance in the text |
| `agentPathsIn(tokens)` | `string[] -> string[]` | every `docs/agents/<name>.md` found in the tokens, in order; `<name>` is `[A-Za-z0-9_-]+` (a single segment: `docs/agents/roles/x.md` and `docs/agents/skills/` are not matched). Left boundary: start of token or a character that is not a word character, `.`, `/` or `-` |
| `skillText(pluginsDir = PLUGINS)` | `string -> string` | the text of every file named `SKILL.md` anywhere under `pluginsDir`, joined with a NUL, skipping dot-folders and `node_modules`. Nothing else (README, `references/`, agent files, ADRs) is read |
| `unknownAgentPaths(tokens, text = skillText())` | `(string[], string) -> string[]` | each path from `agentPathsIn(tokens)` that is not a substring of `text`, as written (`docs/agents/nope.md`) |
| `unknownNames(tokens, opts = {})` | `(string[], {pluginsDir?, sources?, listed?, skillText?}) -> string[]` | `unknownCommands(tokens, sources, pluginsDir, listed)` followed by `unknownAgentPaths(tokens, skillText)`. Defaults: `pluginsDir = PLUGINS`, `sources = skillSources(pluginsDir)`, `listed = marketplaceNames()`, `skillText = skillText(pluginsDir)`. Reported strings are the AC-19 ones (`/factory:no-such-skill`, `install nosuch`, `marketplace other`) and the path |
| `handWrittenPages(contentDir = CONTENT)` | `string -> {lang, file, label, path}[]` | every `*.md` at any depth under each folder `<contentDir>/<lang>/`, sorted by label; `label` is `<lang>/<relative path>` (`nl/getting-started.md`). No page list, no language list: both come from the folder. A page added later is returned without an edit |
| `pageFaults(pages, opts = {})` | `({label, text}[], opts) -> string[]` | for each page, `unknownNames(backtickedTokens(text), opts)`; each fault is the string `<label>: <token>`, in page order then token order, without de-duplication |

Reading and reporting. `names.test.mjs` reads `handWrittenPages()`, asserts its length is above zero (AC-5), loads each file's text, and asserts `pageFaults(...)` equals `[]` with the faults as the assertion message (AC-9). The check holds no page, token, path or language list and no skip (AC-6, AC-10).

## 3. Expected behaviour, observable

Tokens below are fixed input; `PLUGINS` is the real folder unless a copy is named. "Reports" means the function result contains the string.

| Input | Expected | Criteria |
|---|---|---|
| `pageFaults([{label:"en/p.md", text:"Run `/factory:no-such-skill` now."}])` | `["en/p.md: /factory:no-such-skill"]` | AC-1, AC-9 |
| same with `` `/factory:idea` `` | `[]` | AC-1, AC-4a |
| `` Use `/nosuch:idea`. `` | reports `/nosuch:idea` | AC-4a |
| `` `claude plugin install nosuch@wimsuenens` `` | reports `install nosuch` | AC-2, AC-4b |
| `` `claude plugin install factory@other` `` | reports `marketplace other` | AC-4b |
| `` `claude plugin install wayfinding@wimsuenens` `` | `[]` | AC-4b |
| `` `claude plugin install mattpocock-skills@wimsuenens` `` | `[]`; with `opts.listed = new Set()` reports `install mattpocock-skills` | AC-7, AC-2 |
| `` See `docs/agents/nope.md`. `` | reports `docs/agents/nope.md` | AC-3, AC-4c |
| a fenced block holding `docs/agents/nope.md` | reports it; the same block with `docs/agents/factory.md` is `[]` | AC-3, AC-4c |
| `` `docs/agents/factory.md` `` | `[]` | AC-4c |
| `` `docs/adr/0001.md` ``, `` `apps/site/x.md` ``, `` `docs/agents/roles/x.md` `` | `[]` (no rule matches) | AC-8 |
| the copy of `en/getting-started.md` with `/wayfinding:wayfinder` changed to `/wayfinding:no-such` and labelled `nl/getting-started.md` (also for an install target and a `docs/agents` path) | reports it with the label `nl/getting-started.md` | AC-4d, AC-9 |
| the AC-8 spans: `` `/reload-plugins` ``, `` `/plugin marketplace add x/y` ``, `` `Run /reload-plugins to activate.` ``, `` `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` ``, `` `claude plugin marketplace add WimSuenens/agent-plugins` ``, `` `wayfinding` ``, `` `https://example.org/a:b` `` | `[]` | AC-8 |
| the same AC-8 look-alikes as plain text, outside backticks, with a bad `/x:y` | `[]` (only backticked text is a token) | AC-1 |
| the real `handWrittenPages()` then `pageFaults` over their text | `[]`, set non-empty, labels include `en/getting-started.md` and `nl/getting-started.md` | AC-5, AC-6 |
| `handWrittenPages(tmp)` with `tmp/en/a.md`, `tmp/nl/a.md`, `tmp/de/sub/b.md` | the three labels, no edit to the check | AC-5 |
| `handWrittenPages(emptyDir)` | `[]` (and the test that reads the real folder fails on an empty set) | AC-5 |
| `skillText(copy)` where the copy's `SKILL.md` files no longer mention `docs/agents/factory.md` | `` `docs/agents/factory.md` `` is reported; adding the path to one `SKILL.md` of the copy clears it; a copy where only `README.md` or `references/x.md` holds it still reports it | AC-3, AC-10 |
| `` ``a `/x:y` b`` `` (double backtick), a span wrapped over two lines, a span in link text, an escaped backtick | per the section 1 table, via `inlineSpans` | AC-1 (edges) |
| every fenced block of the real pages via `unknownCommands(fencedBlocks(text))` equals `unknownCommands(<the rendered pre texts>)`; and the AC-19 control input through `unknownNames` returns what `unknownCommands` returns for it | identical, token for token | AC-7 |

A control that still passes with its rule disabled does not count (AC-4): QA proves each by running it once against a copy of `names.mjs` with that rule emptied and seeing it fail.

## 4. Worked example

Page text (`nl/getting-started.md`, one line changed from the real page):

````
Het tweede schrijft `docs/agents/setup.md`. Draai `/factory:run-everything`.

```
claude plugin install factory@other
```
````

`backtickedTokens(text)` is `["docs/agents/setup.md", "/factory:run-everything", "claude plugin install factory@other"]`. `pageFaults([{label: "nl/getting-started.md", text}])` is

```
[
  "nl/getting-started.md: /factory:run-everything",
  "nl/getting-started.md: marketplace other",
  "nl/getting-started.md: docs/agents/setup.md"
]
```

(commands and installs first, in token order, then paths: that is `unknownNames`' order). The test fails with these three lines as its message.

## 5. Acceptance criteria map

| AC | Covered by |
|---|---|
| AC-1, AC-2 | section 2 (`inlineSpans`, `unknownNames`), section 3 rows 1 to 7 |
| AC-3 | `agentPathsIn`, `skillText`, `unknownAgentPaths`; section 3 path rows |
| AC-4 | section 3 (rows for a to d) and the closing rule on disabled controls |
| AC-5 | `handWrittenPages`; section 3 folder rows |
| AC-6 | the real-pages row; no list in any signature |
| AC-7 | Q2 move-and-re-export; the last section 3 row |
| AC-8 | `agentPathsIn` boundary and single-segment rule; the AC-8 row; the AC-19 pattern reused unchanged |
| AC-9 | `pageFaults` message format |
| AC-10 | `skillText` reads only `SKILL.md` files, takes a folder argument; the copy rows |

No ADR: every decision here is a two-way door (the tokenizer, the file split, the path source stay one edit each, and the path source was decided in the requirement).
