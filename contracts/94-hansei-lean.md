# Contract 94 — Waste tags on andons, findings and waits; flow efficiency and the per-stage view on the hansei record

Slice [#94](https://github.com/WimSuenens/agent-plugins/issues/94) · Requirement [94-lean-extensions](../docs/requirements/94-lean-extensions.md) · Builds on [39-hansei-record](39-hansei-record.md), [64-ledger-and-fields](64-ledger-and-fields.md), [60-gemba-line](60-gemba-line.md) · Sources [#87](https://github.com/WimSuenens/agent-plugins/issues/87), [#88](https://github.com/WimSuenens/agent-plugins/issues/88) · Sister contracts [94-a3-v2](94-a3-v2.md), [94-release](94-release.md)

Serves AC-4, AC-5, AC-6, AC-7, AC-8, AC-9. **Fixed here, before the build, and replayed by QA:** the tag token and its places (§1, §2), the minute rule of the per-stage view and the percent rule (§3, §4), the placement of the two derived lines under measure 1 without a schema bump (§5), and the worked examples (§6), which QA uses as expected values.

## Paths

Paths:
- plugins/factory/references/hansei.md
- plugins/factory/skills/run/SKILL.md
- tests/factory/
- contracts/94-hansei-lean.md
shared: none

`hansei.md` is edited by the developer once for this contract and [94-a3-v2](94-a3-v2.md) together. The developer adds no test beside the code (the slice adds no script on this side). The record's readers (`references/baseline.md`, `tests/factory/baseline_replay.py`) are **not changed**: they key on `^1\. lead time: ` and `^   - <role>: ` and never read the two new sub-lines (checked against `parse()` in `baseline_replay.py`: the sub-line keys `flow efficiency` and `per stage` are not roles, and header lines are matched only at column 0).

## 1. The waste tag: one token, four places, one guide (AC-4, AC-5)

**The token** is the text `waste: ` followed by one of the eight lowercase names `transport`, `inventory`, `motion`, `waiting`, `overproduction`, `over-processing`, `defects`, `skills`, ended by a space, `,`, `;` or the end of its cell or line. Untagged is valid everywhere and reads `-` where a value is written. **Every 2.2.0 ledger, lead state and andon comment is valid unchanged.**

| Place | Form | Written when |
|---|---|---|
| an andon comment | an optional **last line** `- waste: <type>` after `- carried on:`; absent or `- waste: -` is untagged. The comment is posted once and never edited, so the tag is decided when it is posted. `<!-- factory:andon v1 -->` stays v1 (readers key on the line keys; a line a reader does not know is not read). | the lead, in the draft, before the scan |
| a ledger Waits row | a token inside the `What` cell, after the existing text, separated by `; ` (`TaskStop A1 kind 2: same-finding-twice; waste: defects` is **not** counted: the A3 skips `andon`-kind waits, [94-a3-v2](94-a3-v2.md) §3.1; tag the andon comment instead) | the lead, when it writes the row at the wait's end |
| a ledger Tasks row | a token per tagged finding inside the `Notes` cell (`1 finding; waste: defects`), appended when the lead adds the row | the lead, as it reads the task's result |
| the lead state `## Findings` table | an **optional sixth column** `Waste` (`Role | Round | Id | Severity | Text | Waste`), `-` or a type. A table of five columns stays valid. It is the lead's working place: **the A3 never reads it** (the lead state is removed at the merge, so the tag is copied to the Tasks row's `Notes` as above when the row is added). | the lead, as it logs the finding |

**The guide.** `hansei.md` gains a subsection `### Tagging waste` at the end of section 1 (after `## Findings` and `## Abnormalities`) holding the table below and the three rules after it. The table is the guide of AC-5; the developer may tighten the wording, not drop a type or a column.

| Type | In the factory | Tag it when the entry is |
|---|---|---|
| `transport` | handoffs: brief, result, closing comment, the next role loading the context again | a brief or result that had to be sent or read twice, or a resume that reloaded the same context |
| `inventory` | work started or ready and not moving: `Ready` slices, open branches, frontier tickets waiting | a slice or branch that sat while the item did something else |
| `motion` | agents searching and re-reading files (cache-read tokens) | an agent that read the same files again without new output |
| `waiting` | the Waits table: person, limits, stalled, interrupted, andon | a wait of any of the five kinds |
| `overproduction` | building beyond the frame (the lead's breadth check) | work that no acceptance criterion asked for |
| `over-processing` | checks without a risk trigger, exact-prose assertions | a check or an assertion whose failure could not have mattered |
| `defects` | rework rounds, first-pass yield, escaped defects | a finding at or above minor, a rework task, a failed demo criterion |
| `skills` | a lesson kept in one role's memory that never reaches a shared artefact | a repeat that a shared rule would have prevented |

Rules: (1) one tag per entry; when two types fit, tag the **cause**, and when the cause is unclear the type earlier in the table's order. (2) Tagging is the lead's reading; nothing checks that a tag is right, and an untagged entry is not an error. (3) A tag word outside the eight is not read: the A3 skips it and names it ([94-a3-v2](94-a3-v2.md) §3.1).

**Edits in `skills/run/SKILL.md`:** *The comment* (the andon comment template) gains the optional last line `- waste: <type | ->` with the sentence "Optional. A reader that does not know the line ignores it."; the *Kind 2* bullet of *Detection* says the `## Findings` row may carry a sixth cell `Waste`. Nothing else in SKILL.md changes for the tags. The sentence in `hansei.md` section 1 that the Findings table "is the ledger of the kind 2 rule … Nothing else is kept there" gains "and the optional `Waste` tag".

## 2. Where the A3 reads the tags (open question 1, restated for the build)

The sources, the counting rule, the order, `untagged`, and the unreadable-ledger case are in [94-a3-v2](94-a3-v2.md) §3.1. This contract fixes only what the sources must hold: the three places in the table above, all on the tracker, all surviving the merge. No field is added to the hansei record or the ledger header (the ledger stays `v1`: a `waste:` token inside an existing free-text cell adds no column, key or table).

## 3. The per-stage view: the minute rule (AC-7; open question 2)

Both new lines are derived at the close, at step 8.4, from the ledger's Tasks and Waits tables, the role-task sub-issues' times (*List role tasks*) and measure 1. They are not stored anywhere else.

**Minute grid.** Every time is UTC, cut to the minute (`floor`). Let `s` be the ledger's `started` and `e` the approval time; `T` is the set of minutes `m` with `s <= m < e`. For Tasks row `i` (table order) let `a_i` be its sub-issue's `created_at` and `b_i` its `closed_at`, each cut to the minute; the row covers `[a_i, b_i)`. Let `W` be the union, clipped to `T`, of every Waits row with `Held item: yes`, of any of the five kinds, as an interval `[Start, End)`.

**Stage of a minute `m` in `T`** (the first rule that holds):

1. the stage of the **first row in table order** that covers `m` (rows may overlap when two roles ran together; the earlier row wins, and the later row gets only the minutes the earlier does not cover);
2. else the stage of the row with the **smallest `a_i` greater than `m`** (ties: table order): the minutes before a stage starts, in which the lead briefs it, belong to the stage it prepares, and a wait that ends before a stage starts is a wait *at or before* that stage;
3. else the pseudo-stage **`Merge approval`**: every minute after the last row ends (the lead's closing steps, the demo, the person's merge wait).

**Bucket name.** The row's `Stage` cell with a trailing ` (round <n>)` removed (`Build (round 2)` is `Build`). `Merge approval` is reserved for rule 3 and is not a Tasks-table stage. Buckets are listed in the order of their first row in the table, `Merge approval` last, and **only when it has at least one minute**; a stage whose rows were wholly covered by earlier rows is still listed (`Security 0m / 0m`).

**Numbers.** For a bucket: `working` = the number of its minutes that are not in `W`; `waiting` = the number of its minutes that are in `W`. Both in whole minutes, written `<working>m / <waiting>m` (always minutes, never `3h07m`).

**The two sums hold by construction**, and QA tests them: `Σ working = e − s − |W| = agent working` of measure 1, and `Σ waiting = |W|` = the sum of the five item-held waits of measure 1 (measure 1 counts overlaps once across kinds, which is the union). A wait that spans two stages is split by minutes; a wait is never listed by id.

**Not captured, all or nothing** (a partial list would break the two sums):

- `per stage: not captured (ledger comment missing)`: the ledger cannot be read.
- `per stage: not captured (no task row)`: the Tasks table has no row.
- `per stage: not captured (task times not readable)`: any row's sub-issue times cannot be read.

## 4. Flow efficiency (AC-6)

`flow efficiency` = `agent working / total` of measure 1 as a whole percent, **rounded half up**, written `<n>%`. Integer rule, so QA and the lead agree: with `w` = agent working minutes and `t` = total minutes, `pct = floor((200 * w + t) / (2 * t))`. It is `not captured (<reason>)` — never `0%` — when:

- `not captured (total is 0m)`: `t = 0`.
- `not captured (ledger comment missing)`: measure 1 itself is `not captured (ledger comment missing)`.
- `not captured (agent working not captured)`: any other case in which measure 1's `agent working` or `total` is not a measured value (the Tasks or Waits table lacks what it needs).

`13%` for 52 of 404 (52 / 404 = 12.87); `58%` for 162 of 281; `75%` for 45 of 60; `100%` for `w = t`; a measured `w = 0` with `t > 0` reads `0%` (measured, truly zero).

## 5. Placement on the record: two sub-lines, no schema bump (AC-8, AC-9)

In the `### Layout` template of `hansei.md` section 3, directly under measure 1 and above measure 2, two sub-lines in the same indent as measure 5's role lines (three spaces, `- `):

```
1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>; stalled <dur>; interrupted <dur>; andon <dur>
   - flow efficiency: <pct>%
   - per stage: <stage> <working>m / <waiting>m; …
2. first-pass yield: …
```

with the not-captured forms of §3 and §4 in their place. **The marker stays `<!-- factory:hansei v5 -->`; no header key, no measure and no stored field is added.** Why this is not a version change: a v3/v4/v5 reader finds measure 1 by `^1\. lead time: ` and reads only its `; `-parts, and finds role lines by `^   - <role>: `; sub-lines it does not know are not read. The baseline and the A3 measure table are unchanged and read neither sub-line (that is #92, out of scope).

`hansei.md` edits, in these places:

- **Layout** (section 3): the template above.
- **Value grammar:** a row `<pct>` (a whole percent `[0-9]+%`, or `not captured (<reason>)`) and a note that the per-stage line's minutes are `<m>m` whole minutes.
- **Measures table, row 1, Source column:** a sentence "The two sub-lines under the line (`flow efficiency`, `per stage`) are **derived at the close** from the Tasks and Waits tables and the role-task times, per the rule below; they are not stored anywhere else."
- **A new paragraph** "Derived lines of measure 1" with §3 and §4 of this contract (the minute rule, the bucket names, the percent rule, the not-captured forms) and the two small examples of §6.
- **Versions paragraph** (the line "Release 2.0.0 keeps v5…"): a sentence "Release 2.3.0 keeps v5: it adds two derived sub-lines under measure 1 (`flow efficiency`, `per stage`); no key, order, grammar or meaning of an existing line changes, and every reader of v3 to v5 ignores the sub-lines. A record posted before 2.3.0 has none and is read as before."
- **The worked example** (item #12): the two sub-lines under measure 1 (§6.1) and one sentence after the check paragraph reproducing the arithmetic.
- **Section 5, close in order**, item 4: "Fill the template (measure 1 with its two derived sub-lines), measure 7 reading `pending resurvey`, and *Post hansei*." `skills/run/SKILL.md` step 8.4 reads the same: "Fill the hansei template (it carries the `gemba` line and, under measure 1, the two derived lines)".

## 6. Worked examples (expected values for QA)

### 6.1 Item #12, the example already in `hansei.md`

The ledger of section 4 (total 11:40Z to 16:21Z = 281m, held waits 119m, agent working 162m), with the role-task sub-issues' times (cut to the minute):

| Row | Stage | `created_at` | `closed_at` |
|---|---|---|---|
| 1 (#31) | Requirement | 11:40 | 12:00 |
| 2 (#32) | Contracts and ADRs | 12:00 | 12:50 |
| 3 (#33) | Build | 12:50 | 14:15 |
| 4 (#34) | QA | 14:15 | 15:10 |
| 5 (#35) | Security | 14:30 | 15:02 |
| 6 (#36) | Build (round 2) | 15:10 | 15:35 |
| 7 (#37) | QA (round 2) | 15:35 | 15:48 |
| 8 (#38) | Documentation | 15:48 | 16:00 |

Held waits clipped to `T`: W1 12:02–12:41 (39m, in Contracts and ADRs), W2 13:05–13:20 and W3 13:52–14:10 (15m + 18m, in Build), W6 15:03–15:07 (4m, in QA), W7 15:11–15:23 (12m, in Build round 2), W4 15:49–16:00 (11m, in Documentation), W8 16:01–16:09 and W5 16:09–16:21 (8m + 12m, after the last row: Merge approval). Row 5 (Security) lies wholly inside row 4, so it gets no minute. Result:

```
1. lead time: total 4h41m; agent working 2h42m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m; andon 20m
   - flow efficiency: 58%
   - per stage: Requirement 20m / 0m; Contracts and ADRs 11m / 39m; Build 65m / 45m; QA 64m / 4m; Security 0m / 0m; Documentation 1m / 11m; Merge approval 1m / 20m
```

Checks: working 20 + 11 + 65 + 64 + 0 + 1 + 1 = 162 = 2h42m; waiting 0 + 39 + 45 + 4 + 0 + 11 + 20 = 119 = 51 + 15 + 15 + 18 + 20; 162 / 281 = 57.65, rounds to 58.

### 6.2 The item #73 figures (the requirement's AC-6 and AC-7)

Started 10:00Z, approved 16:44Z (total 404m = 6h44m), one held person wait 10:52–16:44 (352m = 5h52m), agent working 52m. Rows (cut to the minute): Requirement 10:00–10:10, Contracts and ADRs 10:12–10:22, Build 10:24–10:40, QA 10:40–10:46, Documentation 10:46–10:50.

```
1. lead time: total 6h44m; agent working 52m; waiting for the person 5h52m; waiting on limits 0m; stalled 0m; interrupted 0m; andon 0m
   - flow efficiency: 13%
   - per stage: Requirement 10m / 0m; Contracts and ADRs 12m / 0m; Build 18m / 0m; QA 6m / 0m; Documentation 4m / 0m; Merge approval 2m / 352m
```

Contracts and ADRs has 12m because the two minutes 10:10–10:12 precede its start (rule 2); Build 18m likewise (10:22–10:24); Merge approval has the two minutes 10:50–10:52 of the lead's closing steps (rule 3) and the whole 352m wait. Sum: 10 + 12 + 18 + 6 + 4 + 2 = 52. The 352 waiting minutes appear on `Merge approval` and on no other stage.

### 6.3 Overlap, a wait between stages, a rework round

Started 09:00Z, approved 10:00Z (total 60m). Rows: Build 09:00–09:20; QA 09:20–09:30; Security 09:25–09:40; Build (round 2) 09:45–09:55. Held waits: limits 09:10–09:16 (6m), person 09:40–09:45 (5m), person 09:56–10:00 (4m). Agent working 45m.

```
   - flow efficiency: 75%
   - per stage: Build 24m / 11m; QA 10m / 0m; Security 10m / 0m; Merge approval 1m / 4m
```

Security gets 09:30–09:40 only (09:25–09:30 is QA's, the earlier row); the 5m wait 09:40–09:45 precedes `Build (round 2)` and lands on Build (rule 2); the closing minute 09:55–09:56 and the 4m wait are `Merge approval`. Sums: working 24 + 10 + 10 + 1 = 45; waiting 11 + 4 = 15.

### 6.4 Not captured

A ledger comment that was deleted: measure 1 reads `not captured (ledger comment missing)` in each part, and the sub-lines read `   - flow efficiency: not captured (ledger comment missing)` and `   - per stage: not captured (ledger comment missing)`. A total of 0m: `flow efficiency: not captured (total is 0m)`.

## 7. Map of the criteria to this contract

| AC | Covered by | Test (offline) |
|---|---|---|
| AC-4 | §1 (every place optional, `-` untagged) | the 2.2.0 ledger and andon fixtures still pass the A3 replay unchanged; a tagged and an untagged row counted as [94-a3-v2](94-a3-v2.md) §3.1 says |
| AC-5 | §1, the guide table in `hansei.md` | text pins: the eight names and the "Tag it when" column in `### Tagging waste` |
| AC-6 | §4, §6.2 | replay of the percent rule on 52/404, 162/281, 45/60, `t = 0`, missing ledger |
| AC-7 | §3, §6.1 to §6.3 | replay of the minute rule on the three tables; the two sums; `Merge approval` carries the 352 |
| AC-8 | §5 | the marker pin still reads `v5`; no new header key; the baseline replay over every record fixture gives the same result; a record with the sub-lines is read by `parse()` as one without |
| AC-9 | §5 | measure 1's line unchanged on the worked example; the sub-lines follow the value grammar |

Existing tests that may pin the record layout and that QA checks (`grep -rn "lead time: total\|### Layout\|Release 2.0.0 keeps v5\|## Findings" tests/`): `test_baseline_a3.sh` (`v4-*`, `v5-*`), `test_gemba.sh` (`t6-*`, `t7-*`), `test_ledger_fields.sh`, `test_baseline_replay.sh`. A test that counts lines of the template between two headings must allow the two sub-lines.
