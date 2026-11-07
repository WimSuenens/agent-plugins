# Result: architect — 64
Status: done
Abnormality: none
Progress:
  Done: finding 1 (project id source) and finding 2 (split join wording) amended in contracts
  Next: none
Summary: contracts/64-board-script.md now has --project-id on all three commands, the Tracker-table fallback (only when owner and project number match), plan skipping B-views, apply and finish exiting 2 with `board: project id unknown`, and an offline check row. contracts/64-role-tasks.md section 6 now defines the details body and the join (line for line; over-long line cut gives one newline per cut). Read post-text.sh split: it meets the wording, including the cut-line case, so no developer finding. No new gh operation.
Artifacts: contracts/64-board-script.md, contracts/64-role-tasks.md
Decisions: join wording relaxed to line-for-line (byte-exact would need a no-newline cut marker; chosen: matches build / rejected: byte-exact / cost to undo: one sentence plus a split change)
Open questions: none
