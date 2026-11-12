# Result: architect — 147
Status: done
Abnormality: none
Progress:
  Done: three visual-direction options written, with leaning and cost to undo.
  Next: none; the lead hands this to the throwaway prototype.
Summary: Three options differ in look and feel only (stack stays Astro). "Lean as second theme" is read as Lean thinking (flow, andon, waste) as the second narrative theme beside the one-way-door hook, shown through visual cues, not as a second colour theme. If the owner meant a switchable colour theme, say so; it changes option C only. Leaning: A. All three can meet contrast (4.5:1 text, 3:1 UI), keyboard use (visible focus, skip link, real links and buttons), reduced motion (no motion without a `prefers-reduced-motion` guard) and fast mobile loads (system or one self-hosted variable font, no client JS beyond the language switcher, no images above the fold).
Artifacts: work/frontier-147/01-result-architect.md
Decisions: none (the choice is a one-way door for the owner; no two-way door decided here)
Open questions: Does "Lean as second theme" mean narrative theme (assumed) or a switchable colour theme?
Missing: none

## Options

### A. Editorial doors (calm, text-first)
Warm off-white page, deep ink text, one terracotta accent; a serif for headings and a clean sans for body; a single readable column (about 70 characters) with generous spacing and a slim side nav. The hook is the home page headline plus a two-part "Agents decide / You decide" split block; each one-way door is marked in the prose by a small, labelled door callout (icon plus words, never colour alone). Lean appears as a quiet recurring "Lean note" aside (andon, waste, flow) in a second, muted accent. Reads like good documentation; lowest density.
Prototype must show: home hero with the hook and split block; one narrative page with a door callout and a Lean note; one generated reference page (a skill) to prove the style holds for dense generated content; the Dutch variant of the hero (longer words); keyboard focus on nav and switcher; light mode only plus reduced-motion check.

### B. Operations board (Lean made visible, denser)
Cooler neutral surfaces, a monospace or tabular accent for labels, and a card-and-lane layout echoing a kanban board: home page shows lanes "Agents do" and "You decide", with doors as pinned cards. Colour carries status (flow, stop-the-line amber for andon) always paired with a text label. Higher density, a persistent left nav and an on-page table of contents. Lean is the visible metaphor, so it is the second theme everywhere, not an aside.
Prototype must show: home with the lane layout and door cards; a page with an andon-style warning; the reference page in table form; narrow-phone layout (lanes stack, nothing scrolls sideways); status never conveyed by colour alone; Dutch hero.

### C. Plain and quick (minimal, dark/light, reference-first)
System fonts only, black-on-white with an automatic dark mode, thin rules instead of cards, almost no decoration; the hook is a single bold sentence over a short list of the doors, then straight into the content. Lean shows as a labelled second section on each plugin page. Fastest to load and cheapest to build, least memorable and least warm.
Prototype must show: home with the single-sentence hook; light and dark rendering of one page (contrast in both); reference page; mobile load without any custom font; Dutch hero.

## Leaning
A. It carries "neutral but warm" best, puts the one-way-door idea first without a metaphor newcomers must learn, and keeps Lean as a second theme in proportion. B is the strongest if the owner wants Lean to be the site's identity; C if speed of delivery beats character.

## Cost to undo (after real pages exist)
- Any option: a rewrite of the layout components and global styles, plus a re-check of contrast and the performance budgets. Content (Markdown, generated reference data, translations) is untouched when it stays free of layout markup.
- A: moderate. Type scale, colour tokens and the callout components change; page structure is kept.
- B: highest. The lane and card layout is baked into page templates and some content (door cards), so a switch touches templates and content shape.
- C: lowest to leave, since little is built; moving up to A or B is a styling and template addition.
- Keep the cost down in all three: colour, type and spacing as CSS custom properties, and doors and Lean notes as named components, so a later change stays a refactor.
