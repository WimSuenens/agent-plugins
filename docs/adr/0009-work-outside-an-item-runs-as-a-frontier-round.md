---
status: proposed
---

# Work outside an item runs as a frontier round

Clearing the map's one-way doors (step 3 of `/factory:run`) happens before any item exists, so it has no `item/<id>` branch to work on. It runs as a **frontier round** instead: branch `frontier/<map>` in its own worktree, one folder `work/frontier-<ticket>/` per ticket, the same message templates as items, and commits starting `#<ticket> <role>: <what>`. The round ends at the end of step 3: its last commit removes `work/`, and one PR carrying only ADRs and glossary changes is merged to main before step 4 cuts the next item. A card decided later, or doors reopened by a resurvey, start a new round from main. The lead tracks the round in the map's Factory run section only.

An ADR never cites a path under `work/`, in an item or a round, because `work/` never reaches main. It cites the ticket comment that holds the decision card, the decision, or the findings. Research is read by the step-3 subagent itself, without a nested background agent, and its full findings are posted as the ticket's resolution comment; the report in `work/frontier-<ticket>/` is temporary.

Complements [0002](0002-one-branch-and-worktree-per-item.md), which covers work inside an item.

## Considered options

- **Frontier work directly on main.** Rejected. Roles' message files would land on main, and a half-cleared frontier would sit there between commits.
- **One long-lived frontier branch per map.** Rejected. ADRs would stay off main until the map dissolves, while items need them now.
- **Research on its own `research/<name>` branch, or in `docs/research/` on main.** Rejected. The branches had to be bundled and cleaned up by hand, and a report on main duplicates the findings the ticket already holds.

**Provisional** until a frontier round has run end to end on a real project.
