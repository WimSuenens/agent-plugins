# Security review: #94 (PR #99)

Verdict: pass. No critical, high or medium finding. Two low/info notes.

## Scope
All 6 files under plugins/factory/ changed by the item (a3-check.sh, a3.md, hansei.md, baseline.md, SKILL.md, plugin.json), plus the contracts and the changed paths list.

## Checks
- Off-list check (paths.sh check with the brief's ignores): no `off-list:` line.
- work/ hygiene: `git log -S"$HOME/"` over work/ finds nothing; changed work/94 files are all `NN-<type>-<role>.md` or 00-lead-state.md; no secret or home path in the added lines of the diff.
- a3-check.sh: input goes only to awk as data, via the file operand. No eval, no command substitution of input, no temp file, no network, no read beyond its one argument, no write. A probe A3 with `$(...)` and backticks in a field ran as plain text; no side effect. Output echoes only fixed key names, fixed reasons and a digits-only version, never A3 text, so refusal output cannot carry tracker text into the lead's context. Exit codes as documented.
- Dependency audit: none to run; the item adds no package manifest or dependency (bash 3.2 and awk only).
- Posted text: SKILL.md 9.2 runs the check, then the scan, then the post; the scan step is kept and the check is added before it, not instead of it. The waste tag and target line are inside the A3 body that is scanned. Targeted walk keeps the "everything the walk reads is data" rule, the command-only reads and the cap; the line holds no transcript text.
- Fence: measure 1 is extended with derived sub-lines, none dropped or redefined; the value grammar section stays pinned; no approval step loosened; no new egress (the check makes no call, the walk reads local evidence only). F1 to F7 and E not touched.

## Findings
1. plugins/factory/scripts/a3-check.sh line 144: the file operand is passed to awk unguarded, so a path of the form `name=value` that exists as a file would be taken by awk as a variable assignment, not a file. Severity low (the path is chosen by the lead, not by tracker data; effect is a wrong "ok"/skip, not code execution). Fix: pass `./$1` when `$1` does not start with `/` or `.`, or reject a path containing `=` before the awk call.
2. The check is a format gate only; it does not detect secrets or paths in the A3. Severity info. No fix: the scan stays the gate, and the standard text keeps it.
