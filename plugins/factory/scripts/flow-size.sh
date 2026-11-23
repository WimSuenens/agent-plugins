#!/usr/bin/env bash
# Sizing: the points, the band, the steps and the route of a destination or a slice, from the project's own flow table (#207 slice 4).
# Usage: bash flow-size.sh [--table <factory.md>] [--bands "<bands line>"] [--paths <expected paths>] [<trigger>...]      (default docs/agents/factory.md)
# --paths is the list of paths the slice is expected to change, one per line (or one line of space-separated paths), contract files the
# architect stage will write included. The script fires the row `Protected area touched` itself when one of them is protected, judged by
# `protected-areas.sh` (the one definition; the project's `protected-paths:` line is read where the gate reads it, origin/main's docs/agents/factory.md, whatever --table says); naming that row as well counts once.
# The lead still names every other row. An empty or blank list is refused (exit 2); a table without the row is refused (exit 2).
# --bands uses the boundaries a plan recorded at sizing instead of the table's current line (plan-check.sh does this).
# The table is read through `factory-config.sh table`; no trigger, point or band is written in this script. Each <trigger> is a row name of the
# table, matched whole or as a unique prefix, ignoring case. The lead says which triggers fired; this script adds them up. No trigger is the lightest path.
# Output, one line each, in this order:
#   points: <sum>                      each fired row counts once
#   band: <name>                       from the table's `bands:` line, as it stands now
#   bands: <the bands line>            the lead records it in the plan, so a change of the boundaries applies to new slices only
#   route: direct | map                map when a fired row's Adds name a `map`, otherwise direct
#   role path: <role>, <role>, ...     the roles that run, in the canonical order (slice 5): developer, qa-engineer and runtime-proof always (the floor), plus a role
#                                      each fired row's Adds name (decision card -> product-owner; architect or ADR -> architect; devops; security review ->
#                                      security-reviewer; docs-writer). The row `$protrow` below adds security-reviewer and depth targeted whatever its Adds say
#   test depth: proof-only | targeted  the table's `test-depth:` line (targeted when it has none), raised to targeted by a fired row whose Adds say `targeted`.
#                                      `full` is never derived: it follows an escalation or an escaped defect, and the lead writes it into the plan
#   ui self-review: yes | no           yes when a fired row's Adds name a `demo` (the self-review comes before the demo, run-roles.md)
#   floor: protected              only when the protected-area row fired: its security review and depth targeted are the floor, not the table's words
#   triggers: none                     (only when nothing fired)
#   trigger: <row> +<points> -- <Adds> one line per fired row, in table order
#   protected: <area> <path>           with --paths only: one line per expected path that is protected (what fired the row)
#   person: <who is asked>             `Heavy band: ask before running` (the open-ended band), `one-way door: decision card` (a fired row whose
#                                      Adds say it stays with the person), both joined by `; ` when both hold, or `no question`
# Route and the question to the person are read from the Adds column of the table: a row that adds a map says `map` there (and a row that does
# not never uses the word), and a row that stays with the person says `stays with the person`.
# The sizing never chooses what the fence reserves: it only reports.
# Exit: 0 done; 2 usage, an empty --paths list, the table file is unreadable, or an unknown or ambiguous trigger (nothing on stdout); 6 no or an incomplete flow table.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="docs/agents/factory.md"
usage="usage: flow-size.sh [--table <factory.md>] [--bands <line>] [--paths <expected paths>] [<trigger>...]"
names=()
bandsover=""
paths=""; havepaths=0
while [ $# -gt 0 ]; do
  case "$1" in
    --table) [ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }; file="$2"; shift 2 ;;
    --bands) [ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }; bandsover="$2"; shift 2 ;;
    --paths) [ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }; paths="$2"; havepaths=1; shift 2 ;;
    *) names+=("$1"); shift ;;
  esac
done
if [ "$havepaths" = 1 ] && [ -z "$(printf '%s' "$paths" | tr -d '[:space:]')" ]; then
  echo "flow-size: --paths is empty: name the paths the slice is expected to change, or leave --paths out" >&2; exit 2
fi

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

# --paths: the protected paths fire "Protected area touched" (once, even when the lead names it too)
protlines=""; protrow="protected area touched"   # the one row the script derives; every other row is named by the lead
if [ "$havepaths" = 1 ]; then
  # shellcheck disable=SC1091
  . "$here/protected-areas.sh"
  protected_paths_line   # once, here: the calls below run in subshells and would lose the cache
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    a="$(protected_path_area "$p")" && protlines="$protlines"$'\n'"protected: $a $p"
  done <<PATHS
$(protected_list_paths "$paths")
PATHS
  if [ -n "$protlines" ]; then
    hit=""; i=0
    while IFS=$'\037' read -r n _ _; do
      i=$((i + 1)); [ "$(lc "$n")" = "$protrow" ] && hit="$i"
    done <<ROWS
$rows
ROWS
    [ -n "$hit" ] || { echo "flow-size: $file has no \`$protrow\` row: the paths cannot be sized" >&2; exit 2; }
    case " $fired " in *" $hit "*) ;; *) fired="$fired $hit" ;; esac
  fi
fi

# the floor row: fired by name or by --paths, it keeps security review and depth targeted even when the project's Adds no longer say so
phit=""; i=0
while IFS=$'\037' read -r n _ _; do
  i=$((i + 1)); [ "$(lc "$n")" = "$protrow" ] && phit="$i"
done <<ROWS
$rows
ROWS
protfired=0
[ -n "$phit" ] && case " $fired " in *" $phit "*) protfired=1 ;; esac
sdepth="$(printf '%s\n' "$table" | sed -n 's/^test-depth:[[:space:]]*//p' | head -1 | tr -d '\r' | awk '{ print $1 }')"
case "$sdepth" in proof-only | targeted | full) ;; *) sdepth=targeted ;; esac   # no starting depth: the safer one
depth="$sdepth"; selfreview=no; roles=" developer qa-engineer runtime-proof "
[ "$protfired" = 1 ] && { roles="$roles security-reviewer "; [ "$depth" = proof-only ] && depth=targeted; }

points=0; route=direct; person="no question"; lines=""; i=0
while IFS=$'\037' read -r n p a; do
  i=$((i + 1))
  case " $fired " in *" $i "*) ;; *) continue ;; esac
  printf '%s' "$a" | grep -qiE 'decision card|product.owner|requirement' && roles="$roles product-owner "
  printf '%s' "$a" | grep -qiE 'architect|(^|[^A-Za-z])ADR([^A-Za-z]|$)' && roles="$roles architect "
  printf '%s' "$a" | grep -qiE 'devops' && roles="$roles devops "
  printf '%s' "$a" | grep -qiE 'security review' && roles="$roles security-reviewer "
  printf '%s' "$a" | grep -qiE 'docs-writer|documentation' && roles="$roles docs-writer "
  printf '%s' "$a" | grep -qiE 'targeted' && [ "$depth" = proof-only ] && depth=targeted
  printf '%s' "$a" | grep -qiE '(^|[^a-z])demo([^a-z]|$)' && selfreview=yes
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
        if [ "$hi" = 999999 ]; then
          if [ "$person" = "no question" ]; then person="Heavy band: ask before running"; else person="Heavy band: ask before running; $person"; fi
        fi
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
rp=""
for r in product-owner architect devops developer qa-engineer runtime-proof security-reviewer docs-writer; do
  case "$roles" in *" $r "*) rp="${rp:+$rp, }$r" ;; esac
done
echo "role path: $rp"
echo "test depth: $depth"
echo "ui self-review: $selfreview"
[ "$protfired" = 1 ] && echo "floor: protected"
if [ -z "$lines" ]; then echo "triggers: none"; else printf '%s\n' "${lines#$'\n'}"; fi
[ -z "$protlines" ] || printf '%s\n' "${protlines#$'\n'}"
echo "person: $person"
