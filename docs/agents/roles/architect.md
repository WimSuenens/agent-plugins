# Role file: architect

Project rules, checks and knowledge for the architect role, kept under version control. Only the architect role reads this file and its skills folder, `docs/agents/skills/architect/`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

## Knowledge

## Skills used

## Migrated memory

<!-- migrated: factory-architect/andon-contract-craft.md -->
---
name: andon-contract-craft
description: Lessons from writing the andon (stop-the-line) contracts for the factory plugin: replayable detection rules, circular links, run identity, record side effects of a pause
metadata:
  type: feedback
---

Detection rules a second role must replay: give each finding a fixed-slot signature (object, trigger, guard, criterion, field) written from the one-line text only, then match by clauses. A free "feels the same" rule is not replayable. Say what to do when a slot is missing (do not flag, write `unclear`). Tell the replayer not to pick a control pair that is itself a repeat (a residual of an earlier fix).

**Why:** the requirement demanded QA replay five known repeats plus control pairs, with the architect banned from running it.
**How to apply:** any "detect X in logs/findings" contract; include a worked table with the real cases and one control.

Circular references: a comment that names an override and an override that names the comment need a `pending` placeholder and a second commit. Decide the order in the contract.

Run identity: tie a "run" to something that already has a number (the map issue), and bind "next run" at the first worktree the run creates, because the next map does not exist when the person answers keep.

Side effects of a pause on existing records: `TaskStop` writes a request-interrupted entry and the pause leaves a silent gap, so the old cut-off scan would count it as a stall; spend is short too. Write the reconciliation rule (a scan line touching an andon wait is that wait) and the truncation kind in the same contract that adds the wait kind.

Edits to a file in a path another role owns (docs/agents/factory.md) need an ownership row, and a path-matching rule must say how it treats section rows.

Do not renumber steps that other documents cite ("step 9"); add a step after it.

<!-- migrated: factory-architect/baseline-a3-contract-craft.md -->
---
name: baseline-a3-contract-craft
description: Craft for contracts that derive a page from records (baseline, per-run report): check every expected value for self-consistency, where state can live after cleanup, source of each label
metadata:
  type: feedback
---

When a requirement's worked expected values are the replay target, write the rule so every example comes out exactly, then list each place two examples disagree (counts that sum to n vs one item with two lines; same field spelled two ways) as a question for the requirement's owner instead of silently picking.

**Why:** #57's AC-3 had doors "summing to n" next to `confirmed 2` for one item, and `not captured 1` next to `not captured (2 of 2 items: ...)`; QA compares strings.

**How to apply:**
- Before placing a note "in the stage log", check when the log is deleted (`work/<id>/` goes at step 8.6); put later notes in a surviving place (the map's Factory run section).
- For a derived page, give each label (date, drop note, reference) a named source that is not a figure and not a store: comment `created_at`, override statuses on main, a report's answer line. A removed override leaves no trace, so a drop needs the report line.
- Record the one-run window with a run list on a surviving ticket; do not infer membership from dates.
- A find rule must never depend on a best-effort step (pin), or its failure makes a second issue.
- Renumbering a step breaks cited numbers; fold new content into the existing number and renumber only the sub-steps.
- Settle/close rounds that brief a role need a place for messages; name it and add the protocol bullet.

<!-- migrated: factory-architect/board-state-contract-craft.md -->
---
name: board-state-contract-craft
description: Moving run state from lead files to a tracker board — re-pointing readers without losing a measure, F7-safe field type, fake-gh op list, scripts for order-sensitive steps
metadata:
  type: feedback
---

When a record moves out of a file into the tracker, walk every reader first (grep the old section names) and write a reader table: reader, old source, new source, what changes. If all re-point, no question to the lead is needed; say so up front.

**Why:** the brief made "a reader cannot be re-pointed" a stop condition; a table proves it either way.

**How to apply:**
- Keep the old tables verbatim in one mutable ledger comment; take times from the tracker's own created/closed stamps and never copy them. Replays then compare by stage and role (row numbers shift when lead/person rows go).
- A Number field cannot hold `not captured (...)` and a blank beside a note is still a blank: use TEXT fields with a stated grammar (fence F7).
- Give QA a closed list of tracker operations with ids and a fake `gh` interface (log of argv/stdin, per-op answers, fail switch). Order-sensitive steps (migration phases, split posting, overlap rule) become small scripts so tests run what the lead runs.
- State of a migration is read from the board, not a progress file; that makes re-runs idempotent for free. Snapshot goes outside the repo, never overwritten.
- Check the requirement's literal strings against the product: a filter token naming an unused built-in field matches nothing; flag the deviation instead of copying it.
- Brief-in-issue and the work/ citation rule collide (the brief's Output line names a work/ draft): read the rule narrowly and record the reading as a decision.

<!-- migrated: factory-architect/derived-lines-contract-craft.md -->
---
name: derived-lines-contract-craft
description: Craft for contracts that add derived lines or checks to stored records (no schema bump, one minute rule, script for a prose check)
metadata:
  type: feedback
---

When a requirement says "add a derived line, no schema bump, sums must equal an existing measure":
- Define one function (stage of a minute) and count minutes, not waits by id; then both sums hold by construction. Write 2-3 worked tables (a real item, the requirement's figures, an overlap case) and recompute each by hand before committing.
- Place new lines as indented sub-lines under an existing measure and check the reader (parse() in the replay tool) keys on `^N\. key:` and role names, so old readers ignore them. Name the trigger that reopens it (the next slice that reads them).
- A "check" that is prose only cannot be tested for refusal: contract a small script (exit 0/1/2/3, one `refused: <key> (<reason>)` line each), say it moves the tooling fingerprint.
- Where requirement wording hides data (A3 target `none` when readings unusable), follow the AC, then say what the person loses and where the figure shows instead.
- Before promising a source for a count, check it survives the merge (`work/` is removed): copy a tag into a tracker comment cell instead.
- Existing tests pin template blocks by "first fenced block after heading": keep the new version first and the old second, and list the pins QA must change.

<!-- migrated: factory-architect/gemba-sample-contract-craft.md -->
---
name: gemba-sample-contract-craft
description: Contract craft for a counted sampling rule plus a bounded read of agent transcripts, a new record line, and a close-time andon
metadata:
  type: feedback
---

- Insert a new close step as `8.3a`, not a renumbering: step numbers are cited in the skill, references, tests, runbook and reference page. **Why:** #57 D12 refused renumbering for the same reason. **How to apply:** count citations with `grep -rnoE "step 8\.[0-9]+"` before choosing.
- A sampling rule needs: the order (log listing order, not a `#` cell), the flag test by prefix and lowercase, a fallback set, and a no-candidate form. Give a fabricated worked example, never a replay of the real logs (QA owns those).
- A cap must count everything the walk reads (brief included) and be enforced by `head -c` inside the command; give `n` and `m` definitions so "n chars of m" is replayable.
- An andon raised after the merge approval: no wait (lead time ended; a wait would break `agent working = total - waits`), no override (a commit after approval changes what was approved).
- A contract that spells a home-path pattern fails its own hygiene search; describe the pattern in words.
- A new record line with a new schema version also needs the baseline presence check and the generalised `records:` line; list the test pins that move (v4 marker greps).
- I cannot run jq/shell as architect: state filters as property contracts and ask the developer to run them once.

<!-- migrated: factory-architect/harness-contract-craft.md -->
---
name: harness-contract-craft
description: Craft lessons for designing measurement/judging harness contracts (blind pairs, frozen replays, versioned presets)
metadata:
  type: feedback
---

When a contract hands out a "reference" image for blind judging, don't expose it on the same channel drawing agents use (e.g. MCP); use a separate surface (REST) so the drawing agents stay blind.

**Why:** in carnet #44, putting the pair maker on /mcp would have let fresh-drawing agents fetch their own reference.

**How to apply:** for any judge/benchmark surface, ask "who else can call this?" before choosing the transport.

Also: consumers asked that all image processing stay server-side, and that degradations (control copies) be versioned presets, not ad-hoc arguments. Expect this: make tunable parameters immutable preset ids from the start. Content-addressed (sha256) file names are neutral but recur across pairs, so tell the consumer to rename files before judging.

When a normalisation pixel check fails, ask whether the failing cue also exists in real pairs (e.g. lossy-WebP chroma in references vs lossless renders). If it does, fix the normaliser by applying the same degradation to both sides, rather than weakening the test preset or the threshold. Frame such a pixel check as necessary-not-sufficient next to a judged control.

Hand-made approximations of a codec (e.g. DIY 4:2:0) don't neutralise codec cues and can double-apply them; route both sides through the identical real codec call at the same grid, and make the control's own degradation share that function (then copy = W(W(x)) vs W(x)). Always pre-write a stop rule (max N normaliser iterations, then escalate as a one-way door on the test itself).

Never estimate a known quantity from pixels: our own renderer's paper colour is known, so take it from the renderer. Estimate only the foreign side (the reference), and give the estimate a guard plus a per-item override. A "dark = luma threshold" line mask swallows dark fills; define ink as near the image's own darkest colour in hue and thin (opening removes wide areas).

Tool-interface "epoch": keep it hand-bumped, with a snapshot test that forces classification; a hash epoch refuses scripts on additive changes. Count default changes as interface changes.

<!-- migrated: factory-architect/measurement-record-craft.md -->
---
name: measurement-record-craft
description: Craft for lead-time/token measurement records from agent runs - exhaustive wait kinds, cut-off markers in Claude Code transcripts, replay rules on real data, fail-closed detection, severity-based pass, safe close
metadata:
  type: feedback
---

A residual measure ("agent working = total - waits") silently absorbs every wait kind you did not name. In a real demo, stalls (stream watchdog) and machine sleep put about 5h into "agent working". Make the wait taxonomy exhaustive (person, limits, stalled, interrupted) and give each kind a detection event, a start and an end.

**Why:** the person failed the acceptance criterion on exactly this (factory #39 AC-17). The v2 rules, written from reasoning alone, failed QA's replay on the demo transcripts again. The lead's countermeasure: write detection rules against the data and replay them before committing.

**How to apply:**
- Write detection as a script with fixture-testable output, not jq in prose. `tail -n 1` gave the notice time, because the watchdog writes `[Request interrupted by user]` at the notice.
- Gap start = the last non-marker user/assistant entry before the marker. Gap end = the first non-marker assistant entry after it, or `open`.
- Scan at close for cut-offs the agent recovered from. They send no notice, yet they lose the request in flight, so spend is truncated even when the run ended normally.
- The Lead's own wait stops role waits. Otherwise the overlap order hands the Lead's sleep to a role.
- Replay the rules on the real transcripts plus every transcript on the machine to measure false positives. Report the result as a table.

Transcript markers (Claude Code 2.1.287, undocumented, observed 2026-11):
- A `user` entry with `isMeta` and the text "cut off mid-stream".
- A `user` entry with the text `[Request interrupted`.
- An `assistant` entry with `isApiErrorMessage: true` and `error: server_error | rate_limit`, model `<synthetic>`. Note that "No response requested." is also `<synthetic>`, so don't key on the model.
- A `system` entry with `subtype: api_error` and an `error` object (an automatic retry).

Fail closed with independent signals (flag OR field OR text), plus a silent-gap net: a tool_result, then ≥600s, then an assistant entry. Idle gaps after end-of-turn are not stalls.

pmset: use only the strict awk filter (Sleep|Wake). DarkWakes are filtered out, so "asleep" runs from a Sleep line to the next Wake. Test "asleep at any moment", which includes the last line before the gap. Agents keep running during dark wakes.

Define "pass first time" by severity: no finding at or above minor, and a missing severity counts as at or above. Do not use the verdict alone.

Close: guard first (numeric id, worktree path from `git worktree list --porcelain`, `-L` symlink check). Stage only the protocol files `NN-*.md` plus `add -u`, and use `git -C`. Then run `git rm -r && rm -rf -- && commit`. The harness blocks an architect's scratch `bash -c` that runs `rm -rf`, so leave that verification to QA.

<!-- migrated: factory-architect/options-card-craft.md -->
---
name: options-card-craft
description: Craft for writing one-way-door option sets for a product-owner decision card (combining doors, asymmetric undo, non-technical wording)
metadata:
  type: feedback
---

When two one-way-door questions depend on each other (e.g. derived-vs-asserted access plus history), offer one card with only the coherent combinations, not the full cross product.

**Why:** separate cards let the person pick an incoherent pair; this way the comparison stays at about 3 options.

**How to apply:** let the leaning rest on asymmetric cost to undo. If X to Y is a cheap refactor and Y to X loses data for good (history can never be added after the fact), lean X. Add a comparison table and draft everyday-words card lines so the PO doesn't have to translate mechanism.

When the brief says to read issues via `gh` but there is no shell tool, go ahead using the brief's summary. State that as a caveat in the options and result, and ask the lead to check against the ticket text, rather than blocking.

Before crediting an option with a privacy or exposure gain, check what is already public: on GitHub, a pushed PR's commits stay on `refs/pull/<n>/head` for good (owner can't delete it), so squash-merge only keeps them out of main's clones. Check with `git ls-remote origin 'refs/pull/<n>/*'` and `gh repo view --json visibility`. Also: GitHub rebase-merge always rewrites shas and sets committer date to merge time, which breaks any check reading `%cI` from main. Separate "the policy" (two-way, one template line) from "this one merge" (one-way, permanent on main).

<!-- migrated: factory-architect/plugin-versioning-craft.md -->
---
name: plugin-versioning-craft
description: Craft for Claude Code plugin version identity, measurement baselines, and measurement-record contracts (fingerprints, scripts, honesty rule, wait accounting)
metadata:
  type: feedback
---

When records (baselines, retros) must be labelled with "the plugin version":
- With `version` in plugin.json, the cache dir / `${CLAUDE_PLUGIN_ROOT}` basename becomes the semver. The sha is then NOT reliably observable at runtime (installed_plugins.json can be stale mid-session). Offer a **content fingerprint** (sha256 over the standard files under the substituted plugin root) as the "sha alongside", plus a git tag per release so semver maps back to a sha.
- Without `version`, the version is the marketplace repo HEAD sha. Every push, even docs-only or another plugin's change, is a new version, so a "reset on version change" rule fires spuriously. Key resets on the fingerprint instead.
- A fingerprint change under the same semver = a forgotten bump. Make it an abnormality, never a silent new baseline.

**Why:** in the 2026-11 factory-Lean round, the brief's "semver plus sha in each record" turned out not to be observable. The fingerprint solved both the readability and the lossy-label problems.

**How to apply:** separate what is truly one-way (the label written on each record; freezing the installed version for a run, since time passes) from what only looks weighty (the `version` field is one line; calling data "baseline" vs "calibration" is a rename if the labels are complete). Lean on that asymmetry. Prefer calibration over a baseline that compares two different capture methods. See [[options-card-craft]].

When recording such a decision as an ADR: widening the fingerprint beyond standard work (e.g. hooks/, scripts/) collides with a "patch = everything else" bump rule, since a patch then moves the fingerprint. Name that collision explicitly as left to the slice rather than resolving it in the ADR. Tag the run freeze **locked** (deliberate, unrecoverable) and the rest provisional.

Measurement-record contracts (factory #39, 2026-11):
- Split the fingerprint per bump level (standard work vs tooling): it dissolves the "patch moves the fingerprint" collision with no information lost, so it is a two-way door, not an ADR.
- Content fingerprint = sha256 of a `sha256sum`-style manifest (file hash + relative path, LC_ALL=C sorted). Path-independent, mtime-proof, and catches added/removed files. Verify it on two real copies before writing it into a contract.
- `${CLAUDE_PLUGIN_ROOT}` exists only as Markdown substitution, so scripts take the root as an argument. A `--plugin-dir` root's basename is "factory", so read the release from plugin.json.
- A record that is edited after `work/` is removed needs a marker search plus a pointer in a surviving place (the map body).
- The honesty rule needs every tool to fail loudly: exit non-zero on an empty window, never print 0.
- Wait times only add up when you count "item-held" waits (no agent working). Per-row waits double-count parallel stages.
- gh can't read the history of a Project custom-field change, so don't promise it as cross-check evidence.
- Transcript spend: dedupe on message.id and drop the `<synthetic>` model. Compare timestamps as epochs, because "HH:MMZ" sorts after "HH:MM:SS.sssZ" as text.
- `${CLAUDE_PLUGIN_ROOT}` is substituted in skill files only, not in reference files or project docs. Those write `<plugin root>` and point at the SKILL.md `Plugin root:` line.
- Security review of record contracts (#39 round 2): any stderr line that can be copied into a public record names files by basename. Committed lead state writes $HOME as `~`. Never put a real local path or session id in a contract example.
- Define semver strictly (no leading zeros). Bash `$((08+1))` is an octal error, which gave an empty suggested version. A malformed *base* version is an error, not a silent 0.0.0.
- Marker-found tracker records need an author filter (`.user.login`), or anyone can plant or block the record. `gh api --jq` has no `--arg`, so splice the login into the filter (safe: logins are `[A-Za-z0-9-]`).
- Every PR path needs the poka-yoke (item PR, frontier PR) plus a re-check before merge, because commits land after opening. Fingerprints are all or nothing: an unreadable file exits non-zero with empty stdout.

<!-- migrated: factory-architect/shell-script-contract-craft.md -->
---
name: shell-script-contract-craft
description: Craft for contracting small bash CLIs and plain-bash test harnesses (bash 3.2 portability, data-only test cases, size limits)
metadata:
  type: feedback
---

Patterns for contracts on tiny bash tools under a "stock macOS bash 3.2, no bats" constraint.

**Why:** these close gaps that are easy to miss at contract time and that a newer local bash hides.

**How to apply:**
- Shebang `#!/bin/bash`, not `/usr/bin/env bash`: env picks Homebrew bash 5 and hides 3.2 breakage.
- Have the runner invoke the CLI as `"$BASH" script`, so `/bin/bash run.sh` tests the CLI under the same bash.
- Test cases as data-only dirs (`args` one per line, byte-exact `stdout` compared with `cmp -s`). This keeps the harness line count separate from the cases, and checks the trailing newline, which `$(...)` strips.
- 3.2 gotcha: `"${arr[@]}"` on an empty array under `set -u` errors; use `${arr[@]+"${arr[@]}"}`. No mapfile, `declare -A`, `${v,,}`, `&>>`, `;&`.
- Zero cases found = failure, so a moved test dir cannot pass silently.
- Charting constraints that are two-way doors go in contracts/README.md "Standing constraints" with rejected alternatives, not ADRs. See [[slice-contract-craft]].
- Commands an agent runs via its Bash tool: shell variables do not survive between calls, so contract multi-step blocks as ONE call and write `"${w:?}"` so an empty var stops instead of hitting the main checkout.
- Deleting inside a worktree: prefer `git -C "$w" clean -fdx -- <path>` plus `[ ! -e ]` over `rm -rf "$var/..."` (Claude Code's removal safety check prompts on rm of a variable and stalls unattended runs; git clean stays in the repo, does not follow symlinks).
- Git pathspec `*` crosses `/`; use `':(glob)dir/[0-9][0-9]-*.md'` to keep it one level.
- Values copied from transcripts into committed text: whitelist (`^[a-z_]+$` else `other`).

<!-- migrated: factory-architect/text-slice-contract-craft.md -->
---
name: text-slice-contract-craft
description: Contracting a slice whose deliverable is instruction text (markdown), not code
metadata:
  type: feedback
---

For a text-only slice, name per file: section, statement (meaning), word-for-word lines, and the existing tests that pin wording.

**Why:** QA writes tests first and the developer may not touch tests/, so every pin must be found by the architect up front (grep tests/ for the sentence, the table-row prefix, the version string and the template words).

**How to apply:** grep tests for each line you plan to change; also check version-pinned checks (a minor bump breaks hard-coded release strings); check ordering pins (a table row found by prefix and compared to a later line); do not add a new stage name without checking the hansei Stage list and its test. A decision that is not a role task (lead decisions) stays out of the stage table and the ledger. Check paths.sh list on each contract before committing.

