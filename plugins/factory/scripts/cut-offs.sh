#!/usr/bin/env bash
# The cut-offs a Claude Code transcript shows: one line per gap in which an agent (or the Lead) made no progress.
# Usage: bash cut-offs.sh [--since <UTC time>] [--until <UTC time>] [--sleep-log <file> | --sleep-log -] [--] <transcript.jsonl>...
# Times: YYYY-MM-DDTHH:MMZ or YYYY-MM-DDTHH:MM:SSZ, compared as epoch seconds.
# Stdout, tab-separated, sorted by start per transcript: <basename> <kind> <start> <end | open> <markers>
# --sleep-log: the output of the exact pmset/awk filter in references/hansei.md; a stalled gap in which the machine slept becomes interrupted.
# Exit: 0 ok (zero or more lines); 2 bad usage; 3 a transcript or the sleep log is unreadable, or an entry lacks a timestamp; 4 jq missing.
# See contracts/39-plugin-scripts.md section 4 in the repo that hosts the factory.

if ! command -v jq >/dev/null 2>&1; then
  echo "cut-offs: jq missing" >&2
  exit 4
fi

since=""
until_=""
sleep_log=""
have_sleep=0
while [ $# -gt 0 ]; do
  case "$1" in
    --since) since="${2:-}"; shift 2 || { echo "cut-offs: --since needs a time" >&2; exit 2; } ;;
    --until) until_="${2:-}"; shift 2 || { echo "cut-offs: --until needs a time" >&2; exit 2; } ;;
    --sleep-log) [ $# -ge 2 ] || { echo "cut-offs: --sleep-log needs a file or -" >&2; exit 2; }
                 sleep_log="$2"; have_sleep=1; shift 2 ;;
    --) shift; break ;;
    -*) echo "cut-offs: unknown option $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
if [ $# -eq 0 ]; then
  echo "usage: cut-offs.sh [--since T] [--until T] [--sleep-log <file>|-] [--] <transcript.jsonl>..." >&2
  exit 2
fi

norm() {
  case "$1" in
    "") return 0 ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]Z) printf '%s:00Z' "${1%Z}" ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) printf '%s' "$1" ;;
    *) return 1 ;;
  esac
}
since="$(norm "$since")" || { echo "cut-offs: bad --since time" >&2; exit 2; }
until_="$(norm "$until_")" || { echo "cut-offs: bad --until time" >&2; exit 2; }

sleep_text=""
if [ "$have_sleep" = 1 ]; then
  if [ "$sleep_log" = "-" ]; then
    sleep_text="$(cat)" || { echo "cut-offs: sleep log unreadable" >&2; exit 3; }
  else
    if [ ! -r "$sleep_log" ] || [ ! -f "$sleep_log" ]; then
      echo "cut-offs: sleep log $(basename "$sleep_log") unreadable" >&2
      exit 3
    fi
    sleep_text="$(cat "$sleep_log")" || { echo "cut-offs: sleep log $(basename "$sleep_log") unreadable" >&2; exit 3; }
  fi
fi

# a name starting with "-" must not be read as an option by jq
args=()
for f in "$@"; do
  case "$f" in -*) f="./$f" ;; esac
  args+=("$f")
done
set -- "${args[@]}"

for f in "$@"; do
  if [ ! -r "$f" ] || [ ! -f "$f" ] || ! jq -se 'all(.[]; type == "object")' "$f" >/dev/null 2>&1; then
    echo "cut-offs: transcript $(basename "$f") unreadable" >&2
    exit 3
  fi
done

prog='
def epoch: sub("\\.[0-9]+"; "") | fromdateiso8601;
def iso: strftime("%Y-%m-%dT%H:%M:%SZ");
def txt: if (.message.content | type) == "string" then .message.content
         else ([.message.content[]? | select(.type == "text") | .text] | join("")) end;
def mark:
  if .type == "user" and (txt | test("cut off mid-stream")) then ["stalled", "cut-mid-stream"]
  elif .type == "user" and (txt | startswith("[Request interrupted")) then ["stalled", "request-interrupted"]
  elif .type == "assistant" and (.isApiErrorMessage == true or ((.error // null) | type) == "string"
                                 or (txt | test("^(API Error|You.ve hit your)")))
    then [ (if (.error // "") == "rate_limit" or (txt | test("^You.ve hit your")) then "limits" else "interrupted" end),
           ("api-error:" + ((.error // "unknown") | tostring)) ]
  elif .type == "system" and (.error // null) != null then ["interrupted", "api-retry"]
  else null end;
def rank: if . == "limits" then 0 elif . == "interrupted" then 1 else 2 end;

# sleep events as epoch seconds (UTC), from "YYYY-MM-DD HH:MM:SS +HHMM Sleep|Wake" lines; others are skipped
( [ $sl | split("\n")[]
  | capture("^(?<d>[0-9]{4}-[0-9]{2}-[0-9]{2}) (?<t>[0-9]{2}:[0-9]{2}:[0-9]{2}) (?<s>[+-])(?<h>[0-9]{2})(?<m>[0-9]{2}) (?<k>Sleep|Wake) *$")?
  | { t: (((.d + "T" + .t + "Z") | fromdateiso8601) - ((if .s == "-" then -1 else 1 end) * ((.h | tonumber) * 3600 + (.m | tonumber) * 60))), k: .k }
] | sort_by(.t) ) as $ev

| [ .[] | select(.type == "user" or .type == "assistant" or .type == "system") ]
| to_entries
| map(.value as $e
      | ($e | mark) as $mk
      | if ($e.type != "system" or $mk != null) and (($e.timestamp | type) != "string") then error("no timestamp") else . end
      | { type: $e.type, mk: $mk, t: (if ($e.timestamp | type) == "string" then ($e.timestamp | epoch) else null end),
          res: ($e.type == "user" and ([ $e.message.content | if type == "array" then .[] else empty end | select(.type == "tool_result") ] | length) > 0) })
| . as $all
| [ $all[] | select(.type != "system" and .mk == null) ] as $prog
| ($all | map(select(.type != "system" or .mk != null))) as $ents

# marker gaps
| [ range(0; $ents | length) as $p | $ents[$p] | select(.mk != null) as $m
    | ([ $ents[0:$p][] | select(.type != "system" and .mk == null) ] | last) as $s
    | ([ $ents[$p+1:][] | select(.type == "assistant" and .mk == null) ] | first) as $n
    | { start: (if $s then $s.t else $m.t end), key: (if $s then $s.t else $m.t end), mt: $m.t,
        end: (if $n then $n.t else null end), kind: $m.mk[0], mark: $m.mk[1] } ]
| group_by(.start)
| map({ start: .[0].start, first: (map(.mt) | min), last: (map(.mt) | max), end: .[0].end,
        kind: (map(.kind) | sort_by(rank) | .[0]), marks: (map(.mark) | unique | join(",")) }) as $mg

# silent gaps: a tool result, then an assistant entry 600s or more later, nothing between
| [ range(0; $prog | length - 1) as $i | $prog[$i] as $a | $prog[$i+1] as $b
    | select($a.res and $b.type == "assistant" and ($b.t - $a.t) >= 600)
    | select(([ $ents[] | select(.mk != null and .t >= $a.t and .t <= $b.t) ] | length) == 0)
    | { start: $a.t, first: $a.t, last: $b.t, end: $b.t, kind: "stalled", marks: "silent-gap" } ] as $sg

| ($mg + $sg)
| map(select(($since == "" or .first >= ($since | epoch)) and ($until == "" or .first <= ($until | epoch))))
| sort_by(.start, .first)
| map( . as $g
      | (if .end == null then .last else .end end) as $e
      | (if .kind == "stalled" and ($ev | length) > 0 then
           ( ([ $ev[] | select(.t >= $g.start and .t <= $e) ] | length) > 0
             or (([ $ev[] | select(.t <= $g.start) ] | last) as $b | $b != null and $b.k == "Sleep") )
         else false end) as $asleep
      | (if $asleep then "interrupted" else .kind end) as $kind
      | [ $name, $kind, (.start | iso), (if .end == null then "open" else (.end | iso) end), .marks ] | @tsv )
| .[]
'

result=""
for f in "$@"; do
  out="$(jq -rs --arg since "$since" --arg until "$until_" --arg name "$(basename "$f")" \
           --rawfile sl <(printf '%s\n' "$sleep_text") "$prog" "$f" 2>/dev/null)" || {
    echo "cut-offs: transcript $(basename "$f") unreadable" >&2
    exit 3
  }
  [ -z "$out" ] || result="${result}${out}"$'\n'
done
printf '%s' "$result"
