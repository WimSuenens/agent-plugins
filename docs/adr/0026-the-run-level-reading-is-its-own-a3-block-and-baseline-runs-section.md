---
status: accepted
---

# The run-level reading is its own A3 block and a Runs section of the baseline

Decided on [Obeya discipline: the run-level reading in the A3 and the baseline](https://github.com/WimSuenens/agent-plugins/issues/282), part of [Map: the Obeya discipline for the factory](https://github.com/WimSuenens/agent-plugins/issues/278); builds on [0024](0024-the-obeya-discipline-has-its-own-opt-in-line.md) and [0025](0025-a-whole-run-block-is-computed-from-the-item-ledgers-and-a-run-waits-table.md).

The run-level reading (raw and adjusted run duration, whole-run blocks per kind, with first-pass yield and rework as guardrails) enters the A3 and the baseline **beside** their item rules, never through them. The A3's one experiment stays item-based (`references/a3.md` sections 4–7 are unchanged): run duration is never an experiment's `measure targeted`.

**A3 v4** is v3 plus four lines, directly after `not detectable from records`:

```
- run timing: raw <dur>; adjusted <dur>; blocked: person <dur>, limits <dur>, stalled <dur>, interrupted <dur>
- discipline: <off | on>
- run compared: <earlier runs' medians, this run, signed difference — for raw and adjusted | not comparable (…) | none (<reason>)>
- guardrails: first-pass yield <…>; rework <…>
```

`run compared` compares with the runs of the **same series** whose discipline was `off`; it gives medians with `k of n runs`, this run's values and the signed difference for raw and adjusted duration, and no word for better or worse and no cause.

**The baseline** keeps its marker `v1` (the body is wholly derived and rewritten at each update). Each series block gains a **Runs** section split by `discipline: off` and `discipline: on`. One run is one sample; figures are medians with `k of n runs` (rule R1), read from the `run timing` line of v4 A3s only. The guardrails are read over the items of those runs (R1 and R2), so speed and quality are compared on one footing.

- **Series.** Runs are compared within one series only. A reading from an older series is shown *indicative* under the existing `carry` rule, never as the comparison; across a release the A3 reads `run compared: not comparable (release moved from <M.N> to <M.N>)` with both sides shown. In practice the preview ships first, then one run with the discipline off and one with it on, in that series.
- **Stopped runs.** A run marked `run stopped` has its own `run timing` in its A3, but the Runs section only names it (`not counted: run stopped`) and leaves it out of every median.
- **No backfill.** A3s v1–v3 are not read for runs, and the past runs #280 found are not added.
- **No before-reading.** `obeya-discipline: on` with no `off` run in the current series is not refused: the run start warns once, and the A3 reads `run compared: none (no run with discipline off in series <M.N>)`.

This is one-way: from the first v4 A3 on, every later run is read against these lines and this section.

## Considered options

- **Run duration as an experiment measure** (a row in a3.md section 5): rejected. The before/during/after classes of sections 6 and 7 are per item; stretching them to runs breaks their rules silently.
- **One Runs section with all runs together**: rejected. Without the split by discipline the comparison the destination asks for cannot be read.
- **Compare runs across series**: rejected. It contradicts the series rule every other reading obeys.
- **Guardrails in the A3 only**: rejected. The baseline would show speed without quality.
- **Refuse `obeya-discipline: on` without a before-reading**: rejected. The choice stays with the person; the gap is made visible instead.
- **Baseline marker `v2`**: rejected. *Find baseline* would read every existing baseline issue as not the baseline and ask the person.
- **Count stopped runs** / **backfill old A3s**: rejected. A stopped run is short because it is unfinished, and #280 found the old runs insufficient.
