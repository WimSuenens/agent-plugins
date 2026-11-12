# Result: product-owner — 156
Status: done
Abnormality: none
Progress:
  Done: requirement written at docs/requirements/156-live-skeleton.md (27 acceptance criteria, A to E), committed.
  Next: none; the lead sends it to the architect and qa-engineer.
Summary: The requirement turns the frame's Behaviour into 27 Given/When/Then criteria, each testable on the built output, the workflow file or the live site. Every Under test line maps to criteria (table in the file). Pinned the deferred switcher mechanism (localStorage, redirect only when entering at English Home, history replace, no redirect for direct links). Four human-only criteria (look, Dutch naturalness, no flash, screen reader). No one-way door found: base path, stack and look are already locked.
Artifacts: docs/requirements/156-live-skeleton.md
Decisions: switcher storage localStorage / cookie, URL-only rejected / about an hour to undo; redirect only at English Home entry, replacing history / redirect all English pages rejected / small script change; Dutch option on English-only pages goes to Dutch Home / none / one line per page; missing name or description in a SKILL.md fails the build / skip rejected / a minute; expected skill count computed, not hard-coded in tests / none / none; generated reference data not committed / commit it later / about a day.
Open questions: accessibility check tool (architect); one Reference page or one per plugin, and its slug (architect, deferred slug line); the example slug /reference/ in AC-9 is a placeholder.
Missing: none
