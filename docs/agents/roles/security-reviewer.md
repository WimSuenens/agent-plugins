# Role file: security-reviewer

Project rules, checks and knowledge for the security-reviewer role, kept under version control. Only the security-reviewer role reads this file and its skills folder, `docs/agents/skills/security-reviewer/`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

## Knowledge

## Skills used

## Migrated memory

<!-- migrated: factory-security-reviewer/factory-review-probes.md -->
---
name: factory-review-probes
description: Repeatable probes for reviewing factory plugin slices (paths.sh, post-text.sh scan, git diff listing, posting rules)
metadata:
  type: feedback
---

Probes that found real issues in factory reviews:
- `git diff --name-only A...B` hides a rename's source path and quotes non-ASCII names; demand `-c core.quotePath=false diff --no-renames`.
- Path-list comparators: test `p//q` and `p/./q` and case differences, not only `..`.
- Scanners built on awk `{n,}` intervals can fail open on mawk; test with a known token.
- Check every posted artifact (titles, ledger, stage summary, andon), not only briefs and results, goes through the scan.
- `gh issue comment --body "<text>"` with result-derived text is shell-injection-prone; want `--body-file`.

**Why:** found in item 64 review. **How to apply:** run these first on any factory slice touching scripts or posting rules.

<!-- migrated: factory-security-reviewer/shell-tooling-review-probes.md -->
---
name: shell-tooling-review-probes
description: Probes and recurring gaps when security-reviewing bash helper scripts and gh/tracker instructions in agent/plugin repos
metadata:
  type: feedback
---

Probes that found real issues in bash tooling reviews (factory plugin scripts, 2026-11):

- `git diff --name-only` quotes non-ASCII/special paths (`"a/d\303\251.md"`), so `case` path classification silently misses them. Recommend `-z` + `read -d ''`, or fail closed on unclassified paths. On re-verify, check that the `-z` output isn't piped back through `tr '\0' '\n'`: a newline in a file name then splits the path and escapes the classification again. A `*$'\n'*) level=minor` case on the raw `-z` records is enough. Don't insist on a catch-all when the contract makes the other paths a lower level.
- `cmd < "$file"` inside `$(...)` on an unreadable file: error printed, empty output, script still exits 0. Check for "measured value from nothing" (violates honesty rules for metrics).
- Gates run once at PR open (version bump etc.) are often not re-run before merge/tag; feedback rounds can change the checked files afterwards.
- `gh api .../comments | select(.body|startswith(marker))` without `.user.login` filter is spoofable on public repos.
- Error messages carrying absolute `$HOME` paths end up copied into "not captured (<reason>)" fields on public trackers; `work/` dirs deleted before a `--merge` merge stay in history.
- Probe option injection on ref args (`--output=/tmp/x` as base ref): `git rev-parse --verify` first blocks it.
- Probe harness gotcha: `git reset --hard; git clean -fd` between probes deletes empty dirs, so `mkdir -p` before each probe.
- Option-like filenames (`-n.jsonl`) break `basename`/`jq`.
- Unchecked `tmp=$(mktemp -d)`: on failure paths collapse to `/out`, `/repo`. macOS `mktemp -d` ignores TMPDIR, so you can't easily force the failure there; rate low and recommend `|| exit 1`.
- Cleanup steps for agent-run instructions: `git add -A <dir>` before a removal commit sweeps stray untracked files (.env, dumps) into permanent `--merge` history; relative `rm -rf dir/<id>` depends on the cwd (the lead's shell resets to the main checkout when it cds outside it) and follows a committed symlinked parent (`git rm` fails, then `rm -rf` deletes outside). Recommend explicit files, `git -C <abs>`, an id regex, an `-L` check, `&&`.
- Re-verify of such fixes: a git pathspec `"dir/[0-9][0-9]-*.md"` lets `*` cross `/` (use `':(glob)…'`). And a variable set in a "guard" block (`w=…`) does not survive between the agent's Bash tool calls. Empty `$w` makes `git -C ""` act on the cwd and turns `rm -rf -- "$w/x"` into `/x`. Require one shell call plus `"${w:?}"`. Claude Code's safety check blocks such `rm` lines (even in probes): replace `rm` with `echo` to show the target, and never try to get around the check.
- `git -C "$w" clean -f -d -x -q -- dir/<id>` is a good `rm -rf` replacement: it removes symlinks as links, does nothing behind a symlinked parent, refuses out-of-repo pathspecs, and skips nested repos (pair it with `[ ! -e ]`). Run close scripts under zsh too (the agent Bash tool may be zsh). Prose commands described as "one script that stops at first failure" need an explicit `|| exit 1`, or a failed `git add` lets the cleanup delete uncommitted files.
- Home-path checks scoped to `-- work/` miss `reviews/`, which stays in main's tree. Also run `git grep "$HOME/" HEAD`. `-S"$HOME/"` only sees the reviewer's own home.
- Instructions that tell an agent to read macOS `pmset -g log` with a loose grep (`' (Sleep|Wake) '`) pull in PIDs, process/service names, uid, battery, and timezone. The exact filter is `awk -F'\t' '$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *$/ {print $1}'`, plus a "copy times only" rule.
- Tiny CLI slices (printf-only): probe `-n`, `%n`, `$(id)`, backticks, and control bytes; keep the review short and proportionate.

**Why:** these were the non-obvious findings; the obvious quoting was usually fine.
Session ids / agent ids in committed state: accepted as low-value (random, local-only, grant no access) when the workflow needs them after a resume.

**How to apply:** run these probes on scratchpad copies for any shell tooling review; dependency audit for such slices = "no manifests changed" + note runtime tool versions.
