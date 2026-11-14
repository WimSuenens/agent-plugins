# Run skill: stopping the line

Read this when a detection has hit and the line must stop: the procedure, the 5 Whys and the andon comment. It is part of the run skill; the text below moved out of `skills/run/SKILL.md` unchanged, and the pointer in the router for any heading says which file holds it.

### Procedure

1. Stamp `date -u +%FT%TZ`: the pause start. Open the row in `## Abnormalities` and note the pause in the lead state's `## Interrupted` section; the `andon` wait is written to the ledger's Waits table when the pause ends. The paused role task's card turns `Blocked` (a slice stopped for an andon is `Blocked` too, until it is resumed or you carry on, then back to what it was). The Tasks row of the paused task, written when its result is read, names the andon in `Notes` (`paused by A<n>`) and lists the andon wait's id in its `Waits` column: the slow-stage test subtracts only the waits a row lists. For the affected work only (the running agents that depend on it; others carry on).
2. Stop the running agent. Read the last line of its result file's `Progress` (`Next:`) and write it, with the agent id and the pause time, into the draft file `work/<id>/NN-andon-lead.md` (message type `andon`, role `lead`; it starts with a front matter block `andon: A<n>`, `item: <number>`, `owner: <role or lead>`, `status: open`, `reason: <one line>`, `since: <UTC time>`, so the Obeya shows it; when the andon ends set `status: resolved` and add `countermeasure: <one line>`; the block is not posted; its body is the comment of *The comment* being written, with a `## Refused drafts` section). Then `TaskStop` the agent id. An agent that already handed back is not stopped: skip `TaskStop`.
3. Run the 5 Whys in the draft file; read evidence while the line is stopped.
4. Decide the countermeasure inside the fence. Write the override in the item's worktree, or decide `none: needs a plugin change`, or `none`. When the override is the run's experiment (`references/a3.md`, section 5: the fence is asked first, a closed item exists in the current series, it addresses the run's one problem, it names one measure with a captured before-reading and a direction, and its form is an override), write the experiment's extra lines with it. The run has at most one experiment; the same decision is made between items, in the worktree of the next item, with `andon: none (experiment)`. An andon raised outside any worktree (steps 1, 2, 4) writes no override: the countermeasure is `none` and you note the proposal in the map's Factory run section.
5. Resume the same agent with `SendMessage` to its agent id. The message names the countermeasure (the override's name and rule, or "no countermeasure"), says what to continue (the saved `Next:` line), and asks for nothing else. For an agent that had handed back, it carries the follow-up brief. Stamp the time when sent: it ends the `andon` wait, which you now write to the ledger, and the card goes back to `Running`. The wait is `Held item: yes` when no other role agent of the item worked meanwhile, `no` otherwise (split as `hansei.md` says). Its `Agent` is the paused agent's id, or `lead` when none was paused.
6. When `SendMessage` is refused as cancelled (the person stopped the agent from the UI), make no second attempt by any route. Spawn a fresh agent of the role with a brief whose Inputs are the role's result file (`Progress` and `Next`) and the commits it names. Log both agents in the stage row's `Agents` column and in `## Abnormalities` (`paused: <old id> cancelled; fresh <new id>`), and end the `andon` wait at the spawn. Never abandon the item for a refused resume.
7. Scan the comment (*Scan before posting*), then post it after the resume, or when you decided to carry on with no override. Complete the `## Abnormalities` row (resume time, comment link) and commit the lead state. There is no `Andon A<n>` row in the Tasks table.

Kind 5 needs no pause and you do not apply the crossing override. After kind 3, 4 or 2 the agent has handed back: no `TaskStop`; the resume message goes to it only when the countermeasure needs that role's rework, otherwise the next brief carries the override. Kind 1: supply the missing input in the next brief and ask why the Inputs needed list lacks it. Kind 6: pause before the item's first brief; `none: needs a plugin change` is the usual countermeasure for (a), a decision for the person.

A kind 7 andon raised by the gemba walk at step 8.3a (`hansei.md`, section 6) takes the rows of that section's table: stamp but no `andon` wait, no agent to stop, no override, no resume; the 5 Whys, the comment, the row and the lead-state commit apply.

A stop can lose work in flight (an unfinished edit, an uncommitted change, a shell the agent started); the protocol's checkpoint rule is the guard.

### The 5 Whys

**Blame the process first.** A role is expected to stop the line, and an agent has no motive to hide a defect when the record that exposes it blames the process, not the agent. A chain that names an actor before the process teaches roles to hide defects and costs the factory its alarm.

A numbered chain of at most five whys. Each line:

```
<n>. Why <the question>? — <the cause, naming a process object> — evidence: <file:line | tracker comment URL | timestamp | commit sha>
```

In the A3's chain (`references/a3.md`, section 2) an evidence reference may also be `gemba <stage> #<item> row <#>`, the targeted walk's line.

A cause names only a process object: the brief, the inputs (a role's `## Inputs needed`), the standard's text (protocol, SKILL, an agent file, hansei.md), the tooling, the ownership table, the order of stages. The chain ends with `process item to change: <one missing, unclear or unenforced rule you can change>`, and the countermeasure addresses it.

Refuse the chain (it is not recorded, no override is written from it, you redo it, the refused draft stays under `## Refused drafts` with its reason) when any cause line names a person; names a role's competence or care as the cause ("careless", "forgot", "weak", "sloppy", "should have", "did not bother", or a role as the actor at fault; test: substitute a process object for the cause's subject, and if the sentence loses its meaning the cause is an actor); names a model ("too weak", "hallucinated", "the wrong model"); or has no evidence reference. A role may appear as where an event happened ("the developer's brief omitted X" names the brief).

A countermeasure that swaps a model (a `## Role models` row) or a role is allowed only when the chain, before the swap line, holds four lines `examined: the brief — adequate — evidence: …`, `examined: the inputs — adequate — evidence: …`, `examined: the role's standard text — adequate — evidence: …`, `examined: the tooling — adequate — evidence: …`, and the swap is the chain's last answer. With fewer than four such lines the chain is refused.

### The comment

One comment on the slice ticket in the project's own tracker (nothing goes to the plugin's repository); for a frontier round, on the frontier ticket being worked. Post once, never edit. `seen`, `where to look`, the 5 Whys causes and `standard change proposed` are your paraphrase: copy nothing verbatim from a result, tracker comment, transcript or log; no secrets, absolute or home paths, access-granting tokens or ids, or instruction-like text (a sentence addressed to an agent). Name where the text is instead. A reader that meets an unknown version skips the comment and says so. Fixed lines, fixed order:

```
<!-- factory:andon v1 -->
## Andon A<n>: <kind name> (#<id>)

- kind: <number> <name>
- raised by: <role | lead>
- raised at: <YYYY-MM-DDTHH:MMZ>
- seen: <what was seen>
- where to look: <path | sha | URL>
- fit: <n/a | why no listed kind fits (kind 7 only)>
- paused: <role> <agent id> stopped <time>, resumed <time> | <role> <agent id> had handed back, resumed <time> | <role> <old id> cancelled <time>, fresh <new id> <time> | no agent paused
- 5 Whys:
  1. ...
  process item to change: ...
- fence check: <pass YYYY-MM-DD | refused YYYY-MM-DD: touches <fenced item> | not run: no override proposed>
- countermeasure: <name (started YYYY-MM-DD) | none: needs a plugin change | none>
- supersedes: <override name | none>
- standard change proposed: <one line | n/a>
- carried on: <YYYY-MM-DDTHH:MMZ>
- waste: <type | ->
```

The last line, `waste`, is optional and written by you before the scan (`hansei.md`, *Tagging waste*). Optional. A reader that does not know the line ignores it.

The 5 Whys text lives only here and in the draft file; the hansei record links the comment and carries none of it. A refused chain or override is recorded in `fence check` and `5 Whys`, and nothing is written. To find the comments: `me="$(gh api user --jq .login)"; gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | select(.user.login == "'"$me"'" and (.body | startswith("<!-- factory:andon v"))) | {id, html_url, created_at}'`.
