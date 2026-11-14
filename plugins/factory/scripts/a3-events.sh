#!/bin/bash
# a3-events.sh: the events lines of an A3 (v3), built from the run's records, so the A3 is not written from memory.
# The lead runs it at step 9 and pastes its output into the A3; the lead adds the cause of each event and nothing else.
# Usage:
#   a3-events.sh [--item <n> [--ledger <file>] [--hansei <file>] [--comments <file>]]... [--filed <file>]
#   One `--item` group per item of the run (the map's number may be a group of its own, with only `--comments`).
#   --ledger   the ledger comment of the item (its Tasks, Waits and Person's touches tables).
#   --hansei   the hansei record of the item (its `3. rework:` line).
#   --comments the item's other comments (stage summaries, resolution, needs-you cards), as one file.
#   --filed    the output of `intake.sh filed-since <run start> <run end> --state all` (one `<n><TAB><title><TAB><source>` per issue).
# Prints, in A3 order:
#   - events: <n>                              (or `none (no event in the records read)`)
#     event: <kind> #<item> <where> — cause: ?   one line per event; the lead replaces `?`; a3-check.sh refuses a `?` left in
#   - issues filed during the run: <k>: #<n> <title>; ...   (or `none (no issue carried the triage label or the marker)`)
#   - not detectable from records: <list>
# Kinds, and what each one is read from. A kind is detected only by the structure named here; the text of a note is never copied.
#   rework              a Tasks row whose Stage ends `(round <N>)`, N at least 2.
#   needs-decision      a Tasks row whose Result is `needs-decision`.
#   overturned          the hansei line `3. rework: ... overturned two-way decisions <N>`, N above 0.
#   refusal             a line of the item's comments that holds the word `refus` (a gate or a check refused something): KEYWORD match on free text.
#   withdrawn-skip      a line of the item's comments that holds `skip` and `withdrawn`: KEYWORD match on free text.
#   correction          an `Answered:` line of a needs-you card that holds `correction`: KEYWORD match on free text.
#   wait                every row of the ledger's Waits table: its id, kind and whole minutes.
#   person-stop         a Waits row or a touch whose text holds `stopped`: KEYWORD match on free text; one per item.
# What it cannot see, because no record holds it (printed as `not detectable from records`): a brief refused by the scan, why a
# rework round happened, a contradiction between two rules of a contract (only the rework round it caused shows), a defect in an input
# (only the `needs-decision` row of the role that found it), and any event no role or the lead wrote down. A keyword kind misses an
# event that is worded differently, and reports a line that only mentions the word; read each one before the cause is written.
# Exit: 0 done; 2 usage or an unreadable file. Needs awk only; reads the files it is given and nothing else.

usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

NOT_DETECTABLE="a brief refused by the scan; why a rework round happened; a contradiction between two contract rules (only the rework round it caused shows); the cause of a defect in an input; any event no role or the lead wrote down"

items=""; filed=""
cur=""; ledger=""; hansei=""; comments=""
flush() {
  [ -n "$cur" ] || return 0
  for f in "$ledger" "$hansei" "$comments"; do
    [ -z "$f" ] || { [ -r "$f" ] && [ -f "$f" ]; } || { echo "a3-events: cannot read $f" >&2; exit 2; }
  done
  items="$items$cur|$ledger|$hansei|$comments
"
}
while [ $# -gt 0 ]; do
  case "$1" in
    --item) flush; cur="${2:-}"; case "$cur" in '' | *[!0-9]*) usage ;; esac; ledger=""; hansei=""; comments=""; shift 2 ;;
    --ledger) [ -n "$cur" ] || usage; ledger="${2:?}"; shift 2 ;;
    --hansei) [ -n "$cur" ] || usage; hansei="${2:?}"; shift 2 ;;
    --comments) [ -n "$cur" ] || usage; comments="${2:?}"; shift 2 ;;
    --filed) filed="${2:?}"; shift 2 ;;
    *) usage ;;
  esac
done
flush
[ -z "$filed" ] || { [ -f "$filed" ] && [ -r "$filed" ]; } || { echo "a3-events: cannot read $filed" >&2; exit 2; }

detect() {
  printf '%s' "$items" | while IFS='|' read -r n led han com; do
  [ -n "$n" ] || continue
  if [ -n "$led" ]; then
    awk -v N="$n" '
      function mins(s,   y,mo,d,h,mi,yy,era,yoe,doy,doe) {
        if (s !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}/) return ""
        y=substr(s,1,4)+0; mo=substr(s,6,2)+0; d=substr(s,9,2)+0; h=substr(s,12,2)+0; mi=substr(s,15,2)+0
        yy=y-(mo<=2); era=int(yy/400); yoe=yy-era*400
        doy=int((153*(mo+(mo>2?-3:9))+2)/5)+d-1; doe=yoe*365+int(yoe/4)-int(yoe/100)+doy
        return (era*146097+doe-719468)*1440+h*60+mi
      }
      function trim(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
      { sub(/\r$/, "") }
      /^### Tasks/ { sec="t"; next }
      /^### Waits/ { sec="w"; next }
      /^### Person/ { sec="p"; next }
      /^### / { sec=""; next }
      sec=="t" && /^\| [0-9]+ \|/ {
        split($0, c, "|"); row=trim(c[2]); stage=trim(c[4]); role=trim(c[5]); res=trim(c[9])
        if (match(stage, /\(round [0-9]+\)$/)) {
          r=substr(stage, RSTART+7, RLENGTH-8)+0
          if (r >= 2) print "rework #" N " row " row " " stage " (" role ")"
        }
        if (res == "needs-decision") print "needs-decision #" N " row " row " (" role ")"
      }
      sec=="w" && /^\| W[0-9]+ \|/ {
        split($0, c, "|"); id=trim(c[2]); kind=trim(c[3]); a=mins(trim(c[5])); b=mins(trim(c[6])); what=trim(c[8])
        if (a != "" && b != "") print "wait #" N " " id " " kind " " (b - a) "m"
        else print "wait #" N " " id " " kind " (time not readable)"
        if (what ~ /stopped/ && !stop) { stop=1; print "person-stop #" N " " id }
      }
      sec=="p" && /^\| [0-9]{4}-/ {
        split($0, c, "|")
        if (trim(c[4]) ~ /stopped/ && !stop) { stop=1; print "person-stop #" N " touch " trim(c[2]) }
      }' "$led"
  fi
  if [ -n "$han" ]; then
    awk -v N="$n" '{ sub(/\r$/, "") } /^3\. rework:/ { if (match($0, /overturned two-way decisions [0-9]+/)) { k=substr($0, RSTART+29, RLENGTH-29)+0; if (k > 0) print "overturned #" N " " k " two-way decision" (k > 1 ? "s" : "") } }' "$han"
  fi
  if [ -n "$com" ]; then
    awk -v N="$n" '
      { sub(/\r$/, "") }
      { low=tolower($0) }
      low ~ /refus/ { print "refusal #" N " comment line " NR }
      low ~ /skip/ && low ~ /withdrawn/ && !wd { wd=1; print "withdrawn-skip #" N " comment line " NR }
      /^Answered:/ && low ~ /correction/ { print "correction #" N " comment line " NR }' "$com"
  fi
  done
}
events="$(detect)"

if [ -z "$events" ]; then
  echo "- events: none (no event in the records read)"
else
  printf -- '- events: %s\n' "$(printf '%s\n' "$events" | wc -l | tr -d ' ')"
  printf '%s\n' "$events" | sed 's/^/  event: /; s/$/ — cause: ?/'
fi
if [ -n "$filed" ] && [ -s "$filed" ]; then
  k="$(wc -l <"$filed" | tr -d ' ')"
  # a title is the lead's own paraphrase target: backtick, @ and angle brackets are neutralised (references/a3.md, section 1)
  list="$(sed "s/[\`@<>]/'/g" "$filed" | awk -F'\t' '{ t=$2; if (length(t) > 80) t=substr(t,1,80) "…"; printf "#%s %s; ", $1, t }' | sed 's/; $//')"
  printf -- '- issues filed during the run: %s: %s\n' "$k" "$list"
else
  echo "- issues filed during the run: none (no issue carried the triage label or the marker)"
fi
echo "- not detectable from records: $NOT_DETECTABLE"
