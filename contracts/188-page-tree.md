# Contract 188 — Page tree: the one source for slugs, routes, navigation and language counterparts

Issue [#188](https://github.com/WimSuenens/agent-plugins/issues/188) · Requirement `docs/requirements/188-wiki-shell.md` · Builds on [156 site skeleton](156-site-skeleton.md) and [156 reference generator](156-reference-generator.md) · Siblings: [wiki components](188-wiki-components.md), [a11y landmarks](188-a11y-landmarks.md) · [ADR 0022](../docs/adr/0022-the-documentation-site-has-an-editorial-wiki-look.md)

## Paths

Paths:
- apps/site/src/data/pages.mjs
- apps/site/src/lib/pages.mjs
- apps/site/src/pages/
- apps/site/src/content/pages/
- apps/site/src/components/registry.mjs
- apps/site/astro.config.mjs
- apps/site/package.json
- apps/site/package-lock.json
- apps/site/test/pages.test.mjs
- tests/site/
shared: CONTEXT.md

`apps/site/src/pages/` holds, after this slice, exactly two files: `[...slug].astro` and `nl/[...slug].astro` (the three route files of 156, `index.astro`, `nl/index.astro` and `reference/index.astro`, are removed). The slice touches no `plugins/` and no `.github/` path: the deploy workflow runs `npm run build`, which already builds and checks everything below, and no new infrastructure is needed (Chromium is already installed in CI for the 156 check).

> Superseded in part by [225 reference section](225-reference-section.md): section 1 (the initial array: Reference is no longer English only and no longer carries `alsoListedIn`; Skills and Agents entries are added), section 2.2 (the Dutch Reference link example) and section 4 (the registry keys).

## 1. The seam: one data file

`apps/site/src/data/pages.mjs` exports `pages`, an array. It is data only: no import, no function. Adding a page is one edit to this array plus the page's content file (section 3). Entry shape:

| Field | Type | Meaning |
|---|---|---|
| `slug` | string | Path segment: `[a-z0-9]+(-[a-z0-9]+)*`. Home is `""` and is the only entry whose `parent` is `null`. Same slug in both languages. |
| `parent` | string or `null` | Slug of the parent entry. Top-level pages have `parent: ""` (Home). Nesting changes the navigation tree and the breadcrumb, never the URL (URLs are flat: one segment). |
| `title` | `{ en, nl? }` | Navigation and breadcrumb label per language. `title.en` is required for every entry. A page **exists in a language** when `title.<lang>` is a non-empty string. |
| `heading` | `{ en?, nl? }`, optional | The page `h1` and the `title` element's page part when it differs from the label (Home: label "Home" / "Thuis", heading "Agent plugins"). Defaults to `title`. |
| `source` | `"markdown"` or `"component"` | `markdown`: hand-written, one content file per language that exists (section 3). `component`: the body is an Astro component named by `component`. This is the hand-written or generated flag: the generated Reference is a `component` page whose body calls the generator; Home is a `component` page whose body comes from `i18n/ui.mjs`. |
| `component` | string | Required when `source` is `component`; a key of `apps/site/src/components/registry.mjs` (section 4). |
| `seeAlso` | string[], optional | Slugs of related pages, in display order. `""` is Home. |
| `review` | `{ nl?: "draft" or "reviewed" }`, optional | Review status of the Dutch page. A Dutch page with no value is `draft`: the safe default, so a new Dutch page shows its notice without an extra field. Setting `reviewed` is the one edit that removes the notice. |
| `alsoListedIn` | lang[], optional | Languages whose navigation tree lists this page although it is not built in them (see 2.2). Only `["nl"]` is used: the Reference. |

Initial content of the array (the worked example; order is the sibling order in the tree):

```js
export const pages = [
  { slug: "", parent: null, title: { en: "Home", nl: "Thuis" }, heading: { en: "Agent plugins", nl: "Agent plugins" },
    source: "component", component: "home", seeAlso: ["getting-started", "reference"], review: { nl: "draft" } },
  { slug: "getting-started", parent: "", title: { en: "Getting started", nl: "Aan de slag" },
    source: "markdown", seeAlso: ["reference", ""], review: { nl: "draft" } },
  { slug: "reference", parent: "", title: { en: "Reference" },
    source: "component", component: "reference", seeAlso: ["getting-started"], alsoListedIn: ["nl"] },
];
```

Home's review stays `draft` until the owner decides (open question 5 of the requirement): the contract works for either answer, because the notice follows the field alone.

## 2. Derived structures

`apps/site/src/lib/pages.mjs` is the only module that reads `pages.mjs`, validates it and derives from it. Components and routes call it; none holds a list of pages or writes a URL for another page (they use `url()` from 156 with a slug the module returns). Exports (the unit-test seam of the developer; QA tests the built output, not these):

```js
loadPages(entries = pages, { contentDir })   // validates (section 5), returns the model; throws on a fault
model.exists(slug, lang)        // title[lang] present
model.href(slug, lang)          // url(`${slug}/`) or url(`nl/${slug}/`); Home: url("") and url("nl/")
model.title(slug, lang)         // label
model.heading(slug, lang)       // h1 text
model.tree(lang)                // nested [{ slug, href, label, lang, current?: no, children }] for the language
model.breadcrumb(slug, lang)    // [{ slug, href, label }] Home first, the page last
model.seeAlso(slug, lang)       // [{ slug, href, label }], existing pages of that language only
model.counterpart(slug, lang)   // slug itself when it exists in the other language, else null
model.drafts()                  // sorted list of hrefs of Dutch pages whose review is not "reviewed"
```

### 2.1 URLs and routes (AC-3)

English page `/agent-plugins/<slug>/`, Dutch page `/agent-plugins/nl/<slug>/`, Home `/agent-plugins/` and `/agent-plugins/nl/`. `src/pages/[...slug].astro` and `src/pages/nl/[...slug].astro` emit one route per page that exists in that language (Home with an undefined `slug` param) from `getStaticPaths`; nothing else is routed. A page with no `title.nl` has no `/nl/<slug>/` route (no stub, no redirect). The slug `nl` is reserved (it would collide with the Dutch route tree).

### 2.2 Navigation tree (AC-5)

`tree(lang)` is the entries nested by `parent`, siblings in array order, Home as the root. An entry is listed in language L when it exists in L, **or** when L is in its `alsoListedIn`. A page listed but not built in L (the Dutch tree's Reference) links to the page that exists, which is the English page, and carries `lang="en"` and `hreflang="en"` on the link; its label is the English title (a `lang="en"` link with a Dutch word would misdeclare the language). Every other label is in the language of the page being read. A page not built in L and not in `alsoListedIn` is absent from L's tree (AC-16): the Dutch tree never links to a missing `/nl/` page.

### 2.3 Breadcrumb (AC-10)

`breadcrumb(slug, lang)` is Home, each ancestor from the top, then the page, labels in `lang`, hrefs in `lang`. Home's own breadcrumb is the single item Home. The component renders ancestors as links and the last item as text (see the components contract).

### 2.4 See-also (AC-13)

`seeAlso(slug, lang)` keeps a slug only when the page exists in `lang` (built, not merely listed); labels are `title[lang]`. A slug missing from the whole tree is a build error (section 5); a slug that exists only in the other language is dropped silently. With none left the result is empty and nothing is rendered.

### 2.5 Language counterpart (AC-14, AC-15, AC-16)

For the page `(slug, lang)` the switcher's option for language L is `href(slug, L)` when `exists(slug, L)`, else the Home of L (`/agent-plugins/` or `/agent-plugins/nl/`). The option for the page's own language is the page itself. Counterpart is by equal slug (decision from the requirement); there is no per-page counterpart field. The alternates `link rel="alternate" hreflang` pair in `head` appears on every page that exists in both languages (156 had it on the two Homes only) and on no page that exists in one.

### 2.6 Draft status (AC-21)

A Dutch page is `draft` unless `review.nl === "reviewed"`. `drafts()` lists the draft Dutch hrefs, and the build prints one line to the build log, once: `pages: dutch drafts: /agent-plugins/nl/ /agent-plugins/nl/getting-started/` (`none` when there are none). A value other than `draft` or `reviewed` is a build error. A `review` on an entry without `title.nl` is a build error (a status for a page that does not exist).

## 3. Content files and authoring (hand-written pages)

- Location: `apps/site/src/content/pages/<lang>/<slug>.md`, one per language the page exists in: `en/getting-started.md`, `nl/getting-started.md`. Format: Markdown, no front matter (the title is in the page tree; a front-matter `title` is ignored and has no effect).
- The body starts at `h2`. A level-1 heading in a content file is a build error (the layout renders the one `h1` from the page tree). Heading ids are the Markdown renderer's default slugs; the contents list reads them (components contract, section 4).
- No layout markup (AC-22). A content file holds prose, `h2`/`h3` headings, lists, code (fenced blocks and inline code) and links. The build fails, naming the file, when text outside code holds a `style=` or `class=` attribute, a `<div`, `<span` or `<style` tag, or a colour literal (`#` followed by 3, 4, 6 or 8 hex digits, `rgb(`, `hsl(`). All layout comes from the components and `tokens.css`.
- Internal links in content are written site-root relative, without the base: `[Reference](/reference/)`, Dutch content `[Getting started](/nl/getting-started/)`. A small hast plugin of the Sätteri Markdown processor (the same one that adds `tabindex` to code blocks, components contract section 8; `rehypePage.mjs`, registered through `markdown.processor` in `astro.config.mjs`, not `markdown.rehypePlugins`) prefixes the base, so the built link is `/agent-plugins/reference/` and ends in `/`. An author writes the `/nl/` prefix explicitly; none is added. The build fails on a body link whose path is not a page of the tree (and not a fragment or an external URL): the fragment and cross-page crawl itself is QA's test (AC-18).
- Choice of format (two-way door): Markdown through Astro's own renderer, because Dutch and English content are prose edited by the owner and an agent; an `.astro` content file invites layout markup. Rejected: MDX (components in content invite layout markup, one more dependency). Cost to undo: rename the files and add the integration; hours.
- Seed copy: Getting started English comes from the prototype page `getting-started` (the owner-approved copy in `prototype/147`, `prototype/content.py`); the step headings become `h2` "Add the marketplace", "Install the plugins you want", "Set up your repository, once", "Run your first command" (the numbering "1." is dropped: an ordered position comes from the document, and the contents list shows the order). Commands are code blocks, identical in English and Dutch. Every `/plugin:skill` in a code block must exist as `plugins/<plugin>/skills/<skill>/SKILL.md` (AC-19; QA's test reads the built page and the plugin tree). The prototype's links to pages that do not exist yet (`plugins`, `running`, `lean`, `factory`, `wayfinding`) are dropped from the text; only links to pages in the page tree remain. The Dutch page is the agent draft, status `draft`.

## 4. Component pages

`apps/site/src/components/registry.mjs` exports, per `component` key, `{ body, headings }`: `body` is the Astro component rendered in the page, `headings(lang)` returns the headings the contents list shows, `[{ depth: 2|3, id, text }]`. Keys: `home` (h2s "What this site is" and "Reference", ids stable and equal in both languages, `what` and `reference`) and `reference` (h2 per plugin with `id="<plugin>"` as in 156; one h3 per skill with `id="<plugin>-<skill>"`, so the generator's output is the only source of the list: AC-12). Adding a component page is two edits (the entry and the registry key); only markdown pages meet the one-edit bar of AC-2, which is the case the requirement names.

## 5. Build validation (AC-4)

`loadPages` fails the build with a message of the form `pages: <slug or "(home)">: <fault>`, naming the entry and the fault, for each of:

| Fault | Message ends with |
|---|---|
| duplicate slug | `duplicate slug` |
| slug does not match the pattern, or is `nl` | `invalid slug` / `reserved slug` |
| `parent` slug not in the tree (or `parent` missing on a non-Home entry, or a second Home, or a parent cycle) | `parent "<p>" does not exist` / `cycle` |
| a `seeAlso` slug not in the tree | `see-also "<s>" does not exist` |
| `title.en` missing | `missing English title` |
| a page exists in language L but its parent does not exist in L | `parent "<p>" has no <L> page` |
| `source: "markdown"` and the content file for a language that exists is missing | `missing content file <path>` (path relative to `apps/site/`) |
| a content file with no matching entry and language | `content file <path> has no page tree entry` |
| `source: "component"` with an unknown `component` | `unknown component "<c>"` |
| `alsoListedIn` names a language the page exists in | `alsoListedIn conflicts with title.<lang>` |
| level-1 heading, layout markup, or a broken body link in a content file | the file path and the fault (section 3) |
| two headings with the same id on one page | `duplicate heading id "<id>"` |

Messages hold no absolute path and no home directory. A valid tree builds; the same data with one fault, as a copy of the source (the requirement's fixture), makes `npm run build:site` exit non-zero with that line in its output.

## 6. Worked example

Fixture A (AC-2): add to `pages.mjs` the entry `{ slug: "credits", parent: "", title: { en: "Credits" }, source: "markdown" }` and the file `src/content/pages/en/credits.md` holding `## Thanks` and a paragraph. Build: `/agent-plugins/credits/` exists (200, `lang="en"`); the English tree lists Credits under Home with its link; its breadcrumb is `Home / Credits`; `/agent-plugins/nl/credits/` does not exist; the English page's Dutch switcher option goes to `/agent-plugins/nl/`; the Dutch tree has no Credits entry. Add `nl: "Dank"` to its `title` and `src/content/pages/nl/credits.md`: `/agent-plugins/nl/credits/` exists, shows the draft notice, both switchers point at each other, and the Dutch tree lists "Dank". No other source file changed.

Fixture B (AC-4): `{ slug: "x", parent: "nowhere", ... }` fails with `pages: x: parent "nowhere" does not exist`.

Switcher on English Reference: Dutch option `href="/agent-plugins/nl/"`. On `/agent-plugins/nl/getting-started/`: English option `href="/agent-plugins/getting-started/"`.

## 7. Acceptance criteria map

| Criteria | Where |
|---|---|
| AC-1, AC-2 | sections 1, 2, 6 (components contract sections 2 to 6 for the rendering) |
| AC-3 | section 2.1 |
| AC-4 | section 5 |
| AC-5, AC-16 | section 2.2 |
| AC-10 | section 2.3 |
| AC-13 | section 2.4 |
| AC-14, AC-15, AC-17 | section 2.5 (the script of 156 section 6 is unchanged: store on choice, redirect only at the English Home) |
| AC-18 | sections 3, 5 (build-side) and QA's crawl |
| AC-19, AC-20, AC-22 | section 3 |
| AC-21 | sections 1, 2.6 and components contract section 5 |

## 8. Things in the repo that state a changed rule

Searched with `grep -rn` for the old facts (route files, "Nothing else is built", top bar Reference label, Toc, three pages). To update, with the owner of each:

- `contracts/156-site-skeleton.md` section 2 (source layout lists the three route files), section 3 ("Nothing else is built"), section 4 (top bar Reference link text on Dutch pages), section 9 (breadcrumb markup, the contents list of the Reference): this contract and the components contract supersede them; the architect adds a one-line "superseded in part by 188" note to the 156 files after the build (a later edit, not in this slice's Paths for the developer).
- `contracts/156-reference-generator.md` Paths names `apps/site/src/pages/reference/index.astro`; the page moves to the registry body component, and the generator seam `loadSkills()` is unchanged.
- `tests/site/routes.test.mjs` line 53 (`htmlFiles(dist)` equals three files), `tests/site/switcher.test.mjs` (Dutch Home link "Naslag"), `tests/site/a11y.test.mjs` (page count 3, `reference/index.html` copies still valid): QA's to update.
- `CONTEXT.md` line 140 (Documentation site) stays true; the glossary terms "page tree" and "draft page" are added to it in this slice (hence `shared: CONTEXT.md`).
