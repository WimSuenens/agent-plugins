---
status: proposed
---

# The factory owns the destination and the slicing; wayfinding charts the route

Supersedes [0006](0006-factory-builds-wayfinder-slices.md).

`/factory:run` starts from an idea, not from a slice. The lead first grills the person, via `/grill-with-docs`, about *what* the destination is, and writes the answer into the map's Destination in a fixed shape: What, For whom, Done when (three to five observable outcomes), Not. `/wayfinding:wayfinder` then charts *how* to get there, taking that destination as given and skipping its own naming step. From there the lead owns the whole run: it cuts each slice with `/wayfinding:beachhead`, builds it as one item, resurveys, and moves on to the next slice without waiting, until the map dissolves. It stops only when the destination moves or a `[locked]` decision is contradicted. Slices run one at a time, because each resurvey shapes the next cut.

The run's state lives in a "Factory run" section at the top of the map issue, so `/factory:run #<map>` resumes it. Item state stays in `work/<id>/`.

The map's one-way-door tickets reach the person through the same channel as one-way doors found during a build. Research runs AFK. A prototype is built AFK by the developer on a throwaway branch and linked from the card, but the person decides. A grilling ticket becomes a decision card that defaults to `/grilling`. A task ticket is manual work, not a decision, so it becomes a task request to the person. While a card or task is open, the run continues with whatever it does not block.

## Considered options

- **Keep 0006: the factory builds slices that wayfinding cuts.** Rejected. The person had to clarify the effort inside wayfinding's map-scale grilling, and a run entered with `#slice` skipped clarification altogether.
- **One slice per `/factory:run` invocation.** Rejected. The person would have to restart the factory after every merge, and the slicing would sit outside it again.
- **Parallel slices.** Rejected for now. A slice cut before the previous resurvey is cut on stale knowledge.

## Consequences

`/factory:run` no longer accepts a slice made outside the factory; standalone wayfinding still serves anyone who wants that. Wayfinder's "Name the destination" step grills only when no destination is passed in.
