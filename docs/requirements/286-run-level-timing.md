# 286 — Run-level timing end to end, discipline off (the before-reading)

Slice: [#286](https://github.com/WimSuenens/agent-plugins/issues/286) · Map: [#278](https://github.com/WimSuenens/agent-plugins/issues/278) · ADRs: [0024](../adr/0024-the-obeya-discipline-has-its-own-opt-in-line.md), [0025](../adr/0025-a-whole-run-block-is-computed-from-the-item-ledgers-and-a-run-waits-table.md), [0026](../adr/0026-the-run-level-reading-is-its-own-a3-block-and-baseline-runs-section.md) · Builds on: [39-hansei-record](39-hansei-record.md), [57-per-run-a3-and-baseline](57-per-run-a3-and-baseline.md), [64-board-as-run-state](64-board-as-run-state.md)

## User outcome

The person starts an ordinary factory run, with no `obeya-discipline` line and no other switch. While the run goes on, the Lead writes every wait that belongs to no item (the person's answer to "which slice next?" or "close the run now?", and any limit, stall or interruption of the Lead's own session) in a **Run waits** table in the run's Factory run section. When the run closes, the person reads in the A3 how long the run took (raw), how long it took without the minutes in which the whole run stood still (adjusted), and how many of those still minutes each kind caused (person, limits, stalled, interrupted), next to `discipline: off`. The pinned Factory baseline then shows a **Runs** section for the series, with this run as its first sample. The item-based experiment in the A3 reads exactly as before.

This serves the map's Destination: run-level timing "recorded on existing artifacts and compared in the A3 and baseline", and "this repo has its own before-reading". The discovery-readiness checkpoint and the run with the preview on are the next slice.

## Terms used here

- **Factory run section**, **ledger**, **held wait** (`Held item: yes`), **hansei record**, **A3**, **baseline**, **series**, **R1/R2**, **honesty rule**: as in `CONTEXT.md` and requirements 39, 57 and 64.
- **In flight**: an item is in flight from its start to its close, as the architect's contract defines the two instants from the item's records (see Open questions, Q2).
- **Whole-run block**: a minute in which every item in flight is in a held wait of kind `person`, `limits`, `stalled` or `interrupted`, or no item is in flight and a Run waits row covers the minute (ADR 0025). An `andon` wait is never a block; a wait with `Held item: no` is never a block.
- **Raw run duration**: the A3 comment's `created_at` minus the section's `started:`. **Adjusted**: raw minus whole-run blocked minutes.
- **`<dur>`**: the hansei value grammar (`3h07m` from one hour, `42m` below it, `0m`).
- **The new standard**: the factory as it is on this slice's branch, loaded in a separate session with `claude --plugin-dir <worktree>/plugins/factory` (the installed release stays frozen for the running run).
- **[fixture]**: QA checks it offline against files it writes. **[runtime-proof]**: checked from a scenario transcript of the new standard on the sandbox repo. **[post-merge]**: checked on the first real run of this repo under the released version (see Open questions, Q1).

## Acceptance criteria

### A. Run timing is always on (ADR 0024)

**AC-A1** [runtime-proof] — *Under test: ADR 0024.*
Given a project whose `docs/agents/factory.md` has no `obeya-discipline` line (one scenario with `obeya: on`, one with `obeya: off`, one with no `## Obeya` section at all),
When a run of the new standard closes with at least one item closed,
Then the posted A3 has the marker `<!-- factory:a3 v4 -->`, carries a `run timing` line in the grammar of AC-C1 and a line `- discipline: off`, and the person was asked no question and set no line to get them.

**AC-A2** [fixture]
Given the new standard's text (`skills/run/SKILL.md`, the `references/` files it names for run start, run waits and run close, and the scripts they call),
When QA searches every step that writes `started:`, a Run waits row, or the `run timing` line,
Then none of those steps is conditional on any line of `docs/agents/factory.md` (`obeya`, `obeya-discipline`, `measurement` included): under `measurement: lite` the same three are written.

### B. Whole-run blocks from the item ledgers and the Run waits table (ADR 0025)

**AC-B1** [fixture] — *Under test: ADR 0025, `started:` on every path.*
Given each path into a run that the standard names (a new run writing the section for the first time on a map; a direct run's run ticket; a closed section replaced by `run-state.sh start`; a section copied to a map on escalation; a resumed open section),
When the path has written or kept the section,
Then `run-state.sh started <body file>` prints a UTC time for every one; the replaced section's `started:` is the replacement time, the copied section's is the original unchanged, and the resumed section's is unchanged by the resume.

**AC-B2** [fixture]
Given a Factory run section that has no `started:` line (written before the line existed),
When the run closes,
Then the Lead does not invent a start: the A3 reads `- run timing: not captured (run section has no started: line)`, `a3-check.sh` accepts it, and the baseline's Runs section names the run as not counted with that reason instead of counting it.

**AC-B3** [fixture] — the table.
Given a Factory run section written by the new standard (new or replaced by `run-state.sh start`),
Then it holds a `### Run waits` table with exactly the columns `#`, `Kind`, `Agent`, `Start`, `End`, `What` (no `Held item` column), ids `R1`, `R2` … counting up in the run, and a row is written when its wait ends.

**AC-B4** [runtime-proof] — *Under test: ADR 0025, questions between items.*
Given a run of the new standard in which the Lead asks the person "which slice next?" while no item is in flight, and later "Close the run now?",
When the run closes,
Then the Run waits table has one `person` row for each question, `Agent` `lead`, Start the minute the question was put and End the minute the answer was read, and the `What` cell names the question.

**AC-B5** [fixture] — *Under test: ADR 0025, limits, stalls and interruptions of the Lead outside items.*
Given a Lead session transcript fixture holding, while no item is in flight, one usage-limit gap, one stall gap and one interruption gap (each of a kind `cut-offs.sh` already reports),
When the run-close step of the standard runs `cut-offs.sh` over the Lead's transcript from `started:` to the close,
Then each gap becomes one Run waits row of its kind (`limits`, `stalled`, `interrupted`), `Agent` `lead`, Start and End from the script's line cut to minutes, and no gap is lost or written twice.

**AC-B6** [fixture] — *Under test: ADR 0025, blocked never exceeds raw, no double count, agrees with a hand count.*
Given this fixture (all times UTC on one day, intervals start-inclusive, end-exclusive, whole minutes):

| What | Interval | Notes |
|---|---|---|
| `started:` | 10:00 | |
| A3 `created_at` | 14:00 | raw 4h00m |
| item A in flight | 10:10–12:00 | |
| item B in flight | 11:00–13:30 | |
| A W1 `person`, held yes | 10:30–10:50 | only A in flight |
| A W2 `limits`, held yes | 11:20–11:50 | |
| B W1 `person`, held yes | 11:30–12:10 | |
| B W2 `andon`, held yes | 12:30–12:40 | andon is not a block |
| B W3 `stalled`, held no | 12:50–13:00 | not held, not a block |
| R1 `person` (close the run now?) | 13:30–13:45 | no item in flight |
| R2 `limits` (Lead, found by `cut-offs.sh`) | 13:40–14:00 | overlaps R1 for 5m |

When the run-close computation of the standard is applied,
Then the A3 reads `- run timing: raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m`.
Hand count: person = 20 (A W1) + 20 (11:30–11:50, A and B both held; person before limits) + 10 (12:00–12:10, only B, held) + 15 (R1) = 65m; limits = 15m (R2 after R1 ends); 11:20–11:30 and 11:50–12:00 are not blocked (one item in flight not held); the sum 80m ≤ raw 240m; adjusted = 240 − 80 = 160m.
And for two controls, each a copy changed in one field: (a) B W1 changed to `limits`: then 11:30–11:50 counts as limits and the line reads `person 35m, limits 45m` (A W1 20 + R1 15; 20 + 10 + R2 15), adjusted unchanged; (b) R2 changed to 13:00–14:00 while B is in flight 13:00–13:30 and not held: R2 counts only 13:45–14:00, the line is unchanged.

**AC-B7** [fixture]
Given any fixture QA builds from ledgers and a Run waits table,
Then the four blocked kinds sum to at most raw, adjusted is never negative, and no minute is counted under two kinds.

### C. The run-level reading: A3 v4 and the baseline Runs section (ADR 0026)

**AC-C1** [fixture] — *Under test: ADR 0026, `a3-check.sh` checks v4 and still accepts v1 to v3.*
Given a v4 A3 fixture: a valid v3 A3 with the marker changed to `<!-- factory:a3 v4 -->` and, directly after `not detectable from records` (and after `calibration experiments` when that line is present), the four lines
```
- run timing: raw <dur>; adjusted <dur>; blocked: person <dur>, limits <dur>, stalled <dur>, interrupted <dur>
- discipline: off
- run compared: none (no run with discipline off in series <M.N>)
- guardrails: first-pass yield <…>; rework <…>
```
When `bash a3-check.sh <file>` runs,
Then it prints `ok v4` and exits 0; and for each of these controls it exits 1 with a `refused: <key> (…)` line naming the key: one of the four lines left out; the four in another order; `discipline:` neither `off` nor `on`; a `run timing` value outside the grammar (a missing kind, a blank, a `<dur>` not in the hansei grammar) that is not `not captured (<reason>)`; `run compared` in none of the ADR's three forms.
And every v1, v2 and v3 fixture the acceptance suite holds today gives the same output and exit as on `main`; a marker `v5` exits 3 with `skipped: …`.

**AC-C2** [fixture] — *Under test: ADR 0026, the experiment lines keep their meaning.*
Given `plugins/factory/references/a3.md` on this branch and on `main`,
Then sections 4 to 7 (the problem, the experiment, before/during/after, not comparable) are unchanged in text; and for every v3 refusal fixture in the suite, the same fixture with the marker set to v4 and the four lines added is refused with the same `refused:` lines for the v3 keys.

**AC-C3** [fixture] — *Under test: ADR 0026, the Runs section derives from the A3 lines and the series line alone.*
Given a set of v4 A3 fixtures and the hansei records of their items,
When the baseline update of the new standard is replayed,
Then every series block has a `Runs` section split into `discipline: off` and `discipline: on`; each figure is a median with `k of n runs` (R1), and every figure can be recomputed by QA from the A3s' `run`, `series and release`, `run timing`, `discipline` and `guardrails` lines without opening a ledger, a Run waits table or a Factory run section. A series with no v4 A3 shows each half as `none (no run in series)` (exact wording per the contract); no v1–v3 A3 is read for runs.

**AC-C4** [fixture]
Given a v4 A3 whose `run` line reads `run stopped`,
Then the Runs section names it (`not counted: run stopped`, with its A3 link) and leaves it out of every median and every `n`.

**AC-C5** [fixture] — *Under test: ADR 0026, marker `v1` keeps *Find baseline* working.*
Given the body of the existing baseline issue [#62](https://github.com/WimSuenens/agent-plugins/issues/62) as it stands at the slice start, used as a fixture,
When *Find baseline* runs (its filter on that body) and then the update of the new standard rewrites the body,
Then *Find baseline* returns #62 before and after, the rewritten body's first line is still exactly `<!-- factory:baseline v1 -->`, every section that existed before is still present with the same figures, and the person is asked nothing.

**AC-C6** [post-merge] — the before-reading.
Given the first run of this repo that runs entirely on the released new standard, with no `obeya-discipline` line,
When it closes,
Then its A3 is v4 with `discipline: off` and `run compared: none (no run with discipline off in series <M.N>)`, passes `a3-check.sh`, and the Factory baseline issue's current series shows a Runs section whose `discipline: off` half lists this run as `1 of 1 runs`, with the same raw and adjusted values as the A3; QA (or the person) checks the A3's numbers against a hand count from the run's item ledgers and its Run waits table, as in AC-B6.

## Out of scope

- Reading the `obeya-discipline` line: this slice always writes `discipline: off` and no step reads the line (frame, Deliberately faked).
- The start-of-run warning for `obeya-discipline: on` without a before-reading (next slice, ADR 0024/0026).
- The discovery-readiness checkpoint (next slice).
- `run compared` beyond `none (…)`: on this first run there is nothing to compare with. `a3-check.sh` accepts the other two forms as grammar (AC-C1), but no criterion here tests the medians, the signed differences or the `not comparable (release moved …)` reading.
- What the Obeya room shows of run timing (map Deferred; trigger: a run with the preview on).
- Backfilling v1–v3 A3s or the past runs #280 found (ADR 0026: no backfill).
- Making the discipline the default; pooling across projects; any causal or better/worse claim.
- Flow efficiency as a baseline field ([#92](https://github.com/WimSuenens/agent-plugins/issues/92), outside the map).

## Open questions

- **Q1 (lead)** — Which run is the before-reading? The run in flight (map #278) is frozen on the installed 3.9.x and will post a v3 A3 at its close, so it cannot carry `run timing`. Leaning: the before-reading is the first run started after the release of this slice is installed (AC-C6, [post-merge]), and the frame's "the run this slice is proven on" is read as the runtime proof on the sandbox (AC-A1, AC-B4).
- **Q2 (architect)** — Which two instants bound an item "in flight" (start: the ledger's `started:`; end: the hansei record's `created_at`, the merge, or the card set Done)? AC-B6 states its intervals directly, so it does not wait on the answer; the contract must name the source so the post-merge hand count (AC-C6) is reproducible.
- **Q3 (architect)** — A Lead limit, stall or interruption while an item is in flight: does it go to the item's ledger (as the item close scan does today), to Run waits, or both? ADR 0025 says Run waits hold waits that belong to no item; the contract must say how a Lead gap during an item is assigned so that no minute lands twice. AC-B5 only uses gaps with no item in flight.
- **Q4 (architect)** — ADR 0026 reads the baseline guardrails "over the items of those runs (R1 and R2)", while the frame's Under test line says the Runs section needs nothing beyond the A3's lines and the series line. Leaning: the Runs guardrails are read from the A3's `guardrails` line (which the Lead computes from the items at close), so AC-C3 holds as written; if the contract reads them from the hansei records instead, AC-C3's "without opening" clause names the records as allowed.
- **Q5 (architect)** — Is the run-close computation of AC-B6 a script (testable as known-answer fixtures) or a procedure in the standard text (replayed by QA by hand)? Leaning: a script, since overlapping intervals across items are where a hand computation errs; the criterion holds either way.
