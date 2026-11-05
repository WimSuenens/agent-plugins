#!/bin/bash
# cut-offs.sh: contract 39-plugin-scripts section 4 (markers, gaps, silent gap, strongest kind, sleep log, window, exits),
# behind AC-11 (waits from the transcript), AC-15 measures 1 and 5, and AC-17 (the demo's stalls and sleeps).
# Fixture shapes are copied from the acceptance demo's real transcripts (factory-sandbox #2); see reviews/qa-39.md.
. "$(dirname "$0")/lib.sh"
CO_() { bash "$CO" "$@"; }
# entry builders: <ts> [...]
U()   { printf '{"type":"user","timestamp":"%s","message":{"content":"%s"}}\n' "$1" "${2:-go on}"; }
A()   { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","content":[{"type":"text","text":"%s"}]}}\n' "$1" "${2:-a$RANDOM}" "${3:-working}"; }
AT()  { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","content":[{"type":"tool_use","id":"%s","name":"Bash","input":{}}]}}\n' "$1" "a$RANDOM" "$2"; }
UR()  { printf '{"type":"user","timestamp":"%s","message":{"content":[{"tool_use_id":"%s","type":"tool_result","content":"ok"}]}}\n' "$1" "$2"; }
CUT() { printf '{"type":"user","timestamp":"%s","isMeta":true,"message":{"role":"user","content":"Your response above was cut off mid-stream and only your next message is delivered. Write the complete response again from the start."}}\n' "$1"; }
INTA(){ printf '{"type":"user","timestamp":"%s","message":{"content":[{"type":"text","text":"[Request interrupted by user]"}]}}\n' "$1"; }
INTS(){ printf '{"type":"user","timestamp":"%s","message":{"content":"[Request interrupted by user for tool use]"}}\n' "$1"; }
APIE(){ printf '{"type":"assistant","timestamp":"%s","isApiErrorMessage":true,"error":"%s","message":{"id":"e%s","model":"<synthetic>","content":[{"type":"text","text":"%s"}]}}\n' "$1" "$2" "$RANDOM" "${3:-API Error: Your computer went to sleep mid-response.}"; }
SYSE(){ printf '{"type":"system","subtype":"api_error","timestamp":"%s","error":{"status":529},"retryAttempt":1}\n' "$1"; }
SYS() { printf '{"type":"system","subtype":"info","content":"x"}\n'; }
rows() { cut -f2- | tr '\t' '|' | paste -sd';' -; }   # drop the basename, one string per output

# --- marker 1: cut-mid-stream (the demo QA's isMeta entry): stalled, start = last non-marker entry before, end = first assistant after
{ U 2026-11-05T00:07:00Z; A 2026-11-05T00:08:06.200Z; CUT 2026-11-05T00:14:49.000Z; A 2026-11-05T00:14:53.900Z; } > "$T/m1.jsonl"
ck marker-cut-mid-stream "stalled|2026-11-05T00:08:06Z|2026-11-05T00:14:53Z|cut-mid-stream" "$(CO_ "$T/m1.jsonl" | rows)"
ck output-basename-first "m1.jsonl" "$(CO_ "$T/m1.jsonl" | cut -f1)"
ck output-five-tab-fields 5 "$(CO_ "$T/m1.jsonl" | awk -F'\t' '{print NF}')"
# --- marker 2: request-interrupted (array and string content), at the end of the file: end open; start is not the notice (F1)
{ U 2026-11-04T23:00:00Z; AT 2026-11-04T23:50:45.512Z t1; UR 2026-11-04T23:50:46.823Z t1; INTA 2026-11-05T00:05:54.064Z; } > "$T/m2a.jsonl"
ck marker-request-interrupted-array "stalled|2026-11-04T23:50:46Z|open|request-interrupted" "$(CO_ "$T/m2a.jsonl" | rows)"
{ U 2026-11-04T23:00:00Z; A 2026-11-04T23:10:00Z; INTS 2026-11-04T23:20:00Z; U 2026-11-04T23:30:00Z continue; A 2026-11-04T23:31:00Z; } > "$T/m2s.jsonl"
ck marker-request-interrupted-string-resumed "stalled|2026-11-04T23:10:00Z|2026-11-04T23:31:00Z|request-interrupted" "$(CO_ "$T/m2s.jsonl" | rows)"
{ U 2026-11-04T23:00:00Z "please grep for [Request interrupted"; A 2026-11-04T23:31:00Z; } > "$T/m2m.jsonl"
ck marker-request-interrupted-only-at-start "" "$(CO_ "$T/m2m.jsonl")"
# --- marker 3: api-error. Flag+field (the demo's sleep), field only, flag only, text only, rate_limit, "You've hit your"
{ U 2026-11-05T00:40:00Z; A 2026-11-05T00:48:37Z; APIE 2026-11-05T01:04:10Z server_error; U 2026-11-05T01:04:28Z continue; A 2026-11-05T01:04:31Z; } > "$T/m3.jsonl"
ck marker-api-error-sleep "interrupted|2026-11-05T00:48:37Z|2026-11-05T01:04:31Z|api-error:server_error" "$(CO_ "$T/m3.jsonl" | rows)"
{ U 2026-11-05T00:40:00Z; A 2026-11-05T00:48:37Z; printf '{"type":"assistant","timestamp":"2026-11-05T01:00:00Z","error":"overloaded_error","message":{"id":"f","content":[{"type":"text","text":"x"}]}}\n'; A 2026-11-05T01:01:00Z; } > "$T/m3f.jsonl"
ck marker-api-error-field-only "interrupted|2026-11-05T00:48:37Z|2026-11-05T01:01:00Z|api-error:overloaded_error" "$(CO_ "$T/m3f.jsonl" | rows)"
# --- I4 (contract ce920d4): the error value reaches the output only when it matches ^[a-z_]+$; any other string reads "other"
i4() { { U 2026-11-05T00:40:00Z; A 2026-11-05T00:48:37Z; printf '{"type":"assistant","timestamp":"2026-11-05T01:00:00Z","error":%s,"message":{"id":"f","content":[{"type":"text","text":"x"}]}}\n' "$1"; A 2026-11-05T01:01:00Z; } > "$T/i4.jsonl"; CO_ "$T/i4.jsonl" | cut -f5; }
ck i4-lower-underscore-kept "api-error:invalid_request_error" "$(i4 '"invalid_request_error"')"
ck i4-uppercase-other "api-error:other" "$(i4 '"Overloaded"')"
ck i4-digits-other "api-error:other" "$(i4 '"error_529"')"
ck i4-space-other "api-error:other" "$(i4 '"server error"')"
ck i4-tab-newline-other "api-error:other" "$(i4 '"a\tb\nc"')"
ck i4-path-secret-other "api-error:other" "$(i4 '"/Users/someone/.env TOKEN=abc"')"
ck i4-empty-string-other "api-error:other" "$(i4 '""')"
ck i4-five-fields-kept 5 "$(i4 '"a\tb\nc"' >/dev/null; CO_ "$T/i4.jsonl" | awk -F'\t' '{print NF}' | paste -sd' ' -)"
{ U 2026-11-05T00:40:00Z; A 2026-11-05T00:48:37Z; printf '{"type":"assistant","timestamp":"2026-11-05T01:00:00Z","isApiErrorMessage":true,"error":{"status":529},"message":{"id":"f","content":[{"type":"text","text":"x"}]}}\n'; A 2026-11-05T01:01:00Z; } > "$T/i4o.jsonl"
ck i4-object-error-other "api-error:other" "$(CO_ "$T/i4o.jsonl" | cut -f5)"
{ U 2026-11-05T00:40:00Z; A 2026-11-05T00:48:37Z; printf '{"type":"assistant","timestamp":"2026-11-05T01:00:00Z","isApiErrorMessage":true,"message":{"id":"f","content":[{"type":"text","text":"Something new"}]}}\n'; A 2026-11-05T01:01:00Z; } > "$T/m3g.jsonl"
ck marker-api-error-flag-only "interrupted|2026-11-05T00:48:37Z|2026-11-05T01:01:00Z|api-error:unknown" "$(CO_ "$T/m3g.jsonl" | rows)"
{ U 2026-11-05T00:40:00Z; A 2026-11-05T00:48:37Z; A 2026-11-05T01:00:00Z f "API Error: Connection error."; A 2026-11-05T01:01:00Z; } > "$T/m3t.jsonl"
ck marker-api-error-text-only "interrupted|2026-11-05T00:48:37Z|2026-11-05T01:01:00Z|api-error:unknown" "$(CO_ "$T/m3t.jsonl" | rows)"
{ U 2026-11-04T22:00:00Z; A 2026-11-04T22:02:06.400Z; APIE 2026-11-04T22:02:10Z rate_limit "You've hit your session limit · resets 11:50pm"; U 2026-11-04T23:49:40Z continue; A 2026-11-04T23:49:48Z; } > "$T/m3r.jsonl"
ck marker-api-error-rate-limit "limits|2026-11-04T22:02:06Z|2026-11-04T23:49:48Z|api-error:rate_limit" "$(CO_ "$T/m3r.jsonl" | rows)"
{ U 2026-11-04T22:00:00Z; A 2026-11-04T22:02:06Z; A 2026-11-04T22:02:10Z f "You’ve hit your weekly limit"; A 2026-11-04T23:49:48Z; } > "$T/m3h.jsonl"
ck marker-hit-your-limit-text-curly "limits|2026-11-04T22:02:06Z|2026-11-04T23:49:48Z|api-error:unknown" "$(CO_ "$T/m3h.jsonl" | rows)"
{ U 2026-11-04T22:00:00Z; A 2026-11-04T22:02:06Z f "The API Error: line is a quote"; A 2026-11-04T23:49:48Z; } > "$T/m3q.jsonl"
ck marker-api-error-only-at-start "" "$(CO_ "$T/m3q.jsonl")"
# --- marker 4: a system entry with an error (Claude Code's retry); system entries without one are ignored (and need no timestamp)
{ U 2026-11-05T01:00:00Z; A 2026-11-05T01:05:00Z; SYS; SYSE 2026-11-05T01:06:00Z; A 2026-11-05T01:07:00Z; } > "$T/m4.jsonl"
ck marker-api-retry "interrupted|2026-11-05T01:05:00Z|2026-11-05T01:07:00Z|api-retry" "$(CO_ "$T/m4.jsonl" | rows)"
# --- strongest kind wins for markers sharing a start; markers sorted, comma-separated
{ U 2026-11-05T01:00:00Z; A 2026-11-05T01:05:00Z; SYSE 2026-11-05T01:06:00Z; CUT 2026-11-05T01:06:30Z; A 2026-11-05T01:07:00Z; } > "$T/sk1.jsonl"
ck strongest-interrupted-over-stalled "interrupted|2026-11-05T01:05:00Z|2026-11-05T01:07:00Z|api-retry,cut-mid-stream" "$(CO_ "$T/sk1.jsonl" | rows)"
{ U 2026-11-05T01:00:00Z; A 2026-11-05T01:05:00Z; INTA 2026-11-05T01:06:00Z; APIE 2026-11-05T01:06:10Z rate_limit "You've hit your limit"; APIE 2026-11-05T01:06:20Z server_error; A 2026-11-05T02:07:00Z; } > "$T/sk2.jsonl"
ck strongest-limits-wins "limits|2026-11-05T01:05:00Z|2026-11-05T02:07:00Z|api-error:rate_limit,api-error:server_error,request-interrupted" "$(CO_ "$T/sk2.jsonl" | rows)"
# --- a marker with no earlier entry starts at its own time; fractions are dropped; lines sorted by start
{ CUT 2026-11-05T01:00:00.999Z; A 2026-11-05T01:00:05.5Z; } > "$T/first.jsonl"
ck marker-first-entry-own-start "stalled|2026-11-05T01:00:00Z|2026-11-05T01:00:05Z|cut-mid-stream" "$(CO_ "$T/first.jsonl" | rows)"
ck several-gaps-sorted "2026-11-05T00:08:06Z 2026-11-05T00:14:53Z 2026-11-05T00:32:26Z" "$( { U 2026-11-05T00:07:00Z; A 2026-11-05T00:08:06Z; CUT 2026-11-05T00:14:49Z; A 2026-11-05T00:14:53Z; CUT 2026-11-05T00:32:17Z; A 2026-11-05T00:32:26Z; CUT 2026-11-05T00:48:14Z; A 2026-11-05T00:48:37Z; } > "$T/three.jsonl"; CO_ "$T/three.jsonl" | cut -f3 | paste -sd' ' -)"
# --- silent gap: a tool result, then the next user/assistant entry is an assistant 600s or more later, no marker between
{ U 2026-11-05T10:00:00Z; AT 2026-11-05T10:00:05Z s; UR 2026-11-05T10:00:06Z s; A 2026-11-05T10:10:06Z; } > "$T/sg600.jsonl"
ck silent-gap-600s "stalled|2026-11-05T10:00:06Z|2026-11-05T10:10:06Z|silent-gap" "$(CO_ "$T/sg600.jsonl" | rows)"
{ U 2026-11-05T10:00:00Z; AT 2026-11-05T10:00:05Z s; UR 2026-11-05T10:00:06Z s; A 2026-11-05T10:10:05Z; } > "$T/sg599.jsonl"
ck silent-gap-599s-none "" "$(CO_ "$T/sg599.jsonl")"
{ U 2026-11-05T10:00:00Z; A 2026-11-05T10:00:05Z f "Done."; U 2026-11-05T12:00:00Z "next"; A 2026-11-05T12:00:05Z; } > "$T/idle.jsonl"
ck idle-after-end-of-turn-none "" "$(CO_ "$T/idle.jsonl")"
{ U 2026-11-05T10:00:00Z; AT 2026-11-05T10:00:05Z s; UR 2026-11-05T10:00:06Z s; U 2026-11-05T11:00:00Z "hello?"; A 2026-11-05T11:00:05Z; } > "$T/sgu.jsonl"
ck silent-gap-needs-assistant-next "" "$(CO_ "$T/sgu.jsonl")"
{ U 2026-11-05T10:00:00Z; AT 2026-11-05T10:00:05Z s; UR 2026-11-05T10:00:06Z s; CUT 2026-11-05T10:15:00Z; A 2026-11-05T10:15:05Z; } > "$T/sgm.jsonl"
ck silent-gap-not-when-marker-between "stalled|2026-11-05T10:00:06Z|2026-11-05T10:15:05Z|cut-mid-stream" "$(CO_ "$T/sgm.jsonl" | rows)"
# --- --sleep-log: a stalled gap turns interrupted when the machine slept at any moment of it; offsets applied (UTC)
# gap: tool result 23:50:46Z, interrupt 00:05:54Z, open (end = last marker time for the test)
SL="$T/sleep.log"
printf '2026-11-05 00:50:45 +0100 Sleep               \n' > "$SL"   # = 23:50:45Z, 1s before the start: last line before start is Sleep (the demo developer)
ck sleep-before-start-interrupted "interrupted|2026-11-04T23:50:46Z|open|request-interrupted" "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | rows)"
printf '2026-11-05 00:50:40 +0100 Sleep\n2026-11-05 00:50:44 +0100 Wake\n' > "$SL"   # slept and woke before the start, awake after
ck awake-throughout-stays-stalled "stalled" "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
printf '2026-11-05 01:00:00 +0100 Sleep\n2026-11-05 07:00:00 +0100 Wake\n' > "$SL"   # Sleep 00:00Z inside [23:50:46Z, 00:05:54Z]
ck sleep-inside-gap-interrupted "interrupted" "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
printf '2026-11-05 01:00:00 +0000 Sleep\n' > "$SL"   # 01:00Z: after the gap, so no
ck sleep-offset-applied "stalled" "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
printf '2026-11-04 18:55:00 -0500 Sleep\n' > "$SL"   # = 23:55Z inside the gap, negative offset
ck sleep-negative-offset "interrupted" "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
printf '2026-11-05 01:00:00 +0100 DarkWake\n2026-11-05 01:00:00 +0100 Sleep reason x\n' > "$SL"   # not exact lines: skipped
ck sleep-nonmatching-lines-skipped "stalled" "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
# a closed stalled gap: sleep inside [start, end]
printf '2026-11-05 01:20:00 +0100 Sleep\n2026-11-05 01:25:00 +0100 Wake\n' > "$SL"   # 00:20Z-00:25Z inside 00:14:53Z-00:32:26Z (second gap of three.jsonl)
ck sleep-closed-gap-only-that-one "stalled interrupted stalled" "$(CO_ --sleep-log "$SL" -- "$T/three.jsonl" | cut -f2 | paste -sd' ' -)"
# a Wake line inside the gap with no Sleep inside, and the last line before the start a Wake: a Wake inside counts on its own
# (contract ce920d4, QA F5 settled: the machine was asleep just before it, even when the log lost the matching Sleep)
printf '2026-11-04 23:00:00 +0000 Wake\n2026-11-04 23:55:00 +0000 Wake\n' > "$SL"
ck sleep-wake-inside-alone-not-asleep interrupted "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
printf '2026-11-04 23:55:00 +0000 Wake\n' > "$SL"   # a rotated head: only the Wake survives
ck sleep-wake-inside-only-line interrupted "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
printf '2026-11-04 23:00:00 +0000 Wake\n2026-11-05 00:30:00 +0000 Wake\n' > "$SL"   # a Wake after the open gap's last marker (00:05:54Z): outside
ck sleep-wake-after-gap-stays-stalled stalled "$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" | cut -f2)"
# limits and interrupted keep their kind; stdin with -
printf '2026-11-04 23:10:00 +0100 Sleep\n' > "$SL"
ck sleep-limits-keeps-kind "limits" "$(CO_ --sleep-log - -- "$T/m3r.jsonl" < "$SL" | cut -f2)"
ck sleep-log-stdin "interrupted" "$(printf '2026-11-05 00:50:45 +0100 Sleep\n' | CO_ --sleep-log - -- "$T/m2a.jsonl" | cut -f2)"
# no pmset text reaches the output: a log full of process names, and a transcript with a secret
printf '2026-11-05 00:00:01 +0100 Assertions  PID 412(secret-proc) Created PreventUserIdleSystemSleep\n2026-11-05 00:50:45 +0100 Sleep\n' > "$SL"
out="$(CO_ --sleep-log "$SL" -- "$T/m2a.jsonl" 2>&1)"; ck sleep-no-pmset-echo 0 "$(printf '%s' "$out" | grep -c 'secret-proc\|PID\|Sleep')"
# the exact filter hansei.md gives, run with a stand-in pmset on PATH, feeds the script: DarkWake and other lines dropped
mkdir -p "$T/bin"; cat > "$T/bin/pmset" <<'EOP'
#!/bin/bash
printf '2026-11-05 00:50:40 +0100 DarkWake            \tDarkWake from Deep Idle [CDNP] : due to SMC.OutboxNotEmpty smc.70070000 wifibt/ Using AC (Charge:93%%) 2 secs\n'
printf '2026-11-05 00:50:45 +0100 Sleep               \tEntering DarkWake state due to '"'"'Sleep Service Back to Sleep'"'"':TCPKeepAlive=active Using AC (Charge:93%%) 15 secs\n'
printf '2026-11-05 00:50:46 +0100 Assertions          \tPID 99(secretd) Created InternalPreventSleep\n'
EOP
chmod +x "$T/bin/pmset"
HAF="$PLUGIN/references/hansei.md"
PF="$(grep -oE "pmset -g log \| awk -F'\\\\t' '[^']+' \| bash \"<plugin root>/scripts/cut-offs.sh\" --sleep-log - -- <transcript>" "$HAF" | head -1)"
ck hansei-filter-found 1 "$([ -n "$PF" ] && echo 1)"
got="$(cd "$T" && PATH="$T/bin:$PATH" eval "$(printf '%s' "$PF" | sed -e "s|<plugin root>|$PLUGIN|" -e 's|<transcript>|m2a.jsonl|')" 2>&1)"
ck hansei-filter-pipeline "m2a.jsonl|interrupted|2026-11-04T23:50:46Z|open|request-interrupted" "$(printf '%s' "$got" | tr '\t' '|')"
ck hansei-filter-drops-darkwake-and-pids "2026-11-05 00:50:45 +0100 Sleep               " "$(PATH="$T/bin:$PATH" eval "$(printf '%s' "$PF" | sed 's/ | bash .*//')")"
# --- --since/--until keep gaps whose first marker lies inside; the start may lie before --since
ck window-first-marker-inside "2026-11-05T00:14:53Z" "$(CO_ --since 2026-11-05T00:20Z --until 2026-11-05T00:40Z -- "$T/three.jsonl" | cut -f3)"
ck window-start-before-since-kept "2026-11-05T00:08:06Z" "$(CO_ --since 2026-11-05T00:14:49Z --until 2026-11-05T00:14:49Z -- "$T/three.jsonl" | cut -f3)"
ck window-seconds-format "" "$(CO_ --since 2026-11-05T00:48:15Z -- "$T/three.jsonl")"
ck window-silent-gap-by-start 1 "$(CO_ --since 2026-11-05T10:00Z --until 2026-11-05T10:01Z -- "$T/sg600.jsonl" | grep -c silent-gap)"
CO_ --since 2026-11-05 -- "$T/m1.jsonl" >/dev/null 2>&1; ck bad-time-exit-2 2 $?
CO_ --sleepy "$T/m1.jsonl" >/dev/null 2>&1; ck unknown-option-exit-2 2 $?
CO_ >/dev/null 2>&1; ck no-file-exit-2 2 $?
CO_ --sleep-log >/dev/null 2>&1; ck sleep-log-no-arg-exit-2 2 $?
# --- exit 3, stdout empty, stderr names the file by basename only
mkdir -p "$T/deep/dir"; { U 2026-11-05T00:00:00Z; printf 'not json\n'; } > "$T/deep/dir/agent-bad.jsonl"
out="$(CO_ "$T/m1.jsonl" "$T/deep/dir/agent-bad.jsonl" 2>"$T/err")"; code=$?
ck exit3-not-json "3||cut-offs: transcript agent-bad.jsonl unreadable" "$code|$out|$(cat "$T/err")"
printf '{"type":"assistant","message":{"id":"x","content":[{"type":"text","text":"hi"}]}}\n' > "$T/deep/dir/agent-nots.jsonl"
out="$(CO_ "$T/m1.jsonl" "$T/deep/dir/agent-nots.jsonl" 2>"$T/err")"; code=$?
ck exit3-missing-timestamp "3||cut-offs: transcript agent-nots.jsonl unreadable" "$code|$out|$(cat "$T/err")"
out="$(CO_ "$T/m1.jsonl" "$T/deep/dir/agent-none.jsonl" 2>"$T/err")"; code=$?
ck exit3-missing-file "3||cut-offs: transcript agent-none.jsonl unreadable" "$code|$out|$(cat "$T/err")"
out="$(CO_ --sleep-log "$T/deep/dir/no.log" -- "$T/m1.jsonl" 2>"$T/err")"; code=$?
ck exit3-sleep-log-unreadable "3||0" "$code|$out|$(grep -c / "$T/err")"
printf '[1,2]\n' > "$T/arr.jsonl"; CO_ "$T/arr.jsonl" >/dev/null 2>&1; ck exit3-non-object-line 3 $?
mkdir -p "$T/adir.jsonl"; CO_ "$T/adir.jsonl" >/dev/null 2>&1; ck exit3-directory 3 $?
# --- exit 4: jq missing
mkdir -p "$T/nojq"; ln -sf "$(command -v basename)" "$T/nojq/basename"; ln -sf "$(command -v cat)" "$T/nojq/cat"
out="$(PATH="$T/nojq" /bin/bash "$CO" "$T/m1.jsonl" 2>"$T/err")"; code=$?
ck exit4-jq-missing "4||cut-offs: jq missing" "$code|$out|$(cat "$T/err")"
# --- empty file and a clean run: no line, exit 0; a file named like an option after --; no message text in the output
: > "$T/empty.jsonl"; out="$(CO_ "$T/empty.jsonl")"; ck empty-file-no-line "0|" "$?|$out"
{ U 2026-11-05T00:00:00Z; A 2026-11-05T00:01:00Z f "Done."; } > "$T/clean.jsonl"; out="$(CO_ "$T/clean.jsonl")"; ck clean-no-line "0|" "$?|$out"
mkdir -p "$T/dd"; cp "$T/m1.jsonl" "$T/dd/-x.jsonl"; ck dash-file-after-dashdash "-x.jsonl" "$(cd "$T/dd" && CO_ -- -x.jsonl | cut -f1)"
{ U 2026-11-05T00:00:00Z "SECRET-qa-123"; A 2026-11-05T00:01:00Z f "SECRET-qa-456"; CUT 2026-11-05T00:20:00Z; A 2026-11-05T00:21:00Z; } > "$T/secret.jsonl"
ck no-message-text-in-output 0 "$(CO_ "$T/secret.jsonl" 2>&1 | grep -c 'SECRET\|cut off')"
# --- several files: lines of each, in argument order
ck several-files "m1.jsonl m2a.jsonl" "$(CO_ "$T/m1.jsonl" "$T/m2a.jsonl" | cut -f1 | paste -sd' ' -)"
# --- the demo QA agent's full shape (a85f55…), without a sleep log: the contract's seven-line table minus the sleep turns
{ U 2026-11-05T00:07:00Z; A 2026-11-05T00:08:06.2Z; CUT 2026-11-05T00:14:49Z; A 2026-11-05T00:14:53Z; CUT 2026-11-05T00:32:17Z; A 2026-11-05T00:32:26Z
  CUT 2026-11-05T00:48:14Z; A 2026-11-05T00:48:37Z; APIE 2026-11-05T01:04:10Z server_error; U 2026-11-05T01:04:28Z continue; A 2026-11-05T01:04:31Z
  AT 2026-11-05T01:05:28Z q; UR 2026-11-05T01:05:29Z q; APIE 2026-11-05T01:21:35Z server_error; A 2026-11-05T01:21:45Z; AT 2026-11-05T01:25:06Z r; UR 2026-11-05T01:25:07Z r; INTA 2026-11-05T01:43:02Z; } > "$T/agent-a85f55.jsonl"
ck demo-qa-shape "stalled|stalled|stalled|interrupted|interrupted|stalled" "$(CO_ "$T/agent-a85f55.jsonl" | cut -f2 | paste -sd'|' -)"
ck demo-qa-shape-starts "00:08:06 00:14:53 00:32:26 00:48:37 01:05:29 01:25:07" "$(CO_ "$T/agent-a85f55.jsonl" | cut -f3 | cut -c12-19 | paste -sd' ' -)"
ck demo-qa-shape-last-open "open" "$(CO_ "$T/agent-a85f55.jsonl" | tail -1 | cut -f4)"

# --- the real demo transcripts, when this machine still has them (cleanupPeriodDays): the contract's worked example
DP="$HOME/.claude/projects/-Users-wimsuenens-Projects-portfolio-factory-sandbox"
DL="$DP/61c45656-95a0-41df-8e1d-1d321cad55d4.jsonl"; DS="$DP/61c45656-95a0-41df-8e1d-1d321cad55d4/subagents"
if [ -r "$DL" ] && [ -r "$DS/agent-a37df3717d6edee1d.jsonl" ] && [ -r "$DS/agent-a85f55ebb2244ed91.jsonl" ]; then
  ck demo-replay-agents-no-sleep-log "stalled|23:50:46Z|open|request-interrupted;stalled|00:08:06Z|00:14:53Z|cut-mid-stream;stalled|00:14:53Z|00:32:26Z|cut-mid-stream;stalled|00:32:26Z|00:48:37Z|cut-mid-stream;interrupted|00:48:37Z|01:04:31Z|api-error:server_error;interrupted|01:05:29Z|01:21:45Z|api-error:server_error;stalled|01:25:07Z|open|request-interrupted" \
    "$(CO_ "$DS/agent-a37df3717d6edee1d.jsonl" "$DS/agent-a85f55ebb2244ed91.jsonl" | sed -E 's/2026-11-0[45]T//g' | rows)"
  ck demo-replay-lead "limits|2026-11-04T22:02:06Z|2026-11-04T23:49:48Z|api-error:rate_limit;interrupted|2026-11-05T01:43:18Z|2026-11-05T06:49:32Z|api-error:server_error" \
    "$(CO_ --since 2026-11-04T21:52Z --until 2026-11-05T07:08Z -- "$DL" | rows)"
  # the night's sleep, as the machine's pmset log showed it (UTC: Sleep 23:50:45Z, next Wake 06:49Z): every stall turns interrupted
  ck demo-replay-with-sleep "interrupted interrupted interrupted interrupted interrupted interrupted interrupted" \
    "$(printf '2026-11-05 00:50:45 +0100 Sleep\n2026-11-05 07:49:00 +0100 Wake\n' | CO_ --sleep-log - -- "$DS/agent-a37df3717d6edee1d.jsonl" "$DS/agent-a85f55ebb2244ed91.jsonl" | cut -f2 | paste -sd' ' -)"
else
  skip demo-replay "factory-sandbox #2 transcripts not on this machine (cleanupPeriodDays)"
fi
done_
