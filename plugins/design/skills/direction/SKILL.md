---
name: direction
description: Interview a project into one design direction — counted rules for concept, colour, type, shape, motion and voice — then optionally prototype it and write a reusable brief.
disable-model-invocation: true
---

A design direction is a small set of **counted commitments**, not a mood
board. "Pick a calm palette" is a **mood word**: nothing anyone can build
from. "Pick exactly three colours and name what each one is allowed to
touch" is a counted commitment. This skill runs an interview that turns
every answer into counted commitments, then writes them as a design brief
that any implementer (human or agent) can take as its own starting prompt.

Every phase below converts mood words into counted commitments. When an
answer comes back as a mood word, ask one forced-choice follow-up and
log the counted answer it produces.

## Workflow

### 0. Project context

Ask a few direct questions about the *thing being designed*: what's being
built, who it's for, and its hard constraints (existing brand colours,
accessibility requirements, platform/framework, dark-mode-only, etc.).
This phase is scoping, not ideation.

**Done when** product, audience and every constraint are written down
verbatim in a working draft. Constraints gate every later answer: an
accent that fails contrast on a required background is wrong however good
it looks.

### 1. Concept

Skim 1-2 files from `references/kits/` for calibration on how narrow a
concept statement should be, picking kits whose domain differs from the
user's so nothing bleeds across. Kits are calibration, never a source:
invent every colour, font, device and line of copy fresh.

Then surface the governing metaphor or tension with the questions in
`references/interview-guide.md` §Concept. The concept is what every later
dimension justifies itself against ("does this serve
luxury-through-restraint, or fight it?").

**Done when** the user has committed to one sentence naming the concept.
If they want to explore instead of commit, follow the guide's
"undecided user" note and carry 2-3 concept sentences forward.

### 2. Colour, Type, Shape & elevation, Motion, Voice

Copy `assets/design-brief-template.md` into the working draft (one copy
per candidate concept). Walk the five dimensions in that order with
the questions in `references/interview-guide.md`. Write
each counted commitment into its template section the moment it's given.

**Done when** all five sections of every draft hold counted commitments
and no mood words.

### 3. Synthesize

Read `references/brief-schema.md` — what "counted" vs "mood word" looks
like per section — and finish each draft against it: the title, the fixed
opening line, and the seven content sections (Concept, Colour strategy,
Type strategy, Shape & elevation, Motion, Voice, Apply it).

- **One concept** → one brief.
- **Several concepts, or answers pulling in genuinely different
  directions** → 2-3 *divergent* candidate briefs, each internally
  consistent and choosing different values on every dimension (two
  candidates sharing a palette size or an entrance device are one
  direction twice). Label them A/B/C with a one-line epithet each, e.g.
  "A: instrument panel," "B: paper and ink."

**Done when** every brief's *Apply it* recap names one concrete device per
dimension. If it can't, the section it can't name is still a mood word:
go back to phase 2 for it.

### 4. Prototype (offer, don't assume)

Offer to prototype 1-3 candidates as a landing-page mockup for the user's
actual product. On a yes, follow `references/prototyping.md`. Skip this
phase if the user declines or there's no concrete product to mock up yet.

### 5. React, iterate, blend, pick

Walk the user through what they're seeing (or reading, if unprototyped).
Blending is a normal outcome ("A's palette with B's type system"). Re-run
the relevant slice of phase 2 for anything that changes, so every edited
section still holds counted commitments.

**Done when** the user names one direction as final.

### 6. Write the final brief

Write the chosen direction as a markdown file in the user's project, in
the schema from `references/brief-schema.md` — that shape is what makes it
reusable as an implementation prompt, the same way the files in
`references/kits/` are. Default path: `design/direction.md` (or
`design/direction-<slug>.md` when several named directions are kept side
by side); confirm path and filename with the user before writing and
honour any override.

Report the path back, and name the next step: `/design:design-system`
reads this brief as its input when building the design system.
