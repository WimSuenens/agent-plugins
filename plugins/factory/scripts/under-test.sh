#!/usr/bin/env bash
# Closing a slice records, per "Under test" line of its frame, whether the observation held; this flags the lines that are not confirmed
# (#160 (a); #207 slice 4).
# Usage: bash under-test.sh <frame file> <hansei record file>
# The frame's `## Under test` section holds one `- [<name>](<link>) — <what would contradict it>` line each (the name is the link text, or the
# text before ` — `). Only the record's measure 7 (the `7.` line and what follows it up to the next numbered line) is read; it holds one `   - <name>: confirmed | contradicted | not exercised` line each.
# Output: one `flag:` line per Under test line that is not `confirmed`, then `under-test: <k> of <n> confirmed`.
#   flag: <name>: contradicted -- resurvey the map            (the observation failed: the resurvey decides)
#   flag: <name>: not exercised -- confirm it or say why it could not be observed
#   flag: <name>: missing -- no line of the record says confirmed, contradicted or not exercised for it   (also `pending resurvey`)
# Exit: 0 every line confirmed; 1 at least one flag; 2 usage, an unreadable file, or a frame with no Under test lines.

[ $# -eq 2 ] && [ -r "$1" ] && [ -f "$1" ] && [ -r "$2" ] && [ -f "$2" ] || { echo "usage: under-test.sh <frame file> <hansei record file>" >&2; exit 2; }

names="$(tr -d '\r' <"$1" | awk '
  /^## /{ on = ($0 ~ /^## Under test[ \t]*$/); next }
  on && /^- / { l = substr($0, 3)
    if (l ~ /^\[[^]]*\]/) { sub(/^\[/, "", l); sub(/\].*$/, "", l) } else { sub(/ — .*$/, "", l) }
    print l }')"
[ -n "$names" ] || { echo "under-test: $1 has no Under test lines" >&2; exit 2; }

n=0; ok=0; bad=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  n=$((n + 1))
  state="$(tr -d '\r' <"$2" | awk '/^[0-9]+\. /{ on = ($0 ~ /^7\. /); next } on' | grep -F -- "- $name: " | grep -E ': (confirmed|contradicted|not exercised)[[:space:]]*$' | head -1 | sed -E 's/^.*: (confirmed|contradicted|not exercised)[[:space:]]*$/\1/')"
  case "$state" in
    confirmed) ok=$((ok + 1)) ;;
    contradicted) bad=1; echo "flag: $name: contradicted -- resurvey the map" ;;
    "not exercised") bad=1; echo "flag: $name: not exercised -- confirm it or say why it could not be observed" ;;
    *) bad=1; echo "flag: $name: missing -- no line of the record says confirmed, contradicted or not exercised for it" ;;
  esac
done <<NAMES
$names
NAMES
echo "under-test: $ok of $n confirmed"
[ "$bad" = 0 ]
