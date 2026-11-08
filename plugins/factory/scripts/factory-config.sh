#!/usr/bin/env bash
# The two lines of docs/agents/factory.md the lead reads: factory-state and parallel-limit.
# Usage: bash factory-config.sh state [<factory.md>]     (default docs/agents/factory.md)
#        bash factory-config.sh limit [<factory.md>]
# state: prints nothing on success. limit: prints the number of slices that may run at the same time (2 when the line is absent).
# Exit: 0 ok; 2 usage or the file is missing or unreadable; 3 state: no factory-state line (a 1.x project);
#       4 state: a factory-state line that is not line 1 or whose value is not 2; 5 limit: a bad or doubled parallel-limit line.
# Both lines are matched at column 0 and nowhere else. The setting is read from the file and from nowhere else.
# See contracts/64-parallel-slices.md section 3 in the repo that hosts the factory.

cmd="${1:-}"
case "$cmd" in
  state | limit) ;;
  *) echo "usage: factory-config.sh state|limit [<factory.md>]" >&2; exit 2 ;;
esac
file="${2:-docs/agents/factory.md}"
if [ ! -f "$file" ] || [ ! -r "$file" ]; then
  echo "factory.md missing: run setup-factory-skill" >&2
  exit 2
fi

if [ "$cmd" = state ]; then
  first="$(head -n 1 "$file" | tr -d '\r')"
  if [ "$first" = "factory-state: 2" ]; then
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

count="$(grep -c '^parallel-limit:' "$file")"
if [ "$count" = 0 ]; then
  echo 2
  exit 0
fi
if [ "$count" -gt 1 ]; then
  echo "factory.md has parallel-limit more than once" >&2
  exit 5
fi
line="$(grep '^parallel-limit:' "$file" | tr -d '\r')"
if printf '%s\n' "$line" | grep -Eq '^parallel-limit: [1-9][0-9]*[ ]*$'; then
  printf '%s\n' "$line" | sed -E 's/^parallel-limit: ([0-9]+).*$/\1/'
  exit 0
fi
echo "factory.md line \"$line\": parallel-limit must be a whole number of 1 or more" >&2
exit 5
