#!/usr/bin/env bash
# Sizing: the points, the band, the steps and the route of a destination or a slice, from the project's own flow table (#207 slice 4).
# Usage: bash flow-size.sh [--table <factory.md>] [--bands "<bands line>"] [<trigger>...]      (default docs/agents/factory.md)
# --bands uses the boundaries a plan recorded at sizing instead of the table's current line (plan-check.sh does this).
# The table is read through `factory-config.sh table`; no trigger, point or band is written in this script. Each <trigger> is a row name of the
# table, matched whole or as a unique prefix, ignoring case. The lead says which triggers fired; this script adds them up. No trigger is the lightest path.
# Output, one line each, in this order:
#   points: <sum>                      each fired row counts once
#   band: <name>                       from the table's `bands:` line, as it stands now
#   bands: <the bands line>            the lead records it in the plan, so a change of the boundaries applies to new slices only
#   route: direct | map                map when a fired row's Adds name a `map`, otherwise direct
#   triggers: none                     (only when nothing fired)
#   trigger: <row> +<points> -- <Adds> one line per fired row, in table order
#   person: <who is asked>             `Heavy band: ask before running` (the open-ended band), `one-way door: decision card` (a fired row whose
#                                      Adds say it stays with the person), or `no question`
# The sizing never chooses what the fence reserves: it only reports.
# Exit: 0 done; 2 usage, the table file is unreadable, or an unknown or ambiguous trigger (nothing on stdout); 6 no or an incomplete flow table.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="docs/agents/factory.md"
names=()
bandsover=""
while [ $# -gt 0 ]; do
  case "$1" in
    --table) [ $# -ge 2 ] || { echo "usage: flow-size.sh [--table <factory.md>] [--bands <line>] [<trigger>...]" >&2; exit 2; }; file="$2"; shift 2 ;;
    --bands) [ $# -ge 2 ] || { echo "usage: flow-size.sh [--table <factory.md>] [--bands <line>] [<trigger>...]" >&2; exit 2; }; bandsover="$2"; shift 2 ;;
    *) names+=("$1"); shift ;;
  esac
done

table="$(bash "$here/factory-config.sh" table "$file")"; rc=$?
if [ "$rc" != 0 ]; then
  [ "$rc" = 2 ] && echo "flow-size: $file: unreadable" >&2
  [ "$rc" = 6 ] && echo "flow-size: $file has no complete flow table: run setup-factory-skill" >&2
  exit "$rc"
fi

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# rows: one per trigger row, in table order: name <US> points <US> adds
rows="$(printf '%s\n' "$table" | grep -E '^\| [^|]+\|[^|]*\|' | grep -vE '^\| Trigger[[:space:]]*\|' | grep -vE '^\|[-| ]+\|?$' |
  awk -F'|' '{ n=$2; p=$3; a=$4; gsub(/^[ \t]+|[ \t]+$/, "", n); gsub(/^[ \t]+|[ \t]+$/, "", p); gsub(/^[ \t]+|[ \t]+$/, "", a); printf "%s\037%s\037%s\n", n, p, a }')"
bandsline="$(printf '%s\n' "$table" | sed -n 's/^bands:[[:space:]]*//p' | head -1 | tr -d '\r')"
[ -n "$bandsover" ] && bandsline="$bandsover"

fired=""   # space-separated row numbers
for want in ${names[@]+"${names[@]}"}; do
  w="$(lc "$(trim "$want")")"
  exact=""; pre=""; npre=0; i=0
  while IFS=$'\037' read -r n _ _; do
    i=$((i + 1))
    ln="$(lc "$n")"
    [ "$ln" = "$w" ] && exact="$i"
    case "$ln" in "$w"*) pre="$i"; npre=$((npre + 1)) ;; esac
  done <<ROWS
$rows
ROWS
  if [ -n "$exact" ]; then hit="$exact"
  elif [ "$npre" = 1 ]; then hit="$pre"
  else
    if [ "$npre" -gt 1 ]; then echo "flow-size: ambiguous trigger \"$want\" (matches $npre rows)" >&2; else echo "flow-size: unknown trigger \"$want\"" >&2; fi
    exit 2
  fi
  case " $fired " in *" $hit "*) ;; *) fired="$fired $hit" ;; esac
done

points=0; route=direct; person="no question"; lines=""; i=0
while IFS=$'\037' read -r n p a; do
  i=$((i + 1))
  case " $fired " in *" $i "*) ;; *) continue ;; esac
  case "$p" in '' | *[!0-9]*) echo "flow-size: row \"$n\": points \"$p\" is not a whole number" >&2; exit 2 ;; esac
  points=$((points + p))
  lines="$lines"$'\n'"trigger: $n +$p -- $a"
  printf '%s' "$a" | grep -qiE '(^|[^a-z])map([^a-z]|$)' && route=map
  printf '%s' "$a" | grep -qi 'stays with the person' && person="one-way door: decision card"
done <<ROWS
$rows
ROWS

# the band: `<Name> <low> to <high>` or `<Name> <low> or more`, separated by commas
band=""
oldifs="$IFS"
IFS=','
for b in $bandsline; do
  IFS="$oldifs"
  b="$(trim "$b")"
  if [ -n "$b" ]; then
    bn="${b%% *}"; rest="${b#* }"; lo="${rest%% *}"; hi=""
    case "$rest" in
      *" or more"*) hi=999999 ;;
      *" to "*) hi="${rest##* to }"; hi="${hi%% *}" ;;
    esac
    case "$lo$hi" in '' | *[!0-9]*) ;; *)
      if [ -z "$band" ] && [ "$points" -ge "$lo" ] && [ "$points" -le "$hi" ]; then
        band="$bn"
        [ "$hi" = 999999 ] && person="Heavy band: ask before running"
      fi ;;
    esac
  fi
  IFS=','
done
IFS="$oldifs"
[ -n "$band" ] || { echo "flow-size: the bands line \"$bandsline\" has no band for $points points" >&2; exit 2; }

echo "points: $points"
echo "band: $band"
echo "bands: $bandsline"
echo "route: $route"
if [ -z "$lines" ]; then echo "triggers: none"; else printf '%s\n' "${lines#$'\n'}"; fi
echo "person: $person"
