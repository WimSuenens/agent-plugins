# Result: architect — 57
Status: done
Abnormality: none
Progress:
  Done: contracts written and committed (`#57 architect: contracts for the baseline issue, A3, run close, records and overrides; glossary terms`); one wording fix committed after it
  Next: none; waits for the lead (open questions below), then the developer builds from the contracts
Summary: Five contracts, `contracts/57-*.md`, each with a worked example. 57-records-and-overrides: hansei v4 (an extent per override: whole item, from, until), the `overrides at start` label line, the experiment's override lines, the Factory run lines. 57-baseline: find/create/pin rule and commands, record reading, the exact rule text for AC-3 and AC-5, the section and reference rules for AC-6, the body layout, update and repair. 57-a3: marker `factory:a3 v1`, template, place (the map issue), the exact rule text for AC-11, AC-14, AC-15 and the experiment. 57-run-close: step 9 rewritten as the one close (update, A3, settle, feedback offer, report), step 10 removed, new 8.10, the stopped-run yes, the settle lines, promote to a card, step 9.4 shrunk. 57-standard-changes: release 1.2.0 (developer edits `plugin.json`, the Lead tags at *Merge PR*), fingerprint effect (standard moves, tooling does not), paths per file, the AC-26 exception, every AC mapped, 18 decisions. No script is added. No one-way door found, so no ADR. CONTEXT.md: Baseline reworded; Series, A3, Countermeasure experiment added, each with the honesty-rule line.
Artifacts: contracts/57-records-and-overrides.md, contracts/57-baseline.md, contracts/57-a3.md, contracts/57-run-close.md, contracts/57-standard-changes.md, CONTEXT.md
Decisions: (all two-way; full text with rejected options in contracts/57-standard-changes.md §7)
  D1 experiment measures limited to 1, 3, 5, 6 / measures 2, 4, 7 / widen a table.
  D2 baseline = one issue body / comments per section, a repo file, a store / move to comments; trigger body over 50,000 characters.
  D3 find by exact title and the Lead's author, pin best-effort and never read / find by pin / one rule.
  D4 hansei v4 with an extent per override, v3 and v4 read, v1 and v2 skipped / infer from dates, read v3 lists as whole-item / bump to v5.
  D5 `overrides at start` in the label / stage-log note / move a line.
  D6 after-items = the run's items; a kept override's later items live in the baseline / count across runs / one rule.
  D7 run list `closed in this run` in the map's Factory run section / read membership from tickets or dates / one line.
  D8 A3 on the map issue / last slice ticket, baseline issue / move the marker's home.
  D9 reference section keyed by the overrides adopted on main; only drops read from A3 answers / all answers from the A3 / change the key's source.
  D10 problem by counted targets, applied when the countermeasure is written and at close only to list others / re-choose at close / one rule.
  D11 measure-branch candidates above 1 listed, the rest counted / list all / print them.
  D12 run close is step 9, step 10 removed, update at 8.10 / renumber to 10 or 11 / reorder text.
  D13 update note in the map's Factory run section (the stage log is gone at 8.6) / stage log / move a note.
  D14 settle worktree as a third place, `work/settle-<map>/` / main checkout, Lead-written card / one protocol bullet.
  D15 tracker commands in the setup skill's template with the run skill's fallback / commands in references/baseline.md / move bullets.
  D16 release 1.2.0 minor / patch, major / change a string before the tag.
  D17 no script; hooks/scripts line stays open on the map; trigger = first slice that changes scripts/ or hooks/ / aggregator script / add one script.
  D18 outcome fields as counts, not-captured entry `not captured <m> (<m> of <n> items: …)`, doors count Under test lines / sum doors to n / one rule.
Open questions: (none block the build; the first four are for the requirement's owner, via the lead)
  1. AC-3 doors: "summing to n" cannot hold with `doors confirmed 2` for one item. Settled by D18 (doors count lines).
  2. AC-3 acceptance demo: `not captured 1` (S5 alone) and `not captured (2 of 2 items: …)` (S5, S5b) are written by one rule, `not captured <m> (<m> of <n> items: …)`; `<k=0>` is read as the condition, with m of n written.
  3. AC-7 says the update note goes in "the stage log's notes", but the stage log is removed at step 8.6, before the update at 8.10. Placed in the map's Factory run section (D13). Overturn in feedback if the person wants it elsewhere.
  4. AC-11, AC-12, AC-13, AC-16, AC-20 wording differences (silent none, `experiment:` line keyed `countermeasure`, first field line versus marker, two extra A3 lines) are listed in contracts/57-standard-changes.md §8.
  5. AC-26 exception to name for the person: `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (the tracker commands). Other path beyond the requirement's list of examples: `references/protocol.md` gets one bullet (settle worktree).
  6. Lead: item #57 runs on the frozen install, so the tag `factory-v1.2.0` is made by hand at merge as for #39 and #49; no baseline issue is created in agent-plugins by this item (AC-27).
  7. QA's fixtures must state the session's release (AC-2, AC-5 depend on the current series).
