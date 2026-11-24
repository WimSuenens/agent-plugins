#!/bin/bash
# The `run:` steps of the CI the project declares, for the QA brief (#254): QA runs the ones that need no secret and no network before it hands back.
# Usage: bash ci-steps.sh [<factory.md>]      (default docs/agents/factory.md in the current directory; run it in the item worktree)
# Reads the first line `ci: ...` at column 0 of the file. `ci: none` prints `none`. `ci: workflow <path> ...` names a workflow file: <path> must be under
# `.github/workflows/` and end in .yml or .yaml, relative to the current directory. Prints, one per line, the `run:` steps of the jobs that run on pull
# requests, in file order: nothing when the workflow's `on:` has no `pull_request`, and a job whose `if:` names only a push (`event_name == 'push'`) is left out.
# A multi-line `run:` is one line: lines joined with `; ` (a `>` block with a space). Quotes around a one-line `run:` are removed; nothing is expanded or run.
# Prints `none` when there is no step to print. The lead puts the output in the QA brief; it decides which steps need a secret or the network (a person's judgement).
# Exit: 0 printed; 2 usage, an unreadable file, no `ci:` line, a workflow path outside `.github/workflows/` or missing.
# bash 3.2 compatible; needs awk.

f="${1:-docs/agents/factory.md}"
[ $# -le 1 ] && [ -r "$f" ] || { sed -n '2,/^# bash 3.2/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
line="$(grep -m 1 '^ci:' "$f" | tr -d '\r')"
[ -n "$line" ] || { echo "ci-steps: no ci: line in $(basename "$f")" >&2; exit 2; }
case "$line" in
  "ci: none" | "ci: none "*) echo none; exit 0 ;;
  "ci: workflow "*) ;;
  *) echo "ci-steps: the ci: line names no workflow file and is not none" >&2; exit 2 ;;
esac
wf="${line#ci: workflow }"; wf="${wf%% *}"
case "$wf" in
  .github/workflows/*.yml | .github/workflows/*.yaml) ;;
  *) echo "ci-steps: the workflow must be under .github/workflows/ (.yml or .yaml)" >&2; exit 2 ;;
esac
case "$wf" in *..*) echo "ci-steps: the workflow path may not hold .." >&2; exit 2 ;; esac
[ -f "$wf" ] && [ -r "$wf" ] || { echo "ci-steps: $wf: not a readable file" >&2; exit 2; }

out="$(tr -d '\r' <"$wf" | awk '
  function ind(l) { match(l, /^ */); return RLENGTH }
  function trim(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
  function flush() { if (inb) { st[++ns] = sjob SUBSEP trim(buf); inb = 0; buf = "" } }
  function unq(x) { x = trim(x); if (x ~ /^".*"$/ || x ~ /^\x27.*\x27$/) x = substr(x, 2, length(x) - 2); return x }
  {
    l = $0
    if (inb) {
      if (trim(l) == "") next
      if (ind(l) > keycol) { t = trim(l); if (t !~ /^#/) buf = (buf == "" ? t : buf sep t); next }
      flush()
    }
    if (trim(l) == "" || trim(l) ~ /^#/) next
    i = ind(l)
    if (i == 0) {
      sec = "other"
      if (l ~ /^("on"|\x27on\x27|on):/) { sec = "on"; rest = l; sub(/^[^:]*:/, "", rest); if (rest ~ /(^|[^A-Za-z_])pull_request([^A-Za-z_]|$)/) pr = 1 }
      else if (l ~ /^jobs:/) { sec = "jobs"; jobind = -1 }
      next
    }
    if (sec == "on") { if (l ~ /(^|[^A-Za-z_])pull_request([^A-Za-z_]|$)/) pr = 1; next }
    if (sec != "jobs") next
    if (jobind < 0) jobind = i
    if (i == jobind && l ~ /^ *[A-Za-z0-9_-]+:/) { job++; sjob = job; next }
    if (l ~ /^ *if:/ && i == jobind + 2) { if (l ~ /event_name *== *\x27push\x27/ && l !~ /pull_request/) skip[job] = 1; next }
    if (l ~ /^ *(- +)?run:/) {
      key = index(l, "run:"); keycol = key - 1
      v = substr(l, key + 4)
      v = trim(v)
      if (v ~ /^[|>][+-]?$/) { inb = 1; buf = ""; sep = (substr(v, 1, 1) == ">") ? " " : "; "; next }
      st[++ns] = sjob SUBSEP unq(v)
    }
  }
  END {
    flush()
    if (!pr) exit
    for (k = 1; k <= ns; k++) { split(st[k], p, SUBSEP); if (!skip[p[1]] && p[2] != "") print p[2] }
  }')"
if [ -n "$out" ]; then printf '%s\n' "$out"; else echo none; fi
