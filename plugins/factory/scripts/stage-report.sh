#!/usr/bin/env bash
# stage-report.sh: the fixed lines of the stage summary at each stage boundary (#230). The lead pastes the output unchanged; nothing is written from memory.
# Usage: bash stage-report.sh --run-body <run ticket body file> [--ledger <ledger file>]... [--since <UTC of the last boundary>]
#   --run-body  the body of the run ticket (the map's, or the destination ticket's in the direct route): its Factory run section gives the run start.
#   --ledger    the ledger comment of an item of the run, as a file; repeat for each item. Its Waits table gives the waits.
#   --since     the last boundary (`YYYY-MM-DDTHH:MM:SSZ`); the default is the run start.
# Prints, in this order:
#   new issues since <start>: ...               `intake.sh filed-since --run-body <body> --line`, as it prints it (provisional, see intake.sh)
#   direction: docs/direction.md created <UTC> (<sha>)   only when the commit that added docs/direction.md (on HEAD) is at or after --since
#   waits so far: <n> (<kind> <k>: <m> min; ...)   every row of the ledgers' Waits tables, by kind, in whole minutes; `0` with no rows;
#                                                 `none (no ledger given)` without --ledger
# Exit: 0 done; 2 usage, an unreadable file, or a Factory run section that is closed or has no `started:` line (intake.sh and run-state.sh say why);
#       4 the issue list could not be read (intake.sh).

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
body=""; since=""; leds=()
while [ $# -gt 0 ]; do
  case "$1" in
    --run-body) body="${2:-}"; shift 2 || usage ;;
    --ledger) [ -n "${2:-}" ] || usage; leds+=("$2"); shift 2 ;;
    --since) since="${2:-}"; shift 2 || usage ;;
    *) usage ;;
  esac
done
[ -n "$body" ] || usage
ts='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
[ -z "$since" ] || printf '%s' "$since" | grep -Eq "$ts" || { echo "stage-report: --since must be YYYY-MM-DDTHH:MM:SSZ" >&2; exit 2; }
for f in ${leds[@]+"${leds[@]}"}; do [ -f "$f" ] && [ -r "$f" ] || { echo "stage-report: $f: unreadable" >&2; exit 2; }; done

issues="$(bash "$here/intake.sh" filed-since --run-body "$body" --line)"; rc=$?
[ "$rc" = 0 ] || exit "$rc"
start="$(bash "$here/run-state.sh" started "$body")" || exit 2
[ -n "$since" ] || since="$start"
printf '%s\n' "$issues"

# docs/direction.md: the commit that added it, in UTC
top="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$top" ]; then
  row="$(TZ=UTC git -C "$top" log --diff-filter=A --date=format-local:%Y-%m-%dT%H:%M:%SZ --format='%cd %h' -- docs/direction.md 2>/dev/null | tail -1)"
  if [ -n "$row" ]; then
    when="${row%% *}"; sha="${row##* }"
    # fixed-width UTC stamps compare as text
    [ "$when" \< "$since" ] || printf 'direction: docs/direction.md created %s (%s)\n' "$when" "$sha"
  fi
fi

if [ "${#leds[@]}" = 0 ]; then echo "waits so far: none (no ledger given)"; exit 0; fi
cat "${leds[@]}" | tr -d '\r' | awk '
  function mins(s,   y,mo,d,h,mi,yy,era,yoe,doy,doe) {
    if (s !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}/) return ""
    y=substr(s,1,4)+0; mo=substr(s,6,2)+0; d=substr(s,9,2)+0; h=substr(s,12,2)+0; mi=substr(s,15,2)+0
    yy=y-(mo<=2); era=int(yy/400); yoe=yy-era*400
    doy=int((153*(mo+(mo>2?-3:9))+2)/5)+d-1; doe=yoe*365+int(yoe/4)-int(yoe/100)+doy
    return (era*146097+doe-719468)*1440+h*60+mi
  }
  function trim(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
  /^### Waits/ { sec = 1; next }
  /^### / { sec = 0; next }
  sec && /^\| W[0-9]+ \|/ {
    split($0, c, "|"); kind = trim(c[3]); a = mins(trim(c[5])); b = mins(trim(c[6]))
    n++; cnt[kind]++; if (!(kind in seen)) { seen[kind] = 1; order[++k] = kind }
    if (a != "" && b != "") m[kind] += b - a
  }
  END {
    if (!n) { print "waits so far: 0"; exit }
    out = ""
    for (i = 1; i <= k; i++) out = out (i > 1 ? "; " : "") order[i] " " cnt[order[i]] ": " (m[order[i]] + 0) " min"
    print "waits so far: " n " (" out ")"
  }'
