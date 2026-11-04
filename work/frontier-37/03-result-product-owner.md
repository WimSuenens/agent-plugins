# Result: product-owner — 37
Status: needs-decision
Progress:
  Done: inputs read; decision card written; card and result committed
  Next: none; waits on the person's choice
Summary: Decision card for #37 with three options that differ in how much of the person's authority is fenced off and how long an override may live. A: the proposal as written (wide fence, re-confirm at next hoshin). B: narrow fence (only merge/production approvals and the card route), same hoshin expiry. C: wide fence, every override ends at the close of the run it started in unless the person keeps, promotes or drops it. Recommendation C: same protection as A, but tied to a review moment that exists (run close, alongside the A3) rather than hoshin, whose timing and owner the map lists under "Not yet specified". B is flagged as the costly-to-undo direction: skipped checks and unrecorded measures cannot be recovered. Override format and precedence are kept out of the card, as the brief asked. Question me (/grilling) is the first dig-deeper option.
Artifacts: work/frontier-37/02-decision-local-countermeasure-bounds.md
Decisions:
- Card framing: "Same in all options" block above the options (visibility in hansei + hoshin, yokoten stays a card, format/precedence deferred) / rejected repeating it per option / undo: edit the card.
- Option C's renewal lets an experiment span runs, so the deferred "how long a countermeasure experiment is measured" stays deferred / rejected having C pre-empt it / undo: one line in the card.
Open questions:
- Architect (before posting): confirm the day estimates (A ~1 day, B ~0.5 day, C ~1.5 days of standard text; ~0.5 day per item to re-verify after the fact under B). No architect leaning was asked for: this door is about the person's authority, not a technical approach.
- Lead: whether an override that crosses the fence should itself be an andon abnormality any role can raise. It would extend the map's Andon list, so it is not on this card; worth raising if the person picks A or C.
Missing: none
Decision card: work/frontier-37/02-decision-local-countermeasure-bounds.md
