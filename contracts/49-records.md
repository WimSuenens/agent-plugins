# Contract 49 — Records: the stage log with the andon, and hansei schema v3

Slice [#49](https://github.com/WimSuenens/agent-plugins/issues/49) · Requirement [49-andon](../docs/requirements/49-andon.md) · Changes: [39-stage-log](39-stage-log.md), [39-hansei-record](39-hansei-record.md) · Companions: [49-abnormality-list](49-abnormality-list.md), [49-andon-process](49-andon-process.md), [49-overrides](49-overrides.md), [49-standard-changes](49-standard-changes.md)

Serves AC-8 (the wait), AC-23, AC-24, AC-25. Everything in the two 39 contracts stays as written unless this contract says otherwise. The text goes into `plugins/factory/references/hansei.md`, next to the v2 text it replaces.

## 1. The lead state: two new sections

The lead state keeps the four sections of [39-stage-log](39-stage-log.md) in their order and gets two more after them: `## Findings`, then `## Abnormalities`. A frontier round, which has no lead state, keeps the andon lines in the map's Factory run section.

## 2. The stage log

- The `Stage` column gains one value: `Andon A<n>`. Each andon is a row: `Role` `lead`, `Agents` the paused agent's id (and the fresh one, when the resume was refused), `Start` the pause start, `End` the resume (or the carry-on), `Waits` the andon's wait id, `Result` `done`, `Notes` `kind <n> <name>; override <name|none>`. Lead rows are never tested by the slow-stage rule.
- The row of the stage that was paused names the abnormality in its `Notes`: `paused by A<n>`.
- An item with an andon runs through the same stages as one without, plus these rows.

## 3. `## Findings` and `## Abnormalities`

```
## Findings

| Role | Round | Id | Severity | Text |
|---|---|---|---|---|
| security-reviewer | 1 | L4 | low | an unreadable file yields a fingerprint and exit 0 |

## Abnormalities

| Id | Raised (UTC) | Kind | Raised by | Paused agent | Resumed (UTC) | Andon comment | Override |
|---|---|---|---|---|---|---|---|
| A1 | 2026-11-08T10:02Z | 2 same-finding-twice | lead | developer b7d031 (handed back) | 2026-11-08T10:19Z | https://github.com/example/shop/issues/12#issuecomment-111 | replay-before-build |
```

- `## Findings` is the ledger of [49-abnormality-list](49-abnormality-list.md) §4.1: one row per finding the Lead read, filled as it reads the result. Nothing else is kept there.
- `## Abnormalities`: one row per abnormality raised, from the moment it is raised, including the ones with no andon yet. `Kind` is the number and name. `Raised by`: a role, or `lead`. `Paused agent`: `<role> <id>`, `<role> <id> (handed back)`, `<role> <old id> cancelled; fresh <new id>`, or `-`. `Resumed`: the resume time, or the carry-on time when no agent was resumed. `Andon comment`: the URL, or `-` until posted. `Override`: the name, or `none`.
- The row is written at the pause start, completed at the resume, and the URL added when the comment is posted. A row that still reads `-` for the comment at close is `raised, no andon recorded` in the record (§6).

## 4. Wait kinds: four become five

The Wait kinds table of [39-stage-log](39-stage-log.md) §3 gets a fifth row:

| Kind | What it is | Detected by | Start | End |
|---|---|---|---|---|
| `andon` | the Lead held the affected work to run an andon: pause, 5 Whys, countermeasure | the Lead starts an andon ([49-andon-process](49-andon-process.md) §2) | `date -u` when the Lead starts the andon (the stop of the agent, or the start of the 5 Whys when no agent runs) | `date -u` when the resume message is sent, or when the Lead decided to carry on with no resume (or, for a refused resume, when it spawned the fresh agent) |

- **Agent**: the paused agent's id; `lead` when no agent was paused. **What**: `TaskStop A<n> kind <n>: <name>` when a running agent was stopped; `no stop A<n> kind <n>: <name>` otherwise.
- **Held item**: as for any wait: `yes` when no other role agent of the item worked meanwhile, `no` when one did (the split rule of [39-stage-log](39-stage-log.md) §3 applies). Only `yes` waits count in measure 1.
- **One wait, one kind**: an andon pause that meets a usage limit midway is two entries, back to back.
- **Close scan.** `cut-offs.sh` will print lines for a stopped agent: the stop writes a `[Request interrupted by user]` entry (marker `request-interrupted`), and the pause leaves a silent gap. Both belong to the andon, not to a stall. In *Cut-offs at close*, step 2, a line of any kind whose interval overlaps or touches a logged `andon` wait of the same agent **is that wait**: the Lead keeps the wait's kind `andon` and its Start and End (the Lead's own clock), and adds no wait.
- **Overlaps** across kinds are counted once, to the kind that comes first in this order: `person`, `limits`, `stalled`, `interrupted`, `andon`.
- **Truncation (measure 5).** A `TaskStop` can cut the request in flight, so the stopped agent's transcript may be short by an unknown amount. An `andon` wait whose `What` begins `TaskStop` names the agent as truncated, like a `stalled` or `interrupted` wait: the role's spend reads `not captured (transcript truncated by andon)`. An `andon` wait that begins `no stop` truncates nothing. `token-spend.sh --require-end` exiting 6 for the stopped transcript is explained by that wait (signal a), so the role's `<kind>` is `andon`, not `unlogged`.

The Wait kinds heading in `hansei.md` reads "Five kinds".

## 5. The hansei record, schema v3

### 5.1 Marker and schema version

First line exactly `<!-- factory:hansei v3 -->`. Regex for any version unchanged. A reader that meets an unknown version skips the record.

**v2 → v3** (release 1.1.0): measure 1 gains a sixth part, `andon`, and `agent working` no longer includes that time (a v2 record has no andon time, so for an item with no andon the two read the same); a new header line `abnormalities` is added after `active overrides`. Both are grammar changes, hence the bump. A reader never compares measure 1 across the versions for an item that had an andon. The v2 contract stays the reference for v2 records.

### 5.2 Layout

Fixed lines, fixed order; only the angle brackets change. New in v3: the `abnormalities` line and the `andon` part of measure 1.

```
<!-- factory:hansei v3 -->
## Hansei: #<id> <slice title>

- series: <release | calibration (pre-baseline)>
- plugin: factory <semver>
- standard: <64 hex>
- tooling: <64 hex>
- context: wayfinding <version>; mattpocock-skills <version>
- active overrides: <none | name (since YYYY-MM-DD); …>
- abnormalities: <none | <n> (<kind name> <count>, …): A<k> <URL | raised, no andon recorded>; …>
- stage-log cross-check: largest gap <N>m (<row>: <evidence>)

### Measures

1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>; stalled <dur>; interrupted <dur>; andon <dur>
2. first-pass yield: ... (unchanged)
3. rework: ... (unchanged)
4. escaped defects: ... (unchanged)
5. tokens: ... (unchanged)
6. person's touches: ... (unchanged)
7. doors: ... (unchanged)
```

### 5.3 Field definitions

| Field | What it holds | Source |
|---|---|---|
| `active overrides` | each **in-force** override ([49-overrides](49-overrides.md) §2) by name and `started` date, `name (since YYYY-MM-DD)`, in file order, separated by `; `. `none` when the file has no `## Overrides` section or no in-force entry. Superseded entries are not listed. | `docs/agents/factory.md` in the item worktree, read at the approval time |
| `abnormalities` | the count of rows in `## Abnormalities`, then in parentheses the count per kind name in kind order, then a colon and one `A<k> <link>` per row, where the link is the URL of its andon comment. A row with no comment reads `A<k> raised, no andon recorded`. Never a count that leaves a raised abnormality out. `none` when the table is empty. The record carries **no 5 Whys text and no transcript content**: it links the comment. | `## Abnormalities` of the lead state |
| measure 1 | **total**, **waiting for the person**, **waiting on limits**, **stalled**, **interrupted** as in v2; **andon** = the item-held `andon` waits, overlaps counted once to the kind that comes first in the order of §4; **agent working** = total − (person + limits + stalled + interrupted + andon), so the six parts add up to the total. | stage log |

The value grammar, the honesty rule and every other field and measure are those of [39-hansei-record](39-hansei-record.md). `andon` reads `0m` when the item had no andon.

### 5.4 Worked example (AC-24)

Item #12 of [39-stage-log](39-stage-log.md) §5, with two andons and one override in force. A1: a kind 2 repeat, the developer `c44a10` had handed back, 12m pause (W7, held). A2: a kind 3 hit, no agent running, 8m (W8, held). The 39 stage log's waits are unchanged: person 51m, limits 15m, stalled 15m, interrupted 18m.

```
<!-- factory:hansei v3 -->
## Hansei: #12 Export a report as CSV

- series: release
- plugin: factory 1.1.0
- standard: 9a1c5e7b3d2f40869a7c1e5b3d9f2a4c6e8b0d1f3a5c7e9b2d4f6a8c0e1b3d5f
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- context: wayfinding 5a136f2eaa0a; mattpocock-skills 1.3.1
- active overrides: replay-before-build (since 2026-11-08)
- abnormalities: 2 (same-finding-twice 1, role-outside-role 1): A1 https://github.com/example/shop/issues/12#issuecomment-111; A2 https://github.com/example/shop/issues/12#issuecomment-222
- stage-log cross-check: largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)

### Measures

1. lead time: total 4h41m; agent working 2h42m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m; andon 20m
...
```

Check: 4h41m = 281m; 51 + 15 + 15 + 18 + 20 = 119m; 281 − 119 = 162m = 2h42m. The record carries no why-chain; each link opens the andon comment. Had A2's comment not been posted, the line would end `A2 raised, no andon recorded`.

## 6. Lifecycle at close

[39-hansei-record](39-hansei-record.md) §6 keeps its order. Step 2 (the close scan) applies the new reconciliation of §4. Step 4 fills the v3 template: a row of `## Abnormalities` with no comment URL reads `raised, no andon recorded`. Nothing else changes; the settle round of [49-overrides](49-overrides.md) §8 is the run's, not the item's.

## 7. Acceptance criteria → this contract

| AC | Where |
|---|---|
| AC-8 (the wait) | §4 |
| AC-23 | §1, §2, §3, §4 |
| AC-24 | §5 |
| AC-25 | §5.3, §5.4 (the human-only read of a real comment); [49-standard-changes](49-standard-changes.md) §6 |
