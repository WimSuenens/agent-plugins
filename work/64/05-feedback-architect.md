# Feedback: architect — 64
Source: lead
Findings:
1. docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md, point 3 — low — it quotes the filter `status:"Waiting on you"`, which names the unused built-in field. Amend to the `factory-status:` token your contract uses, and say in one line why (the built-in `Status` field is not used by the factory).
2. docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md, Targets served line — low — "one comparison, no new tooling" reads against the four scripts your contracts add (paths.sh, factory-config.sh, post-text.sh, board.sh). Amend the wording so it says what it meant (no lock registry, no hook; a script that compares two path lists is the one comparison) and leave the decision itself unchanged. Update the status lines only if the repo's format needs it.
3. Otherwise your decisions are accepted as they stand; no change to the contracts is required unless the wording fix touches one.
Re-verify: grep docs/adr/0015-* for `status:"Waiting on you"`; the Targets line of ADR 0016. Write `work/64/06-result-architect.md` (Status, Summary, Decisions) and commit with subject starting `#64 architect: `.
