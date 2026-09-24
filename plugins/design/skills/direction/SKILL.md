---
name: direction
description: Run a structured interview that forces a project to commit to a governing design concept and specific, counted rules for colour, type, shape & elevation, motion, and voice — the same method used by a library of five reference "brand kit" design briefs. Synthesizes one direction, or 2-3 divergent candidates, optionally prototypes them (Artifact tool or static HTML fallback), and writes the chosen direction as a reusable design-brief markdown file into the user's project. Explicit-invoke only — do not trigger opportunistically from a passing mention of "design," "colours," or "branding."
disable-model-invocation: true
---

A design direction is a small set of *specific, counted* rules — not a mood
board. "Pick a calm palette" produces nothing anyone can build from; "pick
exactly three colours and name what each one is allowed to touch" does. This
skill runs that kind of interview, then turns the answers into a design-brief
markdown file that reads like `references/brief-schema.md` and can be handed
to any implementer (human or agent) as its own starting prompt.

Five worked examples ship in `references/kits/` — real design briefs, each
picking different, tightly specific values for the same dimensions. They are
calibration material, never a source to copy from. Skim, don't transcribe.

## Workflow

### 0. Project context

Before any design question, get the brief for the *thing being designed*:
what's being built, who it's for, and any hard constraints (existing brand
colours, accessibility requirements, platform/framework, dark-mode-only,
etc.). Keep this to a few direct questions — this phase is scoping, not
ideation. Write down constraints verbatim; they gate every later answer (an
accent colour choice that fails contrast on a required background is wrong
regardless of how good it looks).

### 1. Concept

Surface the governing metaphor or tension in a handful of sharp
forced-choice or short-answer questions — see `references/interview-guide.md`
§Concept. The concept is the thing every later dimension has to justify
itself against ("does this serve luxury-through-restraint, or fight it?").
Do not move to phase 2 until the user has committed to one sentence naming
it. If they want to defer commitment in favour of exploring divergent
directions, see the "undecided user" note in the interview guide and switch
straight to producing 2-3 concept sketches instead of one.

**Before this phase**, skim 1-2 files from `references/kits/` (not all
five) if you want calibration on how narrow and specific a concept
statement should be. Pick kits whose domain differs from the user's, so
nothing bleeds across by accident.

### 2. Colour, Type, Shape & elevation, Motion, Voice

Walk these five dimensions one at a time, in this order. For each, ask 2-4
questions from `references/interview-guide.md` that force a *specific,
counted* commitment — never accept a mood word as a final answer. Example
phrasings (full bank is in the reference file):

- Colour: "Pick an exact number of colours for the whole palette — not
  counting greys. What is that number, and what is each one the *only*
  thing allowed to use it for?"
- Type: "How many typefaces — one, two, three? Give each one job it does
  and nothing else does."
- Shape & elevation: "Pick one distinctive elevation device (a shadow
  pairing, a cut corner, a glow) that will appear everywhere something
  needs to lift off the page. What is it, concretely?"
- Motion: "What's the one thing that animates once, on entrance, and
  never again? Separately: is there an ambient loop, and if so, how many —
  zero, one, or two, never more?"
- Voice: "How are section labels formatted — numbered, slash-prefixed,
  plain? What's the one verbal tic that shows up nowhere else in the
  product's copy?"

If an answer comes back vague ("something modern," "a nice blue"), push
back once with a forced-choice follow-up rather than accepting it — this is
the whole mechanism the reference kits model. Log each committed answer
against the matching section of `references/brief-schema.md` as you go
rather than holding them in memory until the end.

### 3. Synthesize

Write the answers into the 7-section schema from
`references/brief-schema.md` (Concept, Colour strategy, Type strategy,
Shape & elevation, Motion, Voice, Apply it). Two paths:

- **User committed to one direction** — write it straight.
- **User wants options, or answers pulled in genuinely different
  directions** — write 2-3 *divergent* candidate briefs, each internally
  consistent and each choosing different values for every dimension (don't
  let two candidates share a palette size or the same entrance device —
  that's not really two directions). Label them clearly (A/B/C with a
  one-line epithet each, e.g. "A: instrument panel," "B: paper and ink").

Use `assets/design-brief-template.md` as the literal skeleton to copy and
fill for each brief; `references/brief-schema.md` is what tells you what
"good" looks like per section while you fill it in.

### 4. Prototype (offer, don't assume)

Ask whether the user wants 1-3 candidate directions prototyped as a quick
landing-page mockup for their actual product, implementing that
candidate's rules literally (the counted colours, the type roles, the
named shape/elevation device, the motion rules, the voice rules).

- **Artifact tool available this session** → load the `artifact-design`
  skill first (its own contract requires this), then publish one artifact
  per candidate.
- **Artifact tool not available** → write a self-contained static
  HTML+CSS file per candidate (inline `<style>`, no build step, no
  external assets) to `design/prototypes/<candidate-slug>.html` in the
  user's project (ask before writing outside the current project; offer to
  use a different folder if the user prefers). Tell the user to open it in
  a browser — do not attempt to open it yourself.

Skip this phase entirely if the user declines or if there's no concrete
product context to mock up against yet.

### 5. React, iterate, blend, pick

Walk the user through what they're seeing (or reading, if unprototyped).
Expect blending — "A's palette with B's type system" is a normal outcome,
not a failure of phase 3. Re-run the relevant slice of phase 2 for anything
that changes, and keep every section's commitments counted and specific
through the edits; don't let a revision reintroduce vagueness.

### 6. Write the final brief

Once the user picks (or refines to) one direction, write it as a markdown
file in the user's project, in the exact 7-section schema — this is what
makes it reusable as an implementation prompt later, the same way the
reference kits' `prompt.md` files are consumed. Default path:
`design/direction.md` (or `design/direction-<slug>.md` if multiple named
directions are being kept side by side); confirm the path and filename
with the user before writing, and honour any override. Report the path
back when done.

## References

Read lazily, per repo convention — not up front:

- `references/kits/aurelia.md`, `halftone.md`, `mira.md`, `nexus.md`,
  `vacance.md` — five full worked example briefs. Skim 1-2 before phase 1
  for calibration on specificity; never read all five for one interview,
  and never copy their concrete colours/fonts/copy/devices.
- `references/brief-schema.md` — the 7-section schema explainer: what each
  section must contain and what "vague" vs. "specific" looks like per
  section. Read before phase 3 (synthesis) and keep open while writing.
- `references/interview-guide.md` — the full question bank by dimension,
  with example phrasings and guidance for the undecided-user / multiple-
  candidates case. Read before phase 1, re-check per dimension through
  phase 2.

## Assets

- `assets/design-brief-template.md` — blank, prose-free skeleton of the
  7-section schema. Copy this verbatim per candidate/direction and fill it
  in during phases 3 and 6, rather than freehanding the headings.
