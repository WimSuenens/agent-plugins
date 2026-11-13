# Result: architect — 188
Status: done
Abnormality: none
Progress:
  Done: site-nav-empty exempts the breadcrumb nav in contracts/188-a11y-landmarks.md section 2; paths.sh list contracts/188-*.md exits 0.
  Next: none
Summary: Answer to QA question 04: accept option A. `site-nav-empty` now applies to every `nav[data-nav]` except `nav[data-nav="breadcrumb"]`. The breadcrumb's content stays checked by `site-current-page` (exactly one `aria-current="page"`) and its presence by `site-nav-required`. AC-10, AC-26, AC-27 and contracts/188-wiki-components.md section 3 are unchanged (Home's breadcrumb stays one plain-text item, no link), so no needs-decision. Option B rejected: it contradicts AC-10 ("no links"). The contract's worked-fault table is unchanged (its site-nav-empty row uses the contents nav). Searched the repo for site-nav-empty: only the a11y contract and tests/site/a11y.test.mjs line 151 (contents nav emptied, still fails as expected) state it.
Tests affected in tests/site/: none need a change. tests/site/a11y.test.mjs line 151 still holds. QA may optionally add a case that Home's breadcrumb does not trigger site-nav-empty (the real build exiting 0 already covers it).
Artifacts: contracts/188-a11y-landmarks.md
Decisions: site-nav-empty exempts the breadcrumb nav / rejected: keep a link in Home's breadcrumb (against AC-10) / cost to undo: one table cell in the contract plus the same line in the check script.
Open questions: none
