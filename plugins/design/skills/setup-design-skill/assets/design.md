# Design

How every skill should treat this repo's design system when touching UI: building screens, prototyping, reviewing code, or filing work.

## Before UI work, read these

- **`design/system.md`**: the design system. Tokens, scales, component states, patterns, and the mechanism behind each rule. Build from its tokens and components; a value missing from it is a gap to raise, not a value to invent.
- **`design/direction.md`** (or `design/direction-*.md`), if present: the governing design direction the system answers to.

If neither file exists, proceed silently. `/design:design-system` creates them.

## Vocabulary

Name UI decisions and findings with the **`/design:ux-psychology`** vocabulary (Hick's law, proximity, smart defaults, goal gradient, dark patterns, …). When a review touches UI (screens, flows, components, copy), run **`/design:ux-review`** on it alongside any code review.

## Where design decisions go

Sort design decisions with the `/wayfinding:reversibility` door vocabulary:

- **One-way doors become ADRs** in `docs/adr/`: token naming architecture, theming model (light/dark/brand), base component library, platform targets, accessibility conformance level. Reversing any of these touches every screen.
- **Two-way doors stay in `design/system.md`**: exact colour values, scale ratios, radii, durations. Change them there; they never earn an ADR.
- **UI terms go in the `CONTEXT.md` glossary** when the product uses them as domain language (e.g. what this product calls a "sheet" vs a "modal", a "plan" vs a "tier").

## Review findings

`/design:ux-review` findings that need follow-up are published to the issue tracker (see `docs/agents/issue-tracker.md`), one issue per finding, so `/triage` and `/to-tickets` can pick them up.
