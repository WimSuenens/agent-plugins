---
status: accepted
---

# The documentation site has an editorial, wiki-style look

Frontier ticket [#147](https://github.com/WimSuenens/agent-plugins/issues/147), under map [#146](https://github.com/WimSuenens/agent-plugins/issues/146). The owner's answer is recorded on the ticket's needs-you comment: https://github.com/WimSuenens/agent-plugins/issues/147#issuecomment-6835019566 (option A, with the language switcher in the top bar).

## Context

Every page, component and style sheet of the documentation site is built on its visual direction, so no slice could start before it was chosen. The owner asked for a look that is neutral but warm. Three clickable prototypes carried identical content (the same 16 pages, as a wiki: navigation tree, breadcrumbs, on-page contents, see-also links, reference tables), so only the look differed. Lean and the Obeya room are content with their own pages, not styling. The stack (Astro) was not in question.

## Options considered

- **A. Editorial doors.** Warm serif type, a single narrow reading column, rules instead of boxes.
- **B. Board.** Dense sans type, panels, a sticky navigation tree on the left and the contents on the right.
- **C. Plain.** A classic wiki look with system fonts that follows the system light or dark setting.

The owner chose A and gave no reasons for not choosing B or C. The comparison below is the architect's assessment at the time of the decision, not the owner's rationale:

- B is efficient for browsing reference and busier for a newcomer. It needs the most custom components and has the highest estimated undo cost (about two weeks), because lanes and cards get baked into templates. It also carries the factory's own metaphor, which the architect judged a poor match for the neutral-but-warm tone the owner asked for.
- C is the fastest and cheapest to build, with the lowest estimated undo cost (days). The architect judged it the least warm of the three.

## Decision

Option **A, Editorial doors**:

- a warm serif for headings and a single reading column (about 70 characters);
- rules instead of boxes and cards;
- wiki navigation on every page: a navigation tree, breadcrumbs, an on-page contents list and see-also links;
- the **language switcher is a control in the top bar of every page**;
- Lean and the Obeya are pages of content, not a visual theme; the look carries no Lean metaphor.

**Locked** once the first slice that builds on it ships; provisional until then.

## Consequences

- Layout components, the type scale and the colour tokens follow the editorial look; page structure and content are the same under every option.
- Colour, type and spacing live in CSS custom properties, and content (Markdown, generated reference data, translations) carries no layout markup, so a later change stays a refactor.
- The accessibility and speed bars hold: contrast of 4.5:1 for text and 3:1 for interface parts, visible focus, a skip link, real links and buttons, no motion without a `prefers-reduced-motion` guard, a system or one self-hosted variable font, and no client script beyond the language switcher.
- The top-bar switcher must work with longer Dutch words and on a narrow phone.
- The serif face and the wide reference tables need a check on mobile speed and horizontal overflow.

## Way back

Undoing this costs about a week of rework on layout components and styles, plus re-checking contrast and mobile speed. Content survives because it carries no layout markup. Supersede this ADR with the ADR that records the new direction.

## Non-functional targets served

Maintainability (tokens and layout-free content), accessibility and mobile speed (the bars above), and the owner's tone of neutral but warm.
