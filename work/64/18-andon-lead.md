# Andon A1: same-finding-twice (draft, lead)

Pause start: 2026-11-08T21:40:50Z. No agent was stopped: QA had handed back. Next: the developer feedback round for F7.

## 5 Whys

1. Why did F7 reach QA? — The *Overlap* paragraph of the run skill was not updated when `paths.sh` gained case folding and overlap rule 3 — evidence: reviews/qa-64.md F7 row, work/64/15-feedback-developer.md item 2 (names `paths.sh` only)
2. Why did the feedback name `paths.sh` only? — The architect's build checklist lists edits by file and line for each finding, and the architect's Done list asks for contract text and QA rows, not for every plugin text that states the changed rule — evidence: plugins/factory/agents/architect.md lines 36-39, work/64/14-result-architect.md build checklist item 2
3. Why did the developer's own check not catch it? — The developer's Done list asks for passing tests and a changed-files list, with no step that searches for other statements of a rule being changed — evidence: plugins/factory/agents/developer.md lines 36-38
4. Why did the same type of defect recur after F5 (a stale baseline line, round 1)? — F5 was routed as a single file-and-line edit; the feedback template has no field for other statements of the rule — evidence: plugins/factory/references/protocol.md lines 80-84, work/64/13-feedback-architect.md item 11
process item to change: the developer's Done list and the architect's checklist format lack "search the plugin for every other statement of a rule you change, and update it or list it".

## Match

M1: the guard sentences pass the one-fix test (after changing a rule, search every text that restates it and update it); the triggers name the same condition (a changed rule left stated elsewhere). F5 = F7.

## Refused drafts

none
