# Run skill: the role path, the test depth, the verdict and the proof

Read this when you size a slice (the role path and the test depth), when you brief QA or read its verdict, when you run the merge gate, when you skip a role, and before a decision card or an acceptance demo of a slice with a visual result. It is part of the run skill; the router names the moments. Here `${CLAUDE_PLUGIN_ROOT}` is not substituted (only the router is): read it as the path on the `Plugin root:` line of `skills/run/SKILL.md`, and write that path in every shell command.

## Role path and test depth

`flow-size.sh` prints `role path:` (the roles that run, in the order `product-owner, architect, devops, developer, qa-engineer, runtime-proof, security-reviewer, docs-writer`) and `test depth:`. Both come from the fired rows' Adds text and from the table's `test-depth:` line, the starting depth of the project type (no line reads as `targeted`). The plan's `role path` and `test depth` fields hold what it printed, or more. A role is derived from these words in a row's Adds: `decision card`, `product owner` or `requirement` (product-owner); `architect` or `ADR` (architect); `devops`; `security review`; `docs-writer` or `documentation`; and `targeted` raises the depth. A row that mentions one of them without wanting the role should say it in other words.

- **The floor is never dropped.** `developer`, `qa-engineer` and `runtime-proof` are on every path. A slice in a protected area also has `security-reviewer` and a depth of at least `targeted`, and the person's merge approval. The scripts keep this even when the project's table has lost the words: `plan-check.sh` refuses a plan that drops one, `skip.sh` refuses to skip QA, the proof, or the security review of a protected slice, and the merge gate pauses for the person. The table adds steps; it never removes these. One-way doors stay with the person.
- **Scaling up** (a role added, the depth raised) is allowed within a slice: write the changed plan and say so in the stage summary. scaling down happens only at the next slice.
- **A role off the path is a recorded skip.** Run `skip.sh check <role> --reason "<reason>" --plan <plan file> <contract file>...`: a role that is not on the plan's path is `skip ok` (the reason is still required and goes in the ledger's Notes); a role on the path is refused.
- **`ui self-review: yes`** in the sizing means a fired row adds a demo: see *UI self-review*.

Test depth, the dial QA reads from the plan:

- `proof-only`: no new tests. The verdict rests on the runtime proof and, for the Light band, on the light verdict. The start for a markdown plugin or a static site.
- `targeted`: tests first for new logic (a failing test before the build), no sweep of edge cases. The start for a code app; the floor for a protected area.
- `full`: edge and failure paths and the full suite. Only after an escalation or an escaped defect; the lead writes it into the plan, the table never derives it.

## The light verdict

For a slice in the lightest band, QA gives an independent pass or block per acceptance criterion with one check each, the mechanical path check, and the existing suite if the project has one. No new tests, no edge sweep. It is still QA's own, binding pass or block: the gate treats it as the QA verdict. It narrows what QA does for the lightest band only; it never stands for a protected area or a higher band.

A light verdict says `Scope: light`. The verdict file stays machine-readable, light or not (`reviews/qa-<id>.md`):

```
Verdict: pass | block
Scope: standard | light
Path check: ok (<what paths.sh check printed>)           light only
Suite: <command> pass | none                              light only

## Criteria
- <id>: pass | check: <one check> | proof: P1[, P2]

## Proof
- P1 [<kind>]: <link or path>

Human-only criteria: <list> | none
```

Every criterion links at least one proof item, every item has a link or path. A standard verdict has the same lines with `Scope: standard`; its `check` is whatever test or scenario QA derived.

## Proof per artefact kind

The kind comes from the plan's optional `- artefact:` line, else from the table's `project-type:` (`proof-kind.sh resolve [--kind <kind>] [--plan <plan file>]` prints the kind and the proof it takes); a project that holds several kinds names it per slice.

| Artefact | Proof item kind |
|---|---|
| web app (`web-app`) | `screenshot` |
| command-line tool or library (`cli`, `library`) | `run-log` |
| instruction markdown (`instruction-markdown`) | `scenario-transcript`, and the verdict's Human-only list |
| docs (`docs`) | `render-log` or `link-check-log` |

The merge gate (`merge-gate.sh check <pr> --qa pass --qa-file <verdict> [--plan <plan file>] [--kind <kind>] ...`) reads the verdict file, prints what it read, and blocks with the criterion named when a criterion has no proof item, links an item that is not listed or has no link, links none of the kind above, or is `block`. A light verdict is accepted only with the plan's lightest band and no protected area.

## UI self-review

When the sizing says `ui self-review: yes`, before a decision card that shows a prototype or the acceptance demo, the factory looks at its own result first. The qa-engineer writes the critique: it is independent of the developer and already captures the proof. The design plugin's `ux-review` is an optional second opinion, not required.

1. Start the application (the run skill of the project, or its documented command) and drive the main pages.
2. Capture screenshots at phone width and at desktop width of each page driven. They are proof items of the verdict (kind `screenshot`).
3. Write `reviews/ui-<id>.md`: one line per finding, `- <severity> | <page> | <what is wrong> | <what to change>`, severity `blocker`, `major` or `minor`; then `Not checked:` with what was not looked at (a remembered choice, keyboard use, another browser, a width), or `none`.
4. Clear faults (`blocker`, `major`) go back to the developer as rework first, and the capture and the critique are redone. `minor` findings go on the card or demo as they are.
5. The decision card or the demo carries the screenshots, the critique and what was not checked.

## The QA brief carries the CI steps

Before you brief QA, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ci-steps.sh"` in the item worktree: it reads the workflow the project's `ci:` line names and prints the `run:` steps of the jobs a pull request runs (or `none`). Paste the output into QA's `Inputs` as it is. QA runs each step that needs no secret and no network, reports each result or the reason it was skipped, and a hand back without them is incomplete (`agents/qa-engineer.md`, *Done*). Read QA's verdict for those results before you accept `done`.

## Summary limit

The Summary field of a result, bullets included, is at most 10 lines; detail goes in Progress or Artifacts. Count the lines before you hand back: the lead's render step refuses a longer Summary and the role is resumed to shorten it. A role calls no lead script for this (the protocol's *Shell* is unchanged); the count is by eye or with `wc -l` on the lines between `Summary:` and the next field.

## Fresh or resumed

The first task of a role in a new slice gets a fresh agent, never one that worked on an earlier slice. Resume an agent only for a rework in the same slice, and only below 200,000 tokens of peak context (provisional). Read the peak before resuming: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/token-spend.sh" <the agent's transcript>`, the `peak` figure (the largest single-message context). At or above the number, spawn a fresh agent: the brief, the feedback and the committed result carry the task on. This is what the run skill's sentence "one agent per role" means: there is one agent per role in each slice and never a second in the same slice. Project knowledge lives in the repository and the role files, not in the agent's context. After the next two runs, read the peak per role task and move the number.
