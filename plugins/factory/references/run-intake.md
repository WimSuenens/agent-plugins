# Run skill: maintenance and idea intake

Read this when a run starts (the maintenance announce line and the intake of ideas) or the person says an idea is waiting. It is part of the run skill; the text below moved out of `skills/run/SKILL.md` unchanged, and the pointer in the router for any heading says which file holds it.

## Maintenance cycle

The factory decides on its own whether a maintenance cycle is opportune. It evaluates concrete signals: backlog empty or nearly empty (at most 1 ready slice), red CI or repeated rework on a path (2 or more), 5 or more merges since the last cycle, an untriaged inbox item older than a run, a known vulnerable dependency. With none present, no cycle runs.

**Announce.** At run start, before intake, state in one line whether maintenance runs and on which signal. Build a snapshot file `{"backlog_ready", "ci", "rework": [{"path", "count"}], "merges_since_cycle", "inbox_aged", "vulnerable_deps"}` from the board, `gh run list` (or the project's CI), the ledger, the merge count since the last cycle's candidates and `intake.sh untriaged`, then run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance.sh" decide <snapshot>` and say its line to the person unchanged.

**The cycle.** When the line says `run`, work through the activities that the signals call for, using the upstream skills for triage, bug diagnosis, architecture improvement, code review and retrospective; those a model cannot invoke are read and followed by hand, as the research and triage skills are. Each activity is done by the role best placed for it, with the lead's brief.

**Candidates only.** Maintenance produces backlog candidates of the maintenance kind and changes no code, file or issue directly. File each result with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance.sh" candidate <cycle> <triage|diagnose|architecture|review|retrospective> <title> <body-file>`; a candidate then goes through the same pipeline as any slice, and the integrator ranks them beside the feature candidates (*The integrator*).

**One-way doors.** A candidate that touches a one-way door is filed with `--one-way-door` and is not executed: it waits for the person as a decision card (step 7).

**The budget.** The per-cycle budget is `maintenance-budget` in `docs/agents/factory.md` (`<N> candidates`, default 10; `maintenance.sh budget`). `maintenance.sh candidate` counts the candidates of the cycle id; exit 7 stops the cycle: file nothing more, say `maintenance budget reached`, and go on to improvement and slice building.

## Idea intake

An **idea** is a tracker issue labelled `idea`: a thought, a reference (URL, document, screenshot) or any input the person or a collaborator wants the factory to weigh. It is filed with `/factory:idea`, directly in the tracker with the label (a collaborator needs no factory for that), or by dropping a file in the **inbox**, the local gitignored folder `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" dir` prints. The ideas are the tracker's; the inbox is only a drop zone.

1. **Drop the inbox.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" drop`. Each file becomes one issue with the label `idea` and is then removed, so the folder never grows; a second run over the same folder creates nothing new. A line `kept <name>: <reason>` (exit 5) is a file the body cannot carry or the scan refused: the file stays. Tell the person the reason; delete nothing yourself.
2. **List the untriaged.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" untriaged`. It prints each open `idea` without an outcome comment as `<n>`, title and `new` or `waiting`. `waiting` is an idea whose decision card is open and not marked `Answered:`: leave it until the person answers; once answered it lists as `new`, and you record its outcome citing the card.
3. **Triage each `new` one.** Read the upstream triage skill and follow it (it cannot be invoked by a model: read `skills/engineering/triage/SKILL.md` of the installed `mattpocock-skills` plugin and apply it by hand), using the map, `CONTEXT.md` and the ADRs as the evidence. Every idea ends with one outcome and a reason, posted as a comment:
   - **direction**: it changes or refines where the project is going; fold it into the map's Destination or Decisions so far (the map is edited at step 4 or by a frontier round). The product-owner also updates the project's direction document `docs/direction.md` (front matter `goal` and `current`, and a `## History` line `- YYYY-MM-DD: what changed` naming the idea) in the same item; the Obeya renders it and never writes it (contract 129-obeya-direction).
   - **slice candidate**: it is a buildable piece of work; it joins the backlog as a candidate for step 4.
   - **research ticket**: the answer is unknown; it becomes a research ticket on the frontier.
   - **parked**: sound, not now; the reason names what would bring it back.
   - **rejected**: not wanted; the reason says why, and the issue is closed as not planned.
4. **One-way doors.** An idea that touches a one-way door is put to the person as a decision card; you do not decide it. Brief it as step 7 does, post the card on the idea (*Decision card*, scanned with `--needs-you`), set its card `Waiting on you`, and post the outcome comment only after the answer, citing the card. Everything else you decide yourself: a two-way triage needs no question.
5. **Record.** Write the reason to a scratch file, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" triage <n> <outcome> <file>`. It scans the text (exit 6 on a hit: rewrite and run again), posts the comment `<!-- factory:triage v1 -->` and, for `rejected`, closes the issue. Never post an outcome without a reason; never leave an idea with no outcome when you end a run's intake.

This section collects and triages; maintenance is *Maintenance cycle*.
