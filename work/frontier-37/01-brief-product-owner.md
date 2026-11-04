# Brief: product-owner — 37
Goal: Write a decision card for #37 ("Bounds of a local countermeasure") so the person can settle what the Lead may never override locally, and how overrides stay visible and bounded in time.
Inputs: #37 (`gh issue view 37`), which holds the proposal; map #34 (`gh issue view 34`): Destination, Decisions so far (especially "Changing the standard", "Andon", "Respect for people"); `docs/agents/factory.md` (decision-maker level: technical); `${CLAUDE_PLUGIN_ROOT}/references/decision-card.md`; the plugin's current standard in this worktree: `plugins/factory/skills/run/SKILL.md`, `plugins/factory/references/protocol.md`.
Constraints:
- This is a grilling ticket in a frontier round: the card offers **Question me** (`/grilling`) as the first dig-deeper option, ahead of the others.
- Two or three options. Options should differ in how much of the person's authority is fenced off and how overrides are bounded (e.g. the proposal as written; a narrower fence; a fence plus a stricter expiry). Keep override *format and precedence* out of the card — that is a two-way door decided later inside a slice.
- Decision-maker is technical: add technical detail inline after the three consequence lines.
- No tracker writes; the lead posts the card.
Output: `work/frontier-37/02-decision-local-countermeasure-bounds.md`; result `work/frontier-37/03-result-product-owner.md` with `Status: needs-decision`. Commit both: `#37 product-owner: decision card on local countermeasure bounds`.
Done: the card follows the template and rules; "Undoing it later" is concrete for each option; the recommendation is your own pick.
