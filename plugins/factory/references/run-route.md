# Run skill: sizing, the plan and the route

Read this when the destination is confirmed, a slice is cut, the plan's route is direct, the work reveals something the sizing missed, or the plan is in the Heavy band. It is part of the run skill; the router names the moments. Here `${CLAUDE_PLUGIN_ROOT}` is not substituted (only the router is): read it as the path on the `Plugin root:` line of `skills/run/SKILL.md`, and write that path in every shell command.

## Sizing

Size right after the person confirmed the four fields of step 1, before any map exists. The destination ticket is the issue the idea came from; when the run starts without one, file one from the four fields (scanned first, *Scan before posting*) and use its number everywhere below. In the map route the plan stays on that ticket, and the map of step 2 is created afterwards. The points table is the project's own: print it with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/factory-config.sh" table` (its rows, points, bands and floor are not repeated anywhere in this plugin). Decide from the four fields, from what you can see in the project and from what the person said which rows fire, and name them. When you cannot tell whether a row fires, count it: the plan may scale down only at the next slice, and up at any time.

Then run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/flow-size.sh" "<row>" "<row>" ...` (a whole row name, or a prefix that picks one row; no name is the lightest path). It prints the points, the band, the bands line it used, the steps each fired row adds, the route (`map` when a fired row adds a map, otherwise `direct`) and who is asked. It refuses a name that is not a row. It reads the route and the question to the person from the table's Adds column: a row that adds a map says `map` in its Adds, and a row that does not never uses the word; a row that stays with the person says `stays with the person`. The sizing reports; it never removes a step the table's `floor:` keeps, and one-way doors stay with the person.

A change of the table's bands applies to new sizings only: the plan records the bands line it was sized under, and an older plan is never re-banded.

## The plan

Write the plan as one comment on the destination ticket (a slice: on the slice ticket), scanned first (*Scan before posting*), and run it without waiting. The newest plan comment is the plan: a changed plan is a new comment, never an edit of an old one. The fields, one `- <field>: <value>` line each:

```
## Plan
- route: direct | map
- role path: standard
- test depth: standard
- triggers: <row> (+<points>), ... | none
- points: <sum>
- band: <name>
- bands: <the bands line used>
- reason: <why this route, in one sentence>
- release: factory <version that is running>
- expected slices: <the expected sequence, one clause each>
- first slice leaves out: <what the first slice deliberately leaves out, naming the part of any approved ADR> | none
```

`role path` and `test depth` read `standard` and are not variable yet. Check the plan with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/plan-check.sh" <plan file> --table docs/agents/factory.md`: it refuses a missing field, points that are not the sum, a band that is not the one the plan's own bands line gives, and a route that is not the table's.

**Who is asked.** The person is asked on an open one-way door (a decision card, step 7, as always) and in the Heavy band (*Heavy band*). Nothing else in the plan waits for the person. Within a slice you may scale up (a row fires that you had not counted: write the changed plan, say so in the stage summary). You scale down, and change the route to a lighter one, only at the next slice.

**Before the first slice is built** (decision 16). `plan-check.sh` prints `tell the person in the stage summary: the first slice leaves out: ...` when the plan names something. Put that line in the stage summary before the first slice's developer starts. Every element of an approved ADR that the first slice leaves out is named there, so the frame cannot contradict an approved ADR unseen. The person's answer is feedback; if it changes the frame, change the slice, not the ADR (an ADR changes only through a decision card).

## The direct route

The route is `direct` when no fired row adds a map. There is no map and no frontier round: steps 2 and 3 do not run, and the wayfinding skills are not read.

1. **Run identity.** The destination ticket is the run ticket (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/run-state.sh" ticket --route direct --destination <n>`). Write the **Factory run** section of step 2 at the top of its body; wherever this skill or a reference says the map's Factory run section, or says the map identifies the run, read the run ticket's. `run-state.sh <started|closed|items|baseline|step|in-flight|freeze|hansei> <body file>` reads that section from either body, and `intake.sh filed-since --run-body` and `a3-events.sh --run-body` take the body instead of a time you copied by hand.
2. **One-way doors.** Each open one-way door goes to the person as a decision card (step 7): the product owner writes it, and a prototype is built for the person when the door is visual. The decisions land as ADRs in one PR from a worktree made with `worktree.sh add frontier <destination>`, approved as the PR of step 3's end is (fence F1 is unchanged), before the first slice that rests on them is built.
3. **Slices.** Cut each slice straight from the destination's **Done when**, as step 4's *No one-way doors* paragraph does (the four-part frame, **Under test** taken from the Done-when outcomes), without `/wayfinding:beachhead`. Take the order from `start-gate.sh` (`order:`), which prints the integrator's advice; the integrator advises and does not choose the route.
4. **The board.** Slice tickets are added as in step 4. The destination ticket gets no map card.

## Escalation

When work reveals a one-way door, a failed assumption or an unknown the sizing missed, stop starting slices (roles in hand finish their step) and chart a map for what is now foggy: invoke `/wayfinding:wayfinder` with the destination and the finding. Say it to the person in one line: `Escalated to a map: <what the work found>.` The map now identifies the run: copy the Factory run section into the map's body unchanged (the same `started`, `closed in this run` and `baseline`), put `Factory run: moved to #<map>` in its place on the destination ticket, and write the changed plan (route `map`, the reason). A session that resumes from the destination ticket and finds that pointer follows it: `run-state.sh` exits 4 and names the map, and the map's body holds the run. A frontier round for the doors found follows (step 3). A contradicted **Under test** line still triggers the resurvey, as before.

## Heavy band

When `flow-size.sh` prints `Heavy band: ask before running` (or `plan-check.sh` prints `ask the person before running`), show the person the plan (route, fired rows with points, reason, expected slices, what the first slice leaves out) as a short summary and wait for yes or changes before the route starts. It is not a one-way door: an answer that changes the plan changes the plan. Record the answer on the ticket.

## The beachhead is the plan's

In the map route, `/wayfinding:beachhead` names candidates; its instruction to put them to the user and wait for the choice does not apply here. The plan decides: choose among the candidates yourself. Ask the person only when a candidate would put a one-way door under test, or when the candidates differ on something only the person can weigh (cost against an outside constraint, for example). Write the candidates, the choice and the reason as one comment on the slice ticket (scanned first), and tell the person at the next stage boundary. Overturning the choice is feedback and never stops the work (step 6, feedback). The wayfinding plugin is not changed.
