# Foundations: defaults and their mechanisms

Two-way-door defaults for `design-system` step 3. A direction brief overrides any of them. State every chosen value in the spec with its mechanism; the user adjusts afterwards.

## Colour

- **Roles, not swatches.** Define semantic roles: `bg` (page), `surface` (card, sheet), `text`, `text-muted`, `border`, `accent` (the one primary action/selection colour), `focus`, and status `success` / `warning` / `danger` / `info`. Each role has one job. *Mechanism:* similarity — one colour, one meaning.
- **Muted neutrals carry the UI; the accent is spent rarely** — the primary action, the current selection, the focus ring. *Mechanism:* pop-out, Von Restorff.
- **Neutral ramp**: ~9–11 steps from `bg` to `text`, slightly tinted toward the accent hue rather than pure grey.
- **Dark theme** (if chosen): re-pick values per role, never invert. Surfaces get lighter with elevation; reduce saturation of the accent and status colours.
- **Contrast pairs to measure** with `scripts/contrast.py`:
  - `text` and `text-muted` on `bg` and on every `surface` → ≥ 4.5:1
  - `accent` text-on-fill (button label on accent) → ≥ 4.5:1
  - `border` of inputs, `focus` ring, meaningful icons on their background → ≥ 3:1
  - every status colour used as text → ≥ 4.5:1; as an icon/fill → ≥ 3:1
- **Status never colour-only**: pair with an icon or text.

## Type

- **One family**; add a second only with one stated job (e.g. tabular numerals, display headings). *Mechanism:* fewer varying dimensions, each variation means more.
- **Scale**: ratio 1.2 (dense UI) to 1.25 (content-led), base 16 px on web; round to whole pixels. 5–7 steps cover most products: caption, body-sm, body, title-sm, title, heading, display.
- **Weights**: two or three (regular, medium/semibold, bold), each locked to roles.
- **Line height**: ≈1.5 for body, 1.2–1.3 for headings; tighter as size grows.
- **Line length**: cap reading text at ≈45–75 characters (`max-width` in `ch`).
- **Letter-spacing**: +0.04–0.08 em on small uppercase labels; slightly negative on large display sizes.
- Body text must survive WCAG 1.4.12 overrides (line height 1.5, letter spacing 0.12 em) without clipping: no fixed heights on text containers.

## Space and layout

- **Spacing scale** on a 4 px base: 4, 8, 12, 16, 24, 32, 48, 64, 96. Gaps inside a group are at least one step smaller than gaps between groups. *Mechanism:* proximity.
- **Grid**: 4 columns mobile, 8 tablet, 12 desktop; one page margin per breakpoint (e.g. 16 / 24 / 32) applied everywhere. *Mechanism:* continuity; consistency drives credibility.
- **Breakpoints**: content-driven; a common start is 640 / 1024 / 1440.
- **Touch targets**: ≥ 44×44 px for primary controls, never below 24×24 (WCAG 2.5.8). *Mechanism:* Fitts.

## Shape and elevation

- **Radius**: one small scale (e.g. 4 / 8 / 16 / full), assigned by role (input, card, sheet, pill). Nested radii: inner = outer − padding.
- **Elevation**: 3–4 levels (flat, raised, overlay, modal), each with one recipe, used for meaning (what floats above what), not decoration. Prefer spacing and a subtle surface tint over shadows for grouping. *Mechanism:* common region and figure–ground are strong cues, so spend them sparingly.

## Motion

- **Durations**: ~100 ms for feedback (press, toggle), 150–250 ms for small transitions, 250–400 ms for large surfaces (sheets, page transitions). *Mechanism:* response-time bands — acknowledge within ~100 ms.
- **Easing**: ease-out for entering, ease-in for leaving, one standard curve for everything else.
- **Purpose only**: motion explains change (where something came from or went). No ambient loops unless a direction brief names them.
- **Reduced motion**: under `prefers-reduced-motion`, transforms and parallax become fades or instant changes.

## Iconography

- One set, one stroke weight, one filled-vs-outline logic (e.g. outline default, filled for selected). Sizes on the spacing scale (16 / 20 / 24). Icons with meaning ≥ 3:1 contrast; icon-only buttons carry an accessible name.
