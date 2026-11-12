# 156 — Live skeleton: bilingual home and generated skills index on GitHub Pages

Slice: [#156](https://github.com/WimSuenens/agent-plugins/issues/156) · Map: [#146](https://github.com/WimSuenens/agent-plugins/issues/146) · Sources: [#148](https://github.com/WimSuenens/agent-plugins/issues/148) (Pages URL and base path), [#149](https://github.com/WimSuenens/agent-plugins/issues/149) (what the plugin files give the generator), [#147](https://github.com/WimSuenens/agent-plugins/issues/147) (the look, ADR 0022)

## User outcome

A newcomer opens https://wimsuenens.github.io/agent-plugins/ and sees a Home page in the editorial look, with a language switcher in the top bar. They switch to Dutch (`/nl/`) and, when they come back later, find Dutch still chosen. They open a Reference page that lists every skill of the marketplace plugins; that list was generated from the plugins' own SKILL.md files, so when a SKILL.md changes the page changes after a rebuild, with no hand-editing. A GitHub Actions workflow builds the site, runs one automated accessibility check on the built pages, fails the build when that check fails, and deploys the site.

This serves the map's Destination: the site is live in English and Dutch, the switcher remembers the choice, reference pages are generated, and the build fails on accessibility regressions.

## Terms used here

- **Base path**: `/agent-plugins/`. The site is served under it on GitHub Pages. English Home is `/agent-plugins/`, Dutch Home is `/agent-plugins/nl/`.
- **Built pages**: the HTML files in the build output, for every route the site has in this slice.
- **Skill source**: a file `plugins/*/skills/*/SKILL.md` in the repository. Copies under `.claude/worktrees/` are not skill sources.
- **Manual command**: a skill whose frontmatter has `disable-model-invocation: true`.
- **Stored choice**: the language the visitor chose with the switcher, kept in the browser.

## Acceptance criteria

QA checks these against the built output (the `dist` folder served under the base path by a local static server), the workflow file, and, where marked, the live site. A browser-driven test is used where behaviour needs a browser.

### A. Home, base path and routes (Under test: Astro, Pages and base path)

**AC-1 English Home is served at the base path.**
Given the site is built and served under `/agent-plugins/`,
when `/agent-plugins/` is requested,
then it returns the English Home page with `<html lang="en">`, one `h1`, and one sentence that states the hook "agents do the work; you decide only what can't be undone" (wording may be adapted, the meaning stays), and a link to the Reference page.

**AC-2 Dutch Home is served at `/nl/` and mirrors the English one.**
Given the site is built and served under `/agent-plugins/`,
when `/agent-plugins/nl/` is requested,
then it returns a Dutch Home page with `<html lang="nl">`, one `h1`, the same sections in the same order as English Home (same number of `h2` headings, same links), and Dutch text in every one of them (no English heading or paragraph left over, apart from names such as plugin and skill names).

**AC-3 Nothing breaks under the base path.**
Given the built pages,
when every `href`, `src` and stylesheet or font reference that points inside the site is checked,
then each one starts with `/agent-plugins/`, and each resolves to an existing file or route in the build output served under that base path (no 404, no link to a path without the base).
And when the site is served at the root instead of the base path, the check fails: the test must prove it is not passing by accident (for example by also requesting an un-based path and expecting 404).

**AC-4 Only Home is translated; the other pages stay English.**
Given the Reference page,
when it is opened,
then it has `<html lang="en">` and is served only at one URL (there is no `/nl/` copy of it).
And given any English-only page,
when the visitor chooses Dutch in the top bar,
then they arrive on Dutch Home.

### B. Language switcher (Under test: remembered switcher, no flash, no loop, narrow phone)

**AC-5 The switcher is in the top bar of every page.**
Given every built page (English Home, Dutch Home, Reference),
when the page is read,
then the top bar holds a language switcher with two options, English and Dutch, the current language marked (`aria-current` or equivalent), each option a real link (`a` with `href`) to the Home of that language, so the switcher works without script.

**AC-6 A first visit shows English and stores nothing.**
Given a browser with no stored choice,
when `/agent-plugins/` is opened,
then English Home is shown, no redirect happens, and nothing is stored until the visitor uses the switcher.

**AC-7 Choosing a language stores the choice and the visitor lands in it.**
Given a browser with no stored choice,
when the visitor chooses Dutch in the switcher,
then the browser lands on `/agent-plugins/nl/` and the stored choice reads Dutch.
And when the visitor then chooses English,
then the browser lands on `/agent-plugins/` and the stored choice reads English.

**AC-8 A returning visitor finds the choice remembered, without a redirect loop.**
Given the stored choice is Dutch,
when `/agent-plugins/` is opened in a fresh page load,
then the browser ends on `/agent-plugins/nl/`, having moved there by replacing the history entry (pressing Back leaves the site or goes to the previous page, never to the English root and back again), and the number of navigations from the request to the final page is at most 2.
And given the stored choice is English,
when `/agent-plugins/nl/` is opened directly (for example from a shared link),
then Dutch Home stays: a direct link to a page is never redirected away from the language of that URL.
And given the stored choice is Dutch and the visitor chooses English,
then they stay on English Home and are not sent back to Dutch (the explicit choice replaces the stored one).

**AC-9 The remembered choice applies only to entering at the English Home.**
Given the stored choice is Dutch,
when `/agent-plugins/reference/` (or any page other than English Home) is opened directly,
then it is shown as requested, without a redirect.

**AC-10 The English Home does not flash before a Dutch return.** *(human-only proxy below)*
Given the stored choice is Dutch,
when `/agent-plugins/` is opened,
then no English Home content is painted before the Dutch page arrives. The automated proxy: the redirect is performed by a script that runs in the page `head`, before the body, and the page body is not rendered visible until it has decided.

**AC-11 The switcher fits a narrow phone with Dutch labels.**
Given a viewport 320 CSS pixels wide, the Dutch Home page and the English Home page,
when the top bar is shown,
then the site name, the navigation entry points the top bar holds, and both switcher options are visible and operable without horizontal scrolling of the page (document width equals viewport width), and no top-bar item overlaps another or is clipped.

**AC-12 The switcher is the only client script.**
Given the built pages,
when their `script` elements and script files are listed,
then the only script on any page is the language switcher's (a few lines, no framework runtime), and a page loaded with scripts disabled still shows all content and a working switcher by plain links.

### C. Generated Reference (Under test: reference generator, source of truth)

**AC-13 The Reference page lists every skill source once.**
Given the repository,
when the site is built,
then the Reference page has one entry for each file matching `plugins/*/skills/*/SKILL.md`, no more and no fewer (a count of 18 at the time of writing, but the expected number is computed by the test from the files, not written into it), and no entry comes from `.claude/worktrees/` copies or any file outside `plugins/`.

**AC-14 Each entry carries what the plugin files give.**
Given a skill source,
when its entry is read on the Reference page,
then it shows: the skill `name`; the command `/<plugin>:<name>` where `<plugin>` is the folder name under `plugins/`; the `description` text in full; the plugin it belongs to (entries are grouped or labelled by plugin); and a marker "manual command" exactly when `disable-model-invocation` is `true`.
And when the skill has an `argument-hint`, the entry shows it; when it has none, the entry shows no empty label or placeholder.

**AC-15 Odd characters survive.**
Given the descriptions that hold em dashes, " - " hyphens, ellipses, backticks, slashes, quotes and colons (for example factory `run` and `obeya`, design `direction`, wayfinding `reversibility`, toolkit `source-to-pptx`),
when the Reference page is read,
then each description equals the frontmatter text of its source after YAML parsing (compared as text), characters are not turned into mojibake or entities that show on screen, and text in backticks is not swallowed or treated as markup that breaks the page.

**AC-16 A change to a SKILL.md shows up after a rebuild with no other edit.**
Given a fixture or temporary change that alters a skill's `description` (and one that adds a new skill folder with a SKILL.md, and one that removes a skill),
when the site is rebuilt, touching no file other than that SKILL.md or folder,
then the Reference page shows the new description, the new skill, and no longer the removed one; and no generated reference data is committed to the repository (the generated entries exist only in the build output or in ignored files), so a hand-edit has nothing to edit.

**AC-17 Missing optional fields do not break the page; missing required fields do.**
Given skill sources that lack `argument-hint`, `license`, `version` and `disable-model-invocation` (as 15 of 18 lack `argument-hint`),
then the build succeeds and the entries are complete without them.
And given a skill source with no `name` or no `description`,
then the build fails with a message that names the file, so a broken source is seen at build time, not as a blank entry. *(Two-way door decided by the product-owner; see Decisions.)*

**AC-18 Each Reference entry is reachable and readable on its own.**
Given the Reference page,
when the visitor uses the on-page contents list or a plugin's heading link,
then it jumps to that plugin's group (a stable fragment id), and the page has a breadcrumb back to Home, in line with the wiki navigation of ADR 0022 as far as this slice has pages (navigation tree, breadcrumbs, on-page contents; see-also links may be absent, see out of scope).

### D. Look and accessibility (Under test: editorial look, contrast, keyboard, reduced motion)

**AC-19 The pages have the editorial look.** *(human-only, see below for the machine part)*
Given the built pages,
when they are read,
then headings use the warm serif of ADR 0022, body text is one reading column of about 70 characters, sections are separated by rules instead of boxes or cards, and colours, type sizes and spacing come from CSS custom properties (no hard-coded colour in a component rule). The machine part: a check finds the custom properties and finds no colour literal outside the token definitions.

**AC-20 Text contrast is at least 4.5:1, interface parts 3:1.**
Given the built pages and the colour tokens,
when contrast is computed for every text and background pair the pages use (body, headings, links in running text and visited, the top bar, the switcher in its normal, hover and current states, code text, table text, the skip link),
then each text pair is at least 4.5:1 and each interface part (focus ring, switcher border, rule that carries meaning) is at least 3:1 against its neighbour. The computation is done on the real rendered pages, not only on the token list.

**AC-21 Keyboard use works on every page.**
Given each built page and only the keyboard,
when the visitor presses Tab from the page start,
then the first stop is a visible "skip to content" link that moves focus to the main content when activated; every link and the two switcher options are reachable in a logical order and operable with Enter; each focused item shows a visible focus indicator (at least 3:1 against its neighbour, not removed by `outline: none` without replacement); and no focus trap exists.

**AC-22 Reduced motion is respected.**
Given a browser set to `prefers-reduced-motion: reduce`,
when the pages are loaded and used,
then no CSS transition, animation or smooth scroll runs (computed `transition-duration` and `animation-duration` are zero or the properties are absent, and `scroll-behavior` is not `smooth`).
And given the preference is not set, any motion the pages use is still short and inside a `prefers-reduced-motion: no-preference` guard (the build may also contain no motion at all).

**AC-23 Semantics support screen readers.**
Given each built page,
when its structure is read,
then it has `lang`, a `title`, one `h1`, a `main` landmark, a `nav` landmark labelled for the top bar, no skipped heading level, real `a` and `button` elements (no click handler on a `div`), and the language switcher's options carry the language name in its own language ("English", "Nederlands") and `hreflang`.

### E. Accessibility check and deploy (Under test: Actions deploy, build fails on failed check)

**AC-24 One automated accessibility check runs on every built page.**
Given the built site,
when the build command for the site is run (the one the workflow uses),
then an automated accessibility check runs against every built page (English Home, Dutch Home, Reference) and its pass or fail decides the exit status of that command.

**AC-25 The build fails when the check fails.**
Given a built page that has a known accessibility fault (the test adds a fault to a copy: an image without alt text, or text pushed below 4.5:1 contrast),
when the build command is run on it,
then the command exits non-zero and its output names the page and the fault.
And given the real pages with no fault,
then the same command exits zero.

**AC-26 The workflow builds, checks and deploys with the Actions source.**
Given the workflow file under `.github/workflows/`,
when it is read and linted (for example with `actionlint`),
then it: triggers on push to `main` for changes under `apps/site/` and `plugins/` (so a SKILL.md change redeploys) and on manual dispatch, and builds on pull requests that touch those paths without deploying; installs, builds and runs the accessibility check before any deploy step, and a failed check stops the deploy; deploys with the GitHub Pages Actions flow (upload the build output as a Pages artifact, then `actions/deploy-pages`) using only the permissions that flow needs (`contents: read`, `pages: write`, `id-token: write`); and sets the base path to `/agent-plugins` so the deployed site matches AC-3.

**AC-27 The deployed site is live at the published URL.** *(post-merge)*
Given the workflow has run on `main`,
when https://wimsuenens.github.io/agent-plugins/ and https://wimsuenens.github.io/agent-plugins/nl/ are requested,
then each returns 200 with the page of AC-1 and AC-2, the Reference page returns 200 and lists the same count of skills as AC-13, and the stylesheet and fonts load with 200.

## Mapping from the frame's Under test lines

| Under test (frame) | Acceptance criteria that would show the contradiction |
|---|---|
| Astro in `apps/site/` is the stack | AC-2, AC-12, AC-13, AC-19, AC-24 (Astro cannot give the look, the routes, the generated pages, or needs script beyond the switcher); the site lives in `apps/site/` (AC-26 paths) |
| GitHub Pages, served under `/agent-plugins/` | AC-1, AC-2, AC-3, AC-26, AC-27 |
| English at root, Dutch at `/nl/`, remembered switcher | AC-5 to AC-10, AC-2 |
| What the plugin files give the generator [provisional] | AC-13 to AC-15, AC-17 |
| Generated reference content is the source of truth | AC-16 |
| Editorial look (ADR 0022), contrast, keyboard, narrow phone | AC-11, AC-19 to AC-23 |

## Human-only criteria

QA cannot fully decide these; the person (or a reviewer with a real browser) judges them, and the verdict is recorded on the item.

- **H-1 The look is the editorial, neutral-but-warm one of ADR 0022** (the machine parts are in AC-19). The owner looks at Home and Reference on a laptop and a phone and says whether it matches the chosen prototype A.
- **H-2 The Dutch Home reads as natural Dutch.** The Dutch is drafted by an agent; the owner reviews it. How the review is recorded is the deferred translation workflow, so for this slice the owner's word on the item is enough. Until then the Dutch Home is a draft.
- **H-3 No visible flash on a return visit** (AC-10): the owner opens the site with Dutch chosen and sees no English page appear first, on a real phone or a throttled connection.
- **H-4 A screen reader announces the pages sensibly** (AC-23): one pass with VoiceOver on Home and Reference.

## Decisions (two-way doors decided here)

- **Switcher storage is `localStorage`** under one key, holding `en` or `nl`. Rejected: a cookie (a static site has no server that reads it; it would be sent on every request) and URL-only (does not remember). This fires the map's deferred "language-switcher mechanism" line and pins it as a testable value. Cost to undo: a small script change plus a migration line; about an hour.
- **A redirect on a return visit happens only when entering at the English Home** (AC-8, AC-9), by replacing the history entry; direct links to any other page are never redirected. Rejected: redirecting every English page (breaks shared links, risks loops). Cost to undo: a small script change.
- **On an English-only page, the Dutch option goes to Dutch Home** (AC-4), since the page has no Dutch twin yet. Cost to undo: a one-line change per page when a translation exists.
- **A skill source missing `name` or `description` fails the build** (AC-17), rather than being skipped, so a broken plugin file is seen at once. Cost to undo: a minute.
- **The expected skill count is computed, never written into tests** (AC-13), because the survey found counts drift (seven versus eight agents).
- **No generated reference data is committed** (AC-16): it exists only in the build. Cost to undo: choose to commit it later; a day.

## Out of scope

Everything the frame lists as deliberately faked:

- Dutch for any page but Home; the translation workflow and how the owner's review is recorded.
- Narrative pages beyond placeholders or short text; the full wiki tree, slugs and navigation structure (only the pages this slice needs: Home, Reference); see-also links.
- The full accessibility tooling and the performance budgets. This slice has one automated check (AC-24, AC-25); it states no numeric speed budget. Mobile performance budgets are the deferred line.
- Drift detection of hand-written pages against changed plugins.

And beyond the frame, so a later slice picks them up:

- Reference pages for agents, commands, hooks, manifests, factory references and scripts, and the credits block for the upstream skills. This slice generates the skills index only.
- Narrative sections on wayfinding, design, factory, toolkit, discover; the Lean and Obeya content.
- Search, analytics, a custom domain, a third language, a blog or changelog feed.

## Open questions

- Which accessibility check tool to use (owner: architect). Any tool is fine if AC-24 and AC-25 hold; it must check contrast on rendered pages (AC-20).
- Whether the Reference page is one long page or one page per plugin (owner: architect, with the deferred slug line). AC-13 to AC-18 hold either way if the page(s) sit under one reachable Reference entry.
- The URL of the Reference page: AC-9 uses `/agent-plugins/reference/` as an example; the final slug is the architect's call within the deferred slug line.
