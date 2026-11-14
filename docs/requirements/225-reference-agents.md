# 225 — Reference pages for agents: generated Agents page and a Reference section, in English and Dutch

Slice: [#225](https://github.com/WimSuenens/agent-plugins/issues/225) · Map: [#146](https://github.com/WimSuenens/agent-plugins/issues/146) · Builds on: [156 live skeleton](156-live-skeleton.md) and [188 wiki shell](188-wiki-shell.md) (their criteria and test conventions still hold and are not repeated; where this slice changes one, it is named under "Criteria this slice changes") · Look: [ADR 0022](../adr/0022-the-documentation-site-has-an-editorial-wiki-look.md), not reopened here

## User outcome

A newcomer opens Reference and sees it split into two pages, Skills and Agents, in English and in Dutch. The Skills page is the generated skills list that Reference was until now. The Agents page lists every agent of every plugin that has agents (today the factory plugin's eight role agents) with its name, description, model and tools, all read from the agent files in `plugins/`. When an agent file is added, edited or removed, the pages change at the next build with no hand edit, and every count shown on the site is computed from the files, never typed.

This serves the map's Destination: reference pages (skills, agents) generated from the plugins' own files, in English and Dutch, on the wiki shell.

## Terms used here

- **Agent source**: a file `plugins/<plugin>/agents/*.md`. Files under a dot-prefixed folder (such as `.claude/worktrees/`) and anything outside `plugins/` are not agent sources.
- **Reference section**: the Reference page and its two child pages, Skills and Agents, nested in the page tree as Home > Reference > Skills and Home > Reference > Agents. URLs stay flat, as the page tree fixes them: `/agent-plugins/reference/`, `/agent-plugins/skills/`, `/agent-plugins/agents/`, and the same under `/agent-plugins/nl/`.
- **Reference overview**: the Reference page itself. It introduces the section, links to Skills and Agents and shows derived counts.
- **Derived count**: a number computed at build time from the files (skill sources, agent sources, plugins). A typed number in a source file, a content file or a UI string is not a derived count.
- **English plugin text**: text that comes from a plugin file (names, descriptions, models, tool names, argument hints). It is English and is not translated by this slice.
- **Draft**: a Dutch page whose review status is not `reviewed` (188). The three Dutch Reference pages ship as drafts.

## Acceptance criteria

QA checks these against the built output served under `/agent-plugins/`, with a browser-driven test where behaviour needs one. The expected counts and field values are computed by the test from the files under `plugins/`, never written into it. Fixtures add, change or remove agent files and pages on a copy of the source, never on the real plugins.

### A. The generator reads the agent files (Under test: #149 generator facts)

**AC-1 The Agents page lists every agent source once.**
Given the repository,
when the site is built,
then the English Agents page has one entry for each file matching `plugins/*/agents/*.md`, no more and no fewer, grouped by plugin, ordered by plugin name and then agent name, and no entry comes from `.claude/worktrees/` copies or any file outside `plugins/`.

**AC-2 Each entry carries what the agent file gives.**
Given an agent source,
when its entry is read,
then it shows the frontmatter `name`, the `description` in full, the `model` as written in the file (for example `inherit`, `sonnet`, `haiku`), and the `tools` as a list of the tool names the file gives, and the plugin it belongs to. A `tools` value that is a comma-separated string and one that is a YAML list both give the same list of names.

**AC-3 Odd characters survive.**
Given the agent descriptions (they hold commas, parentheses, slashes and the words "and"/"or" in long sentences),
when the page is read,
then each description equals the frontmatter text after YAML parsing (compared as text), with no mojibake or visible entities.

**AC-4 Every real agent file parses as strict YAML and has the required fields.**
Given every file matching `plugins/*/agents/*.md` as it is in the repository,
when the site is built,
then the build succeeds. This is the check that #149 predicted these files are usable: it is contradicted if any real agent file fails strict YAML parsing or lacks `name` or `description`.

**AC-5 Missing optional fields do not break the page; missing required fields do.**
Given a fixture agent file with no `model`, one with no `tools`, and one with neither,
then the build succeeds and the entry is complete without the missing field: no empty "Model" or "Tools" label, no placeholder, no the text `undefined` or `null` on the page.
And given a fixture agent file with no `name`, no `description`, an empty one, or no frontmatter or broken YAML,
then the build fails and the output names the file and the fault.

**AC-6 A plugin without an `agents/` folder is only skipped.**
Given the repository, where `design`, `discover`, `toolkit` and `wayfinding` have no `agents/` folder,
when the site is built,
then they have no group and no empty heading on the Agents page, they still appear on the Skills page, and the generator needed no special case for them beyond skipping. And given a fixture plugin whose `agents/` folder exists but holds no `.md` file, then it is skipped the same way. A file in `agents/` that is not `.md` is ignored.

**AC-7 A change to an agent file shows up after a rebuild with no other edit.**
Given fixtures that alter an agent's `description`, `model` or `tools`, add a new agent file (in an existing plugin and in a plugin that had no `agents/` folder) and remove one,
when the site is rebuilt, touching no file other than that agent file or folder,
then the Agents page, in English and in Dutch, shows the new text, the new agent under its plugin (a new plugin group when it is the plugin's first), and no longer the removed one. No generated agent data is committed to the repository.
(Under test: generated reference content is the source of truth.)

### B. Counts are derived (Under test: counts derived, source of truth)

**AC-8 Every count on the site follows the files.**
Given the built site,
then the Reference overview, the Skills page and the Agents page each show the counts they claim (at least: skills and the plugins they come from on Skills and on the overview; agents and the plugins they come from on Agents and on the overview), each equal to the number the test computes from `plugins/` at the time.
And given the AC-7 fixtures (one more agent, one fewer, a first agent in a new plugin) and a fixture that adds or removes a skill folder,
then every count on those three pages changes to match, in English and in Dutch, with no other edit.
And no page source (`pages.mjs`, a content file, a UI string) holds a typed count of skills, agents or plugins.

### C. The Reference section sits in the wiki shell (Under test: #188 page tree)

**AC-9 The section is added by data and page content only.**
Given the change that adds the Skills and Agents pages and turns Reference into the overview,
when the branch is compared with `main`,
then within `apps/site/src/` the shell code is unchanged: `lib/pages.mjs`, `layouts/`, `pages/` (both route files), `components/PageTree.astro`, `Breadcrumb.astro`, `Contents.astro`, `SeeAlso.astro`, `TopBar.astro`, `LangSwitcher.astro`, `DraftNotice.astro`, `lib/langScript.mjs`, `lib/rehypePage.mjs` and `astro.config.mjs`. What changes is the entries in `data/pages.mjs`, the generated-page layer (the component registry, the generated bodies, the agent loader beside `lib/skills.mjs`), the UI strings in `i18n/ui.mjs` and content files. This is the contradiction test for #188: it is contradicted if the shell code had to change.

**AC-10 Navigation, breadcrumb and counterpart follow the tree.**
Given each built page of the section, in each language,
then the navigation tree nests Skills and Agents (in that order) under Reference under Home, the breadcrumb is Home > Reference > Skills or Home > Reference > Agents (Home > Reference for the overview) with labels and links in the page's language, `aria-current="page"` is on exactly one entry (the page read), the contents list holds the page's own headings, and the language switcher goes to the same slug in the other language.
(All asserted against `data/pages.mjs`, as 188 AC-1 does.)

**AC-11 The overview links to both children and the tree's see-also works.**
Given the Reference overview in each language,
then it links to the Skills page and to the Agents page of its own language, each with a one-line description and its derived count, and the see-also list on the three pages follows the entries in `data/pages.mjs`.

**AC-12 The build lists the new Dutch pages as drafts.**
Given the built site,
then the build output's single `pages: dutch drafts:` line names `/agent-plugins/nl/reference/`, `/agent-plugins/nl/skills/` and `/agent-plugins/nl/agents/`, each Dutch page shows the draft notice, and setting a page's review to `reviewed` in the page tree is the one edit that removes it (188 AC behaviour, unchanged).

### D. Dutch pages (Under test: Behaviour, in English and Dutch)

**AC-13 Dutch Reference, Skills and Agents exist and are navigable.**
Given the built site,
then `/agent-plugins/nl/reference/`, `/agent-plugins/nl/skills/` and `/agent-plugins/nl/agents/` exist with `<html lang="nl">`; the Dutch navigation tree lists Reference with Skills and Agents under it as real links to those Dutch pages (no more link to the English Reference with `hreflang="en"`); the Dutch Home's Reference link goes to the Dutch Reference page; and the English pages' language switchers go to these pages.

**AC-14 Dutch carries the English plugin text, marked as such.**
Given the Dutch Skills and Agents pages,
then page titles, headings of the page itself, field labels (name, description, model, tools, plugin, counts sentence) and the intro are Dutch; each element that holds English plugin text (descriptions, tool names, model, argument hint, command) carries `lang="en"`; and each of the two pages has one visible Dutch sentence saying that the entries below are English. The Dutch intro text is an agent draft, marked as draft by AC-12; this slice does not claim it is reviewed.
And the Dutch pages have the same entries, in the same order and with the same ids, as the English ones.

**AC-15 The existing Skills content survives the move.**
Given the Skills page in each language,
then it satisfies 156 AC-13 to AC-18 as they stood for the Reference page (one entry per skill source, command, full description, "manual command" marker, argument hint only when present, odd characters, rebuild with no other edit, missing required fields fail the build, a stable fragment id per plugin group `<plugin>` and per skill `<plugin>-<skill>`), now at `/agent-plugins/skills/` and `/agent-plugins/nl/skills/`.
And the Agents page uses the same id scheme: `<plugin>` for a group and `<plugin>-<agent>` for an agent, each reachable from the contents list and unique on the page.

### E. Quality gates (existing, applied to the new pages)

**AC-16 The accessibility check passes on every new page in both languages.**
Given the built site,
when `npm run build` runs its accessibility check,
then it covers the six pages (`/reference/`, `/skills/`, `/agents/` in both languages) and passes: contrast, keyboard use, landmarks, one `h1`, reduced motion, as for every other page (156 AC-20 to AC-25, 188 landmark criteria).

**AC-17 The Agents page fits a narrow phone.**
Given a 320 px wide viewport,
when the English and the Dutch Agents page are read,
then the longest tools list (the developer or qa-engineer entry) wraps inside the viewport and the page has no horizontal scroll.

**AC-18 No new client script.**
Given the built pages,
then the language switcher stays the only client script (156 AC-12) and the new pages add none.

**AC-19 The pages are live.** *(post-merge)*
Given the deployed site at https://wimsuenens.github.io/agent-plugins/,
when `/reference/`, `/skills/`, `/agents/` and the same under `/nl/` are requested,
then each returns 200, the Agents page lists the same count of agents as AC-1, and the stylesheet loads with 200.

## Criteria this slice changes

These earlier criteria are overtaken by the Behaviour of this slice. The slice's tests replace the old assertions; the developer does not edit `tests/`, QA does.

- **156 AC-4** (only Home is translated; Reference has no `/nl/` copy): now Home, Reference, Skills and Agents are translated. Getting started stays as 188 has it. An English-only page still sends the Dutch option to Dutch Home; no page in this section is English-only.
- **188 AC-3 and AC-5** (the URL list, and the Dutch Reference entry that links to the English Reference with `lang="en"` and `hreflang="en"`): the URL list gains `/skills/` and `/agents/` and their Dutch twins; the Dutch Reference entry is a real Dutch link. In the page tree this is dropping `alsoListedIn` from Reference and adding `title.nl`.
- **156 AC-13 to AC-18**: they apply to the Skills page, not the Reference overview (AC-15 above).
- **188 AC-1 and AC-2** still hold and are the standard AC-9 and AC-10 reuse.

## Traceability

| Frame line | Criteria |
|---|---|
| Behaviour: Reference split into Skills and Agents, English and Dutch | AC-10, AC-11, AC-13, AC-14, AC-15 |
| Behaviour: Agents page, eight role agents, name, description, model, tools from the files | AC-1, AC-2, AC-3 |
| Behaviour: change in `plugins/` changes the page at the next build, counts derived | AC-7, AC-8 |
| Under test: #149 (strict YAML, required fields, plugin without `agents/` skipped) | AC-4, AC-5, AC-6 (and AC-3) |
| Under test: #188 (only entries in `pages.mjs` and page content) | AC-9, AC-10, AC-12 |
| Under test: generated content is the source of truth (new agent appears, no typed count) | AC-7, AC-8 |
| Destination: accessible, in the shell, deployed | AC-16, AC-17, AC-18, AC-19 |

## Out of scope

Everything the frame lists as **Deliberately faked**, and what follows from it:

- **Hooks and manifests are not listed.** They belong to the same generator question and wait for the next reference slice; no Hooks page, no Manifests page, no `hooks/` or `.claude-plugin` reading.
- **Dutch reference pages carry the English plugin text, marked as such** (AC-14), as the Skills page does. The Dutch intro text is agent-drafted and stays a draft until the owner reviews it; owner review is not part of this slice. No Dutch translation of descriptions.
- **Performance budgets stay deferred** (trigger: first page with images or extra client script). AC-18 keeps that trigger from firing.

Also out of scope, as the slice's own choices:

- The agents' `skills` frontmatter field and the agent body text are not shown; only name, description, model, tools and plugin.
- A command or spawn name for agents (agents are not commands).
- Narrative pages about the factory, its roles or the Lean way (the "how much factory depth" question stays open on the map).
- Redirects from old Reference anchors (`/reference/#<plugin>`) to the Skills page.
- Changes to the look (ADR 0022), the language switcher, the deploy workflow, or any `plugins/` file.

## Decisions (two-way doors, decided by the product-owner)

- **Flat slugs, nesting by parent.** `skills` and `agents` are top-level slugs with `parent: "reference"`; URLs stay one segment, as the 188 page tree fixes. Rejected: nested URLs (`/reference/agents/`), which would change the tree's slug rule (shell code). Cost to undo: rename two entries and add redirects.
- **Reference becomes an overview; the skills list moves to Skills.** The old `/reference/#<plugin>` anchors move to `/skills/#<plugin>`; no redirect (the site is new, nothing links to the anchors). Cost to undo: a redirect page per anchor target, small.
- **Model shown as written.** `inherit` is not translated or explained per entry. Cost to undo: a one-line mapping in the generated body.
- **`tools` accepted as a comma-separated string or a YAML list.** Today all eight files use a string; the list form is accepted so a plugin author is not forced into one.
- **Zero agent sources anywhere fails the build**, as zero skill sources does, so an empty page is never shipped by accident. Cost to undo: allow an empty page with a note.
- **"Page content" includes the generated body.** For a generated page, the registry entry, the body component and the loader are its content layer, as the 188 page-tree contract already says (adding a component page is two edits, the entry and the registry key). AC-9 therefore guards the shell code, not the generated-page layer.
- **Reference title in Dutch is "Naslag"** (the word `ui.mjs` already uses for the Dutch section heading), as an agent draft.

## Open questions

None blocking. If the owner reads "page content" in the #188 Under test line more narrowly than the decision above (nothing but `pages.mjs` and content files), AC-9 tightens and the generated pages would need a different seam; the lead raises that with the architect, not the person.
