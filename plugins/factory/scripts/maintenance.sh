#!/usr/bin/env bash
# The maintenance cycle: deciding whether to run one, and filing its results as backlog candidates.
# Usage: bash maintenance.sh decide <signals.json>
#        bash maintenance.sh budget [<factory.md>]
#        bash maintenance.sh candidate <cycle> <activity> <title> <body-file> [<factory.md>] [--one-way-door]
# decide: reads a snapshot {"backlog_ready": n, "ci": "green|red", "rework": [{"path", "count"}], "merges_since_cycle": n,
#      "inbox_aged": n, "vulnerable_deps": n} (a missing field reads as quiet) and prints one line:
#      "maintenance: run -- signal: <signal>[; <signal>...]" or "maintenance: skip -- no signal". A signal is: at most 1 ready
#      slice, red CI, 2 or more reworks on one path, 5 or more merges since the last cycle, 1 or more untriaged inbox items
#      older than a run, 1 or more known vulnerable dependencies.
# budget: prints the per-cycle ceiling, in candidates, from the line `maintenance-budget: <N> candidates` (default 10).
# candidate: files one backlog candidate of the maintenance kind (label `maintenance`, marker <!-- factory:maintenance <cycle> <activity> -->)
#      and prints "candidate <url> <activity>". <activity> is triage, diagnose, architecture, review or retrospective. It
#      changes nothing else: no code, no existing issue. With --one-way-door the candidate also gets the label `one-way-door` and
#      says it is not executed. The text is scanned first (post-text.sh scan).
# Exit: 0 ok; 2 usage or a bad snapshot; 4 a gh call failed; 5 a bad maintenance-budget line; 6 the scan refused the text;
#       7 the per-cycle budget is reached (nothing filed).

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-}"
usage() { echo "usage: maintenance.sh decide <signals.json> | budget [<factory.md>] | candidate <cycle> <activity> <title> <body-file> [<factory.md>] [--one-way-door]" >&2; exit 2; }

read_budget() {
  local file="${1:-docs/agents/factory.md}" line
  [ -f "$file" ] || { echo 10; return 0; }
  case "$(grep -c '^maintenance-budget:' "$file")" in
    0) echo 10; return 0 ;;
    1) ;;
    *) echo "factory.md has maintenance-budget more than once" >&2; return 5 ;;
  esac
  line="$(grep '^maintenance-budget:' "$file" | tr -d '\r')"
  if printf '%s\n' "$line" | grep -Eq '^maintenance-budget: [1-9][0-9]* candidates[ ]*$'; then
    printf '%s\n' "$line" | sed -E 's/^maintenance-budget: ([0-9]+) .*$/\1/'
  else
    echo "factory.md line \"$line\": maintenance-budget must be a whole number of 1 or more followed by candidates" >&2; return 5
  fi
}

case "$cmd" in
  decide)
    [ $# -eq 2 ] || usage
    command -v jq >/dev/null 2>&1 || { echo "maintenance: jq missing" >&2; exit 2; }
    [ -r "$2" ] && jq -e 'type == "object"' "$2" >/dev/null 2>&1 || { echo "maintenance: $2: not a signals snapshot" >&2; exit 2; }
    s="$(jq -r '
      [ (if (.backlog_ready != null and .backlog_ready <= 1) then "backlog empty or nearly empty (\(.backlog_ready) ready)" else empty end),
        (if .ci == "red" then "red CI" else empty end),
        ((.rework // [])[] | select(.count >= 2) | "repeated rework on \(.path) (\(.count))"),
        (if (.merges_since_cycle // 0) >= 5 then "\(.merges_since_cycle) merges since the last cycle" else empty end),
        (if (.inbox_aged // 0) >= 1 then "\(.inbox_aged) untriaged inbox \(if .inbox_aged == 1 then "item" else "items" end) older than a run" else empty end),
        (if (.vulnerable_deps // 0) >= 1 then "\(.vulnerable_deps) known vulnerable \(if .vulnerable_deps == 1 then "dependency" else "dependencies" end)" else empty end)
      ] | join("; ")' "$2")" || { echo "maintenance: $2: not a signals snapshot" >&2; exit 2; }
    if [ -n "$s" ]; then echo "maintenance: run -- signal: $s"; else echo "maintenance: skip -- no signal"; fi
    ;;
  budget)
    [ $# -le 2 ] || usage
    read_budget "${2:-}"; exit $?
    ;;
  candidate)
    [ $# -ge 5 ] || usage
    cycle="$2"; act="$3"; title="$4"; body="$5"; shift 5
    door=0; cfg=""
    for a in "$@"; do case "$a" in --one-way-door) door=1 ;; *) [ -z "$cfg" ] && cfg="$a" || usage ;; esac; done
    case "$act" in triage | diagnose | architecture | review | retrospective) ;; *) usage ;; esac
    case "$cycle" in '' | *[!A-Za-z0-9._-]*) usage ;; esac
    [ -r "$body" ] || usage
    limit="$(read_budget "$cfg")" || exit 5
    tmp="$(mktemp -d)" || exit 2; trap 'rm -rf "$tmp"' EXIT
    { printf '<!-- factory:maintenance %s %s -->\n\n' "$cycle" "$act"; cat "$body"
      [ $door = 1 ] && printf '\nNot executed: touches a one-way door; it needs a decision card to the person before any work starts.\n'; } >"$tmp/body"
    printf '%s\n' "$title" >"$tmp/title"
    bash "$here/post-text.sh" scan "$tmp/body" "$tmp/title" >&2 || { echo "maintenance: the scan refused the candidate; nothing filed" >&2; exit 6; }
    gh issue list --label maintenance --state all --limit 1000 --json number,body >"$tmp/known.json" 2>"$tmp/err" \
      || { echo "maintenance: gh issue list failed" >&2; exit 4; }
    n="$(jq --arg m "<!-- factory:maintenance $cycle " '[.[] | select(.body | contains($m))] | length' "$tmp/known.json")"
    if [ "$n" -ge "$limit" ]; then
      echo "maintenance budget reached: $n of $limit candidates this cycle; stop the cycle" >&2; exit 7
    fi
    gh label create maintenance --description "A maintenance candidate for the backlog" >/dev/null 2>&1 || true
    labels=(--label maintenance)
    if [ $door = 1 ]; then
      gh label create one-way-door --description "Touches a one-way door; not executed without the person" >/dev/null 2>&1 || true
      labels+=(--label one-way-door)
    fi
    url="$(gh issue create --title "$title" "${labels[@]}" --body-file "$tmp/body")" || { echo "maintenance: gh issue create failed" >&2; exit 4; }
    echo "candidate $url $act"
    ;;
  *) usage ;;
esac
