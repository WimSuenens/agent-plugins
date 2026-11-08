# Contract 64 — The ledger, the hansei fields, and the readers of the sections that leave the lead state

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADRs [0014](../docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md), [0015](../docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md) · Changes [39-stage-log](39-stage-log.md) §1 to §5, [49-records](49-records.md) §1 to §4 and [60-gemba-sample](60-gemba-sample.md) §1 (where the rows come from), none of their measures · Calls: [64-gh-calls](64-gh-calls.md)

Serves AC-20 to AC-26. Where the card statuses and the views are decided: [64-board-status](64-board-status.md). Where a role task is created and closed: [64-role-tasks](64-role-tasks.md).

## Paths

Paths:
- plugins/factory/references/hansei.md
- plugins/factory/references/baseline.md
- plugins/factory/references/a3.md
- plugins/factory/skills/run/SKILL.md
- plugins/factory/references/protocol.md
- tests/factory/
shared: none

## 1. The answers, first

The requirement asks three things of this part. Short answers; the sections below give the rules.

1. **No reader of the stage log, the waits or the touches loses a measure.** Every reader was walked (§4). Each finds its input in one of three places: the sub-issues of the slice (their `created_at` and `closed_at`), the **ledger** (one comment on the slice ticket), or the lead state. Nothing is dropped, so there is no question to the lead on this point.
2. **Field type.** The six fields are **text** fields. A Number field cannot hold `not captured (<reason>)`, and a Number cell left blank beside a note would let a blank stand for it, which fence F7 forbids. Text is the one type that meets F7 (§5).
3. **Where waits and touches live.** In the ledger, as the same two tables the lead state held. A person's wait starts at the `Asked:` stamp of the card's needs-you comment ([64-board-status](64-board-status.md) §4).

## 2. The ledger

**The ledger** is one comment by the lead on the slice ticket. It carries the three things the lead state's stage log, waits and touches carried, and nothing the board or the sub-issues already hold. A frontier round has **no ledger** (it has no stage log, no wait table and no record today either).

- **Marker.** The first line is exactly `<!-- factory:ledger v1 -->`. A reader finds it with `^<!-- factory:ledger v([0-9]+) -->\r?$` on the first line, among the lead's own comments (`T-comments`). One per item. A second is never posted: the lead finds the first and edits it.
- **Posted** once, at item start (step 5), by `T-comment`. **Edited** by `T-edit-comment` (read the body with `T-comments`, change the tables, write it back) when a task row is added, a wait ends, or the person touches. Each edit changes only what the event adds; the previous tables are copied unchanged. The comment's edit history is GitHub's, as for the hansei record.
- **Size.** A ledger holds one row per role task, wait and touch of one item (tens of rows), far below the 65,536 characters of a comment. A ledger that would exceed 60,000 bytes is not split: the lead stops and tells the person (`Waiting on you`), because that item is not a normal one.
- **Mutable, and said so.** The owner can edit or delete it. The hansei record copies its numbers at close; a deleted ledger leaves the record's values `not captured (ledger comment missing)` (§5), never invented.

Shape (the Tasks table has the stage log's columns minus the three that the sub-issue knows):

```
<!-- factory:ledger v1 -->
## Ledger: #12 Export a report as CSV

- started: 2026-11-04T11:40Z
- start checks: author test: ok; freeze: none; drift: same as #9; baseline: #8 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #31 | Requirement | product-owner | a1c9e2 | - | 48210 | done | 6 criteria, 2 decisions, 1 card |
| 2 | #32 | Contracts and ADRs | architect | b7d031 | W1 | 61450 | done | 3 ADRs |

### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:10Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
```

### Header lines

- `started`: the `date -u +%FT%TZ` stamp the lead takes when step 5 begins, cut to the minute. It replaces the `Start item` row's `Start`. Lead time starts here.
- `start checks`: one line, parts separated by `; `: the kind 3 author test result (`author test: ok` or `author test: one git identity for all roles`), the freeze check (`freeze: ok`, `freeze: none`, or `freeze: not captured (map body last edited by <login>)`), the kind 6(a) drift result (`drift: same as #<n>`, `drift: no earlier record for <semver>`, `drift: pre-release install`), the baseline check outcome. It replaces the `Start item` row's `Notes`. Nothing reads it but the person.

### The Tasks table

One row per role task, added by the lead **when it reads the task's result** (after the closing comment and the close, [64-role-tasks](64-role-tasks.md) §5), in the order the tasks were created. A role task still open has no row.

| Column | Content |
|---|---|
| `#` | the row's number, 1, 2, 3 … in table order. It replaces the stage log's `#`; the stage log counted lead and person rows too, the Tasks table does not (§7 says how a replay copes) |
| `Task` | the role-task sub-issue's number, `#<n>`. Its `created_at` is the row's **Start**, its `closed_at` the row's **End**, read with `T-subissues`. Never copied into the table (one source) |
| `Stage` | `Requirement`, `Contracts and ADRs`, `Environment`, `Build`, `QA`, `Security`, `Delivery`, `Documentation`; a rework task appends ` (round <n>)` as before (`Build (round 2)`). There is no `Start item`, `Acceptance demo`, `Open PR`, `Merge approval` or `Andon A<n>` row: those were lead or person rows that no reader reads (§4) |
| `Role` | one of the seven roles |
| `Agents` | every agent handle that worked this task, comma-separated; a resume keeps the id, a fresh spawn adds one |
| `Waits` | ids of the `### Waits` entries that held this task, or `-` |
| `Peak ctx` | as the stage log's: the largest `<subagent_tokens>` or `totalTokens` among this task's completion notices, `not captured (<reason>)` when none carried it |
| `Result` | the result's Status, the verdict or the outcome: `done`, `pass`, `findings`, `blocked`, `needs-decision`, `refused`, … |
| `Notes` | free text as before: counts of decisions and cards, `slow: <own> against median <m> of <n> earlier rows`, `no baseline: fewer than 3 earlier rows`, `paused by A<n>`, `done, then <kind>`, and `split <k>` when the result needed `<k>` comments ([64-role-tasks](64-role-tasks.md) §6) |

**Duration** and **agent working** of a row are computed, never stored: Duration = `closed_at` − `created_at` in whole minutes (rounded to the nearest minute, as `<dur>`); agent working = Duration less the union of the intervals of the waits named in `Waits` that are `Held item: yes` and of kind `person`, `limits`, `stalled`, `interrupted` or `andon`, each cut to the row's interval (overlaps once). This is the 1.3.0 rule of `skills/run/SKILL.md` *Detection*, kind 4, word for word, on the new Start and End.

### The Waits and Touches tables

Identical to the lead state's tables in columns, kinds, ids and meaning (`references/hansei.md` section 1, *`## Waits` and `## Person's touches`*, and its detection rules, *Cut-offs at close*, *Done, then stopped*): five wait kinds, `Held item`, `W<n>` ids counting up in the item, five touch kinds. Three things change, and only these:

1. **When a row is written.** A wait is written when it **ends** (its End is known), never open: the lead holds the open wait in its head and in the lead state's `## Running agents` row for the stopped agent (`interrupted: <kind> since <UTC>`), and a person's wait in the card's needs-you comment (`Asked:` line, [64-board-status](64-board-status.md) §4). A touch is written when the person's answer is read. This replaces "write each wait and each touch as it happens"; the recorded clocks are the same.
2. **A cut-off lead.** A lead that is cut off before it writes an ended wait loses that row only for the `person` kind it can re-derive from the card's comments, and for the cut-off kinds the close scan (`cut-offs.sh` over every transcript) finds again, as it does today for waits no notice reported. Nothing else is lost.
3. **The approval.** The touch `approval` at *merge and clean up?* is the approval time; lead time ends there, as the `Merge approval` row's End did.

## 3. The lead state after 2.0.0 (AC-24)

`work/<id>/00-lead-state.md` keeps the lead's memory and nothing the board shows:

```
# Lead state: item <id> (map #<map>)

- Board item id: <item>
- Next step: <step>
- Open questions: <none | list>
- Frozen on: <factory sha or semver> (see map #<map> Factory run section)
- Assigned ADR number: <NNNN | none>

## Running agents
<role task #<n>: <role> <agent id> | none>

## Shared resources
<list | none>

## Interrupted
<role task #<n>, agent id, since <UTC>, kind <kind>, last commit <sha7>, Progress pointer: work/<id>/NN-result-<role>.md | none>

## Label
… (unchanged)

## Findings
… (unchanged)

## Abnormalities
… (unchanged)
```

- **There is no `Status:` line.** The board holds the slice's status (AC-4). Searching `plugins/` for `Status:` as a lead-state line finds nothing.
- `## Label`, `## Findings` and `## Abnormalities` **stay** (requirement Decision 8). Each is the lead's working memory: the label is written once at start; the findings table is the kind 2 matching ledger and has no reader outside the lead; the abnormalities table is re-built into the andon comments. Moving them would put the lead's own scratch on a public ticket for no reader's gain. Cost to undo: a day.
- `## Findings` `Round` reads "as in the Tasks table's `Stage` cell".

## 4. Every reader, and where it reads now (AC-25, AC-26)

The 1.3.0 readers were found by searching `plugins/factory/` and `README.md` for `stage log`, `stage-log`, `## Waits`, `Person's touches`, `Held item`; the developer repeats the search (AC-25 is that search finding nothing outside §8).

| Reader | 1.3.0 source | New source | What changes in its text |
|---|---|---|---|
| Measure 1, lead time (`hansei.md` section 3) | `Start item` row, `## Waits`, `Merge approval` row | `started` (ledger), `### Waits` (ledger), `approval` touch (ledger) | the *Source* cell; the arithmetic is word for word |
| Measure 3, rework | `NN-feedback-*.md` count per role; `Source: lead` overturns | count of `rework` sub-issues per **role that received them** (the `Role` field of the rework task, or the marker's role); overturned = rework tasks whose body has `Source: lead` | the *Source* cell |
| Measure 5, tokens | `Agents` and `Peak ctx` columns of the stage log; truncation by `## Waits` | the Tasks table's `Agents` and `Peak ctx`; truncation by the ledger's waits | the *Source* cell; the truncation signals are word for word |
| Measure 6, touches | `## Person's touches` | `### Person's touches` (ledger) | the *Source* cell |
| Measures 2, 4, 7 | result files, deferred, resurvey | unchanged (the drafts stay in `work/` until step 8.6, the resurvey is unchanged) | none |
| Kind 4 slow-stage (`SKILL.md` *Detection*; protocol table row 4) | rows of the stage log: Duration, `Waits` column, `Role`, `#` | rows of the Tasks table: Duration from the sub-issue, `Waits`, `Role`, `#` | one sentence; the protocol's table row reads "a **role task** whose agent-working time is more than twice the median of the same role's earlier **tasks**" (the observation is the same, the object is renamed; fence F4: kind and right to raise unchanged) |
| Cut-off scan at close (`hansei.md`, *Cut-offs at close*) | `Agents` column of the stage log | the Tasks table's `Agents`; waits to the ledger | two nouns |
| Stage-log cross-check (`hansei.md` section 2) | each row's interval and git/tracker evidence | each Tasks row's interval from the sub-issue; evidence: git commits, the stage summary comment, **and** the task's closing comment's `created_at` | the header key stays `stage-log cross-check` (§8); the text says it checks the Tasks table |
| Gemba sample rule (`hansei.md` section 6, requirement 60) | `Role`, `Agents`, `Result`, `Notes`, listing order of the stage log | the same four columns of the Tasks table, in table order | one sentence: "the Tasks table of the ledger, or a manual table of the same shape". The rule's text is otherwise unchanged. Its steps 1 to 5 still hold; steps that mention a `lead` or `person` row stay, since a manual 1.x log may have them |
| Gemba evidence: the brief and the commit window | `NN-brief-<role>.md` / `NN-feedback-<role>.md` by commit time; `Start` of the row | the row's `Task` sub-issue: `gh issue view <task> --json body,createdAt,closedAt` (one extra read, inside the 30,000 character cap, ending in `head -c`; its check line `brief exit N, stderr M chars` is counted like the others, see the next row); the commit window opens at `created_at` | the *Which brief* paragraph; the rest of the walk is unchanged. A task issue that cannot be read: `not captured (brief not found)` |
| Gemba budget (`hansei.md` section 6, line 492 and the `n` definition at line 532) | `<budget>` = 29,900 minus what was read; 100 characters kept back for the count lines and newlines; `n` at most 29,900 | **`<budget>` = 29,800 minus what was read; 200 characters kept back** (chosen; rejected: leaving the new `brief exit N, stderr M chars` and `view exit N, stderr M chars` lines out of the count, which would let a walk print more than the 30,000 it promises). `n` is at most 29,800. The worst case, a 200,000-character view with a 12,000-character brief, prints at most 30,000 in all, counted by `wc -c` over everything the walk prints. QA row: the replay of T8 (a generated 200,000-character view, with and without a brief) counts the whole output and finds at most 30,000; the pins of `29900` in `tests/factory/test_gemba.sh` become `29800` (QA's file, next QA round). | the three numbers in line 492, the `n` definition (line 532) and the contrast example (line 595: `read transcript 29800 chars`). This **amends** [60-gemba-line](60-gemba-line.md) (`n` at most 29900) and [60-gemba-walk](60-gemba-walk.md) (`head -c 29900`) to 29800; the 60 contracts stay as history and this row governs. The gemba line grammar does not change (`n` is a plain integer) |
| Baseline update note (`baseline.md` line 216, step 8.1 item 4) | "The stage log is gone by then (step 8.6), so the map's section is where this note lives." | "The ledger comment stays on the ticket after `work/<id>/` goes (step 8.6), but the note is about the run, not the item, so the map's Factory run section is where it lives." The stage log no longer exists in 2.0.0, so the old sentence is false. | one sentence; a **build item** (the search for `stage log` in §4's first paragraph finds this line outside §8, which AC-25 forbids) |
| `Held item` and the split rule | `## Waits` | `### Waits` (ledger) | the noun |
| Interruptions (`SKILL.md` *Interruptions*) | "open a wait in `## Waits`" | note the stop in the lead state's `## Interrupted`; the wait is written to the ledger when it ends (resume, respawn, accepted result) | steps 1 and 2 |
| Andon procedure steps 1 and 7 | `## Waits` andon wait, `Andon A<n>` stage row | the andon wait is written to the ledger when the pause ends; no `Andon A<n>` row; the paused task's `Notes` read `paused by A<n>` and its `Waits` list the andon wait | the two steps |
| Run close and A3 (`a3.md`, `baseline.md`) | the hansei record's lines, not the log | unchanged (they read records) | none, except where the search above finds a hit |
| Hansei record `stage-log cross-check` / `gemba` header lines | built from the log | built from the Tasks table; the line's `row <#> <stage>` uses the Tasks table's `#` and `Stage` | none to the grammar |

**Result.** No measure is lost, no kind is dropped, no right to raise is narrowed. The one definition that moves is a row's End: the sub-issue's `closed_at` (after the closing comment is posted and the issue closed) instead of the moment the lead read the result. In a live run that is seconds to a minute later. `references/hansei.md` says so in one place (§8 item 2) and the replay (§7) does not meet it, because its fixtures set both times equal.

## 5. The fields (AC-20, AC-22)

Five fields, made by `scripts/board.sh` ([64-board-script](64-board-script.md) §5) and recorded in the Tracker table of `docs/agents/factory.md` ([64-board-status](64-board-status.md) §2):

| Field | Type | On | Value |
|---|---|---|---|
| `Tokens` | **TEXT** | role task, slice | `<int>` or `not captured (<reason>)` |
| `Minutes` | **TEXT** | role task | `<int>` or `not captured (<reason>)` |
| `Hours` | **TEXT** | slice | `<int>.<dd>` (two decimals) or `not captured (<reason>)` |
| `Rework rounds` | **TEXT** | slice | `<int>` or `not captured (<reason>)` |
| `Person touches` | **TEXT** | slice | `<int>` or `not captured (<reason>)` |

`Tokens` serves both kinds of card, so the five names are the requirement's "six fields" with `Tokens` counted twice.

**Grammar** (a test checks every `B-text` value against it):

```
int          := "0" | [1-9][0-9]*
dd-number    := int "." [0-9][0-9]
not-captured := "not captured (" reason ")"      reason: 1 to 80 characters, no "(" or ")" or newline, no home path
```

- **Never empty.** After the close, none of the five fields is empty on any card the item produced: a slice card, and every role task card of the item. A card for which the lead cannot compute a value gets `not captured (<reason>)`. `0` is written only for a value measured as zero (`Rework rounds` `0` when no rework task exists; `Person touches` `0` is possible only for an item with no touch, which has no approval and so cannot close).
- **`n/a (did not run)` is never written in a field.** A card exists only for something that ran.
- **Why text.** Alternatives: (a) Number plus a paired text field for the reason: rejected, the Number cell is blank when the value is `not captured`, and a blank is what F7 forbids. (b) Number, with the reason only in the hansei comment: rejected, the same blank. (c) Number, `-1` as a sentinel: rejected, it reads as a measure. The cost of text: the History view sorts by text and sums nothing; the person reads, and the hansei record and the baseline keep the numbers. If a later release wants sums, it adds Number twins filled only for captured values (the twin's blank is then not a claim, because the text field beside it holds the value). Undo cost of the choice: a field cannot change type in place, so a new field and a copy script, half a day.

### How each value is computed (all from the ledger, the sub-issues and the scripts)

| Field | Rule | Same as |
|---|---|---|
| role task `Minutes` | the Tasks row's agent working, in whole minutes (§2) | kind 4's agent-working time |
| role task `Tokens` | `token-spend.sh --since <created_at> --until <closed_at> <the task's agents' transcripts>`, the `spend` total only. Exit 3, 4, 5, 6 give `not captured (<the measure 5 reason>)` exactly as `hansei.md` measure 5 | measure 5 per task |
| slice `Tokens` | the sum of the role tasks' `Tokens`, the lead excluded (the lead's spend stays in the record). When any task reads `not captured`, the sum is not shown as a total: `not captured (<k> of <n> role tasks not captured)` | measure 5 summed over roles |
| slice `Hours` | measure 1's `total` (`approval − started`, whole minutes) ÷ 60, rounded half up to two decimals: `187m` gives `3.12` | measure 1 `total` |
| slice `Rework rounds` | the number of `rework` sub-issues of the slice ([64-role-tasks](64-role-tasks.md) §7) | measure 3, summed over roles (feedback briefs) |
| slice `Person touches` | the number of rows in `### Person's touches` (all five kinds, the approval included) | measure 6, summed |
| a frontier-round role task | `Tokens` and `Minutes` both `not captured (frontier round keeps no ledger)` | a deliberate simplification, listed as Unverified in the changelog |

A ledger that cannot be read gives `not captured (ledger comment missing)` for `Hours`, `Person touches` and the waits-dependent `Minutes`; the sub-issue-only values (`Rework rounds`, `Tokens`) are still computed.

### Setting them

At **step 8.4a**, the new step after *Post hansei* (8.4) and before 8.5: the lead sets every field of every task of the item, then the slice's, with `B-text` (one call per field). Setting is idempotent (the same value again is harmless). The sub-issues are closed by then, so a card never shows a number while its task is still running. A resumed close finds a card with a field already set and does not overwrite a different value without saying so.

## 6. The views (AC-6, AC-21)

Both are made by `board.sh` through `B-vcreate`, with the fallback of [64-board-script](64-board-script.md) §6.

| View | Layout | Filter | Fields shown | Order |
|---|---|---|---|---|
| `Needs you` | TABLE | `factory-status:"Waiting on you"` | Title, Kind, Role, Parent issue | none |
| `History` | TABLE | `is:closed kind:slice,"role task"` | Title, Kind, Role, Parent issue, `Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches` | closed, newest first |

**A deliberate difference from the requirement's literal.** AC-6 and ADR 0015 write the filter as `status:"Waiting on you"`. That token names the project's built-in `Status` field, which the factory does not use (`docs/agents/factory.md`, *Tracker*), so it would match no card. A custom field with a space in its name is filtered by its lower-case, hyphenated name, `factory-status`. Whether GitHub parses it exactly so is **unproven** (#52 found the syntax by reading, never by trying); the scratch-Project try settles it, and the fallback prints the filter for the person to correct. The intent (every card that is `Waiting on you`) is the requirement's; the token is the architect's, a two-way door.

## 7. Replay evidence for AC-23, AC-25 and AC-26

W12, C49 and L57 are the three stage logs the gemba rule was replayed on ([60-gemba-sample](60-gemba-sample.md) §2). The replay shows that moving the data changed no answer. QA does it in this order.

1. **Before reading any 2.0.0 text,** QA writes the expected values from the 1.3.0 rules applied to the **old** logs (`references/hansei.md` section 4 for W12, the #49 and #57 comments for C49 and L57), per log:
   - measure 1 in full (`total`, the five waits, `agent working`), from the old log;
   - for every role row, its agent-working time (Duration less held waits), and the kind 4 flag it would have got (median of earlier rows of the same role, strictly greater than twice);
   - the gemba pick: **the row's `Stage` and `Role`**, not its `#`;
   - measure 5's agents list and `Peak ctx` per role; measure 6 counts; the sum of measure 3's counts.
2. **Re-express each log** as the 2.0.0 inputs it would have produced: (a) a `T-subissues` fixture, one role task per role row, with `created_at` = that row's `Start` and `closed_at` = that row's `End` (seconds `:00`), (b) a ledger body in the §2 shape: `started` = the `Start item` row's `Start`, the Tasks table from the role rows (columns copied), the Waits and Touches tables copied verbatim, the approval touch.
3. **Read the 2.0.0 text step by step** on the new inputs (QA's readers, in the style of `tests/factory/gemba_pick.py`): lead time and the five waits, agent working per task and the kind 4 flags, the gemba pick, the measure 5 and 6 inputs, and the five field values (`Minutes` per task, `Hours`, `Rework rounds`, `Person touches`).
4. **Compare.** Everything equals the step 1 values, with exactly these listed differences:
   - the `#` of a row (the Tasks table renumbers from 1); the pick is compared by `Stage` and `Role`. For W12 the old pick is `row 2` (`Requirement`, product-owner); the new row is `row 1` with the same stage and role.
   - the lead and person rows are gone; nothing reads them (§4).
   - `Hours` is the old `total` ÷ 60 to two decimals.
   Any other difference is a QA finding, unless `hansei.md` states the new definition in one place (§8 item 2).
5. **The searches** (AC-25): `grep -rn -i 'stage log'`, `grep -rn 'stage-log'`, `grep -rn '## Waits'`, `grep -rn "Person's touches"` over `plugins/`, `README.md` and `docs/agents/factory.md`'s template. Allowed hits: the header key `stage-log cross-check`; the migration's text and the 1.x worked examples under the heading of §8 item 3; `README.md`'s history sentence. QA lists each hit with its place.
6. **The andon table** (AC-25, F4): `references/protocol.md`'s table keeps seven rows, the same names, and rows 1 to 3 and 5 to 7 word for word; row 4's observation differs only by the noun (§4). QA diffs the table against `main`.

QA reports the three replays in `reviews/qa-64.md` with the expected values quoted from step 1.

## 8. What `references/hansei.md` and `skills/run/SKILL.md` change

1. **Section 1** is rewritten: "The lead state's six sections" becomes "The lead state, and the ledger". `## Label`, `## Findings`, `## Abnormalities` keep their text; the stage log, waits and touches text moves, with its detection rules, under the ledger. A frontier round keeps its andon lines in the map's Factory run section.
2. **A row's End** is the sub-issue's `closed_at` (§4 *Result*), stated once, in the Tasks table description. The sentence "The `Start item` row starts the item's lead time" becomes "`started` starts the item's lead time".
3. **Section 4** (the worked stage-log example) is deleted and replaced by a worked **ledger** example (W12 in the §2 shape). The 1.3.0 example survives only in the migration notes of `setup-factory-skill` under the heading `Version 1.x records` (and in the changelog), so a 1.x record can still be read by a reader of the history.
4. **Section 3's marker stays `<!-- factory:hansei v5 -->`.** No key, order, grammar or meaning of the record changes; only the *Source* cells of the measures and the cross-check line's description (§4). The header key `stage-log cross-check` keeps its 1.x name so that every record of the series reads alike; renaming it is a v6 record (a day of reader and test-pin work, [60-gemba-line](60-gemba-line.md) §1 shows the cost). It is the one allowed hit of §7 step 5.
5. **Section 5** (close, in order) gains **8.4a** (set the fields, §5) and changes 8.1 (the approval touch is written to the ledger), 8.2 (waits go to the ledger), 8.6 (the commit stages the lead state and the drafts that remain). The ledger comment stays on the ticket after `work/<id>/` goes.
6. **`SKILL.md` step 5** (item start) posts the ledger (`T-comment`) and writes `started`; step 6 and 7's per-stage text points to [64-role-tasks](64-role-tasks.md) instead of "open the row".
7. **Hansei measure 3** counts rework tasks (§4); **measure 5**'s per-task spend uses the window of §5.
