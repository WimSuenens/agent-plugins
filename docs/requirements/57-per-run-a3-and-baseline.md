# 57 — Per-run A3 and a baseline issue: the run ends with one problem and one experiment

Slice: [#57](https://github.com/WimSuenens/agent-plugins/issues/57) · Map: [#34](https://github.com/WimSuenens/agent-plugins/issues/34) · ADRs: [0011](../adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on: [39-hansei-record](39-hansei-record.md), [49-andon](49-andon.md)

## User outcome

The person running the factory in a project has one place that says what "normal" looks like for that project on the factory release it runs: a pinned **Factory baseline** issue that the factory tells the project to set up and keeps up to date from the project's own hansei records. Where a number is missing, the baseline says so and never shows 0.

When a run ends, the person gets one **A3** on the project's tracker and one question. The A3 names the one problem the run worked on, the 5 Whys behind it (blaming the process first), the one countermeasure that was tried as a local override, how the measure moved **before and after** against the baseline (with the item numbers, how many items, and the release), and what is still uncertain. The question is the settle line of requirement 49, now carrying those numbers: keep, promote or drop. Promoting never changes the plugin by itself: it puts a decision card in front of the person. The batch of factory-feedback issues at the end of today's step 9 shrinks to what the A3 lists and the person approves; nothing about the project reaches `WimSuenens/agent-plugins`.

This serves the map's third and fourth *Done when* lines (the baseline part): every run ends with one A3 on one problem and one countermeasure experiment, measured before and after against the project's baseline; each project has a baseline that the plugin tells it to set, record and update. The hoshin view, its themes and the parked-concept triggers (the rest of the fourth line) are not in this slice.

## Terms used here

- **Baseline issue**: the project's pinned issue titled `Factory baseline`, in the project's own tracker. Its layout is the architect's contract; this requirement fixes what it must hold and how its numbers are made.
- **Record**: a hansei comment found by its first line `<!-- factory:hansei v<n> -->` (requirement 39). A comment with no such line (the manual calibration comments on #39 and #49) is **not a record**.
- **Readable record**: a record whose schema version the new standard reads (the current one). Any other version is skipped and named, as the hansei standard already says.
- **Series**: the release's major and minor, `X.Y`, taken from the record's `plugin: factory <semver>` line when its `series:` line reads `release`. A record whose `series:` reads `calibration (pre-baseline)` belongs to no series.
- **Section**: one block of the baseline issue: a series, plus the set of overrides that were in force for the whole of each item in it (none, or named). The **reference section** is the one the next experiment is measured against.
- **Experiment**: the run's one countermeasure, an override (ADR 0011) that names the measure it is meant to move.
- **Before, during, after items**: relative to the experiment's override: *before* = closed before the override started, in the same series; *during* = in flight when it started; *after* = started with it in force and closed within the run (how long after-items are counted is the architect's, see Open questions).
- **A3**: the one-comment report of a run's problem, countermeasure and reading. Its marker and layout are the architect's contract.
- **Run close**: the ordered end of a run, defined in group D.
- **Settle round**, **override**, **fence**, **andon**, **fixture**, **standard work**, **tooling**: as in requirements 39 and 49. The new standard is the factory as it is on branch `item/57`, loaded with `claude --plugin-dir <worktree>/plugins/factory` in a separate session on the sandbox repo (the install stays frozen, ADR 0012).
- **Honesty rule**: a value is a measured value, `0` when truly zero, `n/a (did not run)`, or `not captured (<reason>)`; never a guess, never blank, never dropped (fenced, F7).

## Validation data

Rules in this requirement that measure or detect something are checked on records that already exist, replayed by QA (or the developer; never the architect) following the standard's text step by step:

| Name | Where | What it is |
|---|---|---|
| **S5** | [factory-sandbox #5](https://github.com/WimSuenens/factory-sandbox/issues/5#issuecomment-6691591256) | hansei v3, `series: release`, `plugin: factory 1.1.0`, 1 abnormality, `acceptance demo not captured`, `devops n/a (did not run)`. The only readable record that is not calibration. |
| **S2** | [factory-sandbox #2](https://github.com/WimSuenens/factory-sandbox/issues/2#issuecomment-6652019454) | hansei v1, `plugin: factory 1.0.0`. A schema the new standard does not read (measure 1 hid stalls and interruptions). |
| **C39** | [#39 calibration comment](https://github.com/WimSuenens/agent-plugins/issues/39#issuecomment-6666857840) | manual calibration record, no marker; measure 1 split `not captured`; 22h18m total over an overnight demo. The shape that showed why a mean would hide a missing value. |
| **C49** | [#49 stage-log comment](https://github.com/WimSuenens/agent-plugins/issues/49#issuecomment-6691671841) | manual stage log, no marker; per-role token spend `not captured`. |

QA writes the **controls** as copies of S5 changed in the named fields only, and records, before the replay, what each control must do and why: S5b (`developer` spend `not captured (transcript truncated by stalled)`, lead time total 20m with agent working 12m), S5c (`plugin: factory 1.2.0`), S5d (`plugin: factory 1.1.1`, same `standard`), S5e (`plugin: factory 1.1.1`, a different `standard`), S5f (`series: calibration (pre-baseline)`, `plugin: factory 9147301f75c3 (pre-release install, no semver)`), and C39t (C39's seven measures transcribed by hand into the record shape, with its `not captured` fields kept, once as `series: calibration (pre-baseline)` and once as `series: release` plus `plugin: factory 1.1.0`). The replay's table (rule, input, expected, found) goes in QA's verdict. The architect's contract text for each rule is fixed before the developer builds anything on it.

Facts found while writing this: #39 and #49 hold **no** marker-bearing record (their comments are manual, written before the mechanism existed), so S5 is the single real release record, and S2 is the only real record of an unreadable version. The rules are therefore also tested on the controls above; this is stated so no one reads a 5-of-5 style result into data that does not exist.

## Acceptance criteria

Criteria marked **[human-only]** can only be judged by the person in a real session running the new standard on the sandbox repo; QA lists them for the acceptance demo. Criteria marked **[post-merge]** are checked by the Lead after the merge. All others QA checks against the branch: the plugin files, any script the developer adds, and fixtures (stand-in inputs QA writes in `tests/`, applied by following the standard's text step by step; the rule under test is read off the Lead's written output). Where a criterion depends on a record's or an override's layout, that layout is the architect's contract (fixed before the build).

### A. The baseline issue (Baseline; Measures; What reaches agent-plugins)

**AC-1 The Lead finds or creates the one baseline issue at run start.** *(Under test: Baseline)*
Given the new standard and a project tracker (a fixture of the tracker commands' outputs),
when the Lead runs its run-start checks (`## Andon`, *Run start*, step 0 and again at step 5),
then it looks for the pinned issue titled `Factory baseline`; with one found it uses it and creates nothing; with none found it creates one in the project's own tracker and pins it, and tells the person in one line; with more than one found it creates nothing, uses none, and asks the person which one counts; and when pinning fails (the tracker's limit of pinned issues, or no pinning) it says so, finds the issue by its title from then on, and still never creates a second.
And the commands to find, create, pin and edit it are written where the project's other factory tracker operations are, with the fallback the run skill already gives for projects set up before the operation existed (`skills/run/SKILL.md`, the *Post hansei* fallback).
It is contradicted if a run can start in a project with no baseline issue and no word to the person, or can create a second one.

**AC-2 Setup reads the baseline back from the records that exist.** *(Under test: Baseline, Measures; validation: S5, S2, C39, C49, S5c–S5f)*
Given the project's tracker holding S2, S5, S5c, S5d, S5e, S5f and the comments C39 and C49 (as fixtures of that tracker's comment lists),
when the Lead sets up the baseline,
then it finds records by their first line only, and:
- S5, S5d and S5e are read; S5c is read into series `1.2`; S5f is read into no series and listed under a section titled `Calibration (pre-baseline)` with its item number and link; S2 is skipped and named (`skipped: schema v1`); C39 and C49 are not records, so nothing reads them and no figure of either enters any section (the person may link them by hand in the calibration section; nothing sums them);
- S5d joins series `1.1` with S5 (same `standard`, a patch release); S5e is excluded from series `1.1` and named (`excluded: standard differs under 1.1`);
- every section names the items it holds by slice ticket number and link, and the current series (the release the session runs) is the first section, reading `0 items` with every figure `not captured (no items in series)` when it holds none.
It is contradicted if a calibration record or an unreadable record changes a figure of any section, or if an item is in two series.

**AC-3 How the seven measures are read into a section, and the honesty rule on top.** *(Under test: Baseline, Measures; validation: S5, S5b)*
Given a section's records,
when the Lead writes the section,
then each field is read as follows, with `n` = the section's items and `k` = the items whose record captured that field:
- a duration, a count, a token total or a peak context: the **median** of the `k` captured values (the mean of the two middle values for an even `k`, durations then rounded half up to the whole minute), shown with `k` of `n`: `<value> (<k> of <n> items)`, and `(<n-k> not captured)` appended when `k < n`;
- a field no item captured: `not captured (<k=0> of <n> items: <reasons, each once>)`, never `0`, blank or left out;
- an item whose field reads `n/a (did not run)` is counted in neither `k` nor the not-captured count; it is counted as `n/a` beside it, and a role that ran in no item reads `n/a (did not run in any of <n> items)`;
- first-pass yield per stage, and doors (measure 7): the count of items per outcome (`pass first time`, `pass first time (low)`, `failed first time`, `n/a`, `not captured`; `confirmed`, `contradicted`, `not exercised`, `not captured`), summing to `n`; a record whose measure 7 reads `pending resurvey` or `not captured (…)` counts as `not captured`;
- escaped defects: the literal `not captured`, as the records read;
- the parts of lead time are each read on their own; the medians of the parts need not add up to the median of the total, and the section says so in one line.
No mean, no sum of captured values, and no figure computed over a field that any item did not capture without its `k of n`.
Tested on S5 alone (n = 1): lead time `18m` with parts `10m`, `5m`, `0m`, `0m`, `0m`, `3m`; first-pass yield `qa pass first time 1`, `security pass first time 1`, `acceptance demo not captured 1`; rework `qa-engineer 1`, `security-reviewer 1`, all others `0`, overturned `0`; `devops` tokens `n/a (did not run in any of 1 items)`; `docs-writer` spend `745399 (1 of 1 items)`; escaped defects `not captured`; touches `approvals 1`, `other 6`, the rest `0`; doors `confirmed 2`.
Tested on S5 and S5b (n = 2): lead time `19m`, agent working `11m`; `developer` spend `82432 (1 of 2 items, 1 not captured)`, peak context `27730 (2 of 2 items)`; `acceptance demo not captured (2 of 2 items: person did not run the demo…)`.
Tested on C39t as `series: release`: the lead time parts read `not captured (1 of 1 items: manual log, split not kept)`, not `0`, and the total reads `22h18m (1 of 1 items)`.
It is contradicted if any not-captured field shows `0`, a median of captured values is shown without its `k of n`, or a `n/a` role is read as zero.

**AC-4 A calibration record never enters a baseline.** *(Under test: Measures; ADR 0012)*
Given the section for series `1.1` written from S5 alone and again from S5 plus S5f plus C39t-as-calibration,
when the two are compared,
then every figure and every item list is identical, and S5f and C39t appear only under `Calibration (pre-baseline)`.
And given an experiment whose before-items would include S5f,
then the A3's before reading does not use it (AC-14).
It is contradicted if a calibration item changes a release baseline or is used as a "before". This run (#57) is itself calibration: see AC-27.

**AC-5 A release change starts a new section; the old one stays as history.** *(Under test: Baseline)*
Given records S5 (`1.1.0`), S5d (`1.1.1`, same `standard`), S5c (`1.2.0`) and S5e (`1.1.1`, different `standard`),
when the baseline is written, in this order of events: S5, S5d, then S5c arrives,
then series `1.1` (S5, S5d) is unchanged by S5c's arrival and moves from current to **history** with the date and the release that replaced it; `1.2` becomes the current section holding S5c alone; a patch release (`1.1.0` to `1.1.1`) starts no new section; a tooling-only difference (same `standard`, different `tooling`) starts no new section (ADR 0012, as settled by #39); a difference in `standard` under one `X.Y` is excluded and named, and the Lead says that the forgotten bump belongs to the andon of kind 6 (it does not start a section silently).
It is contradicted if a patch or a tooling-only change resets the baseline, or if a minor release leaves the old section off the issue.

**AC-6 An adopted countermeasure starts a new reference section; a dropped one leaves a note.** *(Under test: Baseline; Bounds of a local countermeasure)*
Given a series `1.2` whose items are before-items (no override), after-items (override `X` in force for the whole item) and one during-item (override `X` started inside it), and the person's answer to `X` at the settle round,
when the baseline is updated after the answer,
then for `keep` and for `promote` the reference section becomes the section of items with `X` in force (it starts empty if no after-item exists yet and reads `0 items`), and the earlier section moves to history labelled `before X (<kept|promote chosen> <date>)`; for `drop` the section with `X` moves to history labelled `X dropped <date>`, the reference section stays the one without `X`, and the baseline carries a note `X dropped <date>` (ADR 0011, point 5); the during-item is in neither section and is named in the history label.
It is contradicted if an answer leaves the old reference unnoticed, or the during-item is counted in a section.

**AC-7 Update at the item's close, repaired at run start.** *(Under test: Baseline)*
Given the new standard,
when it is read,
then it tells the Lead to rewrite the current section from all readable records of the series after each item's record has reached its final state (measure 7 edited by the resurvey, or `not captured (run stopped before the resurvey)`), in the item's close order, after *Edit hansei* and before the next item or the run close; the update is a recomputation from the records, so running it twice gives the same text; and it puts the number of records read and the minutes the update took in the stage log's notes for that step.
And given a fixture where the previous run was stopped before the update,
when the next run starts,
then the Lead's run-start check finds a record that the baseline does not list, recomputes, and says so in one line.
It is contradicted if the baseline can only change by hand-editing a figure.

**AC-8 Every figure can be read back from the records, with no store.** *(Under test: Baseline)*
Given the baseline issue as written for AC-2 and AC-3,
when a reader takes only the records it names (by item number) and the standard's rules,
then they reproduce every figure of the issue, and the issue holds no figure whose source is not a record it names; it holds no raw record text, no transcript content and no 5 Whys text.
It is contradicted if a figure needs a database, a script's saved state or an unnamed source.

**AC-9 Baseline data stays in the project.** *(Under test: What reaches agent-plugins)*
Given every file of the new standard,
when it is searched for instructions that create, edit or read the baseline issue, an A3, or any figure of either,
then each targets the project's own tracker (no `--repo WimSuenens/agent-plugins`, no path in the plugin repo); step 9's issue (AC-25) is the only instruction that names that repository.
It is contradicted if any instruction writes a baseline figure or an A3 into the plugin repo.

**AC-10 The baseline in a real session.** **[human-only]** *(Under test: Baseline)*
Given the sandbox project, which holds S2 and S5 and no baseline issue, and the demo session started on the new standard (the person types the run-start words in the demo's script, below),
when the Lead has started the run,
then a pinned `Factory baseline` issue exists; its history section for `1.1` shows S5's figures as the person reads them in S5's record, S2 is named as skipped, and the current series reads `0 items`; and after the first demo item closes, the current section lists that item and its figures match the item's record. The person notes the minutes it took to read the baseline.
It is contradicted if the person cannot set, read and see updated the baseline through this one issue.

### B. The run's one problem and one experiment (Loops; Changing the standard; Bounds of a local countermeasure)

**AC-11 The run's problem is chosen by a counted rule.** *(Under test: Loops)*
Given a fixture run of three items with these andons: A1 (process item: a missing line in a role's Inputs needed) in two items, A2 (process item: the step order of one stage) in one, and a fixture where no andon was raised and the items' records show lead time above the section's median,
when the Lead follows the standard's rule for choosing the problem,
then candidates are the process items named by the run's andons (two andons are one candidate when they name the same file or section of the standard); each is shown with the number of items it appears in; the candidate with the most items is the problem, a tie goes to the one raised first; with no andon the candidates are the measures of the run's items, each as its ratio to the section's median (only those whose section value has `k >= 1`), the largest ratio is the problem and the A3 says `not above baseline` when that ratio is 1 or less; and every candidate not chosen is listed in the A3 with its count.
It is contradicted if the rule can pick two problems, or none.

**AC-12 The experiment is one override that names its measure; the fence is checked first.** *(Under test: Changing the standard; Bounds of a local countermeasure)*
Given a fixture run, a chosen problem, and a proposed countermeasure,
when the Lead writes the experiment,
then it is an override in `docs/agents/factory.md` written as requirement 49 and ADR 0011 say (fence check first; a countermeasure that crosses the fence is refused, nothing is written), and it carries, besides requirement 49's fields, the one measure of the seven it is meant to move, the direction, and the reading **before** it started (the section's value with `k of n` and the item numbers); the experiment is never started with `before: not captured`, and no override is written for an experiment that has no closed item in the current series (the first items measure only: the A3 then reads `experiment: none (no closed item in series <X.Y> to measure against)`).
And a run has at most one experiment: any other override written in the run (an andon's countermeasure) is listed in the A3 and its settle line reads `before/after: not measured (not this run's experiment)`.
It is contradicted if an experiment can start without its measure and its before-reading, or if two overrides of one run are both reported as the experiment.

**AC-13 The experiment is tried through `docs/agents/factory.md` alone.** *(Under test: Changing the standard)*
Given the countermeasure of AC-12 and a fixture run,
when the Lead applies it,
then no path under `plugins/` changes and the Lead's next briefs carry the override's rule as requirement 49's AC-15 says; and a countermeasure whose only form is a change of the plugin text writes no override: the A3 reads `experiment: none (needs a plugin change)` and the proposal goes in the A3's list for step 9 (AC-25).
It is contradicted if applying the experiment needs an edit under `plugins/factory/`.

**AC-14 Before, during and after items are told apart from the records.** *(Under test: Baseline, Loops; validation: S5, S5b, S5c, controls)*
Given records of three items of one series, closed before, across and after the start of override `X`, each carrying what the architect's contract says about the overrides in force,
when the Lead reads the experiment's before and after,
then the first is a before-item, the second a during-item (named in the A3 and counted in neither reading), and the third an after-item; an item of another series (S5c against S5) is in neither reading; a calibration item (S5f) is in neither; and each reading is the AC-3 reading of its items.
It is contradicted if the during-item is counted, or a calibration or other-series item is.

**AC-15 When the two readings cannot be compared, the A3 says so.** *(Under test: Baseline; honesty rule)*
Given a fixture where the release moved from `1.2.x` to `1.3.0` between the before-items and the after-items, or where a second override was in force for the after-items only,
when the Lead writes the reading,
then it reads `not comparable (<why>)` for the change and shows each side as it is; it never shows a difference between two readings that are not comparable.
And given an after-reading with no captured value (`k = 0`),
then the change reads `not captured (<reason>)`, never `0` and never a difference.

### C. The A3 (Loops; Standard work; What reaches agent-plugins)

**AC-16 The A3 has a fixed shape.** *(Under test: Loops, Standard work)*
Given the new standard,
when it is read,
then it gives the A3 as fixed lines in a fixed order with a marker as the body's first line that carries a schema version (a script can find it without reading the rest, like the hansei and andon markers; a reader that meets an unknown version skips it and says so), and the lines are: run (`#<map>`), series and release with the two fingerprints, problem, evidence, the 5 Whys, the problem's process item to change, countermeasure (the override's name and start date, or `none` with the reason), measure targeted and direction, **before**, **after**, change, items counted (before, during, after, by number), what is still uncertain, other problems seen (AC-11), standard changes proposed (AC-25), and the person's answer (`pending`, then keep, promote or drop with the date).
And given the same fixture run read by two separate readers who have only the standard's text (a person, or a fresh agent), each filling the template once,
then both outputs have the same line keys in the same order. (Shape only; the content of the problem may differ.)
It is contradicted if the two shapes differ, or if a line can be left out.

**AC-17 The A3 cannot be written without a before/after reading.** *(Under test: Loops)*
Given a fixture run with an experiment, and another with none (AC-12),
when the Lead writes the A3,
then in both the **before**, **after** and **change** lines are present; each holds, for the before and after, a value with `k of n` items, the item numbers and the release, or `not captured (<reason>)` or `not comparable (<why>)`, and for a run with no experiment `none (<reason>)` with the reason given in AC-12; never `0` for a missing value and never a blank.
And the standard tells the Lead not to post an A3 whose before/after lines are blank, missing or `0` for a value that was not measured.
It is contradicted if an A3 can be posted without those lines.

**AC-18 The A3's 5 Whys uses the Andon rule and ends in a process item.** *(Under test: Loops; respect for people, already in the standard by #49)*
Given the chosen problem,
when the Lead writes the 5 Whys,
then it follows the same rule as an andon's (`skills/run/SKILL.md`, *The 5 Whys*: causes name process objects only, each with evidence, the last line `process item to change: …`, a chain that names a person, a role's care or competence, or a model is refused and redone, and a model or role swap only after the four `examined:` lines), and the standard does not restate the rule a second time: it points to the one in *The 5 Whys*, so one change edits both.
And given three fixture chains (the process-ending one of #49's AC-13(c), and its (a) and (b)),
then (c) is accepted and (a), (b) are refused.
It is contradicted if the A3 can carry a chain that the andon rule would refuse.

**AC-19 What the A3 says is uncertain is never empty and is concrete.** *(Under test: Loops)*
Given a fixture A3,
when the Lead fills `what is still uncertain`,
then it holds at least the sample size of each reading (`k of n`, so that `n = 1` reads `one item`), every other override in force during the after-items, whether the items were of a similar kind of work (named), and every `not captured` the reading hides; and it states that no significance is claimed (a reading of counts with item numbers: what moved, not that it is proven).
It is contradicted if the line can be `none`.

**AC-20 One A3 per run, in the project's tracker, with no raw data.** *(Under test: Loops; What reaches agent-plugins)*
Given a run that closes,
when the Lead posts the A3,
then it is one comment, posted once, in the project's own tracker at the place the architect names, with `seen`-style paraphrase only: no raw hansei record, transcript text, absolute or home path, secret, or instruction-like sentence; it names the baseline issue by link.
And given a run that closed no item,
then no A3 is written and the Lead says `0 items closed: nothing to measure`; and given a run the person stops after at least one item closed, the A3 is written and its first line says `run stopped`.
It is contradicted if a run with items ends without an A3, or if two A3 exist for one run.

**AC-21 The A3 in a real session.** **[human-only]** *(Under test: Loops)*
Given the demo run (script below),
when the person reads the A3,
then it names one problem that the person recognises from the session, its 5 Whys ends in a process item with evidence the person can follow, the before and after figures and item numbers match what the person reads on the baseline issue and in the items' records, and `what is still uncertain` is concrete. The person writes down any line they had to correct and the minutes it took them to read the A3.
It is contradicted if the A3 reports a figure the baseline or the records do not show.

### D. Run close, settle, step 9 (Loops; Standard work; Bounds; What reaches agent-plugins)

**AC-22 The run-close order is written once and is the only close.** *(Under test: Loops; Standard work)*
Given the new standard,
when it is read,
then the run's close is these actions, in this order, written in one place of `skills/run/SKILL.md` (the architect places them; `references/*.md` may hold their templates):
1. update the current section from the records (AC-7);
2. write the experiment's before/after reading and post the A3 (AC-17, AC-20);
3. the settle round of requirement 49, whose line for the experiment now carries the A3's before and after (AC-23);
4. the feedback offer of step 9 (AC-25);
5. report the run closed with the A3's link, the baseline's link and the outcome of each override.
And there is no other batch step that gathers findings at the end of the run, and no instruction that reports the run closed before action 3 has an answer for every override of the run (requirement 49, AC-26).
And when the person stops a run, the Lead asks once whether to close it now; on yes it runs this order with the A3 marked `run stopped`; on no it writes nothing and a later run start finds the unanswered overrides (requirement 49, AC-27).
It is contradicted if a run can be reported closed without the A3 (when an item closed), or without an answer for each override.

**AC-23 The settle line carries the experiment's before and after.** *(Under test: Bounds of a local countermeasure; Baseline)*
Given a fixture `docs/agents/factory.md` with the experiment `X` and one other override `Y` of the run,
when the Lead shows the settle lines,
then `X`'s line is `X — started <date> — before <v> (<k> of <n>; items …) / after <v> (<k> of <n>; items …) — keep, promote or drop?` (or `not comparable (…)` or `not captured (…)` as AC-15 says), and `Y`'s line reads `Y — started <date> — before/after: not measured (not this run's experiment) — keep, promote or drop?`; `before/after: no baseline yet` no longer appears anywhere in the standard.
And the answers are applied as requirement 49's AC-26 and AC-27 say (not rewritten here), then the baseline is updated as AC-6 says, and the A3's last line shows the answer and its date.
It is contradicted if a settle line shows a figure the A3 does not.

**AC-24 `promote` puts a decision card in front of the person; it never changes the plugin.** *(Under test: Changing the standard)*
Given the person answers `promote` to override `X` at the settle round, in a fixture,
when the Lead follows the standard,
then `X`'s status becomes `promote chosen <date>` and it stays in force; the Lead briefs the product-owner for a decision card for the yokoten (a one-way door: the change goes to every project) per `references/decision-card.md`, at the decision-maker level in `docs/agents/factory.md`, posted on the project's tracker ticket it belongs to (the A3's ticket), with a recommendation and its undo cost; nothing is written under `plugins/` and nothing is sent to `WimSuenens/agent-plugins` until the person decides the card; and the run may be reported closed with the card open (the card is not an override's answer).
And the standard does not let any route promote without a card (no automatic promotion, no "promote" by silence or default, F1 and F2).
It is contradicted if promotion changes the plugin, or reaches agent-plugins, without a decided card.

**AC-25 Step 9 shrinks to what the A3 lists and the person approves.** *(Under test: What reaches agent-plugins; Loops)*
Given a fixture run with: an `other` (kind 7) abnormality, an andon whose countermeasure was `none: needs a plugin change`, three briefs that came back `blocked` for an input the protocol should have named, a role that did another role's work, and a person's remark that a step felt clumsy,
when the Lead follows the standard's step 9,
then it drafts a factory issue only for things the A3 lists (`standard changes proposed`, the `other` abnormalities, and the person's remark, each with the reason it is listed) and not for the three blocked briefs or the role's work unless they are the A3's problem or its other problems seen (they stay in the project's hansei records and the A3's list); each draft holds the problem in factory terms, the exact standard change, before/after numbers against the baseline with item count and release, a neutral kind of work, and no code, names, business content or raw hansei records; the person approves, edits or declines each; and only an approved draft is posted, with `--repo WimSuenens/agent-plugins`.
And the Lead asks the person what felt clumsy before drafting, as step 9 does now.
It is contradicted if a draft is posted without the person's yes, if a draft holds project data, or if the Lead drafts from outside the A3's lists.

**AC-26 Standard work stays inside its paths.** *(Under test: Standard work)*
Given branch `item/57`,
when the diff against `main` is read,
then every changed path under `plugins/factory/` is `skills/run/SKILL.md`, a file in `references/`, a file in `scripts/`, or `.claude-plugin/plugin.json`; no new role, no new agent file; and any changed path outside those (for example the setup skill's tracker template, `skills/setup-factory-skill/`, where the baseline's tracker commands may live) is named in the architect's contract with its reason and is listed here by QA as an exception for the person to see. When a script is added, the architect's contract says whether a change under `hooks/` or `scripts/` resets the baseline (a tooling-only patch does not, ADR 0012); when no script is added, that line of the map stays open.
It is contradicted if the new close needs a role or a script outside the listed paths without the exception being named.

### E. Release and calibration

**AC-27 The change is released, and this run starts no baseline of agent-plugins.** *(ADR 0012)*
Given branch `item/57`,
when the diff against `main` is read,
then it changes standard work, `plugin.json`'s `version` is at least one minor above `1.1.0`, and the Lead's bump check (requirement 39, AC-8) passes; the new fingerprints are quoted in QA's verdict.
And **[post-merge]**, given this item runs on the frozen install `9147301f75c3` as calibration,
when the Lead closes it,
then no `Factory baseline` issue has been created in agent-plugins' tracker by this item's work, and its stage-log comment is filed under `Calibration (pre-baseline)`; the new standard's own baseline begins with the first item run on the new release (ADR 0012, point 6).

**AC-28 Release tag.** **[post-merge]**
Given the PR for #57 is merged,
when the tags are listed,
then `factory-v<semver>` for the version in AC-27 exists and points at the merge commit on `main`.

### F. The acceptance demo (human-only)

The demo is a separate session started with `claude --plugin-dir <worktree>/plugins/factory` on the sandbox repo (a project with a map and no baseline issue; it holds S2 and S5). **The person types every seed in the demo window**; a message relayed by another session carries no person's authority and the Lead rightly declines it (lesson of #49). The demo carries the criteria that #49 could not exercise (its AC-9, AC-10 and AC-28, as written there, not rewritten here).

**Demo script.** Three small sandbox items in one run, each of about the size of S5; the sandbox project and its three slices are the Lead's to cut with the person (Open questions). What the person types, in order:

1. `/factory:run` and, when asked, the `Plugin root:` line the Lead names (the run skill is loaded first). Then `/factory:run #<sandbox map>`. Expected: AC-10 (the baseline issue appears).
2. **Item 1** (measures only; no experiment may start, AC-12): answer the Lead's questions; at `merge and clean up?` type `yes`.
3. **Item 2** (the paused agent and the override). While a role agent of item 2 is working (the Lead says which), type: `Stop the line now: the <role> agent has no way to tell which test runner this project uses. Pause it, run the 5 Whys, tell it what to do, and let it carry on.` The Lead raises kind 7 itself on the person's word. Before the stop, the demo needs the agent to have written and committed a one-line note and printed a timestamp with the shell (AC-9 of #49): the person types, earlier, `Ask the <role> agent to write a one-line note to its result file, commit it, and print the time with date -u, before it starts the rest.` At the resume the person types: `Ask it what note it wrote and what time it printed, and have it run date -u again.`
4. **The cancelled agent** (still item 2, a second andon): while another role agent is working, type `Stop the line again for the <role> agent: same cause`. When the Lead has paused it, the person opens `/tasks` and stops that agent from the UI, then types `I stopped the <role> agent from /tasks. Resume it.` Expected (#49 AC-10): the resume is refused and a fresh agent is spawned; the person writes down the Lead's wording.
5. At `merge and clean up?` of item 2 type `yes`. **Item 3** (after-items): no seed; type `yes` at its merge question.
6. Run close: type `Stop the run here and close it.` The Lead asks once whether to close it now (AC-22): type `yes`. It posts the A3 and shows the settle lines. For the override, type `promote` (a decision card appears, AC-24). Then, at step 9, type a remark: `the test runner was not in the brief`, and type `no` to every draft except one you approve by hand.
7. Afterwards the person runs the checks of AC-21, AC-29 to AC-31 and notes the minutes each took.

If the Lead declines a typed seed (for example a person's word is not accepted as a kind 7), the person writes down the exact wording and the criterion reads `not exercised: <reason>`; that is a finding for the standard, not a pass.

**AC-29 The carried criteria, in the demo.** **[human-only]** *(Under test: What the Lead can observe — #35, AC-9, AC-10; Bounds of a local countermeasure, AC-28)*
Given steps 3 to 6 of the script,
when they have run,
then the criteria of requirement 49 read as it writes them: AC-9 (the resumed agent states its note and timestamp and runs the shell again; the person records what was lost at the stop), AC-10 (a cancelled agent is refused and replaced and the item goes on), and AC-28 (the settle line shown, the answer applied and merged before the run is reported closed, the minutes noted); and the settle line of step 6 carries the experiment's figures, not `no baseline yet`.
Each of the three reads `pass`, `fail` or `not exercised: <reason>` in QA's list; none is left unmarked.

**AC-30 The experiment was a local override alone.** **[human-only]** *(Under test: Changing the standard)*
Given the demo,
when it has ended,
then the plugin worktree under `plugins/` shows no change (`git status` on it is clean), and `docs/agents/factory.md` of the sandbox shows the override with its status `promote chosen <date>`.

**AC-31 Nothing reached agent-plugins except an approved issue.** **[human-only]** *(Under test: What reaches agent-plugins)*
Given the demo,
when it has ended,
then the list of agent-plugins issues and comments created during the demo holds only the drafts the person approved (at most one, if the person approved one), none with project data, no A3 and no baseline figure; the A3, the baseline issue and the decision card are in the sandbox's tracker.

## Under test → criteria

| #57 Under test line | Criteria that would show the contradiction |
|---|---|
| Baseline: set, record, update through the pinned issue; numbers read back without a store; `not captured` never 0 or silently averaged; release change or adopted countermeasure starts a new baseline with the old kept as history | AC-1, 2, 3, 7, 8, 10 (set, record, update, read back); AC-3, 15 (honesty); AC-5, 6 (new baseline, history) |
| Loops: exactly one A3 and one experiment without a batch step 9; no A3 without a before/after | AC-11, 12, 16, 17, 18, 19, 20, 21, 22 |
| Standard work: no role or script outside `run/SKILL.md`, `references/*.md`, `scripts/`; two Leads produce the same A3 shape | AC-16 (shape), AC-22, AC-26 |
| Changing the standard: experiment as a local override alone; promotion only by decision card | AC-12, 13, 24, 30 |
| Bounds of a local countermeasure (AC-28 of #49): no run closes with an override lacking its answer; the before/after shows in the settle round | AC-6, 22, 23, 29 |
| Measures: the seven measures into a baseline per release series; no calibration item leaks | AC-2, 3, 4, 14 |
| What the Lead can observe (AC-9, AC-10 of #49) | AC-29 (demo; script steps 3 and 4) |
| What reaches agent-plugins: only a person-approved issue with no project data | AC-9, 20, 24, 25, 31 |

## Out of scope

From the frame's **Deliberately faked**:
- The hoshin view, its themes and the parked-concept triggers: the baseline here is a pinned issue, not a view.
- The gemba sample, and "blame the process first" as a new rule: it is already in the standard (requirement 49, group C); the A3 only reuses it (AC-18), and the map's fifth *Done when* line is not touched.
- A metrics store, and any script that aggregates hansei records: the Lead reads the comments. (The Lead records how many records it read and how long the update took, AC-7, so that the resurvey can judge whether the deferral's trigger fired.)
- Significance testing: before and after are counts with item numbers.
- Comparing projects, and normalising by item size or type.
- How long an experiment is measured (items "after", one run): settled by the architect inside the slice, for one run only; this slice fires that deferral's trigger (the first experiment starts), and its answer is written back on the map at the resurvey.
- A real baseline of agent-plugins: this run stays frozen on `9147301f75c3`, so #57 is calibration (AC-27); the demo's baseline is the sandbox's.
- Whether a `hooks/` or `scripts/` change resets the baseline: decided only if a script is added (AC-26).

Also out of scope:
- Loosening or narrowing the fence (ADR 0011).
- Changing what a "run" is beyond AC-22's stopped-run close.
- Automatic changes to the shared plugin standard (map: Out of scope); implementing a promoted countermeasure in the plugin (a later item after the card is decided).
- Escaped-defect tracing: the measure still reads `not captured`.

## Decisions

Two-way doors decided here (chosen / rejected / cost to undo). No one-way door was found: every choice below is a text change to standard work or a reading rule, reversible by a minor release and a baseline recompute.

1. **A baseline field is read as the median of the captured items, with `k of n`.** Rejected: the mean (one overnight item like C39's 22h18m would dominate a small section), and a sum (the parts would add up to a value that no item had). Undo: one rule in `references/hansei.md` plus a recompute from the records; no data is lost because the baseline is derived.
2. **Sections are keyed by release `X.Y` and by the overrides in force for the whole item**, and before/during/after come from the records, not from dates. Rejected: date ranges (an override's `started` is a date, and three demo items close the same day); one section per run (ignores a release change in the run). Undo: change the key and recompute.
3. **No experiment starts without a closed item in the current series; at most one experiment per run; other overrides are listed and read `not measured`.** Rejected: letting an experiment start with `before: not captured` (the A3 would carry no reading, which the Under test line forbids) and measuring every override (several confounded experiments in one run). Undo: one rule; the A3 text is unchanged.
4. **Order at the run close: update, A3, settle round, feedback offer, report.** Rejected: step 9 before the settle (a draft that proposes a plugin change would be written before the person says promote or drop, and a promote needs its card first), and the A3 after the settle (ADR 0011 puts the settle line next to the A3). Undo: reorder text.
5. **A person-stopped run runs the close after one yes.** Rejected: a stopped run writes nothing (today's text; the run would lose its A3 and the demo could not reach the settle round without dissolving the map). Undo: one rule.
6. **`promote` posts a decision card at the settle round and the run may close with the card open.** Rejected: blocking the close until the card is decided (it could wait days), and recording the answer only (requirement 49's stopgap; the map's third line says promotion is a card). Undo: one rule.
7. **The problem is chosen by counts (items an andon's process item appears in; otherwise the largest measure ratio to the baseline).** Rejected: the Lead's free choice (two Leads could not be compared) and asking the person to choose (it adds a touch; the person sees the choice in the A3). Undo: one rule.
8. **No A3 for a run that closed no item.** Rejected: an A3 on nothing, which would need a problem the run did not show. Undo: one rule.
9. **Manual comments without a marker (C39, C49) are not records.** Rejected: a name search for "calibration" (it would let a comment's wording decide what is summed). The person may link them by hand under `Calibration (pre-baseline)`. Undo: add a list of links.
10. **The record count and update minutes go in the stage log**, so the deferral "aggregating becomes too slow" has an observable. Proposed reading for the resurvey, not fixed here: the trigger fires when an update takes more than 10 minutes of Lead time or reads more than 50 records. Undo: drop the note.

## Open questions

- **Architect**: the baseline issue's form (body, comments or both; the layout of a section and of the history); the A3's marker, template and where it is posted; where the baseline's tracker commands live (the project's tracker doc via the setup skill's template, with the run skill's fallback for older projects) and the exception that AC-26 asks to be named; the way pinning is done and what happens when it fails (AC-1); where the run-close actions sit in `skills/run/SKILL.md` and how step 9 and step 10 are renumbered or merged; the exact text of the rules for AC-3, AC-5, AC-11, AC-14 and AC-15, fixed before the build and replayed by QA on the validation data.
- **Architect**: what a record carries so the baseline can tell, per item, which overrides were in force for the whole item, for part of it, or not at all (a schema bump of the hansei record, `hansei v4`, or a field read from the lead state at close); the override format's link to the A3 when an experiment does not start from an andon (requirement 49's override carries an andon link); how long an experiment's after-items are counted (items "after"; one run only, or across a kept override), and which A3 reports a kept override's later items; add *A3*, *Baseline issue* and *Experiment* to `CONTEXT.md`.
- **Architect**: whether a change under `hooks/` or `scripts/` resets the baseline: only if a script is added (ADR 0012 already settles that a tooling-only patch does not).
- **Lead (with the person)**: the sandbox project's three small slices for the demo and who types each seed (AC-29 to AC-31); whether the Lead accepts the person's typed "stop the line now" as its own kind 7 (the standard says "any role and the lead"; if it does not, steps 3 and 4 of the script need another way to have an agent running when the pause comes, and AC-29 stays `not exercised`); who tags the release (AC-28).
- **Lead**: that no record that carries a marker exists on #39 or #49 in this tracker (the validation data note above): the brief's phrase "the hansei records already on #39 and #49" reads, here, as the manual comments C39 and C49 plus the sandbox's S5 and S2.
