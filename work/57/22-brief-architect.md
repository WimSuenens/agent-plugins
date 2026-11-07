# Brief: architect — 57 (feedback round 2: contract text before code)

Goal: Settle the contract text for QA's round 2 findings and observations, so the developer's second fix round builds from text.

Inputs: `reviews/qa-57.md` ("Round 2": R2-1 to R2-3, observations R2-O1 to R2-O5), `reviews/security-57.md` (round 2: S4), your contracts `contracts/57-*.md`, the plugin text at b3310d7.

Findings:
1. R2-1 / S4 (medium, same defect found by QA and security): *Find baseline* must be null-safe: an empty or missing body reads `no-marker`, and a *Find baseline* that exits non-zero means "lookup failed: change nothing and tell the person", never "none found". Fix `contracts/57-baseline.md` §2: add the expected output row for an empty or missing body, the null-safe form (QA suggests `((.body // "") | split("\n")[0] // "" | test(...))`), and the failed-lookup rule.
2. R2-3 (low): `57-baseline.md` §1 names "the calibration line" as a place a reason is code-spanned, but that line holds only the record's `plugin:` free text. Say which is true and fix the clause.
3. R2-O1 to R2-O3 bind a rule. Write them: one code span per reason (R2-O1); `not captured (unreadable <key> line)` written per field with the line's key (R2-O2); a v4 record whose `active overrides` line is outside the extent grammar is skipped whole and named (R2-O3). Accept the reader's `# READING:` choices, or say why not.
4. R2-2 (low, developer's text): the *Create baseline* literal "Run only after *Find baseline* printed nothing" contradicts the `no-marker` exception in the same bullet; state in `57-baseline.md` (or the standard-changes contract) the one wording the bullet must carry.
5. R2-O4 is the requirement's wording (AC-14); the product-owner amends it, not you.

Constraints: write only `contracts/`, `docs/adr/`, `CONTEXT.md`; no one-way door expected; keep the fence, the honesty rule, no home path. In your result list the fixtures and expected values that move (QA already holds the empty-body fixture and the reader readings above; say which expectations must change, if any). Commit subjects `#57 architect: `. Result: `work/57/24-result-architect.md` (start with `Status: working`).

Done: each of items 1 to 4 has a clause the developer can build from, named by file and section; list of moved fixtures; two-way decisions with chosen / rejected / cost to undo.
