# Result: architect — frontier-53
Status: done
Abnormality: none
Progress:
  Done: read tracker #50, #51, #52, #53, #54, #55, ADRs 0001, 0002, 0006, 0007, 0009, 0013, issue-tracker.md; wrote the options file
  Next: nothing; the lead writes the decision card
Summary: Three doors, three options each, with undo cost in days, my leaning, and the dependencies. Leanings: A1 sub-issue per role task; B1 six values (B2 with a Stage field if A is overturned); C1 path-list overlap. B1 depends on A1; C depends on B for Waiting on you and Blocked; A and C are independent. Points the map text lacks: the path list exists only after the architect stage; version, changelog, glossary and ADR numbers are paths every slice touches; the limit setting 1 is a free retreat for C, so it is nearly a two-way door; the 2.0.0 migration can avoid the undocumented dropped-option behaviour by adding options first, moving items, and dropping last.
Artifacts: work/frontier-53/02-options-architect.md
Decisions:
- Frontier-round role tasks hang under the frontier ticket, not under the map / rejected: directly under the map (nears the 100-child cap) / cost to undo: under 1 day
- Migration runs in three phases (add options keeping ids, re-set items, drop old options) with a snapshot / rejected: overwrite the option list in one call (undocumented effect on items) / cost to undo: none, it is a procedure
- `/factory:run` refuses an unmigrated project via a `factory-state: 2` line in `docs/agents/factory.md` / rejected: run and write an unknown status / cost to undo: under 1 day
- The map's "Factory run" section stays as the run's resume pointer (step, branch, FREEZE) / rejected: remove it with the lead state sections / cost to undo: 1 day
- Overlap rule for C: equal path or directory prefix, plus always-overlapping shared paths (version, changelog, glossary, ADR numbering) / rejected: glob matching (harder to test) / cost to undo: under 1 day
- Role keeps a committed draft result in `work/` while the lead posts the comment / rejected: result only in the comment (a cut-off role loses Progress) / cost to undo: 1 day
Open questions: C may be a two-way door because the limit setting 1 undoes it in minutes; the lead decides whether it still goes on the card (I would keep it: the person asked for it, ADR 0007 states the opposite).
