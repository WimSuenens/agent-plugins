#!/bin/bash
# token-spend.sh: AC-15 measure 5, AC-16 (never 0 for an uncaptured spend) and contract 39-plugin-scripts section 3.
# Adopted from the developer's fixture test and extended by QA.
. "$(dirname "$0")/lib.sh"
a() { # id ts in cw cr out [model]
  printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","model":"%s","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s}}}\n' "$2" "$1" "${7:-claude-x}" "$3" "$4" "$5" "$6"; }
{ a m1 2026-11-04T10:00:00.100Z 1 10 100 5
  a m1 2026-11-04T10:00:00.900Z 2 20 200 50          # streamed: the last entry of an id wins
  echo '{"type":"user","timestamp":"2026-11-04T10:01:00Z","message":{"content":"hi"}}'
  a m2 2026-11-04T10:05:00Z 3 30 300 7
  a m3 2026-11-04T10:06:00Z 9 9 9 9 "<synthetic>"     # rate-limit stand-in: excluded
  echo '{"type":"assistant","timestamp":"2026-11-04T10:07:00Z","message":{"id":"m4","model":"x"}}'
  a m5 2026-11-04T20:44:12.345Z 1 1 1 1
} > "$T/one.jsonl"
a n1 2026-11-04T11:00:00Z 100 0 0 0 > "$T/two.jsonl"
ck all "spend 616 (input 6, cache write 51, cache read 501, output 58); peak 340; messages 3" "$(bash "$TS" "$T/one.jsonl")"
ck several-files-add-up "spend 716 (input 106, cache write 51, cache read 501, output 58); peak 340; messages 4" "$(bash "$TS" "$T/one.jsonl" "$T/two.jsonl")"
ck since "spend 344 (input 4, cache write 31, cache read 301, output 8); peak 340; messages 2" "$(bash "$TS" --since 2026-11-04T10:05Z "$T/one.jsonl")"
ck since-epoch-not-text "spend 4 (input 1, cache write 1, cache read 1, output 1); peak 4; messages 1" "$(bash "$TS" --since 2026-11-04T20:44Z "$T/one.jsonl")"
ck until "spend 272 (input 2, cache write 20, cache read 200, output 50); peak 272; messages 1" "$(bash "$TS" --until 2026-11-04T10:00:30Z "$T/one.jsonl")"
ck window-inclusive "spend 340 (input 3, cache write 30, cache read 300, output 7); peak 340; messages 1" "$(bash "$TS" --since 2026-11-04T10:02:00Z --until 2026-11-04T10:05:00Z "$T/one.jsonl")"
# the <tok> slot is the spend part verbatim, and total = i + w + r + o
line1="$(bash "$TS" "$T/one.jsonl")"
tot="$(printf '%s' "$line1" | sed -E 's/^spend ([0-9]+) .*/\1/')"
sum="$(printf '%s' "$line1" | sed -E 's/.*input ([0-9]+), cache write ([0-9]+), cache read ([0-9]+), output ([0-9]+)\).*/\1+\2+\3+\4/' | bc)"
ck tok-total-is-sum "$tot" "$sum"

# a message id seen in two files of one role counts once
cp "$T/two.jsonl" "$T/two-copy.jsonl"
ck duplicate-id-across-files "spend 100 (input 100, cache write 0, cache read 0, output 0); peak 100; messages 1" "$(bash "$TS" "$T/two.jsonl" "$T/two-copy.jsonl")"
# null and missing usage fields read as 0 within a captured message; blank lines; a path with a space
printf '\n{"type":"assistant","timestamp":"2026-11-04T10:00:00Z","message":{"id":"x","model":"m","usage":{"input_tokens":7,"output_tokens":null}}}\n\n' > "$T/sp ace.jsonl"
ck null-fields-blank-lines-space-path "spend 7 (input 7, cache write 0, cache read 0, output 0); peak 7; messages 1" "$(bash "$TS" "$T/sp ace.jsonl")"
# entries without a timestamp: counted without a window, never inside one
printf '{"type":"assistant","message":{"id":"y","model":"m","usage":{"input_tokens":5}}}\n' > "$T/nots.jsonl"
ck no-timestamp-no-window "spend 5 (input 5, cache write 0, cache read 0, output 0); peak 5; messages 1" "$(bash "$TS" "$T/nots.jsonl")"
bash "$TS" --since 2026-01-01T00:00Z "$T/nots.jsonl" >/dev/null 2>&1; ck no-timestamp-in-window-exit-5 5 $?

# --- AC-16: an uncaptured spend never prints a 0 line
out="$(bash "$TS" --since 2030-01-01T00:00Z "$T/one.jsonl" 2>/dev/null)"; code=$?
ck empty-window-exit-5 5 $code; ck empty-window-no-stdout "" "$out"
bash "$TS" --since 2026-11-04T11:00Z --until 2026-11-04T09:00Z "$T/one.jsonl" >/dev/null 2>&1; ck inverted-window-exit-5 5 $?
: > "$T/empty.jsonl"; out="$(bash "$TS" "$T/empty.jsonl" 2>/dev/null)"; code=$?; ck empty-file-exit-5 5 $code; ck empty-file-no-stdout "" "$out"
printf '{"type":"user","message":{}}\n' > "$T/useronly.jsonl"; bash "$TS" "$T/useronly.jsonl" >/dev/null 2>&1; ck no-assistant-exit-5 5 $?
a s1 2026-11-04T10:00:00Z 9 9 9 9 "<synthetic>" > "$T/synth.jsonl"; bash "$TS" "$T/synth.jsonl" >/dev/null 2>&1; ck synthetic-only-exit-5 5 $?
# unreadable transcripts: exit 3, the file name on stderr (the Lead copies it into "not captured (...)")
out="$(bash "$TS" "$T/missing.jsonl" 2>"$T/err")"; code=$?; ck missing-exit-3 3 $code; ck missing-no-stdout "" "$out"
has missing-names-file "$T/err" "missing.jsonl"
echo 'not json' > "$T/bad.jsonl"; out="$(bash "$TS" "$T/one.jsonl" "$T/bad.jsonl" 2>"$T/err")"; code=$?
ck bad-json-exit-3 3 $code; ck bad-json-no-partial-stdout "" "$out"; has bad-json-names-file "$T/err" "bad.jsonl"
bash "$TS" --since 2026-11-04T10:05Z "$T/bad.jsonl" >/dev/null 2>&1; ck bad-json-with-window-exit-3 3 $?
mkdir "$T/dir.jsonl"; bash "$TS" "$T/dir.jsonl" >/dev/null 2>&1; ck directory-exit-3 3 $?
cp "$T/one.jsonl" "$T/locked.jsonl"; chmod 000 "$T/locked.jsonl"
bash "$TS" "$T/locked.jsonl" >/dev/null 2>&1; ck unreadable-permission-exit-3 3 $?; chmod 644 "$T/locked.jsonl"
printf '[1,2]\n' > "$T/arr.jsonl"; out="$(bash "$TS" "$T/arr.jsonl" 2>/dev/null)"; code=$?
ck json-but-not-object-exit-3 3 $code; ck json-but-not-object-no-stdout "" "$out"
# jq missing: exit 4
mkdir "$T/bin"; for c in bash sed sort cat tr cut awk grep head dirname basename printf; do p="$(command -v $c)" && ln -s "$p" "$T/bin/$c"; done
PATH="$T/bin" /bin/bash "$TS" "$T/one.jsonl" >/dev/null 2>&1; ck jq-missing-exit-4 4 $?
# bad arguments: exit 2 (developer's addition)
bash "$TS" --since garbage "$T/one.jsonl" >/dev/null 2>&1; ck bad-time-exit-2 2 $?
bash "$TS" --since 2026-11-04 "$T/one.jsonl" >/dev/null 2>&1; ck date-only-exit-2 2 $?
bash "$TS" --since >/dev/null 2>&1; ck since-without-value-exit-2 2 $?
bash "$TS" --frobnicate "$T/one.jsonl" >/dev/null 2>&1; ck unknown-option-exit-2 2 $?
bash "$TS" >/dev/null 2>&1; ck no-files-exit-2 2 $?

# --- contract worked example on the real product-owner transcript of #39, when this machine still has it
R="$(find "$HOME/.claude/projects" -name 'agent-aff847e3e8c7e5bfa.jsonl' 2>/dev/null | head -1)"
if [ -n "$R" ]; then
  ck worked-example-po-39 "spend 387472 (input 22, cache write 52402, cache read 316497, output 18551); peak 53942; messages 11" "$(bash "$TS" "$R")"
else
  skip worked-example-po-39 "transcript agent-aff847e3e8c7e5bfa.jsonl not on this machine (cleanupPeriodDays)"
fi
done_
