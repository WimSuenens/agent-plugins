# Brief: product-owner — 57 (requirement amendment)

Goal: Align the requirement with the contracts so that QA, who derives tests from the acceptance criteria, and the developer, who builds from the contracts, read the same rule. This is a text fix before any code.

Inputs:
- `docs/requirements/57-per-run-a3-and-baseline.md` (your own).
- `work/57/04-result-architect.md` and `contracts/57-*.md`, especially `contracts/57-standard-changes.md` §8 ("for the requirement's owner") and §3 (the AC-26 exception).

Constraints:
- Change only the criteria the architect listed: AC-3 (doors counted per Under test line; the `not captured <m> (<m> of <n> items: …)` spelling for the demo case), AC-7 (the records-read note goes in the map's Factory run section, not the stage log, which is removed at step 8.6), AC-11, AC-12, AC-13, AC-16, AC-20 ("first line" means the first field line; `experiment: none (…)` is the A3's `countermeasure:` line; "pick none" is a silent none and the rule ends in `none chosen (<reason>)`; the A3 has two lines beyond AC-16's list, `other overrides` and `baseline`), and AC-26 (name the one path outside the listed ones, `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`, with its reason).
- Where you agree with the architect's reading, adopt it. Where you do not, say so in your result as a `needs-decision`-free question to the Lead and keep your wording; do not argue by rewriting the contract (not your path).
- Keep every other criterion as it is. Keep the Under test table and the demo script consistent with the changes.
- No absolute home path in any file.

Output: the amended `docs/requirements/57-per-run-a3-and-baseline.md` (commit `#57 product-owner: ...`), and `work/57/06-result-product-owner.md` (start with `Status: working`), listing each criterion you changed in one line.

Done:
- Each criterion named above is aligned with the contracts or the disagreement is stated.
- The AC-26 exception is named in the criterion.
- No other criterion changed (list any you had to touch for consistency).
