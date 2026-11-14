<!-- factory:ledger v1 -->
## Ledger: #168 Quote two factory skill descriptions so frontmatter parses as strict YAML

- started: 2026-11-12T21:52Z
- start checks: author test: one git identity for all roles; freeze: none; drift: no earlier record for 2.12.2; baseline: #62 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #169 | Contracts and ADRs | architect | aa3c9a2ee31975ef4 | - | 42322 | done | 1 contract, 0 ADRs; product-owner skipped (reason on the ticket) |
| 2 | #171 | Tests | qa-engineer | adfe0fab77391cbb8 | - | 43712 | done | frontmatter check plus 7 version pins made bump-proof |
| 3 | #172 | Build | developer | ab36566fbac117f80 | - | 29436 | done | two line-3 changes; bump check then refused: needs a minor bump (2.13.0), contract said patch |
| 4 | #174 | Build (round 2) | developer | a1fcdadc1cf782449 | - | 26947 | done | version bump to 2.13.0 after the bump-check refusal |
| 5 | #175 | Documentation | docs-writer | abc0911df728d1aee | - | 54850 | done | changelog entry 2.13.0; full suite green |
| 6 | #177 | QA | qa-engineer | a5eb87b4a4cc6beb4 | - | 38541 | pass | no findings; 2 info-level off-list lines |
| 7 | #178 | Security | security-reviewer | af4d81849b5be7a5d | - | 30750 | pass | no findings; run after the skip was withdrawn |


### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-12T22:30Z | 2026-11-12T22:40Z | yes | merge approval on #168 (PR 176) |


### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-12T21:52Z | other | chose the separate-fix route on the question put while building #156 |
| 2026-11-12T22:40Z | approval | yes to merge PR 176 and clean up |


