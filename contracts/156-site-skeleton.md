# Contract 156 — Site skeleton: routes, pages, language switcher, look

Issue [#156](https://github.com/WimSuenens/agent-plugins/issues/156) · Requirement `docs/requirements/156-live-skeleton.md` · [ADR 0022](../docs/adr/0022-the-documentation-site-has-an-editorial-wiki-look.md) · Siblings: [reference generator](156-reference-generator.md), [accessibility check](156-a11y-check.md), [deploy workflow](156-deploy-workflow.md)

## Paths

Paths:
- apps/site/
- .github/workflows/site.yml
- tests/site/
shared: none

The slice touches no `plugins/` path. `apps/site/` is the developer's (the workflow file is devops'; `tests/site/` is QA's). `docs/agents/factory.md` has no ownership row for `apps/site/`; the lead should add one next to `apps/obeya/` (proposal, not mine to write).

## 1. Stack and commands

Astro, static output, in `apps/site/`, npm with a committed `package-lock.json`, Node 22. The developer records the Astro major installed in the result; the lockfile pins it.

Seams (all run from `apps/site/`):

| Command | Behaviour |
|---|---|
| `npm ci` | installs from the lockfile |
| `npm run build:site` | `astro build` only; output in `$SITE_OUT_DIR` (default `dist`) |
| `npm run build` | `build:site`, then `node scripts/a11y-check.mjs --dist $SITE_OUT_DIR` ([contract](156-a11y-check.md)); exit status is the check's. This is the command the workflow runs. |
| `npm run check:a11y` | the check alone, on an existing build |
| `npm test` | `node --test test/*.test.mjs`: the developer's unit tests |

Environment seams (read by `astro.config.mjs` and the generator; QA uses them for fixtures):

- `SITE_BASE`: base path, default `/agent-plugins`. A value without a leading slash or with a trailing slash is a build error naming the variable.
- `SITE_OUT_DIR`: build output folder, default `dist`.
- `PLUGINS_DIR`: where skills are read from ([generator contract](156-reference-generator.md)).

`site` is `https://wimsuenens.github.io`. `trailingSlash: "always"`, `build.format: "directory"`, so every page is `<route>/index.html` and every internal link ends in `/`.

`apps/site/.gitignore` holds `dist/`, `.astro/` and `node_modules/`. `package.json` is `private: true`.

## 2. Source layout

```
apps/site/
  package.json  package-lock.json  astro.config.mjs  tsconfig.json  .gitignore
  scripts/a11y-check.mjs
  src/
    pages/index.astro            English Home            -> /agent-plugins/
    pages/nl/index.astro         Dutch Home              -> /agent-plugins/nl/
    pages/reference/index.astro  Reference               -> /agent-plugins/reference/
    layouts/Base.astro           html shell, head, skip link, top bar, main slot
    components/TopBar.astro  LangSwitcher.astro  Breadcrumb.astro  Toc.astro
    i18n/ui.mjs                  UI strings: `en` and `nl` objects with the same keys
    lib/skills.mjs               the generator (own contract)
    styles/tokens.css  base.css
  test/skills.test.mjs  test/ui.test.mjs      developer's unit tests
```

Internal links are built with one helper `url(path)` that prefixes the base; no component writes `/agent-plugins/` literally.

## 3. Routes

| URL (under `https://wimsuenens.github.io`) | Page | `html lang` |
|---|---|---|
| `/agent-plugins/` | Home, English | `en` |
| `/agent-plugins/nl/` | Home, Dutch | `nl` |
| `/agent-plugins/reference/` | Reference (one page, all plugins) | `en` |

Nothing else is built (no `/nl/reference/`, no 404 page, no index at `/nl/reference/`). A request outside the base (for example `/`, `/nl/`, `/reference/`) is not served by the build output.

Decision (two-way): **one Reference page at `/reference/`**, one `h2` group per plugin. Rejected: one page per plugin (18 entries are short; a page per plugin adds routes, breadcrumbs and a plugin index with nothing to show yet). Cost to undo: split the page and keep `/reference/` as the index, no link breaks.

## 4. Page structure (every page)

Order inside `body`: skip link, `header` (top bar), `main`, `footer`.

- `html` carries `lang` (`en` or `nl`). `head` holds a non-empty unique `title`, `meta charset`, `meta viewport`, the stylesheet link (base-prefixed), the one inline script (section 6).
- Skip link: `<a class="skip-link" href="#main">` is the first focusable element; `main` is `<main id="main" tabindex="-1">`. Text: "Skip to content" / "Naar de inhoud".
- Top bar: `<header data-test="topbar">` holds, in this order,
  1. the site name, a link to the Home of the page's language (`/agent-plugins/` for `en` pages, `/agent-plugins/nl/` for Dutch Home);
  2. `<nav aria-label="Main">` with one link: Reference (`/agent-plugins/reference/`); on Dutch Home the link text is Dutch ("Naslag") and carries `hreflang="en"`;
  3. the language switcher (section 5).
- Exactly one `h1` per page, no skipped heading level, no `div` with a click handler.
- Wide content never forces horizontal scroll at 320 CSS px (the top bar wraps instead; items never overlap or clip).

## 5. Language switcher

Markup, the same on every page:

```html
<nav data-lang-switcher aria-label="Language">   <!-- Dutch pages: aria-label="Taal" -->
  <a href="/agent-plugins/" data-lang="en" hreflang="en" lang="en" aria-current="true">English</a>
  <a href="/agent-plugins/nl/" data-lang="nl" hreflang="nl" lang="nl">Nederlands</a>
</nav>
```

- Two real links, labels in their own language. `aria-current="true"` is on the option matching the page's `html lang`; the other has no `aria-current`. A page with no Dutch twin (Reference) marks English current and its Dutch link goes to Dutch Home (AC-4).
- Works without script: plain links.
- Keyboard: both links are in the tab order after the main nav; focus ring per section 8.

Stored choice (decision from the requirement, pinned): `localStorage` key `site-lang`, value `en` or `nl`. Any other value is treated as absent. A thrown storage error (private mode) is swallowed: the site then behaves as with no stored choice.

## 6. The one script

Exactly one `script` element per page, inline, in `head`, the same text on every page except for the base-path constant, a few lines, no framework, no external file. It does two things:

1. **Store on choice.** A delegated `click` listener on `document` for `a[data-lang]` writes `localStorage["site-lang"] = <data-lang>` before navigation follows the link. Nothing is written on load.
2. **Redirect only when entering at English Home.** When `location.pathname` equals `<base>/` exactly and the stored value is `nl`, it first sets `data-lang-pending` on `document.documentElement` (CSS: `html[data-lang-pending] body { visibility: hidden }`, so no English content paints) and then calls `location.replace("<base>/nl/")`. On every other URL, and when the stored value is `en`, absent or invalid, it does nothing.

Expected behaviour (the table QA derives AC-6 to AC-10 from):

| Stored | Request | Result |
|---|---|---|
| none | `/agent-plugins/` | English Home, no redirect, storage still empty |
| none | click Nederlands | lands on `/agent-plugins/nl/`, storage `nl` |
| `nl` | click English (from `/nl/`) | lands on `/agent-plugins/`, storage `en`, stays |
| `nl` | `/agent-plugins/` fresh load | ends on `/agent-plugins/nl/` after at most 2 navigations; history entry replaced (Back does not return to the English root) |
| `en` | `/agent-plugins/nl/` direct | Dutch Home stays |
| `nl` | `/agent-plugins/reference/` direct | Reference, no redirect |
| `nl`, scripts disabled | `/agent-plugins/` | English Home with all content and working links |

No other script exists on any page (no hydration islands, no analytics).

## 7. Home pages

Both Homes have the same structure; the strings come from `src/i18n/ui.mjs` (`en` and `nl` objects, same keys, a developer unit test asserts equal key sets and non-empty values):

- `h1`: site title ("Agent plugins" / "Agent plugins").
- `p.lede`: the hook, one sentence. English: "Agents do the work; you decide only what can't be undone." Dutch: "Agenten doen het werk; jij beslist alleen over wat niet terug te draaien is."
- `h2` "What this site is" / "Wat deze site is": one short paragraph naming the marketplace plugins.
- `h2` "Reference" / "Naslag": one paragraph and a link to `/agent-plugins/reference/`.

Same two `h2`, same one link to Reference in both languages. The wording may be adapted; the Dutch is a draft until the owner reviews it (H-2). Each Home has `link rel="alternate" hreflang` to the other.

## 8. Look: tokens, contrast, keyboard, motion

- `src/styles/tokens.css` defines `:root` custom properties only: `--color-*`, `--font-*`, `--size-*`, `--space-*`, `--measure` (about 70ch). No colour literal (`#hex`, `rgb(`, `hsl(`, named colour) exists anywhere under `apps/site/src/` outside `tokens.css`, including component `<style>` blocks; `transparent`, `currentColor` and `inherit` are allowed.
- One light colour scheme (`color-scheme: light`). Dark mode is out of scope.
- Type: a system serif stack for headings and body (Charter, Iowan Old Style, Georgia, serif); a system sans stack for the top bar and the switcher is allowed. No font file, so no font request.
- One reading column (`max-width: var(--measure)`), sections separated by `border-top` rules, no boxes or cards.
- Contrast: every text pair at least 4.5:1, every interface part at least 3:1, in every state the pages have: body, headings, links (default, visited), top bar, switcher (normal, hover, current), code, skip link, focus ring.
- Focus: every focusable element shows a visible outline of at least 3:1 against its neighbour; `outline: none` is never used without a replacement.
- Motion: none. No `transition`, `animation` or `scroll-behavior: smooth` is defined, which satisfies AC-22 under both preferences.

## 9. Reference page (what the page shows; data from the generator)

Route `/agent-plugins/reference/`, `html lang="en"`. Structure:

- `nav[aria-label="Breadcrumb"]`: `ol` with Home (link to `/agent-plugins/`) then "Reference" (`aria-current="page"`).
- `h1` "Reference". One intro `p`.
- `nav[aria-label="On this page"]`: a list of links, one per plugin, `href="#<plugin>"`.
- Per plugin (folder name, alphabetical): `<section>` with `<h2 id="<plugin>">`; the heading text is the plugin name. Per skill (by `name`, alphabetical): the entry markup below.

Entry markup (the seam QA reads; the data attributes are stable, the styling is free):

```html
<article data-skill-entry data-plugin="factory" data-name="run">
  <h3>run</h3>
  <p><code data-field="command">/factory:run</code> <span data-field="manual">manual command</span></p>
  <p data-field="description">Run the software factory as its lead — one cycle ...</p>
  <p data-field="argument-hint">Argument hint: <code>[idea | #map | #slice]</code></p>
</article>
```

- `data-field="manual"` exists exactly when the skill's `disable-model-invocation` is boolean `true`.
- `data-field="argument-hint"` exists exactly when the skill has a non-empty `argument-hint`; no empty label otherwise.
- `data-field="description"` text content equals the parsed frontmatter `description` after trimming (no markdown rendering; backticks stay literal, characters are escaped, not entity-encoded on screen).
- Count of `[data-skill-entry]` equals the count of source files ([generator contract](156-reference-generator.md)).

## 10. Worked example: Home and switcher

Request `GET /agent-plugins/nl/` returns 200, `<html lang="nl">`, one `h1`, one `p.lede` holding the Dutch hook, two `h2`, one link to `/agent-plugins/reference/`, one inline script. Its `nav[data-lang-switcher]` has `Nederlands` with `aria-current="true"` and `English` linking to `/agent-plugins/`. A request for `GET /nl/` (no base) returns 404 from a static server rooted at the build output served under the base.

## 11. Acceptance criteria map

| Criteria | Where |
|---|---|
| AC-1, AC-2, AC-4 | sections 3, 7 |
| AC-3 | sections 1, 2 (`url()` helper, `trailingSlash`), 3 |
| AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-12 | sections 5, 6 |
| AC-11, AC-19, AC-20, AC-21, AC-22 | sections 4, 8 |
| AC-23 | sections 4, 5 |
| AC-18 | section 9 |
| AC-13 to AC-17 | [reference generator](156-reference-generator.md), section 9 |
| AC-24, AC-25 | [accessibility check](156-a11y-check.md), section 1 |
| AC-26, AC-27 | [deploy workflow](156-deploy-workflow.md) |
