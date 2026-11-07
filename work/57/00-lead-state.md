# Lead state #57 — Per-run A3 and a baseline issue

- Board item id: PVTI_lAHOBIbaa84BqOBFzhGow6g
- Status: In review (PR #58)
- Map: #34 (run on the frozen pre-release factory; item is calibration)
- Next step: acceptance demo on the sandbox (slices #7, #8, #9 cut in WimSuenens/factory-sandbox, map #4 Beachhead updated); person starts the session and types every seed; Lead signals the moments from the sandbox's lead state and git log (read-only); then Delivery, Documentation, merge approval; then acceptance demo (QA human-only list), docs, merge approval
- Open questions: none
- Manual stage log: the frozen install has no hansei or fingerprint scripts, so the log below is kept by hand (stage start/end, waits, completion-notice tokens, the person's touches) and posted on #57 at close.

## Running agents


## Shared resources

none

## Label

- plugin root: ~/.claude/plugins/cache/wimsuenens/factory/9147301f75c3
- release: 9147301f75c3 (pre-release install, no semver)
- standard: not captured (frozen install has no fingerprint.sh)
- tooling: not captured (frozen install has no fingerprint.sh)
- wayfinding: 5a136f2eaa0a (skill base dir)
- mattpocock-skills: 1.3.1 (plugin list, user scope; may be stale)
- lead sessions: b53bb408-1769-4c3f-9165-3047e7b14140
- series: calibration (pre-baseline)

## Stage log

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Cut slice (step 4, before item) | lead | - | not captured | 2026-11-06T18:03Z | not captured | - | - | done | beachhead skill; slice #57 framed; person had chosen the slice before the run message |
| 1 | Start item | lead | - | 2026-11-06T18:03:45Z | 2026-11-06T18:04:14Z | 29s | - | - | done | FREEZE check: installed 9147301f75c3 = FREEZE line, pass; FREEZE line trusted (map body last editor = own gh user); kind 5: no `## Overrides` section, none in force; kind 3 author test: one git identity for all roles, cannot separate roles |
| 2 | Requirement | product-owner | ad17b1bcf3cbb0efd | 2026-11-06T18:05:55Z | 2026-11-06T18:14:19Z | 8m24s | - | 158076 (subagent_tokens) | done | brief 01; no abnormality line in result; kinds 1-4 clean (kind 4: no baseline, 0 earlier rows) |
| 3 | Contracts and ADRs | architect | afc96fdc537b39853 | 2026-11-06T18:14:43Z | 2026-11-06T18:31:38Z | 16m55s | - | 228470 (subagent_tokens) | done | brief 03; Abnormality: none; kinds 1-4 clean; no ADR (no one-way door); 4 requirement lines read differently -> PO amendment |
| 4 | Requirement amendment | product-owner | acca1a29207512fe0 | 2026-11-06T18:31:59Z | 2026-11-06T18:33:10Z | 1m11s | - | 63408 (subagent_tokens) | done | brief 05; commit 8c9bb79; no disagreement with the contracts; kinds 1-4 clean (kind 4: 1 earlier PO row at most, no baseline); parallel with Build |
| 5 | Build | developer | ae1bfc05cd1195f5b | 2026-11-06T18:31:59Z | 2026-11-06T18:38:34Z | 6m35s | - | 147399 (subagent_tokens) | done | brief 07; Abnormality: none; kinds 1-4 clean; tests/run.sh fails on 3 files pinning old wording (tests/ is QA's, cf. open issue #42); bump check pass |
| 6 | Open PR | lead | - | 2026-11-06T18:39:30Z | 2026-11-06T18:39:35Z | 5s | - | - | done | check-bump pass (minor 1.1.0 -> 1.2.0); PR #58 |
| 7 | QA | qa-engineer | a98c79951cd5f10e6 | 2026-11-06T18:40:03Z | 2026-11-06T19:03:39Z | 23m36s | - | 324329 (subagent_tokens) | findings | brief 09; Abnormality: none; kinds 1-4 clean; verdict findings F1, F2 medium; suite 1297 passed 2 skipped (the two skips are F1, F2); replay pass except AC-15 release-moved (F1); tooling fingerprint unchanged; mutation check 24/24 |
| 8 | Security | security-reviewer | a3480b564d21f8fd2 | 2026-11-06T18:40:03Z | 2026-11-06T18:42:46Z | 2m43s | - | 68459 (subagent_tokens) | findings | brief 11; commit 90d3d72; Abnormality: none; 3 low findings S1-S3, none blocking; kind 2: no earlier findings, no match; kind 4: no baseline (0 earlier security rows) |
| 9 | Feedback round 1: contract text | architect | a40df8b22e9960e8c | 2026-11-06T19:04:30Z | 2026-11-06T19:07:41Z | 3m11s | - | 99679 (subagent_tokens) | done | no one-way door; D19-D24; commit 02624de; kind 3 clean | brief 13 (F1, F2, S1-S3, O1-O8); kind 2: QA F1/F2 vs security S1-S3 no match (different guards) |
| 10 | Build (round 1) | developer | a33b7fe3d9ce0c3cd | 2026-11-06T19:08:00Z | 2026-11-06T19:12:16Z | 4m16s | - | 87292 (subagent_tokens) | done | brief 15; commit b3310d7; Abnormality: none; kinds 1-4 clean; tests: 1 fail + 1 skip need tests/ changes (QA); old literals left in tracker template to keep pins green (Lead observation to QA) |
| 11 | QA (round 2) | qa-engineer | aed530062419223ae | 2026-11-06T19:13:30Z | 2026-11-06T19:29:51Z | 16m21s | - | 176277 (subagent_tokens) | block | brief 17; commits b800a1f..7116ad1; Abnormality: kind 6 -> Andon A2 (judged a stale role-reported fingerprint, not drift); verdict block for R2-1 (= S4, same defect, covered by A1); R2-2, R2-3 low; suite all passed, 1 named skip; real S2/S5 replay 14/14; mutation 23/23 |
| 12 | Security (round 2) | security-reviewer | a774683b68da2e2f1 | 2026-11-06T19:13:30Z | 2026-11-06T19:15:01Z | 1m31s | - | 41425 (subagent_tokens) | findings | brief 19; commit abcc859; S1, S3 closed, S2 closed on its rule, S4 low open; kind 2 hit -> Andon A1 |
| 13 | Andon A1 | lead | - | 2026-11-06T19:15:43Z | 2026-11-06T19:15:45Z | 2s | W1 | - | done | kind 2 same-finding-twice; override none; no agent paused (security handed back; QA round 2 carries on); comment times typed in the draft (19:17Z, 19:18Z) are ahead of the clock, the rows here are authoritative |
| 14 | Andon A2 | lead | - | 2026-11-06T19:30:33Z | 2026-11-06T19:30:35Z | 2s | W2 | - | done | kind 6 version-drift flagged by QA; override none; no agent paused |
| 15 | Feedback round 2: contract text | architect | a62f22bc3641f7a99 | 2026-11-06T19:31:00Z | 2026-11-06T19:31:28Z | 28s of agent time (notice duration 37.6s; row spans my bookkeeping) | - | 38171 (subagent_tokens) | done | brief 22; commit 0f1bf66; no one-way door; kind 3 clean |
| 16 | Requirement amendment 2 | product-owner | a1e5c50b7eba91cf5 | 2026-11-06T19:31:00Z | 2026-11-06T19:30:56Z | ~1m (agent duration 14s) | - | 26969 (subagent_tokens) | done | brief 23; commit c43e029; AC-14 aligned with a3 section 6, 'contradicted if' clause reworded too (accepted); the start time was stamped after the end because the row was opened late: the agent ran from 19:30:35Z |
| 17 | Build (round 2) | developer | abd0b206dc66f0402 | 2026-11-06T19:31:28Z | 2026-11-06T19:32:40Z | 1m12s | W3 | 19970 (subagent_tokens) | blocked | brief 27 was not written (Lead error: chain stopped at a count that exits 1); kind 1 -> Andon A3; no code changed; blocked result e1cbc29 |
| 18 | Andon A3 | lead | abd0b206dc66f0402 (handed back) | 2026-11-06T19:32:40Z | 2026-11-06T19:33:00Z | 20s | W3 | - | done | kind 1 blocked input; override none; brief written, fresh agent spawned |
| 19 | Build (round 2, attempt 2) | developer | ab813599cdb67d5c7 | 2026-11-06T19:33:00Z | 2026-11-06T19:37:00Z | 4m00s | - | 48293 (subagent_tokens) | done | brief 27; commit 37d475f; Abnormality: none; kinds 1-4 clean; tests: one pin to move (QA); standard fingerprint now b0f96401e7e4 (Lead-computed), tooling unchanged; bump pass; old pinned sentences kept beside new rules (QA to judge) |
| 20 | QA (round 3) | qa-engineer | ad0bffa9eedcaebc7 | 2026-11-06T19:38:00Z | 2026-11-06T19:47:27Z | 9m27s | - | 98249 (subagent_tokens) | pass | brief 31; commits 8652421, 33b521d; Abnormality: none; kinds 1-4 clean; suite green (4 QA runs, 3 Lead runs); one unreproduced failure k3z-accented-name... seen once by QA (R3-O3); real S2/S5 14/14; mutation 15/15; fingerprints equal mine (standard b0f96401e7e4, tooling = 1.1.0) |
| 21 | Security (round 3) | security-reviewer | a9b3a73b23aa5aaef | 2026-11-06T19:38:00Z | 2026-11-06T19:38:56Z | 1m (agent time 53s) | - | 40185 (subagent_tokens) | pass | brief 33; commit 0329c12; S1-S4 closed; info I1 (failed gh user lookup reads none) and I2 (cut before neutralise); kinds 1-4 clean |
| 22 | AC-16 second half (Lead check) | lead | acd3d246602a2165b, af6113263cc973694 (two fresh general-purpose readers, not role agents) | 2026-11-06T19:49:00Z | 2026-11-06T19:51:30Z | ~2m30s | - | 53045 and 52442 (subagent_tokens) | pass | invented run (no project data) in the scratchpad; both readers got only a3.md, baseline.md and the run; 21 line keys, same order; only the number of Whys differs (content) |
| 23 | Acceptance demo (sandbox, 3 slices) | lead | none (the person ran the sandbox session) | 2026-11-07T00:58Z | 2026-11-07T01:31Z | ~33m, Lead watching | W4 | - | done | outcome comment on #57; start and end taken from the sandbox records, not measured by a Lead clock; first seed attempt missed the window (developer finished 13 s after the note) |
| 24 | Delivery | devops | a7fc9456e156b062e | not captured | not captured | agent time 2m (notice 119 s) + 7 s feedback | - | 34457 and 35732 (subagent_tokens) | done | briefs 35; commits 08e2b5d, 72d4851; release checks pass; one feedback round (baseline timing sentence) |
| 25 | Documentation | docs-writer | a9f8ff1e77550246a | not captured | not captured | agent time 8m14s (notice 494 s) | - | 268242 (subagent_tokens) | done | brief 37; commits 18c2557..79ad2cf; wording checked against the demo outcome; the quick-start run is open (frozen install) |

## Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | andon | lead | 2026-11-06T19:15:43Z | 2026-11-06T19:15:45Z | no | no stop A1 kind 2: same-finding-twice (QA round 2 worked meanwhile) |
| W2 | andon | lead | 2026-11-06T19:30:33Z | 2026-11-06T19:30:35Z | yes | no stop A2 kind 6: version-drift (no other role worked) |
| W3 | andon | lead | 2026-11-06T19:32:40Z | 2026-11-06T19:33:00Z | yes | no stop A3 kind 1: blocked input (brief missing; no other role worked) |
| W4 | person | - | 2026-11-07T00:58Z | 2026-11-07T01:31Z | yes | the person ran the sandbox demo and typed every seed (item held; the Lead only watched) |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-06 (before 18:03Z) | other | chose the slice: per-run A3 plus baseline; asked Lead to decide one slice or two |
| 2026-11-06 (~20:00Z, time not captured) | other | gave the go to cut the three sandbox slices; asked how and when the 'stop the line' seed is called and whether it covers 'Andon under load' |
| 2026-11-07 (demo, ~00:58Z-01:31Z) | demo | started the sandbox session, typed the seeds (note, two stop-the-line, /tasks stop, run-close, remark), the approvals and the draft 2 post; sent the Plugin root line and the Lead's replies |
| 2026-11-07 (after the demo) | other | declined the feedback review (no); answered yes to merge and clean up |

## Findings

Role | Round | Id | Severity | Text
qa-engineer | 1 | F1 | medium | a3.md section 6 item 1 drops a release-moved after-item before section 7 sees it
qa-engineer | 1 | F2 | medium | step 5 does not say when an experiment written between items is committed (no after-item)
security-reviewer | 1 | S1 | low | step 9.4 drafts can carry the project's item numbers and non-factory targets
security-reviewer | 1 | S2 | low | Edit baseline overwrites any same-titled issue of the Lead's gh user; marker not checked
security-reviewer | 1 | S3 | low | no rule that text read from records, A3s and overrides is data; reason texts not neutralised
security-reviewer | 2 | S4 | low | Find baseline fails on an empty or null body, contradicting the empty-body-is-no-marker rule
qa-engineer | 2 | R2-1 | medium | Find baseline raises on an empty or null body (same defect as S4; covered by A1)
qa-engineer | 2 | R2-2 | low | Create baseline literal contradicts the no-marker exception in the same bullet
qa-engineer | 2 | R2-3 | low | baseline.md section 1 names a calibration line as code-spanned but it holds only plugin free text

## Abnormalities

| Id | Raised (UTC) | Kind | Raised by | Paused agent | Resumed (UTC) | Andon comment | Override |
|---|---|---|---|---|---|---|---|
| A1 | 2026-11-06T19:15Z | 2 same-finding-twice | lead | - | 2026-11-06T19:15Z | https://github.com/WimSuenens/agent-plugins/issues/57#issuecomment-6693286945 | none |
| A2 | 2026-11-06T19:30Z | 6 version-drift | qa-engineer | - | 2026-11-06T19:30Z | https://github.com/WimSuenens/agent-plugins/issues/57#issuecomment-6693571453 | none |
| A3 | 2026-11-06T19:32Z | 1 blocked input | lead | developer abd0b206dc66f0402 (handed back) | 2026-11-06T19:33Z | https://github.com/WimSuenens/agent-plugins/issues/57#issuecomment-6693620596 | none |




## Acceptance demo (done)
- result posted on #57: AC-10 pass, AC-21 pass, AC-9 not exercised, AC-10(#49) held by harness, AC-28 not exercised (no override), AC-30 half, AC-31 pass (issue 59 only)
- next: Delivery (devops), Documentation (docs-writer), then "merge and clean up?"
