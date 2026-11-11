#!/usr/bin/env bash
# The integrator's dispatch plan, computed from a snapshot of the board. It keeps no state: the same snapshot gives the same plan.
# Usage: bash integrator.sh plan <board.json>
# The snapshot is JSON: {"now": "<UTC ISO time>", "slices": [<slice>, ...]}, the slices in the priority order of the lead and the person.
# A slice: {"id", "status" (Backlog, Ready, Running, Waiting on you, Blocked, Done), "contracts": [<contract file>, ...],
#           "depends_on": [<id>, ...], "kind" (feature or maintenance: both rank by their place in the list), "one_way_door": true (never started), "pr", "merge_ready": true, "created", "ready_since", "closed" (UTC ISO times)}. Every field but id and status may be left out.
# Output lines, in this order:
#   merge <id> -- PR <pr> approved; merges before any start          (slices with merge_ready, in priority order)
#   order: <id> ...                                                    (the Ready slices, dependencies first, else priority order)
#   advise: <id> before <id> -- <id> depends on <id>                   (only when a dependency changes the order)
#   start <id> -- <reason> | pause <id> -- <reason>                    (one per Ready slice, in the order above)
#   measure waiting <id> <XhYm|not captured>                           (each Ready slice: now minus ready_since)
#   measure lead-time <id> <XhYm|not captured>                         (each Done slice: closed minus created)
#   measure batch-size <n>                                             (slices the plan starts together)
#   measure in-flight <n>                                              (Running, Waiting on you and Blocked slices)
#   measure skipped <n> roles in <n> slices                            (roles the lead skipped; slice field "skipped": [<role>, ...])
#   measure rework skipped|full <mean rounds>|not captured            (Done slices, with and without skips; slice field "rework_rounds")
# A slice in flight or merge-ready holds its paths until it is merged. Overlap is decided by paths.sh overlap.
# Exit: 0 plan printed; 2 usage, jq missing, unreadable or malformed snapshot.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "${1:-}" = plan ] && [ $# -eq 2 ] || { echo "usage: integrator.sh plan <board.json>" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "integrator: jq missing" >&2; exit 2; }
[ -r "$2" ] || { echo "integrator: $2: unreadable" >&2; exit 2; }
jq -e '(.slices | type) == "array" and all(.slices[]; (.id != null) and ((.id | tostring | length) > 0) and ((.status | type) == "string"))' "$2" >/dev/null 2>&1 ||
  { echo "integrator: $2: not a board snapshot" >&2; exit 2; }

# one row per slice, fields separated by the unit separator (not tab: empty tab fields would collapse): id, status, pr, merge_ready, depends (space-joined), contracts (space-joined), created, ready_since, closed, one_way_door
rows="$(jq -r '.slices[] | [(.id|tostring), .status, ((.pr // "")|tostring), ((.merge_ready // false)|tostring),
  ((.depends_on // []) | map(tostring) | join(" ")), ((.contracts // []) | join(" ")), (.created // ""), (.ready_since // ""), (.closed // ""), ((.one_way_door // false)|tostring)] | join("\u001f")' "$2")"
now="$(jq -r '.now // ""' "$2")"

secs() { [ -n "$1" ] && jq -n -r --arg t "$1" '$t | fromdateiso8601' 2>/dev/null; }
hm() { local s="$1"; [ "$s" -ge 0 ] 2>/dev/null || { echo "not captured"; return; }; echo "$((s / 3600))h$(((s % 3600) / 60))m"; }

# lookups by id through plain scans of the rows (bash 3.2: no associative arrays)
field() { printf '%s\n' "$rows" | awk -F'\037' -v id="$1" -v n="$2" '$1 == id { print $n; exit }'; }
exists() { printf '%s\n' "$rows" | awk -F'\037' -v id="$1" '$1 == id { f = 1 } END { exit f ? 0 : 1 }'; }

holders=""   # one line per slice that holds paths: id, then its contract files, unit-separator separated
add_holder() { holders="${holders}$1"$'\037'"$2"$'\n'; }
inflight=0

# merges first; they and the slices in flight hold their paths
while IFS=$'\037' read -r id st pr mr dep ctr cr rs cl dr; do
  [ -n "$id" ] || continue
  case "$st" in Running | "Waiting on you" | Blocked) inflight=$((inflight + 1)) ;; esac
  if [ "$mr" = true ]; then
    echo "merge $id -- PR ${pr:-?} approved; merges before any start"
    add_holder "$id" "$ctr"
  else
    case "$st" in Running | "Waiting on you" | Blocked) add_holder "$id" "$ctr" ;; esac
  fi
done <<EOF
$rows
EOF

# the Ready slices in priority order, then dependencies first
ready=""
while IFS=$'\037' read -r id st pr mr dep ctr cr rs cl dr; do
  [ -n "$id" ] && [ "$st" = Ready ] && [ "$mr" != true ] && ready="$ready $id"
done <<EOF
$rows
EOF
ordered=""; remaining="$ready"; guard=0
while [ -n "$remaining" ] && [ $guard -lt 10000 ]; do
  guard=$((guard + 1)); pick=""
  for id in $remaining; do
    blocked=0
    for d in $(field "$id" 5); do
      case " $remaining " in *" $d "*) [ "$d" != "$id" ] && blocked=1 ;; esac
    done
    [ $blocked = 0 ] && { pick="$id"; break; }
  done
  # a dependency cycle: keep the priority order for the rest
  [ -n "$pick" ] || { set -- $remaining; pick="$1"; }
  ordered="$ordered $pick"
  rest=""; for r in $remaining; do [ "$r" = "$pick" ] || rest="$rest $r"; done
  remaining="$rest"
done
echo "order:$ordered"

# advise: a Ready slice whose dependency comes after it in the priority order (the order the plan prints differs)
for id in $ready; do
  later=""; found=0
  for r in $ready; do
    [ $found = 1 ] && later="$later $r"
    [ "$r" = "$id" ] && found=1
  done
  for d in $(field "$id" 5); do
    case " $later " in *" $d "*) echo "advise: $d before $id -- $id depends on $d" ;; esac
  done
done

# start or pause, in that order. A pause gives every reason that holds: a dependency and an overlap can both.
started=0
for id in $ordered; do
  reasons=""
  for d in $(field "$id" 5); do
    if ! exists "$d"; then reasons="${reasons:+$reasons; }waits for $d (dependency not on the board)"; break
    elif [ "$(field "$d" 2)" != Done ]; then reasons="${reasons:+$reasons; }waits for $d (dependency not done)"; break; fi
  done
  [ "$(field "$id" 10)" = true ] && reasons="${reasons:+$reasons; }one-way door: waits for the person's decision card, not executed"
  mine="$(field "$id" 6)"; ok=1
  for f in $mine; do [ -r "$f" ] || ok=0; done
  if [ -z "$mine" ] || [ $ok = 0 ]; then
    reasons="${reasons:+$reasons; }no path list yet (the architect stage is not done)"
  else
    while IFS=$'\037' read -r hid hctr; do
      [ -n "$hid" ] && [ -n "$hctr" ] || continue
      hok=1; for f in $hctr; do [ -r "$f" ] || hok=0; done
      if [ $hok = 0 ]; then
        # an unreadable path list cannot be compared: pause rather than risk an overlap
        reasons="${reasons:+$reasons; }overlaps $hid (its path list is unreadable)"; continue
      fi
      # shellcheck disable=SC2086
      o="$(bash "$here/paths.sh" overlap $mine -- $hctr 2>/dev/null)"
      case "$o" in
        "overlap: yes shared "*) reasons="${reasons:+$reasons; }overlaps $hid on ${o#overlap: yes shared }" ;;
        "overlap: yes "*) reasons="${reasons:+$reasons; }overlaps $hid on ${o#overlap: yes }" ;;
      esac
    done <<HOLDERS
$holders
HOLDERS
  fi
  if [ -n "$reasons" ]; then
    echo "pause $id -- $reasons"
  else
    echo "start $id -- no overlap with a slice in flight or an earlier start"
    add_holder "$id" "$mine"
    started=$((started + 1))
  fi
done

# measures
while IFS=$'\037' read -r id st pr mr dep ctr cr rs cl dr; do
  [ -n "$id" ] && [ "$st" = Ready ] || continue
  a="$(secs "$now")"; b="$(secs "$rs")"
  if [ -n "$a" ] && [ -n "$b" ]; then echo "measure waiting $id $(hm $((a - b)))"; else echo "measure waiting $id not captured"; fi
done <<EOF
$rows
EOF
while IFS=$'\037' read -r id st pr mr dep ctr cr rs cl dr; do
  [ -n "$id" ] && [ "$st" = Done ] || continue
  a="$(secs "$cl")"; b="$(secs "$cr")"
  if [ -n "$a" ] && [ -n "$b" ]; then echo "measure lead-time $id $(hm $((a - b)))"; else echo "measure lead-time $id not captured"; fi
done <<EOF
$rows
EOF
echo "measure batch-size $started"
echo "measure in-flight $inflight"
# skipped roles (slice field "skipped": the roles the lead skipped) and the rework of skipped versus full Done slices (field "rework_rounds")
# measure skipped <roles> roles in <n> slices; measure rework skipped|full <mean rounds, one decimal|not captured>
jq -r '
  def mean(a): if (a | length) == 0 then "not captured" else "\((a | add) / (a | length) * 10 | round / 10 | tostring | if test("\\.") then . else . + ".0" end) (\(a | length) slices)" end;
  .slices as $s
  | ([$s[] | select(((.skipped // []) | length) > 0)]) as $sk
  | "measure skipped \([$sk[] | (.skipped | length)] | add // 0) roles in \($sk | length) slices",
    "measure rework skipped \(mean([$s[] | select(.status == "Done" and ((.skipped // []) | length) > 0 and (.rework_rounds | type) == "number") | .rework_rounds]))",
    "measure rework full \(mean([$s[] | select(.status == "Done" and ((.skipped // []) | length) == 0 and (.rework_rounds | type) == "number") | .rework_rounds]))"
' "$2"
