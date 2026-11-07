# Brief: qa-engineer — 57

Goal: Verify slice #57 against its acceptance criteria and give a verdict. Derive tests from the criteria, update the pins of the old wording, replay the baseline and A3 rules, and list the human-only criteria for the acceptance demo.

Inputs:
- `docs/requirements/57-per-run-a3-and-baseline.md` (amended, 8c9bb79) and `contracts/57-*.md` (the rules the criteria test).
- The change on PR #58 / branch `item/57`: `plugins/factory/` (new `references/baseline.md`, `references/a3.md`; changed `skills/run/SKILL.md`, `references/hansei.md`, `references/protocol.md`, the tracker template, `plugin.json` 1.2.0), and `work/57/08-result-developer.md`.
- Existing tests: `tests/run.sh`, `tests/factory/`. Three test files fail because they pin the old wording: `test_andon_text`, `test_fingerprint`, `test_standard_text` (version 1.1.0; the hansei v3 marker and old `active overrides` line; old step 9 and 10 text and settle line; the old override and plugin-change sentences). Update those pins to the new standard. Do not weaken a check: each pin you change must state why the new text still protects the same thing.
- `reviews/qa-39.md` and `reviews/qa-49.md` for the verdict format.

Constraints:
- The validation data (AC-2, AC-3 and the other replay criteria): the replay runs the rules on the records S2, S5 and the comments C39, C49 named in the requirement, plus the controls S5b–S5f and C39t. **Write the expected result of each control before the replay** (the requirement says so) and record the table rule / input / expected / found in the verdict. The architect fixed each rule's text; run the rule as written.
- **No sandbox or project content in this repository.** Fixtures in `tests/` are synthetic: invented values in the record shape, no text, URLs, names, counts or tokens copied from the sandbox records. When you replay on the real records S2 and S5, read them with `gh` into a scratch file outside the repo (`mktemp`), report only the table of rule / expected / found and pass or fail in the verdict, and remove the scratch file. Quote nothing from the records.
- Honesty rule: a measure not captured reads `not captured`, never 0. Check it in the rules and in the tests.
- State the tooling fingerprint did not move (`bash plugins/factory/scripts/fingerprint.sh plugins/factory`, compare with 1.1.0 via a worktree of tag `factory-v1.1.0`); the architect's contract says so and the verdict records it.
- List the path outside AC-26's list (the setup skill's tracker template) as the exception for the person to see.
- The person does not need to be bothered for what a test can check. Criteria only a person can judge in a real session go to the **Human-only criteria** list of your verdict; the demo uses a separate session on the sandbox; do not run it.
- You write only `tests/` and `reviews/qa-*`. Findings go in the verdict with file, severity and required fix, for the developer. A residual of a finding is a finding. No absolute home path in any file.
- Commit subjects start `#57 qa-engineer: `.

Output: updated and new tests in `tests/factory/`; `reviews/qa-57.md` (verdict `pass` or `findings`, per-criterion table, the replay table, Human-only criteria, the AC-26 exception, fingerprint result); `work/57/10-result-qa-engineer.md` (start with `Status: working`).

Done:
- `bash tests/run.sh` result stated, with every failing check named and its cause.
- Every criterion has a result: pass, finding, human-only, or post-merge.
- The replay table is complete and written before the replay for the controls.
- A verdict line: `pass` only when nothing but human-only and post-merge criteria is open.
