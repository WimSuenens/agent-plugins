# Contract 133 — Obeya theme: The Wall

Issue [#133](https://github.com/WimSuenens/agent-plugins/issues/133) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · builds on [contract 127](127-obeya-themes.md)

Paths:
- apps/obeya/app/themes/wall/
- apps/obeya/test/wall-theme.test.mjs
- apps/obeya/test/wall-source.mjs

The Wall is the physical Obeya room on screen: cork, whiteboard, sticky notes, index cards and an andon light tower. It is the folder `app/themes/wall/` and is chosen by the cookie `obeya-theme=wall`. It presents the `view` prop and nothing else (contract 127 section 1).

## Behaviour

- Every view renders: lens badge, needs-you slot (first), direction (goal, heading arrow, history), andon, factory line, decisions made, pending decisions, intake tray and the parse-failure card.
- Provenance (merged, `in flight: <item>`, event) is a tag on every object.
- Board notes are `<details>`: click or keyboard to open. Blocked notes carry a BLOCKED stamp and name the blocker. The waiting-on-you column is outlined and its notes carry a "Needs you" flag.
- The andon tower has `data-test="andon-light"` and `data-state` `red` (an andon is open) or `green`, always with a text label.
- A Done column of more than 6 notes folds into one stack (`data-test="done-stack"`); more than 8 decisions fold into a card box (`data-test="adr-stack"`). Folded notes stay in the page. Long lists scroll inside their box.
- No runtime network access: system font stacks only, no remote CSS, fonts or images. Handwriting fonts are headings only; body text is the system sans.
- The only animation is the red lamp's pulse, off under `prefers-reduced-motion: reduce`; status is also shown by text.
- Single column at 40 rem and narrower.
