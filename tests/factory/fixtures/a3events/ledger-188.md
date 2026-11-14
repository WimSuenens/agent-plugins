<!-- factory:ledger v1 -->
## Ledger: #188 Wiki shell: navigation tree, contents and the first hand-written page, in English and Dutch

- started: 2026-11-12T23:20Z
- start checks: author test: one git identity for all roles; freeze: none; drift: same as #156; baseline: #62 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #189 | Requirement | product-owner | ac63813ee50fd3e91 | - | not captured (completion notice not read at row time) | done | 28 criteria, 6 two-way decisions, 0 cards, 1 open question for the owner |
| 2 | #190 | Contracts and ADRs | architect | a400875aa8b552d55 | - | 87000 | done | 3 contracts, 0 ADRs, 4 questions answered; glossary and AC-25 follow-ups sent |
| 3 | #191 | Tests | qa-engineer | a5441dbb68a9a470a | - | not captured (completion notice not read at row time) | done | tests for AC-1 to AC-27 and updated skeleton tests; 1 contract conflict question to the architect |
| 4 | #197 | Contracts and ADRs (round 2) | architect | a098be2553f28963b | - | not captured (completion notice not read at row time) | done | site-nav-empty exempts the breadcrumb nav (option A) |
| 5 | #198 | Build | developer | a8ee83db71d4c8503 | - | not captured (completion notice not read at row time) | done | targeted test 35/35; 1 question (AC-19 helper) |
| 6 | #199 | Tests (round 2) | qa-engineer | a2502da0072bac977 | - | not captured (completion notice not read at row time) | done | AC-19 helper accepts marketplace plugins |
| 7 | #200 | Contracts and ADRs (round 3) | architect | aaf149e09f6add7b6 | - | not captured (completion notice not read at row time) | done | contracts match the Satteri build; two path additions |
| 8 | #201 | Build (round 2) | developer | abad7d05d0a936dba | - | not captured (completion notice not read at row time) | done | declared dependency, deleted url.mjs |
| 9 | #203 | QA | qa-engineer | a8f5a95f6630d0620 | - | not captured (completion notice not read at row time) | done | verdict pass; 177 of 178, 1 skipped |
| 10 | #204 | Security review | security-reviewer | a0b72f55116262baa | - | not captured (completion notice not read at row time) | done | verdict pass; 1 low note |
| 11 | #205 | Documentation | docs-writer | a2531a6758bb6eb46 | - | not captured (completion notice not read at row time) | done | README section rewritten |


### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-12T23:48Z | 2026-11-13T22:17Z | yes | the owner stopped the run after the Tests stage; resumed with /factory:run |
| W2 | person | - | 2026-11-13T22:47Z | 2026-11-13T22:51Z | yes | acceptance demo put to the owner |
| W3 | person | - | 2026-11-13T22:52Z | 2026-11-13T22:54Z | yes | merge approval asked |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-12T23:20Z | other | chose the wiki shell with the first real page as the next slice |
| 2026-11-12T23:48Z | other | stopped the factory after the Tests stage |
| 2026-11-13T22:51Z | demo | tried the pages on the local build; all steps good |
| 2026-11-13T22:54Z | approval | merge and clean up: yes; close the run afterwards |

