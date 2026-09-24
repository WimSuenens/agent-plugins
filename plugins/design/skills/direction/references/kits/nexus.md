> Reference example (**nexus** kit) — read for calibration on how specific and rule-bound a direction can get. Do not reuse this kit's colours, fonts, copy, or named devices in a new direction; borrow only the *pattern* of how tightly each rule is stated.

# Design brief

Apply the principles below to a new, unrelated project. Do not reuse any
specific colours, fonts, or copy from a reference design — invent your own
palette, typography and words from these rules.

## Concept

An instrument panel, not a software product: precision and urgency argued
at the same time, entirely without softness. Base the whole page on flat,
achromatic neutrals with no colour cast, and light it with exactly one hot,
saturated hue. Nothing else on the page should carry colour meaning — the
achromatic base is what makes the one accent read as a signal rather than
a decoration.

## Colour strategy

Pick one hot accent hue (optionally fading toward a close neighbour at its
tail) and let it be the *only* colour in the interface — every button,
every live/status indicator, every label that needs emphasis. Don't
introduce a second brand hue anywhere, even for illustration or category
differentiation; tell sections and items apart with layout and iconography
instead of colour. The instant a second hue appears, the first stops
meaning "this is live" or "this is actionable."

## Type strategy

Use three faces with one strict job each and never let their jobs blur.
One workhorse sans sets body copy only — never a heading. One expressive
display face sets every heading at one fixed, tight tracking value that
never loosens for a "friendlier" moment — the clenched tracking is the
personality; loosen it and the design goes soft. One monospaced face is
your "readout" voice — timers, coordinates, nav labels, status badges — and
it is always set in caps at a wide tracking value, never mixed case, never
used for a sentence a human wrote in a relaxed tone.

## Shape & elevation

Replace rounded corners with a single, consistent cut: clip every corner
at a fixed angle instead of curving it, driven by one or two named "cut"
values so you can turn the whole language off (cut = 0, meaning plain
rectangles) as a proof the effect is systemic, not hand-drawn per element.
Grant yourself exactly one deliberate exception for an element that's
meant to read as *embedded software* rather than *hardware panel* — the one
place a soft, conventional rounded corner is allowed to survive. Keep glow/
elevation tight and hot, sized to the element casting it (a button's own
edge, a dot's own halo) — never a large, faint ambient wash; that's a
different design's move, and mixing the two muddies which one you're
making.

## Motion

Allow one or two small ambient loops that read as "this is live" — a slow
scanning line, a pulsing status dot, a marquee — running indefinitely.
Everything else enters once, staggered on a short stepped delay, and never
repeats. Suppress all of it, ambient and one-time alike, when the viewer
prefers reduced motion, and don't ship anything that reacts continuously to
the pointer with no way to turn it off.

## Voice

Prefix short navigational or category labels with a slash, like a file
path, so they read as system output rather than marketing copy. Reserve
a screaming-snake-case treatment for genuinely telemetry-flavoured micro-
copy only — never for an actual heading. Write calls to action as two
words, imperative and specific, never a generic "Learn more." Give
quantities specific, slightly technical-looking values. When you state a
value of belief or principle, structure it as naming what you refuse to do
in the same breath as what you do — a negation right after the claim reads
as more convincing than the claim alone. Whatever text sits directly on a
solid accent fill, compute its colour against that specific accent tone
rather than assuming white or black will clear contrast.

## Apply it

Take a brief for a completely different product or audience and design it
from these rules: your own achromatic base and single hot accent, your own
fixed-angle cut signature, your own three-face type system with one
readout voice, your own tight-glow elevation, and your own slash-prefixed,
negation-structured voice.
