---
status: proposed
---

# A run is a cycle over a standing backlog, with no slice maximum

Amends [0007](0007-factory-owns-destination-and-slicing.md) (a run takes one destination to a dissolved map; one thin slice at a time) and [0016](0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md) (the `parallel-limit` setting and its default of 2).

Issue [#111](https://github.com/WimSuenens/agent-plugins/issues/111), under [#108](https://github.com/WimSuenens/agent-plugins/issues/108), asked for the run to become a cycle. The idea inbox of [#110](https://github.com/WimSuenens/agent-plugins/issues/110) keeps feeding a map, so a map is a long-lived direction, not a destination that ends.

## Decision

1. **A map is long-lived.** It is not dissolved when its backlog empties; it waits for new ideas, which refine its Destination and Decisions so far.
2. **A run is one cycle over the standing backlog.** It starts by processing intake, then maintenance, improvement and slice building (every mechanism restarts), and ends when the backlog is empty, the per-run budget is reached, or the person stops it. It closes with the existing improvement record (A3 and baseline).
3. **No slice maximum.** `parallel-limit` is removed. Slices run side by side whenever their path lists do not overlap (the overlap rule of 0016 stands); overlapping ones wait as `Ready`. The "one thin slice" rule is removed with it.
4. **The only brake is an optional per-run budget**, `run-budget: <N> tokens|hours` in `docs/agents/factory.md` (`none` by default). When it is reached no new slice or role starts; work in flight finishes the step in hand and stays resumable from its lead state, and the run closes cleanly.
5. **An old `parallel-limit` line is ignored** with a note, and removed by setup.

## Considered options

- **Keep a limit as an optional setting.** Rejected. The path-list rule already prevents conflicts; a count adds a second brake that the budget does that job for.
- **Budget as a slice count.** Rejected. Slices differ in size; tokens and hours measure the cost.

## Consequences

- Undo cost: re-adding a limit is a few lines in `factory-config.sh` and the start gate (under a day, a minor release). Two-way door.
- The A3 and baseline are read per run as before; a run is now a cycle, not a map's whole life, so a map has many runs.
- Parallel running stays unverified on a real project ([0016](0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md)), and now has no count brake: the budget and the person's stop are the brakes.
