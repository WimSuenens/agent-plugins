# Contract 57 — What a record and an override carry so the baseline and the A3 can tell items apart

Slice [#57](https://github.com/WimSuenens/agent-plugins/issues/57) · Requirement [57-per-run-a3-and-baseline](../docs/requirements/57-per-run-a3-and-baseline.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on [39-hansei-record](39-hansei-record.md), [49-records](49-records.md), [49-overrides](49-overrides.md) · Companions: [57-baseline](57-baseline.md), [57-a3](57-a3.md), [57-run-close](57-run-close.md), [57-standard-changes](57-standard-changes.md)

Serves AC-12, AC-14, AC-15 (the override and record fields they read) and the requirement's open questions on what a record carries, the override's link to the A3, and how long after-items are counted. Everything here is a two-way door (a schema version, a status line, a Factory run line): the record's reader skips an unknown version, so a later change is one more bump.

## 1. Hansei record v4

**Why a bump.** A v3 record lists each override in force at approval as `name (since YYYY-MM-DD)`. An override written in the middle of the item looks the same as one that was in force from the first brief, so the baseline cannot tell an item that ran **wholly** under override X from one that ran partly under it (the *during-item*, AC-14). `hansei.md` says any change to a field's grammar bumps the version, so the marker becomes `<!-- factory:hansei v4 -->`.

**What changes (nothing else does).**

1. The marker line.
2. The label (`## Label` of the lead state, §2) gets one line, `overrides at start`, written once at item start.
3. The record's `active overrides` line has a new grammar (§3).

Every other header line, the seven measures and the value grammar are v3's, unchanged. v3 and v4 measures may be compared (v3 added `andon` to measure 1; v4 changes no measure).

**Which versions the new standard reads.** v3 and v4. A record with any other version (v1, v2, a version above 4) is **skipped and named** by the baseline (`skipped: schema v1`, [57-baseline](57-baseline.md) §3). `hansei.md` keeps one short note on v3 (its `active overrides` grammar, §4 here), because a v3 record is read by its own marker. The v2 text is not kept, as today.

## 2. The label's new line

```
## Label

- plugin root: …
- release: …
- standard: …
- tooling: …
- overrides at start: <none | name; name …>
- wayfinding: …
```

`overrides at start`: the names of the overrides **in force** (status `active` with `run` the current run, `kept … for #<map>` or `for next run`, bound at this step, or `promote chosen`; none is a fence crossing) when the Lead opens the `Start item` row, in file order, separated by `; `. It is read from `docs/agents/factory.md` in the item worktree after step 5.2 (binding of kept overrides) and the run-start sort of `## Andon`, *Run start*. It sits between `tooling` and `wayfinding`, and like the rest of the label it is never changed afterwards.

## 3. The `active overrides` line in v4

```
- active overrides: <none | <entry>; <entry> …>
<entry> ::= <name> (since YYYY-MM-DD; whole item)
          | <name> (since YYYY-MM-DD; from <YYYY-MM-DDTHH:MMZ>)
          | <name> (since YYYY-MM-DD; until <YYYY-MM-DDTHH:MMZ>)
```

The list is the union of the label's `overrides at start` and the overrides in force at approval, in file order (an override that is only in the first set is last). For each name:

| Extent | When | `<time>` |
|---|---|---|
| `whole item` | in force at the `Start item` stamp **and** at approval | none |
| `from <time>` | not in force at start, in force at approval (written during the item) | the committer time of its `#<id> lead: override <name>` commit, UTC, cut to the minute (`git log -1 --format=%cI` on that commit, converted) |
| `until <time>` | in force at start, not at approval (superseded during the item) | the committer time of the commit that wrote its `superseded` status, as above |

`none` when both sets are empty. `since` is the override's `started` date. An override that is `promote chosen` counts as in force. The line stays on one line.

An item is a **during-item for X** when X's extent is `from` or `until`. An item is **whole-item under X** when it is `whole item`. The set of names with `whole item` is the item's **key** (`none` is the empty key). An item with at least one `from` or `until` entry has a key too, but it is counted in **no section** ([57-baseline](57-baseline.md) §5).

**Worked example.** A fictional item #12 in a scratch project: `replay-before-build` was in force from the first brief (it was written in an earlier item of the run); `fixtures-first` was written during the Build stage (commit `2026-11-08T15:02Z`); `old-rule` was superseded at `2026-11-08T15:30Z`.

```
- active overrides: replay-before-build (since 2026-11-07; whole item); fixtures-first (since 2026-11-08; from 2026-11-08T15:02Z); old-rule (since 2026-11-05; until 2026-11-08T15:30Z)
```

Its key is `replay-before-build`; it is a during-item for `fixtures-first` and for `old-rule`, so no section counts it.

## 4. Reading a v3 record

A v3 record's line is `active overrides: none` or a list of `name (since YYYY-MM-DD)`. The new standard reads it so:

- `none`: the item's key is the empty key, no extent is partial. The record is placed like a v4 record with `none`. (An override cannot have been in force earlier in the item and be absent at approval, unless it was superseded, which v3 does not list; the item is read as `none` knowingly, and the series block's optional `- records: schema v3 and v4 read together` line ([57-baseline](57-baseline.md) §7) says so when the series holds both schemas.) S5 is this case.
- a list: the extent of each name is **not recorded**. The item is **excluded** and named: `excluded: #<id> (override extent not recorded, schema v3)` ([57-baseline](57-baseline.md) §3). It is in no section and in no reading.

## 5. The override format: the experiment's lines

[49-overrides](49-overrides.md) §2 fixes the entry. Two things are added; neither changes what an override that is not an experiment looks like.

**(a) The `andon` line may read `none (experiment)`** when no andon started the override (the run's experiment written between items, [57-a3](57-a3.md) §4). The rule that a `pending` link left after the item carried on is a defect (kind 7) applies to a `pending` only, never to `none (experiment)`.

**(b) The experiment carries eight more lines**, after `fence check`, written **at the moment the override is written** and never edited except `a3`:

```
- experiment: yes
- problem: <the problem's process item to change, in one line>
- measure: <one measure of §6>
- direction: <down | up>
- series: <X.Y>
- reference: <none | name; name …>
- before: <value> (<k> of <n>; items #<a>, #<b>; factory <semver>)
- a3: <pending | the A3 comment's URL>
```

(`experiment: yes` is the first of the eight.) An override without `experiment: yes` is not the run's experiment.

- `series` is the series of the session ([57-baseline](57-baseline.md) §3), `reference` the key of the reference section of that series when the override was written (the overrides adopted by earlier runs, [57-baseline](57-baseline.md) §6; `none` when empty), `before` the reading of [57-a3](57-a3.md) §6 over the before-items. The override is never written with `before: not captured (…)`.
- `a3` is `pending` until the A3 is posted. The settle commit ([57-run-close](57-run-close.md) §4) replaces it with the comment's URL in the same commit as the answer, while the entry exists; a dropped entry is removed with it. This is the override's link to the A3 when no andon started it.
- Entries stay in the order written; the Lead's run-start sort and the fence check are unchanged. A countermeasure that crosses the fence is refused before any of these lines is written.

**Worked example.** The experiment written between item #6 and item #7 of run `#3`, series `1.2`, the reference empty:

```
### qa-brief-names-runner

- started: 2026-11-09
- run: #3
- rule: The Lead names the project's test runner and the command that runs it in the Constraints of every brief to the developer and the qa-engineer.
- andon: none (experiment)
- status: active
- fence check: pass 2026-11-09 (touches none of the seven)
- experiment: yes
- problem: the developer's brief has no line for the test runner
- measure: 3 developer
- direction: down
- series: 1.2
- reference: none
- before: 1 (2 of 2; items #5, #6; factory 1.2.0)
- a3: pending
```

## 6. The measures an experiment may name

The requirement says "one measure of the seven". Measures 4 (escaped defects, always `not captured`) and 7 (doors, outcomes per Under test line) cannot move as a number; measure 2 (first-pass yield) is an outcome per stage, not a quantity, so no signed difference exists for it. The allowed form of `measure:` is `<number> <field>`:

| Measure | `<field>` | Unit | Read as |
|---|---|---|---|
| 1 lead time | `total`, `agent working`, `waiting for the person`, `waiting on limits`, `stalled`, `interrupted`, `andon` | minutes | median ([57-baseline](57-baseline.md) §4) |
| 3 rework | a role (`product-owner` … `docs-writer`) or `overturned` | count | median |
| 5 tokens | `<role> spend` or `<role> peak context` (`lead` included) | tokens | median |
| 6 person's touches | `decision cards`, `demos`, `approvals`, `overturns`, `other` | count | median |

Measure 2 may be added later (Decisions §D1 of [57-standard-changes](57-standard-changes.md)). An experiment that names a measure outside this table is not written.

## 7. The Factory run section: two lines the Lead keeps

The map's **Factory run** section survives `work/<id>/`'s removal, so what the run close needs lives there. The Lead keeps two lines (the rest of the section is as today):

```
- closed in this run: #<id> <record URL>; #<id> <record URL> …
- baseline: #<id> <n> records, <m>m; …
```

- `closed in this run`: appended at step 8.4, next to the `hansei:` pointer, with the item's record URL. It is the **run list**: the items of the run, in close order. After-items and the run's items for the problem rule are read from it ([57-a3](57-a3.md) §4, §6). It is never edited except by appending. Absent or empty means the run closed no item.
- `baseline`: appended at step 8.10 for each update: the item number, the number of records the update read, and the minutes it took (`date -u` before and after, whole minutes, rounded half up). This is the requirement's "records read and minutes" note (AC-7, decision 10): the stage log is already removed at step 8.6, so the map's section is where it can still be written. The resurvey reads it to judge the metrics-store deferral (the proposed trigger, 10 minutes or 50 records, is the resurvey's, not fixed here).

## 8. After-items: how long they are counted

**One run only.** The after-items of an experiment are the items **in the run list** ([57-a3](57-a3.md) §6). The A3 is written once, at the run close, and never recomputed ([57-a3](57-a3.md) §1). When the person answers `keep`, the override is in force in the next run and its later items are in the baseline's reference section ([57-baseline](57-baseline.md) §6): that is where they are read. **No second A3 reports a kept override**; a kept override is not the next run's experiment (the next run may write a new one with `reference:` naming the kept one). Trigger to revisit (Decisions §D6): the person asks for a second reading of a kept override.

## 9. Acceptance criteria → this contract

| AC | Where |
|---|---|
| AC-12 | §5, §6 |
| AC-14 | §1 to §4 (extents), §7 (the run list) |
| AC-15 | §5 (`reference`), §3 (key) |
| AC-16 (marker versioning pattern) | §1 |
| AC-7 (the records-read note) | §7 |
| open question: what a record carries; link to the A3; how long after-items are counted | §1 to §3; §5(a), §5(b); §8 |
