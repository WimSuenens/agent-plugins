#!/usr/bin/env bash
# The lines of docs/agents/factory.md the lead reads: factory-state and run-budget.
# Usage: bash factory-config.sh state [<factory.md>]     (default docs/agents/factory.md)
#        bash factory-config.sh budget [<factory.md>]
#        bash factory-config.sh table [<factory.md>]
#        bash factory-config.sh reached <spent> [<factory.md>]
#        bash factory-config.sh measurement [<factory.md>]
#        bash factory-config.sh analysis [--asked] [<factory.md>]
# table:   prints the flow table section of factory.md (the lines under `## Flow table` up to the next `## `): the project's points table,
#          its bands, test depth and floor. Exit 6 when the file has none (or an incomplete one).
# state:   also requires the flow table (setup-factory-skill writes it); prints nothing on success. A leftover parallel-limit line is ignored: one note line on stderr, exit 0.
# budget:  prints the per-run budget as "<N> tokens" or "<N> hours", or "none" when the line is absent or says none.
# reached: <spent> is a whole number in the budget's unit. Exit 0 when the budget is not reached (or there is none), 1 when spent >= budget.
# measurement: prints the measurement profile, "full" or "lite"; "full" when the line is absent. The line is "measurement: full" or "measurement: lite".
# analysis: exit 0 when cut-offs and token spend are to be computed (full, or lite with --asked), 1 when not (lite, not asked).
# Exit: 0 ok; 2 usage or the file is missing or unreadable; 3 state: no factory-state line (a 1.x project);
#       4 state: a factory-state line that is not line 1 or whose value is not 2; 5 budget: a bad or doubled run-budget line;
#       6 state or table: no flow table, or an incomplete one (a `## Flow table` heading, a `floor:` line and at least eight trigger rows).
# The lines are matched at column 0 and nowhere else. The setting is read from the file and from nowhere else.
# No slice maximum exists (ADR 0017): slices run side by side whenever their path lists do not overlap.

cmd="${1:-}"
case "$cmd" in
  state | budget | table) file="${2:-docs/agents/factory.md}" ;;
  reached)
    spent="${2:-}"
    case "$spent" in '' | *[!0-9]*) echo "usage: factory-config.sh reached <whole number> [<factory.md>]" >&2; exit 2 ;; esac
    file="${3:-docs/agents/factory.md}"
    ;;
  measurement) file="${2:-docs/agents/factory.md}" ;;
  analysis)
    asked=0
    if [ "${2:-}" = "--asked" ]; then asked=1; shift; fi
    case "${2:-}" in -*) echo "usage: factory-config.sh analysis [--asked] [<factory.md>]" >&2; exit 2 ;; esac
    file="${2:-docs/agents/factory.md}"
    ;;
  *) echo "usage: factory-config.sh state|budget|table|reached|measurement|analysis [<factory.md>]" >&2; exit 2 ;;
esac
if [ ! -f "$file" ] || [ ! -r "$file" ]; then
  echo "factory.md missing: run setup-factory-skill" >&2
  exit 2
fi

# flow_table: prints the flow table section; returns 0 when it is complete, 6 when there is none, 7 when it is incomplete
flow_table() {
  sec="$(awk '/^## /{p = ($0 ~ /^## Flow table[ \t\r]*$/); if (p) next} p' "$file" | tr -d '\r')"
  grep -q '^## Flow table[[:space:]]*$' "$file" || return 6
  rows="$(printf '%s\n' "$sec" | grep -cE '^\| [^|]+\|[^|]*\|' )"
  data=$((rows - 1))   # the header row is not a trigger (the separator row starts with `|-`)
  if [ "$data" -lt 8 ] || ! printf '%s\n' "$sec" | grep -q '^floor:'; then return 7; fi
  return 0
}

if [ "$cmd" = table ]; then
  flow_table >/dev/null; rc=$?
  [ "$rc" = 6 ] && { echo "factory.md has no flow table: run setup-factory-skill" >&2; exit 6; }
  [ "$rc" = 7 ] && { echo "factory.md has an incomplete flow table: run setup-factory-skill" >&2; exit 6; }
  printf '%s\n' "$sec" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sed '1{/^$/d;}'
  exit 0
fi

if [ "$cmd" = state ]; then
  if grep -q '^parallel-limit:' "$file"; then
    echo "note: factory.md has a parallel-limit line; it is ignored (slices run in parallel whenever their path lists do not overlap) and setup-factory-skill removes it" >&2
  fi
  first="$(head -n 1 "$file" | tr -d '\r')"
  if [ "$first" = "factory-state: 2" ]; then
    flow_table >/dev/null; rc=$?
    [ "$rc" = 6 ] && { echo "factory.md has no flow table: run setup-factory-skill" >&2; exit 6; }
    [ "$rc" = 7 ] && { echo "factory.md has an incomplete flow table: run setup-factory-skill" >&2; exit 6; }
    exit 0
  fi
  found="$(grep -m 1 '^factory-state:' "$file" | tr -d '\r')"
  if [ -z "$found" ]; then
    echo "factory.md has no factory-state line: run setup-factory-skill" >&2
    exit 3
  fi
  echo "factory.md has \"$(printf '%s' "$found" | cut -c 1-40)\": run setup-factory-skill" >&2
  exit 4
fi

if [ "$cmd" = measurement ] || [ "$cmd" = analysis ]; then
  mcount="$(grep -c '^measurement:' "$file")"
  if [ "$mcount" = 0 ]; then
    profile=full
  elif [ "$mcount" -gt 1 ]; then
    echo "factory.md has measurement more than once" >&2
    exit 5
  else
    mline="$(grep '^measurement:' "$file" | tr -d '\r')"
    case "$mline" in
      "measurement: full" | "measurement: full "*) profile=full ;;
      "measurement: lite" | "measurement: lite "*) profile=lite ;;
    esac
    if ! printf '%s\n' "$mline" | grep -Eq '^measurement: (full|lite)[ ]*$'; then
      echo "factory.md line \"$mline\": measurement must be full or lite" >&2
      exit 5
    fi
  fi
  if [ "$cmd" = measurement ]; then echo "$profile"; exit 0; fi
  [ "$profile" = lite ] && [ "$asked" = 0 ] && exit 1
  exit 0
fi

count="$(grep -c '^run-budget:' "$file")"
if [ "$count" = 0 ]; then
  budget="none"
elif [ "$count" -gt 1 ]; then
  echo "factory.md has run-budget more than once" >&2
  exit 5
else
  line="$(grep '^run-budget:' "$file" | tr -d '\r')"
  if printf '%s\n' "$line" | grep -Eq '^run-budget: none[ ]*$'; then
    budget="none"
  elif printf '%s\n' "$line" | grep -Eq '^run-budget: [1-9][0-9]* (tokens|hours)[ ]*$'; then
    budget="$(printf '%s\n' "$line" | sed -E 's/^run-budget: ([0-9]+) (tokens|hours).*$/\1 \2/')"
  else
    echo "factory.md line \"$line\": run-budget must be none, or a whole number of 1 or more followed by tokens or hours" >&2
    exit 5
  fi
fi

if [ "$cmd" = budget ]; then
  echo "$budget"
  exit 0
fi
[ "$budget" = none ] && exit 0
limit="${budget%% *}"
[ "$spent" -ge "$limit" ] && exit 1
exit 0
