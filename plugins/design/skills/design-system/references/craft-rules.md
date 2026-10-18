# Craft rules

Visual craft rules, each tied to the mechanism it serves (terms from `/design:ux-psychology`). The mechanism is what tells you when a rule bends: break a rule only when its mechanism doesn't apply. Grades rate the rule as stated, not its mechanism.

Shared by `design-system` (rules the system must make easy to follow) and `ux-review` (rules a screen is checked against).

## Layout and grouping

- **One grid, one spacing scale.** Every edge snaps to the grid; every gap comes from the scale. *Mechanism:* proximity and continuity read as order; low visual complexity and consistency drive first-impression trust. *Grade:* replicated mechanism; any specific value ("24 px") is folklore — consistency is the point.
- **Spacing encodes relationships.** Gaps inside a group are smaller than gaps between groups, by at least one scale step. Too much whitespace disconnects things that belong together. *Mechanism:* proximity.
- **Dividers and boxes sparingly.** Prefer spacing; add a soft divider or container only where spacing alone is ambiguous. *Mechanism:* common region overrides proximity, so a heavy divider regroups the page into harsh blocks.
- **Related things adjacent.** Put information where the decision happens: rating beside the title, quantity beside the add-to-cart, error beside its field. *Mechanism:* proximity, split attention, social proof at the decision point.

## Colour and hierarchy

- **Muted base, one accent spent rarely.** The strongest signal (saturated accent, largest size, motion) goes to the one thing that matters most on the view. *Mechanism:* pop-out needs uniqueness against calm distractors; Von Restorff.
- **Contrast floors are floors.** Body text may sit at lower contrast than headings for hierarchy, but never below 4.5:1; UI components and meaningful icons ≥ 3:1. *Mechanism:* figure–ground; WCAG 1.4.3 / 1.4.11.
- **Colour never carries meaning alone.** Status, badges and errors add text or shape. *Mechanism:* WCAG 1.4.1.

## Typography

- **One family by default; hierarchy from size, weight, colour and line height.** A second family needs one stated job. *Mechanism:* fewer varying dimensions make each variation mean more. *Grade:* folklore as a rule, a sound default.
- **Headlines attract, paragraphs support.** A title stands out by size and weight without shouting; body text gets generous line height (≈1.5) and a comfortable line length (≈45–75 characters). *Mechanism:* hierarchy on few dimensions; readability. *Grade:* line length is contested (long lines read faster on screen, moderate lines are preferred and aid comprehension).
- **Small uppercase labels get letter-spacing.** *Mechanism:* uniform-height caps crowd; slight spacing speeds recognition. *Grade:* contested, small effect.
- **Primary actions in sentence case.** *Mechanism:* caps read as shouting (convention); legibility barely differs for 1–2 words. *Grade:* folklore as usability, legitimate as tone.

## Components and content

- **Survive content variance.** A component must work with any real content: bright and dark photos, long and short names, zero and many items. Icons over images sit on a scrim or chip that guarantees 3:1. *Mechanism:* figure–ground; designing for the system, not one screen.
- **One icon style.** Same stroke weight, same filled-vs-outline logic, limited colours. *Mechanism:* similarity; mixed styles imply different meanings and create accidental isolates.
- **Consistent imagery.** Same background, lighting and framing across a catalogue, so one image works inside the grid. *Mechanism:* similarity, credibility. *Grade:* folklore as a rule, follows from replicated mechanisms.
- **Badges scan in one glance.** Shortest possible copy ("20% off"), no icon repeating the words. *Mechanism:* redundancy; Von Restorff only works if badges are rare.
- **No redundant display labels.** A value whose format explains itself (a currency amount) drops its label ("Price:"); keep labelling consistent across neighbours. **Form inputs always keep a visible label.** *Mechanism:* redundancy effect; WCAG 1.3.1 / 3.3.2.
- **State belongs to controls, not titles.** A variable the user can change (quantity, size, plan) lives in its control, never baked into a heading. *Mechanism:* the display must match state. *Grade:* folklore (no study), prevents a real mismatch.
- **The CTA states the commitment.** The primary action shows what will happen and what it costs ("Add 2 kg — €9.80"). *Mechanism:* uncertainty reduction; honest anchoring. Hiding the total raises short-term revenue in field experiments — showing it is the honest choice, and hidden costs are a dark pattern.
- **Keep context and action in reach.** On long mobile pages, a sticky title keeps context and a sticky bottom action bar keeps the primary action under the thumb — neither may cover the focused element. *Mechanism:* working memory, Fitts; WCAG 2.4.11.
- **Presets for common choices.** Offer one-tap options for the most common values, from real usage data, beside a custom control. *Mechanism:* defaults, Hick, Fitts. Inflated presets are anchoring turned against the user.
