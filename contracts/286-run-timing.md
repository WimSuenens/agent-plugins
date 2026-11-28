# Contract 286 — Run timing: `started:` on every path, the Run waits table, and the run-close computation

Slice [#286](https://github.com/WimSuenens/agent-plugins/issues/286) · Requirement [286-run-level-timing](../docs/requirements/286-run-level-timing.md) · Map [#278](https://github.com/WimSuenens/agent-plugins/issues/278) · ADRs [0024](../docs/adr/0024-the-obeya-discipline-has-its-own-opt-in-line.md), [0025](../docs/adr/0025-a-whole-run-block-is-computed-from-the-item-ledgers-and-a-run-waits-table.md) · Sister contracts [286-a3-v4-and-runs](286-a3-v4-and-runs.md), [286-release](286-release.md) · Builds on [64-ledger-and-fields](64-ledger-and-fields.md), [39-plugin-scripts](39-plugin-scripts.md)

Serves AC-A1 (with the sister contract), AC-A2, AC-B1 to AC-B7 and AC-C6 (its hand count). Answers the requirement's open questions Q2, Q3 and Q5 (§0).

## Paths

Paths:
- plugins/factory/skills/run/SKILL.md
- plugins/factory/references/hansei.md
- plugins/factory/references/run-close-run.md
- plugins/factory/references/run-overrides.md
- plugins/factory/references/run-route.md
- plugins/factory/scripts/run-state.sh
- plugins/factory/scripts/run-timing.sh
- tests/factory/
- CONTEXT.md
- contracts/286-run-timing.md
shared: CONTEXT.md

`plugins/` is the developer's; `run-timing.sh` is a new file. `tests/factory/` is QA's (test paths: new test files and fixtures under it, plus the pins of [286-release](286-release.md) §3). The developer adds no test beside the code: both scripts are tested by QA under `tests/factory/`. `CONTEXT.md` and this contract are the architect's (one sentence on *Whole-run block* and *Run waits*, §8, written in this stage).

## 0. Answers to the open questions

| # | Question | Answer | Where |
|---|---|---|---|
| Q2 | Which two instants bound an item in flight? | **Start**: the ledger's `- started:` line. **End**: the time of the ledger's last `approval` row in *Person's touches* (the end of the item's lead time, measure 1); an item with no `approval` row (still in flight at the close, or the run stopped) ends at the run's close instant. Both are cut to the minute and clipped to the run window `[started, close)`. Both instants live in the ledger comment, which survives the merge, so the post-merge hand count (AC-C6) reads only the ledgers, the Run waits table, the section's `started:` and the A3's `created_at`. | §4.2 |
| Q3 | A Lead limit, stall or interruption while an item is in flight: ledger, Run waits, or both? | **Partitioned by the in-flight windows.** The part of a Lead gap inside an item's in-flight window belongs to that item's ledger, where the item close scan already puts it (`hansei.md`, *Cut-offs at close*, item 1, unchanged). The run-close scan writes a Run waits row only for the minutes of a gap that lie in no item's in-flight window; a gap that crosses a window edge is cut into the parts outside. The computation also reads item waits only for minutes with an item in flight and Run waits only for minutes with none (§4.3), so a minute is counted once even when a record holds it twice. | §3.2, §4.3 |
| Q5 | Is the run-close computation a script or a procedure? | **A script**, `scripts/run-timing.sh` (two subcommands: `gaps` and `line`), tested as known-answer fixtures. The Lead pastes its output and never computes a figure by hand. Every figure is a pure function of the run body, the ledger bodies and the close instant. | §3, §4 |

Q4 (where the Runs guardrails come from) is answered in [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §0. Q1 is the lead's: the before-reading is the first run started on the release that ships this slice (AC-C6, post-merge); the slice is proven on a sandbox scenario (AC-A1, AC-B4).

**Always on (ADR 0024, AC-A2).** No step that writes `started:`, `lead sessions:`, a Run waits row or the `run timing` line reads any line of `docs/agents/factory.md`: not `obeya`, not `obeya-discipline`, not `measurement`, not `run-budget`. The texts say so in those words (§5.1). Under `measurement: lite` the three are written as under full (§4.5 says what `--lite` changes in the figures).

## 1. Seam S1: the Factory run section

### 1.1 The shape

The section that the run skill's step 2 writes (map route), that the direct route writes on the run ticket (`run-route.md`, *The direct route*, which points at step 2), and that `run-state.sh start` prints, is:

```
## Factory run

- started: <UTC time of the run start>
- step: <step>
- in flight: #<id> (item/<id>), … | none
- FREEZE: <sha> (<semver>)
- lead sessions: <session id>[, <session id> …] | none yet
- hansei: <comment URL> (measure 7 pending)
- closed in this run: #<id> <comment URL>, …
- baseline: <note>
- A3: <comment URL of the posted A3>        (written at step 9.2, after the A3 is posted)

### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
```

Two things are new: the `- lead sessions:` line, directly after `- FREEZE:`, and the `### Run waits` table, after the bullet lines. Everything else is as today.

- **`### Run waits`**: exactly six columns, header row exactly `| # | Kind | Agent | Start | End | What |` (AC-B3; no `Held item` column, ADR 0025). Rows:
  - `#`: `R1`, `R2` … counting up in the run, in the order written.
  - `Kind`: one of `person`, `limits`, `stalled`, `interrupted`. No `andon` (an andon is never a block, and an andon outside an item is already recorded in the section's andon lines).
  - `Agent`: always `lead` (a wait that belongs to no item stops the Lead).
  - `Start`, `End`: UTC, `YYYY-MM-DDTHH:MMZ`, End ≥ Start.
  - `What`: free text with no `|` and no newline; for a `person` row it names the question (`which slice next?`, `close the run now?`, `decision card on #<n>: <topic>`); for a row found at close it reads `found at close: <markers>`.
  - A row is written when its wait **ends**, never open (as in the ledger).
- **`- lead sessions:`**: the ids of the Lead's sessions that ran this run, in the order they started, separated by `, `; `none yet` until the first is written. It is the list of transcripts the run-close scan reads (§3.2). Session ids are already public in the hansei record's label; no other identifier is added.
- The **`run-state.sh` field reader** is unchanged for every existing field: the table's lines do not start with `- `, so `run-state.sh started|step|…` read as before.

### 1.2 Every path into a run (AC-B1)

| Path | What happens to `started:`, `lead sessions:` and `### Run waits` | Text that says so |
|---|---|---|
| A new run writes the section for the first time on a map | written from the template of §1.1: `started:` now, `lead sessions: <this session>`, an empty table | `skills/run/SKILL.md` step 2 (template) |
| A direct run writes it on the run ticket | the same template | `run-route.md`, *The direct route* item 1 (points at step 2; unchanged) |
| A closed section is replaced at step 0 | `run-state.sh start` prints `started:` the replacement time, `lead sessions: none yet`, an empty table; the Lead then runs `run-state.sh add-session` (§2.2) before posting | `run-overrides.md`, *Run identity* |
| A section is copied to a map on escalation | copied unchanged: the same `started`, `lead sessions`, `closed in this run`, `baseline` and `### Run waits` table with its rows | `run-route.md`, *Escalation* |
| An open section is resumed (step 0, `#<map>` or the run ticket) | `started:` unchanged and never written at resume; the resuming session's id is appended with `run-state.sh add-session`; the table is kept with its rows | `skills/run/SKILL.md` step 0 |

A section **without `started:`** (written before the line existed) is not given one: the run closes with `- run timing: not captured (run section has no started: line)` (AC-B2; `run-timing.sh line` prints it, §4.4). A section with `started:` but **without `### Run waits`** (an open run that began under an older release) is not given one either, because the waits between items before the upgrade were never recorded: `- run timing: not captured (run section has no Run waits table)`. `run-state.sh add-run-wait` exits 3 on such a section and the Lead writes no row.

### 1.3 The session id

`skills/run/SKILL.md` gets a line directly under `Plugin root: ${CLAUDE_PLUGIN_ROOT}`:

```
Session: ${CLAUDE_SESSION_ID}
```

Claude Code substitutes `${CLAUDE_SESSION_ID}` in skill files the way it substitutes `${CLAUDE_PLUGIN_ROOT}`. The Lead appends that id at step 0 (new run, replaced section, resume). **When the line shows the literal text `${CLAUDE_SESSION_ID}`** (an older Claude Code), the Lead takes the id as `hansei.md`, *Label*, says for `lead sessions` (the path of the first role transcript it spawns in the session) and appends it then. The developer checks the substitution once in the runtime-proof session and notes the result in its result file. This is a two-way door (one line plus the fallback); see the result's Decisions.

## 2. Seam S2: `run-state.sh`, three additions

Existing subcommands and exits are unchanged except `start`'s output (§2.1). Shebang and bash 3.2 rules as the file has them today. The header comment lists the new usage lines and exits.

### 2.1 `start` prints the new shape

`bash run-state.sh start <body file> [--a3 <URL>] [--now <UTC>] [--step <text>]`: the section it prints is, in this order, `- started: <now>`, `- step: <step>`, `- in flight: none`, `- FREEZE: none yet`, `- lead sessions: none yet`, `- closed in this run: none`, `- previous run: <prev>`, `- baseline: not yet`, a blank line, `### Run waits`, a blank line, the header row, the separator row `|---|---|---|---|---|---|`, a blank line. Everything else of `start` (exit 8 on an open run, `--a3`, the rest of the body kept) is unchanged.

### 2.2 `add-session`

`bash run-state.sh add-session <body file> <session id>` prints the body with the id on the section's `- lead sessions:` line. `none yet` is replaced by the id; otherwise `, <id>` is appended; an id already on the line changes nothing (exit 0, body unchanged). A section without the line gets `- lead sessions: <id>` inserted directly after its `- FREEZE:` line, or after `- started:` when it has no `FREEZE:` line. The id must match `^[A-Za-z0-9-]{1,64}$`.

Exits: 0 printed; 1 no Factory run section; 2 usage, unreadable file, bad id; 3 the section has neither `FREEZE:` nor `started:`; 4 moved (as today); 8 the section belongs to a closed run (nothing printed).

### 2.3 `add-run-wait`

`bash run-state.sh add-run-wait <body file> --kind <person|limits|stalled|interrupted> --start <UTC> --end <UTC> --what <text>` prints the body with one row appended to the section's `### Run waits` table: `| R<n> | <kind> | lead | <start> | <end> | <what> |`, `n` the largest `R` number in the table plus 1 (`R1` for an empty table). `<UTC>` is `YYYY-MM-DDTHH:MMZ` or `YYYY-MM-DDTHH:MM:SSZ`; it is written cut to the minute. A row with the same kind, start and end (after the cut) already in the table is not added again: the body is printed unchanged, exit 0, so a repeated close is harmless.

Exits: 0 printed; 1 no Factory run section; 2 usage, unreadable file, a kind not in the four, a time not in the format, end before start, a `--what` holding `|` or a newline or empty; 3 the section has no `### Run waits` table with the exact header; 4 moved; 8 the section belongs to a closed run. On every non-zero exit nothing is printed on stdout.

It writes nothing to the tracker: the Lead scans the printed body (*Scan before posting*) and posts it with `gh issue edit <run ticket> --body-file`, as for `start`.

### 2.4 The field `lead-sessions`

`bash run-state.sh lead-sessions <body file>` prints the line's value as is (`none yet`, or the ids with their `, `; an empty value prints an empty line, exit 0), exit 3 when the line is missing; the other exits as for any field. **Each id is checked** (security L2): unless the value is `none yet` or empty, it is split on `, ` and every part must match `^[A-Za-z0-9-]{1,64}$`, the grammar `add-session` writes. The first part that does not gives exit 2, nothing on stdout, and one stderr line naming the id by its place, never echoing it: `run-state: lead sessions: id <i> of <n> not in its format (^[A-Za-z0-9-]{1,64}$)`. Example: `- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c, ../../x` gives `run-state: lead sessions: id 2 of 2 not in its format (^[A-Za-z0-9-]{1,64}$)`, exit 2. Step 9.2 b then writes the run's `run timing` as `not captured (lead sessions line not in its format)` (§4.4) and reads no transcript.

### 2.5 Worked example (S2)

Body before (`run.md`):

```
# Map: payments

## Factory run

- started: 2026-12-01T10:00:00Z
- step: 4
- in flight: none
- FREEZE: 1a2b3c4 (3.10.0)
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
- closed in this run: none
- baseline: not yet

### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|

## Destination
```

`bash run-state.sh add-run-wait run.md --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09:40Z --what "which slice next?"` prints the same body with the table:

```
| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
| R1 | person | lead | 2026-12-01T10:02Z | 2026-12-01T10:09Z | which slice next? |
```

The same call on its own output prints it unchanged (exit 0). `--kind andon` exits 2. On a body whose section has an `- A3: https://…` line it exits 8 with empty stdout.

## 3. Seam S3a: `run-timing.sh gaps` (the run-close scan)

```
bash run-timing.sh gaps --run-body <body file> --close <UTC> [--ledger <file>]... [--] <cut-offs output file | ->
```

- **Input.** The body of the run ticket; the close instant; the ledger comment body of every item of the run (§4.1); the output of `cut-offs.sh` over the Lead's session transcripts (tab-separated `<basename> <kind> <start> <end | open> <markers>`, its documented format). A cut-offs line is in its format when it has exactly these five fields, `<kind>` is `limits`, `stalled` or `interrupted`, the times are times, and **`<markers>` matches `^[a-z_:-]+(,[a-z_:-]+)*$`** (security L1: `cut-offs.sh` writes only its fixed vocabulary, joined by `,`, such as `silent-gap` or `cut-mid-stream,api-error:rate_limit`; the check keeps any other text out of the `What` cell posted to the tracker). A line out of its format is exit 2.
- **What it does.** For each cut-offs line: Start = the line's start cut to the minute; End = the line's end cut to the minute, or the close instant (cut) when it reads `open`. Clip `[Start, End)` to the run window `[started, close)` (§4.2). Remove every item's in-flight window (§4.2). Each maximal stretch left with at least one minute is one output line. A line that leaves nothing prints one line on stderr, `inside items: <basename> <kind> <start>` or `outside the run: <basename> <kind> <start>`, and nothing on stdout.
- **Output.** One tab-separated line per stretch, in the order of the input lines, then by start: `<kind>\t<start>\t<end>\tfound at close: <markers>`, times `YYYY-MM-DDTHH:MMZ`. Each line is one `run-state.sh add-run-wait` call (`--kind`, `--start`, `--end`, `--what` the fourth field).
- **Exits.** 0 printed (zero or more lines); 2 usage, an unreadable file, a time not in the format, close before started, a cut-offs line not in its format (named on stderr by its line number in the cut-offs input, counting from 1, never echoed: `run-timing: a cut-offs line not in its format: line <k>`), a ledger whose item is not an item of this run; 5 a not-captured case of §4.4 (the same reason on stderr as `not captured (<reason>)`, nothing on stdout); 1 and 4 as `run-state.sh` for the run body.

**Worked example (S3a).** With the run body and ledgers of §4.6 (`started` 10:00, close 14:00, item #41 in flight 10:10–12:00, #42 11:00–13:30) and this cut-offs output (`lead.tsv`; `<sid>` stands for the session id):

```
<sid>.jsonl	stalled	2026-12-01T09:52:10.000Z	2026-12-01T10:14:05.000Z	silent-gap
<sid>.jsonl	interrupted	2026-12-01T10:35:00.000Z	2026-12-01T10:48:30.000Z	api-error:overloaded
<sid>.jsonl	limits	2026-12-01T13:40:12.500Z	open	api-error:rate_limit
```

`bash run-timing.sh gaps --run-body run.md --close 2026-12-01T14:00:27Z --ledger l41.md --ledger l42.md -- lead.tsv` prints

```
stalled	2026-12-01T10:00Z	2026-12-01T10:10Z	found at close: silent-gap
limits	2026-12-01T13:40Z	2026-12-01T14:00Z	found at close: api-error:rate_limit
```

and on stderr `inside items: <sid>.jsonl interrupted 2026-12-01T10:35:00.000Z` (that gap is #41's, in its ledger by the item close scan). The first line was clipped twice: to `started` (09:52 → 10:00) and to #41's window (10:14 → 10:10).

## 4. Seam S3b: `run-timing.sh line` (the computation)

```
bash run-timing.sh line --run-body <body file> --close <UTC> [--lite] [--ledger <file>]...
```

Prints exactly one line on stdout, the A3's `- run timing:` line (its grammar is in [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §2.1).

### 4.1 The items of the run

The items of the run are the `#<n>` of the section's `closed in this run` line (`run-state.sh items`) and of its `in flight` line (the `#<n>` tokens; `none` is no item). Each `--ledger` file is one item's ledger comment body: first line `<!-- factory:ledger v1 -->`, then `## Ledger: #<n> <title>`; the item number is that `#<n>`. A ledger file whose item is not an item of the run exits 2. An item of the run with no ledger file is the not-captured case `ledger of #<n> missing`.

### 4.2 The minute grid, the run window and the in-flight windows

- Every time is UTC, **cut to the minute** (floor; seconds and fractions dropped; a leading `~` on a ledger time is dropped, the time is used).
- `S` = the section's `started:`; `C` = `--close`. The run window is the minutes `m` with `S <= m < C`. **raw** = `C − S` in minutes. `C < S` exits 2.
- For item `i`: `a_i` = its ledger's `- started:`; `b_i` = the `Time (UTC)` of the **last** row of its *Person's touches* table whose `Kind` is `approval`, or `C` when there is none. Its **in-flight window** is `[max(a_i, S), min(b_i, C))` (empty when that is empty).
- `--close` is the A3 comment's `created_at` (ADR 0025): see §5.2 for how the Lead gets it.

### 4.3 Blocked minutes and their kind

Order of kinds: **person, limits, stalled, interrupted** (measure 1's order). For each minute `m` of the run window:

1. `F(m)` = the items whose in-flight window holds `m`.
2. **When `F(m)` is not empty**: for each item `i` in `F(m)`, `K_i(m)` = the kinds of the rows of its ledger's *Waits* table with `Held item` `yes`, `Kind` one of the four, and `Start <= m < End`. The minute is **blocked** when every `K_i(m)` is non-empty; its kind is the first in the order among the union of the `K_i(m)`. An `andon` row and a `Held item: no` row never make an item held. Run waits rows are not read for this minute.
3. **When `F(m)` is empty**: `K(m)` = the kinds of the Run waits rows with `Start <= m < End`. The minute is blocked when `K(m)` is non-empty; its kind is the first in the order. Ledger rows are not read for this minute.
4. `blocked <kind>` = the number of blocked minutes of that kind; **adjusted** = raw − the four blocked counts.

By construction each minute is counted under at most one kind, the four counts sum to at most raw, and adjusted is never negative (AC-B7).

### 4.4 Not captured, all or nothing

The whole line reads `- run timing: not captured (<reason>)` (stdout, exit 5) in these cases, checked in this order; the reasons are fixed texts:

| Reason | When |
|---|---|
| `run section has no started: line` | the section has no `started:` line (AC-B2) |
| `run section has no Run waits table` | the section has no `### Run waits` table with the exact header |
| `ledger of #<n> missing` | an item of the run has no `--ledger` file |
| `ledger of #<n> has no started: line` | a ledger has no `- started:` line |
| `ledger of #<n> not in its grammar` | a ledger's Waits or Person's touches table is missing or has a row whose times are not times |
| `Run waits row R<k> not in its grammar` | a Run waits row whose kind is not one of the four or whose times are not times or whose End is before its Start |

More reasons are written by the Lead without calling `line` (§5.2), because they come from the scan: `lead transcript <basename> unreadable` (cut-offs exit 3) and `jq missing` (cut-offs exit 4); `no lead session recorded` when the `lead sessions` line reads `none yet`, is empty or is absent (`lead-sessions` exit 3); and `lead sessions line not in its format` when `run-state.sh lead-sessions` exits 2 (an id outside `^[A-Za-z0-9-]{1,64}$`, §2.4; its stderr names the id by place). Each reason is 1 to 80 characters with no parentheses, the A3 check's `not captured` grammar.

### 4.5 `--lite`

The Lead passes `--lite` when an item of the run closed without its close scan (its record's measure 1 reads `stalled not captured (lite)`): such an item's ledger lacks the stalls and interruptions only that scan finds. Then `stalled` and `interrupted` read `not captured (lite)` and `adjusted` reads `not captured (lite)`; `raw`, `person` and `limits` are computed as in §4.3 (the kind of a minute is decided as without `--lite`, so a minute that would be `stalled` is not moved to another kind). This follows `hansei.md`, *The lite record*, which leaves `stalled` and `interrupted` not captured under lite and `limits` measured. The run-close scan itself (§5.2) runs under lite as under full.

### 4.6 Worked example (S3b): the AC-B6 fixture

Run body `run.md`: the body of §2.5 with `step: 9`, `closed in this run: #41 https://example.invalid/issues/41#issuecomment-1, #42 https://example.invalid/issues/42#issuecomment-2`, and the table:

```
| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
| R1 | person | lead | 2026-12-01T13:30Z | 2026-12-01T13:45Z | close the run now? |
| R2 | limits | lead | 2026-12-01T13:40Z | 2026-12-01T14:00Z | found at close: api-error:rate_limit |
```

Ledger `l41.md` (item A):

```
<!-- factory:ledger v1 -->
## Ledger: #41 Item A

- started: 2026-12-01T10:10Z
- start checks: author test: ok; freeze: ok; drift: same as #40; baseline: #62 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #51 | Requirement | product-owner | a1 | W1 | 40000 | done | - |

### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-12-01T10:30Z | 2026-12-01T10:50Z | yes | decision card on #41 |
| W2 | limits | lead | 2026-12-01T11:20Z | 2026-12-01T11:50Z | yes | found at close: api-error:rate_limit |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-12-01T10:50Z | decision card | chose A |
| 2026-12-01T12:00Z | approval | merge and clean up |
```

Ledger `l42.md` (item B): `## Ledger: #42 Item B`, `- started: 2026-12-01T11:00Z`, Waits `W1 | person | - | 2026-12-01T11:30Z | 2026-12-01T12:10Z | yes`, `W2 | andon | lead | 2026-12-01T12:30Z | 2026-12-01T12:40Z | yes`, `W3 | stalled | b2 | 2026-12-01T12:50Z | 2026-12-01T13:00Z | no`, touches `2026-12-01T13:30Z | approval | merge and clean up`.

`bash run-timing.sh line --run-body run.md --close 2026-12-01T14:00:27Z --ledger l41.md --ledger l42.md` prints, exit 0:

```
- run timing: raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m
```

By minutes: 10:30–10:50 person 20 (only #41 in flight, held); 11:30–11:50 person 20 (#41 limits and #42 person, both held; person first); 12:00–12:10 person 10 (only #42, held); 13:30–13:45 person 15 (R1, no item); 13:45–14:00 limits 15 (R2 after R1). Not blocked: 11:20–11:30 and 11:50–12:00 (one item not held), 12:30–12:40 (andon), 12:50–13:00 (`Held item: no`), 13:40–13:45 is person, not limits. Sum 80 ≤ 240; adjusted 160.

Controls: (a) #42's W1 kind `limits`: `blocked: person 35m, limits 45m, …`, adjusted `2h40m`. (b) R2 `2026-12-01T13:00Z`–`14:00Z`: the line is unchanged (13:00–13:30 has #42 in flight and not held, so R2 is not read there). (c) `--lite`: `- run timing: raw 4h00m; adjusted not captured (lite); blocked: person 1h05m, limits 15m, stalled not captured (lite), interrupted not captured (lite)`. (d) The body without its `started:` line: `- run timing: not captured (run section has no started: line)`, exit 5. (e) Without `--ledger l42.md`: `- run timing: not captured (ledger of #42 missing)`, exit 5.

## 5. Seam S4: the standard text

Meaning per file; the developer words it in the file's style. Word-for-word only where a line is quoted below.

### 5.1 `references/hansei.md`: a new section `## 8. The run's waits and run timing`

Appended after section 7 (no renumbering). It holds, in this order:

1. **Always written.** The Run waits table, `lead sessions` and the `run timing` line are written on every run, whatever `docs/agents/factory.md` says (`obeya`, `obeya-discipline`, `measurement` or any other line). Word for word: `None of them depends on a line of docs/agents/factory.md.`
2. **The table** (§1.1): columns, ids, kinds, `Agent` `lead`, written when the wait ends, with `run-state.sh add-run-wait`, the body scanned and posted with `gh issue edit`.
3. **Person rows.** A `person` row for every question, card, task request or approval the Lead puts to the person that belongs to no item: at least `which slice next?` (step 4, when the Lead asks), `Close the run now?` (step 9.0), the run-start `keep, promote or drop` lines (*Run start* item 2), the release-crossed question (`run-route.md`), and in a frontier round its decision cards, task requests and the round's `merge and clean up?`. Start: `date -u` when the question is put; End: `date -u` when the answer is read (AC-B4). It is written whether or not an item is in flight; the computation reads it only for minutes with no item in flight (§4.3). A question about an item stays in that item's ledger only. The question asked at the close itself (after the A3 is posted: 9.3, 9.4) falls after the close instant and needs no row.
4. **The run-close scan** (§5.2 steps b and c) finds `limits`, `stalled` and `interrupted`; the Lead does not log those kinds during the run.
5. **Lead gaps and items (Q3).** The partition of §0: inside an item's in-flight window, the item's ledger (item close scan, unchanged); outside every window, Run waits. A sentence is added to *Cut-offs at close* item 1 or after it: `The Lead's gaps outside every item go to the run's Run waits table (section 8).` The existing sentence of item 1 is not reworded (a test pins it).
6. **In flight (Q2)** and **the computation**: §4.2 and §4.3 in words, that `run-timing.sh line` computes it, and that the Lead pastes its line and never computes a figure by hand.
7. **Not captured** (§4.4) and **lite** (§4.5). *The lite record* gains one bullet: the run's timing is written under lite as under full, with `stalled`, `interrupted` and `adjusted` not captured as section 8 says.

### 5.2 `references/run-close-run.md`, step 9

- **9.0**: the `Close the run now?` question is a `person` Run waits row (written when the answer is read, before 9.1).
- **9.2** gains, before the A3 is written, the run's timing, in this order (AC-B5):
  a. Stamp the close: `date -u +%FT%TZ`.
  b. The run-close scan: for each id on `run-state.sh lead-sessions`, the transcript `~/.claude/projects/<project>/<id>.jsonl`; run `cut-offs.sh --until <the stamp> [--sleep-log -] -- <those transcripts>` (the pmset filter of `hansei.md` where `pmset` exists) into a scratch file. No `--since`: `cut-offs.sh` keeps a gap only when its start is at or after `--since`, so a gap that began before `started:` and ran into the run would be lost; `gaps` clips every line to the run window instead. Cut-offs exit 3 or 4, `lead-sessions` reading `none yet` or empty or exiting 3 (`no lead session recorded`), or `lead-sessions` exiting 2 (`lead sessions line not in its format`): the A3's line reads `not captured (<reason>)` of §4.4 and c and d are skipped.
  c. `run-timing.sh gaps --run-body <body> --close <the stamp> --ledger <each item's ledger> -- <scratch file>`; each output line becomes one `run-state.sh add-run-wait … --what '<what>'`, the fourth field in single quotes (it holds spaces, and the markers grammar of §3 admits no `'`); scan and post the body once.
  d. `run-timing.sh line --run-body <body> --close <the stamp> [--lite] --ledger …` (the body as just posted); its line goes into the A3 ([286-a3-v4-and-runs](286-a3-v4-and-runs.md) §2).
  e. After *Post A3*, read the comment's `created_at`, run d again with `--close <created_at>`; when the line differs, *Edit A3* that line (run `a3-check.sh` first). The rows of c are not rewritten.
- The ledgers are found with *Find ledger* for each item of §4.1; an item without one is the not-captured case.
- 9.2's sentence `The A3 posted is v3 (...)` changes to v4 (sister contract).

### 5.3 `skills/run/SKILL.md`

The router stays at or under 70,000 bytes (a test caps it); add only:

- the `Session: ${CLAUDE_SESSION_ID}` line under `Plugin root:` (§1.3);
- step 0: on every entry that starts or resumes a run, append the session id with `run-state.sh add-session` (one sentence);
- step 2: the template of §1.1 (the `lead sessions` line and the empty table) and one sentence: `A wait that belongs to no item goes in the Run waits table when it ends: read references/hansei.md, section 8.`;
- step 4: where the Lead asks the person which candidate, a pointer that the question is a `person` Run waits row.

### 5.4 `references/run-overrides.md`, *Run identity*

The sentence listing the new section's lines adds `lead sessions: none yet` and the empty `### Run waits` table, and says the Lead appends its session (`run-state.sh add-session`) before posting the new body. The rest of the paragraph is unchanged (tests pin `run-state.sh" start`).

### 5.5 `references/run-route.md`, *Escalation*

`(the same \`started\`, \`closed in this run\` and \`baseline\`)` becomes `(the same \`started\`, \`lead sessions\`, \`closed in this run\`, \`baseline\` and \`### Run waits\` table)`. The sentence `` `run-state.sh` exits 4 and names the map `` is unchanged (a test pins it).

## 6. Expected behaviour, for QA

| AC | Observable | Seam |
|---|---|---|
| A1 | runtime proof: a run of the new standard on the sandbox with no `obeya-discipline` line (three variants of `## Obeya`) closes with a v4 A3 whose `run timing` line is in grammar and `discipline: off`; no question was put about them | S1–S4, sister §2 |
| A2 | in `SKILL.md`, the run references and `hansei.md` section 8, no step writing `started:`, a Run waits row or `run timing` is under a condition on a `docs/agents/factory.md` line; the sentence of §5.1 item 1 is present | S4 |
| B1 | `run-state.sh started` prints a UTC time on a body from each path of §1.2 (the step 2 template filled in, `start` output, an escalation copy, a resumed section) | S1, S2 |
| B2 | §4.6 control (d); `a3-check.sh` accepts that line (sister §3); the Runs section names the run (sister §4) | S3b |
| B3 | `start` output has the table with the exact header; `add-run-wait` numbers `R1`, `R2` … | S2 |
| B4 | runtime proof: one `person` row per question, `Agent` `lead`, Start and End the put and read minutes, `What` names the question | S4 |
| B5 | fixture transcript with three gaps outside items → `cut-offs.sh` → `gaps` → `add-run-wait`: three rows, kinds `limits`, `stalled`, `interrupted`, times cut to minutes; a second run of the chain adds none | S3a, S2 |
| B6 | §4.6 and its controls (a) and (b), byte for byte | S3b |
| B7 | for any fixture: four blocked counts sum ≤ raw, adjusted ≥ 0 and equal to raw − sum; a minute counted once (QA may compare with an independent replay) | S3b |
| B5 (L1) | a cut-offs line whose markers are outside `^[a-z_:-]+(,[a-z_:-]+)*$` (for example `$(id) @who`) → `gaps` exit 2, stdout empty, stderr `run-timing: a cut-offs line not in its format: line <k>` without the line's text; the §3 fixtures unchanged | S3a |
| B4 (L2) | `lead-sessions` on `- lead sessions: <valid id>, ../../x` → exit 2, stdout empty, stderr `run-state: lead sessions: id 2 of 2 not in its format (^[A-Za-z0-9-]{1,64}$)` without the id; `none yet`, valid ids and an empty value as before | S2 |
| C6 | post-merge: the hand count uses only the section's `started:`, the A3's `created_at`, the ledgers (`started:`, Waits, `approval`) and the Run waits table | §0 Q2, §4 |

### 6.1 Rework 1 (security L1, L2): every other text that states the changed rules

Rules changed: `lead-sessions` checks its ids (exit 2, §2.4); a new not-captured reason `lead sessions line not in its format` (§4.4); the markers grammar of a cut-offs line and its exit 2 named by line number (§3); `--what` in single quotes (§5.2 c). **Search terms** (`grep -rnF` over the repository, `--exclude-dir` `worktrees`, `node_modules`, `.git`, `work`, `.nuxt`, `.output`; contracts of earlier slices and `reviews/` are history): `no lead session recorded`, `jq missing`, `Two more reasons`, `three, written by you`, `reads \`none yet\` or exits 3`, `exits 3, the A3`, `lead sessions line`, `not in its format`, `lead-sessions`, `--what <what>`, `found at close`, `markers`. The partial-statement case (a text naming three scan reasons where there are now four, or `none yet` without the empty value) is covered by `three, written by you`, `no lead session recorded` and `reads \`none yet\``.

| Text | Says now | Changes to | Owner |
|---|---|---|---|
| `plugins/factory/references/run-close-run.md:13` (9.2 b) | `On exit 3 or 4, or when \`lead-sessions\` reads \`none yet\` or exits 3, … with \`lead transcript <basename> unreadable\`, \`jq missing\` or \`no lead session recorded\`` | adds `lead-sessions` reading empty (with `no lead session recorded`) and `lead-sessions` exiting 2 with `lead sessions line not in its format` | developer |
| `plugins/factory/references/run-close-run.md:14` (9.2 c) | `--what <what>` | `--what '<what>'`, with the reason in a few words (the field holds spaces; the markers grammar admits no `'`) | developer |
| `plugins/factory/references/hansei.md:784` (section 8, *Not captured*) | `The run-close scan adds three, written by you: … and \`no lead session recorded\` (the \`lead sessions\` line reads \`none yet\` or is absent).` | `adds four`, the empty value beside `none yet`, and `lead sessions line not in its format` (`run-state.sh lead-sessions` exit 2) | developer |
| `plugins/factory/scripts/run-timing.sh:189` | stderr `a cut-offs line not in its format: <the whole line>` (echoes transcript-derived text) | `a cut-offs line not in its format: line <k>` (§3); header comment line 21 as needed | developer |
| `plugins/factory/scripts/run-state.sh:31`, `:219` | already as §2.4 (rework 1, commit 964bc25) | unchanged | — |
| `tests/factory/fixtures/split/slice286-added.txt:4`, `:5` | the 9.2 b and 9.2 c lines word for word (the allow-file of `test_run_split.sh`) | the new 9.2 b and 9.2 c lines, after the developer's edit | qa-engineer |
| `tests/factory/test_run_state_286.sh`, `test_run_timing_286.sh` | no L1 or L2 case | the two rows B5 (L1), B4 (L2) of §6 | qa-engineer |

Not stale: `plugins/factory/references/hansei.md:142`, `:147`, `:533` and `skills/setup-factory-skill/SKILL.md:215` (`found at close: <markers>` in the item ledger; the markers come from `cut-offs.sh`'s fixed vocabulary as before); `tests/factory/test_standard_text.sh:104` (`What` `found at close: <markers>`, unchanged); `CONTEXT.md` (names no reason or exit). No test pins the stderr of `gaps` or the reason list (searched `not in its format`, `jq missing`, `no lead session`, `unreadable\`` over `tests/factory/*.sh`).

## 7. Not changed

The ledger format, `ledger.sh`, measure 1 and its derived lines, the item close scan, `cut-offs.sh`, `a3-events.sh` and `intake.sh` (they read `started:` as before and ignore the new lines). No figure of any hansei record changes.

## 8. Glossary

`CONTEXT.md`, *Whole-run block*: one sentence added, `An item is in flight from its ledger's started line to its merge approval, or to the run's close when it has none.` *Run waits*: `A Lead gap during an item stays in the item's ledger; only its minutes outside every item go here.`
