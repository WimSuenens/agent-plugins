# Contract 188 — Accessibility check: landmark and navigation rules on every page

Issue [#188](https://github.com/WimSuenens/agent-plugins/issues/188) · Requirement AC-9, AC-26, AC-27 · Extends [156 accessibility check](156-a11y-check.md) (its command line, output format, exit codes, server and tool choice stay) · Siblings: [page tree](188-page-tree.md), [wiki components](188-wiki-components.md)

## Paths

Paths:
- apps/site/scripts/a11y-check.mjs
- apps/site/test/a11y-args.test.mjs
- apps/site/test/a11y-landmarks.test.mjs
- tests/site/
shared: none

The scripts in `package.json` are unchanged (the dependency line is added under the wiki-components contract): `npm run build` still ends with the check. No `.github/` path changes.

## 1. Decision (open question 4): axe's landmark rules stay on, plus five own checks

The run already uses the tags `best-practice`, `wcag2a` and `wcag2aa`, which switch on axe's `landmark-one-main`, `landmark-no-duplicate-main`, `landmark-unique` (two landmarks of one role with the same name), `region`, `html-has-lang` and `scrollable-region-focusable`. Nothing is added to the axe call. Axe cannot say that a page lacks the breadcrumb, that one lone `nav` has no name, or that the tree has no current entry, so the script gains DOM checks, run in the same browser page after axe, on the same page load.

Rejected: a second tool or a parse of the HTML text (the browser already holds the real DOM and the accessible name, which `aria-label`/`aria-labelledby` resolve in the browser, not in a regular expression); asserting the localised names ("Pages", "Breadcrumb") in the script (the check would then need both languages' strings and a change per new language: it reads the stable `data-nav` hooks instead). Two-way door: one file; cost to undo: hours.

## 2. The own checks

Run on every page found under `--dist` (the set is computed from the output, never listed: AC-26). Each fault prints the 156 line format, with the rule ids below, impact `serious`, and counts as one violation per fault:

```
a11y: FAIL <route> <rule-id> (serious) <help text> :: <selector or "page">
```

| Rule id | Fails when | Help text |
|---|---|---|
| `site-main-count` | the number of `main` elements is not 1 | `Page must have exactly one main landmark` |
| `site-nav-required` | any of `nav[data-nav="site"]`, `nav[data-nav="language"]`, `nav[data-nav="pages"]`, `nav[data-nav="breadcrumb"]` is missing or occurs more than once | `Required navigation landmark missing or repeated: <name>` (`<name>` is the `data-nav` value) |
| `site-nav-name` | a `nav` has an empty or absent accessible name (its `aria-label` or the text of its `aria-labelledby` target, trimmed) | `Navigation landmark must have an accessible name` |
| `site-nav-unique` | two `nav` elements of the page share one accessible name (case-insensitive, trimmed) | `Navigation landmarks must have distinct names` |
| `site-nav-empty` | a `nav[data-nav]` other than `nav[data-nav="breadcrumb"]` holds no `a[href]` (the breadcrumb is exempt: Home's breadcrumb is one plain-text item with no link, AC-10; its content is checked by `site-current-page`, which wants exactly one current item) | `Navigation landmark must not be empty` |
| `site-current-page` | `nav[data-nav="pages"]` holds a number of `[aria-current="page"]` other than 1, or `nav[data-nav="breadcrumb"]` holds a number other than 1 | `Navigation must mark exactly one current page` |

`nav[data-nav="contents"]` and `nav[data-nav="see-also"]` are optional (absent when empty), but when present are covered by `site-nav-name`, `site-nav-unique` and `site-nav-empty`. The language switcher's own `aria-current="true"` is not counted by `site-current-page` (it is a different value on a different nav).

The check also still fails for any axe violation and for an undecidable `color-contrast`, as in 156. `site-main-count` can overlap axe's `landmark-one-main`; both lines may print for one fault (accepted: each names the page and the fault). Output holds routes and selectors only, no absolute path.

## 3. Behaviour QA can test (AC-26, AC-27)

- Real build, `npm run build`: exit 0; last line `a11y: <n> pages checked, 0 violations` where `<n>` is the count of `*.html` files in the output (5 for the real site: English Home, Getting started, Reference; Dutch Home, Getting started). The number is not written in the script: a fixture that adds a page raises it by one (AC-2 and AC-26 together).
- Fault copies of the built output (copy the folder to a scratch place, edit one page, run `node scripts/a11y-check.mjs --dist <copy>`); each exits 1 and names the route and the rule id, and the unfaulted original exits 0:

| Edit to one page | Expected line (route is the edited page) |
|---|---|
| remove the `aria-label` of `nav[data-nav="pages"]` | `site-nav-name` |
| give `nav[data-nav="breadcrumb"]` the same `aria-label` as the pages `nav` | `site-nav-unique` |
| delete `nav[data-nav="breadcrumb"]` | `site-nav-required` |
| change `<main` to `<div` (and its closing tag) | `site-main-count` |
| remove `aria-current="page"` from the tree's entry | `site-current-page` |
| remove every `a` from `nav[data-nav="contents"]` | `site-nav-empty` |

- Usage errors, exit 2 cases and the empty-set rule are those of 156 and do not change.

## 4. Worked example

A copy of `nl/getting-started/index.html` with the tree's `aria-label="Pagina's"` removed:

```
a11y: FAIL /agent-plugins/nl/getting-started/ site-nav-name (serious) Navigation landmark must have an accessible name :: nav[data-nav="pages"]
a11y: 5 pages checked, 1 violations
```

exit status 1. The real build prints `a11y: 5 pages checked, 0 violations`, exit 0.

## 5. Acceptance criteria map

| Criteria | Where |
|---|---|
| AC-9 (landmarks, one `main`, distinct names) | sections 1, 2 (with [components](188-wiki-components.md) section 7 for the markup) |
| AC-26 | section 3 (computed count, both languages, added pages) |
| AC-27 | sections 2, 3 |

## 6. Things in the repo that state a changed rule

`grep -rn` found: `contracts/156-a11y-check.md` section 4 states "the last line reads `a11y: 3 pages checked, 0 violations`" and section 3's worked example uses 3 pages; both become `<n>` computed from the output (5 after this slice); `tests/site/a11y.test.mjs` asserts three pages (QA's to update).
