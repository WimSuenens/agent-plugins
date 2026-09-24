# Design brief schema

The canonical shape every direction gets written in — both the 2-3
candidate briefs from phase 3 and the final brief from phase 6. Every
section exists to hold a *specific, counted* commitment. A section that
could be copy-pasted unchanged into a different project's brief has failed
— vagueness is the failure mode this schema exists to block.

## 1. `# Design brief`

Title only. If this brief coexists with others in the same project, add a
one-word epithet after a colon (`# Design brief: Instrument Panel`).

## 2. Opening instruction

Fixed line, unchanged across every brief this skill produces:

> Apply the principles below to a new, unrelated project. Do not reuse any
> specific colours, fonts, or copy from a reference design — invent your
> own palette, typography and words from these rules.

This makes the brief reusable as a prompt on its own, the same way the
reference kits in `kits/` are consumed.

## 3. `## Concept`

One paragraph naming the governing metaphor or tension that every other
section has to answer to. Good: names a specific tension and a specific
structural consequence of it ("luxury argued through restraint... hold the
palette to three colours... structure the page as alternating chapters").
Vague (reject): a mood adjective with no structural consequence ("a clean,
modern feel").

**Good looks like:** one sentence that could not be pasted into a
different brief unchanged, followed by one sentence describing a concrete
structural device the concept forces.

## 4. `## Colour strategy`

State an exact number of colours (excluding pure greys/neutrals used only
for text-on-text contrast, if that exception is itself stated). For each
one, state the *one* thing it is allowed to touch, and what it is
forbidden from touching. Cards/surfaces must be built from an explicit
rule (a tint? a border-only treatment? the ground colour itself?) rather
than left implicit.

**Good looks like:** "Three colours: a ground, an ink, one accent. The
accent appears on at most N elements, chosen for X reason, never as a
general highlight." **Vague (reject):** "a warm, inviting palette."

## 5. `## Type strategy`

State an exact number of typefaces and, for each, its one locked role
(never shared with another face). If tracking or weight is part of the
system, state the exact number of tracking/weight values and lock each to
one role, the same way colours are locked to roles.

**Good looks like:** "Two faces: one display face for headings/numerals/
labels, one quiet face for everything else. Three tracking values, each
locked to exactly one role." **Vague (reject):** "a bold heading font and
a readable body font."

## 6. `## Shape & elevation`

One named, distinctive elevation or shape device (a shadow pairing, a cut-
corner rule, a glow, an inset-only recess) described concretely enough to
implement without guessing. State the corner-radius/cut strategy and
whether it varies by role or by size. State what the device is *not*
allowed to combine with (e.g. never mix raised and recessed shadows on the
same object).

**Good looks like:** a device stated as a recipe with required parts
("border one step warmer than the ground, plus a soft coloured drop shadow
below AND a crisp hairline highlight along the top edge — both parts
required"). **Vague (reject):** "cards should feel tactile."

## 7. `## Motion`

Separate entrance motion (fires once, describe the one signature device)
from ambient/looping motion (state the exact count — 0, 1, or 2 — of small
ambient devices, never more, and name each one). Note the reduced-motion
fallback, even if it's just "everything above becomes a simple fade."

**Good looks like:** "One signature entrance device, used once per
section on scroll. Exactly one ambient loop: X. Nothing else moves without
user input." **Vague (reject):** "smooth, subtle animations throughout."

## 8. `## Voice`

State the section-label format as a rule (numbered from N, slash-prefixed,
etc.), the headline structure (line count, clause structure), how
quantities are stated (rounded vs. exact — pick one and apply it
everywhere), and one distinctive verbal tic unique to this brief.

**Good looks like:** "Section labels numbered from the second section
onward (the first has no 'before' to count from). Headlines: two short
clauses across two lines. Quantities always stated exactly, never
rounded." **Vague (reject):** "friendly, confident copy."

## 9. `## Apply it`

One closing paragraph: "Take a brief for a completely different product or
audience and design it from these rules," followed by a prose recap
naming one concrete device per dimension (not restated as abstract
principle). This section is what proves the brief is portable: if the
recap can't name one concrete device per dimension, an earlier section was
still too vague.
