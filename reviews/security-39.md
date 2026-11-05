# Security review — #39 hansei record

Reviewer: security-reviewer · Branch `item/39` against `main` (diff `main...item/39`, head `4774b97`) · 2026-11-04

**Verdict: pass** (re-verified at `34ac83c`, `dd57082`, `5e5b9f1`, round 5 at `c20992e`, and the final round at `79e191c`). No critical, high or medium findings. L1–L12, L1a and L8a are fixed, and so is I4. Session and agent ids are accepted (L5). Open, low and non-blocking: L13 (a home path in `reviews/qa-39.md`) and the checklist hit L14; informational I1–I3, I5, I6.

## Scope

Every changed file was reviewed:

| File | Review focus |
|---|---|
| `plugins/factory/scripts/fingerprint.sh` | input/path handling, quoting, symlinks, exit codes |
| `plugins/factory/scripts/check-bump.sh` | ref/option injection, path classification, exit codes |
| `plugins/factory/scripts/token-spend.sh` | argument parsing, transcript reading under `~/.claude`, what reaches stdout/stderr |
| `plugins/factory/references/hansei.md` | data the record exposes, honesty rule, tracker writes |
| `plugins/factory/skills/run/SKILL.md` | fenced gates (ADR 0011), cross-repo writes, order of close |
| `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` | `gh` commands, record lookup/edit, release tagging |
| `plugins/factory/.claude-plugin/plugin.json` | version field only |
| `CONTEXT.md`, `contracts/39-*.md`, `docs/requirements/39-hansei-record.md`, ADR 0012 edit | secrets and personal data in a public repo |
| `work/39/*` | removed before merge; checked for secrets only |

OWASP categories that apply to local shell tooling: A01 (broken access control: cross-repo writes, gate skipping), A03 (injection: shell and option injection), A04 (insecure design: gate and record integrity), A05 (misconfiguration: temp files), A08 (data integrity: record spoofing, fingerprint honesty), A09 (logging and sensitive data in records). A02, A07, A10 do not apply: no crypto beyond content hashing, no authentication, no network calls in the scripts.

## Dependency audit

- The diff adds or changes no dependency manifest (no `package.json`, lockfile, `requirements*.txt`, `go.mod` or project file). The only manifest in the repo, `plugins/toolkit/skills/source-to-pptx/assets/docker/requirements.txt`, is untouched and out of scope.
- Runtime tools the scripts call: `bash` 3.2.57 (`/bin/bash`), `jq` 1.8.1, `git`, `gh` 2.94.0, `shasum`/`sha256sum`, BSD `sed`/`grep`/`find`. The contract's floor is `jq` 1.6; jq 1.7.0 had CVE-2023-50246/50268 (decNumber), fixed in 1.7.1. The input is the person's own transcripts, so exposure is negligible; noted, no finding.
- No secrets in the diff (grep for token, key and private-key patterns: none).

## Probes run (throwaway copies in the scratchpad, nothing in the repo or `~/.claude` changed)

- fingerprint.sh: unreadable file under `scripts/` (exit 0, see L4); symlink from `references/` to `/etc/hosts` (followed, only its hash is printed); `$(id)` in `version` (rejected, exit 2, never evaluated); missing root (exit 2, absolute path on stderr, see L5).
- check-bump.sh: base refs `--output=/tmp/pwn-sec39` and `-p` (both stop at `rev-parse --verify`, exit 2, no file written); non-ASCII standard-work file with a patch bump (passes, see L1); prerelease version `2.0.0-rc1` (refused, exit 1).
- token-spend.sh: option-like file names (L7); missing file in a private path (stderr shows the basename only); non-JSON line (exit 3); bad `--since` with shell metacharacters (exit 2, not evaluated); bad `timestamp` and non-numeric usage in a transcript (exit 3, never a false `0`).
- Gate review of SKILL.md: QA and security verdicts still gate the merge (step 6.5 unchanged), merge stays behind the person's one approval, a bump-check exit 2 goes to the person, and the honesty rule is reinforced. No new text lets the Lead skip a fenced gate. The only `--repo WimSuenens/agent-plugins` is step 9, behind the person's per-draft approval and now with an explicit "no raw hansei records" rule.
- Data in the hansei record: release, two fingerprints, dependency versions, override names, durations, counts, token totals and Under-test line names. No transcript content, prompts, paths or session ids reach the record template; token-spend.sh prints only totals and, on error, a file's basename.

## Findings

### L1 — `plugins/factory/scripts/check-bump.sh:13` — low — quoted paths escape the standard-work classification

`git diff --name-only` quotes any path with non-ASCII or special bytes (`core.quotePath` default). `"plugins/factory/agents/d\303\251velopeur.md"` starts with `"`, matches no `case` pattern, and the change passes with a patch bump (reproduced: `pass: patch bump needed, 1.0.0 -> 1.0.1`). The poka-yoke ADR 0012 point 5 asks for can be passed by a file name; the standard fingerprint still moves, so detection remains.

Fix: read the list NUL-separated and unquoted, e.g. `git diff -z --no-renames --name-only "$base...HEAD" -- plugins/factory/` and loop with `while IFS= read -r -d '' p`; or, as a fallback, treat any path not positively classified as tooling/other as `minor` (fail closed).

### L2 — `plugins/factory/skills/run/SKILL.md` (Open PR) and tracker patch (*Merge PR*) — low — the bump check is not re-run before the merge

The check runs once, before `gh pr create`. QA, security or docs feedback rounds after that can touch `plugin.json` or standard work, and *Merge PR* then tags `factory-v<version>` from whatever `plugin.json` holds, without a re-check. A patch-level PR whose feedback round edits `agents/*.md` merges with a patch bump; a hand-edited version that is not `MAJOR.MINOR.PATCH` would become a tag name.

Fix: in *Merge PR* step 1 (or SKILL.md step 8.7), run `git fetch origin main` and `check-bump.sh` again before `gh pr merge`, and do not merge or tag on a non-zero exit; tag only when the version matches `^[0-9]+\.[0-9]+\.[0-9]+$`.

### L3 — tracker patch, *Find hansei* — low — any commenter can plant a record

The lookup selects any comment whose body starts with `<!-- factory:hansei v`, whoever wrote it. On a public project, a third party who comments first makes the Lead skip posting and try to edit that comment (a 403, or, with admin rights, an overwrite of someone else's comment), and a later reader that aggregates records ingests the spoofed one. This touches the integrity of the measures the baseline is built on.

Fix: filter on the author as well: `select(.user.login == "<gh api user --jq .login>" and (.body | startswith("<!-- factory:hansei v")))`. Readers that aggregate records apply the same filter.

### L4 — `plugins/factory/scripts/fingerprint.sh:47-50` — low — an unreadable file yields a fingerprint and exit 0

When a file in a set cannot be read, the redirection fails, `bash` prints `Permission denied`, the manifest line holds an empty hash, and the script exits 0 with a 64-hex fingerprint (reproduced). The Lead writes that as measured, which runs against the honesty rule (fenced by ADR 0011): an uncaptured value should read `not captured`.

Fix: check each file before hashing (`[ -r "$root/$rel" ] || { echo "fingerprint: cannot read $rel" >&2; exit 2; }`, propagated out of the pipeline, e.g. with a flag file or by building the manifest in the main shell), so the Lead records `not captured (...)`.

### L5 — `hansei.md` section 1 (`## Label`) and fingerprint.sh stderr; `contracts/39-plugin-scripts.md:171` — low — local paths and ids in tracker and git history

- When fingerprint.sh fails, `not captured (<script's message>)` copies `fingerprint: not a factory plugin root: /Users/<name>/…` into the label and from there into the record's `standard`/`tooling` slots on the project's tracker, which may be public.
- The label's `plugin root` and `lead sessions` lines (home directory and session ids) are committed in `work/<id>/00-lead-state.md`. `work/` is deleted in the last commit, but *Merge PR* uses `--merge`, so those commits stay in the project's history for good.
- The contract's worked example (`contracts/39-plugin-scripts.md:171`) commits this machine's project directory and a real session id to the public agent-plugins repo. The username equals the public GitHub login, so the exposure is small.

Fix: in fingerprint.sh print only `basename "$root"` in the error, or have hansei.md say to use the exit code as the reason (`not captured (fingerprint exit 2)`); in the label write the plugin root as `~/…` (`${root/#$HOME/~}`); in the contract replace the path with `~/.claude/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl`.

### L6 — tracker patch, *Edit hansei* — low — scratch file location unspecified

`<record>.md` is "a scratch file outside the repo" with no location or clean-up. A fixed name in shared `/tmp` can be pre-created or read by another local user, and a leftover file holds the project's record.

Fix: `f="$(mktemp -t hansei.XXXXXX)"`, use it for the fetch and the PATCH, then `rm -f "$f"`.

### L7 — `plugins/factory/scripts/token-spend.sh:44-49,51` — low — option-like file names

A transcript path beginning with `-` (only possible with a relative path) is taken as an option by `basename` and `jq` (reproduced: `basename: illegal option -- n`, exit 3 with an empty file name in the message). Not exploitable, since the paths come from `find ~/.claude/projects`, but the error loses the file name the Lead must record.

Fix: prefix relative arguments with `./` before use (`case "$f" in -*) f="./$f";; esac`), and use `basename -- "$f"`.

## Informational

- I1 — SKILL.md, pre-1.0.0 fallback: for a project whose tracker doc lacks *Post hansei*, the Lead runs the whole item on the plugin's GitHub *Factory operations* instead of the project's own section. Any project-specific tracker rule in that section is set aside for the item. Not a fenced gate (merge still waits for the person), and the person is told; acceptable as written.
- I2 — All tracker commands rely on `gh` resolving the repo from the clone. In a fork with an `upstream` remote and no `gh repo set-default`, `gh` may resolve to the upstream repo, so records and stage summaries could land on someone else's tracker. This predates #39 (stage summaries already work this way). A later slice could have setup-factory-skill run `gh repo set-default`.

## Re-verify

Re-verified 2026-11-04 at `34ac83c`, after `2a6b32f`, `be77591` (developer) and `ed0e627` (architect). The probes ran on throwaway copies in the scratchpad.

| Finding | Status | Evidence |
|---|---|---|
| L1 | fixed | `check-bump.sh` reads `git diff -z`. `agents/développeur.md` with a 1.0.0 -> 1.0.1 bump now gives `refuse: standard work changed … needs at least a minor bump (1.1.0)`, exit 1. A path git still quotes is classed as minor. |
| L2 | fixed | *Merge PR* first runs `git fetch origin main` and `check-bump.sh`. On exit 1 or 2 it does not merge. It tags only when the version matches `^[0-9]+\.[0-9]+\.[0-9]+$`, and otherwise skips the tag and tells the person. The frontier round (SKILL.md step 2) also runs the check before its PR. |
| L3 | fixed | *Find hansei* filters on `.user.login == "$me"`, where `me` comes from `gh api user --jq .login`. Splicing the login into `--jq` is safe because GitHub logins are alphanumerics and hyphens and cannot hold a quote. |
| L4 | fixed | An unreadable `scripts/check-bump.sh` gives `fingerprint: cannot read scripts/check-bump.sh`, exit 2, with empty stdout. An unreadable `agents/developer.md` does the same. |
| L5 | fixed / accepted | fingerprint.sh names the root by basename only (`not a factory plugin root: proj` for `/Users/nobody/secret/proj`) and files by their path relative to the root. The label's `plugin root` is written with `~` (hansei.md, and stage-log contract l.25). Script calls take the path from SKILL.md's `Plugin root:` line. The contract example uses `~/.claude/projects/<project>/<session id>/…`, and no `/Users/` path is left in the contracts, hansei.md, SKILL.md, the requirement or CONTEXT.md. **Session ids accepted**: they are random ids that only locate a transcript on the machine that wrote it. They grant no access, and the close needs them after a resume in a fresh session. Keeping them in `--merge` history exposes nothing usable. |
| L6 | fixed | *Edit hansei* uses `rec="$(mktemp)"` and `rm -f "$rec"` afterwards. |
| L7 | fixed | `token-spend.sh -- -n.jsonl` reads the file (spend 3, exit 0). A missing `-missing.jsonl` gives `transcript -missing.jsonl unreadable`, exit 3, with the name kept. Without `--`, `-n.jsonl` is refused as an unknown option, exit 2, named, as the contract specifies. |

### L1a — `plugins/factory/scripts/check-bump.sh:13,22-31` — low — a newline in a file name still escapes the classification (residual of L1)

`git diff -z … | tr '\0' '\n'` turns the NUL separators back into newlines. A path such as `plugins/factory/agents/a<LF>b.md` splits into `plugins/factory/agents/a` and `b.md`. Neither matches a minor pattern, so a patch bump passes (reproduced: `pass: patch bump needed, 1.0.0 -> 1.0.1`). This needs a newline committed in a file name under `agents/` or `references/`. The standard fingerprint still moves, so the change is still detected. Not blocking.

Fix: fail closed. In the `case`, add `plugins/factory/*) ;;` before a final `*) level=minor ;;`, so any line that does not start with `plugins/factory/` counts as standard work. Or loop over the NUL-separated output directly with `while IFS= read -r -d '' p` and drop the `tr`.

## Re-verify, round 3

Re-verified 2026-11-04 at `dd57082`, after `9ee1cdc` (developer). The probes ran on a throwaway repo in the scratchpad with a copy of `check-bump.sh`.

| Finding | Status | Evidence |
|---|---|---|
| L1a | fixed | `check-bump.sh` writes `git diff -z` to a `mktemp` file and loops with `while IFS= read -r -d '' p`, and `tr` is gone from the classification. A new `*$'\n'*) level=minor` case puts any name holding a newline in standard work. With a 1.0.0 -> 1.0.1 bump, `agents/a<LF>b.md`, `references/r<LF>.md`, `agents/d<LF>ir/x.md` and `scripts/s<LF>x.sh` all give `refuse: … needs at least a minor bump (1.1.0)`, exit 1. `agents/a<LF>b.md` with 1.1.0 passes. The L1 regression checks still refuse: `agents/développeur.md`, and a name holding a tab and a `"`. A plain `scripts/x.sh` with a patch bump passes, as the contract says. A bad base ref exits 2. No temp file is left behind. |

**The catch-all is not needed.** I accept the developer's rationale. With `-z`, git passes every path through raw, unquoted, so each NUL-separated record is the real path. The only way a path could slip past the standard-work patterns was the newline split, and the new case closes that, failing closed. Contract 39-plugin-scripts §2 puts every other path under `plugins/factory/` at patch level, so a catch-all `*) level=minor` would contradict the contract without adding any security. The dropped `\"*)` case is safe to drop too: with `-z`, git never quotes a path.

Also read in `9ee1cdc`:
- `token-spend.sh` now sends the main jq call's stderr to `/dev/null`, and its exit 3 message no longer lists every file's name. Less reaches stderr than before.
- In the tracker patch, *Post hansei* writes its scratch file with `mktemp` and removes it with `rm -f`, and *Merge PR* uses the strict semver regex for the tag. Neither adds an injection point.
- `bash tests/run.sh`: ALL PASSED.

Verdict after re-verify: **pass**. No finding is open, so the merge is not blocked.

## Schema v2 review

Reviewed 2026-11-05 at `5e5b9f1`: the changes since `dd57082`, which are the contracts from `9f7825b`, the build `187b5a9` and later, and the devops runbook `25f8978`. The probes ran on throwaway files and repos in the scratchpad. Nothing in the repo or under `~/.claude` was changed.

Files reviewed: `plugins/factory/scripts/token-spend.sh`, `plugins/factory/references/hansei.md`, `plugins/factory/skills/run/SKILL.md`, `contracts/39-hansei-record.md`, `contracts/39-plugin-scripts.md`, `contracts/39-stage-log.md`, `contracts/39-standard-changes.md`, `docs/requirements/39-hansei-record.md`, `docs/factory/release-runbook.md`, and `tests/factory/*` (read for what they pin).

Dependency audit: no manifest or lockfile changed. The only new runtime tool is `pmset`, which ships with macOS and is only read. The secrets grep of the added lines (outside `work/`, `tests/`, `reviews/`) found no token, key or `/Users/` path.

### token-spend.sh `--require-end` (exit 6): no finding

- **Option handling.** These cases were probed: `--require-end` with no file (usage, exit 2), `--require-end=1` (unknown option, exit 2), `--since --require-end` (bad time, exit 2), a repeated flag (accepted), a flag after the file (read as a file named `--require-end`, exit 3), and `-- -n.jsonl` (read as `./-n.jsonl`). Exit 3 is checked before exit 6, as the contract says: a missing file next to a truncated one gives exit 3.
- **Ending check.** The test files were: a final reply (exit 0), a final `SubagentHandback` and its result (0), a trailing `tool_use` (6), a `[Request interrupted` user entry (6), a `tool_result` for a non-handback tool (6), only non-message entries (6), and a user entry with an object as `content` (6, because the jq error counts as truncated). Each case either passes a complete run or fails closed. A false exit 6 only turns spend into `not captured`, never into a wrong number. A role cannot fake an interrupted entry, because only `type == "text"` blocks of user entries are matched, not tool results.
- **Messages.** stderr names the file by basename only (`/…/Users/someone/private/-agent-x.jsonl` gives `transcript -agent-x.jsonl truncated`). A name such as `$(id).jsonl` is printed as is and never evaluated. The record keeps only `not captured (transcript truncated by <kind>)`, and no file name reaches it.

### Agent ids in `## Waits` and committed history: accepted

The new `Agent` column, and the `Agents` column already there, hold agent handles. Like session ids (L5), these are random ids that only locate a transcript on the machine that wrote it, and they grant no access. They reach the public record only through an exit-3 reason (`transcript agent-<id>.jsonl unreadable`), and that exposes nothing usable. No finding.

### L8 — `SKILL.md` step 8.6, `hansei.md` close order step 1, `contracts/39-hansei-record.md:135` — low — `git add -A work/<id>` puts every untracked file into permanent history

The close commit stages everything under `work/<id>/`, not just the lead state and the message files. Any stray file there goes into the `#<id> lead: close` commit, and *Merge PR*'s `--merge` keeps it in the project's history for good, even after `work/` is removed. That could be a scratch dump, a copied transcript, or an `.env` a role made for a test. Reproduced: an untracked `work/39/scratch.env` was staged next to `00-lead-state.md`. Before v2, a file reached history only when its owner committed it on purpose.

Fix: stage only the protocol's files. That means `git add -- work/<id>/[0-9][0-9]-*.md` (lead state, briefs, results, feedback, questions), then `git add -u -- work/<id>` for changes to tracked files. Leave anything else to the `rm -rf` that follows. Or, before staging, run `git status --porcelain --untracked-files=all -- work/<id>` and put any non-message file to the person.

### L9 — the same step — low — `rm -rf work/<id>` depends on the working directory and follows a symlinked `work`

- The step does not say where the commands run (compare step 6.1, "in the item worktree"). The Lead's shell starts in the main checkout. A `cd` into `../wt/<id>`, which is outside that directory, does not persist to the next call. A bare `rm -rf work/<id>` then runs against the main checkout's `work/<id>`, not the worktree's. The damage stays inside the project clone, but it is the wrong tree.
- `rm` follows a symlinked parent directory. Reproduced: in a repo with a committed `work -> ../outside`, `git rm -r work/39` fails (pathspec did not match), and the separate `rm -rf work/39` then deletes `../outside/39` with its contents. This needs a symlink committed on the branch, so it is unlikely. It is the one way the step can reach outside the worktree.

Fix: use the worktree's absolute path from the lead state, and check the id and the path first:
`case "<id>" in ''|*[!0-9]*) stop;; esac; w="<worktree>"; [ -L "$w/work" ] || [ -L "$w/work/<id>" ] && stop; git -C "$w" rm -r -q -- "work/<id>" && rm -rf -- "$w/work/<id>"`. With `&&`, the `rm` never runs when `git rm` fails.

### L10 — `hansei.md` wait kinds (`interrupted` row) and `contracts/39-stage-log.md:95` — low — the documented `pmset` filter brings in activity data that can end up in the record

`pmset -g log | grep -E ' (Sleep|Wake) '` matches far more than sleep and wake events. On this machine it matched 4,159 lines: `Assertions` lines with PIDs and process names, `Wake Requests` lines with the uid and launchd service names, client-ack delay lines naming drivers and Bluetooth, battery charge, and the local timezone offset. Only 745 of those lines were `Sleep` or `Wake` events. Nothing says what the Lead may copy. A raw line pasted into a wait's `What` cell is committed in the lead state and stays in `--merge` history, which is public for this repo. The worked example copies only times (`pmset shows sleep 13:53Z–14:08Z`), which is fine.

Fix: give the exact filter and a copy rule. Use `pmset -g log | awk -F'\t' '$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *$/ {print $1}'`, which prints only `<local time> <offset> Sleep|Wake` (verified: only Sleep and Wake lines). Add the rule: "Copy only the UTC start and end of the sleep into `What`, never a pmset line." This also means the Lead converts the `+0100` offset to UTC, which is a correctness point for QA.

### I3 — `docs/factory/release-runbook.md`, *Tag* — informational

The tag step takes the merge commit from `gh pr view item/39`, which picks the PR by branch name, while the post-merge check uses `gh pr view 40`. If the lookup found the wrong PR or none, `--jq .mergeCommit.oid` would print nothing, and `git tag factory-v1.0.0 ""` fails, so no wrong tag is made. The post-merge checks (`rev-parse` equals PR 40's merge commit, `merge-base --is-ancestor`) would catch a wrong commit anyway. Using the PR number in both places is more robust.

### Note for the lead (not a security finding)

`bash tests/run.sh` at `5e5b9f1` reports FAILURES in `test_standard_text.sh` (ac11, ac14, ac15, example-lead-time). These are v1 text pins that the v2 wording replaced. That is QA's area, and QA is re-verifying in parallel.

Verdict after the schema v2 review: **pass**. L8–L10 are low and do not block the merge. The developer should fix them in the same round if there is one, since L8 and L10 are about what reaches permanent public history.

## Re-verify, round 5

Re-verified 2026-11-05 at `c20992e` (developer `cf700de`, `c20992e`; HEAD `9053427` adds only the devops runbook and lead files). The probes ran on throwaway files and repos in the scratchpad. Nothing in the repo or under `~/.claude` was changed, and real transcripts were only read.

Files reviewed: `plugins/factory/scripts/cut-offs.sh` (new), `plugins/factory/scripts/token-spend.sh`, `plugins/factory/references/hansei.md`, `plugins/factory/skills/run/SKILL.md`, and the matching parts of `contracts/39-plugin-scripts.md` §4, `contracts/39-stage-log.md` and `contracts/39-hansei-record.md`.

Dependency audit: no manifest or lockfile changed. `cut-offs.sh` uses only `jq` (1.8.1 here), `bash`, `basename` and `cat`. The secrets grep of the added lines (outside `work/`, `tests/`, `reviews/`) found no token, key or `/Users/` path.

### cut-offs.sh: no finding above low

- **Options.** `--since`/`--until` with no value or a bad shape: exit 2. Unknown option: exit 2, named. `-n.jsonl` without `--`: unknown option, exit 2. With `--` it is read as `./-n.jsonl`. `--sleep-log` with no value: exit 2. A directory, `/dev/null` or a missing file as sleep log: exit 3, basename only.
- **File names.** `$(id).jsonl` is printed as is and never evaluated. Names with a tab or a newline are escaped by `@tsv` (`x\tlimits\tsilent-gap\ty.jsonl`), so a name cannot add fields or lines to stdout.
- **Malformed input.** Non-JSON, a JSON array, and an entry with no `timestamp`: exit 3, `transcript <basename> unreadable`, empty stdout. jq's own stderr is dropped, so no transcript text reaches stderr.
- **Sleep log.** `/etc/passwd`, 3,000 raw `pmset -g log` lines and one valid line were piped in together. Only the valid line counted: its `+0100` offset was applied, and it turned the gap `interrupted`. No sleep-log text reached stdout or stderr.
- **What the output can carry into the record.** The fields are basename, a fixed kind, two ISO times and the markers. The markers are fixed strings, except `api-error:<.error>`, which copies the transcript's `.error` value (I4).

### token-spend.sh `--require-end` rule 1 (`2>&1` merge): no finding

Merging cut-offs.sh's stderr into its stdout cannot hide a cut-off. On exit 3 or 4 the script stops before the awk test. On exit 0, stderr is empty. A stdout line is counted only with five fields, and the kind and marker fields are fixed strings, while the name field is `@tsv`-escaped. Any other non-zero exit is exit 6 (fails closed). Probed: a spoofed `x<TAB>limits<TAB>silent-gap<TAB>y.jsonl` name and an `n<LF>limits.jsonl` name holding a cut-off still give exit 6. The re-prefixed exit 3 message still names only the basename. `-- -n.jsonl` and `$(id).jsonl` both pass through.

| Finding | Status | Evidence |
|---|---|---|
| L8 | fixed, residual L8a | A scratch repo with item worktree `wt/39`, a shell in the main checkout, and the commands from hansei.md §5 step 6 as written. `scratch.env` (untracked) and `.DS_Store` (ignored) were not staged, and `rm -rf` deleted them. The close commit held only `00-lead-state.md` (changed) and `02-result-x.md` (new). See L8a for a directory named like a message. |
| L9 | fixed, residual L11 | The guard found the worktree through `git worktree list --porcelain` from the main checkout. A committed `work -> ../../outside` and a committed `work/39 -> …/outside/39` both stop the guard, and `outside/39/precious` survives. The `&&` chain is in place. See L11 for the case where the variable is not set. |
| L10 | fixed | hansei.md, contract 39-stage-log and contract 39-plugin-scripts §4 give the exact `awk` filter and the rule to copy only UTC times. On this machine the filter prints 749 lines, and none of them is anything other than `<date> <time> <offset> Sleep\|Wake`. cut-offs.sh never echoes a sleep-log line. |

### L8a — hansei.md §5 step 6.1, SKILL.md 8.6, contract 39-hansei-record — low — the pathspec `*` also matches `/`

`git add -- "work/<id>/[0-9][0-9]-*.md"` is a git pathspec glob, and there `*` crosses directories. A directory `work/39/03-dump/` with a `transcript.md` inside gets staged, as does `99-x.env.md`. Reproduced: `work/39/03-dump/transcript.md` was in the `#39 lead: close` commit. A role would have to create a directory named like a message, so this is unlikely.

Fix: add the `glob` magic, so `*` stays within one level: `git -C "$w" add -- ':(glob)work/<id>/[0-9][0-9]-*.md'`. Verified: it stages `00-lead-state.md` and `03-dump.md`, but not `03-dump/transcript.md` or `x.env`.

### L11 — the same step — low — `$w` does not survive between the Lead's shell calls

The guard sets `w`, and steps 6.1 and 6.2 use `"$w"`. The Lead's Bash tool keeps no variables from one call to the next, and nothing says the guard and the steps must run in one call. When `w` is empty, `git -C ""` runs in the current directory, which is the main checkout, and `rm -rf -- "$w/work/<id>"` becomes `rm -rf -- /work/<id>`. The `&&` after `git rm` stops the `rm` in the usual case, because `work/<id>` does not exist on main. Without that check, the step would reach outside the worktree, and `git -C "" add`/`commit` would run against the main checkout. Reproduced without deleting anything: with `w=""` from the main checkout, `git -C "$w" rev-parse --show-toplevel` prints the main checkout, and the `rm` target is `/work/39`. Claude Code's own safety check refused to run this `rm` line in my probe (variable that could be empty). The Lead's close may be stopped the same way and need a person prompt.

Fix: run the guard and steps 6.1–6.2 as one shell call (say so in the text), and write `"${w:?}"` in every use so that an empty value stops the command. Or have the Lead substitute the resolved absolute path into each command, so no variable is left.

### L12 — `plugins/factory/scripts/cut-offs.sh:52,55` — low — `basename` on a sleep-log name that starts with `-`

`--sleep-log -x` gives `basename: illegal option -- x` and `cut-offs: sleep log  unreadable`, exit 3, and the name is lost (the same pattern as L7). The value is the Lead's own argument, so this cannot be exploited.

Fix: `basename -- "$sleep_log"`, or apply the same `./` prefix as for transcripts.

### I4 — cut-offs.sh `mark`, hansei.md *Cut-offs at close* step 2 — informational

`api-error:` + `(.error | tostring)` copies the transcript's `.error` value into the markers, and hansei.md puts the markers into `What` (`found at close: <markers>`), which is committed. Claude Code writes `.error`, and the values found in this machine's recent transcripts are `rate_limit` and `server_error`. A hand-made `.error` of `x\ty\n/Users/secret/path` comes out `@tsv`-escaped but whole. This is not exploitable, but it goes against the contract's "no message text, no path". A cheap hardening is `if test("^[a-z_]+$") then . else "other" end`.

### Notes for the lead (not security findings)

- **False cut-off markers (correctness, QA's area).** The marker test also matches text that the agent or the brief wrote. A role's first user entry (its brief) containing `cut off mid-stream` produces a `stalled` line, and `token-spend.sh --require-end` then exits 6. An assistant reply starting with `API Error` produces an `interrupted` line. Reproduced with both. Both fail closed: spend reads `not captured`, and the close scan adds a short wait. Briefs for this very feature will quote that phrase, though. Matching only Claude Code's synthetic entries (for example `isApiErrorMessage`, or the exact notice text) would avoid it.
- `--until 2026-11-05T25:99Z` passes the shape check. On a transcript with a gap, jq then fails and the script reports `transcript … unreadable`, exit 3, instead of a bad time, exit 2.
- `bash tests/run.sh` at `9053427` still ends `FAILURES` (the text pins QA is moving). `test_token_spend.sh`: 84 passed.

Verdict after round 5: **pass**. No critical, high or medium finding. L8–L10 are fixed. L8a, L11 and L12 are low and do not block the merge. L11 is the one to fix in a next developer round, because it decides where an `rm -rf` lands.

## Re-verify, final round

Re-verified 2026-11-05 at `79e191c` (developer `57b7592`, `0762ef2`; architect `dbfc448`, `ce920d4`; QA `79e191c`). The probes ran on throwaway repos in the scratchpad, each with a main checkout, an item worktree `wt/39` and an `outside/` directory next to them. Nothing in this worktree, the main checkout or `~/.claude` was changed.

Files reviewed: `plugins/factory/skills/run/SKILL.md` (step 8.6), `plugins/factory/references/hansei.md` (§5 step 6), `plugins/factory/references/protocol.md` (*Messages*), `plugins/factory/agents/security-reviewer.md`, `plugins/factory/scripts/{cut-offs,fingerprint,token-spend}.sh`, `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (*Merge PR*), `docs/adr/0013-*.md`, `contracts/39-hansei-record.md`, `contracts/39-standard-changes.md` §9.

Dependency audit: no manifest or lockfile changed and no new runtime tool. `git clean` is part of git. The secrets grep of the added lines found no token or key. For home paths, see L13 and L14.

The close was tested as written. The guard block was cut from SKILL.md step 6, `<id>` was set to `39`, and the inline commands for 6.1 and 6.2 followed in one script. It ran from the main checkout under both `bash` and `zsh`, because the Lead's Bash tool runs zsh on this machine.

| Finding | Status | Evidence |
|---|---|---|
| L8a | fixed | `':(glob)work/39/[0-9][0-9]-*.md'` staged `00-lead-state.md` (M) and `02-result-x.md` (A) only. `03-dump/transcript.md`, `scratch.env` and the ignored `.DS_Store` were not staged, and `git clean` removed them. The same result came under zsh. |
| L9 | holds | A committed `work -> ../../outside` and a committed `work/39 -> ../../outside/39` both stop the guard (`close: work/ is a symlink`, rc 1), and `outside/` is untouched. |
| L11 | fixed | All three texts (SKILL.md, hansei.md, contract) say "one shell call" and write `"${w:?}"` in every use. With `w=""` in the main checkout, `git -C "${w:?}" rm …` stops before git runs: bash `w: parameter null or not set` (rc 127), zsh `w: parameter not set` (rc 1). The rest of the line never runs. The `rm -rf` on a variable is gone, so Claude Code's removal check no longer comes into it. |
| L12 | fixed | `basename --` is used in every call in all three scripts (no bare `basename` is left). `cut-offs.sh --sleep-log -x` gives `sleep log -x unreadable`, exit 3. `cut-offs.sh -- -missing.jsonl` and `token-spend.sh -- -missing.jsonl` give `transcript -missing.jsonl unreadable`, exit 3. `fingerprint.sh -x` gives `not a factory plugin root: -x`, exit 2. |
| I4 | fixed | `.error` values `rate_limit` and `server_error` pass through unchanged. These all become `api-error:other`: `"x\ty\n/Users/secret/path"`, the object `{"msg":"/Users/secret"}`, `"Server_Error"` and the number `123`. `null` becomes `api-error:unknown`. No path or text from the transcript reaches the markers. |

### `git clean` in place of `rm -rf`: it cannot reach outside the worktree

- **Symlinks inside `work/39/`.** These were planted untracked: an absolute link to `outside/sub`, a link to `outside/precious`, `deep/out -> outside`, a relative `rel -> ../../../outside`, and `sub/x -> outside/sub` in a subdirectory. Each link was removed and nothing it pointed to was touched. A tracked link `03-tracked-link.md -> outside` (named like a message) was removed by `git rm` as a link, and `outside/` kept every file.
- **The guard bypassed on purpose.** I ran the commands with `work -> ../../outside` committed. `git clean -f -d -x -q -- work/39` exits 0 and deletes nothing behind the link. `git rm` fails with `pathspec … did not match`, so the `&&` chain stops there. `outside/39/precious` survives. So `git clean` gives a second barrier behind the guard.
- **Pathspec outside the repo.** `git -C <wt> clean -n -fdx -- ../../outside` is refused (`is outside repository`, rc 128). The id is numeric (the guard checks it), so the pathspec is always `work/<digits>`.
- **Nested repository.** A `git init` under `work/39/nested` is skipped by `git clean` with one `-f`. Then `[ ! -e ]` stops the chain (rc 1), `git rm` stays staged, `nested/` stays in place, and only the `close` commit exists. This matches the text.
- **zsh.** The guard's `case` with `*[!0-9]*` behaves the same in zsh (`3x` stops, `39` goes). Run under zsh, the whole script gave the same commits as under bash.

### L13 — `reviews/qa-39.md:199,205` — low — an absolute home path that stays in main's tree

The review names `claude --plugin-dir /Users/<login>/Projects/portfolio/wt/39/plugins/factory` (l.199) and `Plugin root: /Users/<login>/…` (l.205). It was added in `818e300`. Unlike `work/`, `reviews/` is not removed at close, so this lands in the tree of main, and of every clone, not only in history. Neither safeguard covers it. ADR 0013's rule is written for message files in `work/`. The new checklist line limits itself to `-- work/`. The username is the owner's public login, so the exposure is small, which is why this is low.

Fix: QA writes the path as `../wt/39/plugins/factory` or `~/Projects/portfolio/wt/39/plugins/factory` before the merge. That is one edit to its own file, and it also takes the path out of main's tree. For later items, the architect could widen the protocol rule from "a message file" to "any file a role commits" (reviews, contracts, docs). The checklist line could then drop the `-- work/` limit: `git log -S"$HOME/" --format='%h %s' origin/main..HEAD`, plus `git grep -n "$HOME/" HEAD` for what will sit in main's tree.

### L14 — checklist line run on item/39 — low (as the line prescribes)

I ran `git log -S"$HOME/" --format='%h %s' origin/main..HEAD -- work/`. It prints two commits:

- `a3af016 #39 lead: verification briefs, architect feedback` adds `work/39/09-brief-qa-engineer.md:7`. This is the known path that ADR 0013 accepts.
- `27c8fc3 #39 architect: options for merge style (#48)` adds `work/39/60-options-architect.md:8`, which quotes the same path while it describes it.

The second hit is a quotation of the first and exposes nothing new. But ADR 0013's *Consequences* says #39 has "its one home path (in `work/39/09-brief-qa-engineer.md`)", and there are two files in `work/` (and the review in L13). Fix: no history rewrite (as ADR 0013 says). The architect corrects the ADR sentence to name both files, or words it as "one home path, in the QA brief and quoted in the options file". The lead and the architect keep the rule from now on by quoting such a path as `~/…` or `<home>/…`.

The line works as intended: it found the known path and one more. Its blind spots are covered by I5 and L13.

### Informational

- I5 — `agents/security-reviewer.md`, checklist line. `-S"$HOME/"` matches only the reviewer's own home directory. A home path written on another machine is not found, for example by a second contributor, under `/home/<user>/` on Linux, or by a CI runner. For this single-person setup that is enough. A wider net would be `git log -G'/(Users|home)/[A-Za-z0-9._-]+/' …`, but that needs reading by hand, because placeholders such as `/Users/alice/` in contract 39-standard-changes l.98 also match.
- I6 — SKILL.md 8.6 and hansei.md §5 step 6.1. The text says the call is "one script that stops at the first failure", but 6.1 is given as prose commands that are not chained. If the Lead writes them on separate lines with no `set -e` or `|| exit 1`, a failed `git add` (an `index.lock`, say) lets the chain go on. `git rm` refuses a modified lead state and stops. But a result file that was never committed is untracked, so `git rm` passes it by and `git clean` deletes it. A message would then be lost from the record's evidence. That is integrity, not reach: nothing outside the worktree is touched. Fix: give 6.1 and 6.2 as one fenced block with `|| exit 1` after each 6.1 command, as the guard already does. I used that form in the probe script, and it closes the gap.

Verdict after the final round: **pass**. No critical, high or medium finding, so nothing blocks the merge. L13 is a one-line edit for QA in a file it owns, and it is worth making before the merge because `reviews/` stays in main's tree. L14 needs an ADR wording fix and no history change.
