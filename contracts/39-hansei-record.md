# Contract 39 — Hansei record (schema v2)

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Requirement [39-hansei-record](../docs/requirements/39-hansei-record.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md)

Companion contracts: [39-stage-log](39-stage-log.md) (what the record is computed from), [39-plugin-scripts](39-plugin-scripts.md) (label, bump check, token spend), [39-standard-changes](39-standard-changes.md) (which plugin file says what).

The **hansei record** is one comment on the item's slice ticket, in the project's own tracker. It is posted once, at the person's merge approval, and edited once, after the resurvey, to fill measure 7. There is never a second record for the same item.

## 1. Where the template lives

The record template and the field definitions below are written into a new standard-work file, `plugins/factory/references/hansei.md`, together with the stage log format ([39-stage-log](39-stage-log.md)). `skills/run/SKILL.md` links it with `${CLAUDE_PLUGIN_ROOT}/references/hansei.md`. Standard work therefore becomes `skills/run/SKILL.md`, `references/*.md`, `agents/*.md` (see [39-plugin-scripts](39-plugin-scripts.md) §1).

## 2. Marker

The body's **first line** is exactly:

```
<!-- factory:hansei v2 -->
```

- Regex a reader uses to find a record of any schema: `^<!-- factory:hansei v([0-9]+) -->$` on the first line of a comment body.
- A script finds the record without reading the rest, counting only comments by the account that posts records (the marker alone is not proof: anyone who can comment on the ticket can type it):
  `me="$(gh api user --jq .login)"; gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | select(.user.login == "'"$me"'" and (.body | startswith("<!-- factory:hansei v"))) | {id, html_url, created_at}'` (`gh api --jq` takes no `--arg`, so the login is spliced into the filter; a GitHub login holds only letters, digits and `-`, so it cannot break out of the string).
- The HTML comment is invisible on GitHub; the visible heading on line 2 carries the item for a human.
- **Schema version.** `v2` is this contract. Any change to a field's key, order, grammar or meaning bumps it (`v3`, …). Adding gemba, A3 or andon fields later is a new version. A reader that meets an unknown version skips the record and says so; it never guesses.
- **v1 → v2** (the AC-17 fix round, before release 1.0.0 was tagged): measure 1 gains `stalled` and `interrupted`, and `agent working` no longer includes that time, so a v1 `agent working` and a v2 one measure different things; `<fpy>` gains `pass first time (<n> low)`, and "pass first time" is defined by severity (§4). Both are meaning and grammar changes, hence the bump. Only the acceptance demo's record (factory-sandbox #2) was ever written in v1; release 1.0.0 writes v2. A reader never compares measure 1 or 2 across the two versions.

## 3. Layout

Fixed lines, fixed order. Every line below is always present. Angle brackets are filled in; nothing else changes.

```
<!-- factory:hansei v2 -->
## Hansei: #<id> <slice title>

- series: <release | calibration (pre-baseline)>
- plugin: factory <semver>
- standard: <64 hex>
- tooling: <64 hex>
- context: wayfinding <version>; mattpocock-skills <version>
- active overrides: <none | name (since YYYY-MM-DD); …>
- stage-log cross-check: largest gap <N>m (<row>: <evidence>)

### Measures

1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>; stalled <dur>; interrupted <dur>
2. first-pass yield: qa <fpy>; security <fpy>; acceptance demo <fpy>
3. rework: feedback briefs product-owner <n>, architect <n>, developer <n>, qa-engineer <n>, security-reviewer <n>, devops <n>, docs-writer <n>; overturned two-way decisions <n>
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend <tok>; peak context <n>
   - product-owner: spend <tok>; peak context <n>
   - architect: spend <tok>; peak context <n>
   - developer: spend <tok>; peak context <n>
   - qa-engineer: spend <tok>; peak context <n>
   - security-reviewer: spend <tok>; peak context <n>
   - devops: spend <tok>; peak context <n>
   - docs-writer: spend <tok>; peak context <n>
6. person's touches: decision cards <n>; demos <n>; approvals <n>; overturns <n>; other <n>
7. doors: <pending resurvey | not captured (reason) | per-line list below>
   - <Under test line name>: <confirmed | contradicted | not exercised>
```

### Value grammar

Every value slot (`<dur>`, `<n>`, `<fpy>`, `<tok>`, a version, a hash) holds exactly one of:

| Value | Meaning |
|---|---|
| a measured value | as defined per field below |
| `0` (or `0m`) | measured, and truly zero |
| `n/a (did not run)` | the stage or role did not run on this item. Allowed only in measures 2 and 5 (measure 3 counts briefs received, which is a known `0` for a role that never ran), and only for a stage or role that did not run. |
| `not captured (<reason>)` | the Lead could not observe it. The reason is short and always present. |
| `pending resurvey` | measure 7 only, between posting and the resurvey edit |

Honesty rule (fenced by ADR 0011): an uncaptured value is never `0`, never blank, never dropped. The line stays in its place. `n/a` never stands in for `not captured`.

Formats:

- `<dur>`: whole minutes, rounded to the nearest minute, as `<h>h<mm>m` from one hour (`3h07m`) or `<m>m` below it (`42m`, `0m`).
- `<n>`: a plain integer, no separators.
- `<fpy>`: `pass first time` | `pass first time (<n> low)` | `failed first time` | `n/a (did not run)` | `not captured (<reason>)`. The `(<n> low)` form is used when the first verdict passed with `<n>` ≥ 1 findings below minor (§4, measure 2); with none, the plain form.
- `<tok>`: `<total> (input <i>, cache write <w>, cache read <r>, output <o>)`, plain integers, `total = i + w + r + o`. Or `n/a (did not run)` / `not captured (<reason>)` for the whole slot.
- Times anywhere in the record: UTC, `YYYY-MM-DDTHH:MMZ`.

## 4. Field definitions and sources

### Header

| Field | What it holds | Source |
|---|---|---|
| title line | `#<id>` and the slice ticket's title | `gh issue view <id> --json title` |
| `series` | `release` for an item run on a semver release. `calibration (pre-baseline)` for an item run on a pre-release install (this run, frozen on `9147301f75c3`; ADR 0012 point 6). | the label at item start |
| `plugin` | `factory <semver>` from the label; for a pre-release install `factory <install dir name> (pre-release install, no semver)` | lead state `## Label` ([39-plugin-scripts](39-plugin-scripts.md) §1) |
| `standard` | standard fingerprint, 64 lowercase hex | same |
| `tooling` | tooling fingerprint, 64 lowercase hex | same |
| `context` | dependency versions, context only, never a reset trigger (ADR 0012). Both dependencies of `plugin.json`, in that order. | lead state `## Label`; see [39-stage-log](39-stage-log.md) §1 for how each is read |
| `active overrides` | each active override by name and start date, or `none` when the project's `docs/agents/factory.md` has no `## Overrides` section or it lists none (ADR 0011 point 4) | `docs/agents/factory.md` at approval time |
| `stage-log cross-check` | the largest gap found by the cross-check, with the stage-log row and the evidence it was measured against | [39-stage-log](39-stage-log.md) §4 |

The label is copied from the lead state, as computed at item start. The record never recomputes it.

### Measures

| # | Key | Counted | Source |
|---|---|---|---|
| 1 | `lead time` | **total** = approval time − start of the `Start item` row. **waiting for the person**, **waiting on limits**, **stalled**, **interrupted** = the item-held waits of that kind (stage log `## Waits`, `held item: yes`, after the close scan has added the cut-offs no notice reported; kinds and how each is detected in [39-stage-log](39-stage-log.md) §3). Overlaps are counted once: within a kind as one stretch, and across kinds to the kind that comes first in this line's order (person, limits, stalled, interrupted). **agent working** = total − the four waits, so agent working + person + limits + stalled + interrupted = total. | stage log |
| 2 | `first-pass yield` | per stage (QA, security, acceptance demo), from the stage's **first** run only. **Pass first time** = the first verdict is `pass` **and** that run lists no finding at or above minor. Below minor means a severity of `low`, `info`, `trivial` or `note`; every other severity (`minor`, `medium`, `major`, `high`, `critical`, `blocker`), and a finding with no severity, counts as at or above minor. Written `pass first time` with no finding below minor either, `pass first time (<n> low)` with `<n>` findings below minor, whether or not the Lead routed them as feedback. **Failed first time** = the first verdict is not `pass`, or it lists a finding at or above minor, or (demo) any criterion failed. `n/a (did not run)` when the stage was skipped. | QA and security results, demo outcome, in `work/<id>/` |
| 3 | `rework` | per role, the number of feedback briefs that role received (any `Source`); then the number of two-way decisions overturned by a `Source: lead` feedback brief. Roles that ran and got none read `0`; roles that never ran read `0` too (a count of briefs received is known to be zero). | `work/<id>/NN-feedback-*.md` |
| 4 | `escaped defects` | always `not captured (tracing deferred until the first defect found in a merged item)` in v2 | deferred (map, Deferred) |
| 5 | `tokens` | per role, the Lead first, fixed role order. **spend**: `message.usage` summed over every transcript of that role's agents on this item (resumes and feedback rounds included), one count per distinct `message.id`; for the Lead, its main-session transcript(s) between the `Start item` start and approval. **Truncated transcripts**: a transcript cut by a stall or an interruption lost the request in flight, so its sum is short by an unknown amount; the role's spend then reads `not captured (transcript truncated by <kind>)`, never a number, `<kind>` being `stalled` or `interrupted`. The Lead recognises truncation by either of two signals: (a) **the wait**: a `stalled` or `interrupted` wait in `## Waits`, logged at a notice or added by the close scan ([39-stage-log](39-stage-log.md) §3, *Cut-offs at close*), names one of the role's agents (or `lead`) in its `Agent` column; `<kind>` is that wait's kind (the earliest, when there are several). A recovered cut-off counts as much as a final one: the request it cut was lost either way; (b) **the transcript**: `token-spend.sh --require-end` exits 6 for one of the role's transcripts ([39-plugin-scripts](39-plugin-scripts.md) §3: a cut-off marker anywhere in it, or no final reply), with no such wait logged; `<kind>` is then `unlogged`. Exit 3 or 4 there reads `not captured (<stderr line>)` as usual. **peak context**: the largest `<subagent_tokens>` (background) or `totalTokens` (foreground) across that role's completion notices that carried one; `not captured (failure notice carried no token count)` when none did; for the Lead, the `peak` the spend script reports over the same window, or `not captured (transcript truncated by <kind>)` when its spend reads so. A role with no agent on this item: `n/a (did not run)` for both. | `scripts/token-spend.sh` ([39-plugin-scripts](39-plugin-scripts.md) §3); completion notices logged in the stage log |
| 6 | `person's touches` | counts of the touches list by kind: `decision card` (an answered card), `demo` (a demo the person ran), `approval` (a merge or production yes), `overturn` (a two-way decision the person overturned), `other` (anything else the person did for the item) | stage log `## Person's touches` |
| 7 | `doors` | per **Under test** line of the slice frame, in frame order, named by its link text: `confirmed`, `contradicted`, or `not exercised`, as the resurvey found. `pending resurvey` from posting to the edit; `not captured (run stopped before the resurvey)` when the resurvey never happens. | the resurvey (step 8) |

## 5. Tracker operations

These go into the factory's tracker patch (`skills/setup-factory-skill/references/issue-tracker-github.factory.md`, `## Factory operations`), as new bullets after *Stage summary*. For projects whose section predates 1.0.0, see [39-standard-changes](39-standard-changes.md) §4. All commands run in the project's own clone; none names `--repo`, so the record lands in the project's own tracker (AC-20).

- **Find hansei**: `me="$(gh api user --jq .login)"`, then `gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | select(.user.login == "'"$me"'" and (.body | startswith("<!-- factory:hansei v"))) | .id'`. Prints the id of the record the Lead's own `gh` account posted, or nothing. A comment by anyone else that starts with the marker is ignored: it can neither block *Post hansei* nor be edited in place of the real record.
- **Post hansei**: run *Find hansei* first. When it prints nothing: `rec="$(mktemp)"`, write the filled template to `"$rec"`, `gh issue comment <id> --body-file "$rec"`, then `rm -f "$rec"`; the command prints the comment URL, ending `#issuecomment-<comment-id>`. When it prints an id, the record exists already (a resumed close): update it with *Edit hansei* instead. Never post a second record.
- **Edit hansei**: `rec="$(mktemp)"`, `gh api "repos/{owner}/{repo}/issues/comments/<comment-id>" --jq .body > "$rec"`, change only the measure 7 block, `gh api --method PATCH "repos/{owner}/{repo}/issues/comments/<comment-id>" -F body=@"$rec"`, then `rm -f "$rec"`.

`{owner}/{repo}` are filled in by `gh api` from the clone's remote. The scratch file comes from `mktemp` (the system temp directory, private to the user, outside the repo), is never committed, and is removed once the command that reads it has run.

## 6. Lifecycle at close

Step 8 of `skills/run/SKILL.md` runs in this order. The numbers are the contract; the wording is the developer's.

1. Ask **merge and clean up?**. On the yes, stamp `date -u +%FT%TZ` as the approval time: it ends the stage log's `Merge approval` row and is the touch `approval`.
2. Complete `## Waits` with the close scan ([39-stage-log](39-stage-log.md) §3, *Cut-offs at close*), then cross-check the stage log against git and the tracker ([39-stage-log](39-stage-log.md) §4).
3. Total token spend per role ([39-plugin-scripts](39-plugin-scripts.md) §3).
4. Fill the template, measure 7 reading `pending resurvey`, and *Post hansei*. Write `hansei: <comment URL> (measure 7 pending)` into the map's **Factory run** section, because `work/<id>/` is about to go and the map is what survives.
5. Environment teardown, when the item had one.
6. Remove `work/<id>/`, in the item worktree, in this order, which never meets a dirty file and never reaches outside the worktree (security L8, L9):
   0. Guard. Every command names the worktree by its absolute path, so the shell's working directory does not matter (it starts in the main checkout, and a `cd` into `../wt/<id>` does not persist):
      ```
      case "<id>" in ''|*[!0-9]*) echo "close: id not numeric" >&2; exit 1 ;; esac
      w="$(git worktree list --porcelain | awk -v b="branch refs/heads/item/<id>" '/^worktree /{p=substr($0,10)} $0==b{print p}')"
      [ -n "$w" ] || { echo "close: no worktree for item/<id>" >&2; exit 1; }
      if [ -L "$w/work" ] || [ -L "$w/work/<id>" ]; then echo "close: work/ is a symlink" >&2; exit 1; fi
      ```
      When the guard stops, the Lead stops the close and puts it to the person; nothing has been removed.
   1. Commit the lead state, staging only the protocol's files: `git -C "$w" add -- "work/<id>/[0-9][0-9]-*.md"` (lead state, briefs, results, feedback, questions, including any not yet committed), then `git -C "$w" add -u -- "work/<id>"` (changes to tracked files), then, when anything is staged (`git -C "$w" diff --cached --quiet` exits 1), `git -C "$w" commit -m "#<id> lead: close"`. Any other untracked file under `work/<id>/` (a scratch dump, a copied transcript, an `.env` a role made for a test) is never staged: `--merge` keeps a commit in the project's history for good, and those files were never meant for it. The next step deletes them.
   2. `git -C "$w" rm -r -q -- "work/<id>" && rm -rf -- "$w/work/<id>" && git -C "$w" commit -m "#<id> lead: remove work/"`. `rm -rf` takes what git does not track (ignored files such as `.DS_Store`, and the untracked files 6.1 left out); with `&&` it never runs after a failed `git rm`. This is the last commit on `item/<id>`.

   No `-f` is needed: after 6.1 nothing tracked under `work/<id>/` differs from `HEAD`. The record was posted at step 4, so its `created_at` is earlier than both commits (AC-18): the record is always posted before `work/` is removed.
7. *Merge PR* (with the release tag, [39-standard-changes](39-standard-changes.md) §5), board to Done.
8. Resurvey with the frame's **Under test** list.
9. *Edit hansei*: measure 7 gets one line per Under test line. Remove the `hansei:` pointer from the Factory run section.

When the person stops the run between 4 and 8, the Lead edits measure 7 to `not captured (run stopped before the resurvey)` before it stops. A later session that finds the pointer still in the Factory run section does the same.

## 7. Worked example

A fictional item #12 in a scratch project, factory 1.0.0, after the resurvey edit; its stage log is the worked example in [39-stage-log](39-stage-log.md) §5. QA failed once, security passed with two low findings, no demo, no devops stage, one decision card, one overturn, one limit hit, one machine sleep during the build, a mid-stream cut-off QA recovered from by itself, and a docs-writer that stalled after writing its `done` result.

```
<!-- factory:hansei v2 -->
## Hansei: #12 Export a report as CSV

- series: release
- plugin: factory 1.0.0
- standard: 3b9f0c2e7a41d65f0e8c9a7b2d1f4e6a8c0b3d5e7f9a1c2b4d6e8f0a1b3c5d7e
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- context: wayfinding 5a136f2eaa0a; mattpocock-skills 1.3.1
- active overrides: none
- stage-log cross-check: largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)

### Measures

1. lead time: total 4h41m; agent working 3h02m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m
2. first-pass yield: qa failed first time; security pass first time (2 low); acceptance demo n/a (did not run)
3. rework: feedback briefs product-owner 0, architect 0, developer 1, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 1
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend 2841177 (input 1204, cache write 210338, cache read 2601870, output 27765); peak context 96412
   - product-owner: spend 301554 (input 88, cache write 41230, cache read 254101, output 6135); peak context 53942
   - architect: spend 612090 (input 140, cache write 70221, cache read 530417, output 11312); peak context 81277
   - developer: spend not captured (transcript truncated by interrupted); peak context 141210
   - qa-engineer: spend not captured (transcript truncated by stalled); peak context 74480
   - security-reviewer: spend not captured (transcript agent-a41f09.jsonl unreadable); peak context 48820
   - devops: spend n/a (did not run); peak context n/a (did not run)
   - docs-writer: spend not captured (transcript truncated by stalled); peak context not captured (failure notice carried no token count)
6. person's touches: decision cards 1; demos 0; approvals 1; overturns 1; other 0
7. doors:
   - Measures: confirmed
   - Export format: contradicted
```

Before the resurvey edit, the same comment read `7. doors: pending resurvey` with no sub-lines.

How the new v2 values follow from the stage log: W3 (`interrupted`, developer `c44a10`) is a held wait, measure 1's 18m; W4 (`stalled`, docs-writer `e90b55`, logged at its notice) and W6 (`stalled`, QA `d21f77`, found by the close scan) are held waits, measure 1's 11m + 4m = 15m; agent working is 4h41m − 51m − 15m − 15m − 18m = 3h02m. The same three waits name those agents, so the developer's, the QA's and the docs-writer's spend reads `not captured (transcript truncated by …)` (signal a). W6 shows why a run that ended normally is not enough: QA handed back at 15:10Z, but the request the cut-off lost is missing from its sum. The developer's peak is its round-2 notice (141210), the largest that carried a count; QA's is its round-2 notice (74480); the docs-writer's only notice was the failure notice. The security review's first run passed with two `low` findings, hence `pass first time (2 low)`; a single `medium` there would have made it `failed first time`.

### Worked example: this item's own calibration record (AC-22)

#39 runs on the frozen install, which has no template; the Lead writes the record by hand from this contract, running the branch's `scripts/fingerprint.sh` against the frozen install root. Its header reads (fingerprints computed on 2026-11-04 over `~/.claude/plugins/cache/wimsuenens/factory/9147301f75c3`):

```
<!-- factory:hansei v2 -->
## Hansei: #39 Hansei record end to end, shipped as release 1.0.0

- series: calibration (pre-baseline)
- plugin: factory 9147301f75c3 (pre-release install, no semver)
- standard: 48f28915d19a3b1261c98220136dcab0098061d0c62c0d1ee7a290d8ea6d1c20
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- context: wayfinding 5a136f2eaa0a; mattpocock-skills not captured (<reason>)
- active overrides: none
- stage-log cross-check: …
```

Its measures follow the v2 layout. Where the manual stage log lacks a figure (for example spend, if the Lead recorded only peak context), the value reads `not captured (<reason>)`, and the resurvey lists those fields (AC-22).

## 8. Acceptance criteria → contract

| AC | Where |
|---|---|
| AC-1 | [39-standard-changes](39-standard-changes.md) §1 |
| AC-2 | [39-plugin-scripts](39-plugin-scripts.md) §1 (release read from `plugin.json` under the given root) |
| AC-3, AC-4 | [39-plugin-scripts](39-plugin-scripts.md) §1 (algorithm, file sets, worked example) |
| AC-5 | [39-plugin-scripts](39-plugin-scripts.md) §1 (two fingerprints); this contract §3 `standard`/`tooling` |
| AC-6 | §4 `context`; [39-stage-log](39-stage-log.md) §1 |
| AC-7 | [39-standard-changes](39-standard-changes.md) §5 |
| AC-8, AC-9, AC-10 | [39-plugin-scripts](39-plugin-scripts.md) §2; [39-standard-changes](39-standard-changes.md) §3 |
| AC-11, AC-12, AC-13 | [39-stage-log](39-stage-log.md) |
| AC-14 | §2, §3 |
| AC-15 | §4 |
| AC-16 | §3 value grammar; [39-plugin-scripts](39-plugin-scripts.md) §3 exit codes |
| AC-17 | §4 sources (every measure but 4 has an observable source) |
| AC-18, AC-19 | §6 |
| AC-20, AC-21 | §5 (no `--repo`); [39-standard-changes](39-standard-changes.md) §6 |
| AC-22 | §7, second example |
