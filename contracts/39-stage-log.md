# Contract 39 — Stage log in the lead state

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Requirement [39-hansei-record](../docs/requirements/39-hansei-record.md) · Record: [39-hansei-record](39-hansei-record.md)

The **stage log** is the Lead's running account of an item, kept in `work/<id>/00-lead-state.md` from the start of the item to the merge approval. The hansei record is computed from it at close. Its format is written into `plugins/factory/references/hansei.md`, next to the record template.

The lead state keeps its existing parts (board item id, status, next step, open questions, Running agents, Shared resources). This contract adds four sections, in this order, after them: `## Label`, `## Stage log`, `## Waits`, `## Person's touches`.

## 1. `## Label`

Written once at item start (step 5), never changed during the item.

```
## Label

- plugin root: <the substituted ${CLAUDE_PLUGIN_ROOT}>
- release: <semver, or "<dir name> (pre-release install, no semver)">
- standard: <64 hex>
- tooling: <64 hex>
- wayfinding: <version> (<source>)
- mattpocock-skills: <version> (<source>)
- lead sessions: <session id>[, <session id> …]
```

- `release`, `standard`, `tooling`: the output of `scripts/fingerprint.sh` ([39-plugin-scripts](39-plugin-scripts.md) §1). When the script fails, each reads `not captured (<script's message>)`.
- Dependency versions, first source that works:
  1. `skill base dir`: the path segment after `<plugin>/` in the "Base directory for this skill" line the session showed when it last invoked one of that plugin's skills (for example `/wayfinding:beachhead` at step 4). This is the copy the session runs.
  2. `plugin list`: `claude plugin list --json`, the `version` of the entry for that plugin. It is the installed record and can be stale mid-session (#35), so it is labelled.
  3. Otherwise `not captured (<reason>)`.
- `lead sessions`: the Lead's session id, read from the path of the first role transcript it spawns in that session (`~/.claude/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl`; find it with `find ~/.claude/projects -name 'agent-<agent id>.jsonl'`). A resumed item in a fresh session appends that session's id.

## 2. `## Stage log`

One row per stage run, appended as the stage starts and completed as it ends.

```
## Stage log

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
```

| Column | Content |
|---|---|
| `#` | row number, counting up |
| `Stage` | one of: `Start item`, `Requirement`, `Contracts and ADRs`, `Environment`, `Build`, `QA`, `Security`, `Acceptance demo`, `Delivery`, `Documentation`, `Open PR`, `Merge approval`. A feedback round is its own row with ` (round <n>)` appended (`Build (round 2)`, `QA (round 2)`). A rerun after an interruption stays in the same row. |
| `Role` | the role agent, or `lead`, or `person` (`Acceptance demo`, `Merge approval`) |
| `Agents` | every agent handle (agent id) that worked this row, comma-separated; a resume after a limit keeps the id, a fresh spawn adds one. `-` for lead and person rows. |
| `Start (UTC)` | `date -u +%FT%TZ` when the Lead wrote the brief (or, for lead and person rows, began the step / put the question to the person) |
| `End (UTC)` | `date -u +%FT%TZ` when the Lead read the result (or the step ended / the person answered) |
| `Duration` | End − Start, in the record's `<dur>` format |
| `Waits` | the ids of `## Waits` entries that held this row, or `-` |
| `Peak ctx` | the largest `<subagent_tokens>` (background) or `totalTokens` (foreground) among this row's completion notices; `-` for lead and person rows; `not captured (<reason>)` when no notice carried it |
| `Result` | `done`, `pass`, `findings`, `blocked`, `needs-decision`, `refused`, `approved`, … (the result's Status, the verdict, or the outcome) |
| `Notes` | free text: counts of decisions and cards, a refusal reason, an interruption |

Rules:

- **Every time is taken from `date -u`** at the moment, never estimated afterwards. A time filled in later is marked `~` (for example `~14:20Z`) and the record's cross-check names it.
- The `Start item` row starts the item's lead time. It runs from the start of step 5 to the first brief.
- A refused *Open PR* (bump check, [39-plugin-scripts](39-plugin-scripts.md) §2) is an `Open PR` row with `Result` `refused` and the script's message in `Notes`; the next attempt is a new `Open PR` row.
- `Merge approval` starts when the Lead asks **merge and clean up?** and ends at the person's yes. Its End is the record's approval time.

## 3. `## Waits` and `## Person's touches`

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

- **Kind** of a wait: `person` from the moment the Lead puts a question, card, demo or approval to the person until their answer; `limits` from a role's failure notice (`failed … You've hit your … limit`), or the Lead's own `Usage limit reached` line, until the resume.
- **Held item**: `yes` when no role agent of this item was working during the wait (the item could not move); `no` when other work went on meanwhile. Only `yes` waits count in the record's lead-time split, so the split never double-counts time in which an agent worked. A wait that is `no` at its start and becomes `yes` when the running work finishes is split into two entries.
- **Kind** of a touch: `decision card`, `demo`, `approval`, `overturn`, `other`. A touch's time is the person's answer, as the Lead saw it.

## 4. Cross-check before the record

Before posting the record (close step 2), the Lead compares every row that has a role agent with the evidence for that row:

- **git**: the role's commits on `item/<id>` belonging to that row, `git log item/<id> --format='%cI %s'`, messages starting `#<id> <role>:`, converted to UTC.
- **tracker**: the stage summary comment for that row, `gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | [.created_at, (.body | split("\n")[0])] | @tsv'`.

A row's gap is, for each piece of evidence, its distance in minutes to the row's interval [Start, End] (0 when inside), and the row's gap is the largest of these. The record's `stage-log cross-check` field names the largest gap across rows, its row and its evidence: `largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)`. With no evidence for any row it reads `not captured (<reason>)`.

A stage summary is posted right after the row's End, so its gap is the Lead's own delay; a gap larger than the row's duration is what AC-12 calls a contradiction. The Lead does not fix the log to remove the gap: it records it.

`Factory status` change times are not used as evidence: GitHub does not expose a timeline of a Project's custom single-select field through `gh issue`, and the Project's item only reports its latest update.

## 5. Worked example

The lead state of item #12 at approval, abridged to the new sections:

```
## Label

- plugin root: /Users/p/.claude/plugins/cache/wimsuenens/factory/1.0.0
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

