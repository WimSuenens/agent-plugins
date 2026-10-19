# Core components and states

For `design-system` step 4. Specify each component's anatomy, sizes, and **every state** below; a state left unspecified gets invented inconsistently on every screen.

## Universal states

Every interactive component specifies: **default, hover, focus-visible, active/pressed, disabled**. Add the component-specific states listed below.

- **Focus-visible**: a ring in the `focus` role, ≥ 3:1 against its surroundings, never removed without a replacement.
- **Disabled**: reduced emphasis but still legible; explain *why* nearby when the reason isn't obvious (a disabled button with no reason is a dead end).
- **Pressed**: visible within ~100 ms (response-time bands).

## Components

| Component | Specific states / variants | Rules and mechanism |
|---|---|---|
| **Button** | primary, secondary, tertiary/ghost, destructive; loading | One primary per view (Von Restorff). Sentence case. Loading keeps its width. Label states the outcome, and the cost when there is one. ≥ 44 px tall on touch (Fitts). |
| **Text input** | filled, error, success, read-only | Visible label always (WCAG 1.3.1); helper and error text directly below (split attention). Error says what to do, not just what's wrong. Input border ≥ 3:1. |
| **Select / combobox** | open, selected, no results | A sensible default where one exists (defaults); searchable past ~10 options (Hick). |
| **Checkbox / radio / switch** | checked, indeterminate (checkbox) | Whole label is the target (Fitts). Consent boxes start unchecked (preselection is a dark pattern). Switch = immediate effect; checkbox = applied on submit. |
| **Segmented control / chips** | selected | For 2–5 mutually exclusive presets; presets from real usage data (defaults). |
| **Stepper** | min, max | Pair with presets for common values; show the unit inside the control. |
| **Card** | interactive (hover/pressed), selected | Grouping by spacing and surface tint before borders and shadows (common region used sparingly). Must survive any image and any text length. |
| **Badge / tag** | status variants | Shortest copy; colour plus text (WCAG 1.4.1); rare enough to stay distinctive. |
| **Navigation bar / tab bar** | current, with badge | Current location always visible (working memory); 3–5 tab-bar items, most important at the ends (serial position). Follow platform conventions (Jakob's law). |
| **Sheet / modal / dialog** | open, dismissing | Equal-weight, neutral dismiss (symmetric exit). Focus trapped inside, returned on close. Destructive confirms name the object ("Delete 3 projects"). |
| **Toast / inline feedback** | success, error, with action | Confirms every async result; errors persist until dismissed or resolved. Never covers the primary action or focus (WCAG 2.4.11). |
| **Progress (bar, steps, checklist)** | determinate, indeterminate, complete | Credits real completed steps (goal gradient); determinate past ~1 s where possible (response-time bands). |
| **Empty state** | first-use, no-results, error | One primary action; shows what value will appear (reciprocity, commitment). |
| **Sticky action bar** | hidden, visible, with keyboard open | Holds the primary action (and its controls, e.g. quantity) on long mobile pages (Fitts, proximity). Safe-area aware; never covers the focused element (WCAG 2.4.11). |
| **Image scrim / icon chip** | — | Behind any icon or text over a photo; measured with `contrast.py --over` against the lightest and darkest catalogue images (figure–ground, WCAG 1.4.11). |
| **Skeleton / loading** | — | Matches final layout to avoid shift; replaced by content or an error, never left spinning. |
