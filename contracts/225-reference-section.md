# Contract 225 — Reference section: overview, Skills and Agents pages, English and Dutch

Issue [#225](https://github.com/WimSuenens/agent-plugins/issues/225) · Requirement `docs/requirements/225-reference-agents.md` · Builds on [188 page tree](188-page-tree.md), [188 wiki components](188-wiki-components.md), [156 reference generator](156-reference-generator.md) · Sibling: [agent loader](225-agents-loader.md) · [ADR 0022](../docs/adr/0022-the-documentation-site-has-an-editorial-wiki-look.md) (look, not reopened)

## Paths

Paths:
- apps/site/src/data/pages.mjs
- apps/site/src/components/registry.mjs
- apps/site/src/components/ReferenceBody.astro
- apps/site/src/components/SkillsBody.astro
- apps/site/src/components/AgentsBody.astro
- apps/site/src/components/ReferenceOverview.astro
- apps/site/src/i18n/ui.mjs
- apps/site/src/styles/base.css
- apps/site/src/styles/tokens.css
- apps/site/test/pages.test.mjs
- apps/site/test/ui.test.mjs
- tests/site/
shared: none

`ReferenceBody.astro` is renamed to `SkillsBody.astro` (the old name is removed; `ReferenceOverview.astro` is the new Reference body). The slice touches no `plugins/`, `.github/` or `docs/` path. `tokens.css` only when a new token is needed.

**Frozen (AC-9).** Nothing else under `apps/site/src/` changes: `lib/pages.mjs`, `lib/skills.mjs`, `lib/langScript.mjs`, `lib/rehypePage.mjs`, `layouts/`, `pages/` (both route files), `components/PageTree.astro`, `Breadcrumb.astro`, `Contents.astro`, `SeeAlso.astro`, `TopBar.astro`, `LangSwitcher.astro`, `DraftNotice.astro`, `Home.astro`, and `astro.config.mjs`, `package.json`, `package-lock.json`, `scripts/`. QA's test: `git diff main --name-only` under `apps/site/` is a subset of the Paths above plus `lib/agents.mjs` and `test/agents.test.mjs` of the [agent loader](225-agents-loader.md). No new npm dependency, no client script (AC-18).

## 1. Seam: page-tree entries (AC-9, AC-10, AC-11, AC-12, AC-13)

Three entries in `data/pages.mjs`, siblings of Getting started under Home, Skills and Agents children of Reference, in this array order (so the tree lists Skills then Agents):

```js
  { slug: "reference", parent: "", title: { en: "Reference", nl: "Naslag" },
    source: "component", component: "reference", seeAlso: ["getting-started"], review: { nl: "draft" } },
  { slug: "skills", parent: "reference", title: { en: "Skills", nl: "Vaardigheden" },
    source: "component", component: "skills", seeAlso: ["agents", "reference"], review: { nl: "draft" } },
  { slug: "agents", parent: "reference", title: { en: "Agents", nl: "Agenten" },
    source: "component", component: "agents", seeAlso: ["skills", "reference"], review: { nl: "draft" } },
```

`alsoListedIn` is removed from Reference. URLs stay flat: `/agent-plugins/{reference,skills,agents}/` and `/agent-plugins/nl/...`. The existing validation of the page-tree contract (section 5) needs no change: both Dutch parents exist. Nothing else is hand-edited for the section. Getting started and Home keep their entries.

## 2. Seam: registry (AC-7, AC-8, AC-15)

`components/registry.mjs` keeps `home` and gains keys, each `{ body, props(lang), headings(lang) }` as in the page-tree contract section 4:

| Key | Body | Props | Headings (contents list) |
|---|---|---|---|
| `reference` | `ReferenceOverview.astro` | `{ counts }` | `h2` id `skills` ("Skills" / "Vaardigheden") and `h2` id `agents` ("Agents" / "Agenten") |
| `skills` | `SkillsBody.astro` | `{ groups, counts }` | as 188: `h2` id `<plugin>`, nested `h3` id `<plugin>-<skill>` |
| `agents` | `AgentsBody.astro` | `{ groups, counts }` | `h2` id `<plugin>`, nested `h3` id `<plugin>-<agent>`, text is the name |

`groups` for each is `[{ plugin, id, entries/skills: [{ ...item, id }] }]`, built from `loadSkills()` / `loadAgents()` in one place that the body and `headings` both read (so they cannot drift). Counts: see the [agent loader](225-agents-loader.md) section 5. Ids are unique per page (the layout's `headingIdFaults` check already fails the build on a clash).

## 3. Markup QA reads (AC-1, AC-2, AC-8, AC-11, AC-14, AC-15, AC-17)

Hooks are `data-` attributes; text and class names are free.

**Counts** (all three pages, in `main`): each count is the whole text of an element `<span data-count="<name>">N</span>` inside a sentence the developer words. Names: `skills`, `skill-plugins`, `agents`, `agent-plugins`. Overview carries all four, Skills carries `skills` and `skill-plugins`, Agents carries `agents` and `agent-plugins`. QA compares each to the number computed from `plugins/`.

**Overview** (`reference`): an intro paragraph, then two sections, in this order, one per child. Each section has an `h2` (ids above), a one-line description, a link (in the page's language, `href` the child's page, no `lang`/`hreflang` attribute, taken from `getModel().link()` as `Home.astro` does, not typed) and its counts.

**Skills page**: as 156 section 9 and `ReferenceBody` today: per plugin `<section>` with `h2 id="<plugin>"`; per skill `<article data-skill-entry data-plugin data-name>` with `h3 id="<plugin>-<skill>"`, `code[data-field="command"]`, `[data-field="manual"]` only for a manual command, `p[data-field="description"]`, `p[data-field="argument-hint"]` only when present. Unchanged except the language marking below and that the page now lives at `/skills/`.

**Agents page**: per plugin that has agents one `<section>` with `h2 id="<plugin>"`; per agent:

```html
<article data-agent-entry data-plugin="factory" data-name="integrator">
  <h3 id="factory-integrator">integrator</h3>
  <p data-field="description">Merge train. ...</p>
  <p data-field="model"><span>Model:</span> <code data-value>sonnet</code></p>   <!-- only when model != null -->
  <div data-field="tools"><span>Tools:</span>                                      <!-- only when tools is non-empty -->
    <ul><li><code data-value>Read</code></li> ... one li per tool, in file order</ul></div>
</article>
```

No empty label, no placeholder, no `undefined` or `null` text. Descriptions render as the trimmed text node (escaped, no entity visible, no `set:html`). Plugin groups with no agent do not appear. Tools wrap (AC-17): the `ul` is a wrapping flex or inline list and `code` has `overflow-wrap: anywhere` (`base.css`); at 320 px the longest tools list leaves `document.documentElement.scrollWidth <= clientWidth`.

**Dutch language marking (AC-14).** On a Dutch page, the page title, the `h1`, the intro, field labels (`Model:` as "Model:", `Tools:` as "Hulpmiddelen:", "Argumentwijzer:", "handmatig commando"), the count sentences and section headings are Dutch. Each element that holds English plugin text carries `lang="en"`: the plugin `h2`, the entry `h3`, `[data-field="description"]`, every `code` value (command, model, tool, argument hint). On English pages none of those carries `lang`. Each of the Skills and Agents pages in Dutch holds one `p[data-field="english-note"]` (Dutch text: the entries below are English). Entries, order and ids are identical in both languages. Contents list: the shell's `Contents.astro` shows the plugin and entry names without a `lang` attribute; this is accepted (the shell is frozen) and not a failure.

## 4. UI strings (`i18n/ui.mjs`; AC-8, AC-14)

Both languages keep equal key sets (the `ui.test.mjs` check). New or changed keys, Dutch an agent draft: `referenceOverviewIntro`, `skillsIntro` (replaces `referenceIntro`), `agentsIntro`, `skillsDesc`, `agentsDesc` (the one-line descriptions on the overview), `skillsCountSentence`, `agentsCountSentence`, `modelLabel`, `toolsLabel`, `englishNote`; `referenceP` on Home is reworded (it said every skill; the Dutch said "de naslag is nog Engels", now untrue). A count sentence is a template with the number slot, for example `"{skills} skills from {plugins} plugins"`, filled at render by the body; singular/plural wording is the developer's, no digit is written in any string. Keys for headings or labels already there (`manual`, `argumentHint`) stay.

## 5. Behaviour (observable)

- Built URLs: `/agent-plugins/{reference,skills,agents}/index.html` and the `nl/` twins; no `/agent-plugins/nl/` page outside the tree. The English tree: Home > Getting started, Reference > (Skills, Agents). The Dutch tree the same with Dutch labels, all real Dutch links, none with `hreflang="en"`. Breadcrumb Home > Reference > Skills (Thuis > Naslag > Vaardigheden). Switcher: same slug in the other language. See-also per section 1.
- Build log: one line `pages: dutch drafts: /agent-plugins/nl/ /agent-plugins/nl/getting-started/ /agent-plugins/nl/reference/ /agent-plugins/nl/skills/ /agent-plugins/nl/agents/` (hrefs sorted by the model; QA checks that the three new ones are named, and that nothing else changed in the line's form). Setting `review: { nl: "reviewed" }` on one entry removes that page from the line and its notice.
- Home's Reference link on `/agent-plugins/nl/` goes to `/agent-plugins/nl/reference/` (the link now has no `lang="en"`); the top bar's link likewise (both read the model, no code change).
- a11y check covers the six pages with no edit to the script (it crawls `dist`).

## 6. Worked example

Fixture (AC-7, AC-8), on a copy of the source with `PLUGINS_DIR` at a copy of `plugins/`: add `design/agents/sketcher.md` with `name: sketcher`, `description: Draws wireframes (fast, rough, many).`, `tools: [Read, Write]`, no `model`. Rebuild, nothing else touched. English Agents page: a new group `design`, `h3 id="design-sketcher"`, the description exactly as parsed, a tools list `Read`, `Write`, no Model line; `data-count="agents"` is one more and `data-count="agent-plugins"` one more; the overview shows the same two numbers; the Dutch Agents page has the same entry with `lang="en"` on the description and tools and the Dutch labels; the contents list has `#design` and `#design-sketcher`. Remove the file and everything returns.

Dutch Agents entry of the integrator: `<h3 id="factory-integrator" lang="en">integrator</h3>`, `<p data-field="description" lang="en">Merge train. ...</p>`, `<p data-field="model"><span>Model:</span> <code data-value lang="en">sonnet</code></p>`, `<span>Hulpmiddelen:</span>` and `<code data-value lang="en">Read</code>` ...

## 7. Acceptance criteria map

| Criteria | Where |
|---|---|
| AC-1, AC-2, AC-3, AC-4, AC-5, AC-6 | [agent loader](225-agents-loader.md) 2 to 4; markup in 3 here |
| AC-7 | agent loader 5, 7; here 2, 6 |
| AC-8 | agent loader 5; here 2, 3 (`data-count`), 4, 6 |
| AC-9 | Paths and "Frozen" above; sections 1, 2 |
| AC-10 | section 1 (data only; tree, breadcrumb, switcher by the unchanged model), section 5 |
| AC-11 | sections 1 (see-also), 3 (overview) |
| AC-12 | sections 1 (`review`), 5 |
| AC-13 | sections 1, 5 |
| AC-14 | sections 3 (language marking), 4 |
| AC-15 | sections 2, 3 (ids; Skills markup unchanged) |
| AC-16 | section 5 (the check crawls `dist`) |
| AC-17 | section 3 (wrapping) |
| AC-18 | Frozen: no script, no dependency |
| AC-19 | post-merge; nothing to build |

## 8. Things in the repo that state a changed rule

Searched with `grep -rn` (reference, `/reference/`, `nl/reference`, "English only", "Dutch Reference", "five pages", `referenceIntro`). To update, by owner:

- QA, `tests/site/`: `pages.test.mjs` line 28 and 54 (`nl/reference` must not be built; the slug regexp) and line 194 (the fixture "parent reference has no nl page" no longer fails: the parent has a Dutch page, pick another parent), `routes.test.mjs` lines 55 to 58 (URL list and "no /nl/reference/"), `switcher.test.mjs` line 274 (Dutch Reference 404), `getting-started.test.mjs` line 108 (no body link to `/nl/reference/`: now valid), `wiki.test.mjs` lines 66, 229 (tree and link of Reference in Dutch), `reference.test.mjs` (Skills content now at `/skills/`; the Reference overview has a different body), `a11y.test.mjs` (page count 3 is now 6 pages plus Home).
- Developer, `apps/site/test/pages.test.mjs`, `ui.test.mjs`: assertions on the old Reference entry and on key sets.
- docs-writer, `README.md` lines 225 (Reference described English only and Dutch linking to English), 235 ("a Dutch Reference" listed as not built), 277 (`PLUGINS_DIR` reads skills only; agents too), 296 (the five pages that answer 200; now eleven pages). Outside this slice's Paths (README is not under `apps/site/`); the lead routes it.
- Architect, later: `contracts/188-page-tree.md` section 1 (initial array shows Reference English only with `alsoListedIn`), section 2.2 (the Dutch Reference link example), section 4 (registry keys), and `contracts/188-wiki-components.md` lines 63, 100, 101, 115, 119, 133 (Dutch Reference as an English link; the Reference contents list). A one-line "superseded in part by 225" note after the build, as for 156.
