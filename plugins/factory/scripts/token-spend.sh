#!/usr/bin/env bash
# Token spend of one role (or the lead) from Claude Code transcripts.
# Usage: bash token-spend.sh [--since <UTC time>] [--until <UTC time>] [--require-end] [--] <transcript.jsonl>...
# Times: YYYY-MM-DDTHH:MMZ or YYYY-MM-DDTHH:MM:SSZ, compared as epoch seconds.
# Stdout: spend <total> (input <i>, cache write <w>, cache read <r>, output <o>); peak <p>; messages <n>
# --require-end: a transcript must show a run that ended by itself and was never cut on the way (cut-offs.sh in this script's directory reports no stalled/interrupted line other than silent-gap; last assistant/user entry is a final reply or the SubagentHandback result). Not for the lead's own session.
# Exit: 0 ok; 2 bad arguments; 3 a file is missing, unreadable or not JSON; 4 jq missing; 5 no message in window; 6 --require-end and a transcript is truncated.
# See contracts/39-plugin-scripts.md section 3 in the repo that hosts the factory.

if ! command -v jq >/dev/null 2>&1; then
  echo "token-spend: jq missing" >&2
  exit 4
fi

since=""
until_=""
require_end=0
while [ $# -gt 0 ]; do
  case "$1" in
    --since) since="${2:-}"; shift 2 || { echo "token-spend: --since needs a time" >&2; exit 2; } ;;
    --until) until_="${2:-}"; shift 2 || { echo "token-spend: --until needs a time" >&2; exit 2; } ;;
    --require-end) require_end=1; shift ;;
    --) shift; break ;;
    -*) echo "token-spend: unknown option $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
if [ $# -eq 0 ]; then
  echo "usage: token-spend.sh [--since T] [--until T] [--require-end] [--] <transcript.jsonl>..." >&2
  exit 2
fi

# Turn YYYY-MM-DDTHH:MMZ[:SS] into YYYY-MM-DDTHH:MM:SSZ; empty stays empty; anything else fails.
norm() {
  case "$1" in
    "") return 0 ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]Z) printf '%s:00Z' "${1%Z}" ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) printf '%s' "$1" ;;
    *) return 1 ;;
  esac
}
since="$(norm "$since")" || { echo "token-spend: bad --since time" >&2; exit 2; }
until_="$(norm "$until_")" || { echo "token-spend: bad --until time" >&2; exit 2; }

# a name starting with "-" must not be read as an option by jq
args=()
for f in "$@"; do
  case "$f" in -*) f="./$f" ;; esac
  args+=("$f")
done
set -- "${args[@]}"

for f in "$@"; do
  if [ ! -r "$f" ] || [ ! -f "$f" ] || ! jq -se 'all(.[]; type == "object")' "$f" >/dev/null 2>&1; then
    echo "token-spend: transcript $(basename "$f") unreadable" >&2
    exit 3
  fi
done

if [ "$require_end" = 1 ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for f in "$@"; do
    # rule 1: no cut-off marker anywhere (one marker test, shared with cut-offs.sh); exit 3 or 4 is passed on
    all="$(bash "$here/cut-offs.sh" -- "$f" 2>&1)"; rc=$?
    if [ "$rc" -eq 3 ] || [ "$rc" -eq 4 ]; then
      printf '%s\n' "$all" | sed 's/^cut-offs:/token-spend:/' >&2
      exit "$rc"
    fi
    if [ "$rc" -ne 0 ] || printf '%s\n' "$all" | awk -F'\t' '$2 != "limits" && $5 != "silent-gap" && NF >= 5 {f=1} END {exit !f}'; then
      echo "token-spend: transcript $(basename "$f") truncated" >&2
      exit 6
    fi
    if ! jq -se '
      def blocks: (.message.content | if type == "array" then .[] else empty end);
      [ .[] | select(.type == "assistant" or .type == "user") ] as $m
      | [ $m[] | select(.type == "assistant") | blocks | select(.type == "tool_use" and .name == "SubagentHandback") | .id ] as $hand
      | ($m | last) as $l
      | ($l != null)
        and (
          ($l.type == "assistant" and ([ $l | blocks | select(.type == "tool_use") ] | length) == 0)
          or ($l.type == "user" and ([ $l | blocks | select(.type == "tool_result" and (.tool_use_id as $t | $hand | index($t))) ] | length) > 0)
        )
    ' "$f" >/dev/null 2>&1; then
      echo "token-spend: transcript $(basename "$f") truncated" >&2
      exit 6
    fi
  done
fi

out="$(jq -rs --arg since "$since" --arg until "$until_" '
  def epoch: sub("\\.[0-9]+"; "") | fromdateiso8601;
  def tok: (.input_tokens // 0), (.cache_creation_input_tokens // 0), (.cache_read_input_tokens // 0), (.output_tokens // 0);
  [ to_entries[] | .key as $i | .value
    | select(.type == "assistant" and (.message.usage | type) == "object" and .message.model != "<synthetic>")
    | select(
        ($since == "" or ((.timestamp // "") != "" and (.timestamp | epoch) >= ($since | epoch))) and
        ($until == "" or ((.timestamp // "") != "" and (.timestamp | epoch) <= ($until | epoch))))
    | {k: (.message.id // ("noid-" + ($i | tostring))), u: .message.usage}
  ]
  | reduce .[] as $e ({}; .[$e.k] = $e.u)
  | [ .[] | {i: (.input_tokens // 0), w: (.cache_creation_input_tokens // 0), r: (.cache_read_input_tokens // 0), o: (.output_tokens // 0)} ]
  | if length == 0 then empty else
      {i: (map(.i) | add), w: (map(.w) | add), r: (map(.r) | add), o: (map(.o) | add), p: (map(.i + .w + .r + .o) | max), n: length}
      | "spend \(.i + .w + .r + .o) (input \(.i), cache write \(.w), cache read \(.r), output \(.o)); peak \(.p); messages \(.n)"
    end
' "$@" 2>/dev/null)" || { echo "token-spend: a transcript is unreadable or not JSON" >&2; exit 3; }

if [ -z "$out" ]; then
  echo "token-spend: no messages in window" >&2
  exit 5
fi
printf '%s\n' "$out"
