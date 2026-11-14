<!-- factory:ledger v1 -->
## Ledger: #156 Live skeleton: bilingual home and generated skills index on GitHub Pages

- started: 2026-11-12T21:14Z
- start checks: author test: one git identity for all roles; freeze: none; drift: no earlier record for 2.12.2; baseline: #62 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #157 | Requirement | product-owner | ad120addea8bae9fe | - | 45417 | done | 27 criteria, 6 two-way decisions, 0 cards |
| 2 | #161 | Contracts and ADRs | architect | ab1cf6a53ce519aff | - | 80640 | done | 4 contracts, 0 ADRs, 2 questions answered, paths parse defect sent back |
| 3 | #163 | Tests | qa-engineer | abd8d90e7b0e2a198 | - | 93845 | done | tests for AC-1 to AC-26; AC-27 and H-1 to H-4 not scripted |
| 4 | #165 | Build | developer | a17d7ce44dd7f8612 | - | 94594 | needs-decision | Astro 7.4.11; 2 questions (invalid YAML in 2 plugin files to the owner; parallel test files to QA, fixed by a build lock) |
| 5 | #170 | Environment | devops | aa122b25eea6f0925 | - | 30224 | done | workflow site.yml; 6 of 7 workflow tests pass, 1 test threshold for QA, actionlint not installed |
| 6 | #180 | Build (round 2) | developer | a5aea270dcae8a60b | - | 31442 | done | page headings separated from document titles; found by the owner viewing the site |
| 7 | #183 | Documentation | docs-writer | a06a8cda494c7bab0 | - | 89259 | done | README section Documentation site; every command run before it was written |
| 8 | #184 | QA | qa-engineer | a5b94d0f0f773c152 | - | 42642 | pass | 2 low findings (actionlint not run, first deploy unproven); human-only criteria H-1 to H-4 listed |
| 9 | #185 | Security | security-reviewer | a3c7517a6a7cdd6c8 | - | 33771 | pass | no findings above info; 2 info notes |


### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-12T23:02Z | 2026-11-12T23:06Z | yes | acceptance demo on #156: look, Dutch, no flash, screen reader |
| W2 | person | - | 2026-11-12T23:06Z | 2026-11-12T23:08Z | yes | merge approval on #156 (PR 182) |


### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-12T21:51Z | other | owner chose a separate fix item first for the invalid YAML in two factory skill files |
| 2026-11-12T23:06Z | demo | passed the four human-only checks (look, Dutch, no flash, VoiceOver) |
| 2026-11-12T23:08Z | approval | yes to merge PR 182 and clean up |

