Skipping product-owner: a one-line quoting of two skill descriptions with a fully specified behaviour; the slice frame states it, no requirement choices remain. QA is not skipped.


-----
Contracts and ADRs: one contract (quote the two descriptions, strict-YAML frontmatter check, factory patch release 2.12.3). No ADR. Fix is double-quoting the two description values; no overlap with the site slice in flight.
code review: no — trigger: no trigger
promote chosen, still in force: none
Decisions: double-quote style (block scalar, rewording and a tolerant generator rejected); parser choice for the check left to QA. Tests that pin 2.12.2 are QA's to update in this slice; the version bump waits until they are green.


-----
Tests: tests/factory/test_skill_frontmatter.sh parses every SKILL.md with Ruby Psych and fails now for the right reason (the two files); seven version-pinned tests now read the version so they survive the 2.12.3 bump, except one changelog-fingerprint row that waits for the bump entry.
promote chosen, still in force: none
Decisions: Ruby Psych is the parser (stock on macOS); the pre-slice descriptions live in fixtures; the pins check semver shape rather than a fixed version. Contract says 20 SKILL.md files, the repo has 18 (the test uses the glob count).


-----
Build: both descriptions double-quoted on line 3 (only those two lines changed); the frontmatter test passes with 18 files, and the full suite is green except the changelog-fingerprint row waiting for the release entry. breadth: as expected.
Open PR check refused: the SKILL.md changes are standard work, so the release is a minor bump, 2.13.0, not the patch 2.12.3 the contract named. The contract is being corrected; the developer will bump plugin.json and the docs-writer will write the changelog entry in this slice. Security review skipped (two one-line quotings and tests; no code, secrets, auth or data), reason recorded here.
promote chosen, still in force: none


-----
Security review: the earlier skip is withdrawn. The merge gate refuses a skipped security review for this slice (the diff carries a contract file), so the security-reviewer runs.
QA verdict: pass, no findings, no human-only criteria; two info-level off-list lines (the architect's own contract and the docs-writer's role-knowledge note).
promote chosen, still in force: none


-----
<!-- factory:needs-you v1 -->
Asked: 2026-11-12T22:30Z
Cause: merge approval
Ask: Merge PR 176 (factory 2.13.0: two skill descriptions quoted so every skill file parses as strict YAML) and clean up? QA and security both pass with no findings and the full test suite passes. The merge gate pauses because the change includes a contract, and it reports no CI checks on this branch (the repo has no workflow that runs the factory tests), so the passing test runs are the local ones in the PR description.
Options: yes or no
After you answer: it merges, factory 2.13.0 is tagged, and the documentation-site slice is rebuilt on top of it.


Answered: 2026-11-12T22:40:50Z


-----
Resolved: merged in PR 176 as factory 2.13.0 (tag factory-v2.13.0). Every SKILL.md frontmatter now parses as strict YAML (18 of 18); the two fixed descriptions read the same as before.

What the build taught: the research on the generator's inputs (#149) called the frontmatter single-line YAML, but two descriptions were not strictly valid, and only the site build, which parses every skill file with a real YAML parser, found it. Quoting standard text is itself a minor factory release under the bump rule, so a one-line fix cost a minor version, a changelog entry and a security review (a contract in the diff keeps the merge gate from skipping it). The repo has no CI that runs the factory tests, so the merge rested on the local test runs recorded in the PR.


-----
