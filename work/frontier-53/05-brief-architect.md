# Brief: architect — frontier-53 (ADRs for #53, #54, #55 of map #50)
Goal: Write the three ADRs for the decisions the person made on the decision card, in the frontier worktree.
Inputs: tracker #50, #53, #54, #55; the decision comments on #53, #54, #55 and the card they link (cite that card comment, never a path under `work/`); `work/frontier-53/02-options-architect.md` and `02-result-architect.md` (your own); `docs/adr/` (next free numbers 0014, 0015, 0016); `CONTEXT.md`.
Constraints:
- Decisions: A1 (#53) one sub-issue per role task, brief = body, result = closing comment; B1 (#54) six-value `Factory status` plus `Kind` and `Role`, migration in three phases; C1 (#55) parallel slices on non-overlapping path lists, limit setting `parallel-limit` in `docs/agents/factory.md`, default 2 at release (the Destination's default; the person did not choose 1).
- ADR 0014 for A (partly replaces ADR 0001), 0015 for B (amends ADR 0002), 0016 for C (amends ADR 0007; touches the wayfinding plugin's beachhead and resurvey text). Update the status line of each amended ADR as the repo's ADR format does. Cite the decision comments and the research comments (#51, #52).
- Record the two-way decisions from your options result that these ADRs rely on (frontier role tasks under the frontier ticket, three-phase migration, `factory-state: 2`, shared paths always overlapping, committed draft result in `work/`) as consequences, labelled two-way.
- Add to `CONTEXT.md` only the terms that crystallise (role task, Factory status, Needs you view, path list); owner is you.
- Note in each ADR that undoing A or B after 2.0.0 is itself a 3.0.0 release.
- No contracts yet (they belong to the slice). No tracker writes. No absolute path under the home directory in any file.
Output: `docs/adr/0014-*.md`, `0015-*.md`, `0016-*.md`, edits to ADR 0001, 0002, 0007 status lines, `CONTEXT.md` terms; result `work/frontier-53/05-result-architect.md`. Commit your own paths, subject starting `#53 architect: `.
Done: three ADRs written and cited; amended ADRs marked; terms added; result written with Status and Decisions.
