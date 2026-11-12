# Role file: docs-writer

Project rules, checks and knowledge for the docs-writer role, kept under version control. Only the docs-writer role reads this file and its skills folder, `docs/agents/skills/docs-writer/`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

## Knowledge

- Factory release entries (`CHANGELOG.md`): the ac19 check in `tests/factory/test_lean_rules.sh` reads the newest `## factory ` entry and greps it for the standard and tooling fingerprints. Compute them with `bash plugins/factory/scripts/fingerprint.sh plugins/factory` after the version bump, and put them in that entry. The release date is `date -u +%F`.
- The documentation site (`apps/site`, #156): `npx astro preview` daemonises, so the process started by the command exits at once and the server keeps running. Read the address it prints, then stop it with `npx astro preview stop`; check it with `npx astro preview status`. Do not kill the pid you see at start.
- A Bash command that names another role's folder under `docs/agents/roles/` or `docs/agents/skills/` is refused by the memory guard as a whole, so list only your own folder in one call.

## Skills used

## Migrated memory

<!-- migrated: factory-docs-writer/feedback_brief_only_if_vs_role_done.md -->
---
name: brief-only-if-vs-role-done
description: When a brief says "update file X only if ..." but the contract or the role's Done list requires an entry in X, follow the contract and Done list and flag the conflict as an open question in the result
metadata:
  type: feedback
---

When a brief limits a file ("update it only if it restates ..., otherwise leave it") and the slice contract or my role's Done list requires content in that same file (for example, every contract has a reference entry), I add the required content and say so under Decisions and Open questions. I do not silently skip the requirement.

**Why:** On slice 73 (factory 2.1.0) the brief said to leave `docs/factory/reference.md` alone unless it restated test ownership, while contract 73-release §1 asked for three contract index entries and the role's Done requires a reference entry for every contract. The lead had not reconciled the two. Following the contract and flagging it let the lead confirm or reverse it with a one-line answer.

A contract's numbered list can be longer than the count in the brief or the contract's own prose (2.3.0: contract §2 numbers five items for "four changes"). Follow the brief's count, keep the extra item in the release's lead paragraph, and list the choice under Decisions.

**How to apply:** Read the contract's own paths section for the file before editing. Record the conflict in the result with the exact brief line and the contract line, the choice made, and the cost to undo. Keep the added content to pointers, not restated rules.

<!-- migrated: factory-docs-writer/feedback_check_internal_links.md -->
---
name: check-internal-links-after-heading-edits
description: After editing docs, check every relative link and #anchor with a script; a renamed heading breaks anchors silently and an old one was already broken on #60
metadata:
  type: feedback
---

Run a link check over every doc you touched before committing: each relative file path must exist, and each `#anchor` must match a heading of the target file under GitHub's slug rule (lowercase, punctuation dropped, spaces to hyphens).

**Why:** On #60 the reference page's 49-records entry linked to a hansei heading slug that an earlier release had already renamed. No test covers anchors, so the break was silent. The link check found it in one pass.

**How to apply:**
- Write the checker to the scratchpad and run it with `python3 -I`, passing the touched files as arguments. Resolve paths relative to each file's own directory.
- Build each target's heading set from its own text, and skip `http` links and `${...}` plugin-root links.
- When you rename a heading you cite, grep the whole docs folder for its old slug first. Repoint links in files you own; for another owner's file, propose the fix to the lead.
- GitHub anchors for headings with a colon or commas: drop the punctuation, keep the number's hyphen (`### 94-a3-v2: the A3 at v2, ...` gives `#94-a3-v2-the-a3-at-v2-...`). Write the anchor from the heading you ship, then let the checker confirm it.
- The checker writes to the scratchpad and is run as `python3 -I`; its own negative test (a missing file, a bad anchor) is worth one run on each new version of the script.
- Related: [[run-docs-without-touching-frozen-state]] for the quick-start side of the same check.

<!-- migrated: factory-docs-writer/feedback_limitations_match_final_verdicts.md -->
---
name: limitations-match-final-verdicts
description: Before writing a release's known limitations, check each one against the final QA and security verdicts, the suite's named skips and the slice's full comment thread; limitation lists go stale fast across review rounds
metadata:
  type: feedback
---

Write a release's "known limitations" from the final verdicts and the suite's current skips, not from the earlier rounds' text or the previous CHANGELOG.

**Why:** On factory #39 the CHANGELOG I inherited listed three schema v2 checks as open (F1 to F3) and three security items (L8 to L10) as open. Both were closed in later rounds: the test suite had no skips for them and the security final verdict said "fixed". Only the two docs skips were real. The same drift showed up in the release runbook, which still named F1 to F3 as skips. On #57 the QA round 3 verdict listed the AC-16 second half as open, but the Lead's later comment on the slice thread had already reported it passed. The verdict alone would have been stale.

**How to apply:**
- For each limitation, find its evidence: `grep -n skip tests/...` for named skips, and the final verdict's table or "Verdict after the final round" line for findings.
- Read the slice's whole comment thread (`gh issue view <n> --comments`), not only the verdict: later Lead comments close or reopen verdict items. Where they disagree, list the item and ask the lead which one stands.
- Keep open items as open, with the owner's id (e.g. security I6) and whether it is deferred; drop closed items instead of carrying them as history.
- Where the brief says "all X passed" and a verdict leaves one human-only check open, write the open check into the docs and raise it under Open questions. Do not quietly match the brief.
- Other owners' docs (runbook, ADRs) that repeat the stale text go to the lead as proposed fixes, not edits. On #57 the runbook's "written by the Lead at run close" for the baseline was incomplete against the contract; I proposed the fix to the lead instead of editing it.
- A verdict covers the head it was given, not later rework. List `git log` after each verdict's head: a fix made after a pass is written as "fixed, not re-reviewed", and the fingerprint quoted is the final head's, not the one in the verdict (2.3.0: QA quoted a tooling value from before rework 1).
- A demo outcome comment lists what was and was not exercised. Quote its "not exercised" lines as limitations; do not turn a demo's "pass" into a claim beyond its wording (the demo's A3 had no experiment, so the experiment's before and after were not seen).

<!-- migrated: factory-docs-writer/feedback_no_shell_verification.md -->
---
name: no-shell-verification
description: When briefed without a shell, docs-writer cannot execute setup steps; trace each step to a command another role ran and flag the Done item as open
metadata:
  type: feedback
---

When the lead says "you have no shell", I cannot meet the Done item "setup, run and deploy steps executed exactly as documented".

**Why:** The protocol requires every statement to trace to a command someone ran. If I claim a step was verified when I never ran it, the trace is false.

**How to apply:**
- Build the quick start only from commands other roles report they ran: the devops runbook, the developer's "How to run", and the qa re-run.
- Read the scripts themselves (seed, env script, config loader) to get the dependency order and the defaults. Example: a seed that reads an env var only exists after VM setup, so the seed must come after it. Another: a seed with plain inserts can only run once.
- In the result, say plainly that I did not run anything, and ask the lead to have someone with a shell run it once.
- Runbooks are devops-owned. If one points at the README for a step, write that step in the README, then propose the runbook fix under Open questions instead of editing the runbook.

<!-- migrated: factory-docs-writer/feedback_read_install_state_before_docs.md -->
---
name: read-install-state-before-docs
description: Before writing any install or freeze fact into a doc, read `claude plugin list --json`; never copy a frozen-install sha from an older README or runbook into a new release's text
metadata:
  type: feedback
---

Read the live install state before writing "the install is frozen on X" into a README, changelog or runbook. Run `claude plugin list --json` (read-only) and quote the `version` and `installPath` it reports.

**Why:** On factory item 64 I first wrote that the install stayed on `9147301f75c3`, copied from the 1.1.0 to 1.3.0 README and runbook sections. The live entry showed factory 1.3.0 (user scope), the frozen install of that run. The wrong sha would have gone into the 2.0.0 changelog and runbook.

**How to apply:** When a release text names the frozen install, take the version from the lead state's `Label` or `Frozen on` line and confirm it with `claude plugin list --json`. Older sections that name a sha are history for their own release; leave them as they are.

For what the installed release does (for example, how a 2.2.0 reader treats a v2 A3), read its text on main with `git show main:<path>` when main carries that release, and do not open the install path. On 2.3.0 the 2.2.0 unknown-version rule was confirmed that way (`plugins/factory/references/a3.md`, section 1). Note that `claude plugin list --json` output includes local install paths: keep them out of any file in the repo.

<!-- migrated: factory-docs-writer/feedback_run_docs_without_touching_frozen_state.md -->
---
name: run-docs-without-touching-frozen-state
description: When executing a doc's setup or deploy steps on a machine with a frozen plugin install, run read-only and validate-only commands; skip install, marketplace and init steps and say so in the result
metadata:
  type: feedback
---

Run a documented quick start only as far as it is read-only or validate-only. Skip the steps that change user-scope state (plugin install, marketplace add or update, uninstall, `/reload-plugins`) or re-create repo state (`git init`, `gh repo create`), and list each skipped step with its reason in the result.

**Why:** On the factory item #39 the calibration run must stay on one frozen install; running a documented `marketplace add` or `install` would have broken the freeze, and the freeze holds for every project on the machine. A `git init` in an existing clone would also have changed the repo itself. On #57 the same freeze held, and the read-only and validate-only checks ran cleanly with no state change.

**How to apply:**
- Safe to run: `claude plugin validate <path>`, `claude plugin list --json` (to confirm the frozen version is still installed), scripts that only print (fingerprint, check-bump after a fetch, token-spend on a known transcript), `bash tests/run.sh` (it writes nothing into the repo), and read-only `gh api` / `gh issue view` / `gh issue list` calls. Tracker lookups copied from a template's read operations (Find, Read) are the best check that the documented commands exit 0.
- Skip and report: install, marketplace, uninstall, reload, `git init`, `gh repo create`, slash commands that run an interactive flow (`/factory:run`, `/factory:setup-factory-skill`), and any tag or tracker write (create, pin, edit, post, comment).
- Before running a quick start, check the lead state or the map's Factory run section for a freeze. A freeze entry means no user-scope plugin commands.
- Do not write fingerprints or hashes into docs: they move with every edit to the covered files. Exception: where the release contract and a test pin them (2.3.0: the changelog entry's last line, pinned by the ac19 checks), write them once there, after the last edit under `plugins/`. The runbook and reference hold none. Elsewhere quote the value only in the result, with the date it was computed.
- `git ls-remote --tags origin 'factory-v*'` is read-only: check which release tags exist before writing a tag step. On 2026-11-10 the tags ran to `factory-v2.1.0`; 2.2.0 had none.
- Check a token-spend or similar worked example against its contract's numbers; a match is the evidence the documented command works.
- Capture exit codes directly (`cmd; echo rc=$?`), not after a pipe into `tail` (the pipe hides the status). Use the scratchpad for temp files, not /tmp.
- Contract worked examples that name a transcript by agent id can be reproduced: `find ~/.claude/projects -name "agent-<id>.jsonl"`, then run the script on it and compare the figures.
- The zsh shell expands `=` at a word start: `echo =====` fails with "not found". Use `printf '%s\n' ----` for separators.
- `token-spend.sh --require-end` exits 6 on a transcript that is still open (no final reply yet), including the transcript of the agent running the check itself. That is the check's definition of cut off, not a script fault; re-run it on a finished transcript, or say so in the result (#60, 1.3.0).
- The transcript of the running agent is the only one to hand in a fresh session: find it with `find ~/.claude/projects -newer <a file of this item>` (the `subagents/` folder), since a stage log may not name agent ids.

