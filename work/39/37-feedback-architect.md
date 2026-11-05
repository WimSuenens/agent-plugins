# Feedback: architect — 39
Source: acceptance demo (person: AC-17 fail)
Findings — update the contracts first; the developer builds from them next:
1. #44 (`gh issue view 44`) — major — wait kinds: add "stalled" (an agent or the Lead made no progress, e.g. the stream watchdog) and "interrupted" (machine sleep, server_error, until resume), so measure 1's split is agent working + person + limits + stalled + interrupted = total. Say how each is detected and stamped in the stage log.
2. #44, second part — major — token spend from a transcript cut by a stall or interruption reads `not captured (transcript truncated by <kind>)`, never a number; say how the Lead recognises truncation (e.g. the role's notice failed, or the transcript ends without a final assistant message).
3. #45 — minor — Interruptions: an agent that stalls or fails after writing a complete `done` result is checked against its Done list and accepted without a resume; logged as its wait kind.
4. #46 — minor — first-pass yield: define "pass first time" precisely (e.g. first verdict `pass` with no finding at or above minor) and state the record's wording for a pass with low findings.
5. #47 — minor — close step: commit the lead state before `git rm -r work/<id>` (or the order that never fails); keep "record posted before work/ removal".
Keep schema `v1` unless a field's meaning changes incompatibly; if it does, say so and bump.
Inputs: #44–#47, the demo record https://github.com/WimSuenens/factory-sandbox/issues/2#issuecomment-6652019454 (read-only), contracts/39-*.md, docs/requirements/39-hansei-record.md.
Output: contracts/39-*.md; result `work/39/38-result-architect.md`. Commit `#39 architect: wait kinds, truncation, FPY, close order`. Touch only your paths.
