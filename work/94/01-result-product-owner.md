# Result: product-owner — 94
Status: done
Abnormality: none
Progress:
  Done: read brief, map #93, sources #87-#90, a3.md, hansei.md; wrote the requirement (committed)
  Next: none
Summary: Requirement docs/requirements/94-lean-extensions.md has 19 acceptance criteria in Given/When/Then in six groups (A3 v2 lines, flow efficiency and per-stage view, target, targeted gemba, v1 compatibility, tests and release). Each of the four Under test lines maps to criteria: Done-when 1 to AC-1, AC-2, AC-11, AC-13; Done-when 2 to AC-6, AC-7, AC-8; Done-when 3 to AC-15, AC-16; Done-when 4 to AC-18, AC-19. Out of scope lists #92, the record schema bump, other plugins, and more. No one-way door found: marker, tag grammar and line formats are all two-way. One real tension is raised for the architect (open question 1): the waste tags live on andons, lead-state findings and ledger waits, none of which the record carries, and the record may not gain a field.
Artifacts: docs/requirements/94-lean-extensions.md
Decisions:
  - waste tags are the eight lowercase TIMWOODS names, untagged `-` / free text, codes / one edit
  - waste line counts tagged entries, shows untagged count / counting items / one edit
  - target comparison inclusive / strict / one edit
  - flow efficiency whole percent, half up / one decimal / one edit
  - v2 marker `<!-- factory:a3 v2 -->` / separate marker / one edit
  - position of the new lines left to the architect, order fixed and checked
Open questions: (owner architect unless noted) 1 where the A3 reads waste tags from; 2 how waits map to stages; 3 exact line grammars; 4 allowed none-reasons for the three new lines; 5 where the settle line change lives; 6 next minor 2.3.0 and fingerprints (developer with devops)
