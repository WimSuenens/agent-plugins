# Hansei: the stage log and the record

For the lead. Read it at item start (step 5) and at close (step 8). Roles do not need it.

The lead keeps a **stage log** in `work/<id>/00-lead-state.md` while the item runs. At the person's merge approval it computes the **hansei record** from that log and posts it as one comment on the slice ticket, before `work/<id>/` is removed.

**Measurements stay in the project.** Every record, log line and measure is written to the project's own tracker or to `work/<id>/` in the project's worktree. None names `--repo`, and none is written to `WimSuenens/agent-plugins`. The one cross-repo write is step 9's factory feedback issue, under the rule in `skills/run/SKILL.md`.

Scripts below are called as `bash "<plugin root>/scripts/<name>.sh" …`. `<plugin root>` is the path on the `Plugin root:` line of `skills/run/SKILL.md`, which the lead already holds (Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}` only in that skill file, not in this one): fill it in before running a command. The same path goes into the label's `plugin root` line, with a leading home directory written as `~`. Times are always taken from `date -u +%FT%TZ` at the moment, never estimated afterwards; a time filled in later is marked `~` (`~14:20Z`), and the cross-check names it.

## 1. The lead state's four sections

After the existing parts (board item id, status, next step, open questions, Running agents, Shared resources), the lead state gets four sections, in this order.

### `## Label`

Written once at item start, never changed.

```
## Label

- plugin root: <the path on the `Plugin root:` line of skills/run/SKILL.md>
- release: <semver, or "<dir name> (pre-release install, no semver)">
- standard: <64 hex>
- tooling: <64 hex>
- wayfinding: <version> (<source>)
- mattpocock-skills: <version> (<source>)
- lead sessions: <session id>[, <session id> …]
```

- `release`, `standard`, `tooling`: the output of `bash "<plugin root>/scripts/fingerprint.sh" "<plugin root>"`. When the script fails, each reads `not captured (<script's message>)`.
- Dependency versions, first source that works:
  1. `skill base dir`: the path segment after `<plugin>/` in the "Base directory for this skill" line the session showed when it last invoked one of that plugin's skills (for example `/wayfinding:beachhead` at step 4). This is the copy the session runs.
  2. `plugin list`: `claude plugin list --json`, the `version` of that plugin's entry. It is the installed record and can be stale mid-session, so it is labelled.
  3. Otherwise `not captured (<reason>)`.
- `lead sessions`: the Lead's session id, read from the path of the first role transcript it spawns in that session (`~/.claude/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl`; find it with `find ~/.claude/projects -name 'agent-<agent id>.jsonl'`). A resumed item in a fresh session appends that session's id.

### `## Stage log`

One row per stage run, appended as the stage starts and completed as it ends.

```
## Stage log

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
```

| Column | Content |
|---|---|
| `#` | row number, counting up |
| `Stage` | one of: `Start item`, `Requirement`, `Contracts and ADRs`, `Environment`, `Build`, `QA`, `Security`, `Acceptance demo`, `Delivery`, `Documentation`, `Open PR`, `Merge approval`. A feedback round is its own row with ` (round <n>)` appended (`Build (round 2)`). A rerun after an interruption stays in the same row. |
| `Role` | the role agent, or `lead`, or `person` (`Acceptance demo`, `Merge approval`) |
| `Agents` | every agent handle (agent id) that worked this row, comma-separated; a resume after a limit keeps the id, a fresh spawn adds one. `-` for lead and person rows. |
| `Start (UTC)` | when the lead wrote the brief (for lead and person rows: began the step, or put the question to the person) |
| `End (UTC)` | when the lead read the result (or the step ended, or the person answered) |
| `Duration` | End − Start, in the record's `<dur>` format |
| `Waits` | ids of `## Waits` entries that held this row, or `-` |
| `Peak ctx` | the largest `<subagent_tokens>` (background) or `totalTokens` (foreground) among this row's completion notices; `-` for lead and person rows; `not captured (<reason>)` when no notice carried it |
| `Result` | the result's Status, the verdict, or the outcome: `done`, `pass`, `findings`, `blocked`, `needs-decision`, `refused`, `approved`, … |
| `Notes` | free text: counts of decisions and cards, a refusal reason, an interruption |

Rules:

- The `Start item` row starts the item's lead time. It runs from the start of step 5 to the first brief.
- A refused *Open PR* (bump check) is an `Open PR` row with `Result` `refused` and the script's message in `Notes`; the next attempt is a new `Open PR` row.
- `Merge approval` starts when you ask **merge and clean up?** and ends at the person's yes. Its End is the approval time.

### `## Waits` and `## Person's touches`

```
## Waits

| Id | Kind | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|
| W1 | person | 2026-11-04T12:10Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |
| W2 | limits | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | developer failed: session limit, resumed at reset |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
```

- Kind of a wait: `person` from the moment you put a question, card, demo or approval to the person until their answer; `limits` from a role's failure notice (`failed … You've hit your … limit`), or your own `Usage limit reached` line, until the resume.
- `Held item`: `yes` when no role agent of this item was working during the wait; `no` when other work went on. Only `yes` waits count in the lead-time split, so it never double-counts time in which an agent worked. A wait that is `no` at its start and becomes `yes` when the running work finishes is split into two entries.
- Kind of a touch: `decision card` (an answered card), `demo`, `approval`, `overturn`, `other`. A touch's time is the person's answer, as you saw it.

Write each wait and each touch as it happens, not at close.

## 2. Cross-check before the record

Before posting the record, compare every row that has a role agent with the evidence for that row:

- **git**: the role's commits on `item/<id>` belonging to that row, `git log item/<id> --format='%cI %s'`, messages starting `#<id> <role>:`, converted to UTC.
- **tracker**: the stage summary comment for that row, `gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | [.created_at, (.body | split("\n")[0])] | @tsv'`.

A row's gap is, for each piece of evidence, its distance in minutes to the row's interval [Start, End] (0 when inside); the row's gap is the largest. The record's `stage-log cross-check` names the largest gap across rows, its row and evidence: `largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)`. With no evidence for any row it reads `not captured (<reason>)`. A stage summary is posted right after the row's End, so its gap is your own delay; a gap larger than the row's duration contradicts the log. Do not fix the log to remove a gap: record it.

`Factory status` change times are not evidence: GitHub does not expose a timeline of a Project's custom field.

## 3. The record

One comment on the slice ticket, in the project's own tracker. Posted once at approval, edited once after the resurvey to fill measure 7. Never a second record for the same item.

### Marker

The body's **first line** is exactly `<!-- factory:hansei v1 -->`. A reader finds a record with `^<!-- factory:hansei v([0-9]+) -->$` on the first line. Any change to a field's key, order, grammar or meaning bumps the version; a reader that meets an unknown version skips the record and says so.

### Layout

Fixed lines, fixed order. Every line is always present. Angle brackets are filled in; nothing else changes.

```
<!-- factory:hansei v1 -->
## Hansei: #<id> <slice title>

- series: <release | calibration (pre-baseline)>
- plugin: factory <semver>
- standard: <64 hex>
- tooling: <64 hex>
- context: wayfinding <version>; mattpocock-skills <version>
- active overrides: <none | name (since YYYY-MM-DD); …>
- stage-log cross-check: largest gap <N>m (<row>: <evidence>)

### Measures

1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>
2. first-pass yield: qa <fpy>; security <fpy>; acceptance demo <fpy>
3. rework: feedback briefs product-owner <n>, architect <n>, developer <n>, qa-engineer <n>, security-reviewer <n>, devops <n>, docs-writer <n>; overturned two-way decisions <n>
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend <tok>; peak context <n>
   - product-owner: spend <tok>; peak context <n>
   - architect: spend <tok>; peak context <n>
   - developer: spend <tok>; peak context <n>
   - qa-engineer: spend <tok>; peak context <n>
   - security-reviewer: spend <tok>; peak context <n>
   - devops: spend <tok>; peak context <n>
   - docs-writer: spend <tok>; peak context <n>
6. person's touches: decision cards <n>; demos <n>; approvals <n>; overturns <n>; other <n>
7. doors: <pending resurvey | not captured (reason) | per-line list below>
   - <Under test line name>: <confirmed | contradicted | not exercised>
```

### Value grammar

Every value slot (`<dur>`, `<n>`, `<fpy>`, `<tok>`, a version, a hash) holds exactly one of:

| Value | Meaning |
|---|---|
| a measured value | as defined per field below |
| `0` (or `0m`) | measured, and truly zero |
| `n/a (did not run)` | the stage or role did not run on this item. Allowed only in measures 2 and 5, and only for a stage or role that did not run. |
| `not captured (<reason>)` | you could not observe it. The reason is short and always present. |
| `pending resurvey` | measure 7 only, between posting and the resurvey edit |

**Honesty rule**: an uncaptured value is never `0`, never blank, never dropped. The line stays in its place. `n/a` never stands in for `not captured`.

Formats:

- `<dur>`: whole minutes, rounded to the nearest minute, as `<h>h<mm>m` from one hour (`3h07m`) or `<m>m` below it (`42m`, `0m`).
- `<n>`: a plain integer, no separators.
- `<fpy>`: `pass first time` | `failed first time` | `n/a (did not run)` | `not captured (<reason>)`.
- `<tok>`: `<total> (input <i>, cache write <w>, cache read <r>, output <o>)`, plain integers, `total = i + w + r + o` (this is the `spend …` part of `token-spend.sh`'s line, verbatim). Or `n/a (did not run)` / `not captured (<reason>)` for the whole slot.
- Times anywhere in the record: UTC, `YYYY-MM-DDTHH:MMZ`.

### Header fields

| Field | What it holds | Source |
|---|---|---|
| title line | `#<id>` and the slice ticket's title | `gh issue view <id> --json title` |
| `series` | `release` for an item run on a semver release; `calibration (pre-baseline)` for an item run on a pre-release install | the label |
| `plugin` | `factory <semver>`; for a pre-release install `factory <install dir name> (pre-release install, no semver)` | `## Label` |
| `standard`, `tooling` | the two fingerprints, 64 lowercase hex. A reader compares them with another record's: a different `standard` means standard work changed; a different `tooling` with the same `standard` means only tooling changed. | `## Label` |
| `context` | both dependencies of `plugin.json`, in that order; context only, never a reset trigger | `## Label` |
| `active overrides` | each active override by name and start date, or `none` when the project's `docs/agents/factory.md` has no `## Overrides` section or it lists none | `docs/agents/factory.md` at approval time |
| `stage-log cross-check` | the largest gap found by the cross-check | section 2 |

Copy the label from the lead state. The record never recomputes it.

### Measures

| # | Key | Counted | Source |
|---|---|---|---|
| 1 | `lead time` | **total** = approval time − start of the `Start item` row. **waiting for the person** and **waiting on limits** = the item-held waits of that kind (`## Waits`, `Held item: yes`), overlaps counted once. **agent working** = total − both waits, so the three parts add up to the total. | stage log |
| 2 | `first-pass yield` | per stage (QA, security, acceptance demo): the stage's **first** verdict. `pass first time` when it was `pass`; `failed first time` when it had findings or a failed criterion; `n/a (did not run)` when the stage was skipped. | QA and security results, demo outcome, in `work/<id>/` |
| 3 | `rework` | per role, the number of feedback briefs that role received (any `Source`); then the number of two-way decisions overturned by a `Source: lead` feedback brief. Roles that ran and got none read `0`; roles that never ran read `0` too. | `work/<id>/NN-feedback-*.md` |
| 4 | `escaped defects` | always `not captured (tracing deferred until the first defect found in a merged item)` in v1 | deferred |
| 5 | `tokens` | per role, the Lead first, fixed role order. **spend**: `bash "<plugin root>/scripts/token-spend.sh" <transcripts>` over every transcript of that role's agents on this item (resumes and feedback rounds included); for the Lead, its main-session transcript(s) (`~/.claude/projects/<project>/<session id>.jsonl` for each id under `lead sessions`) with `--since` the `Start item` start and `--until` the approval time. **peak context**: the largest `<subagent_tokens>` / `totalTokens` across that role's completion notices (from the stage log's `Peak ctx`); for the Lead, the `peak` the script reports over the same window. A role with no agent on this item: `n/a (did not run)` for both. | the script; completion notices |
| 6 | `person's touches` | counts of the touches list by kind | `## Person's touches` |
| 7 | `doors` | per **Under test** line of the slice frame, in frame order, named by its link text: `confirmed`, `contradicted`, or `not exercised`, as the resurvey found. `pending resurvey` from posting to the edit; `not captured (run stopped before the resurvey)` when the resurvey never happens. | the resurvey |

Token script exits (any non-zero exit: write the value as below, never `0`):

| Exit | The value |
|---|---|
| 3 | `not captured (transcript <file name> unreadable)` |
| 4 | `not captured (jq missing)` |
| 5 | `not captured (no messages in window)` |

Transcripts are deleted after `cleanupPeriodDays` (30 by default), and those written before Claude Code 2.1.307 may hold placeholder usage; take the totals at close.

### Worked example

A fictional item #12 in a scratch project, factory 1.0.0, after the resurvey edit. QA failed once, security passed, no demo, no devops stage, one decision card, one overturn, one limit hit. Its lead state is the stage-log example in section 4.

```
<!-- factory:hansei v1 -->
## Hansei: #12 Export a report as CSV

- series: release
- plugin: factory 1.0.0
- standard: 3b9f0c2e7a41d65f0e8c9a7b2d1f4e6a8c0b3d5e7f9a1c2b4d6e8f0a1b3c5d7e
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- context: wayfinding 5a136f2eaa0a; mattpocock-skills 1.3.1
- active overrides: none
- stage-log cross-check: largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)

### Measures

1. lead time: total 4h33m; agent working 3h27m; waiting for the person 51m; waiting on limits 15m
2. first-pass yield: qa failed first time; security pass first time; acceptance demo n/a (did not run)
3. rework: feedback briefs product-owner 0, architect 0, developer 1, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 1
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend 2841177 (input 1204, cache write 210338, cache read 2601870, output 27765); peak context 96412
   - product-owner: spend 301554 (input 88, cache write 41230, cache read 254101, output 6135); peak context 53942
   - architect: spend 612090 (input 140, cache write 70221, cache read 530417, output 11312); peak context 81277
   - developer: spend 1466997 (input 302, cache write 120554, cache read 1321874, output 24267); peak context 138578
   - qa-engineer: spend 520336 (input 97, cache write 64010, cache read 447880, output 8349); peak context 70114
   - security-reviewer: spend not captured (transcript agent-a41f09.jsonl unreadable); peak context 48820
   - devops: spend n/a (did not run); peak context n/a (did not run)
   - docs-writer: spend 120774 (input 31, cache write 30215, cache read 87790, output 2738); peak context 31006
6. person's touches: decision cards 1; demos 0; approvals 1; overturns 1; other 0
7. doors:
   - Measures: confirmed
   - Export format: contradicted
```

Before the resurvey edit, line 7 read `7. doors: pending resurvey` with no sub-lines.

## 4. Stage-log worked example

The lead state of item #12 at approval, new sections only.

```
## Label

- plugin root: ~/.claude/plugins/cache/wimsuenens/factory/1.0.0
- release: 1.0.0
- standard: 3b9f0c2e7a41d65f0e8c9a7b2d1f4e6a8c0b3d5e7f9a1c2b4d6e8f0a1b3c5d7e
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- wayfinding: 5a136f2eaa0a (skill base dir)
- mattpocock-skills: 1.3.1 (plugin list)
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c

## Stage log

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Start item | lead | - | 2026-11-04T11:40Z | 2026-11-04T11:43Z | 3m | - | - | done | label computed |
| 2 | Requirement | product-owner | a1c9e2 | 2026-11-04T11:43Z | 2026-11-04T11:58Z | 15m | - | 53942 | done | 9 ACs, 2 decisions |
| 3 | Contracts and ADRs | architect | b7d031 | 2026-11-04T11:58Z | 2026-11-04T12:55Z | 57m | W1 | 81277 | done | 1 card |
| 4 | Build | developer | c44a10 | 2026-11-04T12:55Z | 2026-11-04T14:46Z | 1h51m | W2 | 138578 | done | |
| 5 | Open PR | lead | - | 2026-11-04T14:47Z | 2026-11-04T14:48Z | 1m | - | - | done | bump check passed (no factory paths) |
| 6 | QA | qa-engineer | d21f77 | 2026-11-04T14:48Z | 2026-11-04T15:10Z | 22m | - | 70114 | findings | 1 finding |
| 7 | Security | security-reviewer | a41f09 | 2026-11-04T14:48Z | 2026-11-04T15:02Z | 14m | - | 48820 | pass | |
| 8 | Build (round 2) | developer | c44a10 | 2026-11-04T15:11Z | 2026-11-04T15:30Z | 19m | - | 141210 | done | QA finding fixed |
| 9 | QA (round 2) | qa-engineer | d21f77 | 2026-11-04T15:31Z | 2026-11-04T15:40Z | 9m | - | 74480 | pass | |
| 10 | Documentation | docs-writer | e90b55 | 2026-11-04T15:41Z | 2026-11-04T15:52Z | 11m | - | 31006 | done | |
| 11 | Merge approval | person | - | 2026-11-04T15:53Z | 2026-11-04T16:13Z | 20m | W3 | - | approved | |

## Waits

| Id | Kind | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|
| W1 | person | 2026-11-04T12:10Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |
| W2 | limits | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | developer failed: session limit, resumed at reset |
| W3 | person | 2026-11-04T15:53Z | 2026-11-04T16:13Z | yes | merge and clean up? |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
| 2026-11-04T13:40Z | overturn | overturned the architect's CSV delimiter decision |
| 2026-11-04T16:13Z | approval | merge and clean up: yes |
```

From this log: total 11:40Z → 16:13Z = 4h33m; held person waits W1 + W3 = 51m; held limit wait W2 = 15m; agent working 4h33m − 51m − 15m = 3h27m. No Delivery row: the item had nothing to deliver, and devops reads `n/a (did not run)` in the record.

## 5. Close, in order

Step 8 of `skills/run/SKILL.md` follows this order:

1. Ask **merge and clean up?**. On the yes, stamp the approval time: it ends the `Merge approval` row and is the touch `approval`.
2. Cross-check the stage log (section 2).
3. Total the token spend per role.
4. Fill the template, measure 7 reading `pending resurvey`, and *Post hansei*. Write `hansei: <comment URL> (measure 7 pending)` into the map's **Factory run** section, because `work/<id>/` is about to go and the map survives.
5. Environment teardown, when the item had one.
6. The last commit on `item/<id>` removes `work/<id>/`. The record's `created_at` is earlier than this commit.
7. *Merge PR* (with the release tag), board to Done.
8. Resurvey with the frame's **Under test** list.
9. *Edit hansei*: measure 7 gets one line per Under test line. Remove the `hansei:` pointer from the Factory run section.

When the person stops the run between 4 and 8, edit measure 7 to `not captured (run stopped before the resurvey)` before you stop. A later session that finds the pointer still in the Factory run section does the same.
