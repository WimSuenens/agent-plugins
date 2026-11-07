# Contract 60 — The walk: what is read, how much, what is compared, where a finding goes

Slice [#60](https://github.com/WimSuenens/agent-plugins/issues/60) · Requirement [60-gemba-sample](../docs/requirements/60-gemba-sample.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on [49-andon-process](49-andon-process.md), [57-run-close](57-run-close.md), [60-gemba-sample](60-gemba-sample.md)

Serves AC-2, AC-3, AC-5, AC-6, AC-7, AC-9. The walk is written **once**, in `references/hansei.md` section 6 (*The gemba walk*); `skills/run/SKILL.md` step 8.3a is one sentence that points to it. Wording is the developer's; every command, number and refusal below must appear in that section.

## 1. Where and when

- **Step 8.3a** of `skills/run/SKILL.md`, and item **3a** of `hansei.md` section 5: after 8.3 (token totals), before 8.4 (fill the template and post). It is not renumbered 8.4 because the requirement, the ADRs, the baseline, the A3, the tests and the runbook cite 8.4, 8.6, 8.10 and 8.11 (the reason #57 gave for D12). It is done after the merge approval (8.1), so lead time (which ends at the approval) holds none of it, and the Lead's own spend, which 8.3 takes up to the approval, holds none of it. The walk's time and cost are in no measure; the line's characters-read figure is a label ([60-gemba-line](60-gemba-line.md) §5).
- A walk is done for an **item** only. A frontier round has no hansei record and no walk. An item run on a pre-release install (calibration) has no text for it and no line.
- One walk per item. The Lead never starts a second walk of another stage, even when the first found nothing.

## 2. The rule that holds the walk to the work, not the report

- **Evidence**, in this order of preference:
  1. **The transcript** of every agent id in the sampled row's `Agents` cell, found as `hansei.md` finds transcripts (`find ~/.claude/projects -name 'agent-<agent id>.jsonl'`).
  2. **The commits and the result file**, used for the whole row when any of the row's transcripts cannot be read (missing, deleted, not JSON, `jq` missing): the sampled role's commits on `item/<id>` whose subject starts `#<id> <role>: `, with their diffs, and the role's result file in `work/<id>/` **with its `Summary` field removed**.
- **Not evidence, never read as such**: the result's `Summary`, the completion notice's text, the stage summary comment, and the final reply of the transcript. The final reply is kept in the filtered view only so the Lead sees what the agent **claimed**; a claim becomes a difference only when the calls, results or diffs contradict it, and a `Done` item is *traced* only by a tool call, a tool result or a diff, never by a sentence of the agent's. In the commits fallback the result file's `Progress`, `Artifacts` and `Decisions` lines are claims in the same way: an artifact path is traced only when a commit diff touches it.
- **Which commits.** Those of the sampled role on `item/<id>` with committer time not before the row's `Start (UTC)` (omit when that cell is not a captured time) and before the `Start` of the role's next row, if any. **Which brief.** The role's `NN-brief-<role>.md` and `NN-feedback-<role>.md` files in `work/<id>/`, in `NN` order, matched to the role's role rows in log order: the row's ordinal among the role's rows is the file's ordinal. **Which result file.** The same ordinal among the role's `NN-result-<role>.md` files. When the brief of the row cannot be found: `not captured (brief not found)`.

## 3. The cap, enforced by the command

The walk reads **only** through the commands of `hansei.md` section 6; no other command, file read or `gh` call brings text of the evidence, the brief or the log into the Lead's context for the walk. Total read for one walk: **at most 30,000 characters printed** (counted by `wc -c`, everything the commands print, count lines and newlines included). Every read command ends in `head -c <budget>`, with `<budget>` = **29,900** minus what the walk has already read (100 characters are kept back for the count lines and newlines, as built in `hansei.md` section 6), so `n` is at most 29,900; when it is 0 or less, no further read is made. The walk never reads a whole transcript.

Reference shape (the developer may change quoting, not the properties: a filter that keeps what is listed, a `head -c`, a count of what was returned, a separate count of the whole view):

```
# 1. the brief (counts toward the total)
f="$(mktemp)"; head -c 29900 "work/<id>/<brief file>" > "$f"; wc -c < "$f"; cat "$f"; rm -f "$f"

# 2. the transcript view, per agent id, in Agents order, one cap for all
view() {
  for t in <transcript paths>; do
    echo "== agent <id>"
    jq -r 'def blocks: (.message.content | if type == "array" then .[] else empty end);
           select(.type == "assistant" or .type == "user") | blocks
           | if .type == "tool_use" then "CALL " + .name + " " + ((.input | tojson) | .[0:300])
             elif .type == "tool_result" then "RESULT " + ((.content | if type == "array" then (map(.text? // "") | join("")) else tostring end) | split("\n")[0] | .[0:200])
             else empty end' "$t"
    jq -rs '[ .[] | select(.type == "assistant") | .message.content | if type == "array" then .[] else empty end | select(.type == "text") | .text ] | last // "" | "FINAL " + .[0:1500]' "$t"
  done
}
f="$(mktemp)"; view | head -c <budget> > "$f"; wc -c < "$f"; cat "$f"; rm -f "$f"
view | wc -c        # m: the size of the whole view, for "n chars of m"
```

The commits fallback keeps the same shape: `git -C <worktree> log --no-merges --format='%H %s' item/<id>` filtered to the role's subjects and window, then for each sha `git -C <worktree> show --unified=0 --format='commit %h %s'`, kept to the lines that start `commit `, `diff --git `, `+` or `-` (the diffs' file lists and changed lines), the result file through `awk` dropping the `Summary:` field (from its line to the next line that starts `Status:`, `Progress:`, `Artifacts:`, `Decisions:`, `Open questions:`, `Missing:` or `Decision card:`), then `head -c <budget>`. A view is ordered brief, then evidence; the figure `n` is the sum of the characters returned.

- **Partial.** The evidence view is longer than the budget: the walk is `partial`. It reads the head of the view; it may then make **one** more bounded read of the specific part a `Done` item points to (a `grep -n` over the view for a path or a command, `git show <sha> -- <path>`), with `head -c` on what is left of the budget, and no more. It writes only what it found so far.
- **The extra bounded read** takes only a worktree-relative path with no `..` and no leading `-`, or a hex sha, always quoted and placed after `--`; a path or sha that fails that test gets no extra read (security N1). It does not widen the cap.
- `n` = characters read in all (brief included). `m` = the brief's characters plus the whole view's (`view | wc -c`). A walk that read the whole view is not partial.
- The commands read the Lead's own checkout (`work/<id>/`, the item branch) and the transcripts the standard already reads (`cut-offs.sh`, `token-spend.sh`); the commit window is a `git log` filter, no new tool. `jq` is the one dependency, already required by the token script; with `jq` missing, the transcript is unreadable and the fallback applies.
- The reference filter is a contract of properties, not yet run against a real project transcript. The developer runs it once on a transcript of this item's own agents and says so in the result; real readability is the unverified item 3 of the requirement.

## 4. What is compared

Read the evidence against **two** things, and look for **exactly three** things:

- the **brief** of the row (each `Done` item, each `Constraints` item, the `Output` paths). *Counting:* an item is a bullet line under the field; where a field is one line, each `;`-separated clause is an item. `d` = Done items, `c` = Constraints items.
- the **row** in the stage log (`Result`, `Notes`, `Waits`).

The three things:

1. a `Done` item with **no trace** of the work in the evidence;
2. work in the evidence that the brief's `Constraints` or the role's ownership forbids (ownership is read as kind 3 reads it: `git show origin/main:docs/agents/factory.md`, never the worktree copy);
3. a row `Result` or `Notes` that the evidence **contradicts** (`done` while a `Done` item is untraced is thing 1; `pass` while the transcript shows a failing check is thing 3; `Notes` `resumed after a limit` with no interruption in the transcript is thing 3).

A walk that checks the stage log alone is not a walk (AC-2, AC-3).

**Found.**

| Outcome | Written as |
|---|---|
| none of the three, whole view read | `nothing (<d> Done items and <c> constraints checked)`; a `nothing` without both counts is refused |
| none of the three, partial | `nothing in the part read (<n> chars of <m>)`; never plain `nothing` |
| one or more | `difference: <one sentence>` for the first by brief order (a lower `Done` item before a higher, then a `Constraints` item, then a path, then a row field); the others, if any, go in the 5 Whys' evidence lines, not in the line |

**The sentence.** One line, at most 200 characters, no `;`, no newline, no copied text of the transcript, the brief or a commit message. Form: `<the Done item k | the Constraint k | the path P | the row's Result|Notes> <what the evidence shows>, process object: <brief | inputs | standard text | tooling | ownership table | order of stages>`. Its subject is a brief item, a path or a log field, never a person, a role's care, or a model. A role may appear only as where the event happened (`the developer's commits`). It is tested by the refusal rules of `skills/run/SKILL.md` *The 5 Whys* (substitute a process object for the subject; if the sentence loses its meaning it names an actor), which the standard **points to and does not restate**.

## 5. Where a finding goes (AC-7)

A `difference` always goes to a 5 Whys, **before the record is posted** (before 8.4). The place: **an andon of kind 7 with no paused agent**. It reuses the Andon comment, the 5 Whys rule, the refusal and the `## Refused drafts` section, and puts the link on the record's `abnormalities` line; the alternative (a comment of its own) would add a marker for no gain (rejected, D3).

How the andon's procedure (`skills/run/SKILL.md`, *Andon*, *Procedure*) applies to a walk raised at 8.3a, after the approval:

| Procedure step | At 8.3a |
|---|---|
| 1 stamp, open an `andon` wait | **stamp, no wait.** A wait is time the item was held; the lead time ended at the approval (8.1), so a wait after it would be outside the total and would break `agent working = total − the five waits`. The `## Abnormalities` row is opened; no `## Waits` entry; measure 1's `andon` part is unchanged. |
| 2 stop the running agent | none: no agent is running or paused. `Paused agent` `-`. |
| 3 the 5 Whys, in `work/<id>/NN-andon-lead.md` | **applies**, under *The 5 Whys* unchanged. The chain's cause lines may cite the evidence (a commit sha, a transcript timestamp, a brief line). |
| 4 countermeasure | **fixed**: the walk writes no override. The approval covered the diff as shown, and a commit after it would change what is merged. The countermeasure is `none` (a process item the project can change) or `none: needs a plugin change` (the item lives in the plugin's text); the proposal is noted in the map's Factory run section, as for an andon raised outside any worktree. |
| 5, 6 resume, refused resume | none. |
| 7 post, complete the row, add the stage-log row, commit the lead state | **applies**: the `Andon A<n>` row is a lead row with `Waits` `-`, `Notes` `kind 7 other; gemba walk after approval; override none`; the lead-state commit of 8.6 carries it. |

- **Detection.** Kind 7 ("for an event that fits no kind 1 to 6 and still ought to stop the line"): the walk's `difference` is such an event; its comment's `fit` line reads that the Lead's gemba walk compared a sampled stage's evidence with its brief and found a difference, which no kind 1 to 6 observes. At 8.3a the line has already stopped (the approval), so "stop" is the record of the finding and its 5 Whys.
- **Timing rules held.** Lead time and its split: unchanged (no wait). Kind 4: lead rows are never tested. Kind 3 over the whole branch at the approval: already done at 8.1; the walk commits nothing under `plugins/` or an owned path (only the lead state, which the existing 8.6 commit carries). Token spend: 8.3 ended at the approval; the walk's reading is in no measure. The Andon comment, `carried on` time and the `Abnormalities` row's `Resumed` (the carry-on time) are as for an andon that paused nobody.
- **The comment's fixed lines** for a walk: `kind: 7 other`, `raised by: lead`, `paused: no agent paused`, `fence check: not run: no override proposed`, `countermeasure: none | none: needs a plugin change`, `supersedes: none`, `standard change proposed: <one line, when the item is in the plugin's text> | n/a`.
- **Which of the two `changes` outcomes.** The chain's last line `process item to change: …` names an object. In a file under the plugin root (the run skill, a reference, an agent file, a script, the setup skill's template) the outcome is `none: needs a plugin change` and `standard change proposed` is filled; otherwise (the item's own brief or inputs, the project's `docs/agents/factory.md`, a project doc) the outcome is `process item: <that item> (<comment URL>)`.
- **Accepted and refused.** A refused chain, or a `found` sentence that fails the refusal test, is redone; the refused draft stays under `## Refused drafts`; **nothing is written to the line until a chain is accepted and the comment posted** (the line carries the comment's link). A difference never ends as `changes nothing`.

## 6. Not captured (AC-5)

| Case | The line |
|---|---|
| (a) transcript unreadable, commits and result file readable | the walk is done from them; `read commits and result file …` |
| (b) transcript unreadable and the commits or result file cannot be read (the role worked in a project the Lead cannot reach) | `row <#> <stage> (<role>); not captured (<reason>)`, reason `transcript and commits unreadable` |
| (c) no role row | `not captured (no role stage ran)` |
| (d) an agent id of the row has no transcript and the role has no commit in the window | `row …; not captured (no transcript and no commits for agent <id>)` |
| brief not found | `row …; not captured (brief not found)` |

None reads `nothing`, none reads a count of 0 in place of a missing walk, none is blank or dropped. A walk that read a transcript for some agents and not others uses the fallback for the whole row (§2).

## 7. Why gemba transfers (AC-9) — one line, in `hansei.md` section 6, nowhere else

> Gemba transfers to an agent factory because an agent's summary is written by the party being checked and the stage log holds clocks and counts, not what was done, so the work shows only in the transcript or the commits; the Lead goes and looks at a sample instead of trusting a report.

## 8. Worked example

Item #14 ([60-gemba-sample](60-gemba-sample.md) §2) sampled row 4, Build, developer `c44a10`. Brief `04-brief-developer.md` has three `Done` items and two `Constraints`; the transcript is readable.

1. Read the brief: 1,240 characters returned.
2. View: `view | head -c 28660` returned 21,480 characters; `view | wc -c` gives 21,480, so the whole view was read, not partial. `n = 1,240 + 21,480 = 22,720`, `m = 22,720`.
3. Compare: `Done` items 1 and 2 are traced by `CALL Edit` and a commit diff; item 3 (a file list at `plugins/x/ref.md`) has no call, result or diff; the result's `Summary` says it was done. That is thing 1.
4. A `difference`: sentence `Done item 3 has no trace in the calls or the commit diffs, process object: the brief`. The chain, ending `process item to change: the brief named no output path for Done item 3`, is accepted; that item is this item's own brief, so the outcome is `process item:`. Andon A1 (kind 7) is posted at `https://github.com/example/shop/issues/14#issuecomment-333`.
5. The line (grammar [60-gemba-line](60-gemba-line.md) §2):

```
- gemba: row 4 Build (developer); read transcript 22720 chars; found difference: Done item 3 has no trace in the calls or the commit diffs, process object: the brief; changes process item: the brief named no output path for Done item 3 (https://github.com/example/shop/issues/14#issuecomment-333)
```

Contrasts: the same sampled row with every item traced reads `found nothing (3 Done items and 2 constraints checked); changes nothing`. A 200,000-character view with the brief of 1,240 reads `read transcript 29900 chars, partial (cap)`; nothing found reads `found nothing in the part read (29900 chars of 201240)`.
