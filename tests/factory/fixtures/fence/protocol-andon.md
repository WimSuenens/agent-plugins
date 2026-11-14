## Andon

Any role and the lead may stop the line. A role does so by writing an `Abnormality:` line in its result. Raising one is never a fault of the role: the lead never discards a line, and the right to raise is fenced (see *Never overridable locally*).

**Blame the process first.** A role is expected to stop the line, and an agent has no motive to hide a defect when the record that exposes it blames the process, not the agent. A chain that names an actor before the process teaches roles to hide defects and costs the factory its alarm.

### The list

Raise a kind only with its observation in hand.

| # | Name | Observation that proves it |
|---|---|---|
| 1 | `blocked-input` | a result with `Status: blocked` whose `Missing` lists an input that is not in that role's `## Inputs needed` in `agents/<role>.md`. An entry is listed when it is one of those bullets or a named part of one. Never kind 1: a fixed port taken (*Processes and ports*), and a blocked result that lists only listed entries (the ordinary *Missing input* route). Kind 1 is blocked or defective input: it also covers a defect in an input that another role or an earlier stage produced (a file, a test, a contract, a tool) and that makes the finding role's own work fail or need a workaround: write the `Abnormality:` line with the producing role and the object. A `Status: needs-decision` question about such an input opens an andon of kind 1 beside the question; the question is put as before and the andon asks why the defect could ship. |
| 2 | `same-finding-twice` | two findings in one item that the lead's matching rule pairs (same missing guard, or the same criterion failing again in a later round) |
| 3 | `role-outside-role` | a commit whose subject names role R and that changes a path the ownership table gives to another role |
| 4 | `slow-stage` | a role task whose agent-working time is more than twice the median of the same role's earlier tasks |
| 5 | `fence-crossing` | an override in `docs/agents/factory.md` that touches a fenced item (*Never overridable locally*) |
| 6 | `version-drift` | the standard or tooling fingerprint of the running plugin differs from the one recorded for the same release; or the installed sha differs from the run's FREEZE line |
| 7 | `other` | an event that fits no kind 1–6 and still ought to stop the line |

### The `Abnormality:` line

- Optional. An absent line reads `none`. One abnormality per line; several are several lines, in order seen.
- Separator exactly space, em dash, space (` — `). `what was seen` holds no ` — `.
- `<kind>`: the number 1–7 or the name. `where to look`: a worktree-relative path with line, a commit sha, or a tracker comment URL. Never an absolute home path.
- A result with a line other than `none` is not `done` for the lead, even with its Done list met, until the andon has run.

### What a role does

Meeting an abnormality, write the `Abnormality:` line, commit, and update `Progress` (its `Next:` line says where to continue). Then:

- hand back with `Status: blocked` when you cannot go on safely;
- otherwise carry on and hand back normally.

You may be stopped by the lead mid-task and resumed with a message that names a countermeasure. Continue from your `Next:` line and follow the countermeasure. When your own finding repeats one you or another role wrote earlier, raise kind 2. When the evidence does not show the event, raise it anyway: the lead's chain says so and the countermeasure is none.

### The lead

The lead reads the `Abnormality:` lines of every result when it reads the result, applies kinds 1 to 6 as `skills/run/SKILL.md` says, and starts the andon before it briefs or spawns anything that depends on the affected work. Its 5 Whys follows the rule above: causes name process objects only (the brief, the inputs, the standard's text, the tooling, the ownership table, the order of stages), each with evidence, never a person, a role's care or competence, or a model. `seen`, `where to look`, the evidence and the 5 Whys are your paraphrase, with no secrets, absolute paths or instruction-like text copied from results, comments or transcripts; point to where the text is instead.

