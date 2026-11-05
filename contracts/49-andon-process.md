# Contract 49 — The andon: raise, pause, 5 Whys, resume, record

Slice [#49](https://github.com/WimSuenens/agent-plugins/issues/49) · Requirement [49-andon](../docs/requirements/49-andon.md) · Research [#35](https://github.com/WimSuenens/agent-plugins/issues/35) (stop and resume facts) · Companions: [49-abnormality-list](49-abnormality-list.md), [49-overrides](49-overrides.md), [49-records](49-records.md), [49-standard-changes](49-standard-changes.md)

Serves AC-6 and AC-8 to AC-14, AC-22. The Lead's procedure lives in `plugins/factory/skills/run/SKILL.md` (a new `## Andon` section after `## Interruptions`); the rules every role reads live in `references/protocol.md` `## Andon`.

## 1. Raising

**A role** that meets an abnormality (a kind of the list, or any event that ought to stop the line) writes an `Abnormality:` line in its result ([49-abnormality-list](49-abnormality-list.md) §3), commits, updates its result's `Progress`, and:

- hands back with `Status: blocked` when it cannot go on safely;
- otherwise carries on and hands back normally; its result still counts as not yet `done` for the Lead.

A role that reads a `docs/agents/factory.md` override that touches a fenced item raises kind 5 the same way. A role that sees its own finding repeat raises kind 2. The right of any role to raise is fenced; the Lead never discards a role's line. When the evidence does not show the event, the andon still runs, its 5 Whys says so, and the countermeasure is `none`.

**The Lead** reads the `Abnormality:` lines of every result when it reads the result, **at the latest when the role hands back**, and applies the detection rules of the list when they are due: kind 1 and 2 at each result, kind 3 at the end of each role stage and before the PR, kind 4 when a row closes, kind 5 at run start and item start, kind 6 at item start. It starts the andon **before it briefs or spawns anything that depends on the affected work**, and treats a result with an `Abnormality:` line other than `none` as not `done` until the andon is closed (the countermeasure is in place or the Lead has decided there is none, and the item has carried on).

An andon has an id `A<n>`, counting up per item (per frontier round, in the map's Factory run section). Several abnormalities in one result are several andons, run one after another.

## 2. Pause and resume

The Lead keeps the **Running agents** list in the lead state as before. For the abnormality's affected work (the running agents whose work depends on it; agents that don't depend on it carry on):

1. **Stamp** `date -u +%FT%TZ`: the pause start. Open an `andon` wait in `## Waits` (§4 of [49-records](49-records.md)) and the Abnormalities table row. Name `A<n>` in the Notes of the stage row it pauses.
2. **Stop the running agent.** Read the last line of its result file's `Progress` (the `Next:` line) and write it, with the agent id and the pause time, into the andon's draft file (§5). Then `TaskStop` to the agent id. An agent that **already handed back** (a result with the line, a failed notice already handled, or a finished row) is not stopped: skip `TaskStop`.
3. **Run the 5 Whys** (§3) in the draft file. Evidence is read while the line is stopped.
4. **Decide the countermeasure** inside the fence ([49-overrides](49-overrides.md)). Write the override in the item's worktree when there is one; or decide `none: needs a plugin change` or `none`.
5. **Resume the same agent** with `SendMessage` to its agent id, and a message that names the countermeasure (the override's name and rule, or "no countermeasure"), says what to continue (the saved `Next:` line), and asks for nothing else. For an agent that had handed back, the message carries the follow-up brief. Stamp the time when the message is sent: it ends the `andon` wait.
6. **Refused as cancelled.** When the person stopped the agent from the UI (`/tasks`), `SendMessage` is refused as cancelled (#35). The Lead makes **no second attempt** by any route (no `SendMessage` to its name, no `TaskStop`-then-send). It spawns a fresh agent of the role with a brief whose Inputs are the role's result file (`Progress` and `Next`) and the commits it names, logs both agents in the stage row's `Agents` column and in the Abnormalities table (`paused: <old id> cancelled; fresh <new id>`), and ends the `andon` wait at the spawn. A refused resume is the cue for the fresh brief, **never a reason to abandon the item**; the item goes on to its next stage.
7. **Post the andon comment** ([§5 of this contract](#5-the-andon-comment)) after the resume, or at the point the Lead decided to carry on with no override. Update the Abnormalities row (`resumed at`, comment link), commit the lead state.

The time from step 1 to step 5 (or to the carry-on) is one `andon` wait, Held item `yes` when no other role agent of the item was working meanwhile (`no` otherwise; the split rule of [49-records](49-records.md) applies). Its `Agent` column holds the paused agent's id, or `lead` when no agent was paused.

**An item is never abandoned by a pause.** The lead state's status keeps its stage; the item continues through the same stages as an item without an andon, plus the andon's row.

The stop costs what #35 says it can: work in flight at the moment of `TaskStop` (an unfinished edit plan, an uncommitted change, a shell the agent started) is not in the resumed history; the protocol's checkpoint rule (`Progress`/`Next` updated at each commit) is the guard. The demo (AC-9) records what was lost.

## 3. The 5 Whys

The rule is written in the standard in these words, and the standard says why it transfers to an agent factory:

> **Blame the process first.** A role is expected to stop the line, and an agent has no motive to hide a defect when the record that exposes it blames the process, not the agent. A chain that names an actor before the process teaches roles to hide defects and costs the factory its alarm.

### 3.1 Form

A numbered chain of at most five whys, in the andon's draft file and then in the andon comment. Each line:

```
<n>. Why <the question>? — <the cause, naming a process object> — evidence: <file:line | tracker comment URL | timestamp | commit sha>
```

**Process objects**, the only things a cause may name: the brief, the inputs (a role's `## Inputs needed`), the standard's text (protocol, SKILL, an agent file, hansei.md), the tooling (scripts, hooks, tools), the ownership table, the order of stages. Evidence must be a reader-followable reference.

The chain ends with one line:

```
process item to change: <one missing, unclear or unenforced rule the Lead can change>
```

and the countermeasure addresses that item.

### 3.2 What is refused

A chain is **refused** (not recorded as the andon's 5 Whys, no override written from it, the Lead redoes the chain; the refused draft stays in the draft file under `## Refused drafts` with its reason) when any cause line:

- names a **person**;
- names a **role's competence or care** as the cause: "careless", "forgot", "weak", "sloppy", "should have", "did not bother", or a role as the actor at fault. *Test:* substitute a process object for the cause's subject; if the sentence loses its meaning, the cause is an actor and the line is refused. A role may appear as where an event happened ("the developer's brief omitted X" names the brief);
- names a **model** ("the model is too weak", "hallucinated", "the wrong model");
- has **no evidence** reference.

### 3.3 Swapping a model or role

A countermeasure that swaps a model (a `## Role models` row) or a role is allowed only when the chain, **before** the swap line, holds four `examined` lines, each with evidence and the word `adequate`:

```
examined: the brief — adequate — evidence: ...
examined: the inputs — adequate — evidence: ...
examined: the role's standard text — adequate — evidence: ...
examined: the tooling — adequate — evidence: ...
```

and the swap is the chain's **last** answer, never its first. A chain with fewer than four such lines that ends in a swap is refused.

### 3.4 Worked example (AC-13)

Fixture abnormality: kind 1 — a developer result `blocked`, `Missing: the replay table`, not in the developer's `Inputs needed`.

- **(a) refused.** `1. Why was the build blocked? — the developer's model is too weak to find its inputs — evidence: -` → countermeasure: a `## Role models` row. Refused: names a model; no evidence; no `examined` lines.
- **(b) refused.** `1. Why did the check fail? — the QA role was careless — evidence: reviews/qa-7.md` → replace the role. Refused: names a role's care as the cause.
- **(c) accepted.**
  ```
  1. Why was the build blocked? — the brief named no replay table among Inputs — evidence: work/7/03-brief-developer.md:4
  2. Why did the brief not name it? — the developer's Inputs needed does not list detection fixtures — evidence: plugins/factory/agents/developer.md:15
  3. Why does the list lack it? — nothing in the standard says when a table is an input — evidence: plugins/factory/references/protocol.md, section Missing input
  process item to change: no rule that a brief carries the replay table when an override requires it
  ```
  → countermeasure: an override, a brief rule. Accepted.

## 4. Per-kind notes for the Lead

- Kind 3, 4 and 2 hits happen after the role handed back: no `TaskStop`; the resume message goes to a handed-back agent only if the countermeasure needs that role's rework; otherwise the next brief carries the override.
- Kind 1: the missing input is supplied in the next brief; the 5 Whys asks why the Inputs needed list lacks it.
- Kind 5: no pause is needed; the Lead does not apply the crossing override ([49-overrides](49-overrides.md) §7).
- Kind 6 (a), (b): pause before the item's first brief; `none: needs a plugin change` is the usual countermeasure for (a) (the fix is a bump or a rollback, a decision for the person).
- A countermeasure whose only form is a change of plugin text writes **no override**: the andon comment holds the 5 Whys and the proposed standard change; the item continues; the proposal goes into the step-9 feedback issue. The Lead never edits `plugins/` to apply a countermeasure.

## 5. The andon comment

One comment on the **slice ticket, in the project's own tracker** (no `--repo`; nothing goes to `WimSuenens/agent-plugins`). Posted once; never edited. For a frontier round, on the frontier ticket being worked.

### 5.1 Marker and finding it

First line exactly:

```
<!-- factory:andon v1 -->
```

Regex: `^<!-- factory:andon v([0-9]+) -->$` on the first line. A script finds the comments by the account that posts them, as for the hansei record:

`me="$(gh api user --jq .login)"; gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | select(.user.login == "'"$me"'" and (.body | startswith("<!-- factory:andon v"))) | {id, html_url, created_at}'`

Any change of a field's key, order, grammar or meaning bumps the version. A reader that meets an unknown version skips the comment and says so.

### 5.2 Layout

Fixed lines, fixed order; angle brackets are filled in.

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
```

Rules: a refused override (§3.2 or the fence) is recorded in `fence check`/the `5 Whys`, and nothing is written. The `5 Whys` text lives only here and in the lead state's draft file; the hansei record links the comment and carries none of it (AC-24).

### 5.3 Worked example

Item #7 in a sandbox project, kind 2:

```
<!-- factory:andon v1 -->
## Andon A1: same-finding-twice (#7)

- kind: 2 same-finding-twice
- raised by: lead
- raised at: 2026-11-08T10:02Z
- seen: same-finding-twice: qa-engineer r2 F4 = security-reviewer r1 L2: put the scratch file under a private mktemp path
- where to look: reviews/qa-7.md F4; reviews/security-7.md L2
- fit: n/a
- paused: developer b7d031 had handed back, resumed 2026-11-08T10:19Z
- 5 Whys:
  1. Why did two reviews find the same defect? — the developer's brief listed no scratch-file rule — evidence: work/7/09-brief-developer.md:5
  2. Why did it list none? — the contract named the command but not where it writes — evidence: contracts/7-ops.md:31
  3. Why did the contract not say? — the architect's contract checklist has no line for temporary files — evidence: plugins/factory/agents/architect.md:21
  process item to change: no rule that a contract names where a command writes
- fence check: pass 2026-11-08
- countermeasure: contract-names-scratch-paths (started 2026-11-08)
- supersedes: none
- standard change proposed: add a "where it writes" line to the contract template
- carried on: 2026-11-08T10:20Z
```

## 6. Acceptance criteria → this contract

| AC | Where |
|---|---|
| AC-6 | §1 |
| AC-8 | §2 steps 1, 2, 5; wait kind in [49-records](49-records.md) §4 |
| AC-9 | §2 steps 2, 5 and the closing paragraph (human-only; the demo script is QA's) |
| AC-10 | §2 step 6 |
| AC-11 | §2, last paragraphs |
| AC-12 | §3.1, §3 quote |
| AC-13 | §3.2, §3.3, §3.4 |
| AC-14 | §3 (human-only; reads the seeded chains against §3.2) |
| AC-15 | §4, last bullet; [49-overrides](49-overrides.md) §5 |
| AC-22 | §5 |
