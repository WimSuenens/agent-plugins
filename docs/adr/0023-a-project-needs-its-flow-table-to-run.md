---
status: accepted
---

# A project needs its flow table to run

Decided in the grill session of 13 and 14 November 2026, recorded on [#187](https://github.com/WimSuenens/agent-plugins/issues/187#issuecomment-6875271136) (decision 12) and in the one-way-door section of [#207](https://github.com/WimSuenens/agent-plugins/issues/207). The grill session is the decision card. The owner's wording is quoted below; where the record gives no reason, this ADR says so.

## Context

The factory sizes each destination and each slice with a points table: eight triggers, each adding steps and points, and the path is the sum of the triggers that fire. The record puts the principle as: "The lead sizes each destination and each slice with a points table, takes the lightest path that keeps the floor, and the factory learns from the gap between estimated and actual points." (owner, #187 comment). The table is its own section in the project's `docs/agents/factory.md`; setup scans the project and writes it with a reason per row, every row `provisional`, and the person confirms it once.

The question this ADR settles is what `/factory:run` does in a project that has no table. A project set up before 3.0.0 is such a project: its `factory.md` has `factory-state: 2` and nothing else of the table.

## Options considered

- **Refuse a run without the table**: chosen. `factory-config.sh state` exits with a new code (6) and says "run setup-factory-skill"; nothing else in the run skill starts. The record states it as: "a project without the table can no longer run" `(owner)`. The record gives no reason for refusing over the other two options. Reasons the architect gives: the lead can only size against a table that the person has seen and confirmed, and a table seeded silently would be the lead's own guess standing in for the person's confirmation `(architect)`; a refusal is also the only option under which a project's first run of a new release cannot proceed on a path nobody sized `(architect)`.
- **Warn and auto-seed**: rejected. A run without the table would print a warning, write the initial table by itself and go on. The person gave no reason for rejecting it. Reasons the architect gives: it removes the one confirmation the design asks for, so the table would stand as `provisional` without anyone having confirmed a row `(architect)`; and a run that writes a project's `factory.md` at its start changes a file the person owns, before any question `(architect)`.
- **Leave as is**: rejected. A project without the table keeps running on the old fixed path, and the table applies only where it exists. The person gave no reason for rejecting it. Reasons the architect gives: two flows would live side by side for good, so every later slice (sizing, the plan on the ticket, role path, test depth) would carry a branch for "no table" `(architect)`; and the measures of the revision plan compare slices by band, which a project without a table cannot give `(architect)`.

## Decision

Option **Refuse a run without the table** `(owner)`.

- `factory-config.sh state` also requires the table: a `## Flow table` section with a `floor:` line and at least eight trigger rows. A project without it exits 6 and prints "factory.md has no flow table: run setup-factory-skill". Exits 3, 4 and 5 keep their meaning. `factory-config.sh table` reads the section.
- `setup-factory-skill` scans the project, shows the table once, asks one question, and on a clear yes appends the section; a re-run on a 2.x project appends it and changes no other line.
- The release that adds the gate is **3.0.0**, a major release, and only that release: "Release 3.0.0 belongs to that slice only; all other slices stay 2.x." `(owner)`
- The floor is not part of what the table can remove, and fence F1 is not loosened: "Fence F1 is not loosened (auto-merge of a frontier PR was not chosen)." `(owner)` This slice does not edit the fence.

## Consequences

- Every project that uses the factory must run `setup-factory-skill` once after upgrading to 3.0.0 before `/factory:run` starts. A project that does not sees the refusal and the sentence that names the fix.
- The `ci:` line and the table are written by the same setup step, so a project set up on 3.0.0 has both.
- The merge-gate and the later slices can assume the table exists.
- The baseline starts a new series at 3.0, as a new minor does.

## Way back

Going back to "warn and auto-seed" or to "leave as is" changes the `state` check back to exit 0 for a project without the table, and removes the sentence from the run skill. That is a release (a minor, or a major if projects came to rely on the refusal), and the projects that already have a table keep it. Because this ADR is a one-way door the person decided, reversing it needs a decision card to the person, not the lead's judgement.

## Non-functional targets served

Predictability (a run never starts on an unsized path), and honesty about maturity (every row stays `provisional` until the person's confirmation and enough slices say otherwise).
