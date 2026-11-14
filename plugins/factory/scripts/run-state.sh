#!/usr/bin/env bash
# The one reader of the Factory run section, and the rule for which ticket holds it (#187 decision 9; #207 slice 4).
# Usage: bash run-state.sh <field> <ticket body file>
#        bash run-state.sh moved <ticket body file>
#        bash run-state.sh ticket --route direct|map --destination <n> [--map <n>]
#        bash run-state.sh status <ticket body file>
#        bash run-state.sh start <ticket body file> [--a3 <comment URL>] [--now <UTC>] [--step <text>]
# <field>: started | step | in-flight | freeze | hansei | closed | baseline | items | a3
#   Reads the `- <field>: <value>` line inside the body's `## Factory run` section (up to the next `## ` heading) and nowhere else. The body is
#   the run ticket's: the map's in the map route, the destination ticket's in the direct route; the section has the same shape in both.
#   `items` prints the item numbers of the `closed in this run` line (`#30 #29`), empty when it says none.
# moved: prints `#<n>` from a `Factory run: moved to #<n>` line (what an escalation leaves on the destination ticket), exit 3 when there is none.
# ticket: prints `#<n>` of the run ticket: the destination ticket in the direct route (no map exists), the map in the map route.
# status: prints `closed` when the section belongs to a run whose A3 is posted (it has an `- A3: <url>` line, or its step reads `9 (run closed`), else `open`.
# start: step 0 of a new run (#230). Prints the body with its Factory run section replaced by a new one: `started:` now (UTC, or --now), `step: 0` (or --step),
#   `in flight: none`, `FREEZE: none yet`, `closed in this run: none`, `previous run:` (the A3 link, or `A3 posted (link not recorded)`), `baseline: not yet`;
#   nothing else of the old section survives, the rest of the body is kept. It writes nothing to the tracker: the lead posts the body (`gh issue edit --body-file`).
#   It starts only a closed run's section: --a3 says the lead found the run's posted A3 (*Find A3*) and makes the section closed. A section of an
#   open run is not touched: exit 8, nothing on stdout.
# Exit: 0 printed; 1 the body has no Factory run section; 2 usage, an unknown field, or an unreadable file; 3 the section has no such line (or `moved`: no pointer);
#       4 the run moved to a map (the body says `Factory run: moved to #<n>`): read that ticket's body; 8 start: the section belongs to an open run.

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

if [ "$1" = status ] || [ "$1" = start ]; then
  cmd="$1"; body="${2:-}"; [ $# -ge 2 ] && shift 2 || shift; a3=""; now=""; step=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --a3) a3="${2:-}"; shift 2 || usage ;;
      --now) now="${2:-}"; shift 2 || usage ;;
      --step) step="${2:-}"; shift 2 || usage ;;
      *) usage ;;
    esac
  done
  [ -n "$body" ] && [ -f "$body" ] && [ -r "$body" ] || { echo "run-state: ${body:-no file}: unreadable" >&2; exit 2; }
  moved="$(tr -d '\r' <"$body" | sed -n 's/^Factory run: moved to \(#[0-9][0-9]*\)[[:space:]]*$/\1/p' | head -1)"
  if ! tr -d '\r' <"$body" | grep -q '^## Factory run[[:space:]]*$'; then
    [ -n "$moved" ] && { echo "run-state: the run moved to $moved: read the body of $moved" >&2; exit 4; }
    echo "run-state: $body has no Factory run section" >&2; exit 1
  fi
  sec="$(tr -d '\r' <"$body" | awk '/^## /{ on = ($0 ~ /^## Factory run[ \t]*$/); next } on { print }')"
  oldstep="$(printf '%s\n' "$sec" | sed -n 's/^- step:[[:space:]]*//p' | head -1)"
  olda3="$(printf '%s\n' "$sec" | sed -n 's/^- A3:[[:space:]]*//p' | head -1 | sed 's/[[:space:]]*$//')"
  closed=0
  { [ -n "$olda3" ] || [ -n "$a3" ]; } && closed=1
  case "$oldstep" in "9 (run closed"*) closed=1 ;; esac
  if [ "$cmd" = status ]; then [ "$closed" = 1 ] && echo closed || echo open; exit 0; fi
  if [ "$closed" != 1 ]; then
    echo "run-state: the Factory run section belongs to an open run (no A3 posted): nothing started; pass --a3 <comment URL> when its A3 is posted" >&2; exit 8
  fi
  [ -n "$now" ] || now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$now" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || { echo "run-state: --now must be YYYY-MM-DDTHH:MM:SSZ" >&2; exit 2; }
  prev="${a3:-$olda3}"; [ -n "$prev" ] || prev="A3 posted (link not recorded)"
  tr -d '\r' <"$body" | awk -v now="$now" -v step="$step" -v prev="$prev" '
    /^## / {
      if ($0 ~ /^## Factory run[ \t]*$/ && !done) {
        print "## Factory run"; print ""
        print "- started: " now; print "- step: " step; print "- in flight: none"; print "- FREEZE: none yet"
        print "- closed in this run: none"; print "- previous run: " prev; print "- baseline: not yet"; print ""
        skip = 1; done = 1; next
      }
      skip = 0
    }
    !skip { print }'
  exit 0
fi

field="$1"; body="${2:-}"
case "$field" in
  started | step | in-flight | freeze | hansei | closed | baseline | items | a3 | moved) ;;
  *) usage ;;
esac
[ -n "$body" ] && [ -f "$body" ] && [ -r "$body" ] || { echo "run-state: ${body:-no file}: unreadable" >&2; exit 2; }

moved="$(tr -d '\r' <"$body" | sed -n 's/^Factory run: moved to \(#[0-9][0-9]*\)[[:space:]]*$/\1/p' | head -1)"
if [ "$field" = moved ]; then [ -n "$moved" ] || exit 3; echo "$moved"; exit 0; fi
sec="$(tr -d '\r' <"$body" | awk '/^## /{ on = ($0 ~ /^## Factory run[ \t]*$/); if (on) found = 1; next } on { print } END { exit found ? 0 : 7 }')"
if ! { [ $? -eq 0 ] && [ -n "$(tr -d '\r' <"$body" | grep -m 1 '^## Factory run[[:space:]]*$')" ]; }; then
  [ -n "$moved" ] && { echo "run-state: the run moved to $moved: read the body of $moved" >&2; exit 4; }
  echo "run-state: $body has no Factory run section" >&2; exit 1
fi

key="$field"
case "$field" in a3) key="A3" ;; freeze) key="FREEZE" ;; items) key="closed in this run" ;; closed) key="closed in this run" ;; in-flight) key="in flight" ;; esac
line="$(printf '%s\n' "$sec" | grep -m 1 "^- $key:")"
[ -n "$line" ] || { echo "run-state: the Factory run section has no \`$key:\` line" >&2; exit 3; }
val="$(printf '%s\n' "$line" | sed "s/^- $key:[[:space:]]*//; s/[[:space:]]*\$//")"
if [ "$field" = items ]; then
  [ "$val" = none ] && exit 0
  printf '%s\n' "$val" | grep -oE '(^|, )#[0-9]+' | tr -d ', ' | tr '\n' ' ' | sed 's/ $//'; echo
  exit 0
fi
printf '%s\n' "$val"
