# Result: architect — frontier-53
Status: done
Abnormality: none
Progress:
  Done: ADRs 0014, 0015, 0016 written; status lines of 0001, 0002, 0007 amended; four terms added to CONTEXT.md (see git log for the commits)
  Next: nothing; the lead reviews and merges the frontier PR
Summary: ADR 0014 (A1: sub-issue per role task, partly replaces 0001), 0015 (B1: six statuses plus Kind and Role, amends 0002), 0016 (C1: parallel slices on non-overlapping path lists, default limit 2, amends 0007 and touches wayfinding's beachhead and resurvey text). Each cites the decision comment, the card comment and the research comments (#51 for A, #52 for B). Each records rejected alternatives, undo cost, and the non-functional targets. 0014 and 0015 state that undoing them after 2.0.0 is a 3.0.0 release; 0016 states that undoing C is not. Two-way decisions listed in the ADRs' "Decided inside, overturnable" sections. Status lines: 0001 "proposed, partly replaced by 0014", 0002 "proposed, amended by 0015", 0007 "proposed, amended by 0016". No contracts, no tracker writes.
Artifacts: docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md, docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md, docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md, docs/adr/0001-factory-roles-talk-through-files.md, docs/adr/0002-one-branch-and-worktree-per-item.md, docs/adr/0007-factory-owns-destination-and-slicing.md, CONTEXT.md
Decisions:
- Role tasks of frontier rounds hang under the frontier ticket / rejected: under the map / cost to undo: under 1 day
- Committed draft result in work/ while the lead posts the comment; commit wins where they differ / rejected: comment only / cost to undo: 1 day
- Map's "Factory run" section stays as resume pointer / rejected: remove it / cost to undo: 1 day
- Three-phase migration with snapshot / rejected: one-call overwrite / cost to undo: none, a procedure
- `factory-state: 2` line makes /factory:run refuse an unmigrated project / rejected: run anyway / cost to undo: under 1 day
- Shared paths (version, CHANGELOG, CONTEXT, ADR number) always overlap; equal-or-prefix rule / rejected: globs / cost to undo: under 1 day
- Status-line wording "proposed, partly replaced by 00NN" and "proposed, amended by 00NN" for amended ADRs (the repo had only "superseded by") / rejected: a new status word / cost to undo: minutes
Open questions: none
