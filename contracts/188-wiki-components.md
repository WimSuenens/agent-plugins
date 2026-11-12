# Contract 188 — Wiki shell components: navigation tree, breadcrumb, contents, see-also, draft notice, code blocks

Issue [#188](https://github.com/WimSuenens/agent-plugins/issues/188) · Requirement `docs/requirements/188-wiki-shell.md` · Siblings: [page tree](188-page-tree.md), [a11y landmarks](188-a11y-landmarks.md) · Builds on [156 site skeleton](156-site-skeleton.md) (its look rules, the one script and the switcher stay) · [ADR 0022](../docs/adr/0022-the-documentation-site-has-an-editorial-wiki-look.md)

## Paths

Paths:
- apps/site/src/layouts/Base.astro
- apps/site/src/layouts/Page.astro
- apps/site/src/components/TopBar.astro
- apps/site/src/components/LangSwitcher.astro
- apps/site/src/components/PageTree.astro
- apps/site/src/components/Breadcrumb.astro
- apps/site/src/components/Contents.astro
- apps/site/src/components/SeeAlso.astro
- apps/site/src/components/DraftNotice.astro
- apps/site/src/components/Home.astro
- apps/site/src/components/ReferenceBody.astro
- apps/site/src/components/Toc.astro
- apps/site/src/lib/rehypePage.mjs
- apps/site/src/i18n/ui.mjs
- apps/site/src/styles/tokens.css
- apps/site/src/styles/base.css
- apps/site/astro.config.mjs
- apps/site/test/ui.test.mjs
- tests/site/
shared: none

`Toc.astro` is deleted (replaced by `Contents.astro`); it stays in `Paths:` so the deletion is the developer's to make. `astro.config.mjs` is listed in both this and the page-tree contract (markdown options and the rehype step).

## 1. Page shape (every page, both languages)

`src/layouts/Page.astro` wraps `Base.astro`; both route files render a page only through it. Source order in `body`:

1. skip link (`a.skip-link`, first focusable; the text is the `ui` string; `href="#main"`),
2. `header[data-test="topbar"]` (156 section 4, with the changes in section 7),
3. `nav[data-nav="pages"]` (the navigation tree, section 2),
4. `main#main[tabindex="-1"]`, which holds, in order: breadcrumb (section 3), the draft notice when the page is a draft Dutch page (section 5), the one `h1`, the contents list when it has entries (section 4), the body (Markdown or component), the see-also list when it has entries (section 6),
5. `footer`.

Exactly one `main` and one `h1` per page. The `h1` text is `model.heading(slug, lang)`; content files and component bodies never produce an `h1`. The tree sits before `main` in the source so the skip link, which jumps past top bar and tree to `main`, still comes first, and so a keyboard or screen-reader reader meets the tree once, in a predictable place. (The requirement's order "skip link, top bar, main" is kept for what is inside the reading flow; the tree is navigation, not content.)

`title` element: Home keeps the 156 strings (`ui.title`); every other page `<heading> - Agent plugins`. `html lang` is the page's language. `link rel="alternate"` per [page tree contract](188-page-tree.md) section 2.5.

## 2. Navigation tree (AC-5 to AC-9, AC-24, AC-25)

```html
<nav data-nav="pages" aria-label="Pages">          <!-- Dutch: "Pagina's" -->
  <ul>
    <li><a href="/agent-plugins/" aria-current="page">Home</a>
      <ul>
        <li><a href="/agent-plugins/getting-started/">Getting started</a></li>
        <li><a href="/agent-plugins/reference/">Reference</a></li>
      </ul>
    </li>
  </ul>
</nav>
```

On `/agent-plugins/nl/getting-started/`: label "Thuis" for Home, "Aan de slag" with `aria-current="page"`, and `<a href="/agent-plugins/reference/" lang="en" hreflang="en">Reference</a>` (page tree contract 2.2).

- One list item per entry of `model.tree(lang)`; nested `ul` for children; every entry is a real link to an existing page of the build.
- Exactly one entry carries `aria-current="page"`, the page being read, on the `a`. On a page whose own tree entry is a fallback (cannot happen: a fallback entry has no page of its own in that language) nothing changes.
- No client script, no `details`, no state; no `transition` or `animation` anywhere in the tree. The link states (default, visited, hover, current, focus) use tokens and meet 4.5:1 text and 3:1 interface contrast; the current entry is marked by more than colour (a rule or weight), not by colour alone.
- Phone presentation (decision of open question 2): **always open and in the flow**, above `main`, on viewports narrower than 48rem; at 48rem and wider the tree is a column beside the 70-character reading column (CSS grid on a wrapper, the same markup). Entries wrap, never clip, never overlap, and the page never scrolls horizontally at 320px; to keep the tree short on a phone it is set in the small sans size with tight spacing, siblings may flow inline. Rejected: `details`/`summary` closed by default (a closed-on-phone and open-on-desktop state cannot be set without script, and the requirement forbids it; one that is open by default gains nothing); a menu button (needs script or a hidden checkbox hack that is not a real button). Two-way door; cost to undo: swap the markup and one CSS block, hours. Trigger to reopen: the tree reaches more than 8 entries (a phone then spends more than a screen on it), the first later slice that adds narrative pages; the answer then is `details`/`summary` open by default with the summary hidden at 48rem and wider.

## 3. Breadcrumb (AC-10)

```html
<nav data-nav="breadcrumb" aria-label="Breadcrumb">          <!-- Dutch: "Kruimelpad" -->
  <ol>
    <li><a href="/agent-plugins/nl/">Thuis</a></li>
    <li aria-current="page">Aan de slag</li>
  </ol>
</nav>
```

Items come from `model.breadcrumb(slug, lang)`: Home, ancestors, the page. All but the last are links; the last is plain text with `aria-current="page"`. Home's breadcrumb is the single item `<li aria-current="page">Home</li>` (every page has the nav, so the a11y check has one rule; Home shows only itself). Props: `{ slug, lang }`; the component never receives a hand-written trail. The 156 Reference breadcrumb (hard-coded "Home / Reference") is removed.

## 4. Contents list (AC-11, AC-12)

`src/components/Contents.astro`, props `{ headings, lang }` where `headings` is `[{ depth: 2|3, id, text }]` in document order. Markdown pages get it from the renderer's own heading list (the ids are the ids in the rendered page, so a link cannot point at a missing id); component pages get it from the registry's `headings(lang)` (page tree contract section 4).

```html
<nav data-nav="contents" aria-label="On this page">          <!-- Dutch: "Op deze pagina" -->
  <ol>
    <li><a href="#add-the-marketplace">Add the marketplace</a></li>
    <li><a href="#install-the-plugins-you-want">Install the plugins you want</a>
      <ol><li><a href="#if-the-install-fails">If the install fails</a></li></ol>
    </li>
  </ol>
</nav>
```

- One link per `h2` and `h3`, in order, `h3` nested under the preceding `h2` (an `h3` before any `h2` is listed at top level); each `href="#<id>"` with that `id` present on the heading in `main`. Nothing hand-listed.
- With no `h2` on the page the component renders nothing: no `nav`, no heading, no empty list. A visible label for the list is not a heading element (it must not enter the contents or the heading outline); the accessible name is the `aria-label`.
- The generated Reference lists each plugin `h2` (`#<plugin>`) with its skills as nested `h3` (`#<plugin>-<skill>`): a new plugin group appears with no other edit (AC-12, together with 156 AC-16). The navigation tree and breadcrumb of the Reference do not change (they list the page). The 156 expectation `nav[aria-label="On this page"] a[href="#<plugin>"]` holds unchanged.
- The Reference `h2`/`h3` of 156 gain no hand-listed ids; ids come from the generator's data in one place (`ReferenceBody.astro` and the registry `headings` read the same function so they cannot drift).

## 5. Draft notice (AC-21)

`src/components/DraftNotice.astro`, shown only on a Dutch page whose `review.nl` is not `reviewed`; props `{ lang }`. Markup: one `p[data-draft-notice]` in the page language, before the `h1`: Dutch text "Deze vertaling is een concept en is nog niet door de eigenaar gecontroleerd." (a draft sentence; the owner may reword it, the element and the rule are the contract). No notice on English pages and none on a `reviewed` Dutch page. The notice is plain text: it uses tokens, meets 4.5:1 and is distinguished by a rule or border, not by colour alone, and is not a `role="alert"`.

## 6. See-also (AC-13)

```html
<nav data-nav="see-also" aria-label="See also">          <!-- Dutch: "Zie ook" -->
  <ul><li><a href="/agent-plugins/reference/">Reference</a></li></ul>
</nav>
```

Items come from `model.seeAlso(slug, lang)`; labels in the page language, links to that language's page. Rendered after the body, at the end of `main`; with no items, nothing is rendered. A visible label, if any, is not a heading. On `/agent-plugins/nl/getting-started/` the list holds Thuis only (Reference is not a Dutch page, so it is left out). Getting started and Home show at least one entry in each language.

## 7. Top bar and switcher (changes to 156 sections 4 and 5)

- The top bar keeps `header[data-test="topbar"]` with site name, `nav[data-nav="site"][aria-label="Main"]` (Dutch "Hoofdmenu"; the name is unchanged from 156) and the language switcher with `data-nav="language"` added next to `data-lang-switcher`. Its one link is Reference, built from the same model data as the tree entry; on Dutch pages it is the English Reference with `lang="en"` and `hreflang="en"` and the English label "Reference" (156 had "Naslag" with `hreflang="en"`; the label changes for the reason in 2.2 of the page tree contract). The site-name link goes to the Home of the page's language.
- Switcher markup, `aria-current="true"` marking, labels, `hreflang`, the stored-choice key and the one inline script are unchanged. Only the hrefs change: each option is the counterpart per page tree contract 2.5 and the option for the current language is the current page's own URL.
- Every `nav` on a page has a distinct accessible name: Main, Language, Pages, Breadcrumb, On this page, See also (Dutch: Hoofdmenu, Taal, Pagina's, Kruimelpad, Op deze pagina, Zie ook). The names come from `i18n/ui.mjs`; both objects keep equal key sets (156 developer test). The six stable hooks `data-nav="site|language|pages|breadcrumb|contents|see-also"` are the seam the accessibility check reads ([a11y landmarks](188-a11y-landmarks.md)).

## 8. Code blocks and content styling (AC-22 to AC-24)

- Markdown renders with `markdown.syntaxHighlight: false` in `astro.config.mjs`: the highlighter writes inline `style` attributes with colour literals onto the `pre`, which would break AC-22 and AC-24 ("tokens only"). Code is plain `pre > code`, styled by `base.css` from tokens.
- `src/lib/rehypePage.mjs` is one small rehype step, registered in `astro.config.mjs`: it (a) sets `tabindex="0"` on every `pre` (a scrollable region must be keyboard-focusable; axe `scrollable-region-focusable`), and (b) prefixes the base path to the site-root links of content (page tree contract section 3). It adds no class, no `style`, no script.
- `pre`: `overflow-x: auto`, `max-width: 100%`, never widens the page; text at least 4.5:1 on its background; a visible focus outline (3:1) like every focusable element. The page's `overflow-wrap: anywhere` of 156 must not break a command mid-token in a `pre` (use `white-space: pre`); at 320px the document width still equals the viewport width.
- Lists, `blockquote` and a note in prose use plain Markdown; there is no component syntax in content.
- No colour literal anywhere under `apps/site/src/` outside `tokens.css` (156 section 8); new tokens for the tree, rule and notice are added there. `prefers-reduced-motion: reduce` and no-preference both see no `transition`/`animation`/smooth scrolling (the tree has none). One reading column of about 70 characters (`--measure`); the tree column at 48rem and wider is outside that measure and does not narrow it.

## 9. Worked example: `/agent-plugins/nl/getting-started/`

`<html lang="nl">`; skip link; top bar with "Agent plugins" (to `/agent-plugins/nl/`), Main nav with Reference (`lang="en"`), switcher with Nederlands current and English linking to `/agent-plugins/getting-started/`; `nav[data-nav="pages"]` as in section 2 with "Aan de slag" current; `main` holding breadcrumb `Thuis / Aan de slag`, the draft notice, `h1` "Aan de slag", the contents list of the four `h2` steps, four `h2` with code blocks identical to English, and the see-also list with Thuis. Names of the navs are all different; one `main`; one `script`.

## 10. Acceptance criteria map

| Criteria | Where |
|---|---|
| AC-5, AC-6, AC-7, AC-8, AC-9 | sections 2, 7 |
| AC-10 | section 3 |
| AC-11, AC-12 | section 4 |
| AC-13 | section 6 |
| AC-14, AC-15, AC-16 | section 7 (hrefs) and [page tree](188-page-tree.md) 2.5 |
| AC-19 to AC-22 | [page tree](188-page-tree.md) section 3 and section 1 here |
| AC-21 | section 5 |
| AC-23 | section 8 |
| AC-24, AC-25 | sections 1, 2, 5, 8 |
| AC-9, AC-26, AC-27 | [a11y landmarks](188-a11y-landmarks.md) |

## 11. Things in the repo that state a changed rule

`grep -rn` for the changed facts found: `contracts/156-site-skeleton.md` sections 4 (Dutch Reference label), 9 (hard-coded breadcrumb, Toc list), `tests/site/switcher.test.mjs` and `tests/site/routes.test.mjs` (Dutch top-bar link text, the three-file route list), `tests/site/reference.test.mjs` line 229 and 232 (contents nav name and links: still valid, the list gains nested `h3` links). QA updates its tests; the 156 contracts get a note after the build.
