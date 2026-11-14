#!/usr/bin/env bash
# The one reader of the Factory run section, and the rule for which ticket holds it (#187 decision 9; #207 slice 4).
# Usage: bash run-state.sh <field> <ticket body file>
#        bash run-state.sh ticket --route direct|map --destination <n> [--map <n>]
# <field>: started | step | in-flight | freeze | hansei | closed | baseline | items
#   Reads the `- <field>: <value>` line inside the body's `## Factory run` section (up to the next `## ` heading) and nowhere else. The body is
#   the run ticket's: the map's in the map route, the destination ticket's in the direct route; the section has the same shape in both.
#   `items` prints the item numbers of the `closed in this run` line (`#30 #29`), empty when it says none.
# ticket: prints `#<n>` of the run ticket: the destination ticket in the direct route (no map exists), the map in the map route.
# Exit: 0 printed; 1 the body has no Factory run section; 2 usage, an unknown field, or an unreadable file; 3 the section has no such line.

usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ $# -ge 1 ] || usage

if [ "$1" = ticket ]; then
  shift; route=""; dest=""; map=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --route) route="${2:-}"; shift 2 || usage ;;
      --destination) dest="${2:-}"; shift 2 || usage ;;
      --map) map="${2:-}"; shift 2 || usage ;;
      *) usage ;;
    esac
  done
  case "$dest" in '' | *[!0-9]*) usage ;; esac
  case "$route" in
    direct) echo "#$dest" ;;
    map) case "$map" in '' | *[!0-9]*) echo "run-state: the map route needs --map <n>" >&2; exit 2 ;; esac; echo "#$map" ;;
    *) usage ;;
  esac
  exit 0
fi

field="$1"; body="${2:-}"
case "$field" in
  started | step | in-flight | freeze | hansei | closed | baseline | items) ;;
  *) usage ;;
esac
[ -n "$body" ] && [ -f "$body" ] && [ -r "$body" ] || { echo "run-state: ${body:-no file}: unreadable" >&2; exit 2; }

sec="$(tr -d '\r' <"$body" | awk '/^## /{ on = ($0 ~ /^## Factory run[ \t]*$/); if (on) found = 1; next } on { print } END { exit found ? 0 : 7 }')"
[ $? -eq 0 ] && [ -n "$(tr -d '\r' <"$body" | grep -m 1 '^## Factory run[[:space:]]*$')" ] || { echo "run-state: $body has no Factory run section" >&2; exit 1; }

key="$field"
case "$field" in freeze) key="FREEZE" ;; items) key="closed in this run" ;; closed) key="closed in this run" ;; in-flight) key="in flight" ;; esac
line="$(printf '%s\n' "$sec" | grep -m 1 "^- $key:")"
[ -n "$line" ] || { echo "run-state: the Factory run section has no \`$key:\` line" >&2; exit 3; }
val="$(printf '%s\n' "$line" | sed "s/^- $key:[[:space:]]*//; s/[[:space:]]*\$//")"
if [ "$field" = items ]; then
  [ "$val" = none ] && exit 0
  printf '%s\n' "$val" | grep -oE '(^|, )#[0-9]+' | tr -d ', ' | tr '\n' ' ' | sed 's/ $//'; echo
  exit 0
fi
printf '%s\n' "$val"
