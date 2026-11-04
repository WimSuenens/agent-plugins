# Brief: architect — 39
Goal: Define the contracts for slice #39: the hansei record's format, the stage log's format, the fingerprint computation, the bump check, and where each lives in the standard.
Inputs: slice #39 (`gh issue view 39`); requirement `docs/requirements/39-hansei-record.md`; product-owner result `work/39/02-result-product-owner.md` (its Decisions and Open questions); `docs/adr/0011-*.md`, `docs/adr/0012-*.md`; #35 findings (`gh issue view 35 --comments`); the plugin under `plugins/factory/`; `docs/agents/issue-tracker.md`; `CONTEXT.md`.
Constraints:
- Settle the product-owner's architect questions: how the record tells a `hooks/`/`scripts/` change apart from a standard-work change (and so whether it resets the baseline, per ADR 0012 "Left to the slice"); where the fingerprint computation lives; the record's exact layout and marker (with schema version); where the post/edit hansei tracker commands live, including for projects set up before 1.0.0 (setup-factory-skill and/or a fallback in run/SKILL.md).
- Lead decision (two-way): the Lead creates the `factory-v1.0.0` tag as part of *Merge PR*. Reflect it in the contract.
- Contracts go in `contracts/` (your path). Any ADR only for a one-way door; two-way choices go in your result's Decisions.
- Add *Hansei record* and *Stage log* to `CONTEXT.md`.
- Name the shared resources the item needs (expect: none beyond a scratch project/tracker for the demo — say so).
Output: `contracts/39-*.md`, `CONTEXT.md` edit; result `work/39/04-result-architect.md`. Commit: `#39 architect: contracts for the hansei record`.
Done: your role's Done list.
