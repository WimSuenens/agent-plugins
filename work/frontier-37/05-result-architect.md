# Result: architect — 37
Status: done
Progress:
  Done: inputs read; ADR 0011 and CONTEXT.md entries written (4c68a5f)
  Next: none
Summary: ADR 0011 records the person's choice on #37: option C, plus the andon follow-up and the poka-yoke check. It covers the wide fence (six fenced items), poka-yoke at write time (the Lead refuses fenced overrides), detection (a run-start check, and an andon abnormality any role can raise), visibility (name and start date in hansei and hoshin), and expiry at the close of the run the override started in, with keep, promote or drop next to the A3. Consequences name what stays two-way (override format and precedence, fence wording and placement, the hansei field name, how the choice is recorded) and what stays deferred (experiment length, which renewal leaves open). Rejected: A (hoshin expiry, a review moment the map hasn't defined), B (narrow fence, losses that can't be recovered), and detection only. The ADR cites the decision comment URL only. CONTEXT.md gains Local countermeasure, Override, Fence and Yokoten, each with an _Avoid_ line.
Artifacts: docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md, CONTEXT.md
Decisions:
- Glossary placement: the four terms go under the existing "## Factory" heading / rejected a separate "## Lean" heading / undo: move the lines.
- "Detection only" listed as a rejected alternative, since the person's poka-yoke follow-up rejected it / rejected listing only the card's A and B / undo: delete one bullet.
- The fence list location (`references/protocol.md`, read by `skills/run/SKILL.md`) is taken from the card's technical detail; its exact wording and placement are marked two-way / undo: text edit in a slice.
- Provisional trigger: a run closes with at least one override that went through keep, promote or drop.
Open questions: none
Missing: none
