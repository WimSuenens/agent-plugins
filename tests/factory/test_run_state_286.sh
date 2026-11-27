#!/bin/bash
# #286 AC-B1, AC-B3: the Factory run section's new shape and run-state.sh's three additions (`add-session`, `add-run-wait`, `lead-sessions`).
# Written before the build. Contract 286-run-timing sections 1 and 2 fix the lines, the row format and the exits; section 2.5 is the fixture
# tests/factory/fixtures/run286/run25.md. The checks of `start` that #230 pinned stay in test_lead_gaps_230.sh; here only what is new.
. "$(dirname "$0")/lib.sh"
RS="$PLUGIN/scripts/run-state.sh"; FX="$REPO/tests/factory/fixtures/run286"
CLOSED="$REPO/tests/factory/fixtures/lead230/run-body-146-closed.md"; OLD="$REPO/tests/factory/fixtures/slice4/run-body-destination.md"
SID=0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c; SID2=7f3e9a20-1c4b-4d8e-b6a5-2e9f0c1d3b47
NOW=2026-12-02T09:00:00Z; A3URL="https://example.invalid/issues/146#issuecomment-1"
HDR='| # | Kind | Agent | Start | End | What |'; SEP='|---|---|---|---|---|---|'
sec() { awk '/^## /{ on = ($0 ~ /^## Factory run[ \t]*$/); next } on { print }' "$1"; }
# rs <args...>: sets OUT, RC (stderr dropped)
rs() { OUT="$(bash "$RS" "$@" 2>/dev/null)"; RC=$?; }

# ---------- 2.1 start prints the new shape (AC-B3: the table, exact header, on a replaced section) ----------
rs start "$CLOSED" --a3 "$A3URL" --now "$NOW"; ck start-exit 0 "$RC"; printf '%s\n' "$OUT" > "$T/new.md"
ck start-section-shape "$(printf '%s\n' '' "- started: $NOW" '- step: 0' '- in flight: none' '- FREEZE: none yet' '- lead sessions: none yet' \
  '- closed in this run: none' "- previous run: $A3URL" '- baseline: not yet' '' '### Run waits' '' "$HDR" "$SEP" '')" "$(sec "$T/new.md")"
rs lead-sessions "$T/new.md"; ck start-lead-sessions-field "0 none yet" "$RC $OUT"
ck start-rest-of-body-kept 1 "$(grep -c '^## Decisions so far$' "$T/new.md")"
ck start-no-held-item-column 0 "$(grep -c 'Held item' "$T/new.md")"

# ---------- 2.4 lead-sessions ----------
rs lead-sessions "$FX/run25.md"; ck lead-sessions-one-id "0 $SID" "$RC $OUT"
rs lead-sessions "$OLD"; ck lead-sessions-missing-line-exit-3 3 "$RC"
printf '# x\n\nno section here\n' > "$T/nosec.md"; rs lead-sessions "$T/nosec.md"; ck lead-sessions-no-section-exit-1 1 "$RC"

# ---------- 2.2 add-session ----------
rs add-session "$T/new.md" "$SID"; ck add-session-exit 0 "$RC"; printf '%s\n' "$OUT" > "$T/s1.md"
ck add-session-replaces-none-yet "$SID" "$(bash "$RS" lead-sessions "$T/s1.md" 2>/dev/null)"
rs add-session "$T/s1.md" "$SID2"; printf '%s\n' "$OUT" > "$T/s2.md"
ck add-session-appends "$SID, $SID2" "$(bash "$RS" lead-sessions "$T/s2.md" 2>/dev/null)"
rs add-session "$T/s2.md" "$SID"; ck add-session-known-id-changes-nothing "0 $(cat "$T/s2.md")" "$RC $OUT"
ck add-session-only-that-line-changed "- lead sessions: $SID, $SID2" "$(diff "$T/new.md" "$T/s2.md" | sed -n 's/^> //p')"
# a section without the line: after FREEZE:, else after started:
awk '{print} /^- in flight: none$/ && !d {print "- FREEZE: 1a2b3c4 (3.9.1)"; d=1}' "$OLD" > "$T/withfreeze.md"
rs add-session "$T/withfreeze.md" "$SID"; ck add-session-inserted-after-freeze "- FREEZE: 1a2b3c4 (3.9.1)|- lead sessions: $SID" "$(printf '%s\n' "$OUT" | grep -A1 '^- FREEZE:' | paste -sd'|' -)"
rs add-session "$OLD" "$SID"; ck add-session-inserted-after-started "- started: 2026-11-14T11:30:00Z|- lead sessions: $SID" "$(printf '%s\n' "$OUT" | grep -A1 '^- started:' | head -2 | paste -sd'|' -)"
ck add-session-line-outside-section-untouched 1 "$(printf '%s\n' "$OUT" | grep -c '^started: this line is outside the section and must be ignored$')"
# exits
for bad in 'a b' '../x' '' "$(printf 'x%.0s' $(seq 1 65))" 'id|x'; do rs add-session "$FX/run25.md" "$bad"; ck "add-session-bad-id-[$bad]-exit-2" "2|" "$RC|$OUT"; done
rs add-session "$FX/run25.md" "$(printf 'a%.0s' $(seq 1 64))"; ck add-session-64-chars-ok 0 "$RC"
rs add-session "$T/nosec.md" "$SID"; ck add-session-no-section-exit-1 1 "$RC"
grep -v '^- started: \|^- FREEZE: \|^- lead sessions: ' "$FX/run25.md" > "$T/bare.md"; rs add-session "$T/bare.md" "$SID"; ck add-session-no-freeze-no-started-exit-3 3 "$RC"
printf '# x\n\nFactory run: moved to #278\n' > "$T/moved.md"; rs add-session "$T/moved.md" "$SID"; ck add-session-moved-exit-4 4 "$RC"
awk '{print} /^- baseline: / {print "- A3: https://example.invalid/issues/9#issuecomment-3"}' "$FX/run25.md" > "$T/closedrun.md"
rs add-session "$T/closedrun.md" "$SID2"; ck add-session-closed-run-exit-8 "8|" "$RC|$OUT"

# ---------- 2.3 add-run-wait: the worked example of section 2.5 ----------
R1='| R1 | person | lead | 2026-12-01T10:02Z | 2026-12-01T10:09Z | which slice next? |'
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09:40Z --what "which slice next?"
ck s25-exit 0 "$RC"; printf '%s\n' "$OUT" > "$T/w1.md"
ck s25-table "$(printf '%s\n' "$HDR" "$SEP" "$R1")" "$(grep '^|' "$T/w1.md")"
ck s25-only-the-row-added "$R1" "$(diff "$FX/run25.md" "$T/w1.md" | sed -n 's/^> //p')"
rs add-run-wait "$T/w1.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09:40Z --what "which slice next?"; ck s25-repeat-unchanged "0 $(cat "$T/w1.md")" "$RC $OUT"
rs add-run-wait "$FX/run25.md" --kind andon --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck s25-andon-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$T/closedrun.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck s25-closed-run-exit-8-empty "8|" "$RC|$OUT"
# numbering: R2 next; the largest R number plus one; the same kind and minutes with another text is not added again
rs add-run-wait "$T/w1.md" --kind limits --start 2026-12-01T11:00:59Z --end 2026-12-01T11:30Z --what "found at close: api-error:rate_limit"; printf '%s\n' "$OUT" > "$T/w2.md"
ck b3-second-row-r2 '| R2 | limits | lead | 2026-12-01T11:00Z | 2026-12-01T11:30Z | found at close: api-error:rate_limit |' "$(grep '^| R2 ' "$T/w2.md")"
rs add-run-wait "$T/w2.md" --kind limits --start 2026-12-01T11:00Z --end 2026-12-01T11:30:30Z --what "other text"; ck b3-same-minutes-not-added-again "0 $(cat "$T/w2.md")" "$RC $OUT"
sed 's/^| R2 /| R7 /' "$T/w2.md" > "$T/w7.md"; rs add-run-wait "$T/w7.md" --kind stalled --start 2026-12-01T12:00Z --end 2026-12-01T12:05Z --what "found at close: silent-gap"
ck b3-largest-plus-one 1 "$(printf '%s\n' "$OUT" | grep -c '^| R8 | stalled | lead | 2026-12-01T12:00Z | 2026-12-01T12:05Z | found at close: silent-gap |$')"
for k in person limits stalled interrupted; do rs add-run-wait "$FX/run25.md" --kind "$k" --start 2026-12-01T12:00Z --end 2026-12-01T12:00Z --what x; ck "b3-kind-$k-accepted-end-equal-start" 0 "$RC"; done
# exits 2: a time not in the format, end before start, a bad --what, a missing option
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01 --end 2026-12-01T10:09Z --what x; ck arw-bad-time-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:02:00.500Z --end 2026-12-01T10:09Z --what x; ck arw-fraction-not-in-format-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:09Z --end 2026-12-01T10:02Z --what x; ck arw-end-before-start-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what "a | b"; ck arw-what-with-pipe-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what "$(printf 'a\nb')"; ck arw-what-with-newline-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what ""; ck arw-what-empty-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$FX/run25.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z; ck arw-no-what-exit-2 "2|" "$RC|$OUT"
rs add-run-wait "$T/does-not-exist.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck arw-unreadable-exit-2 2 "$RC"
# exit 3: no table with the exact header (an open run begun under an older release); 1 no section; 4 moved
rs add-run-wait "$OLD" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck arw-no-table-exit-3 "3|" "$RC|$OUT"
sed "s/^| # | Kind | Agent | Start | End | What |\$/| # | Kind | Agent | Start | End | Held item | What |/" "$FX/run25.md" > "$T/badhead.md"
rs add-run-wait "$T/badhead.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck arw-header-not-exact-exit-3 "3|" "$RC|$OUT"
rs add-run-wait "$T/nosec.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck arw-no-section-exit-1 "1|" "$RC|$OUT"
rs add-run-wait "$T/moved.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x; ck arw-moved-exit-4 "4|" "$RC|$OUT"
# a table in another section of the body is not the run's table
{ cat "$FX/run25.md"; printf '\n## Notes\n\n### Run waits\n\n%s\n%s\n' "$HDR" "$SEP"; } > "$T/twotables.md"
rs add-run-wait "$T/twotables.md" --kind person --start 2026-12-01T10:02Z --end 2026-12-01T10:09Z --what x
ck arw-only-the-sections-table "1 1" "$(printf '%s\n' "$OUT" | grep -c '^| R1 ') $(printf '%s\n' "$OUT" | awk '/^## Notes/ {n=1} n && /^\| R1 / {c++} END {print (c ? 0 : 1)}')"

# ---------- AC-B1: started: on every path, and the existing fields read as before ----------
ck b1-template-shape-started "2026-12-01T10:00:00Z" "$(bash "$RS" started "$FX/run.md" 2>/dev/null)"
ck b1-replaced-section-started-is-the-replacement-time "$NOW" "$(bash "$RS" started "$T/new.md" 2>/dev/null)"
# escalation: the section copied unchanged to a map body
{ printf '# Map: escalated\n\n'; awk '/^## Factory run/ {on=1} on && /^## Destination/ {exit} on' "$T/w2.md"; } > "$T/map.md"
ck b1-copied-section-started-unchanged "2026-12-01T10:00:00Z" "$(bash "$RS" started "$T/map.md" 2>/dev/null)"
ck b1-copied-section-keeps-rows "2" "$(grep -c '^| R[0-9]' "$T/map.md")"
# resume: add-session changes no started:
rs add-session "$FX/run25.md" "$SID2"; printf '%s\n' "$OUT" > "$T/resumed.md"
ck b1-resumed-started-unchanged "2026-12-01T10:00:00Z" "$(bash "$RS" started "$T/resumed.md" 2>/dev/null)"
ck fields-read-as-before "9|none|#41 #42|1a2b3c4 (3.10.0)|not yet" "$(for f in step in-flight items freeze baseline; do bash "$RS" "$f" "$FX/run.md" 2>/dev/null; done | paste -sd'|' -)"
ck status-open-with-table "open" "$(bash "$RS" status "$FX/run.md" 2>/dev/null)"
done_
