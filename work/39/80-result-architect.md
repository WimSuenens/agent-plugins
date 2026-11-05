# Result: architect — 39
Status: done
Progress:
  Done: ADR 0013 Consequences reworded (023a7d4)
  Next: none
Summary: ADR 0013's "For #39, accepted knowingly" bullet no longer cites work/ paths. It now names the two files as "two of item #39's message files (the QA brief, and the architect's options file, which quotes it), both in the PR's history" and points to security finding L14 in reviews/security-39.md (final round), which names the two commits that add them. Wording only; no other line of the ADR changed. grep finds no `work/39` path and no absolute home path left in the ADR (the generic `work/<id>/` folder pattern stays, since it names the folder convention, not a file).
Artifacts: docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md
Decisions: Cite the review file (reviews/security-39.md, L14) rather than a tracker comment / rejected: tracker comment link / cost to undo: one-line edit. The review file lands on main, so the citation resolves without the tracker.
Open questions: none
