#!/usr/bin/env bash
# The start gate at the run events "slice ready" and "PR opened": the budget part, then the integrator's plan, so the order and the path-overlap
# pauses come from the script and not from the lead's judgement (#160 (b); #207 slice 4).
# Usage: bash start-gate.sh --board <board.json> --slice <id> --event slice-ready|pr-opened [--factory <factory.md>] [--spent <n>]
# <board.json> is the snapshot `integrator.sh plan` reads (the board, in the lead's priority order). --factory defaults to docs/agents/factory.md,
# --spent (default 0) is the run's spend in the budget's unit.
# Output, in this order:
#   event: <event>
#   budget: ok | reached              (factory-config.sh reached)
#   <the integrator's plan lines>     merge, order, advise, start, pause and measure lines, as integrator.sh prints them
#   gate: start <id>                  the plan starts the slice and the budget holds
#   gate: stay <id> -- <reason>       `budget reached`, or the plan's own `pause` reason (for example `overlaps #<id> on <path>`)
# The integrator stays advisory: the lead still starts the slice and still owns priority; the gate only says what the script computed.
# Exit: 0 start; 1 stay; 2 usage, an unreadable board or factory.md, or a slice that is not on the board.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
board=""; slice=""; event=""; factory="docs/agents/factory.md"; spent=0
while [ $# -gt 0 ]; do
  case "$1" in
    --board) board="${2:-}"; shift 2 || usage ;;
    --slice) slice="${2:-}"; shift 2 || usage ;;
    --event) event="${2:-}"; shift 2 || usage ;;
    --factory) factory="${2:-}"; shift 2 || usage ;;
    --spent) spent="${2:-}"; shift 2 || usage ;;
    *) usage ;;
  esac
done
case "$event" in slice-ready | pr-opened) ;; *) usage ;; esac
case "$slice$spent" in *[!0-9]*) usage ;; esac
[ -n "$slice" ] && [ -n "$board" ] || usage

plan="$(bash "$here/integrator.sh" plan "$board" 2>&1)" || { printf '%s\n' "$plan" >&2; exit 2; }
jq -e --arg s "$slice" 'any(.slices[]; (.id | tostring) == $s)' "$board" >/dev/null 2>&1 || { echo "start-gate: slice $slice is not on the board $board" >&2; exit 2; }
bash "$here/factory-config.sh" reached "$spent" "$factory" >/dev/null 2>"${TMPDIR:-/tmp}/start-gate.$$"; rc=$?
err="$(cat "${TMPDIR:-/tmp}/start-gate.$$")"; rm -f "${TMPDIR:-/tmp}/start-gate.$$"
case "$rc" in
  0) budget=ok ;;
  1) budget=reached ;;
  *) printf '%s\n' "$err" >&2; exit 2 ;;
esac

echo "event: $event"
echo "budget: $budget"
printf '%s\n' "$plan"
if [ "$budget" = reached ]; then echo "gate: stay $slice -- budget reached"; exit 1; fi
if printf '%s\n' "$plan" | grep -q "^start $slice --"; then echo "gate: start $slice"; exit 0; fi
reason="$(printf '%s\n' "$plan" | sed -n "s/^pause $slice -- //p" | head -1)"
if [ -n "$reason" ]; then echo "gate: stay $slice -- $reason"; exit 1; fi
# a slice that is not Ready (in flight, merge-ready or done) has no start or pause line
echo "gate: stay $slice -- the plan neither starts nor pauses it (not Ready)"
exit 1
