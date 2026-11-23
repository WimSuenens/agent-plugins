# Result: product-owner — 244
Status: done
Abnormality: none
Progress:
  Done: requirement written, two stale lines in 188 rewritten (this commit)
  Next: none
Summary: Requirement 244-inline-names-check.md has 10 criteria (inline command, inline install target, docs/agents path, a control per rule, both languages and later pages, current pages pass with no exception list, code blocks identical to before, no false alarm on look-alike tokens, failure names page and token, path rule reads skills not a list). Both Under test lines are mapped in a table. Lines 203 and 212 of 188 now say names and paths are checked and only behaviour claims (#245) stay with a reviewer.
Artifacts: docs/requirements/244-inline-names-check.md; docs/requirements/188-wiki-shell.md
Decisions: path truth source is SKILL.md text, not the file system / rejected: check docs/agents/ in this repo / undo an hour; path rule covers docs/agents/*.md only / rejected all docs and plugins paths / undo an hour; reuse AC-19 patterns so "identical" is testable / none / none; real drift on a current page is fixed, never excused / rejected: exception list / a page edit
Open questions: 1. Token source, raw Markdown or rendered HTML, and edge cases (span in link text, escaped or double backticks). Owner: architect. 2. Check beside AC-19 or in its own test file. Owner: architect.
