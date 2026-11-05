# Brief: qa-engineer — 49
Goal: Verify the #49 build against AC-1..AC-30, replace the 17 tests the contract supersedes, and give the release verdict with the Human-only criteria list.
Inputs: docs/requirements/49-andon.md; contracts/49-*.md and 39-*.md; work/49/06-result-developer.md (the 17 failing #39 tests are listed there); plugins/factory/ on this branch; tests/; tracker issue #39 and its comments (the data that showed the defect: its five "same finding twice" abnormalities)
Constraints:
- The 17 failing tests pin literals the contract supersedes (1.0.0, four wait kinds, v2 marker, old measure 1, old example): update them to the 1.1.0 contract; do not weaken a test to pass.
- AC-3: run the written "same finding twice" rule yourself on #39's five abnormalities and at least five control pairs chosen BEFORE you apply the rule; record the replay table per contracts/49-abnormality-list.md section 4.5. If the rule fails, file it as a defect with reproduction; do not fix plugin text (developer's).
- Fixtures per the requirement (e.g. the seven adversarial overrides for the fence, 2x-test cases); apply the standard text step by step as the requirement defines.
- AC-29: quote the final fingerprints (run the repo's fingerprint script on this branch; the developer reports standard e61c7913..., tooling 295033f4...).
- List Human-only and post-merge criteria. The sandbox for human-only checks is WimSuenens/factory-sandbox, Project #10. Nothing from it lands in this repo.
- Do not run /plugin marketplace update or /reload-plugins. No absolute home paths in tests/ or reviews/.
Output: tests/ (yours), reviews/qa-49.md, result in work/49/08-result-qa-engineer.md
Done: every criterion maps to a test; every defect has a reproduction; verdict recorded with Human-only criteria list; tests/run.sh exits 0 or the reasons are defects.
