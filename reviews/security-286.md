# Security review — #286 (run-level timing, factory 3.10.0)

Verdict: **pass** at `c364068` (round 2, task #303): no open finding. L1 and L2 (low) are closed by `964bc25` and `5ad4dac`; I1 stays informational.

Round 1 reviewed `291e787` (branch `item/286`, PR #296), diff against `origin/main`, verdict pass with L1 and L2 open (task #298). Reviewer: security-reviewer.

## Scope

All 59 changed files (`git -c core.quotePath=false diff --no-renames --name-only origin/main...item/286`) plus `reviews/qa-286.md` and QA's fixtures added since. Focus as briefed: `plugins/factory/scripts/run-timing.sh` (new), `run-state.sh` (`add-session`, `add-run-wait`, `lead-sessions`), `a3-check.sh` (v4), the `Session: ${CLAUDE_SESSION_ID}` line and its fallback in `skills/run/SKILL.md`, step 9.2 a–e of `references/run-close-run.md`, `references/hansei.md` section 8, and what reaches the tracker from transcripts.

## OWASP and data handling, per area

| Area | Result |
|---|---|
| Injection (A03), `run-timing.sh` | No `eval`, no command built from input. File arguments are passed to awk with `./` prepended (`argpath`), so a name such as `x=1` or `-l42.md` is read as a file, not an assignment or option (probed: both give the same line as the plain fixtures). `--close` goes through `awk -v` but is matched against the strict time regex; `2026-12-01T15:00Z\n` exits 2. No temp file, no clock, no network. |
| Injection (A03), `run-state.sh` | `add-session` restricts the id to `^[A-Za-z0-9-]{1,64}$` before it reaches `awk -v`. `add-run-wait` passes `--what` through `ENVIRON` (no backslash processing); `\|` and newline are refused. Probed `$(id)`, backticks, `a\nb\\c`, `-n`, `<script>`, `@login`: each is written literally into the row, nothing evaluated. Times are pattern-checked before use. |
| Injection, `a3-check.sh` v4 | Pure validation over the A3 file; awk regexes only (DFA, no backtracking blow-up). No new file or network access. |
| Sensitive data to the tracker (A01/A09) | What `run-timing.sh gaps` emits goes into the run ticket body. The only transcript-derived parts are the kind (checked against three values) and the markers column of `cut-offs.sh`, which today is a fixed vocabulary (`cut-mid-stream`, `request-interrupted`, `api-error:<[a-z_]+ or other>`, `api-retry`, `silent-gap`). No transcript text, no path. The transcript basename goes only to stderr. `run timing` line: figures and fixed reasons only. See L1 for the missing check on the markers column. |
| `${CLAUDE_SESSION_ID}` and fallback | The id is only ever written through `add-session`, which validates it; the fallback (`hansei.md`, *Label*: the id from the first subagent transcript path) goes through the same check. A non-substituted literal `${CLAUDE_SESSION_ID}` would be refused (it holds `$`, `{`, `}`). Session ids in the public run ticket: accepted as before (random, local-only, grant no access; reviews/security-39.md L5). |
| Transcript paths built from the body | Step 9.2 b builds `~/.claude/projects/<project>/<id>.jsonl` from `run-state.sh lead-sessions`. That read does not validate the ids: see L2. |
| Data egress (question E) | The PR notes the item branch is pushed after each stage, so `work/286/` reaches the public remote before review. Target is the project's own repository, which its collaborators already read: no new egress. Consequence: anything a role writes in `work/` is public at once, so the home-path and secret checks below matter before the PR, not only at merge. |
| Secrets and home paths | Added lines grepped for `/(Users\|home)/<name>/`, GitHub/OpenAI/AWS token shapes, private keys, `password=`/`token=`: no hit. `git log -S"$HOME/" origin/main..HEAD -- work/`: no line. `git grep "$HOME/" HEAD`: hits only in older reviews (security-39, security-156), none from this item. Every `work/286/` file is `00-lead-state.md` or `NN-<type>-<role>.md`. The transcript fixture `tests/factory/fixtures/run286/lead-b5.jsonl` is synthetic. |
| Tests (`tests/factory/*286*`, `run_timing_oracle.py`, `runs_replay.py`) | No `shell=True`, `eval`, `os.system`, pickle or `rm -rf`; files written only under the directory the test passes in. |
| Resource use (A04) | `run-timing.sh` walks the run window minute by minute; see I1. |

## Findings

### L1 — `run-timing.sh gaps` passes the markers column through unchecked — low — closed in round 2

- Location: `plugins/factory/scripts/run-timing.sh`, the cut-offs block (`fi == nled + 2`): `g[5]` is stored as `gm[ng]` and printed as `found at close: <markers>`; `references/run-close-run.md` step 9.2 c turns each line into `run-state.sh add-run-wait … --what <what>`, posted to the run ticket.
- Seen: a cut-offs line whose markers held a command substitution, an absolute path under a user's home folder and an `@` mention came out with all three unchanged in the `found at close:` field (exit 0). The kind and times are checked; the markers are not.
- Impact: not exploitable today, because `cut-offs.sh` emits only a fixed vocabulary (hardened in item 39, I4). But the guarantee "no transcript text or path on the tracker" now rests on a different script, and step 9.2 c has the lead write a shell command from this field.
- Recommended fix: in the cut-offs block, add `g[5] !~ /^[a-z_:-]+(,[a-z_:-]+)*$/` to the format check (a line that fails is the existing `a cut-offs line not in its format` exit 2). Optionally say in step 9.2 c to single-quote `--what`.

### L2 — `run-state.sh lead-sessions` does not validate the ids it prints — low — closed in round 2

- Location: `plugins/factory/scripts/run-state.sh`, the field reader (`lead-sessions` → `key="lead sessions"`); used by `references/run-close-run.md` step 9.2 b to build transcript paths and a `cut-offs.sh` command.
- Seen: a body with `- lead sessions: ../../x, $(touch pwned), abc` prints that value unchanged (exit 0). `add-session` on that body keeps the bad ids and appends the new one. Nothing was executed in the probe; the risk is in the lead's command built from the output.
- Impact: the run ticket body can be edited by any collaborator with triage or write access. A hand-edited id could steer the scan to another `.jsonl` (path traversal: only markers come out, so little leaks) or put shell syntax into the command the lead writes. Needs collaborator access, so low.
- Recommended fix: for `lead-sessions`, split on `, ` and check each id against `^[A-Za-z0-9-]{1,64}$`; on failure exit 2 with `run-state: lead sessions: an id not in its format` (step 9.2 b then reads `not captured`). Optionally have `add-session` apply the same check to the ids already present.

### I1 — the minute-by-minute loop grows with the run window — informational

- Location: `run-timing.sh` END, `for (m = S; m < C; m++)` (and the per-gap loop in `gaps`).
- Seen: a `started:` of `1970-01-01T00:00:00Z` with the fixture ledgers took 29 s of CPU and printed `raw 498927h00m`. A real run of days or weeks is instant.
- Recommended fix (optional): refuse a window longer than, say, 366 days with exit 2, or count with interval arithmetic. No merge impact.

## Dependency audit

No manifest or lockfile changed (no `package.json`, lockfile, `requirements*.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile` in the diff). No new dependency. The new and changed scripts use only bash (3.2.57 here), awk (BSD awk 20200816), sed, tr, grep, cut, sort and head; `cut-offs.sh` (unchanged) needs jq (1.8.1 here). The QA oracles use the Python 3 standard library only (3.15.2 here).

## Changed paths

`paths.sh check --own-role-files` with the briefed ignores, over the changed-file list: no `off-list:` line (exit 0).

## Re-verify (after fixes)

The checks asked for in round 1:

- L1: a cut-offs line with a marker outside `[a-z_:-]` makes `gaps` exit 2; the existing fixtures still pass.
- L2: `lead-sessions` on a body with `../../x` exits 2; on a valid body it prints the ids as before.

## Round 2 — re-verification at `c364068`

| Finding | Status | Evidence |
|---|---|---|
| L1 (low) | closed | `run-timing.sh` (`964bc25`, `5ad4dac`) adds `g[5] !~ /^[a-z_:-]+(,[a-z_:-]+)*$/` to the cut-offs format check and names a bad line as `line <k>` only. Probed markers: a command substitution, a `'`, a space, upper case, `\|`, `,` and `a,,b`. Each exits 2 with `a cut-offs line not in its format: line 1`, and the line is not echoed. `cut-mid-stream,api-error:rate_limit` still passes (exit 0). |
| L1, step 9.2 c quoting | holds | `--what '<what>'` in single quotes. The `what` is `found at close: ` plus the markers grammar `[a-z_:-,]`, so it can hold no `'`, `$`, backtick or backslash, and the single quotes hold for every value the grammar allows. |
| L2 (low) | closed | `run-state.sh lead-sessions` (`964bc25`) checks each `, `-separated id against `^[A-Za-z0-9-]{1,64}$` and exits 2 with `id <i> of <n>`, never echoing the value. Probed: `../../x` → `id 1 of 1`, exit 2; `$(touch …), abc` → `id 1 of 2`, exit 2, and nothing ran; `abc, ../y` → `id 2 of 2`, exit 2; `abc,def` (no space) → exit 2; `none yet`, `abc, def` and an empty value print as before (exit 0). Step 9.2 b maps exit 2 to `not captured (lead sessions line not in its format)`. |
| I1 (info) | unchanged | Optional; no merge impact. |

Residual, informational only: `add-session` still keeps ids already in the line without checking them. The reader now refuses them, so no path or command is built from them. `gaps` still names the transcript basename (field 1) on stderr in its `inside items` and `outside the run` notes. That is stderr only and never reaches the tracker.

Home-shaped path in this file (round 1, the L1 probe on line 31): reworded to describe the probe without the path. `bash tests/factory/test_release64.sh` check `ac45-no-home-path-or-token-in-changed-files`: see the result of task #303.

Dependency audit, round 2: the fix commits touch two scripts and two references; no manifest changed, no new dependency.
