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

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:10Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |
| W2 | limits | c44a10 | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | developer failed: session limit, resumed at reset |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
```

- `Agent`: the agent id the wait stopped, `lead` when it stopped the Lead itself, `-` for a `person` wait. Measure 5 reads this column to find truncated transcripts.
- Kind of a wait: four kinds. **Every** stretch in which an agent or you sat still for a reason other than its own work is one of them. A wait is found in one of two ways, and both use the same evidence, the transcript, through `scripts/cut-offs.sh`:
  - **at a notice**, during the run: a role's failure notice (or your own resume after you stopped) opens the wait, and your next action on the stopped agent closes it;
  - **at close**, by scanning every transcript of the item: this finds the cut-offs an agent recovered from by itself, which send no notice, and your own (*Cut-offs at close* below).

| Kind | What it is | Detected by | Start | End |
|---|---|---|---|---|
| `person` | the item waits on the person's answer | you put a question, card, demo or approval to the person | `date -u` when you put it | `date -u` when you read the answer |
| `limits` | a usage or session limit | a role's failure notice `failed … You've hit your … limit`; or a `cut-offs.sh` line of kind `limits` (marker `api-error:rate_limit`: your own `You've hit your … limit` entry, or a role's) | the line's start; at a role's notice, the start of the last line `cut-offs.sh` prints for that agent's transcript | the line's end; `open`, or a role's notice: `date -u` at the resume |
| `stalled` | an agent or you made no progress while the session stayed up | a role's failure notice naming no progress (the stream watchdog, `no progress for 600s`, or a stream idle timeout); or a `cut-offs.sh` line of kind `stalled` (markers `cut-mid-stream`, `request-interrupted`, `silent-gap`). For you, the line comes from your own session transcript: you stopped mid-step and were set going again only by a person message that answers no question you put (for example "continue") | the line's start: the `timestamp` of the last entry before the gap that is not itself a cut-off marker | the line's end (the agent's first output after the gap); when the line reads `open`, `date -u` when you resume the agent, spawn a new one for the work, or accept its `done` result (*Done, then stopped*) |
| `interrupted` | the connection or machine went away: machine sleep, network loss, an API server error | a role's failure notice naming an API, server or connection error that is not a usage limit (`server_error`, `overloaded`, a 5xx, a dropped connection); or a `cut-offs.sh` line of kind `interrupted` (markers `api-error:<error>` other than `rate_limit`, such as your own `API Error: Your computer went to sleep mid-response`, and `api-retry`), including a `stalled` gap the sleep log turned `interrupted` | as `stalled` | as `stalled` |

- **stalled or interrupted.** The notice or the marker decides. One exception: a `stalled` gap in which the machine was asleep at any moment is `interrupted`, because the sleep is what the watchdog saw. `cut-offs.sh --sleep-log -` applies this when you pipe in the sleep log, and only then (macOS):

  ```
  pmset -g log | awk -F'\t' '$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *$/ {print $1}' | bash "<plugin root>/scripts/cut-offs.sh" --sleep-log - -- <transcript>
  ```

  Use this exact filter, never a looser `grep`: `pmset -g log` also holds process names, PIDs, launchd service names and battery data. **Copy only UTC start and end times** of a sleep into `What` (`sleep 13:53Z–14:08Z`), never a pmset line. Where `pmset` is not available, call the script without `--sleep-log`; the notice or marker alone decides.
- **Taking the start from the transcript.** At a role's notice, run `bash "<plugin root>/scripts/cut-offs.sh" [--sleep-log -] -- <transcript>` on the stopped agent's transcript, and the **last line's start**, cut to `YYYY-MM-DDTHH:MMZ`, is the wait's start. Never `tail -n 1`: the stream watchdog writes its `[Request interrupted by user]` entry at the notice, so the last line of the file is the notice, and the stall would lose its whole ten-minute watchdog window to agent working. A recorded clock is not an estimate, so it carries no `~`. When the script prints nothing for a role's notice (a notice the transcript shows no marker for), the start is the `timestamp` of the transcript's last `user` or `assistant` entry before the notice. When the transcript cannot be read (exit 3 or 4), the start is your `date -u` stamp at the notice, marked `~` (it is later than the real start), and the cross-check names it. Your own waits come from the close scan; you may log one when you resume, with the same script on your own session transcript.
- **The Lead's own wait stops a role's.** While you are in a wait yourself, no role wait accrues: a role wait still open when your own wait starts ends there, and if the role is still waiting when you resume, a new entry opens from your resume to your action on that role. The time goes to your wait, whose cause held everything. (In the demo, QA's last stall, 01:25Z, ends at 01:43Z when your own sleep starts; the 5h06m to 06:49Z are your `interrupted`.)
- **One wait, one kind.** A stretch that changes cause midway (a stall, then a limit hit on the resume) is two entries, back to back.
- **Overlapping held waits of different kinds** (a sleep while a decision card is open) are counted once, to the kind first in measure 1's order: person, limits, stalled, interrupted.

- `Held item`: `yes` when no role agent of this item was working during the wait; `no` when other work went on. Only `yes` waits count in the lead-time split, so it never double-counts time in which an agent worked. A wait that is `no` at its start and becomes `yes` when the running work finishes is split into two entries.
- Kind of a touch: `decision card` (an answered card), `demo`, `approval`, `overturn`, `other`. A touch's time is the person's answer, as you saw it.

Write each wait and each touch as it happens, not at close.

### Cut-offs at close

At close, before the cross-check (section 5, step 2), complete `## Waits` from the transcripts:

1. Run `cut-offs.sh` once over every role agent's transcript of this item (the `Agents` column of the stage log), with `--sleep-log -` where `pmset` exists; and once over each session under `lead sessions`, with `--since` the `Start item` start and `--until` the approval time.
2. For each line, find a logged wait for the same agent (`lead` for a session transcript) whose interval overlaps or touches the line's. **When there is one**, it is the same wait: set its Start to the line's start when they differ (the line is the better clock), keep its End and its kind unless the line's kind is the stronger (`limits`, `interrupted`, `stalled`, in that order). **When there is none**, add a wait: the line's kind, the agent, Start and End from the line (cut to minutes; an `open` end takes the End of that agent's last stage-log row), `Held item` as for any wait, and `What` `found at close: <markers>`.
3. Apply *The Lead's own wait stops a role's* to the result.

A wait found at close carries no `~`: its times are recorded clocks. When the script fails for a transcript (exit 3 or 4), the cross-check names it: `cut-offs not captured (transcript <basename> unreadable)`, and that role's spend reads `not captured` (`--require-end` exits with the same code). A role agent's transcript holds only this item's work, and your window is cut by `--since`/`--until`, so no further filter is needed.

### Done, then stopped

An agent that stalls or fails **after** writing its result with `Status: done` is not an interrupted agent. When its notice arrives and:

1. the result file reads `Status: done` with every field filled, and its **Progress** names commits that are all on `item/<id>` (`git branch --contains <sha>` lists it), and
2. the role's paths have no uncommitted changes in the worktree,

read it as a completion: check the role's Done list against the artifacts as for any result, close the row, and do **not** resume or respawn the agent. Log the wait with the notice's kind (`stalled`, `interrupted` or `limits`), its End the moment you accepted the result. The row's `Peak ctx` reads `not captured (failure notice carried no token count)` when the notice carried none, and its `Notes` say `done, then <kind>`. When either check fails, it is an ordinary interruption: resume the agent.

## 2. Cross-check before the record

Before posting the record, compare every row that has a role agent with the evidence for that row:

- **git**: the role's commits on `item/<id>` belonging to that row, `git log item/<id> --format='%cI %s'`, messages starting `#<id> <role>:`, converted to UTC.
- **tracker**: the stage summary comment for that row, `gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | [.created_at, (.body | split("\n")[0])] | @tsv'`.

A row's gap is, for each piece of evidence, its distance in minutes to the row's interval [Start, End] (0 when inside); the row's gap is the largest. The record's `stage-log cross-check` names the largest gap across rows, its row and evidence: `largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)`. With no evidence for any row it reads `not captured (<reason>)`. A stage summary is posted right after the row's End, so its gap is your own delay; a gap larger than the row's duration contradicts the log. Do not fix the log to remove a gap: record it.

`Factory status` change times are not evidence: GitHub does not expose a timeline of a Project's custom field.

## 3. The record

One comment on the slice ticket, in the project's own tracker. Posted once at approval, edited once after the resurvey to fill measure 7. Never a second record for the same item.

### Marker

The body's **first line** is exactly `<!-- factory:hansei v2 -->`. A reader finds a record with `^<!-- factory:hansei v([0-9]+) -->$` on the first line. Any change to a field's key, order, grammar or meaning bumps the version; a reader that meets an unknown version skips the record and says so. v2 changed measure 1 (`stalled`, `interrupted`; `agent working` no longer includes them) and `<fpy>` (`pass first time (<n> low)`), so never compare measure 1 or 2 across v1 and v2.

### Layout

Fixed lines, fixed order. Every line is always present. Angle brackets are filled in; nothing else changes.

```
<!-- factory:hansei v2 -->
## Hansei: #<id> <slice title>

- series: <release | calibration (pre-baseline)>
- plugin: factory <semver>
- standard: <64 hex>
- tooling: <64 hex>
- context: wayfinding <version>; mattpocock-skills <version>
- active overrides: <none | name (since YYYY-MM-DD); …>
- stage-log cross-check: largest gap <N>m (<row>: <evidence>)

### Measures

1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>; stalled <dur>; interrupted <dur>
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
- `<fpy>`: `pass first time` | `pass first time (<n> low)` | `failed first time` | `n/a (did not run)` | `not captured (<reason>)`.
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
| 1 | `lead time` | **total** = approval time − start of the `Start item` row. **waiting for the person**, **waiting on limits**, **stalled**, **interrupted** = the item-held waits of that kind (stage log `## Waits`, `held item: yes`, after the close scan has added the cut-offs no notice reported; kinds and how each is detected in this file). Overlaps are counted once: within a kind as one stretch, and across kinds to the kind that comes first in this line's order (person, limits, stalled, interrupted). **agent working** = total − the four waits, so agent working + person + limits + stalled + interrupted = total. | stage log |
| 2 | `first-pass yield` | per stage (QA, security, acceptance demo), from the stage's **first** run only. **Pass first time** = the first verdict is `pass` **and** that run lists no finding at or above minor. Below minor means a severity of `low`, `info`, `trivial` or `note`; every other severity (`minor`, `medium`, `major`, `high`, `critical`, `blocker`), and a finding with no severity, counts as at or above minor. Written `pass first time` with no finding below minor either, `pass first time (<n> low)` with `<n>` findings below minor, whether or not the Lead routed them as feedback. **Failed first time** = the first verdict is not `pass`, or it lists a finding at or above minor, or (demo) any criterion failed. `n/a (did not run)` when the stage was skipped. | QA and security results, demo outcome, in `work/<id>/` |
| 3 | `rework` | per role, the number of feedback briefs that role received (any `Source`); then the number of two-way decisions overturned by a `Source: lead` feedback brief. Roles that ran and got none read `0`; roles that never ran read `0` too. | `work/<id>/NN-feedback-*.md` |
| 4 | `escaped defects` | always `not captured (tracing deferred until the first defect found in a merged item)` in v2 | deferred |
| 5 | `tokens` | per role, the Lead first, fixed role order. **spend**: `bash "<plugin root>/scripts/token-spend.sh" <transcripts>` sums `message.usage` over every transcript of that role's agents on this item (resumes and feedback rounds included), one count per distinct `message.id`; for the Lead, its main-session transcript(s) between the `Start item` start and approval. **Truncated transcripts**: a transcript cut by a stall or an interruption lost the request in flight, so its sum is short by an unknown amount; the role's spend then reads `not captured (transcript truncated by <kind>)`, never a number, `<kind>` being `stalled` or `interrupted`. The Lead recognises truncation by either of two signals: (a) **the wait**: a `stalled` or `interrupted` wait in `## Waits`, logged at a notice or added by the close scan (*Cut-offs at close*), names one of the role's agents (or `lead`) in its `Agent` column; `<kind>` is that wait's kind (the earliest, when there are several). A recovered cut-off counts as much as a final one: the request it cut was lost either way; (b) **the transcript**: `token-spend.sh --require-end` exits 6 for one of the role's transcripts (see below), with no such wait logged; `<kind>` is then `unlogged`. Exit 3 or 4 there reads `not captured (<stderr line>)` as usual. **peak context**: the largest `<subagent_tokens>` (background) or `totalTokens` (foreground) across that role's completion notices that carried one; `not captured (failure notice carried no token count)` when none did; for the Lead, the `peak` the spend script reports over the same window, or `not captured (transcript truncated by <kind>)` when its spend reads so. A role with no agent on this item: `n/a (did not run)` for both. | `scripts/token-spend.sh`; completion notices logged in the stage log |
| 6 | `person's touches` | counts of the touches list by kind | `## Person's touches` |
| 7 | `doors` | per **Under test** line of the slice frame, in frame order, named by its link text: `confirmed`, `contradicted`, or `not exercised`, as the resurvey found. `pending resurvey` from posting to the edit; `not captured (run stopped before the resurvey)` when the resurvey never happens. | the resurvey |

At close pass `--require-end` for every role transcript (never for the Lead's own session, still running). It exits 6 when a transcript was cut off: `cut-offs.sh` finds a cut-off marker anywhere in it (a `stalled` or `interrupted` line other than `silent-gap`, even one the agent recovered from), or it does not end on a final reply.

Token script exits (any non-zero exit: write the value as below, never `0`):

| Exit | The value |
|---|---|
| 3 | `not captured (transcript <file name> unreadable)` |
| 4 | `not captured (jq missing)` |
| 5 | `not captured (no messages in window)` |
| 6 | `not captured (transcript truncated by <kind>)`, `<kind>` from the `stalled` or `interrupted` wait naming that agent, else `unlogged` |

Transcripts are deleted after `cleanupPeriodDays` (30 by default), and those written before Claude Code 2.1.307 may hold placeholder usage; take the totals at close.

### Worked example

A fictional item #12 in a scratch project, factory 1.0.0, after the resurvey edit. QA failed once, security passed with two low findings, no demo, no devops stage, one decision card, one overturn, one limit hit, one machine sleep during the build, a mid-stream cut-off QA recovered from by itself, and a docs-writer that stalled after writing its `done` result. Its lead state is the stage-log example in section 4.

```
<!-- factory:hansei v2 -->
## Hansei: #12 Export a report as CSV

- series: release
- plugin: factory 1.0.0
- standard: 3b9f0c2e7a41d65f0e8c9a7b2d1f4e6a8c0b3d5e7f9a1c2b4d6e8f0a1b3c5d7e
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- context: wayfinding 5a136f2eaa0a; mattpocock-skills 1.3.1
- active overrides: none
- stage-log cross-check: largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)

### Measures

1. lead time: total 4h41m; agent working 3h02m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m
2. first-pass yield: qa failed first time; security pass first time (2 low); acceptance demo n/a (did not run)
3. rework: feedback briefs product-owner 0, architect 0, developer 1, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 1
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend 2841177 (input 1204, cache write 210338, cache read 2601870, output 27765); peak context 96412
   - product-owner: spend 301554 (input 88, cache write 41230, cache read 254101, output 6135); peak context 53942
   - architect: spend 612090 (input 140, cache write 70221, cache read 530417, output 11312); peak context 81277
   - developer: spend not captured (transcript truncated by interrupted); peak context 141210
   - qa-engineer: spend not captured (transcript truncated by stalled); peak context 74480
   - security-reviewer: spend not captured (transcript agent-a41f09.jsonl unreadable); peak context 48820
   - devops: spend n/a (did not run); peak context n/a (did not run)
   - docs-writer: spend not captured (transcript truncated by stalled); peak context not captured (failure notice carried no token count)
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
| 4 | Build | developer | c44a10 | 2026-11-04T12:55Z | 2026-11-04T14:46Z | 1h51m | W2, W3 | 138578 | done | resumed after a limit and after a sleep |
| 5 | Open PR | lead | - | 2026-11-04T14:47Z | 2026-11-04T14:48Z | 1m | - | - | done | bump check passed (no factory paths) |
| 6 | QA | qa-engineer | d21f77 | 2026-11-04T14:48Z | 2026-11-04T15:10Z | 22m | W6 | 70114 | findings | 1 finding |
| 7 | Security | security-reviewer | a41f09 | 2026-11-04T14:48Z | 2026-11-04T15:02Z | 14m | - | 48820 | pass | 2 low |
| 8 | Build (round 2) | developer | c44a10 | 2026-11-04T15:11Z | 2026-11-04T15:30Z | 19m | - | 141210 | done | QA finding fixed |
| 9 | QA (round 2) | qa-engineer | d21f77 | 2026-11-04T15:31Z | 2026-11-04T15:40Z | 9m | - | 74480 | pass | |
| 10 | Documentation | docs-writer | e90b55 | 2026-11-04T15:41Z | 2026-11-04T16:00Z | 19m | W4 | not captured (failure notice carried no token count) | done | done, then stalled; Done list checked, not resumed |
| 11 | Merge approval | person | - | 2026-11-04T16:01Z | 2026-11-04T16:21Z | 20m | W5 | - | approved | bump re-check passed (no factory paths) |

## Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:10Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |
| W2 | limits | c44a10 | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | developer failed: session limit, resumed at reset |
| W3 | interrupted | c44a10 | 2026-11-04T13:52Z | 2026-11-04T14:10Z | yes | developer failed: server_error at 14:09Z; sleep 13:53Z–14:08Z; start from cut-offs.sh; resumed |
| W4 | stalled | e90b55 | 2026-11-04T15:49Z | 2026-11-04T16:00Z | yes | docs-writer failed: no progress for 600s, after its done result; start from cut-offs.sh; accepted, not resumed |
| W5 | person | - | 2026-11-04T16:01Z | 2026-11-04T16:21Z | yes | merge and clean up? |
| W6 | stalled | d21f77 | 2026-11-04T15:03Z | 2026-11-04T15:07Z | yes | found at close: cut-mid-stream; QA recovered by itself, no notice |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
| 2026-11-04T13:40Z | overturn | overturned the architect's CSV delimiter decision |
| 2026-11-04T16:21Z | approval | merge and clean up: yes |
```

From this log: total 11:40Z → 16:21Z = 4h41m; held person waits W1 + W5 = 51m; held limit wait W2 = 15m; held stalls W4 + W6 = 11m + 4m = 15m; held interruption W3 = 18m; no two held waits overlap; agent working 4h41m − 51m − 15m − 15m − 18m = 3h02m. W6 is held because the security review, the only other agent in that stretch, ended at 15:02Z. W3, W4 and W6 also mark the developer's, the docs-writer's and the QA's transcripts as truncated, so the record reads their spend as `not captured`. No Delivery row: the item had nothing to deliver, and devops reads `n/a (did not run)` in the record.

W6 is the close scan's work: QA's transcript held one `cut-off mid-stream` marker, QA recovered and handed back normally, and no notice came. `cut-offs.sh` printed `agent-d21f77.jsonl\tstalled\t2026-11-04T15:03:12Z\t2026-11-04T15:07:40Z\tcut-mid-stream`, with no logged wait for `d21f77` overlapping it, so the lead added W6.

## 5. Close, in order

Step 8 of `skills/run/SKILL.md` follows this order:

1. Ask **merge and clean up?**. On the yes, stamp the approval time: it ends the `Merge approval` row and is the touch `approval`.
2. Complete `## Waits` with the close scan (*Cut-offs at close*), then cross-check the stage log (section 2).
3. Total the token spend per role.
4. Fill the template, measure 7 reading `pending resurvey`, and *Post hansei*. Write `hansei: <comment URL> (measure 7 pending)` into the map's **Factory run** section, because `work/<id>/` is about to go and the map survives.
5. Environment teardown, when the item had one.
6. Remove `work/<id>/`, in the item worktree, in this order, which never meets a dirty file and never reaches outside the worktree. The guard and steps 6.1 and 6.2 run as **one shell call** (one Bash tool call, one script that stops at the first failure): the Lead's shell keeps no variables between calls, so `w` exists only inside that call, and every use is written `"${w:?}"`, which stops the command when `w` is empty. Every command names the worktree by its absolute path, so the shell's working directory does not matter (it starts in the main checkout, and a `cd` into `../wt/<id>` does not persist):
   0. Guard:
      ```
      case "<id>" in ''|*[!0-9]*) echo "close: id not numeric" >&2; exit 1 ;; esac
      w="$(git worktree list --porcelain | awk -v b="branch refs/heads/item/<id>" '/^worktree /{p=substr($0,10)} $0==b{print p}')"
      [ -n "$w" ] || { echo "close: no worktree for item/<id>" >&2; exit 1; }
      if [ -L "${w:?}/work" ] || [ -L "${w:?}/work/<id>" ]; then echo "close: work/ is a symlink" >&2; exit 1; fi
      ```
      When the guard stops, stop the close and put it to the person; nothing has been removed.
   1. Commit the lead state, staging only the protocol's files: `git -C "${w:?}" add -- ':(glob)work/<id>/[0-9][0-9]-*.md'` (lead state, briefs, results, feedback, questions, including any not yet committed; the `glob` magic keeps `*` inside one directory level, so a directory named like a message, `work/<id>/03-dump/`, is not staged), then `git -C "${w:?}" add -u -- "work/<id>"` (changes to tracked files), then, when anything is staged (`git -C "${w:?}" diff --cached --quiet` exits 1), `git -C "${w:?}" commit -m "#<id> lead: close"`. Any other untracked file under `work/<id>/` (a scratch dump, a copied transcript, an `.env` a role made for a test) is never staged: a commit stays in the project's history for good, and those files were never meant for it. The next step deletes them.
   2. `git -C "${w:?}" rm -r -q -- "work/<id>" && git -C "${w:?}" clean -f -d -x -q -- "work/<id>" && [ ! -e "${w:?}/work/<id>" ] && git -C "${w:?}" commit -m "#<id> lead: remove work/"`. `git clean -fdx` takes what git does not track (ignored files such as `.DS_Store`, and the untracked files 6.1 left out) and the emptied directories. It cannot act outside the repository it is given, deletes a symlink rather than following it, and is not a shell `rm` on a variable, which Claude Code's removal safety check stops with a prompt. The `[ ! -e … ]` test catches what `git clean` leaves on purpose (a nested git repository): then stop the close and put it to the person, with `git rm` staged and nothing committed. With `&&` nothing runs after a failed step. This is the last commit on `item/<id>`.

   No `-f` is needed: after 6.1 nothing tracked under `work/<id>/` differs from `HEAD`. The record's `created_at` is earlier than both commits.
7. *Merge PR* (with the release tag), board to Done.
8. Resurvey with the frame's **Under test** list.
9. *Edit hansei*: measure 7 gets one line per Under test line. Remove the `hansei:` pointer from the Factory run section.

When the person stops the run between 4 and 8, edit measure 7 to `not captured (run stopped before the resurvey)` before you stop. A later session that finds the pointer still in the Factory run section does the same.
