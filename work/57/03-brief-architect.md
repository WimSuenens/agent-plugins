# Brief: architect — 57

Goal: Write the contracts for slice #57 (per-run A3 and baseline issue) so the developer can build from text alone: the exact rules, formats and places the requirement leaves to the architect, and record any decided one-way door as an ADR.

Inputs:
- `docs/requirements/57-per-run-a3-and-baseline.md` (31 acceptance criteria; read its "Open questions" and the ten Decisions in `work/57/02-result-product-owner.md`).
- Slice ticket #57 and map #34 (Decisions so far, Deferred, Notes: "Two-way decisions left to the roles inside slices").
- ADRs 0011, 0012, 0013; `CONTEXT.md`; existing contracts `contracts/39-*.md` and `contracts/49-*.md` for the style and for what they already fix (hansei v3, overrides, the abnormality list).
- Standard work as it stands: `plugins/factory/skills/run/SKILL.md` (steps 8 to 10, Andon, Settle round), `plugins/factory/references/hansei.md`, `plugins/factory/references/protocol.md`, `docs/agents/factory.md`.
- Data the rules are checked on: the hansei records on factory-sandbox #5 (v3, release 1.1.0) and #2 (v1), which the product-owner found are the only marker-bearing records; the comments on agent-plugins #39 and #49 are manual, not records. QA replays the rules on them plus the field-edited control copies the requirement names.

Constraints:
- Contract text before code: write the rules so QA can run each on the replay data and get the expected values the requirement states (AC-3 holds the expected values for sandbox #5).
- Decide the architect's list from the product-owner's report: baseline issue form (and pinning, with its failure case); A3 marker, template and where it is posted; where the baseline's tracker commands live (if outside the paths the requirement allows, name the exception for AC-26); where the run-close actions sit in `skills/run/SKILL.md`; what a record carries to tell an override in force for a whole item from one in force for part of it (a possible `hansei v4`, with its schema version and the older versions still read); the override's link to the A3 when no andon started it; how long after-items are counted (one run only); whether a `hooks/` or `scripts/` change resets the baseline (only if a script is added, ADR 0012 "Left to the slice"); the exact text of the rules for AC-3, AC-5, AC-11, AC-14, AC-15.
- Keep the fence of ADR 0011; the honesty rule (not captured, never 0); no project data in agent-plugins; no absolute home path in any file you write (`~/` or worktree-relative only).
- Add the Lean terms the slice introduces (baseline, A3, countermeasure experiment, series) to `CONTEXT.md`, only as they crystallise, each with the honesty-rule line.
- A one-way door found is `needs-decision` with options and a leaning, not an ADR by assumption. A change that needs more than one minor release step (for example a new major) goes back as a question.
- You write only contracts/, docs/adr/, CONTEXT.md. You do not edit plugins/ (the developer's), tests/ or the requirement.
- The release number and who tags it: the standard change bumps the factory's plugin version (minor, `1.2.0`) in `plugins/factory/.claude-plugin/plugin.json`, which is the developer's edit; the tag is made by the Lead at merge by *Merge PR*. Say so in the contract.

Output: `contracts/57-*.md` (as many files as the seams need, same style as 39 and 49), ADR(s) only when a one-way door was decided, updated `CONTEXT.md`; your result `work/57/04-result-architect.md` (start it with `Status: working`).

Done:
- Every item of the architect's list above has an answer in a contract, with the exact rule text for AC-3, 5, 11, 14, 15.
- Every acceptance criterion maps to a contract clause or says why it needs none.
- The paths the developer may change are listed per contract, and the standard-change contract says what it bumps and how it moves the fingerprint.
- Two-way decisions listed in Decisions with chosen / rejected / cost to undo.
