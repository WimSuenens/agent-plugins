# 60 — Gemba sample: the Lead walks one stage per item

Slice: [#60](https://github.com/WimSuenens/agent-plugins/issues/60) · Map: [#34](https://github.com/WimSuenens/agent-plugins/issues/34) · ADRs: [0011](../adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on: [39-hansei-record](39-hansei-record.md), [49-andon](49-andon.md), [57-per-run-a3-and-baseline](57-per-run-a3-and-baseline.md)

## User outcome

At every item close, before the hansei record is written, the Lead walks **one** stage of the item that a stated rule picks. It reads what the agent actually did (its transcript, or its commits and result file; never the agent's own summary) and compares it with the brief it was given and with its row of the stage log. The hansei record then carries **one line** that says which stage was walked, what the walk found, and whether it changes anything. The person reading the record sees whether the factory's own paperwork matched the work, without reading a transcript.

What the walk finds is a question about the process (the brief, the inputs, the standard's text, the tooling, the ownership table, the order of stages), never a verdict on a person, a role or a model. A walk that could not be done says `not captured (<reason>)`; it never reads "nothing found", and it never reads 0.

This serves the map's fifth *Done when* line (the gemba half; "blame the process first" was written into the standard by requirement 49 and is reused here) and loop 1 of the map's Decisions ("hansei + one gemba sample" per item).

## Terms used here

- **Gemba**: going to where the work was done and looking at it, instead of reading a report of it. Here: the walk of one stage.
- **Walk**: the Lead's reading of one stage's work, bounded by a context cap (AC-6).
- **Stage log**, **row**, **lead state**: as in `references/hansei.md`. A **role row** is a row whose `Role` is one of the seven role agents and whose `Agents` column is not `-`.
- **Eligible row**: a role row whose `Result` starts with `done` or `pass`, and whose `Notes` do not read `paused by A<n>`. A row that ended in `findings`, `blocked`, `refused`, `needs-decision` or `block`, or was paused by an andon, was already examined by feedback or a 5 Whys; the walk goes where the log is silent.
- **Sampled row**: the row the rule of AC-1 picks.
- **Evidence**: the transcript of the sampled row's agent(s), else the sampled role's commits on `item/<id>` and its result file. **Not evidence**: the result file's `Summary` field, the completion notice's text, the stage summary comment on the tracker (these are the agent's own report, which the walk checks).
- **Gemba line**: the one line of the hansei record (AC-4).
- **New standard**: the factory as it is on branch `item/60`, checked by reading its text step by step and applying it to fixtures (no acceptance demo gates this slice, see the map's *Verification* decision).
- **Honesty rule**: a value is a measured value, `0` when truly zero, or `not captured (<reason>)`; never a guess, never blank, never dropped.

## Validation data

The sample rule is a counted rule, so it is replayed on stage logs that already exist, by QA or the developer (never the architect), following the standard's text step by step. QA writes, before the replay, the row each log must give and why.

| Name | Where | What it is |
|---|---|---|
| **W12** | `references/hansei.md`, section 4 (the worked example of item #12) | a 13-row stage log in the current shape: a QA row that ended in `findings`, a Build row `paused by A1`, lead rows, a `done, then stalled` row. |
| **C49** | [#49 stage-log comment](https://github.com/WimSuenens/agent-plugins/issues/49#issuecomment-6691671841) | manual log, 15 rows, no `Notes` or `Waits` column, `Result` free text (`pass (3 medium, 2 low)`). The shape of a log written by hand. |
| **L57** | [#57 stage-log comment](https://github.com/WimSuenens/agent-plugins/issues/57#issuecomment-6700562237) | manual log, 26 rows (0 to 25), `Notes` and `Waits` columns, lead and person rows, rounds, andon rows, a `block` row, `not captured` times. |

For the author's cross-check only (QA recomputes independently and states its own expected rows): by the rule of AC-1, W12 has six eligible rows (2, 3, 4, 7, 10, 11) and `12 mod 6 = 0` picks row 2; C49 has eleven eligible rows (2, 3, 4, 6 to 13) and `49 mod 11 = 5` picks row 8.

Facts found while writing this: no hansei record that carries a gemba line exists yet, so there is nothing to replay for the line itself; the line (AC-4) and the walk (AC-2, AC-3) are tested on fixtures QA writes in `tests/`: a fixture brief, a fixture stage-log row, and a fixture transcript or commit list, applied by following the standard's text. The rule under test is read off the Lead's written line.

## Acceptance criteria

All criteria are checked by QA against the branch, offline (the plugin files and fixtures QA writes in `tests/`), unless marked **[post-merge]** (checked by the Lead after the merge). There is no human-only criterion. What only live use can show is listed under *Unverified* below. Where a criterion depends on the line's exact grammar or the step's place, that is the architect's contract, fixed before the build.

### A. Picking the stage (Loops)

**AC-1 The sample is picked by a counted rule that two readers apply the same way.** *(Under test: Loops; validation: W12, C49, L57)*
Given the new standard and a stage log,
when the Lead picks the stage to walk,
then it applies this rule and nothing else: list the eligible rows in log order; with `n` eligible rows, the sampled row is the one at index `(slice ticket number mod n)`, counting from 0; when no row is eligible, the eligible set is every role row (the walk then also notes that the sampled row was already flagged); when there is no role row, no stage is picked (AC-5). The slice ticket number is the item's id. The rule reads the stage log only: no durations, no judgement, no earlier record.
And given W12, C49 and L57 and the fixture variants QA writes (all role rows flagged; exactly one eligible row; two role rows of the same role; a `Result` of `done, then stalled`; a row `Agents` `-`; a lead row; a person row; a manual log with no `Notes` column), applied once by the Lead's text and once by a second reader who has only the standard's text (a person or a fresh agent),
then both pick the same row on every input.
It is contradicted if two readers pick different rows on any input, or if the rule needs a measure the log does not hold.

### B. What the Lead reads and compares (Capture)

**AC-2 The Lead reads what the agent did, not what it said, and compares it with the brief and the stage log.** *(Under test: Capture)*
Given the sampled row,
when the Lead walks it,
then the standard tells it to read, in this order of preference: (1) the transcript of the row's agent(s), found through the stage log's `Agents` column as `hansei.md` already finds transcripts; (2) when no transcript can be read, the sampled role's commits on `item/<id>` (messages starting `#<id> <role>:`, their diffs) and the role's result file in `work/<id>/`; and that it never uses the `Summary` field, the completion notice's text or the stage summary as evidence (a fixture where the result's `Summary` says `done` while the transcript shows otherwise reads as the transcript shows).
And it tells the Lead to compare what it read with two things: the **brief** of that stage (`work/<id>/NN-brief-<role>.md`: each `Done` item, each `Constraints` item, the `Output` paths) and the stage's **row** in the stage log (its `Result`, `Notes` and `Waits`), and to look for exactly these: a `Done` item with no trace of the work in the evidence; work in the evidence that the brief's `Constraints` or the role's ownership forbids; a row `Result` or `Notes` that the evidence contradicts.
It is contradicted if the standard lets the walk start from the agent's summary, or if the walk compares with the stage log alone.

**AC-3 A walk can find what the stage log cannot show, and "found nothing" carries its count.** *(Under test: Loops, Capture)*
Given three fixtures of one sampled row, each with the same stage-log row (`Result` `done`, no note) and a brief of three `Done` items and two `Constraints`:
- (a) evidence in which the third `Done` item has no trace (the result's `Summary` claims it);
- (b) evidence in which every `Done` item and `Constraints` item is met;
- (c) evidence in which the agent edited a path its role does not own,
when the Lead follows the standard,
then (a) and (c) are written as a difference, one sentence naming the item (the brief's `Done` item, or the path) and the process object concerned, and (b) is written `found nothing (3 Done items and 2 constraints checked)`, with the counts the brief gave; a `found nothing` without those counts is refused.
It is contradicted if (a) or (c) reads as nothing found, or if (b) reads without its counts, or if any of the three needs the stage log alone to be written.

### C. The line in the record (Loops; Measures)

**AC-4 One gemba line, in a v5 record, in the header, not a measure.** *(Under test: Loops, Measures)*
Given the new standard,
when the hansei template is read,
then the record's marker is `<!-- factory:hansei v5 -->`, and there is exactly one new line, `gemba`, placed in the header block directly after `stage-log cross-check` and before `### Measures`; it is always present; it carries, in this order: the sampled row (its `#` and stage and role), what was read (`transcript` or `commits and result file`, with the number of characters read and, when the cap stopped the walk, `partial` with the reason), what was found (`nothing` with its counts as in AC-3, or `difference` with one sentence), and whether it changes anything (`nothing`, or `process item:` followed by the process item to change and the link of the 5 Whys, or `none: needs a plugin change`, which the Lead handles as an andon's plugin-change proposal is handled); the line is one line, holds no transcript text, no 5 Whys text and no raw record text, and cannot be left out; a v5 record whose gemba line is absent is a malformed record the baseline reads as unreadable and names.
And the measures stay seven and numbered 1 to 7, unchanged in key, order and grammar.
And the standard says why the version is v5 and not a field inside v4: its own rule (`hansei.md`, *Marker*) bumps the version on any change to a field's key or order, and a reader that does not know the line skips the record and says so.
It is contradicted if the line sits among the numbered measures, or is optional, or if a record can carry two gemba lines.

**AC-5 A walk that cannot be done reads `not captured`, never "nothing found", never 0.** *(Under test: Measures; honesty rule)*
Given these fixtures: (a) the sampled row's transcript file is deleted or unreadable and the commits and result file are readable; (b) transcript unreadable and the sampled role's commits or result file cannot be read (the role worked in a project the Lead cannot reach); (c) the log has no role row; (d) the sampled row's `Agents` entry names an id with no transcript and no commits,
when the Lead writes the line,
then (a) reads the walk from the commits and result file and says so in `read`; (b) and (d) read `gemba: row <#> <stage> (<role>); not captured (<reason>)`; (c) reads `gemba: not captured (no role stage ran)`; none reads `found nothing`, none reads a count of 0 in place of a missing walk, and none is left blank or dropped.
And a walk stopped by the cap (AC-6) reads `partial` and writes only what it found so far; a partial walk that found nothing reads `found nothing in the part read (<n> chars of <m>)`, never plain `found nothing`.
It is contradicted if a walk that did not happen reads as a walk that found nothing.

### D. Cost (Loops)

**AC-6 The walk has a hard cap on what the Lead reads.** *(Under test: Loops)*
Given the new standard,
when the walk is read,
then it tells the Lead to read the evidence only through a bounded, filtered command (a filter that keeps the tool calls, their results' first lines, the final reply and the commit diffs' file lists and changed lines, cut by `head -c 30000`), so the cap is enforced by the command and not by the Lead's judgement; the total read for one walk is at most **30,000 characters**, and the line records the number actually read (`wc -c` of what the command returned); when the evidence is longer, the walk reads the filtered view's head, may follow one more bounded read of the specific part a `Done` item points to within the same total, and writes `partial` (AC-5); the walk never reads a whole transcript, and never starts a second walk of another stage.
And given a fixture transcript of 200,000 characters, the written line shows a number read of 30,000 or less and `partial`.
It is contradicted if any text of the standard lets one walk read more than the cap, or if the cap is only advice.

### E. Blaming the process (Respect for people)

**AC-7 A finding goes to the 5 Whys under the rule already in the standard; it cannot end in "the agent was wrong".** *(Under test: Respect for people)*
Given a walk that found a difference,
when the Lead records it,
then the difference goes to a 5 Whys written under the rule of `skills/run/SKILL.md`, *The 5 Whys* (a numbered chain of at most five whys, each cause naming a process object with evidence, ending in `process item to change: …`), before the hansei record is posted, in the place the architect names (leaning: an andon of kind 7 with no paused agent, so that its comment holds the chain and the record's `abnormalities` line links it); the gemba line's `changes` part is that chain's `process item to change`, and its `found` sentence names a process object, not an actor.
And the standard does not restate the rule a second time: it points to *The 5 Whys*, so one change edits both.
And given three fixture gemba lines with their chains: (a) found `the developer skipped the third Done item`, chain ending `the developer should have checked`; (b) found `the agent's model is too weak to follow a three-item brief`, countermeasure a model swap; (c) found `the brief's third Done item named no output path`, chain ending `process item to change: the brief template lists no output path per Done item`,
when the Lead follows the standard,
then (a) and (b) are refused (not written to the line, redone) and (c) is accepted; a line whose `found` or `changes` part names a person, a role's care or competence, or a model, with no process item, is never written.
It is contradicted if a gemba line can end in "the agent was wrong" without naming a process item to change.

### F. Scope, reading old records, the honesty line, release (Measures; Loops)

**AC-8 No eighth measure, no hoshin view, no aggregation; old records stay readable.** *(Under test: Measures; Deferred: hoshin view, metrics store)*
Given the new standard and the baseline rules (`references/baseline.md`),
when they are read and then applied to records of v3, v4 and v5,
then the standard reads v3, v4 and v5 (the baseline's skip list names only other versions; a v3 or v4 record has no gemba line and is read without one, with no `not captured` entry created for it); the baseline's seven measures, their medians and sections are computed exactly as before (a v5 record's measures enter the series of its release as v4's do); no baseline or A3 field reads a gemba line; no script reads or counts gemba lines; no hoshin view, no view of gemba lines over items or runs, and no count of `found nothing` against differences exists in the new standard; the gemba line's characters-read figure is a label on the line, not a measure, and enters no section.
It is contradicted if any figure of the baseline or the A3 depends on a gemba line, or if a seventh measure is joined by an eighth.

**AC-9 The close step is placed once, and the standard says why gemba transfers.** *(Under test: Loops; honesty rule of the map)*
Given the new standard,
when `skills/run/SKILL.md` step 8 and `references/hansei.md` are read,
then the walk is one numbered action of step 8, after the cross-check and the token totals and before the hansei template is filled (the architect names the number), the close order in `hansei.md` section 5 names the same place, and the walk is done after the merge approval so its time is part of no measure (lead time ends at the approval).
And the standard holds one line that says why gemba transfers to an agent factory, in the words of the honesty rule: an agent's summary is written by the party being checked, and the stage log holds clocks and counts, not what was done, so the only place the work shows is the transcript or the commits; the Lead goes and looks at a sample instead of trusting a report.
It is contradicted if the walk is described in two places with different steps, or if the standard adopts gemba with no line saying why.

**AC-10 Release 1.3.0, standard-work paths only, no home paths, no project data; the unverified list.** *(ADR 0011, 0012, 0013)*
Given branch `item/60`,
when the diff against `main` is read,
then `plugins/factory/.claude-plugin/plugin.json`'s `version` is `1.3.0` (a minor bump above `1.2.0`: standard work changes), the Lead's bump check (`scripts/check-bump.sh`, requirement 39 AC-8) passes, and the new `standard` and `tooling` fingerprints are quoted in QA's verdict (the fingerprint moves because `skills/run/SKILL.md` and `references/hansei.md` change; `tooling` is expected unchanged unless a script is added); every changed path under `plugins/factory/` is `skills/run/SKILL.md`, a file in `references/`, a file in `scripts/` (only if the architect adds one), or `.claude-plugin/plugin.json`; no new role, no new agent file; a search of every file the diff adds or changes finds no absolute home path (any path that starts at a user's home directory, on any platform) and no project data (a name, number or link from a project other than this repository's own issues); and the 1.3.0 entry of `CHANGELOG.md` lists as **unverified** what offline tests cannot show: the sample rule under real load, the walk's cost in a long item, a real transcript read in a project's own checkout, how often a walk finds a difference, and the 5 Whys of a real gemba finding.
And **[post-merge]**, given the PR for #60 is merged, the tag `factory-v1.3.0` exists and points at the merge commit on `main`; this item runs on the frozen install `9147301f75c3` as calibration (ADR 0012), so the Lead's own close of #60 carries no gemba line and no `Factory baseline` issue is created in agent-plugins' tracker by it. The first item on 1.3.0 starts the new series `1.3` (the minor bump resets the baseline, requirement 57's AC-5, not rewritten here).
It is contradicted if a path outside the list changes without being named, if the bump check fails, or if the changelog presents any of the unverified items as verified.

## Unverified

Offline checks cannot show these, so the release names them as unverified and real use settles them by feedback issues (the map's *Verification* decision):

1. Whether the rule of AC-1 picks stages that teach the Lead something under real load (the proportion of `difference` against `found nothing` over items).
2. Whether the walk stays within its cap and its cost is worth the record in a long item, with a large transcript (the Lead's context).
3. Whether the transcript is readable by the Lead in the project's own checkout during a real run (the same path `cut-offs.sh` and `token-spend.sh` already read; the fallback to commits and result file is tested offline).
4. Whether a real 5 Whys from a gemba finding ends in a process item without the Lead's correction.
5. Whether the deferral "an observer subagent doing gemba" has reason to fire: the line's characters-read figure is the observable (the trigger: the Lead's context runs out during gemba).

## Under test → criteria

| #60 Under test line | Criteria that would show the contradiction |
|---|---|
| Loops: picked by a rule (two Leads agree); cost within the Lead's context; its line not always "nothing found" | AC-1 (rule); AC-6 (cost cap); AC-3 (a walk can find, "found nothing" carries counts); the live proportion and long-item cost are **unverified** (items 1, 2) |
| Capture: the Lead reads real work in the project, not summaries; the walk is more than the stage log | AC-2, AC-3 (compares with the brief and the evidence); AC-5 (unreadable evidence); readability in a real project checkout is **unverified** (item 3) |
| Respect for people: the line and the 5 Whys cannot end in "the agent was wrong" | AC-7 (reuse of *The 5 Whys*; refused fixtures); the real chain is **unverified** (item 4) |
| Measures: no eighth measure; a missing sample reads `not captured`, never 0 | AC-4 (header line, seven measures unchanged); AC-5 (`not captured`); AC-8 (no new measure, no aggregation) |

## Out of scope

From the frame's **Deliberately faked**:
- The per-project hoshin view, and any view that reads gemba lines over items or runs (Deferred: its trigger is a baseline with data from several runs).
- An acceptance demo: no demo gates this slice; the unverified list above goes in the changelog.
- Automatic aggregation of gemba lines, a script that reads them, a count of differences against `found nothing`, and a metrics store (the Lead reads them, as with hansei before a script exists).

Also out of scope:
- An observer subagent doing the walk for the Lead (Deferred: its trigger is the Lead's context running out during a walk).
- More than one sampled stage per item, a walk of a frontier round (no hansei record for frontier rounds yet), and a walk of the Lead's own stages (it checks the agents' work; the person checks the Lead through the record and the A3).
- Rewriting "blame the process first": it stays as requirement 49 and `skills/run/SKILL.md` have it; the walk only reuses it (AC-7).
- Sampling by risk, severity or randomness; the rule is stateless and counted (Decision 1).
- Reading gemba lines in the A3 or the baseline, an eighth measure, a change to the seven measures' grammar.
- Changing the fence (ADR 0011), the release or merge rules (ADR 0012, 0013); the gemba line is not a fenced item and an override cannot remove it (it is part of the record, whose layout the fence already holds).
- The person's own gemba (loop 3) and who picks the hoshin themes (the map: *Not yet specified*).

## Decisions

Two-way doors decided here (chosen / rejected / cost to undo). No one-way door was found: every choice below is a text change to standard work, reversible by a minor release; records already posted as v5 stay readable by a standard that reads v5.

1. **The sample is the eligible row at index `ticket number mod n`.** Rejected: the longest row (it always picks Build, and manual logs hold `not captured` and free-text durations that two readers parse differently); a rotation that reads the previous item's sample (needs a record that holds the line, and none exists); the stage with the most findings (already examined by feedback or an andon, so the walk would restate the log); a random pick (not replayable). Undo: one rule; no data is lost.
2. **Eligible means `done` or `pass`, not flagged by an andon.** Rejected: all rows (the walk would go to rows that a 5 Whys or feedback already covered). Undo: one rule.
3. **Evidence order: transcript, then commits and result file; the `Summary` is never evidence.** Rejected: commits only (the transcript shows work that left no commit and the commands run). Undo: one rule.
4. **Compare with the brief and the stage-log row, looking for three things (a missing `Done` item, work outside the constraints or ownership, a row the evidence contradicts).** Rejected: an open "look for anything" (two Leads would not write comparable lines). Undo: one rule.
5. **`found nothing` carries its counts; a partial walk says `partial`.** Rejected: a bare `found nothing` (it would read the same for a walk of three items and no walk). Undo: one grammar line.
6. **Cap: 30,000 characters per walk, enforced by the read command.** Rejected: no cap (fails the Under test cost line) and a cap in tokens (the Lead cannot count them before reading). The number is a guess to be tuned by feedback (unverified, item 2). Undo: change one number.
7. **The line is a header line after `stage-log cross-check`, in schema v5.** Rejected: a field inside v4 (breaks the standard's own versioning rule, so a v4 reader would not skip a record it does not understand), and an eighth numbered measure (the map allows at most seven). Undo: a v6 that moves or drops it; v5 records stay readable.
8. **A difference always goes to a 5 Whys, before the record is posted.** Rejected: a 5 Whys only for differences the Lead judges serious (that is a judgement of a person's work, not of the process), and a 5 Whys after the record (the line would link nothing). Undo: one rule.
9. **The walk comes after the merge approval, so its time is in no measure.** Rejected: before the approval (it would lengthen the lead time of the item by Lead bookkeeping). Undo: move one step.
10. **No gemba line for an item run on a pre-release install (calibration).** The frozen install has no text for it; this item (#60) is calibration like #57. Undo: none needed.

## Open questions

- **Architect**: the contract for the gemba line's exact grammar (AC-4); the place of the walk in step 8 and the renumbering (AC-9); where the 5 Whys of a difference is written (AC-7; leaning: an andon of kind 7 with no paused agent, so `abnormalities` links it and the fence, refusal and `Refused drafts` rules apply unchanged; the alternative is a comment of its own, which would add a marker); the bounded read command and filter (AC-6), and whether it is text in `hansei.md` or a script (a script moves the `tooling` fingerprint only; leaning: text, no script); how the baseline's skip list is updated to read v5 (`references/baseline.md`, section 3) and the `Which versions the standard reads` text of `hansei.md`; adding *Gemba* to `CONTEXT.md`.
- **Architect**: whether a kind 7 andon raised at close, after the merge approval, fits the andon's own timing rules (its row, its wait, the `Held item` split) without a change to lead time, since the approval already ended the lead time.
- **QA**: the fixtures of AC-1 to AC-7 and the independent expected rows for W12, C49 and L57, written before the replay.
- **Docs-writer**: the changelog's unverified list (AC-10) and the README text for the new line.
- **Lead**: none now. The map's deferred observer subagent (trigger: the Lead's context runs out during gemba) stays open; this slice supplies its observable (the characters-read figure of the line).
