# Contract 64 — Parallel slices: the path list, the overlap rule, the limit, the gate, the review step, the resurvey pause

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADR [0016](../docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md) (amends [0007](../docs/adr/0007-factory-owns-destination-and-slicing.md)) · Statuses: [64-board-status](64-board-status.md) §3

Serves AC-27 to AC-33 and AC-34 (the `factory-state` check). ADR 0016 is built to, not reopened.

## Paths

Paths:
- plugins/factory/skills/run/SKILL.md
- plugins/factory/agents/architect.md
- plugins/factory/agents/qa-engineer.md
- plugins/factory/agents/security-reviewer.md
- plugins/factory/skills/setup-factory-skill/assets/factory.md
- plugins/factory/scripts/paths.sh
- plugins/factory/scripts/factory-config.sh
- plugins/wayfinding/skills/wayfinder/SKILL.md
- plugins/wayfinding/skills/beachhead/SKILL.md
- tests/factory/
shared: none

## 1. The path list in a contract (AC-27)

**Place.** Every contract file of a slice has a section `## Paths`, **directly after its title block** (the lines that link the slice, requirement and ADRs), so that a person and `paths.sh` find it first. One block per contract file. The slice's list is the **union of the blocks of every file `contracts/<id>-*.md`**, `<id>` the slice ticket's number.

**Grammar.** Outside code fences, the block starts at a line that is exactly `Paths:` (column 0) and ends with the `shared:` line:

```
Paths:
- plugins/factory/skills/run/SKILL.md
- plugins/factory/agents/
- tests/factory/
shared: CHANGELOG.md, plugins/factory/.claude-plugin/plugin.json
```

- After `Paths:`, one entry per line, each `- <path>`; the entries end at the first line that does not start with `- `, which must be the `shared:` line (so the `shared:` line follows the list directly).
- A **path** is repo-relative, `/`-separated, no leading `./` or `/`, no `..` component, no spaces, commas, backticks or glob characters (`*`, `?`, `[`). A **file** has no trailing `/`; a **directory prefix** ends in `/`. A directory without its slash is a file to the rule (§2), so write the slash.
- **Every role's paths are included**: `plugins/` for the developer, `tests/` and `reviews/qa-<id>.md` for QA, `reviews/security-<id>.md`, `docs/` for the docs-writer, and so on. A path outside the list is a finding at review (§6).
- `shared:` is `shared: none` or `shared: ` followed by entries separated by `, `. A shared entry is an exact path without a trailing `/`, or the word `adr-number`. The shared set the standard names is: **the plugin version files** (`plugins/<name>/.claude-plugin/plugin.json`), **`CHANGELOG.md`**, **`CONTEXT.md`** and **the next ADR number** (`adr-number`). A slice names on its `shared:` line each of these it will change.
- **`Paths:` is mandatory.** A contract with no block, a block that does not parse, or no `shared:` line fails the architect's Done list (AC-27). The architect's agent file adds this to its Done list.
- This contract's block is the worked example; the union of all the 64 contracts' blocks is the item's list that QA and security compare the diff with.

## 2. The overlap rule (AC-28)

Two slices **overlap** when:

1. some path P in one list is **equal to** a path Q in the other, or P is a **directory prefix of** Q, or Q of P (`P` ends in `/` and `Q` starts with `P`); **or**
2. their `shared:` lines both name the same entry (exact string; `none` names nothing).

Shared entries are not paths for rule 1, and paths are not shared entries for rule 2. Comparison is on strings, character for character, case-sensitive. A name that merely starts the same is not a prefix: `plugins/factory/` is not a prefix of `plugins/factory-x/a.md`.

| List 1 | List 2 | Overlap |
|---|---|---|
| `plugins/factory/skills/run/SKILL.md` | `plugins/factory/skills/run/SKILL.md` | yes (equal) |
| `plugins/factory/` | `plugins/factory/agents/qa-engineer.md` | yes (prefix) |
| `plugins/factory/agents/qa-engineer.md` | `plugins/factory/` | yes (prefix, other order) |
| `plugins/factory/` | `plugins/factory-x/a.md` | no |
| `docs/requirements/70-a.md` | `docs/requirements/71-b.md` | no |
| `plugins/design/` | `plugins/wayfinding/` | no |
| `shared: CHANGELOG.md`, `a/` | `shared: CHANGELOG.md`, `b/` | yes (both shared) |
| `shared: CHANGELOG.md`, `a/` | `shared: none`, `b/` | no (only one names it) |
| `shared: none`, `a/` | `shared: none`, `a/x.md` | yes (prefix) |
| `a/` | `a/b/` | yes (prefix) |
| `a/b.md` | `a/` | yes (prefix) |
| `shared: CHANGELOG.md`, `a/` | `shared: CONTEXT.md`, `b/` | no |
| `shared: adr-number`, `a/` | `shared: adr-number`, `b/` | yes |

### `scripts/paths.sh` (tooling)

The rule is text **and** a script, so a test calls what the lead calls (decision 2 of [64-release](64-release.md) §6; ADR 0016 names "no new tooling" for locks and registries, which this is not, and the script is the whole of the "one comparison"). `bash` 3.2, no network, no writes.

```
paths.sh list <contract-file>...
paths.sh overlap <file>... -- <file>...
paths.sh check <contract-file>...            (names on stdin, one per line)
```

| Subcommand | Prints | Exit |
|---|---|---|
| `list` | one line per entry of the union: `path <p>` or `shared <s>` (`shared none` is not printed) | 0; 2 a file has no `Paths:` block or no `shared:` line; 3 an entry is malformed (names it by line number, not text) |
| `overlap` | `overlap: no`, or `overlap: yes <p> <q>` / `overlap: yes shared <s>` (the first pair found, in list order) | 0 no overlap; 1 overlap; 2 and 3 as `list` |
| `check` | for each stdin name not on the list: `off-list: <name>`. A name is **on the list** when it equals, or lies under, a path entry, or equals a shared entry | 0 none off-list; 1 at least one; 2 and 3 as `list` |

The files given may be contracts or plain files in the same grammar (a test passes a two-line list). An empty `Paths:` block (no entry) is malformed (3).

## 3. The two lines of `docs/agents/factory.md` (AC-29, AC-34)

Read by `scripts/factory-config.sh` (tooling; `bash` 3.2). Both lines are matched at column 0 and nowhere else.

```
factory-config.sh state [<factory.md>]
factory-config.sh limit [<factory.md>]
```

**`factory-state`.** Line 1 of the file is exactly `factory-state: 2`. `state` prints nothing on success.

| Case | stderr (the lead shows it) | Exit |
|---|---|---|
| line 1 is `factory-state: 2` | | 0 |
| no `factory-state:` line at all (a 1.x project) | `factory.md has no factory-state line: run setup-factory-skill` | 3 |
| a `factory-state:` line that is not line 1, or whose value is not `2` (`1`, `3`, empty, `two`) | `factory.md has "<the line as found, cut to 40 characters>": run setup-factory-skill` | 4 |
| the file is missing or unreadable | `factory.md missing: run setup-factory-skill` | 2 |

The lead runs `state` **first**, before the resume-or-start decision of step 0, before any call to the board and before any mutation (AC-34). Exit non-zero: the lead stops and prints the message. A fresh project gets the line from the template; the migration writes it last ([64-board-script](64-board-script.md) §7).

**`parallel-limit`.** One line, `parallel-limit: <N>`, in the section `## Parallel slices` ([64-board-status](64-board-status.md) §2), `<N>` a positive integer without leading zeros (`^parallel-limit: [1-9][0-9]*[ ]*$`).

| Case | stdout | Exit |
|---|---|---|
| no line | `2` (the default) | 0 |
| one valid line | `<N>` | 0 |
| a line that starts `parallel-limit:` and is not valid (`0`, `-1`, `two`, empty, `2.5`, `02`) | | 5, stderr `factory.md line "<the line>": parallel-limit must be a whole number of 1 or more` |
| two or more `parallel-limit:` lines | | 5, stderr `factory.md has parallel-limit more than once` |

On exit 5 the lead **stops and names the line to fix**, as for a bad role model value, and starts nothing. The setting is read from `docs/agents/factory.md` and from nowhere else (no environment variable, no argument).

## 4. The start gate (AC-29)

The lead considers starting the next `Ready` slice. It starts it only when **both** hold:

- **(a) the limit.** The number of slices **in flight** is below `N`. In flight: a slice card with an item branch whose `Factory status` is `Running`, `Waiting on you` or `Blocked` (requirement Decision 4: a slice waiting on the person still holds its paths and its worktree). A `Ready` slice with a branch is not in flight.
- **(b) the list.** The new slice's list exists (§5) and `paths.sh overlap <the new slice's contracts> -- <the contracts of one in-flight slice>` exits 0 for **every** slice in flight. The in-flight slices' contracts are read from **their own worktrees** (`../wt/<id>/contracts/<id>-*.md`), not from `main`.

Otherwise the slice stays `Ready` and the lead **says why**: `limit (<k> of <N> in flight)` or `overlaps #<id> on <path>`. The map's `in flight:` line lists every item in flight (`#12 (item/12), #14 (item/14)`). After a usage-limit hit (`## Interruptions`), the gate behaves as `N = 1` until the slices in flight have closed (decision 6 of [64-release](64-release.md) §6; the existing rule already stops parallel *roles* after a limit).

| Fixture | Result |
|---|---|
| `N = 1`, one in flight | no second slice |
| `N = 2`, one in flight, no overlap | starts |
| `N = 2`, two in flight | waits (`limit`) |
| `N = 2`, one in flight, overlap | waits (`overlaps #<id> on <path>`) |
| line absent | behaves as `N = 2` |
| `0`, `-1`, `two`, empty | the lead stops, names the line, starts nothing |

## 5. When the list is compared (AC-30, Decisions 3)

A slice is **cut** first, and its list exists only after the architect stage. The stages in between are not gated:

- The **product-owner** and **architect** stages may start for a second slice while another runs: they write `docs/requirements/` and `contracts/` and `docs/adr/` under paths no build touches. (Requirement and contract files are named by slice id, so two slices never share one; an ADR number is assigned at slice start, §7.)
- **The comparison is made when the architect's result is read, before the first brief of any other role** (Environment, Build, QA, security, devops, docs). Its input is the union of `contracts/<id>-*.md` in the slice's worktree. No developer, QA or security role is spawned for the slice before this comparison passes the gate of §4.
- A slice whose list **overlaps** stays `Ready`, with its requirement and contracts kept in its worktree. When an in-flight slice closes, the lead runs the gate again for it.
- **Re-check.** When a contract of an in-flight slice changes after the comparison (a contract change proposal accepted by the architect), the lead runs `overlap` again for that slice against the others. A new overlap pauses the slice that started **later**: `Waiting on you`, needs-you comment `Cause: resurvey pause`, its running roles finish the step in hand, no further role for it until the person answers.
- Rejected, as the requirement did: no stage at all before the comparison (wastes the parallelism), building first and checking at QA (defeats the list).

## 6. QA and security check the diff against the list (AC-32)

A QA or security brief for item `<id>` carries, in its `Done` list, this step, and the two agent files carry it too:

1. `git fetch origin main`, then `git diff --name-only origin/main...item/<id>` (the three-dot form: changes on the branch since it left `main`; `origin/main` rather than a local `main`, which may be stale and would show main's own commits).
2. Pipe the names into `bash "<plugin root>/scripts/paths.sh" check contracts/<id>-*.md` in the item worktree.
3. Each `off-list:` line is a **finding** with the path named, severity at least `medium`. No line, no finding.

A path that only the lead changes at merge (the version file, the changelog line, the ADR number as assigned) is **not in the diff when the review runs**: the lead applies them after the review, at merge (§7), and the standard says so. A shared path that does appear in the diff is on the list only if the slice named it on its `shared:` line.

## 7. Merge handling for parallel slices (AC-33)

- **ADR number.** The lead assigns the **next free number** at slice start and records it in the slice's lead state (`Assigned ADR number: NNNN`); the architect names its ADR file with it. The number is the shared entry `adr-number`.
- **Version and changelog.** The lead applies the version bump and the changelog line **at merge, after rebasing on `main`**, when the slice's contracts list them on the `shared:` line. The developer and docs-writer of a slice do not edit them in the branch unless the slice runs alone and names them in `Paths:` (as this slice does, being frozen on 1.3.0).
- **Amended rule.** `skills/run/SKILL.md` no longer says "Items run one at a time" except as the meaning of `parallel-limit: 1`; it cites ADR 0007's closing rule as amended by ADR 0016. The developer searches `plugins/`, `README.md` and `docs/factory/` for `one at a time`, `one slice at a time` and `Items run one at a time` and leaves only that meaning. (`plugins/factory/skills/run/SKILL.md` *Interruptions* item 5, "one frontier ticket's role work at a time", is about roles, not slices, and stays.)

## 8. The resurvey pause (AC-31)

After each merge the wayfinding **Resurvey** checks every slice in flight. The same sentence is in both texts, verbatim, so that the item close and the wayfinding resurvey cannot drift apart:

> A slice in flight is questioned when the merge changes a decision its frame rests on, contradicts one of its Under test lines, or changes a path in its list.

- **`wayfinder/SKILL.md`, Resurvey**, gains a step "Slices in flight": for each slice in flight, compare its requirement, contract and path list with what this merge taught (the Under test results, any new or changed decision, the paths the merge changed: `git diff --name-only <merge>^1 <merge>` through `paths.sh check` against the slice's contracts). The step ends by naming each questioned slice and the question. It does not pause anything: how a slice is paused belongs to the runner.
- **`beachhead/SKILL.md`** gains one line: a slice may be cut while another is in flight; its path list is compared before it is built.
- **`run/SKILL.md` step 8.8** invokes the Resurvey and then applies the pause for every slice it named: the slice becomes `Waiting on you` with the needs-you comment of [64-board-status](64-board-status.md) §4 (`Cause: resurvey pause`, the question as `Ask`); its running roles finish the step in hand; **no further role starts for it until the person answers**. A slice with no question stays `Running`, and the lead says it checked.
- **The factory calls the wayfinding text and does not copy it.** The run text carries the pause sentence above and the pause action, and points to the Resurvey for the comparison.
- **Precedence if the installed wayfinding text is older** (the plugin has no version, [64-release](64-release.md) §4): the run's rule governs, and the run text says so in one sentence.

| Fixture | Result |
|---|---|
| (a) a merge whose decision contradicts B's frame | B paused |
| (b) a merge that changes a path in B's list (the gate should have prevented it) | B paused |
| (c) a merge that touches nothing of B | B stays `Running`, the lead says it checked |

Unverified until two slices run side by side.

## 9. What QA can check offline

| Check | AC | How |
|---|---|---|
| the architect's Done list requires the block | 27 | text check of `agents/architect.md` |
| the table of pairs | 28 | `paths.sh overlap` on two-line list files for each row of §2, plus QA's own rows |
| the gate | 29 | table-driven replay of §4 with `factory-config.sh limit` fixtures (`0`, `-1`, `two`, empty, absent, `2`) and in-flight sets built as fake `B-items` answers |
| no build role before the comparison | 30 | text check that the build briefs of step 6 follow the comparison; fixture of an overlapping second slice stays `Ready` |
| the pause | 31 | the three fixtures; the sentence of §8 appears verbatim in both `wayfinder/SKILL.md` and `run/SKILL.md` |
| off-list path | 32 | a throwaway repo with a branch touching `contracts/x.md` and one off-list file: `check` prints `off-list: <file>`, exit 1; an on-list diff gives exit 0 |
| one rule | 33 | search for `one at a time` |
| the config lines | 34 | the table of §3 |

## 10. The architect's Done list, as it must read (AC-27)

`agents/architect.md`, *Done*, gains one line: "Every contract carries a `Paths:` block and a `shared:` line (`contracts/` guidance in the protocol): a contract without one fails this list." The *Output* line says each contract's `## Paths` section follows its title block.
