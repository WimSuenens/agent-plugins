# Result: architect — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (author WimSuenens, marker architect 1); contract 286-run-timing and glossary (5bc7b03); contracts 286-a3-v4-and-runs and 286-release (4f3c6b0); paths.sh list exit 0 on all three; role file consolidated
  Next: none (lead reads this result; QA writes tests from the three contracts)
Summary:
- Three contracts: run timing (`started:` on every path, the Run waits table, `run-state.sh` add-session, add-run-wait and lead-sessions, the new `run-timing.sh` gaps and line); A3 v4, its check and the baseline Runs section; release 3.10.0 with the pins that move, the stale-text search and the criterion map.
- Q2: an item is in flight from its ledger's `started:` to its last `approval` touch, or to the close when it has none. Both instants are in the ledger, so AC-C6 can be counted by hand after the merge.
- Q3: Lead gaps are split by the item windows. Inside a window they stay in the ledger (item close scan, unchanged); outside every window they become Run waits rows. The computation reads each source only for its own minutes, so no minute counts twice.
- Q4: Runs guardrails come from the A3's `guardrails` line only. First-pass yield is item counts (R2) and rework is per-item values (R1), so AC-C3 holds as written.
- Q5: a script, `run-timing.sh`. The AC-B6 fixture is written out as files in the contract, with its expected line and five controls.
- Release class quoted (`needs: minor bump (standard work), 3.9.1 -> 3.10.0`). No new one-way door was found, so there is no question to the lead.
Artifacts: contracts/286-run-timing.md, contracts/286-a3-v4-and-runs.md, contracts/286-release.md, CONTEXT.md, docs/agents/roles/architect.md
Decisions:
- The run's Lead transcripts come from a new `lead sessions:` line in the Factory run section, filled from `Session: ${CLAUDE_SESSION_ID}` in SKILL.md, or from the first role transcript path when that is not substituted / rejected: scanning every session transcript of the project (catches unrelated sessions) / cost to undo: one line, one subcommand, one procedure step.
- Run waits kinds are the four block kinds only and `Agent` is always `lead` / rejected: allowing `andon` rows / cost to undo: one kind in `add-run-wait` and one table line.
- Under `--lite`, `stalled`, `interrupted` and `adjusted` read `not captured (lite)` while raw, person and limits are measured; a whole-line `not captured` is kept for missing inputs / rejected: all-or-nothing under lite (no run timing at all for lite projects) / cost to undo: the a3-check grammar and the Runs `m not captured` rule.
- The run-close scan runs `cut-offs.sh` without `--since`, and `gaps` clips to the run window / rejected: `--since started` (it drops a gap that began before the run) / cost to undo: one flag.
- The `run timing` line is computed at a close stamp, then recomputed with the A3's `created_at` and edited only when it differs; Run waits rows are not rewritten / rejected: posting first and then computing (the A3 would be posted without the line) / cost to undo: one procedure step.
- `a3-check.sh` checks the arithmetic of `run timing` (sum ≤ raw, adjusted = raw − sum, adjusted not captured exactly when a kind is) / rejected: grammar only / cost to undo: four rows of the refusal table.
- Guardrails grammar: `first-pass yield <p> of <n> items passed first time[, <c> not captured]; rework per item <v1>, … (<k> of <n> items[, <m> not captured])` / rejected: per-run percentages or rework totals (they cannot be pooled over items as ADR 0026 asks) / cost to undo: A3 v5 plus a reader for v4 (the form is posted with the first v4 A3).
- `run compared` forms 2 and 3 are given an exact grammar now (checked, not exercised), and `none` takes two reasons (`no run with discipline off in series <M.N>`, `run timing not captured`) / rejected: leaving them to the next slice / cost to undo: the a3-check table.
- Runs halves: always both headings at the end of every series block; an empty half reads `- none (no run in series)`; not-counted entries `run stopped #<map> <url>` and `run timing not captured (\`<reason>\`) #<map> <url>` / rejected: Runs before the sections (moves the existing text) / cost to undo: one template edit and the replay tool.
Open questions:
- Known limit, not a door: ADR 0025 writes a `person` Run waits row from question to answer. A frontier-round card answered while a frontier role task still works is counted as blocked even though the run moved. Trigger: the first run whose Run waits person row overlaps a working frontier role task. The fix would be a writing rule (start the row when the last role task ends), which is a two-way door.
- For QA: the router plus references size cap (`test_slice3_table.sh`, 158,000 bytes, 156,445 today) must rise. The router cap of 70,000 must not (65,898 today).
Missing: none
