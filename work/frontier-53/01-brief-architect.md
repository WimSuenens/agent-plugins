# Brief: architect — frontier-53 (covers #53, #54, #55 for map #50)
Goal: Give the lead two or three options and a leaning for each of the three one-way doors of map #50, so one decision card can carry all three. Place: frontier round, worktree `../wt/frontier-50`, branch `frontier/50`, messages in `work/frontier-53/`.
Inputs:
- Tracker: #50 (map: Destination, Notes, Decisions so far, Deferred), #53, #54, #55 (the three doors), the research comments cited in #50's Decisions (#51 limits, #52 `gh project` capabilities; read the linked comments).
- Files: `docs/adr/0001-*`, `0002-*`, `0006-*`, `0007-*`, `0009-*`, `0012-*`, `CONTEXT.md`, `docs/agents/factory.md`, `docs/agents/issue-tracker.md` (`## Factory operations`), `plugins/factory/references/protocol.md`.
Constraints:
- Three doors: (A) #53 role tasks are sub-issues that hold the message record (partly replaces ADR 0001); (B) #54 the board is the only status a person reads (amends ADR 0002; includes the 2.0.0 migration); (C) #55 slices run in parallel when contract path lists do not overlap (amends ADRs 0006, 0007; touches the wayfinding plugin).
- The map's Decisions so far are `[provisional]`, seeded from a grilling session; treat them as your leaning, not as settled. Offer genuine alternatives where they exist (for example for A: sub-issue vs comments on the slice ticket vs files kept; for B: one status list vs a status list plus stage field; for C: path-list overlap vs file-level locks vs no parallelism).
- Settled by the person on 2026-11-07 and not up for options: the whole map is one slice released as 2.0.0; the run keeps the old state mechanism until it closes; migration is a `setup-factory-skill` step, status mapping Designed→Ready, In progress and In review→Running, Ready to deploy→Waiting on you; no acceptance demo.
- Per door: two or three options; for each the undo cost in concrete work (days or weeks), what depends on what; say which of the three doors depend on one another and what an overturn of one does to the others.
- Decision-maker is `technical`: include the technical mechanism after the consequences.
- Write no ADR and no contract yet; the ADR follows the person's choice. No tracker writes. No absolute path under the home directory in any file.
Output: `work/frontier-53/02-options-architect.md` (options, leaning, dependencies) and a result `work/frontier-53/02-result-architect.md`. Commit your own paths, subject starting `#53 architect: `.
Done: options file covers all three doors with undo costs and leaning; dependencies between doors stated; result written with Status and Decisions.
