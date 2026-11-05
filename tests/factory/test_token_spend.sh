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

# --- feedback 15 #10 (security L7): "--" ends the options; '-'-prefixed transcript names
mkdir -p "$T/d"; cp "$T/two.jsonl" "$T/d/-x.jsonl"; cp "$T/two.jsonl" "$T/d/--since"
want_two="spend 100 (input 100, cache write 0, cache read 0, output 0); peak 100; messages 1"
ck dashdash-dash-name "$want_two" "$(cd "$T/d" && bash "$TS" -- -x.jsonl)"
ck dashdash-option-like-name "$want_two" "$(cd "$T/d" && bash "$TS" -- --since)"
ck options-then-dashdash "spend 4 (input 1, cache write 1, cache read 1, output 1); peak 4; messages 1" "$(bash "$TS" --since 2026-11-04T20:44Z -- "$T/one.jsonl")"
(cd "$T/d" && bash "$TS" -x.jsonl >/dev/null 2>&1); ck dash-name-without-dashdash-exit-2 2 $?
out="$(cd "$T/d" && bash "$TS" -- -missing.jsonl 2>"$T/err")"; code=$?
ck dashdash-missing-exit-3 3 $code; ck dashdash-missing-stderr "token-spend: transcript -missing.jsonl unreadable" "$(cat "$T/err")"
# exit 3 names the file by basename, in the contract's form, and no directory reaches stderr
deep="$T/home/someone/.claude/projects/p/s/subagents"; mkdir -p "$deep"; echo 'nope' > "$deep/agent-a41f09.jsonl"
bash "$TS" "$T/one.jsonl" "$deep/agent-a41f09.jsonl" >/dev/null 2>"$T/err"; code=$?
ck exit3-contract-line "token-spend: transcript agent-a41f09.jsonl unreadable" "$(cat "$T/err")"; ck exit3-code 3 $code
bash "$TS" "$deep/agent-gone.jsonl" >/dev/null 2>"$T/err"; ck missing-no-abs-path 0 "$(grep -c / "$T/err")"
# JSON that is valid but the wrong shape: the error still names the file and holds no path
cp "$T/arr.jsonl" "$deep/agent-arr.jsonl"; bash "$TS" "$T/one.jsonl" "$deep/agent-arr.jsonl" >/dev/null 2>"$T/err"; code=$?
ck wrong-shape-exit-3 3 $code; has wrong-shape-names-file "$T/err" "agent-arr.jsonl"
# QA-39 F4 (fixed in 9ee1cdc): the contract's one-file line, no path
ck wrong-shape-contract-line "token-spend: transcript agent-arr.jsonl unreadable" "$(cat "$T/err")"; ck wrong-shape-no-path 0 "$(grep -c / "$T/err")"
# wrong shape in the first of two files, and an object-per-line file mixed with a bare number: still one line naming the bad file
printf '{"type":"assistant"}\n42\n' > "$deep/agent-num.jsonl"; bash "$TS" "$deep/agent-num.jsonl" "$T/one.jsonl" >/dev/null 2>"$T/err"; code=$?
ck wrong-shape-mixed-exit-3 3 $code; ck wrong-shape-mixed-line "token-spend: transcript agent-num.jsonl unreadable" "$(cat "$T/err")"
# exit-5 text is the contract's
bash "$TS" --since 2030-01-01T00:00Z "$T/one.jsonl" >/dev/null 2>"$T/err"; ck exit5-text "token-spend: no messages in window" "$(cat "$T/err")"

# --- v2 (contract 39-plugin-scripts section 3): --require-end, exit 6 on a truncated transcript
# Entry shapes copied from real Claude Code subagent transcripts (the acceptance demo's, factory-sandbox #2).
ast() { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","model":"claude-x","content":[{"type":"text","text":"%s"}],"usage":{"input_tokens":1,"cache_creation_input_tokens":2,"cache_read_input_tokens":3,"output_tokens":4}}}\n' "$1" "$2" "$3"; }
atool() { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","model":"claude-x","content":[{"type":"tool_use","id":"%s","name":"%s","input":{}}],"usage":{"input_tokens":1,"cache_creation_input_tokens":2,"cache_read_input_tokens":3,"output_tokens":4}}}\n' "$1" "$2" "$3" "$4"; }
athink() { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","model":"claude-x","content":[{"type":"thinking","thinking":"","signature":"x"}],"usage":{"input_tokens":1,"cache_creation_input_tokens":2,"cache_read_input_tokens":3,"output_tokens":4}}}\n' "$1" "$2"; }
ures() { printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":[{"tool_use_id":"%s","type":"tool_result","content":"ok"}]}}\n' "$1" "$2"; }
uint() { printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":[{"type":"text","text":"[Request interrupted by user]"}]}}\n' "$1"; }
attach() { printf '{"type":"attachment","timestamp":"%s","attachment":{"type":"x"}}\n' "$1"; }
ubrief() { printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"You are the developer for factory item #2."}}\n' "$1"; }
RE() { bash "$TS" --require-end -- "$@"; }
# a run that ended on a final reply: exit 0, and the line is the same as without the option
{ ubrief 2026-11-04T23:00:00Z; atool 2026-11-04T23:00:05Z r1 t1 Bash; ures 2026-11-04T23:00:06Z t1; ast 2026-11-04T23:00:09Z r2 "Done."; attach 2026-11-04T23:00:10Z; } > "$T/final.jsonl"
out="$(RE "$T/final.jsonl")"; code=$?
ck require-end-final-reply-exit-0 0 $code
ck require-end-final-reply-same-line "$(bash "$TS" "$T/final.jsonl")" "$out"
# a run that ended on the SubagentHandback result (the docs-writer's shape in the demo): exit 0
{ ubrief 2026-11-05T06:50:00Z; athink 2026-11-05T06:58:45Z h1; ast 2026-11-05T06:58:45.301Z h2 "Let me create the final report."; atool 2026-11-05T06:58:48Z h3 th SubagentHandback; ures 2026-11-05T06:58:48.613Z th; } > "$T/handback.jsonl"
RE "$T/handback.jsonl" >/dev/null; ck require-end-handback-exit-0 0 $?
# the hand-back tool_use without its result: truncated
{ ubrief 2026-11-05T06:50:00Z; atool 2026-11-05T06:58:48Z h3 th SubagentHandback; } > "$T/handback-noresult.jsonl"
RE "$T/handback-noresult.jsonl" >/dev/null 2>&1; ck require-end-handback-without-result-exit-6 6 $?
# a tool_result that answers some other tool, last: truncated (the model call after it never came)
{ ubrief 2026-11-04T23:00:00Z; atool 2026-11-04T23:50:45Z d1 td Bash; ures 2026-11-04T23:50:46Z td; } > "$T/after-result.jsonl"
RE "$T/after-result.jsonl" >/dev/null 2>&1; ck require-end-ends-on-other-tool-result-exit-6 6 $?
# a tool_result whose id merely matches a SubagentHandback name elsewhere does not count: the id must be the hand-back's
{ ubrief 2026-11-05T06:50:00Z; atool 2026-11-05T06:58:40Z h0 tb Bash; atool 2026-11-05T06:58:48Z h3 th SubagentHandback; ures 2026-11-05T06:58:49Z tb; } > "$T/handback-wrong-id.jsonl"
RE "$T/handback-wrong-id.jsonl" >/dev/null 2>&1; ck require-end-result-of-other-tool-after-handback-exit-6 6 $?
# an unanswered tool call: exit 6, stdout empty, stderr names the file by basename only
deep6="$T/home/someone/.claude/projects/p/s/subagents"; mkdir -p "$deep6"
{ ubrief 2026-11-04T23:00:00Z; atool 2026-11-04T23:50:45Z d1 td Bash; attach 2026-11-04T23:50:46Z; } > "$deep6/agent-e90b55.jsonl"
out="$(RE "$deep6/agent-e90b55.jsonl" 2>"$T/err")"; code=$?
ck require-end-unanswered-tool-exit-6 6 $code; ck require-end-unanswered-no-stdout "" "$out"
ck require-end-stderr-contract-line "token-spend: transcript agent-e90b55.jsonl truncated" "$(cat "$T/err")"
ck require-end-stderr-no-path 0 "$(grep -c / "$T/err")"
# the demo's developer (done, then stalled): the watchdog left "[Request interrupted by user]" as the last entry
{ ubrief 2026-11-04T23:00:00Z; athink 2026-11-04T23:50:41Z d0; atool 2026-11-04T23:50:45Z d1 td Bash; ures 2026-11-04T23:50:46Z td; uint 2026-11-05T00:05:54Z; } > "$deep6/agent-a37df3.jsonl"
out="$(RE "$deep6/agent-a37df3.jsonl" 2>"$T/err")"; code=$?
ck require-end-demo-developer-exit-6 6 $code; ck require-end-demo-developer-no-stdout "" "$out"
ck require-end-demo-developer-stderr "token-spend: transcript agent-a37df3.jsonl truncated" "$(cat "$T/err")"
# without --require-end the same file still sums (the Lead's own window never checks endings)
bash "$TS" "$deep6/agent-a37df3.jsonl" >/dev/null; ck no-require-end-cut-file-still-sums 0 $?
# an interruption earlier in the run, resumed and finished with a final reply: still exit 6 (rule 1)
{ ubrief 2026-11-04T23:00:00Z; atool 2026-11-04T23:10:00Z i1 ti Bash; uint 2026-11-04T23:20:00Z; ubrief 2026-11-04T23:30:00Z; ast 2026-11-04T23:31:00Z i2 "Done."; } > "$T/resumed.jsonl"
RE "$T/resumed.jsonl" >/dev/null 2>&1; ck require-end-interrupted-then-resumed-exit-6 6 $?
# the marker as a plain string content too
{ ubrief 2026-11-04T23:00:00Z; printf '{"type":"user","timestamp":"2026-11-04T23:20:00Z","message":{"content":"[Request interrupted by user for tool use]"}}\n'; ast 2026-11-04T23:31:00Z s2 "Done."; } > "$T/resumed-str.jsonl"
RE "$T/resumed-str.jsonl" >/dev/null 2>&1; ck require-end-interrupted-string-content-exit-6 6 $?
# the text only mentioning the marker later in a message is not the marker
{ ubrief 2026-11-04T23:00:00Z; printf '{"type":"user","timestamp":"2026-11-04T23:20:00Z","message":{"content":"please grep for [Request interrupted"}}\n'; ast 2026-11-04T23:31:00Z q2 "Done."; } > "$T/mention.jsonl"
RE "$T/mention.jsonl" >/dev/null; ck require-end-marker-only-at-start 0 $?
# several files: one truncated among good ones -> exit 6 naming that one; order does not matter
out="$(RE "$T/final.jsonl" "$deep6/agent-a37df3.jsonl" "$T/handback.jsonl" 2>"$T/err")"; code=$?
ck require-end-one-of-several-exit-6 6 $code; ck require-end-one-of-several-names-it "token-spend: transcript agent-a37df3.jsonl truncated" "$(cat "$T/err")"
ck require-end-one-of-several-no-stdout "" "$out"
RE "$T/final.jsonl" "$T/handback.jsonl" >/dev/null; ck require-end-all-good-exit-0 0 $?
# exit order: 3 (unreadable) before 6, 6 before 5
RE "$deep6/agent-a37df3.jsonl" "$T/bad.jsonl" >/dev/null 2>&1; ck require-end-unreadable-wins-over-truncated 3 $?
{ ubrief 2026-11-04T23:00:00Z; atool 2026-11-04T23:10:00Z z1 tz Bash; } > "$T/cut-old.jsonl"
bash "$TS" --require-end --since 2030-01-01T00:00Z -- "$T/cut-old.jsonl" >/dev/null 2>&1; ck require-end-truncated-wins-over-empty-window 6 $?
# --require-end reads the whole file regardless of the window: a cut after --until is still a cut
bash "$TS" --require-end --until 2026-11-04T23:15Z -- "$T/cut-old.jsonl" >/dev/null 2>&1; ck require-end-ignores-window 6 $?
# a file with no assistant/user entry at all is truncated (no final reply), not "0"
attach 2026-11-04T23:00:00Z > "$T/attach-only.jsonl"
out="$(RE "$T/attach-only.jsonl" 2>/dev/null)"; code=$?; ck require-end-no-messages-exit-6 6 $code; ck require-end-no-messages-no-stdout "" "$out"
: > "$T/empty2.jsonl"; RE "$T/empty2.jsonl" >/dev/null 2>&1; ck require-end-empty-file-not-0 6 $?
# option placement: after other options, before --; an unknown option is still exit 2
bash "$TS" --since 2026-11-04T23:00Z --require-end "$T/final.jsonl" >/dev/null; ck require-end-after-since 0 $?
bash "$TS" --require-endx "$T/final.jsonl" >/dev/null 2>&1; ck require-end-typo-exit-2 2 $?
# a file named like the option, after --, is a transcript
cp "$T/final.jsonl" "$T/d/--require-end"; ck require-end-name-after-dashdash "$(bash "$TS" "$T/final.jsonl")" "$(cd "$T/d" && bash "$TS" --require-end -- --require-end)"

# QA-39 v2 F3: a sleep that cut a response mid-run leaves an API-error entry (isApiErrorMessage, error server_error,
# model <synthetic>); the agent then went on and handed back, so no failure notice reached the Lead (no wait logged,
# signal a absent) and --require-end passes it. The request in flight was lost, so its spend is short (contract
# 39-hansei-record measure 5's own premise). Shape copied from a real subagent transcript.
{ ubrief 2026-10-28T07:00:00Z; atool 2026-10-28T07:05:34Z s1 ts Edit; ures 2026-10-28T07:05:34.379Z ts
  printf '{"type":"assistant","timestamp":"2026-10-28T07:14:59.900Z","isApiErrorMessage":true,"error":"server_error","message":{"id":"e1","model":"<synthetic>","content":[{"type":"text","text":"API Error: Your computer went to sleep mid-response. The response above may be incomplete."}],"usage":{"input_tokens":0,"output_tokens":0}}}\n'
  atool 2026-10-28T07:15:21Z s2 th2 SubagentHandback; ures 2026-10-28T07:15:22Z th2; } > "$T/sleep-midrun.jsonl"
RE "$T/sleep-midrun.jsonl" >/dev/null 2>&1; code=$?
if [ $code = 6 ]; then ck require-end-sleep-mid-run-exit-6 6 $code
else skip require-end-sleep-mid-run-exit-6 "QA-39 v2 F3: exit $code, want 6 -- a server_error API-error entry mid-run is not read as a cut (architect, then developer)"; fi
# the same for a stream cut that Claude Code recovered by itself: it writes an isMeta user entry "Your response above was
# cut off mid-stream ..." and the agent goes on (the demo's QA agent a85f55… had three, 00:14Z-00:48Z, with no notice)
{ ubrief 2026-11-05T00:07:00Z; athink 2026-11-05T00:08:06Z c1
  printf '{"type":"user","timestamp":"2026-11-05T00:14:49.000Z","isMeta":true,"message":{"role":"user","content":"Your response above was cut off mid-stream and only your next message is delivered. Write the complete response again from the start — no apology, no mention of the cut-off."}}\n'
  ast 2026-11-05T00:15:00Z c2 "Done."; } > "$T/cut-midstream.jsonl"
RE "$T/cut-midstream.jsonl" >/dev/null 2>&1; code=$?
if [ $code = 6 ]; then ck require-end-cut-mid-stream-exit-6 6 $code
else skip require-end-cut-mid-stream-exit-6 "QA-39 v2 F3: exit $code, want 6 -- a recovered mid-stream cut-off is not read as a cut (architect, then developer)"; fi

# --- contract worked example on the real product-owner transcript of #39, when this machine still has it
R="$(find "$HOME/.claude/projects" -name 'agent-aff847e3e8c7e5bfa.jsonl' 2>/dev/null | head -1)"
if [ -n "$R" ]; then
  ck worked-example-po-39 "spend 387472 (input 22, cache write 52402, cache read 316497, output 18551); peak 53942; messages 11" "$(bash "$TS" "$R")"
else
  skip worked-example-po-39 "transcript agent-aff847e3e8c7e5bfa.jsonl not on this machine (cleanupPeriodDays)"
fi
done_
