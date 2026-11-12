#!/usr/bin/env bash
# The Obeya opt-in of docs/agents/factory.md: the `## Obeya` section with its `obeya: on|off` line.
# Usage: bash obeya-optin.sh status
#        bash obeya-optin.sh set <on|off> [--replace]
# Run from the project root. Setup runs `set` only after the person answered yes or no; there is no default write.
# status: prints "on", "off" or "unanswered" (no `obeya: on|off` line at column 0).
# set: with no line, adds the `## Obeya` section (before `## Tracker`, else at the end) and prints "added obeya: <v>".
#      With a line already there it changes nothing and prints "already answered: <v>", unless --replace is given
#      (setup uses it only right after copying the template, whose `obeya: off` is not an answer): "replaced obeya: <v>".
# Exit: 0 ok; 2 usage, a value other than on or off, or no docs/agents/factory.md.

f="docs/agents/factory.md"
cmd="${1:-}"; [ $# -gt 0 ] && shift
[ -f "$f" ] || { echo "obeya-optin: no $f here" >&2; exit 2; }

current() { awk '/^obeya:[ \t]*(on|off)[ \t]*$/ { sub(/^obeya:[ \t]*/, ""); sub(/[ \t]*$/, ""); print; exit }' "$f"; }

case "$cmd" in
status)
  v="$(current)"; echo "${v:-unanswered}"
  ;;
set)
  v="${1:-}"; [ $# -gt 0 ] && shift
  case "$v" in on | off) ;; *) echo "usage: obeya-optin.sh set <on|off> [--replace]" >&2; exit 2 ;; esac
  replace=0
  for a in "$@"; do [ "$a" = --replace ] && replace=1 || { echo "usage: obeya-optin.sh set <on|off> [--replace]" >&2; exit 2; }; done
  have="$(current)"
  if [ -n "$have" ] && [ "$replace" = 0 ]; then echo "already answered: $have"; exit 0; fi
  tmp="$(mktemp)"
  if [ -n "$have" ]; then
    awk -v v="$v" '!d && /^obeya:[ \t]*(on|off)[ \t]*$/ { print "obeya: " v; d = 1; next } { print }' "$f" >"$tmp"
    verb=replaced
  else
    secf="$(mktemp)"
    cat >"$secf" <<EOT
## Obeya

obeya: $v

Set \`obeya: on\` to opt in to the Obeya, a read-only browser view of this project. \`/factory:obeya\` then starts and stops it in a container on loopback; without \`on\` the command refuses. A project that does not opt in keeps the existing workflow untouched.

EOT
    if grep -q '^## Tracker$' "$f"; then
      awk -v sf="$secf" '!d && /^## Tracker$/ { while ((getline l < sf) > 0) print l; d = 1 } { print }' "$f" >"$tmp"
    else
      { cat "$f"; [ -z "$(tail -c1 "$f")" ] || echo; echo; cat "$secf"; } >"$tmp"
    fi
    verb=added
  fi
  cat "$tmp" >"$f"; rm -f "$tmp" "${secf:-}"
  echo "$verb obeya: $v"
  ;;
*)
  echo "usage: obeya-optin.sh status | set <on|off> [--replace]" >&2; exit 2
  ;;
esac
