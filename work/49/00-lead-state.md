# Lead state: #49 Andon

- **Board item id:** PVTI_lAHOBIbaa84BqOBFzhGaUn0
- **Status:** Ready to deploy (QA pass, security pass after round 2)
- **Map:** #34 (Lean factory run), run step 5 done; next is step 6
- **Branch / worktree:** `item/49` at `../wt/49`
- **Next step:** Build (developer), tracer bullet first; QA fixtures + AC-3 replay alongside
- **Open questions:** none (override location, sandbox project, release tag answered 2026-11-05)
- **Calibration:** frozen factory `9147301f75c3` (installed sha checked at item start: matches the FREEZE line on #34). No `/plugin marketplace update`, no `/reload-plugins`. Pre-release standard has no fingerprint script and no `## Label`; this log is manual.

## Running agents

none (all roles finished); next: acceptance demo (person)



## Carry-overs (from #39, map #34)

- Contract text before code fixes.
- Validate any detection or measurement rule on the data that showed the defect; QA or the developer runs the replay (the architect has no process scope).
- Demo of the new standard: terminal session `claude --plugin-dir <worktree>/plugins/factory`, restarted after the last change to `plugins/`; check the filled `Plugin root:` line before trusting it.
- Sandbox repo WimSuenens/factory-sandbox (Project #10) for demos; nothing from it lands on agent-plugins except step-9 issues the person approves.
- Binding ADRs: 0011 (fence), 0012 (releases, freeze), 0013 (merge style: keep `--merge`). No absolute home paths in `work/`.
- Two-way decisions go to the person in chat with each stage summary; one-way doors as decision cards.

## Stage log (manual)

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Start item | lead | - | 2026-11-05T22:50Z | 2026-11-05T22:51Z | ~1m | - | - | done | board at Backlog, worktree + work/49 created |
| 2 | Requirement | product-owner | aa940c1d056ef54db | 2026-11-05T22:55Z | 2026-11-05T22:59Z | 4m | - | 84629 (subagent_tokens, peak context; spend not captured) | done | 30 ACs, 8 decisions, no card; 19 tool uses |
| 3 | Contracts and ADRs | architect | ad1af84adc138ccf9 | 2026-11-05T23:11Z | 2026-11-05T23:21Z | 10m | - | 184318 (subagent_tokens, peak context; spend not captured) | done | 5 contracts, no ADR, 12 decisions, 44 tool uses |
| 4 | Build | developer | a9399ddf9aa504a15 | 2026-11-05T23:28Z | 2026-11-05T23:33Z | 5m | - | 125458 (subagent_tokens, peak context; spend not captured) | done | 6 commits; 17 #39 tests fail by design, routed to QA; bump check pass |
| 5 | Open PR | lead | - | 2026-11-05T23:34Z | 2026-11-05T23:35Z | 1m | - | - | pass | check-bump: minor 1.0.0 -> 1.1.0 |
| 6 | QA | qa-engineer | a0b6ee3a034e26d7e | 2026-11-05T23:35Z | 2026-11-05T23:50Z | 15m | - | 234836 (subagent_tokens, peak context; spend not captured) | pass | 909 pass, 1 named skip (F1); AC-3: 5/5 flagged, 0/7 controls; 8 human-only criteria |
| 8 | Contracts and ADRs (round 2) | architect | ad1af84adc138ccf9 | 2026-11-05T23:50Z | 2026-11-05T23:52Z | 2m | - | 196892 (subagent_tokens, peak context; spend not captured) | done | S1-S5, QA F1/O1/O2 applied; 8 fence questions (E data egress), no ADR change; Question: E as 8th fenced item? lead kept E a question (two-way) |
| 9 | Build (round 2) | developer | a9399ddf9aa504a15 | 2026-11-05T23:52Z | 2026-11-05T23:54Z | 2m | - | 142265 (subagent_tokens, peak context; spend not captured) | done | contract section 10 applied; 6 tests to QA; standard 683cfb53... |
| 10 | QA (round 2) | qa-engineer | a0b6ee3a034e26d7e | 2026-11-05T23:54Z | 2026-11-06T00:00Z | 6m | - | 266869 (subagent_tokens, peak context; spend not captured) | pass | 950 pass, 2 named skips (docs rows); AC-3 5/5, 0/8; standard 683cfb53... |
| 12 | Documentation | docs-writer | aa3b6dc1f00d21144 | 2026-11-06T00:00Z | 2026-11-06T00:07Z | 7m | - | 206095 (subagent_tokens, peak context; spend not captured) | done | ownership row, reference, README, CHANGELOG 1.1.0; tests 952 pass 0 skipped; 7 decisions |
| 13 | Delivery prep | devops | a33f91761c9ee2e52 | 2026-11-06T00:00Z | 2026-11-06T00:01Z | ~ | - | 35755 (subagent_tokens, peak context; spend not captured) | done | runbook 1.1.0 entry, demo script (8 steps), sandbox read-only state; PR number left as placeholder |
| 11 | Security (round 2) | security-reviewer | a38eb60ee88a63e43 | 2026-11-05T23:54Z | 2026-11-05T23:55Z | ~ | - | pending notice | pass | S2-S5 fixed; S1 partly (low residual: one git identity for all roles); new low N1, N2 accepted, no further round |
| 7 | Security | security-reviewer | a38eb60ee88a63e43 | 2026-11-05T23:35Z | 2026-11-05T23:35Z | ~2m | - | 65906 (subagent_tokens, peak context; spend not captured) | pass | 0 critical/high, 3 medium (S1-S3), 2 low (S4,S5); fixes held for one feedback round with QA's |

## Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-05T22:59Z | 2026-11-05T23:09Z | yes | three questions after the requirement (sandbox project, override location, release tag) |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-05T22:41Z | other | started run at step 5 (item #49), set carry-overs |
| 2026-11-05T23:09Z | other | confirmed all three answers (sandbox #10, worktree + ownership row, tag by merge step) |

## Accepted limits (lead, from security round 2)

- S1 residual: with one git identity for all roles the author test cannot separate them; subject test and the shown rule text still apply (low).
- N1: `seen` may quote a long path that reads like an instruction (low). N2: FREEZE-line check compares logins; the person and the Lead sharing one account defeats it (low). Candidates for step-9 issues; need the person's approval to file.
| 2026-11-06T00:07Z | other | pending: acceptance demo in the sandbox (8 human-only criteria) |
| 2026-11-06T00:20Z | demo | sandbox session started with --plugin-dir on ../wt/49/plugins/factory; first check failed (skill text not loaded yet), re-run after loading factory:run: root = item 49 worktree, release 1.1.0, standard 683cfb53..., tooling 295033f4..., fence heading and question E present. Session trusted. |
