# 188 — Wiki shell: navigation tree, contents and the first hand-written page, in English and Dutch

Slice: [#188](https://github.com/WimSuenens/agent-plugins/issues/188) · Map: [#146](https://github.com/WimSuenens/agent-plugins/issues/146) · Builds on: [156 live skeleton](156-live-skeleton.md) (its criteria and test conventions still hold and are not repeated; where this slice changes one, it is named below) · Look: [ADR 0022](../adr/0022-the-documentation-site-has-an-editorial-wiki-look.md)

## User outcome

A visitor on https://wimsuenens.github.io/agent-plugins/ sees, on every page, a navigation tree that lists every page, a breadcrumb trail, a contents list of the page's own headings and see-also links. The tree covers Home, the hand-written Getting started page and the generated Reference, in English at the root and in Dutch under `/nl/`. Switching language on any page goes to that page's counterpart, or to the other language's Home when none exists. Getting started is the first narrative page, in English and Dutch, seeded from the owner-approved prototype copy; the Dutch is an agent draft the owner reviews.

This serves the map's Destination: a wiki-like bilingual site where a newcomer can follow the pages and start, with narrative pages hand-written and reference pages generated.

## Terms used here

- **Page tree**: the one source that lists every page: its slug, parent, title per language, see-also slugs and (for Dutch pages) review status. The navigation tree, breadcrumbs, URLs, language counterparts and see-also links are all derived from it. Generated Reference pages enter it from the generator's output, not from a hand-kept list.
- **Slug**: the page's path segment. English page URL `/agent-plugins/<slug>/`, Dutch page URL `/agent-plugins/nl/<slug>/`; Home is the empty slug. A page has the same slug in both languages.
- **Counterpart**: the same slug in the other language.
- **Navigation tree**: the list of every page of the current language, nested by parent, shown on every page.
- **Contents list**: links to the headings of the current page.
- **See-also**: a short list of related pages shown at the end of a page.
- **Draft**: a Dutch page whose review status in the page tree is not `reviewed`.

## Acceptance criteria

QA checks these against the built output served under `/agent-plugins/`, with a browser-driven test where behaviour needs one. Fixtures that add or remove a page work on a copy of the source, never on the real pages.

### A. The page tree is the single source (Under test: slugs and navigation from one page tree)

**AC-1 One page tree drives every derived structure.**
Given the page tree lists Home, Getting started and Reference,
when the site is built,
then the routes, the navigation tree, each breadcrumb, each see-also list and each language counterpart on the built pages agree with the page tree entry for that page, and no component or page file holds its own list of pages or its own URL string for another page.

**AC-2 Adding one page is one edit.**
Given a fixture that adds one new page to the page tree (an English entry and its content file, nothing else),
when the site is rebuilt,
then the page is served at `/agent-plugins/<slug>/`, appears in the English navigation tree under its parent, has its breadcrumb, and no other source file was changed. And given the fixture also adds the Dutch content, then `/agent-plugins/nl/<slug>/` exists and both language switchers point at each other.

**AC-3 URLs follow the scheme.**
Given the built site,
then English pages are at `/agent-plugins/`, `/agent-plugins/getting-started/` and `/agent-plugins/reference/`; Dutch pages are at `/agent-plugins/nl/` and `/agent-plugins/nl/getting-started/`; every internal link ends in `/` and starts with `/agent-plugins/` (156 AC-3 still holds). No page exists at a slug that is not in the page tree.

**AC-4 A broken page tree fails the build.**
Given a fixture with a duplicate slug, a parent that does not exist, or a see-also slug that does not exist,
when the site is built,
then the build fails and its output names the entry and the fault.

### B. Navigation tree (Under test: fits 320px, keyboard, landmarks)

**AC-5 The navigation tree lists every page of the current language, on every page.**
Given each built page in each language,
when the page is read,
then it holds one navigation tree listing every page of the page tree in that language: Home, Getting started and Reference in English; Home, Getting started and Reference in Dutch (the Dutch Reference entry links to the English Reference page, keeps the English label "Reference", and carries `lang="en"` and `hreflang="en"` on the link, because Reference is not translated in this slice). Entries are real links to existing pages, nested by the page tree's parents, and the labels are in the page's language, except that Dutch Reference entry.

**AC-6 The current page is marked.**
Given each built page,
when its navigation tree is read,
then exactly one entry carries `aria-current="page"` and it is the entry for the page being read; for a page not in the tree this cannot happen (see AC-4).

**AC-7 The navigation tree is operable with the keyboard and works without script.**
Given only the keyboard and scripts disabled,
when the visitor tabs through a page,
then every entry of the tree is reachable in reading order, activated with Enter, shows a visible focus indicator (3:1, 156 AC-21), and no focus trap exists. The tree adds no client script (156 AC-12 still holds: the language switcher's script is the only one).

**AC-8 The navigation tree fits a 320px phone.**
Given a viewport 320 CSS pixels wide, English and Dutch, every page,
when the page is shown,
then the tree is reachable (either shown in the flow or behind a control that is a real button or `details`/`summary` and is operable with the keyboard), no entry is clipped or overlaps another, and the document width equals the viewport width (no horizontal scrolling of the page).

**AC-9 Landmarks: one navigation landmark per purpose, each labelled.**
Given each built page,
when its landmarks are listed,
then the top bar, the page navigation tree, the breadcrumb trail and the contents list are each a `nav` with its own distinct accessible name in the page's language (for example "Site", "Pages", "Breadcrumb", "On this page"; the see-also list may be a `nav` with its own name or a labelled section), no two `nav` share a name, there is exactly one `main`, and the skip link (156 AC-21) still comes first.

### C. Breadcrumbs, contents and see-also

**AC-10 Every page has a breadcrumb trail built from the page tree.**
Given each built page,
when its breadcrumb is read,
then it lists Home, then each ancestor in the page tree, then the page itself, in the page's language; ancestors are links, the last item is plain text marked `aria-current="page"`; Home carries a breadcrumb that shows only itself: one item, the Home label, plain text marked `aria-current="page"`, no links. The breadcrumb on a Dutch page links to Dutch pages.

**AC-11 The contents list is built from the page's headings.**
Given a page with `h2` and `h3` headings,
when the built page is read,
then its contents list holds one link for each `h2` and `h3` of the main content, in order, nested `h3` under `h2`, each linking to an `id` that exists on that heading; and no entry is hand-listed. Given a fixture that adds a heading to the content, then the contents list gains the entry on rebuild with no other edit. A page with no `h2` shows no empty contents list (no empty `nav`, no empty heading).

**AC-12 The generated Reference's contents list follows the generator.**
Given a fixture that adds a skill under a plugin that has no skills yet (a new plugin group),
when the site is rebuilt touching no file other than that SKILL.md and its plugin folder,
then the Reference page's contents list gains that plugin group and the heading id works, and the navigation tree and breadcrumb for Reference are unchanged (they list the page, not its skills). (This is the proof that generated pages need no hand-kept list: 156 AC-16 plus this.)

**AC-13 See-also links come from the page tree and stay inside the site.**
Given a page whose page tree entry lists see-also slugs,
when the built page is read,
then it shows a see-also list with one link per slug, labelled with each page's title in the page's language, pointing at that language's page. A slug that has no page in the page's language is left out of the list (never a link to a missing page) and, when none remain, no see-also list is shown. Getting started and Home each show at least one see-also link in each language.

### D. Language switching (Under test: counterpart or Home; no 404; no dead link)

**AC-14 The switcher goes to the counterpart page.**
Given each page that exists in both languages (Home, Getting started),
when the visitor chooses the other language in the top bar,
then they arrive at the counterpart URL (`/agent-plugins/getting-started/` and `/agent-plugins/nl/getting-started/` for each other), the stored choice is updated (156 AC-7), and the switcher's current-language marking follows (156 AC-5). The options remain real links with `hreflang` and the language's own name (156 AC-23).

**AC-15 With no counterpart, the switcher goes to the other language's Home.**
Given a page that exists in one language only (the English Reference; any fixture page without Dutch),
when the visitor chooses the other language,
then they arrive at that language's Home, not a 404 and not a different page. This holds on the Dutch side too: wherever a Dutch page shows the Reference link, its label is the English "Reference" (AC-5). (This keeps 156 AC-4 for pages without a twin; the Dutch option on English Reference still goes to Dutch Home.)

**AC-16 A page without a Dutch version does not break the build or leave a dead link.**
Given a fixture page with an English entry only,
when the site is built,
then the build succeeds, the Dutch navigation tree and Dutch see-also lists do not link to a nonexistent `/nl/` page, and the English page's Dutch switcher option goes to Dutch Home. The one deliberate cross-language link is the Dutch tree's Reference entry (AC-5), labelled "Reference" with `lang="en"` and `hreflang="en"`, which goes to an existing English page.

**AC-17 The return-visit redirect and the entry point are unchanged.**
Given the stored choice is Dutch,
when `/agent-plugins/getting-started/` is opened directly,
then it is shown as requested (156 AC-9 holds for the new pages); the redirect still happens only at the English Home (156 AC-8).

**AC-18 No dead internal link in the built site.**
Given the full build output,
when every `a[href]` and every fragment link that points inside the site is followed (each page in each language, tree, breadcrumb, contents, see-also, switcher, body links),
then each resolves to an existing page in the build output and, for a fragment, to an existing `id` on that page. The test also fails when run against a fixture with one deliberately broken link, so it cannot pass by accident.

### E. Getting started, English and Dutch (Under test: first hand-written page, both languages, no layout markup in content)

**AC-19 English Getting started exists and holds the prototype's steps.**
Given the built page at `/agent-plugins/getting-started/`,
when it is read,
then it has `<html lang="en">`, one `h1` "Getting started", and four `h2` steps in this order: add the marketplace, install the plugins you want, set up your repository once, run your first command; each step shows its commands in code blocks. The commands are exactly those of the prototype copy and are checked against the repository's real names: the marketplace source `WimSuenens/agent-plugins`, marketplace name `wimsuenens`, and every `/plugin:skill` command shown exists as a skill source (`plugins/<plugin>/skills/<skill>/SKILL.md`) so the page cannot name a command that does not exist.

**AC-20 Dutch Getting started mirrors English.**
Given `/agent-plugins/nl/getting-started/`,
when it is read,
then it has `<html lang="nl">`, one `h1`, the same number of `h2` headings in the same order as the English page, the same commands (code blocks are identical to the English ones), the same number of links, and Dutch prose in every paragraph, heading and note (names of plugins, skills, commands and `gh` excepted).

**AC-21 Draft Dutch pages are visibly and checkably marked.**
Given a Dutch page whose review status in the page tree is `draft` (Getting started, and Home when the owner has not yet marked it reviewed),
when the page is read,
then it shows one short notice in Dutch that the translation is a draft not yet reviewed by the owner, and a test or build summary can list every Dutch page with status `draft` from the page tree. Given a page whose status is `reviewed`, then no notice is shown. Changing a status is one field in the page tree. (Answers the deferred translation workflow's trigger: the second Dutch page makes unreviewed pages visible; the owner's review itself is not tracked here.)

**AC-22 Content carries no layout markup.**
Given the content files of Getting started (English and Dutch) and the generated Reference,
when they are read,
then they hold prose, headings, lists, code and links only: no `style` attribute, no layout `div` or class names, no colour literal. All layout and colour come from the components and the tokens (ADR 0022's consequence: a later look change stays a refactor).

**AC-23 Code blocks are usable on a phone and by keyboard and screen reader.**
Given a viewport 320 CSS pixels wide on Getting started (both languages),
when a long command is shown,
then the page does not scroll horizontally; the code block itself scrolls or wraps, is reachable by keyboard (focusable when it scrolls), and its text meets 4.5:1 contrast.

### F. Look, accessibility and the build check (Under test: editorial look with the new structure; the check covers new pages)

**AC-24 The new structure keeps the editorial look and the 156 bars.**
Given every built page,
then 156 AC-19 to AC-23 hold for the new components: tokens only (no colour literal outside the token definitions), 4.5:1 contrast for text and 3:1 for interface parts across the tree (normal, hover, current, visited states), the breadcrumb, the contents list, the see-also list, the draft notice and code blocks; a visible focus indicator; and no transition or animation under `prefers-reduced-motion: reduce` (the tree's open and close, if any, does not animate).

**AC-25 The tree, contents and see-also read well in a single reading column.**
Given a laptop-width viewport (1280px) and a phone-width viewport (320px),
when a page is shown,
then the main text stays one column of about 70 characters (156 AC-19); from 48rem viewport width the tree is a column beside the reading column, and below 48rem the tree is always open and in the flow, above `main`, with no `details` element and no script; the order in the source is: skip link, top bar, navigation tree, `main` (breadcrumb, `h1`, text, see-also), with the contents list reachable in a logical order; the skip link is first and, when activated, moves focus past the tree into `main`.

**AC-26 The accessibility check covers the new pages and landmarks.**
Given the built site,
when the build command is run,
then the automated accessibility check runs on every built page in both languages (English Home, English Getting started, Reference, Dutch Home, Dutch Getting started, and any page added by the page tree), and the number of pages checked is computed from the build output, not written into the check.

**AC-27 The check fails on a missing or duplicated navigation landmark.**
Given a copy of a built page with (a) its tree's `nav` label removed, (b) two `nav` elements sharing one name, (c) the breadcrumb `nav` removed or (d) `main` removed,
when the build command is run on it,
then it exits non-zero and names the page and the fault; given the real pages, it exits zero. The check also fails a page that has a navigation tree but no `aria-current="page"` entry.

**AC-28 The deployed site shows the new pages.** *(post-merge)*
Given the workflow has run on `main`,
when `/agent-plugins/getting-started/` and `/agent-plugins/nl/getting-started/` are requested,
then each returns 200 with the pages of AC-19 and AC-20; the Reference still lists the same count of skills as 156 AC-13; the stylesheet and fonts load with 200.

## Mapping from the frame's Under test lines

| Under test (frame) | Acceptance criteria that would show the contradiction |
|---|---|
| Editorial wiki look with the switcher in the top bar (ADR 0022): fits 320px, keyboard, 4.5:1, landmarks; no layout markup in content | AC-7, AC-8, AC-9, AC-22, AC-23, AC-24, AC-25 |
| Page slugs and navigation structure from one page tree; adding a page is one edit | AC-1, AC-2, AC-3, AC-4, AC-5, AC-10 |
| Generated reference content is the source of truth: no hand-kept list for tree, breadcrumbs or see-also | AC-1, AC-12, AC-13 (with 156 AC-16) |
| English at the root, Dutch at `/nl/`, switcher: no 404, wrong page or dead link | AC-14, AC-15, AC-16, AC-17, AC-18 |
| Translation workflow beyond Home: a way to see which Dutch pages are unreviewed | AC-21 |
| Accessibility check in the build covers new pages and landmarks | AC-26, AC-27 |

## Human-only criteria

QA cannot decide these; the person (or a reviewer with a real browser) judges them and the verdict is recorded on the item.

- **H-1 The look matches prototype A.** The owner looks at Home, Getting started and Reference on a laptop and on a phone and says whether the tree, breadcrumbs, contents and see-also match the chosen editorial look (the machine parts are AC-24 and AC-25).
- **H-2 The Dutch Getting started reads as natural Dutch.** An agent drafted it; the owner reviews it and, on approval, sets its status to `reviewed` (AC-21). Until then the notice stays.
- **H-3 A screen reader announces the new pages sensibly.** One pass with VoiceOver on Getting started, English and Dutch: landmarks are announced by name (AC-9), the current page in the tree is announced, the contents list and breadcrumb make sense.
- **H-4 The navigation feels usable on a real phone.** The owner opens the tree on a phone and finds a page without trouble (AC-8 is the machine part).

## Decisions (two-way doors decided here)

- **A page has the same slug in both languages**, so the counterpart is derived, not listed. Rejected: translated slugs (`/nl/aan-de-slag/`), which need a per-page counterpart table (the special case the frame warns against). Cost to undo: a counterpart field in the page tree and one URL redirect per page; hours.
- **The Dutch tree lists Reference and links to the English Reference page**, marked `lang="en"`, rather than hiding it or building a Dutch Reference. Rejected: a Dutch Reference shell around English skill text (more surface, half-translated); omitting it (the Dutch visitor cannot find the Reference). Switching language on Reference still goes to Dutch Home (AC-15). Cost to undo: add the Dutch route and flip the entry; a day. The architect may propose the shell as an alternative (open question 1).
- **Draft Dutch pages carry a visible notice and a status field in the page tree**, and a list of drafts can be produced from the page tree (AC-21). Rejected: tracking only on the slice (the frame's Under test line is then unanswerable). Cost to undo: delete the field and notice; an hour. This fires the map's deferred translation line only as far as "see which pages are unreviewed"; the full workflow stays deferred.
- **A see-also slug with no page in the language is dropped, not an error** (AC-13), while a slug that is not in the page tree at all fails the build (AC-4). Cost to undo: a minute.
- **The tree and contents add no client script** (AC-7), so 156 AC-12 stays true. Rejected: a script-driven collapsible tree. Cost to undo: a script line; an hour.
- **The architect's contracts (contracts/188-*.md) govern three points where they refine this requirement: the navigation tree comes before `main` in source order (a column beside the reading column from 48rem, the skip link jumping past it), the Dutch Reference link label stays the English "Reference" (`lang="en"`, `hreflang="en"`), and Home's breadcrumb shows only itself. The lead accepted them; AC-5, AC-10, AC-15, AC-16 and AC-25 are worded to match.**
- **Getting started's commands are checked against the repository** (AC-19), so the page cannot drift from real skill names; deeper drift detection of narrative pages stays deferred.

## Out of scope

Everything the frame lists as deliberately faked:

- Narrative pages other than Getting started: the Plugins overview, wayfinding, design, factory, The Lean way, the factory roles, running the factory, the Obeya, toolkit and discover, Credits. The prototype shows them; they come in later slices. The tree lists only pages that exist.
- The owner's review of the Dutch Getting started is recorded on the slice; the site tracks only `draft` or `reviewed` (AC-21), not who, when or what changed. The wider translation workflow (how drafts are produced per page) is the deferred line.
- Generated pages stay skills only: no agent, command, hook or factory-reference pages, and no per-skill pages (Reference is still one page).
- No site search, no performance budgets (deferred until images, larger fonts or more client script), no drift detection of hand-written pages against changed plugins.

Beyond the frame, left to later slices: a Dutch Reference, credits for the upstream skills, a third language, a changelog feed.

## Open questions

1. Reference in Dutch: the page stays English in this slice and the Dutch tree links to it (AC-5, Decisions). Whether a later slice gives Dutch visitors a Dutch shell is the architect's to propose; AC-5, AC-15 and AC-16 are the ones that would change. Owner: architect.
2. Tree presentation on a phone: answered by the architect, always open and in the flow above `main` below 48rem, with no `details` and no script (contracts/188-wiki-components.md, the phone presentation bullet). AC-25 is worded to match; AC-8 holds for any presentation.
3. Where the page tree lives (one data file, or content front matter collected at build): AC-1, AC-2 and AC-4 hold for either, as long as adding a page is one edit. Owner: architect.
4. Which accessibility rules the check adds for landmark names (AC-27); the check tool is already decided in 156. Owner: architect.
5. Whether Home also shows the draft notice until the owner marks it reviewed (AC-21 says so when its status is `draft`). Owner: the owner, via the slice review; the default is `draft` for both Dutch pages.
