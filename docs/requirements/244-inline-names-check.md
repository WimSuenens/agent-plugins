# 244 — Site check: verify inline names and paths in hand-written pages

Slice: [#244](https://github.com/WimSuenens/agent-plugins/issues/244) · Map: [#146](https://github.com/WimSuenens/agent-plugins/issues/146) · Sources: [#240](https://github.com/WimSuenens/agent-plugins/issues/240) (what can be checked for drift; its finding is in `docs/research/hand-written-pages-drift.md`) · Widens: [188 wiki shell](188-wiki-shell.md) AC-19

## User outcome

A maintainer who changes a plugin (renames a skill, drops a plugin, moves a setup file) and forgets a hand-written page learns it from the site's test run, not from a reader. When a hand-written page, English or Dutch, writes in backticks a `/plugin:skill` command, an `install <plugin>@<marketplace>` target or a `docs/agents/*.md` path that does not exist in the repository, the test run fails and names the page and the token. This holds for prose and for code blocks alike. The pages as they stand pass without any per-page exception.

This serves the map's Destination: hand-written pages next to the generated reference, kept honest against the plugins' own files.

## Terms used here

- **Hand-written page**: every Markdown file under `apps/site/src/content/pages/<lang>/`, for each language folder (today `en` and `nl`, one file each). Pages the generator builds from plugin files are not hand-written and not in scope.
- **Backticked token**: the text of an inline code span (between single backticks, in a paragraph, list item, heading or link text) or of a fenced code block, as the page's author wrote it.
- **Existing command**: a `/plugin:skill` whose `plugin:skill` is a skill source folder or a skill frontmatter `name` under `plugins/<plugin>/skills/`, exactly as AC-19 of 188 defines it today.
- **Existing install target**: `install <plugin>@<marketplace>` where `<plugin>` is listed in `.claude-plugin/marketplace.json` or has a folder under `plugins/`, and `<marketplace>` is `wimsuenens`, exactly as AC-19 of 188 defines it today.
- **Existing path**: a backticked `docs/agents/<name>.md` that appears verbatim as a substring of at least one `plugins/**/SKILL.md`. The source of truth is the skill text that writes or reads that file, because the setup skills are what create it in a user's repository.

## Acceptance criteria

**AC-1 A command in prose is checked.**
Given a hand-written page with a `/plugin:skill` command inside an inline code span in a paragraph (not in a code block),
when the site's test run executes,
then it fails with a message that names the page and the command when no such skill exists, and passes when the skill exists.

**AC-2 An install target in prose is checked.**
Given a hand-written page with `install <plugin>@<marketplace>` inside an inline code span,
when the test run executes,
then it fails, naming the page and the target, when the plugin is neither listed in `.claude-plugin/marketplace.json` nor a folder under `plugins/`, or when the marketplace is not `wimsuenens`; it passes otherwise.

**AC-3 A `docs/agents/*.md` path is checked, in prose and in code blocks.**
Given a hand-written page with a `docs/agents/<name>.md` path in an inline code span or in a code block,
when the test run executes,
then it fails, naming the page and the path, when that exact path does not appear in any `plugins/**/SKILL.md`, and passes when it does. A path that appears only in a file that is not named `SKILL.md` (a README, a reference file, an agent file, an ADR) does not count as existing.

**AC-4 Each new rule has a control test that proves it fires.**
Given the widened check run on fixed input rather than on the real pages,
when the control tests execute,
then there is at least one control per rule, each with an expectation written before it ran:
(a) a nonexistent `/plugin:skill` inside an inline span is reported, and an existing one is not;
(b) a nonexistent install target inside an inline span (unknown plugin) is reported, a wrong marketplace is reported, and a listed plugin passes;
(c) a nonexistent `docs/agents/<name>.md` is reported, in an inline span and in a code block, and `docs/agents/factory.md` is not reported;
(d) a control for each of the three that supplies the bad token only in a Dutch page (a fixed copy of the Dutch page with one token changed) is reported with that page named.
A control that passes when its rule is disabled does not count.

**AC-5 Both languages are covered, and so is a page added later.**
Given the content folder with one file per language today,
when a hand-written page is added under any `apps/site/src/content/pages/<lang>/` folder,
then the widened check reads it without an edit to the check or a page list in the check; the set of files read is computed from the folder, and the test fails if that set is empty.

**AC-6 The current pages pass without an exception list.**
Given the pages as they stand on this branch (English and Dutch Getting started),
when the widened check runs on them,
then it reports nothing, and the check contains no per-page, per-token or per-line exception, skip list or allow list. A token the rules do not cover (for example `/reload-plugins`, `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, `gh`, `wimsuenens`, `mattpocock-skills` written alone, `Run /reload-plugins to activate.`) is not reported because no rule matches it, not because it is listed. If a real drift is found in a page, the page is fixed in this slice instead of the token being excused.
(Under test, #240: this is the criterion that a correct page raises no false alarm and that no rule needs an exception list. Also covers AC-1 to AC-3 on the real pages: every backticked command, install target and `docs/agents` path on the two pages exists.)

**AC-7 Code blocks give the same result as before.**
Given the code blocks of the current English and Dutch pages and the AC-19 control input of 188 (`/factory:no-such-skill`, `/nosuch:idea`, `install nosuch@wimsuenens`, `install factory@other`, `/factory:idea`, and the two `mattpocock-skills` listed/unlisted inputs),
when they are run through the widened check,
then the reported tokens for commands and install targets are identical to what the check reported before the widening, token for token, and the AC-19 and AC-20 tests of 188 pass unchanged and still contain the same assertions. The only new result a code block can produce is from the new path rule (AC-3), and no current code block holds a `docs/agents` path.
(Under test, AC-19: widening to all backticked tokens must change no result for code blocks.)

**AC-8 Inline spans do not cause false alarms on prose that merely looks like a name.**
Given a page whose inline spans hold: a command with no plugin part (`/reload-plugins`, `/plugin marketplace add ...`), a sentence quoted from a tool (`Run /reload-plugins to activate.`), an environment variable, a shell command (`claude plugin marketplace add WimSuenens/agent-plugins`), a bare plugin name, a path outside `docs/agents/` (`docs/adr/0001.md`, `apps/site/...`), and a URL containing a colon (`https://example.org/a:b`),
when the widened check runs,
then none of them is reported. A `/word:word` form is a command only where the AC-19 pattern already treats it as one (preceded by start of line, whitespace, a backtick, a quote or an opening parenthesis); this criterion pins that the inline reading uses the same pattern, so a URL or a `:`-separated word is not mistaken for a command.

**AC-9 A failure names the page and the token.**
Given a hand-written page that fails any rule,
when the test run reports it,
then the message holds the page's language and file name (`nl/getting-started.md`) and the offending token (`/factory:no-such-skill`, `install nosuch`, `docs/agents/nope.md`), so the maintainer fixes it without searching.

**AC-10 The path rule asks the skills, not a list.**
Given a skill that stops mentioning `docs/agents/factory.md` in every `plugins/**/SKILL.md`, as a fixed copy of the skill files in a temporary folder,
when the widened check runs against that copy,
then `docs/agents/factory.md` on a page is reported, and when one `SKILL.md` in the copy mentions it, it is not reported. The check holds no list of known paths.

## Mapping from the frame's Under test lines

| Under test (frame) | Acceptance criteria that would show the contradiction |
|---|---|
| #240: a backticked token on a current page fails the widened check although the page is correct, or a rule cannot be written without a per-page exception list | AC-6 (current pages pass, no exception list), AC-8 (look-alike tokens not reported), AC-10 (path rule needs no list) |
| Names in code blocks are already checked (AC-19): widening changes a result for code blocks | AC-7 (identical results for code blocks; the 188 tests unchanged) |

Frame Behaviour, line by line: names and paths in backticks, anywhere in the page, English or Dutch (AC-1, AC-2, AC-3, AC-5); fails when the name or path does not exist (AC-1 to AC-3, AC-9); the `docs/agents` path counts as existing when verbatim in some `plugins/**/SKILL.md` (AC-3, AC-10); a control test per new rule (AC-4).

## Out of scope

Everything the frame lists as deliberately faked, and what the ticket keeps out:

- Behaviour claims in prose ("the second command writes ...", "only GitHub trackers are supported"): a reviewer's job, in [#245](https://github.com/WimSuenens/agent-plugins/issues/245). No criterion here tests them.
- Claude Code behaviour claims (`/reload-plugins`, `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, "a session keeps the skill text it read"): the source of truth is outside this repository. AC-6 and AC-8 pin only that they are not reported.
- The "builds on" relation against `plugin.json` `dependencies`: the sentence is prose, not data.
- Paths other than `docs/agents/*.md` (`docs/`, `plugins/`, `apps/`): no rule in this slice; no page holds one.
- Strings in `apps/site/src/i18n/ui.mjs` (Home and Reference intros): not Markdown pages under the content folder.
- No page content is added. Only the check, its control tests, the two stale deferral lines in `docs/requirements/188-wiki-shell.md`, and a page fix if the check finds a real drift change.

## Decisions (two-way doors decided here)

- **The path rule's truth source is the skill text, not the file system.** A `docs/agents/*.md` file lives in a user's repository, so the plugin repository cannot be asked whether it exists; the setup and run skills that write or read it are the nearest source. Rejected: checking `docs/agents/` in this repository (a different set of files, which exist only because this project ran the setup skills). Cost to undo: change the source in the check; an hour.
- **The path rule covers `docs/agents/*.md` only.** Rejected: all `docs/` or `plugins/` paths, which the research found no page using and for which the skills hold no matching source. Cost to undo: one pattern and one control; an hour.
- **Existing rules are widened, not replaced:** the AC-19 patterns and its existence tests are reused, so AC-7 can state "identical". Cost to undo: none beyond the check itself.
- **A real drift found on a current page is fixed in the page in this slice**, not excused (AC-6). Cost to undo: a page edit.
- **The two stale deferral lines in 188 are rewritten in this slice** (done with this requirement): line 203 now says names and paths on hand-written pages are checked, and line 212 now says only behaviour claims stay a reviewer's job (#245). Cost to undo: two lines.

## Open questions

1. Where the in-scope tokens come from: the raw Markdown of each page (spans and fences as the author wrote them) or the rendered HTML (the `code` elements the build produces). The criteria hold for either; the two differ in edge cases (a span inside link text, a span with escaped backticks, a double-backtick span, an inline span that wraps over a line). AC-1 to AC-3 and AC-8 name inline spans and fenced blocks in the author's text; the architect decides the source and confirms the edge cases fall inside it. Owner: architect.
2. Whether the check lives next to AC-19 in `tests/site/getting-started.test.mjs` or in a test of its own, since it now reads every hand-written page and not only Getting started. AC-5 and AC-7 hold either way, provided the 188 AC-19 and AC-20 tests keep their assertions. Owner: architect (the test file itself is qa-engineer's).
