---
status: proposed
---

# Two-way decisions flow back to the lead, and corrections never stop a stage

Every role lists each two-way door it decided in a `Decisions` field of its result: what it chose, the alternative it rejected, and the cost of undoing it. The role does not filter, because it cannot judge what matters to other roles. The lead reads the field alongside `Status` and `Summary`, and posts the decisions with the stage summary on the slice ticket and in chat, so the person sees every one at each stage boundary.

The lead overturns a decision on its own when it contradicts the destination, a contract or ADR, or the map's Decisions so far, and reports the overturn in the same overview. The person can overturn any decision, the lead's included. An overturn becomes a feedback brief (`Source: lead`) to the role that made the decision. That role picks it up in its next round, the way it handles QA findings, and the stage in progress keeps running. A decision reclassified as a one-way door goes through a decision card instead; the stage still runs, but the item does not merge until the card is decided.

## Considered options

- **Live streaming of decisions from background roles.** Rejected. A stage is short next to an item, so the stage boundary is soon enough, and live streaming would need a second channel beside the result files.
- **Only decisions a role flags as uncertain or cross-cutting.** Rejected. Filtering belongs to the lead.
- **Pausing the next stage until a correction lands.** Rejected. It trades progress for a guarantee the merge gate already gives.
