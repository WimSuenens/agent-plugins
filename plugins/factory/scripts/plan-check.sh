#!/usr/bin/env bash
# Checks the flow plan the lead writes on the destination ticket or the slice ticket (#187 decisions 2 and 16; #207 slice 4).
# Usage: bash plan-check.sh <plan file> [--table <factory.md>]      (default docs/agents/factory.md)
# The plan is `- <field>: <value>` lines, under a `## Plan` heading or not. Fields, all required:
#   route (direct | map), role path (the roles that run, comma separated, in the canonical order), test depth (proof-only | targeted | full), triggers (`<row> (+<n>), ...` or `none`),
#   points, band, bands (the boundaries as they stood at sizing), reason, release, expected slices, first slice leaves out (a list, or `none`).
#   An optional `artefact:` line (web-app | cli | library | instruction-markdown | docs) names the kind of proof the gate wants (proof-kind.sh).
# The role path and the test depth are checked against what flow-size.sh derives from the plan's triggers: the plan may hold more (scaling up, any time,
#   recorded in the plan) and never less (scaling down happens only at the next slice). The floor is checked on its own: developer, qa-engineer and
#   runtime-proof are never missing; a protected area keeps security-reviewer and a depth of at least targeted, whatever the table's Adds say.
# It checks that the points are the sum of the triggers and the band is the one the plan's own `bands` line gives for them. It also
# reads each trigger from the project's flow table (through flow-size.sh, which refuses a name that is not a row) and checks that the points and the route are the table's.
# Output: the first failure as `missing: <field>` or `<field>: <what is wrong>` (exit 1); otherwise `plan ok` and, as they apply,
#   tell the person in the stage summary: the first slice leaves out: <list>     (decision 16: an approved ADR is never contradicted unseen)
#   ask the person before running: Heavy band                                     (the open-ended last band of the plan's bands line)
# Release (#207 slice 6, decision 14): the plan records the release it was written under (`release: factory <version>`).
#   plan-check.sh release <plan file> <plugin root>   prints `same` or `release-crossed`: the plan's release against the `release:` line of fingerprint.sh for the plugin root.
#   plan-check.sh <plan file> --release <plugin root> a plan written under another release is not checked against the table (its rows, bands and role names may differ):
#       it prints `release-crossed`, then `plan written under factory <old>; running <new>`, and exits 0 once every field is present. The resume question follows (run-route.md).
#       A plan written under the running release is checked as before.
# Exit: 0 ok; 1 the plan is wrong; 2 usage, or the plan or the table file is unreadable (`release`: or the plugin root is not a factory plugin root).

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usage() { echo "usage: plan-check.sh <plan file> [--table <factory.md>] [--release <plugin root>] | plan-check.sh release <plan file> <plugin root>" >&2; exit 2; }
mode=check
if [ "${1:-}" = release ]; then mode=release; shift; fi
plan="${1:-}"; shift 2>/dev/null
table="docs/agents/factory.md"; relroot=""
if [ "$mode" = release ]; then
  relroot="${1:-}"; [ $# -eq 1 ] || usage
else
  while [ $# -gt 0 ]; do
    case "$1" in
      --table) [ $# -ge 2 ] || usage; table="$2"; shift 2 ;;
      --release) [ $# -ge 2 ] || usage; relroot="$2"; shift 2 ;;
      *) usage ;;
    esac
  done
fi
[ -n "$plan" ] && [ -r "$plan" ] || usage

get() { grep -m 1 "^- $1:" "$plan" | sed "s/^- $1:[[:space:]]*//" | tr -d '\r' | sed 's/[[:space:]]*$//'; }
fail() { echo "$1"; exit 1; }

# the release the plan was written under, and the one running (fingerprint.sh is the one reader of a plugin root's release)
plan_rel() { get release | sed 's/^factory[[:space:]]*//'; }
cur_rel=""
if [ -n "$relroot" ]; then
  cur_rel="$(bash "$here/fingerprint.sh" "$relroot" 2>/dev/null | sed -n 's/^release: //p')"
  [ -n "$cur_rel" ] || { echo "plan-check: $relroot: not a factory plugin root" >&2; exit 2; }
fi
if [ "$mode" = release ]; then
  [ -n "$(get release)" ] || fail "missing: release"
  if [ "$(plan_rel)" = "$cur_rel" ]; then echo same; else echo release-crossed; fi
  exit 0
fi

for f in route "role path" "test depth" triggers points band bands reason release "expected slices" "first slice leaves out"; do
  [ -n "$(get "$f")" ] || fail "missing: $f"
done
if [ -n "$relroot" ] && [ "$(plan_rel)" != "$cur_rel" ]; then
  echo "release-crossed"
  echo "plan written under factory $(plan_rel); running $cur_rel"
  exit 0
fi
route="$(get route)"
case "$route" in direct | map) ;; *) fail "route: \"$route\" is neither direct nor map" ;; esac

trig="$(get triggers)"
pts="$(get points)"; band="$(get band)"; bands="$(get bands)"
case "$pts" in '' | *[!0-9]*) fail "points: \"$pts\" is not a whole number" ;; esac

# the triggers: split `A (+3), B (+1)` into one row name per line (a row name may hold a comma)
names=""
if [ "$trig" != none ]; then
  names="$(printf '%s\n' "$trig" | sed -E 's/ \(\+[0-9]+\)(, |$)/\n/g' | sed '/^$/d')"
  sum="$(printf '%s\n' "$trig" | grep -o '(+[0-9]*)' | tr -d '(+)' | awk '{ s += $1 } END { print s + 0 }')"
else
  sum=0
fi
[ "$sum" = "$pts" ] || fail "points: plan says $pts, its triggers add up to $sum"

# the band from the plan's own bands line, and each trigger, the points and the route from the project's table
[ -r "$table" ] || { echo "plan-check: $table: unreadable (the plan is checked against the project's flow table)" >&2; exit 2; }
args=(--table "$table" --bands "$bands")
tl=()
if [ -n "$names" ]; then while IFS= read -r n; do tl+=("$n"); done <<NAMES
$names
NAMES
fi
got="$(bash "$here/flow-size.sh" "${args[@]}" ${tl[@]+"${tl[@]}"} 2>&1)"; rc=$?
[ "$rc" = 0 ] || fail "triggers: $(printf '%s\n' "$got" | head -1)"
gb="$(printf '%s\n' "$got" | sed -n 's/^band: //p')"
[ "$gb" = "$band" ] || fail "band: plan says $band, the bands line gives $gb"
if true; then
  gp="$(printf '%s\n' "$got" | sed -n 's/^points: //p')"
  [ "$gp" = "$pts" ] || fail "points: plan says $pts, the table gives $gp"
  gr="$(printf '%s\n' "$got" | sed -n 's/^route: //p')"
  [ "$gr" = "$route" ] || fail "route: plan says $route, the table gives $gr"
fi

# the role path, the test depth and the artefact against the sizing of the plan's triggers
canon="product-owner architect devops developer qa-engineer runtime-proof security-reviewer docs-writer"
dpath="$(printf '%s\n' "$got" | sed -n 's/^role path: //p')"
ddepth="$(printf '%s\n' "$got" | sed -n 's/^test depth: //p')"
pfloor=0; printf '%s\n' "$got" | grep -q '^floor: protected' && pfloor=1
ppath="$(get "role path")"; pdepth="$(get "test depth")"
case "$ppath" in *,*) ;; *) fail "role path: write the roles that run; the table gives: $dpath" ;; esac
plist="$(printf '%s' "$ppath" | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
last=0
while IFS= read -r r; do
  idx=0; k=0
  for c in $canon; do k=$((k + 1)); [ "$c" = "$r" ] && idx=$k; done
  [ "$idx" != 0 ] || fail "role path: \"$r\" is not a role (roles: $(printf '%s' "$canon" | tr ' ' ',' | sed 's/,/, /g'))"
  [ "$idx" -gt "$last" ] || fail "role path: \"$r\" is out of order or named twice (order: $(printf '%s' "$canon" | tr ' ' ',' | sed 's/,/, /g'))"
  last="$idx"
done <<PLIST
$plist
PLIST
hasrole() { printf '%s\n' "$plist" | grep -qx "$1"; }
for r in qa-engineer runtime-proof developer; do hasrole "$r" || fail "role path: missing $r, which the floor never drops"; done
if [ "$pfloor" = 1 ]; then hasrole security-reviewer || fail "role path: missing security-reviewer, which the floor keeps for a protected area"; fi
for r in $(printf '%s' "$dpath" | tr ',' ' '); do hasrole "$r" || fail "role path: missing $r, which the table's rows add (scaling down happens at the next slice)"; done
rank() { case "$1" in proof-only) echo 0 ;; targeted) echo 1 ;; full) echo 2 ;; *) echo -1 ;; esac; }
[ "$(rank "$pdepth")" -ge 0 ] || fail "test depth: \"$pdepth\" is not proof-only, targeted or full"
if [ "$(rank "$pdepth")" -lt "$(rank "$ddepth")" ]; then
  if [ "$pfloor" = 1 ]; then fail "test depth: $pdepth is below $ddepth, which the floor keeps for a protected area"; fi
  fail "test depth: $pdepth is below $ddepth, which the table's rows give"
fi
art="$(get artefact)"
case "$art" in "" | web-app | cli | library | instruction-markdown | docs) ;; *) fail "artefact: \"$art\" is not web-app, cli, library, instruction-markdown or docs" ;; esac

echo "plan ok"
leave="$(get "first slice leaves out")"
case "$leave" in none | None | "none.") ;; *) echo "tell the person in the stage summary: the first slice leaves out: $leave" ;; esac
last="$(printf '%s\n' "$bands" | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep ' or more' | tail -1 | cut -d' ' -f1)"
[ -n "$last" ] && [ "$band" = "$last" ] && echo "ask the person before running: $last band"
exit 0
