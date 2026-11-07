# Contract 64 — Role tasks as sub-issues: creation, the closing comment, size, rework, limits, and the text scan

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADR [0014](../docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md) (partly replaces [0001](../docs/adr/0001-factory-roles-talk-through-files.md)), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Calls: [64-gh-calls](64-gh-calls.md) · Statuses: [64-board-status](64-board-status.md) §3

Serves AC-9 to AC-19.

## Paths

Paths:
- plugins/factory/skills/run/SKILL.md
- plugins/factory/references/protocol.md
- plugins/factory/references/decision-card.md
- plugins/factory/agents/
- plugins/factory/scripts/post-text.sh
- tests/factory/
shared: none

## 1. The role task

One spawn of one role on one item is one **role task**: one sub-issue, one card on the board, one draft result file. Its parts:

| Part | Where | Rule |
|---|---|---|
| **marker** | line 1 of the issue body | exactly `<!-- factory:task <role> <n> -->`: `<role>` one of the seven names, `<n>` counts that role's tasks in this item (or this frontier ticket), the first being 1, **rework and re-briefs included** |
| **brief** | the rest of the body, after one blank line | the brief template of `references/protocol.md`, **unchanged in fields** (`Goal`, `Inputs`, `Constraints`, `Output`, `Done`) |
| **title** | the issue title | `<Stage>: <role> on #<id>` (`Build (round 2): developer on #12`); a rework task: `rework <k>: <one line of the finding>` (§7); a frontier task: `<Stage>: <role> on #<ticket>` |
| **parent** | the sub-issue link | the slice ticket for an item; **the frontier ticket for a frontier round, never the map** (ADR 0014, *Decided inside*). Depth: map, ticket, role task |
| **card** | the board | `Kind` `role task`, `Role` the role, `Factory status` per [64-board-status](64-board-status.md) §3 |
| **result** | the closing comment | §5 |
| **draft** | `work/<id>/NN-result-<role>.md`, committed by the role | the record that cannot be edited; where comment and draft differ the draft's commit decides (§8) |

The brief's `Output` line names the draft: `Output: work/<id>/NN-result-<role>.md`, `NN` one above the highest `NN` in the folder when the lead writes the brief; two roles briefed together (QA and security) get the next two numbers in creation order. The role no longer chooses `NN`.

## 2. Find before create (AC-10)

The lead never creates a role task before it has looked for it. Look-up, in order, by the marker `<!-- factory:task <role> <n> -->` on the first line of the body, among issues **authored by the lead's own login** (a public repo can hold a forged marker):

1. `T-subissues` of the parent. A match: use it.
2. No match: `T-recent`. A match there is an issue created but never linked (a limit stopped the lead, §10): **link it** (`T-link`) and use it.
3. No match anywhere: create (§3).

A fixture that ends with two issues carrying one marker is the defect.

## 3. Create and spawn (AC-9)

In this order. Each step is idempotent on a resume because of §2 and because `B-add` returns the existing card.

1. Write the brief to a scratch file (`mktemp`), the marker on line 1. **Scan it** (§9); on a hit, post nothing, tell the person which line, keep the slice `Running`.
2. `T-create` (title, `--body-file`). The URL gives `<n>`.
3. `T-dbid`, then `T-link` to the parent.
4. `B-add`, then `B-set` `Factory status` `Running`, `Kind` `role task`, `Role`.
5. Spawn the role. The **spawn prompt** says, in plain words: the role task's issue number; "read your brief from that issue with `gh issue view <n> --json body --jq .body`; line 1 is a marker, the brief starts at line 3"; the draft result's file name (the brief's `Output` line); and, for a rework, nothing else (the finding is the body). The prompt copies no brief text.
6. Write the agent id into the lead state's `## Running agents`.

The role reads the brief from the issue. It does not write to the tracker (§11).

## 4. The draft result, unchanged

The result template of `references/protocol.md` is unchanged: `Status`, `Abnormality`, `Progress` (`Done`, `Next`), `Summary`, `Artifacts`, `Decisions`, `Open questions`, `Missing`, `Decision card`. A role writes it as soon as it starts, with `Status: working`, and commits it at every checkpoint; the commit subject starts `#<id> <role>: `. Nothing about the draft changes except that its file name comes from the brief.

## 5. The closing comment (AC-11, AC-12)

When the lead reads a finished result (`Status` other than `working`), in this order:

1. **Scan** the draft (§9). A hit: post nothing, tell the person the line, keep the task `Running` and the issue open.
2. **Render** it (`post-text.sh render`, §9) into the comment body, then **elide** and **split** it if needed (§6).
3. **Find** existing result comments (`T-comments`, first line `<!-- factory:result v1 -->`): see the resume table below.
4. **Post** the comment (`T-comment`). For a split result, part 1 first, then each continuation (§6).
5. **Close** the sub-issue (`T-close`). Never before the comment.
6. **Status.** `B-set`: `Done`, or `Blocked` (result `blocked`), per [64-board-status](64-board-status.md) §3. A result `needs-decision` is a `Done` task and a `Waiting on you` slice.
7. **Row.** Add the task's row to the ledger's Tasks table ([64-ledger-and-fields](64-ledger-and-fields.md) §2).

**Shape.** Status, Abnormality and Summary are visible; the other fields are inside one `<details>` element; the text of each field is the draft's, with no field added, dropped or reworded. A field the draft leaves out is left out.

```
<!-- factory:result v1 -->
Status: done
Abnormality: none
Summary: Contracts for the six parts, ADR status lines unchanged, two questions routed to the lead.

<details>
<summary>Details</summary>

Progress:
  Done: contracts written (a1b261c)
  Next: none
Artifacts: contracts/64-*.md
Decisions: field type is text (cost to undo: half a day)
Open questions: none

</details>
```

**Resume table** (the lead resumed and looks at the sub-issue; the find is by the first-line marker among the lead's own comments, never by position or time):

| Fixture | The lead does |
|---|---|
| issue open, marker comment present | close the issue; post nothing |
| issue closed, marker comment present | nothing |
| issue open, no marker comment | post once, then close |
| a split result with some parts posted | post the missing parts only (§6), then close |

None of these ends with two comments carrying the same marker (and part number).

## 6. A result that exceeds one comment (AC-13)

A comment holds at most 65,536 characters (#51). The helper caps each comment at **60,000 bytes**, which is never more than 65,536 characters (a character is at least one byte).

1. **Logs and diffs are linked, not pasted.** Before splitting, `post-text.sh elide` replaces every fenced block over `--max` bytes (default 20,000) by one line, `[block of <n> lines omitted; see <ref>]`, where `<ref>` is the commit URL of the draft's commit (`https://github.com/<O>/<R>/commit/<sha>`). The text names no `work/` path.
2. **Split** (`post-text.sh split`). One comment when the rendered body fits. Otherwise part 1 is the marker line, then `<!-- factory:parts <m> -->`, then Status, Abnormality, Summary, then as much of the `<details>` as fits (closed with `</details>` in the same comment); parts 2 to `m` each start with `<!-- factory:result-cont v1 of=FIRST part=<k>/<m> -->` and carry a balanced `<details><summary>Details, part <k> of <m></summary>…</details>`. Cuts fall on line ends; a line longer than the cap is cut on a character boundary. Concatenating the parts' details bodies gives the original.
3. The lead posts part 1, reads the comment id from the returned URL (`…#issuecomment-<cid>`), replaces `FIRST` by `<cid>` in the later parts, and posts them. A resumed lead finds part 1 by its marker, counts `result-cont` comments with `of=<cid>`, and posts only the missing parts.
4. **Status and Summary are always in part 1.** If those lines alone exceed the cap the helper exits 4 and the lead asks the role to shorten its Summary (it is at most 10 lines).
5. The task's `Notes` in the ledger read `split <m>` when a result needed `<m>` comments; at step 8 the lead counts such rows and says the count in its merge-approval summary, so that "more than rarely" can be judged (**Unverified** 1).

## 7. Rework (AC-15)

Findings from QA or security go to the developer (or the role that fixes) as a **new** sub-issue under the same parent:

- title `rework <k>: <one line>`, `<k>` counting rework sub-issues of the slice from 1;
- body: marker line (`<!-- factory:task <role> <n> -->`, the fixing role's own next `n`), then the **feedback template** unchanged in fields (`Source`, `Findings`, `Re-verify`);
- the earlier role-task issues stay closed and unedited; a finding is never written into one of them or into a file;
- card: `Kind` `role task`, `Role` the fixing role, status per §3;
- `Rework rounds` of the slice = the number of `rework` sub-issues ([64-ledger-and-fields](64-ledger-and-fields.md) §5). The Tasks table stage cell reads `Build (round 2)` for the first rework of the build, as the stage log's `(round <n>)` did.

A `Source: lead` feedback (an overturned two-way decision) is a rework task whose body says so.

## 8. A cut-off role loses no Progress (AC-14)

The draft result is committed at every checkpoint, so a role cut off with `Status: working` leaves its `Progress` there. The lead, resuming it:

- tells the resumed (or fresh) agent to read its `Progress` from the **committed draft in `work/<id>/`**, not from the issue;
- leaves the sub-issue open and the card `Running`;
- posts **no** result comment for a `working` draft.

Where the comment and the draft differ, the draft's commit decides (one sentence in the protocol).

## 9. The text scan, and the helper `scripts/post-text.sh` (AC-13, AC-18)

Tooling, `bash` 3.2, no network, no writes outside the named output paths. Output on stdout in the lines below; diagnostics on stderr name a **file by basename and a line number, never the text** (the text may hold the secret).

```
post-text.sh scan [--needs-you] <file>...
post-text.sh render <draft-result> <out>
post-text.sh elide <in> <out> <ref> [--max <bytes>]
post-text.sh split <in> <outdir>
```

| Subcommand | Does | Exit |
|---|---|---|
| `scan` | reads each file; a line matching one of the **home-path** patterns (an absolute path that starts at a user's home directory on macOS, Linux or Windows; `~/` is allowed, as in ADR 0013) or one of the **secret** patterns (a GitHub token `ghp_`, `gho_`, `ghs_`, `github_pat_` followed by 20 or more token characters; `AKIA` and 16 upper-case alphanumerics; `xox[abprs]-` and token characters; `sk-` and 20 or more token characters; a `-----BEGIN … PRIVATE KEY-----` line; `Bearer ` and 20 or more token characters) is a hit. With `--needs-you` a line naming a path under `work/` followed by a number, or a branch `item/<n>` or `frontier/<n>`, is also a hit. Prints one line per hit: `scan: <basename>:<line>: home-path`, `…: secret`, or `…: work-path` | 0 clean; 1 at least one hit; 2 usage or a file unreadable |
| `render` | writes the §5 body from a draft: marker, Status, Abnormality, Summary visible, the other fields in `<details>`; keeps each field's text byte for byte | 0; 3 the draft lacks `Status:` or `Summary:`, or Summary is over 10 lines |
| `elide` | §6 item 1; prints the number of blocks elided | 0 |
| `split` | §6 items 2 to 4; writes `part-1.md` … `part-<m>.md` into `<outdir>` and prints `<m>` | 0; 4 Status and Summary alone exceed the cap |

The scan covers briefs, closing comments (every part), rework bodies, the needs-you comments of [64-board-status](64-board-status.md) §4 and the ledger. **A hit stops the posting**: nothing goes to the tracker, the lead names the line to the person and the card stays `Running`. A clean text is posted.

**Decision on `work/` in issue text.** The `Citations` rule of the protocol (an ADR, requirement or doc that lands on main never cites a path under `work/`) now also covers **decision cards and needs-you comments**, the texts the person acts on from the board (AC-5). It does **not** cover briefs and closing comments: a brief's `Output` line must name the draft file, and a result may name the files it wrote. Those are pointers inside the working record; they land nowhere on main. The requirement's AC-17 says the rule "now also covers issue text"; this is the narrow reading that keeps the brief template's `Output` line. Undo: one rule, if the person wants the wide reading (the `Output` line then names the file without `work/`).

## 10. A tracker limit stops the creation (AC-19)

The lead designs for three limits (#51): **100 sub-issues per parent**, **8 levels of nesting**, **80 content-creating requests a minute** (`T-create` and `T-comment`). It does not pre-count requests; it reacts to the error.

| Error on | The lead does |
|---|---|
| `T-create` or `T-comment`: a message with `secondary rate limit` (and a `Retry-After` of at most 120 seconds) | waits the stated time **once** (`sleep`), retries **once**; a second failure stops. A `Retry-After` over 120 seconds stops without waiting |
| `T-link`: a message with `nesting` or `too many sub-issues` | stops at once |
| any stop | names the limit and the call to the person; if an issue was created and not linked, names its number; card `Waiting on you` with a needs-you comment, `Cause: tracker limit`; on resume §2 finds the unlinked issue and links it. Never reports success after a failed link, never retries without bound |

## 11. Who writes to the tracker (AC-16, AC-17)

- **Only the lead** runs a mutation call. The protocol's *Shell* section stays **word for word** the 1.3.0 text (fence F6). No agent file and no brief template tells a role to run `gh issue create|edit|comment|close` or a `gh project` or `gh api` write; the architect and product-owner may still read (`gh issue view`).
- **`work/` after 2.0.0** holds: `NN-result-<role>.md` (the committed drafts), `NN-question-<role>.md`, `NN-decision-<slug>.md` (the product-owner's decision-card drafts) and `NN-andon-lead.md` (the lead's andon drafts), and `00-lead-state.md`. The brief and the feedback are sub-issue text. `NN` keeps its meaning for the files that remain. (The requirement's AC-17 names three kinds; the two draft kinds the protocol already had, the card and the andon draft, would have no home otherwise, so they stay.)
- **A question** stays a file the role writes. The lead's answer goes into the role's **next sub-issue body** (or the rework body), never into a file the role did not write.
- Roles' agent files change only where they say where the brief is read from (`gh issue view <n> --json body --jq .body`, the number in the spawn prompt) and where the result file's name comes from (the brief's `Output` line); the architect's and QA's and security's lines are [64-parallel-slices](64-parallel-slices.md) §6 and §7.

## 12. What QA can check offline

| Check | AC | How |
|---|---|---|
| one issue, marker on line 1, body = brief, parent, card, spawn prompt | 9 | follow §3 with the fake `gh`; the log has `T-create`, `T-dbid`, `T-link` (parent = slice, or frontier ticket, never the map), `B-add`, three `B-set` |
| find before create | 10 | fixture: `T-subissues` returns the marker issue; the log has no `T-create`. Fixture: unlinked issue only in `T-recent`; the log has `T-link` and no `T-create` |
| shape of the closing comment, order, status | 11 | `post-text.sh render` on a draft; first line, visible fields, one `<details>`; the log shows `T-comment` then `T-close` then `B-set` |
| the resume table | 12 | the four fixtures; count marker comments after |
| size | 13 | **Big result** (150,000 characters) through `elide` and `split`: every part under 65,536 characters, part 1 holds Status and Summary, concatenated details equal the input; a 100,000-character inline diff is elided with a commit URL |
| cut-off keeps Progress | 14 | text check of the resume step; fixture draft with `Status: working` is never rendered for posting (`render` is not called on it) |
| rework | 15 | feedback fixture: a new sub-issue titled `rework 1: …` with the feedback template; no `T-edit-comment` on an earlier task; `Rework rounds` equals the count |
| shell and messages | 16, 17 | diff the *Shell* section against 1.3.0 (zero lines); search agent files and templates for tracker writes (none); the Messages section lists exactly §11's files |
| scan | 18 | **Home-path result** and a fixture token string: `scan` exits 1 and the log has no `T-comment`; clean text posts; `--needs-you` also rejects `work/12/` and `item/12` |
| limits | 19 | `FAKE_GH_FAIL` per [64-gh-calls](64-gh-calls.md) §3: (a) limit message with `Retry-After`: one wait, one retry, then stop; (b) link nesting error: stop at once; in both the unlinked issue is named and a needs-you comment precedes `Waiting on you`; resume finds it |
