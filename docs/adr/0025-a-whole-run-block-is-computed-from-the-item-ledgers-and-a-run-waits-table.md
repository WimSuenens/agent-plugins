---
status: accepted
---

# A whole-run block is computed from the item ledgers and a Run waits table

Decided on [Obeya discipline: where and how a whole-run block is recorded](https://github.com/WimSuenens/agent-plugins/issues/281), part of [Map: the Obeya discipline for the factory](https://github.com/WimSuenens/agent-plugins/issues/278); builds on [0024](0024-the-obeya-discipline-has-its-own-opt-in-line.md).

A **whole-run block** is a minute in which the whole run stands still: every item in flight is in a held wait (`Held item: yes`), or no item is in flight and the run itself waits. Four kinds count, each reported separately: `person`, `limits`, `stalled`, `interrupted`. An `andon` pause is not a block, because stopping to fix the process is the factory's own work; nor is the Lead's work between items. Overlapping kinds count once, to the first in measure 1's order (person, limits, stalled, interrupted), so run and item readings add up the same way.

Waits that belong to no item go in a **Run waits** table in the map's Factory run section: `#` (`R1`, `R2` …), Kind, Agent, Start, End, What, written when the wait ends. A `person` row runs from the moment the Lead puts the question (which slice next, close the run now) to the moment it reads the answer; `limits`, `stalled` and `interrupted` rows are found at run close by `cut-offs.sh` over the Lead's own transcript, as the item close scan does. Waits inside an item stay in its ledger only. The table has no `Held item` column: whether a wait blocked the run is computed, never stored.

At run close the Lead computes, from the item ledgers and the Run waits table, raw run duration (the A3 comment's `created_at` − the section's `started:`) and adjusted run duration (raw − blocked minutes). They appear as one A3 line (total; adjusted; blocks per kind) and go to the baseline with sample counts. `started:` must be written on every path into a run, a resumed or reopened section included.

The shape is one-way: from the first reading on, every later run is compared with it.

## Considered options

- **Only person and limit blocks** (the map's first wording): rejected. A sleeping session or a stall holds the run just as much; reporting all four apart keeps the reading honest and lets a reader drop the ones they doubt.
- **Count the andon as a fifth kind**: rejected. The run is not idle while the Lead fixes the process; subtracting it would make runs look faster than they were.
- **One run-level list holding every wait, item waits included**: rejected. It stores the item waits twice, against the standing rule of no duplicate records.
- **Derive blocks from the item ledgers alone**: rejected. It misses the waits between items, the gap #280 found.
- **A minute is blocked when any item waits**: rejected. With items in parallel it counts time in which another item moved.
- **Close the run at the `- A3:` line or at the person's "close the run" answer**: rejected. The A3 comment's `created_at` is stamped by GitHub, cannot be edited, and is how #280 read past runs, so old and new readings share one clock.
