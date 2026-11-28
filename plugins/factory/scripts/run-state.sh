#!/usr/bin/env bash
# The one reader of the Factory run section, and the rule for which ticket holds it (#187 decision 9; #207 slice 4).
# Usage: bash run-state.sh <field> <ticket body file>
#        bash run-state.sh moved <ticket body file>
#        bash run-state.sh ticket --route direct|map --destination <n> [--map <n>]
#        bash run-state.sh status <ticket body file>
#        bash run-state.sh start <ticket body file> [--a3 <comment URL>] [--now <UTC>] [--step <text>]
#        bash run-state.sh add-session <ticket body file> <session id>
#        bash run-state.sh add-run-wait <ticket body file> --kind <person|limits|stalled|interrupted> --start <UTC> --end <UTC> --what <text>
# <field>: started | step | in-flight | freeze | lead-sessions | hansei | closed | baseline | items | a3
#   Reads the `- <field>: <value>` line inside the body's `## Factory run` section (up to the next `## ` heading) and nowhere else. The body is
#   the run ticket's: the map's in the map route, the destination ticket's in the direct route; the section has the same shape in both.
#   `items` prints the item numbers of the `closed in this run` line (`#30 #29`), empty when it says none.
#   `lead-sessions` prints the value as is (`none yet`, or the ids with their `, `); an id not ^[A-Za-z0-9-]{1,64}$ is exit 2 (security-286 L2).
# moved: prints `#<n>` from a `Factory run: moved to #<n>` line (what an escalation leaves on the destination ticket), exit 3 when there is none.
# ticket: prints `#<n>` of the run ticket: the destination ticket in the direct route (no map exists), the map in the map route.
# status: prints `closed` when the section belongs to a run whose A3 is posted (it has an `- A3: https://...` line, or its step reads `9 (run closed`), else `open`.
#   An `A3:` value that is not a link (the template's placeholder, `pending`, `none`) does not close a run; --a3 must be a link (exit 2 otherwise).
# start: step 0 of a new run (#230). Prints the body with its Factory run section replaced by a new one: `started:` now (UTC, or --now), `step: 0` (or --step),
#   `in flight: none`, `FREEZE: none yet`, `lead sessions: none yet`, `closed in this run: none`, `previous run:` (the A3 link, or
#   `A3 posted (link not recorded)`), `baseline: not yet`, then an empty `### Run waits` table (#286);
#   nothing else of the old section survives, the rest of the body is kept. It writes nothing to the tracker: the lead posts the body (`gh issue edit --body-file`).
#   It starts only a closed run's section: --a3 says the lead found the run's posted A3 (*Find A3*) and makes the section closed. A section of an
#   open run is not touched: exit 8, nothing on stdout.
# add-session: prints the body with <session id> (^[A-Za-z0-9-]{1,64}$) on the section's `- lead sessions:` line (#286): `none yet` is replaced,
#   another id is appended after `, `, a known id changes nothing. A section without the line gets it after `- FREEZE:`, else after `- started:`.
# add-run-wait: prints the body with one row `| R<n> | <kind> | lead | <start> | <end> | <what> |` appended to the section's `### Run waits` table
#   (#286; references/hansei.md section 8). Times are YYYY-MM-DDTHH:MMZ or YYYY-MM-DDTHH:MM:SSZ, written cut to the minute; n is the largest R
#   number plus 1. A row with the same kind, start and end is not added again (the body is printed unchanged). --what: no `|`, no newline, not empty.
#   Neither writes to the tracker: the lead scans the printed body and posts it (`gh issue edit --body-file`). Neither reads docs/agents/factory.md.
# Exit: 0 printed; 1 the body has no Factory run section; 2 usage, an unknown field, or an unreadable file (lead-sessions: an id not in its format;
#       add-session: a bad id; add-run-wait: a kind not in the four, a time not in the format, end before start, a bad --what); 3 the section has no such line (or `moved`: no pointer; add-session:
#       neither `FREEZE:` nor `started:`; add-run-wait: no `### Run waits` table with the exact header);
#       4 the run moved to a map (the body says `Factory run: moved to #<n>`): read that ticket's body; 8 start: the section belongs to an open run;
#       add-session, add-run-wait: the section belongs to a closed run. On a non-zero exit nothing is printed on stdout.

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

if [ "$1" = add-session ] || [ "$1" = add-run-wait ]; then
  cmd="$1"; shift; body="${1:-}"; [ $# -ge 1 ] && shift
  sid=""; kind=""; ws=""; we=""; what=""; hw=0
  if [ "$cmd" = add-session ]; then
    [ $# -eq 1 ] || usage
    sid="$1"
    case "$sid" in '' | *[!A-Za-z0-9-]*) echo "run-state: the session id must match ^[A-Za-z0-9-]{1,64}\$" >&2; exit 2 ;; esac
    [ ${#sid} -le 64 ] || { echo "run-state: the session id must match ^[A-Za-z0-9-]{1,64}\$" >&2; exit 2; }
  else
    while [ $# -gt 0 ]; do
      case "$1" in
        --kind) [ $# -ge 2 ] || usage; kind="$2"; shift 2 ;;
        --start) [ $# -ge 2 ] || usage; ws="$2"; shift 2 ;;
        --end) [ $# -ge 2 ] || usage; we="$2"; shift 2 ;;
        --what) [ $# -ge 2 ] || usage; what="$2"; hw=1; shift 2 ;;
        *) usage ;;
      esac
    done
    case "$kind" in person | limits | stalled | interrupted) ;; *) echo "run-state: --kind must be person, limits, stalled or interrupted" >&2; exit 2 ;; esac
    for t in "$ws" "$we"; do
      case "$t" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]Z | [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) ;;
        *) echo "run-state: --start and --end must be YYYY-MM-DDTHH:MMZ or YYYY-MM-DDTHH:MM:SSZ" >&2; exit 2 ;;
      esac
    done
    ws="$(printf '%s' "$ws" | cut -c1-16)Z"; we="$(printf '%s' "$we" | cut -c1-16)Z"
    [ "$ws" = "$we" ] || [ "$(printf '%s\n%s\n' "$ws" "$we" | LC_ALL=C sort | head -1)" = "$ws" ] || { echo "run-state: --end is before --start" >&2; exit 2; }
    nl='
'
    [ "$hw" = 1 ] && [ -n "$what" ] || { echo "run-state: --what must name the wait" >&2; exit 2; }
    case "$what" in *'|'* | *"$nl"*) echo "run-state: --what must hold no | and no newline" >&2; exit 2 ;; esac
  fi
  [ -n "$body" ] && [ -f "$body" ] && [ -r "$body" ] || { echo "run-state: ${body:-no file}: unreadable" >&2; exit 2; }
  moved="$(tr -d '\r' <"$body" | sed -n 's/^Factory run: moved to \(#[0-9][0-9]*\)[[:space:]]*$/\1/p' | head -1)"
  if ! tr -d '\r' <"$body" | grep -q '^## Factory run[[:space:]]*$'; then
    [ -n "$moved" ] && { echo "run-state: the run moved to $moved: read the body of $moved" >&2; exit 4; }
    echo "run-state: $body has no Factory run section" >&2; exit 1
  fi
  sec="$(tr -d '\r' <"$body" | awk '/^## /{ on = ($0 ~ /^## Factory run[ \t]*$/) && !d; if (on) d = 1; next } on { print }')"
  oldstep="$(printf '%s\n' "$sec" | sed -n 's/^- step:[[:space:]]*//p' | head -1)"
  olda3="$(printf '%s\n' "$sec" | sed -n 's/^- A3:[[:space:]]*//p' | head -1)"
  case "$olda3" in http://* | https://*) echo "run-state: the Factory run section belongs to a closed run (its A3 is posted): nothing written" >&2; exit 8 ;; esac
  case "$oldstep" in "9 (run closed"*) echo "run-state: the Factory run section belongs to a closed run: nothing written" >&2; exit 8 ;; esac
  if [ "$cmd" = add-session ]; then
    printf '%s\n' "$sec" | grep -q '^- FREEZE:\|^- started:' || { echo "run-state: the Factory run section has neither FREEZE: nor started:" >&2; exit 3; }
    cur="$(printf '%s\n' "$sec" | grep -m 1 '^- lead sessions:')"
    mode=replace; val="$(printf '%s\n' "$cur" | sed 's/^- lead sessions:[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -z "$cur" ]; then
      mode=started; printf '%s\n' "$sec" | grep -q '^- FREEZE:' && mode=freeze; new="$sid"
    elif [ "$val" = "none yet" ] || [ -z "$val" ]; then new="$sid"
    else
      case ", $val, " in *", $sid, "*) mode=keep ;; esac
      new="$val, $sid"
    fi
    tr -d '\r' <"$body" | awk -v mode="$mode" -v line="- lead sessions: $new" '
      /^## / { on = ($0 ~ /^## Factory run[ \t]*$/) && !d; if (on) d = 1; print; next }
      on && !w && mode == "replace" && /^- lead sessions:/ { print line; w = 1; next }
      { print }
      on && !w && mode == "freeze" && /^- FREEZE:/ { print line; w = 1 }
      on && !w && mode == "started" && /^- started:/ { print line; w = 1 }'
    exit 0
  fi
  out="$(tr -d '\r' <"$body" | RS_WHAT="$what" awk -v kind="$kind" -v ws="$ws" -v we="$we" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    BEGIN { what = ENVIRON["RS_WHAT"] }
    { L[NR] = $0 }
    /^## / { on = ($0 ~ /^## Factory run[ \t]*$/) && !d; if (on) d = 1; sub_ = 0; intab = 0; next }
    !on { next }
    /^### / { sub_ = ($0 ~ /^### Run waits[ \t]*$/); intab = 0; next }
    sub_ && !found && $0 ~ /^\| # \| Kind \| Agent \| Start \| End \| What \|[ \t]*$/ { found = 1; intab = 1; last = NR; next }
    intab && /^\|/ {
      last = NR; n = split($0, c, "|"); id = trim(c[2])
      if (id ~ /^R[0-9]+$/) { r = substr(id, 2) + 0; if (r > max) max = r }
      if (trim(c[3]) == kind && trim(c[5]) == ws && trim(c[6]) == we) dup = 1
      next
    }
    intab { intab = 0 }
    END {
      if (!found) exit 3
      for (i = 1; i <= NR; i++) {
        print L[i]
        if (i == last && !dup) print "| R" (max + 1) " | " kind " | lead | " ws " | " we " | " what " |"
      }
    }')"
  rc=$?
  [ $rc = 3 ] && { echo "run-state: the Factory run section has no ### Run waits table with the header | # | Kind | Agent | Start | End | What |" >&2; exit 3; }
  [ $rc = 0 ] || exit 2
  printf '%s\n' "$out"
  exit 0
fi

if [ "$1" = status ] || [ "$1" = start ]; then
  cmd="$1"; body="${2:-}"; [ $# -ge 2 ] && shift 2 || shift; a3=""; now=""; step=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --a3) [ -n "${2:-}" ] || usage; a3="$2"; shift 2 ;;
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
  case "$a3" in '' | http://* | https://*) ;; *) echo "run-state: --a3 must be the link of the posted A3" >&2; exit 2 ;; esac
  case "$olda3" in http://* | https://*) ;; *) olda3="" ;; esac
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
        print "- started: " now; print "- step: " step; print "- in flight: none"; print "- FREEZE: none yet"; print "- lead sessions: none yet"
        print "- closed in this run: none"; print "- previous run: " prev; print "- baseline: not yet"; print ""
        print "### Run waits"; print ""; print "| # | Kind | Agent | Start | End | What |"; print "|---|---|---|---|---|---|"; print ""
        skip = 1; done = 1; next
      }
      skip = 0
    }
    !skip { print }'
  exit 0
fi

field="$1"; body="${2:-}"
case "$field" in
  started | step | in-flight | freeze | lead-sessions | hansei | closed | baseline | items | a3 | moved) ;;
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
case "$field" in a3) key="A3" ;; freeze) key="FREEZE" ;; lead-sessions) key="lead sessions" ;; items) key="closed in this run" ;; closed) key="closed in this run" ;; in-flight) key="in flight" ;; esac
line="$(printf '%s\n' "$sec" | grep -m 1 "^- $key:")"
[ -n "$line" ] || { echo "run-state: the Factory run section has no \`$key:\` line" >&2; exit 3; }
val="$(printf '%s\n' "$line" | sed "s/^- $key:[[:space:]]*//; s/[[:space:]]*\$//")"
if [ "$field" = lead-sessions ] && [ "$val" != "none yet" ]; then
  # the bad id is named by its place, never echoed: the value may hold shell syntax or a path
  pos="$(printf '%s\n' "$val" | awk -F', ' '{ for (i = 1; i <= NF; i++) if ($i !~ /^[A-Za-z0-9-]+$/ || length($i) > 64) { print i " of " NF; exit } }')"
  [ -z "$pos" ] || { echo "run-state: lead sessions: id $pos not in its format (^[A-Za-z0-9-]{1,64}\$)" >&2; exit 2; }
fi
if [ "$field" = items ]; then
  [ "$val" = none ] && exit 0
  printf '%s\n' "$val" | grep -oE '(^|, )#[0-9]+' | tr -d ', ' | tr '\n' ' ' | sed 's/ $//'; echo
  exit 0
fi
printf '%s\n' "$val"
