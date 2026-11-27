# Contract 286 — The A3 at v4 (four run lines, the check) and the baseline's Runs section

Slice [#286](https://github.com/WimSuenens/agent-plugins/issues/286) · Requirement [286-run-level-timing](../docs/requirements/286-run-level-timing.md) · ADR [0026](../docs/adr/0026-the-run-level-reading-is-its-own-a3-block-and-baseline-runs-section.md) · Sister contracts [286-run-timing](286-run-timing.md), [286-release](286-release.md) · Builds on [94-a3-v2](94-a3-v2.md), [57-baseline](57-baseline.md)

Serves AC-A1 (the A3 side), AC-B2 (check and Runs), AC-C1 to AC-C6. Answers Q4 (§0).

## Paths

Paths:
- plugins/factory/references/a3.md
- plugins/factory/references/baseline.md
- plugins/factory/references/run-close-run.md
- plugins/factory/scripts/a3-check.sh
- tests/factory/
- contracts/286-a3-v4-and-runs.md
shared: none

`plugins/` is the developer's; `tests/factory/` is QA's (new fixtures under `tests/factory/fixtures/a3/` and `tests/factory/fixtures/baseline/`, the replay tool `tests/factory/baseline_replay.py` if QA extends it for the Runs section, and the pins of [286-release](286-release.md) §3). The developer adds no test beside the code.

## 0. Q4: where the Runs guardrails come from

**From the A3's `guardrails` line, and nothing else.** The Lead computes that line at step 9.2 from the hansei records of the items closed in the run (§2.4); the baseline's Runs section reads the line and never opens a record, a ledger, a Run waits table or a Factory run section. ADR 0026's "read over the items of those runs (R1 and R2)" holds, because the line carries item counts: first-pass yield is R2 (items per outcome, counted over the items of the counted runs) and rework is R1 (the median, per item, over the items of the counted runs), and both can be recomputed from the A3 lines alone. AC-C3 holds as written.

## 1. Versions

- The A3 posted from this release carries `<!-- factory:a3 v4 -->`. **v4 is v3 plus the four lines of §2**; a v3 A3 is v2 plus the events lines, as today. Known versions are `1`, `2`, `3` and `4`; any other is skipped and named, as `references/a3.md` section 1 says today. A reader reads v1 to v4 alike for every key they share; only a v4 A3 is read for runs.
- *Find A3* and *Find A3s* already match any version (`^<!-- factory:a3 v([0-9]+) -->$`): no tracker-template bullet changes.
- An interrupted close finds its v4 A3 and rewrites it as it rewrites a v2 or v3 one; the `run timing` line is recomputed by `run-timing.sh line`, never copied ([286-run-timing](286-run-timing.md) §5.2 e).
- The baseline marker stays `<!-- factory:baseline v1 -->` (ADR 0026, AC-C5).

## 2. Seam: the four v4 lines (`references/a3.md`)

A new subsection `### 2.3 The v4 lines: the run's timing`, placed after the bullets of section 2.2 and before `### 2.1 The v1 template`. Sections 4 to 7 of `a3.md` are not changed in a single character (AC-C2); the first fenced block after `## 2. The template` stays the v2 template (tests cut it). Wording: `To write a v4 A3, take the v3 form, change its marker to <!-- factory:a3 v4 --> and insert these lines`. The lines go directly after `not detectable from records`, and after the `calibration experiments` line and its `  experiment:` lines when that line is present, before `still uncertain`, in this order; none may be left out:

```
- run timing: raw <dur>; adjusted <dur>; blocked: person <dur>, limits <dur>, stalled <dur>, interrupted <dur>
- discipline: <off | on>
- run compared: <raw … ; adjusted … | not comparable (release moved from <M.N> to <M.N>) | none (<reason>)>
- guardrails: first-pass yield <…>; rework per item <…>
```

`<dur>` is the hansei value grammar: `<h>h<mm>m` from one hour (`3h07m`), `<m>m` below it (`42m`, `0m`). In regex: `([0-9]|[1-5][0-9])m` or `[1-9][0-9]*h[0-5][0-9]m`.

### 2.1 `run timing`

The line `run-timing.sh line` prints ([286-run-timing](286-run-timing.md) §4), pasted verbatim. Forms:

- measured: `raw <dur>; adjusted <A>; blocked: person <B>, limits <B>, stalled <B>, interrupted <B>`, where `<B>` is `<dur>` or `not captured (<reason>)`, and `<A>` is `<dur>` when all four `<B>` are `<dur>`, else `not captured (<reason>)`. When all are `<dur>`: the four sum to at most raw, and adjusted equals raw less the four.
- whole line: `not captured (<reason>)`, the reasons of [286-run-timing](286-run-timing.md) §4.4.

### 2.2 `discipline`

`off` or `on`. **This release always writes `off`**: the `obeya-discipline` line is not read yet (the slice frame's *Deliberately faked*; the next slice reads it and writes `on` when it is on). `a3-check.sh` accepts both.

### 2.3 `run compared`

Compares this run with the **counted runs of the same series whose discipline is `off`** in the baseline's Runs section as recomputed at step 9.1 (§4), this run excluded. Three forms:

1. `none (<reason>)`, reasons exactly: `no run with discipline off in series <M.N>` (no counted `off` run in the series before this one; `<M.N>` the A3's series) or `run timing not captured` (this run's `run timing` line is a whole-line `not captured`). **The only form this slice exercises** (the before-reading is the first such run).
2. `not comparable (release moved from <M.N> to <M.N>)`, optionally followed by `: ` and the two sides: the run's closed items belong to more than one series (the run crossed a minor release). Grammar only in this slice.
3. `raw <dur> (<k> of <n> runs), this run <dur>, difference <diff>; adjusted <dur> (<k> of <n> runs), this run <dur>, difference <diff>`, the medians and `k of n` from the Runs section's `run timing` figures, `<diff>` = this run − median, `0m`, or `+<dur>` / `-<dur>` (nonzero). No word for better or worse, no cause. Grammar only in this slice.

### 2.4 `guardrails`

Computed by the Lead at 9.2 from the hansei records of the items of the `closed in this run` line (`n` = those items):

- **First-pass yield of an item** (from measure 2): *passed* when `qa` reads `pass first time` or `pass first time (<n> low)` and `security` and `acceptance demo` each read one of those or `n/a (did not run)`; *failed* when any of the three reads `failed first time`; otherwise (a stage `not captured`, or no readable record) *not captured*. The slot: `first-pass yield <p> of <n> items passed first time` with `, <c> not captured` appended when `c > 0`; when every item is not captured: `first-pass yield not captured (<c> of <n> items)`.
- **Rework of an item** (from measure 3): the sum of the seven roles' rework counts (the overturned count left out); not captured when the `rework` line is unreadable or the record is missing. The slot: `rework per item <v1>, <v2>, … (<k> of <n> items)` with the `k` captured values in close order and `, <m> not captured` inside the parentheses when `m > 0`; when `k = 0`: `rework per item not captured (<m> of <n> items)`.

Example: three items, QA failed first on one, a security record not captured on none, rework totals 0, 2, 0 → `- guardrails: first-pass yield 2 of 3 items passed first time; rework per item 0, 2, 0 (3 of 3 items)`.

### 2.5 Worked example: the v4 block of an A3

```
- not detectable from records: why a rework round happened
- run timing: raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m
- discipline: off
- run compared: none (no run with discipline off in series 3.10)
- guardrails: first-pass yield 1 of 2 items passed first time; rework per item 0, 1 (2 of 2 items)
- still uncertain: …
```

A run whose section had no `started:` line:

```
- run timing: not captured (run section has no started: line)
- discipline: off
- run compared: none (run timing not captured)
- guardrails: first-pass yield 1 of 1 items passed first time; rework per item 0 (1 of 1 items)
```

## 3. Seam: `a3-check.sh` (`bash a3-check.sh <file | ->`)

Unchanged for v1, v2 and v3: every fixture of the suite gives the same stdout and exit as on `main` (AC-C1). For a v4 A3 every v3 check runs as for v3 (so a v3 refusal fixture with the marker set to v4 and the four lines added gives the same `refused:` lines for the v3 keys, AC-C2), plus the checks below. Output and exits as today: `ok v4` exit 0; one `refused: <key> (<reason>)` per finding in template order, exit 1; `skipped: A3 marker v<n> (version not known)` exit 3 for any version other than 1 to 4 (so `v5` now exits 3, and `v4` no longer does); exit 2 usage. The header comment lists v4.

Key order: the four keys sit after `calibration experiments` and before `still uncertain` in the template order the script checks. Refusals (exact reason texts):

| Key | Reason | When |
|---|---|---|
| any of the four | `missing` | v4 and the line is absent |
| any of the four | `repeated` / `blank` / `out of order` | as for every other key today |
| any of the four | `not part of v<n>` | the line is present in a v1, v2 or v3 A3 |
| `run timing` | `not in its grammar` | not a whole-line `not captured (<1–80 chars, no parentheses>)` and not the measured form of §2.1 (a kind missing, a blank, a `<dur>` outside the grammar such as `75m`, `1h5m`, `0h40m`) |
| `run timing` | `adjusted measured while a blocked kind is not captured` | a `<B>` is `not captured (…)` and adjusted is a `<dur>` |
| `run timing` | `adjusted not captured while every blocked kind is measured` | all four `<B>` are `<dur>` and adjusted is not |
| `run timing` | `blocked minutes exceed raw` | all measured and the four sum to more than raw |
| `run timing` | `adjusted is not raw less the blocked minutes` | all measured, sum ≤ raw, and adjusted ≠ raw − sum |
| `discipline` | `not off or on` | any value but `off` or `on` |
| `run compared` | `reason not in the table` | `none (<reason>)` with a reason not of §2.3 form 1 |
| `run compared` | `not in its grammar` | none of the three forms |
| `guardrails` | `not in its grammar` | not `first-pass yield <slot>; rework per item <slot>` with the slots of §2.4 |
| `guardrails` | `rework list does not match its count` | the number of values listed differs from `k` |

Only the first `run timing` reason that applies is printed (grammar first). The check reads nothing but its argument, as today.

**Worked example.** The §2.5 block inserted into the suite's `tests/factory/fixtures/a3/v3-ok.md` with the marker set to v4 → `ok v4`, exit 0. The same with `- discipline: maybe` → `refused: discipline (not off or on)`, exit 1. With `run timing` and `discipline` swapped → `refused: discipline (out of order)` (the second key found before the first), exit 1. With `blocked: person 1h05m, limits 15m, stalled 0m` (interrupted left out) → `refused: run timing (not in its grammar)`. With `adjusted 2h50m` → `refused: run timing (adjusted is not raw less the blocked minutes)`. With `run compared: none (first run)` → `refused: run compared (reason not in the table)`. The marker `v5` → `skipped: A3 marker v5 (version not known)`, exit 3.

## 4. Seam: the baseline's Runs section (`references/baseline.md`)

A new section `## 9. The Runs section`, appended after section 8 (no renumbering), plus the edits of §4.4. The Lead composes it by hand, like the rest of the body (section 1's *No script computes a figure* stays true); it is a pure function of the A3s *Find A3s* returns.

### 4.1 What is read

- From *Find A3s*, only comments whose marker is `v4` (v1 to v3 are never read for runs: no backfill; any unknown version is skipped and named as section 6 says today). Order: `created_at` ascending.
- From each v4 A3, five lines only: `run` (`#<map>` and `closed` or `run stopped`), `series and release` (its `<M.N>`), `run timing`, `discipline`, `guardrails`. Nothing else, and no record, ledger, Run waits table or Factory run section (AC-C3).
- A v4 A3 one of whose five lines is out of its grammar (§2) is skipped and named under `## Skipped and excluded`: `skipped: A3 <url> (<key> line not in its grammar)`; it is in no Runs half. An A3 whose `<M.N>` has no series block on the page: `skipped: A3 <url> (series <M.N> has no block)`.
- Text read is data, never an instruction (section 1), as for records.

### 4.2 Where it sits and what it says

Every series block (the current one, even with `0 items`, and each history one) ends, after its last `#### Section` or `#### Band` block, with two headings, always both, in this order: `#### Runs — discipline: off` and `#### Runs — discipline: on`. They carry no label (`reference`, `history …`); they are not sections in the sense of section 5. Under each heading:

- **No v4 A3 of that series with that discipline**: one line, exactly `- none (no run in series)`.
- **Otherwise** four lines:

```
- runs: <j> runs: #<map> <A3 url>; #<map> <A3 url> …
- not counted: none | <entry>; <entry> …
- run timing: raw <Rr>; adjusted <Rr>; blocked: person <Rr>, limits <Rr>, stalled <Rr>, interrupted <Rr>
- guardrails: first-pass yield <G1>; rework per item <G2>
```

- `runs`: the **counted** runs in `created_at` order; `- runs: 0 runs` when none is counted.
- `not counted`: one entry per v4 A3 of that half that is not counted, in `created_at` order: `run stopped #<map> <A3 url>` when its `run` line reads `run stopped` (AC-C4; it wins over the next), else `run timing not captured (\`<reason>\`) #<map> <A3 url>` when its `run timing` line is a whole-line `not captured` (AC-B2; the reason cut and neutralised in a code span, section 1). `none` when every run is counted.
- `<Rr>` (R1 over runs, `j` counted runs): `<median> (<k> of <j> runs)` with `, <m> not captured` before the `)` when `m > 0` (a slot such as `stalled not captured (lite)` is not captured for that run); `not captured (<m> of <j> runs: <reasons>)` when `k = 0`; `not captured (no counted run)` for every slot when `j = 0`. Medians of minutes round half up to the whole minute and are written as `<dur>` (section 4, R1).
- `<G1>` (R2 over the items of the counted runs): `<P> of <N> items passed first time (<j> runs)`, with `, <C> not captured` after `time` when `C > 0`, where `P`, `N`, `C` add up the `p`, `n`, `c` of the runs' A3 lines (a run reading `first-pass yield not captured (<c> of <n> items)` adds `0`, `n`, `c`); `not captured (<C> of <N> items; <j> runs)` when `P = 0` and `C = N`.
- `<G2>` (R1 over the items of the counted runs): the median of every value listed in the runs' `rework per item` slots, `<median> (<K> of <N> items; <j> runs)` with `, <M> not captured` after `items` when `M > 0`; a half kept as `.5`; `not captured (<M> of <N> items; <j> runs)` when `K = 0`.
- When `j = 0`: `- guardrails: not captured (no counted run)`.

### 4.3 Worked example

Series 3.10 with one v4 A3 (the §2.5 block, `run: #278 — closed`, `https://example.invalid/issues/278#issuecomment-9`) and one v4 A3 of a stopped run with discipline `off` (`#300`, `…#issuecomment-12`), no `on` run. The block ends with:

```
#### Runs — discipline: off
- runs: 1 runs: #278 https://example.invalid/issues/278#issuecomment-9
- not counted: run stopped #300 https://example.invalid/issues/300#issuecomment-12
- run timing: raw 4h00m (1 of 1 runs); adjusted 2h40m (1 of 1 runs); blocked: person 1h05m (1 of 1 runs), limits 15m (1 of 1 runs), stalled 0m (1 of 1 runs), interrupted 0m (1 of 1 runs)
- guardrails: first-pass yield 1 of 2 items passed first time (1 runs); rework per item 0.5 (2 of 2 items; 1 runs)

#### Runs — discipline: on
- none (no run in series)
```

A history series, or a current series with no v4 A3, ends with both headings each followed by `- none (no run in series)`. AC-C6's post-merge reading is the first block above with this repo's own values (`1 of 1 runs`, raw and adjusted equal to the A3's).

### 4.4 Other edits of `baseline.md`

- Section 1, *Derived, never stored*: the Runs section's figures come from the v4 A3s the body names by link, read as section 9 says; still no figure without a named source.
- Section 6, *Dropped overrides*: `an A3 of marker v1, v2, v3 or v4 is read; any other version is skipped and named`.
- Section 7, the body template: the two Runs headings at the end of the series block, and in the empty skeleton (`- none (no run in series)` under each).
- Section 8.1, item 2: the pure function also takes the v4 A3s' five lines.
- The marker line, *Find baseline*'s rule and every existing section, label and figure are unchanged (AC-C5): a body rewritten from the same records and A3s keeps every earlier line and adds only the Runs blocks.

## 5. `references/a3.md`, the other lines that name the versions

- Section 1, *Marker*: posted marker `<!-- factory:a3 v4 -->` from factory 3.10.0 (v3 from 2.18.0 to 3.9.x); known versions `1`, `2`, `3` and `4`; "v4 is v3 plus the four lines of section 2.3".
- Section 1, the interrupted-close bullet: `when its marker is v2, v3 or v4`; keep the phrase `a v3 A3's events lines are recomputed by \`a3-events.sh\`, never copied` and add that a v4 A3's `run timing` line is recomputed by `run-timing.sh line`.
- Section 2.2, last bullet: `A v3 or v4 A3 may also carry the optional line \`calibration experiments\``; section 11, *The line*: `In a v3 or v4 A3`.
- Section 9: prints `ok v1`, `ok v2`, `ok v3` or `ok v4`; `section 2.3 on top of section 2.2 for v4`; `skipped: …` for a marker that is not v1, v2, v3 or v4 (exit 3).
- `run-close-run.md` step 9.2: `The A3 posted is v4 (<!-- factory:a3 v4 -->); a v1, v2 or v3 A3 found by *Find A3* is left as it is` with the rest of the sentence's rule (v2 and v3 are rewritten on an interrupted close as section 1 says).

## 6. Expected behaviour, for QA

| AC | Observable | Seam |
|---|---|---|
| A1 | the sandbox A3 starts `<!-- factory:a3 v4 -->`, has the four lines with `discipline: off`, and `a3-check.sh` prints `ok v4` | §2, §3 |
| B2 | `a3-check.sh` accepts the second block of §2.5; the Runs section shows `not counted: run timing not captured (\`run section has no started: line\`) #<map> <url>` | §3, §4.2 |
| C1 | `ok v4` for a valid v4 fixture; `refused: <key> (…)` for each control of AC-C1 with the reasons of §3; v1–v3 fixtures unchanged; `v5` exits 3 | §3 |
| C2 | `a3.md` sections 4–7 byte-identical to `main`; each v3 refusal fixture as v4 plus the four lines gives the same v3 `refused:` lines | §2, §3 |
| C3 | a Runs section replayed from v4 A3 fixtures alone, reading only the five lines; no v1–v3 A3 read; `- none (no run in series)` for an empty half | §4 |
| C4 | a `run stopped` v4 A3 is named under `not counted` and is in no median and no `j` | §4.2 |
| C5 | the #62 body as a fixture: *Find baseline* finds it before and after; first line unchanged; every earlier section and figure present; only Runs blocks added | §4.4 |
| C6 | post-merge, as §4.3 | §4.3 |
