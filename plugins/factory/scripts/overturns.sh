#!/bin/bash
# overturns.sh: the overturned count of hansei measure 3 (references/hansei.md), from the bodies of the slice's rework tasks.
# Usage: overturns.sh [<rework-body>...]     one file per rework sub-issue body (`gh issue view <n> --json body --jq .body`); none prints 0.
# Prints the number of `Overturns:` lines that are not `none`, summed over the files: one line per overturned two-way decision, so a
# task that overturns two decisions adds 2. The task's `Source` plays no part: it says only who routed the work.
# Each body must hold the line (references/protocol.md, the feedback template): `Overturns: none`, alone, or one or more lines
# `Overturns: <role> — <decision>`, <role> one of the seven roles. Anything else is a template error, never a zero.
# Exit: 0 printed; 2 usage or a file unreadable; 3 a body breaks the template (stderr names the file, and the line when there is one;
# nothing printed). Needs awk only; reads the files it is given and nothing else.
# A relative path is given to awk as ./<path>, so a name holding `=` is read as a file, not as a variable assignment.

awk_operand() {
  case "$1" in /*) printf '%s' "$1" ;; *) printf './%s' "$1" ;; esac
}

total=0
for f in "$@"; do
  [ -f "$f" ] && [ -r "$f" ] || { echo "overturns: $(basename "$f"): unreadable" >&2; exit 2; }
done
rc=0
for f in "$@"; do
  b="$(basename "$f")"
  # LC_ALL=C: the em dash is matched as its bytes
  n="$(LC_ALL=C awk -v b="$b" '
    { sub(/\r$/, "") }
    /^Overturns:/ {
      lines++
      v = $0; sub(/^Overturns:[ \t]*/, "", v); sub(/[ \t]+$/, "", v)
      if (v == "none") { none++; next }
      if (v ~ /^(product-owner|architect|developer|qa-engineer|security-reviewer|devops|docs-writer) \342\200\224 [^ \t]/) { k++; next }
      print "overturns: " b ":" NR ": not `none` and not `<role> — <decision>`" > "/dev/stderr"; bad = 1
    }
    END {
      if (lines == 0) { print "overturns: " b ": no Overturns line (template error, not a zero)" > "/dev/stderr"; exit 3 }
      if (none && k) { print "overturns: " b ": `Overturns: none` beside an overturned decision" > "/dev/stderr"; exit 3 }
      if (none > 1) { print "overturns: " b ": `Overturns: none` more than once" > "/dev/stderr"; exit 3 }
      if (bad) exit 3
      print k + 0
    }' "$(awk_operand "$f")")" || { rc=3; continue; }
  total=$((total + n))
done
[ "$rc" = 0 ] || exit 3
echo "$total"
