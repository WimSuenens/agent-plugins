# Contract 156 — Accessibility check on built pages

Issue [#156](https://github.com/WimSuenens/agent-plugins/issues/156) · Requirement AC-20, AC-24, AC-25 · Part of the [site skeleton](156-site-skeleton.md) build

## Paths

Paths:
- apps/site/scripts/a11y-check.mjs
- apps/site/package.json
- apps/site/package-lock.json
- apps/site/test/a11y-args.test.mjs
- tests/site/

shared: none

## 1. Decision: axe-core in a real browser, run by Playwright

The check is `@axe-core/playwright` (axe-core rules) driving headless Chromium from the `playwright` package, both `devDependencies`. It runs against the built pages served from the build output, not against source.

Why: AC-20 needs contrast computed on rendered pages. axe's `color-contrast` rule needs real layout and computed styles, which a DOM emulation (jsdom) cannot give. Rejected:

- **axe-core with jsdom**: no layout, so `color-contrast` is skipped (reported "incomplete"), which would pass a contrast regression.
- **pa11y-ci**: also a Chromium run (puppeteer) with the same axe engine, plus its own config and server handling; one more tool for no extra check. Its HTML CodeSniffer runner is noisier.
- **Lighthouse CI**: a score threshold, not a per-fault failure naming the page and the fault; heavier; it also bundles the performance budget that is deferred.
- **A token-only contrast calculation**: does not see the rendered pairs (AC-20 says not only the token list). QA adds a token-level check of its own; this check is the rendered one.

Two-way door: the tool sits behind one script with a fixed command line and output (section 2). Swapping it means rewriting one file. Cost to undo: about a day.

## 2. Seam: `scripts/a11y-check.mjs`

```
node scripts/a11y-check.mjs [--dist <dir>] [--base <path>]
```

- `--dist` default `$SITE_OUT_DIR` or `dist`. `--base` default `$SITE_BASE` or `/agent-plugins`. These are the only options; an unknown option is exit 2.
- It collects every `*.html` file under `--dist` (recursive; dotfiles ignored), starts a static server of its own on port 0 that serves `--dist` under `--base` (a request outside the base is 404), opens each page in Chromium at 1280x800 with `prefers-reduced-motion` unset and scripts enabled, waits for load, and runs axe with the tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa` and `best-practice`, with the `color-contrast` rule enabled. The page URL is the route under the base (`/agent-plugins/nl/`).
- A page that redirects away from its own URL during the run (the language script) is a failure of the check's own setup: the check runs with an empty `localStorage`, so no redirect happens; a final URL different from the requested one is reported as `a11y: ERROR <route> navigated to <url>` and exit 2.
- It stops its server and browser before it exits, on every path.

Output (stdout lines, in page order then rule order):

```
a11y: FAIL <route> <rule-id> (<impact>) <help text> :: <css selector of the node>
a11y: <n> pages checked, <m> violations
```

One `FAIL` line per violating node. Violations are axe `violations` only. `incomplete` results for `color-contrast` are printed as `a11y: WARN <route> color-contrast could not be decided :: <selector>` and count as violations too (an undecided contrast must not pass silently); other incomplete results are not printed.

Exit status: `0` no violations; `1` at least one violation; `2` usage error, no `*.html` under `--dist`, `--dist` missing, Chromium not installed (message says to run `npx playwright install chromium`), or a navigation error. Never `0` on an empty set.

Output holds routes and selectors only: no absolute path, no home directory.

## 3. Worked example

Good build: `node scripts/a11y-check.mjs --dist dist` prints

```
a11y: 3 pages checked, 0 violations
```

and exits 0.

A copy of the build in which `nl/index.html` has `<img src="x.png">` added and the body text colour changed to `#bbbbbb` on white exits 1 and prints, among others,

```
a11y: FAIL /agent-plugins/nl/ image-alt (critical) Images must have alternative text :: img
a11y: FAIL /agent-plugins/nl/ color-contrast (serious) Elements must meet minimum color contrast ratio thresholds :: p
a11y: 3 pages checked, 2 violations
```

## 4. Behaviour QA can test

- Real build: `npm run build` exits 0 and the last line reads `a11y: 3 pages checked, 0 violations`; the page count is the count of `*.html` files in the output (AC-24).
- Fault copies (AC-25): copy the output folder to a scratch folder, add a fault to one page (an image without `alt`; text below 4.5:1), run `node scripts/a11y-check.mjs --dist <copy>`: exit 1, a `FAIL` line names the route and the rule id. The unfaulted original still exits 0.
- `--dist` on an empty folder: exit 2.
- `package.json` `build` equals `astro build && node scripts/a11y-check.mjs --dist ${SITE_OUT_DIR:-dist}` (or an equivalent that propagates the exit status): a failed check fails the build command (AC-24).
- The workflow's build step is `npm run build` and the deploy job needs it ([deploy workflow](156-deploy-workflow.md)).

## 5. Needs real infrastructure

Chromium. Locally: `npx playwright install chromium` once. In CI: `npx playwright install --with-deps chromium` before the build. No network access beyond the install; the check serves the pages itself, on a free port, bound to `127.0.0.1`.

## 6. Acceptance criteria map

AC-20 (rendered contrast, section 2), AC-24 (section 2, 4), AC-25 (sections 2, 3, 4).
