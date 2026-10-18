---
name: ux-review
description: Review a UI — screenshot, live URL, or component code — for UX-psychology, craft and accessibility problems and dark patterns, as findings with severity, principle, evidence and fix. Use when the user asks to review, critique or audit a screen, flow, page or component.
---

# UX review

Critique a UI the way a redesign does: find every place where the screen fights how people perceive, decide and act, name the **mechanism** behind each problem, and propose the fix. The review is exhaustive over the passes below, not a top-three.

## 1. Capture the subject

- **Screenshot / image**: read it directly.
- **Live URL**: open it with the browser tools available this session; capture the relevant states (default, scrolled, empty, error, mobile width).
- **Component code**: read the components and their styles; reason about the rendered result, and render it if the project can run.

Then identify the **product moment(s)** the subject belongs to, from the index below.

**Done when** you can describe what the user is trying to do on this screen in one sentence, and which moment(s) it is.

## 2. Load the standards

- Invoke `/design:ux-psychology` for the vocabulary and the three-check test.
- Read [../design-system/references/craft-rules.md](../design-system/references/craft-rules.md).
- If the repo has `docs/agents/design.md`, read the design system it points at: every value off its tokens or components is a finding.

## 3. Run every pass

Walk the subject once per pass and log findings as you go:

1. **Perception and hierarchy**: grouping, figure–ground, one clear focal point, accidental isolates.
2. **Craft**: every rule in `craft-rules.md`.
3. **Interaction cost**: target size and reach, number and ordering of choices, information carried between steps, response feedback.
4. **Accessibility**: contrast pairs (measure them when you have colour values; estimate and say so when you only have pixels), target size, labels, colour-only meaning, focus, motion.
5. **Persuasion and trust**: every persuasion technique present, run through the three-check test; trust signals at the decision point.
6. **The moment's principles**: the index row's principles that the screen ignores, and the "watch for" patterns it contains.

**Done when** all six passes have run against the whole subject; a pass with no findings says so in the report.

## 4. Report

One entry per finding, most severe first:

```
[severity] <principle> — <one-line problem>
  Evidence: <where: region of the screenshot, selector, file:line>
  Fix: <concrete change>
  Dark pattern: <named pattern + failed check>   (only when the three-check test fails)
```

Severity:

- **blocker**: a dark pattern, or a WCAG AA failure.
- **major**: breaks the moment's primary task or its main trust signal.
- **minor**: costs effort or clarity without breaking the task.
- **polish**: craft consistency.

After the findings, add **beyond fixes**: up to three structural improvements the screen would benefit from (a sticky action area, presets, a reordered flow), each tied to a principle.

Deliver in chat. Then offer two optional outputs:

- Write the report to `design/reviews/<YYYY-MM-DD>-<slug>.md`.
- Publish findings that need follow-up to the issue tracker (see `docs/agents/issue-tracker.md`), one issue per finding.

## Product moment index

| Moment | Primary principles | Watch for |
|---|---|---|
| Onboarding | Goal gradient with real credited steps; IKEA effect; commitment, start small; progressive disclosure; Jakob's law; reciprocity, value before signup; resumption | Fabricated progress; work held hostage; forced registration |
| Forms | Split attention, labels by fields; chunking; smart defaults; Tesler, move complexity to the system; Fitts and target size; proximity | Removed input labels; pre-ticked consent; trick wording |
| Pricing | Anchoring and relative thinking; framing; defaults; choice overload moderators; decoy (weak) | Fake reference prices; phantom tiers; hidden recurring costs |
| Paywall / upgrade | Loss aversion, real losses only; endowment; status quo; framing | Confirmshaming; fake countdowns; asymmetric dismiss; nagging |
| Checkout | All-in price in the CTA; order summary visible; Fitts, sticky action bar; peak–end confirmation; response-time feedback | Hidden costs; sneak into basket; sticky bars covering focus |
| Retention | Peak–end incl. offboarding; variable reward with stopping cues; commitment; status quo | Roach motel; nagging; compulsion loops |
| Empty states | Reciprocity, show value; goal gradient, one first step; one primary action | Fake social proof filling the void |
| Product page | Proximity (rating by title, quantity by CTA); social proof; one primary CTA; muted hierarchy; credibility through consistency; presets; contrast | Fake scarcity or viewers; fake reviews; inflated presets |
