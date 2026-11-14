#!/usr/bin/env bash
# Checks the flow plan the lead writes on the destination ticket or the slice ticket (#187 decisions 2 and 16; #207 slice 4).
# Usage: bash plan-check.sh <plan file> [--table <factory.md>]      (default docs/agents/factory.md)
# The plan is `- <field>: <value>` lines, under a `## Plan` heading or not. Fields, all required:
#   route (direct | map), role path, test depth (both read `standard` until slice 5 makes them variable), triggers (`<row> (+<n>), ...` or `none`),
#   points, band, bands (the boundaries as they stood at sizing), reason, release, expected slices, first slice leaves out (a list, or `none`).
# It checks that the points are the sum of the triggers and the band is the one the plan's own `bands` line gives for them. It also
# reads each trigger from the project's flow table (through flow-size.sh, which refuses a name that is not a row) and checks that the points and the route are the table's.
# Output: the first failure as `missing: <field>` or `<field>: <what is wrong>` (exit 1); otherwise `plan ok` and, as they apply,
#   tell the person in the stage summary: the first slice leaves out: <list>     (decision 16: an approved ADR is never contradicted unseen)
#   ask the person before running: Heavy band                                     (the open-ended last band of the plan's bands line)
# Exit: 0 ok; 1 the plan is wrong; 2 usage, or the plan or the table file is unreadable.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plan="${1:-}"; shift 2>/dev/null
table="docs/agents/factory.md"
while [ $# -gt 0 ]; do
  case "$1" in --table) [ $# -ge 2 ] || { echo "usage: plan-check.sh <plan file> [--table <factory.md>]" >&2; exit 2; }; table="$2"; shift 2 ;; *) echo "usage: plan-check.sh <plan file> [--table <factory.md>]" >&2; exit 2 ;; esac
done
[ -n "$plan" ] && [ -r "$plan" ] || { echo "usage: plan-check.sh <plan file> [--table <factory.md>]" >&2; exit 2; }

get() { grep -m 1 "^- $1:" "$plan" | sed "s/^- $1:[[:space:]]*//" | tr -d '\r' | sed 's/[[:space:]]*$//'; }
fail() { echo "$1"; exit 1; }

for f in route "role path" "test depth" triggers points band bands reason release "expected slices" "first slice leaves out"; do
  [ -n "$(get "$f")" ] || fail "missing: $f"
done
route="$(get route)"
case "$route" in direct | map) ;; *) fail "route: \"$route\" is neither direct nor map" ;; esac
[ "$(get "role path")" = standard ] || fail "role path: reads \`standard\` until the role path is a dial (slice 5)"
[ "$(get "test depth")" = standard ] || fail "test depth: reads \`standard\` until test depth is a dial (slice 5)"

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

echo "plan ok"
leave="$(get "first slice leaves out")"
case "$leave" in none | None | "none.") ;; *) echo "tell the person in the stage summary: the first slice leaves out: $leave" ;; esac
last="$(printf '%s\n' "$bands" | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep ' or more' | tail -1 | cut -d' ' -f1)"
[ -n "$last" ] && [ "$band" = "$last" ] && echo "ask the person before running: $last band"
exit 0
