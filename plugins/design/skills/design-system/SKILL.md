---
name: design-system
description: Build a design system — foundations, components with states, and psychology-driven patterns — from scratch or extracted from an existing UI, written as design/system.md plus tokens in the repo's stack.
disable-model-invocation: true
---

# Design system

A design system is a set of decisions made once so no screen has to make them again. Every rule in it carries its **mechanism** (the `/design:ux-psychology` term it serves), so whoever applies it knows when it bends. The decisions split by **door** (the `/wayfinding:reversibility` vocabulary): one-way doors are asked, two-way doors are chosen and stated.

## 0. Pick the mode and read what exists

The **working draft** is the spec itself: copy [assets/system-template.md](assets/system-template.md) to `design/system.md` now (or next to an existing design folder if the repo has one) and fill it as you go.

- **Extract**: the repo already has UI (stylesheets, a Tailwind config, a component folder, a theme file). Inventory every colour, font size, weight, line height, spacing value, radius, shadow and duration actually in use, with counts. Near-duplicates (`#333` / `#343434`, 15 px / 16 px) are one decision made twice.
- **From scratch**: no UI yet.

In both modes, read `design/direction.md` (or `design/direction-*.md`) if present. Its counted commitments override the defaults in this skill: palette size, type roles, the elevation device, motion rules, voice.

Invoke `/design:ux-psychology` now; the vocabulary is used in every later step.

**Done when** the mode is set, and in extract mode the inventory is written to the draft's Context section.

## 1. Context

Ask a few direct questions: what's being built, for whom, on which platforms, the hard constraints (existing brand assets, accessibility level, dark mode, framework), and the product moments that matter most (onboarding, checkout, pricing, …).

**Done when** the answers are written verbatim in the draft's Context section.

## 2. One-way doors: ask

These decisions touch every screen if reversed. Put each to the user with a recommendation:

1. **Token architecture**: tiers (primitive → semantic → component) and the naming scheme (`color.text.muted`, `--space-4`, …).
2. **Theming model**: light only, light + dark, multi-brand.
3. **Component base**: own components, a headless library, or an existing kit.
4. **Platform targets**: web, iOS, Android, desktop — and therefore the token output formats.
5. **Accessibility level**: WCAG 2.2 AA (the floor this skill assumes) or AAA.

Skip any that a direction brief or an existing ADR already settles. If the repo has `docs/adr/`, record each answer as an ADR.

**Done when** all five are answered and recorded.

## 3. Two-way doors: choose and state

Choose every remaining value yourself, using [references/foundations.md](references/foundations.md) for the defaults and their mechanisms: colour roles and contrast pairs, type scale, spacing scale and grid, radius, elevation, motion, iconography, breakpoints. In extract mode, collapse the inventory onto the new scales and map each old value to its replacement.

Run `scripts/contrast.py` on every pair listed in foundations, once per kind (`--kind text` for text, `--kind ui` for borders, focus rings and icons; `--over` for scrims on photos); adjust until each run exits 0 at the step-2 level.

**Done when** every foundation has values, and every contrast pair is measured and passing.

## 4. Components and patterns

Specify the core components with every state from [references/components.md](references/components.md) — the list is a floor; add the product-specific components the chosen patterns need — then the patterns from [references/patterns.md](references/patterns.md) for the product moments named in step 1. Each pattern names its principle and passes the three-check test.

**Done when** every component lists all its states and every chosen pattern names its principle.

## 5. Write it

1. **Spec**: finish every section of `design/system.md`. Each rule keeps its mechanism.
2. **Code tokens**: one output per step-2 platform target, in the format that platform's code already uses (CSS custom properties, a Tailwind theme, a Swift or Kotlin theme file); CSS custom properties for web when there's nothing yet. Token names follow the step-2 architecture. Values CSS can't express as custom properties (media-query breakpoints) go in as named constants or comments.
3. **DTCG JSON** (`design/tokens.json`, W3C Design Tokens format): when the user asks, or when there are two or more platform targets — then it is the single source, and the platform outputs are generated from it (suggest Style Dictionary).

**Done when** the spec and every token output agree value for value.

## 6. Check it

Check the system against every rule in [references/craft-rules.md](references/craft-rules.md): each rule is either made easy by a token, component or pattern, or deliberately set aside with a reason in the spec. Fix gaps before reporting.

Report the files written. If `docs/agents/design.md` doesn't exist in this repo, suggest `/design:setup-design-skill`, so every other skill builds from the system.
