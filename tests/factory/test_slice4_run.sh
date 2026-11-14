#!/bin/bash
# #207 slice 4: item 4 (run identity: run-state.sh, intake.sh and a3-events.sh read the run ticket, map or destination),
# item 6 (start-gate.sh calls the integrator; under-test.sh flags an Under test line that is not confirmed). Written before the scripts.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RS="$PLUGIN/scripts/run-state.sh"; IN="$PLUGIN/scripts/intake.sh"; AE="$PLUGIN/scripts/a3-events.sh"
SG="$PLUGIN/scripts/start-gate.sh"; UT="$PLUGIN/scripts/under-test.sh"
FX="$REPO/tests/factory/fixtures/slice4"; FA="$REPO/tests/factory/fixtures/a3events"
MAPB="$FX/run-body-map.md"; DESB="$FX/run-body-destination.md"
cd "$T" || exit 1

# ---- item 4: one reader of the Factory run section, whichever ticket holds it
for k in map destination; do
  b="$MAPB"; [ "$k" = destination ] && b="$DESB"
  ck "run-state-$k-started-ok" 0 "$(bash "$RS" started "$b" >/dev/null 2>&1; echo $?)"
done
ck run-state-map-started 2026-11-14T09:00:00Z "$(bash "$RS" started "$MAPB")"
ck run-state-destination-started 2026-11-14T11:30:00Z "$(bash "$RS" started "$DESB")"
ck run-state-map-closed "#30 #29" "$(bash "$RS" items "$MAPB")"
ck run-state-destination-closed-none "" "$(bash "$RS" items "$DESB")"
ck run-state-map-closed-raw "#30 https://example.invalid/issues/30#issuecomment-1, #29 https://example.invalid/issues/29#issuecomment-2" "$(bash "$RS" closed "$MAPB")"
ck run-state-map-baseline "#62 4 records, 3m" "$(bash "$RS" baseline "$MAPB")"
ck run-state-destination-baseline "not yet" "$(bash "$RS" baseline "$DESB")"
ck run-state-map-in-flight "#31 (item/31), #32 (item/32)" "$(bash "$RS" in-flight "$MAPB")"
# only the section counts: a `started:` line outside it is never read
ck run-state-ignores-lines-outside-the-section 2026-11-14T11:30:00Z "$(bash "$RS" started "$DESB")"
printf '# no section\n\n- started: 2026-01-01T00:00:00Z\n' >"$T/nosec.md"
bash "$RS" started "$T/nosec.md" >/dev/null 2>&1; ck run-state-no-section-exit 1 $?
printf '## Factory run\n\n- step: 1\n' >"$T/nofield.md"
bash "$RS" started "$T/nofield.md" >/dev/null 2>&1; ck run-state-no-field-exit 3 $?
bash "$RS" colour "$MAPB" >/dev/null 2>&1; ck run-state-unknown-field-exit 2 $?
bash "$RS" started "$T/missing.md" >/dev/null 2>&1; ck run-state-unreadable-exit 2 $?
# review of slice 4: a run that escalated leaves `Factory run: moved to #<map>` on the destination ticket; the reader follows it (exit 4, names the map)
printf '# dest\n\nFactory run: moved to #77\n\n## Notes\n\nx\n' >"$T/moved.md"
out="$(bash "$RS" started "$T/moved.md" 2>&1)"; code=$?
ck run-state-moved-exit 4 "$code"
ck run-state-moved-names-the-map "run-state: the run moved to #77: read the body of #77" "$out"
bash "$IN" filed-since --run-body "$T/moved.md" 2>/dev/null; ck filed-since-moved-exit-2 2 $?
ck run-state-moved-field "#77" "$(bash "$RS" moved "$T/moved.md")"
bash "$RS" moved "$MAPB" >/dev/null 2>&1; ck run-state-moved-none-exit 3 $?
# which ticket is the run ticket
ck run-ticket-direct "#41" "$(bash "$RS" ticket --route direct --destination 41 --map 7)"
ck run-ticket-map "#7" "$(bash "$RS" ticket --route map --destination 41 --map 7)"
ck run-ticket-direct-needs-no-map "#41" "$(bash "$RS" ticket --route direct --destination 41)"
bash "$RS" ticket --route map --destination 41 >/dev/null 2>&1; ck run-ticket-map-needs-map-exit 2 $?
bash "$RS" ticket --route shortcut --destination 41 >/dev/null 2>&1; ck run-ticket-bad-route-exit 2 $?

# intake.sh filed-since --run-body: the start is the run ticket's `started:`; the same issues as the explicit start, for both fixtures
mkdir -p "$T/bin"; cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "issue list" ] && { cat "$STUB_ISSUES"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH" STUB_ISSUES="$FA/issues-window.json"
R="$T/proj"; mkdir -p "$R/docs/agents"; git init -q -b main "$R"; ( cd "$R" && echo r > README && git add -A && git commit -qm init ) >/dev/null
printf '%s\n' '| Label in mattpocock/skills | Label in our tracker | Meaning |' '|---|---|---|' '| `needs-triage` | `needs-triage` | evaluate |' > "$R/docs/agents/triage-labels.md"
cd "$R" || exit 1
printf '## Factory run\n\n- started: 2026-11-12T19:55:27Z\n- step: 5\n' >"$T/map-body-2.md"
printf '# dest\n\n## Factory run\n\n- started: 2026-11-12T19:55:27Z\n- step: 5\n' >"$T/dest-body-2.md"
END=2026-11-13T22:54:00Z
want="$(bash "$IN" filed-since 2026-11-12T19:55:27Z $END --state all | cut -f1 | tr '\n' ' ')"
for k in map dest; do
  ck "filed-since-run-body-$k" "$want" "$(bash "$IN" filed-since --run-body "$T/$k-body-2.md" $END --state all | cut -f1 | tr '\n' ' ')"
done
ck filed-since-run-body-line-names-the-start "new issues since 2026-11-12T19:55:27Z:" "$(bash "$IN" filed-since --run-body "$T/dest-body-2.md" $END --line | cut -c1-38)"
bash "$IN" filed-since --run-body "$T/nosec.md" $END >/dev/null 2>&1; ck filed-since-run-body-without-section-refused 2 $?
bash "$IN" filed-since --run-body "$T/dest-body-2.md" 2026-11-12T19:55:27Z $END >/dev/null 2>&1; ck filed-since-run-body-and-start-refused 2 $?

# a3-events.sh --run-body: the run list comes from the run ticket, whichever it is
out="$(bash "$AE" --run-body "$MAPB")"
ck a3-events-map-run-list "- items closed in this run: #30 #29" "$(printf '%s\n' "$out" | grep '^- items closed')"
out="$(bash "$AE" --run-body "$DESB")"
ck a3-events-destination-run-list "- items closed in this run: none" "$(printf '%s\n' "$out" | grep '^- items closed')"
ck a3-events-without-run-body-unchanged 0 "$(bash "$AE" | grep -c '^- items closed')"
bash "$AE" --run-body "$T/nosec.md" >/dev/null 2>&1; ck a3-events-run-body-without-section-refused 2 $?

# ---- item 6 (b): the start gate calls the integrator
lf() { local n="$1" sh="$2"; shift 2; { echo "# t"; echo; echo "Paths:"; for p in "$@"; do echo "- $p"; done; echo "shared: $sh"; } >"$T/$n"; }
lf c-a.md none "x/"; lf c-b.md none "x/y.md"; lf c-c.md none "z/"; lf c-run.md none "x/"
NOW="2026-11-11T12:00:00Z"
cat >"$T/board.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"1","status":"Ready","ready_since":"2026-11-11T10:00:00Z","contracts":["$T/c-a.md"]},
 {"id":"2","status":"Ready","ready_since":"2026-11-11T11:30:00Z","contracts":["$T/c-b.md"]},
 {"id":"3","status":"Ready","ready_since":"2026-11-11T09:00:00Z","contracts":["$T/c-c.md"],"depends_on":["1"]},
 {"id":"4","status":"Running","contracts":["$T/c-run.md"]}]}
JSON
printf 'factory-state: 2\n\n## Run budget\n\nrun-budget: none\n' >"$T/f-nobudget.md"
printf 'factory-state: 2\n\n## Run budget\n\nrun-budget: 100 tokens\n' >"$T/f-budget.md"
gate() { out="$(bash "$SG" --board "$T/board.json" --factory "$1" --slice "$2" --event "$3" --spent "${4:-0}" 2>&1)"; code=$?; }
gate "$T/f-nobudget.md" 3 slice-ready
ck gate-prints-the-integrators-order "yes" "$(printf '%s\n' "$out" | grep -q '^order: ' && echo yes || echo no)"
ck gate-order-is-the-integrators "$(bash "$PLUGIN/scripts/integrator.sh" plan "$T/board.json" | grep '^order: ')" "$(printf '%s\n' "$out" | grep '^order: ')"
ck gate-prints-the-event "event: slice-ready" "$(printf '%s\n' "$out" | grep '^event: ')"
ck gate-path-overlap-comes-from-the-script "gate: stay 1 -- $(bash "$PLUGIN/scripts/integrator.sh" plan "$T/board.json" | sed -n 's/^pause 1 -- //p')" "$(gate "$T/f-nobudget.md" 1 slice-ready; printf '%s\n' "$out" | grep '^gate: ')"
ck gate-overlap-exit 1 "$code"
gate "$T/f-nobudget.md" 2 pr-opened
ck gate-pr-opened-overlap-stays "gate: stay 2 -- $(bash "$PLUGIN/scripts/integrator.sh" plan "$T/board.json" | sed -n 's/^pause 2 -- //p')" "$(printf '%s\n' "$out" | grep '^gate: ')"
# a slice the plan starts passes
jq '.slices |= map(select(.id != "4"))' "$T/board.json" >"$T/board2.json"
out="$(bash "$SG" --board "$T/board2.json" --factory "$T/f-nobudget.md" --slice 1 --event slice-ready)"; code=$?
ck gate-start-exit 0 "$code"
ck gate-start-line "gate: start 1" "$(printf '%s\n' "$out" | grep '^gate: ' | cut -c1-13)"
# the budget part still holds: reached means stay, whatever the integrator says
out="$(bash "$SG" --board "$T/board2.json" --factory "$T/f-budget.md" --slice 1 --event slice-ready --spent 100)"; code=$?
ck gate-budget-reached-exit 1 "$code"
ck gate-budget-reached-line "gate: stay 1 -- budget reached" "$(printf '%s\n' "$out" | grep '^gate: ')"
ck gate-budget-line "budget: reached" "$(printf '%s\n' "$out" | grep '^budget: ')"
out="$(bash "$SG" --board "$T/board2.json" --factory "$T/f-budget.md" --slice 1 --event slice-ready --spent 99)"; ck gate-budget-not-reached "budget: ok" "$(printf '%s\n' "$out" | grep '^budget: ')"
bash "$SG" --board "$T/board2.json" --factory "$T/f-nobudget.md" --slice 9 --event slice-ready >/dev/null 2>&1; ck gate-unknown-slice-exit 2 $?
bash "$SG" --board "$T/board2.json" --factory "$T/f-nobudget.md" --slice 2 --event lunch >/dev/null 2>&1; ck gate-unknown-event-exit 2 $?
bash "$SG" --board "$T/nope.json" --factory "$T/f-nobudget.md" --slice 2 --event slice-ready >/dev/null 2>&1; ck gate-unreadable-board-exit 2 $?

# ---- review: the gate leaves no temp file behind
ck gate-no-temp-file 0 "$(grep -c 'start-gate\.\$\$' "$SG")"

# ---- item 6 (a): an Under test line that is not confirmed is flagged at close
cat >"$T/frame.md" <<'F'
## Question

Does it work?

## Under test

- [The rows carry the band](https://example.invalid/1) — the band is missing from a row
- [The route is recorded](https://example.invalid/2) — a ticket has no route
- [Escalation is one line](https://example.invalid/3) — the person has to ask

## Deliberately faked

- nothing
F
rec() { cat >"$T/rec.md" <<R
<!-- factory:hansei v5 -->
6. fpy: x
7. doors: per-line list below
   - The rows carry the band: $1
   - The route is recorded: $2
   - Escalation is one line: $3
R
}
rec confirmed confirmed confirmed
out="$(bash "$UT" "$T/frame.md" "$T/rec.md")"; code=$?
ck under-test-all-confirmed-exit 0 "$code"
ck under-test-all-confirmed-says "under-test: 3 of 3 confirmed" "$(printf '%s\n' "$out" | tail -1)"
rec confirmed "not exercised" confirmed
out="$(bash "$UT" "$T/frame.md" "$T/rec.md")"; code=$?
ck under-test-not-exercised-flagged-exit 1 "$code"
ck under-test-not-exercised-flag "flag: The route is recorded: not exercised -- confirm it or say why it could not be observed" "$(printf '%s\n' "$out" | grep '^flag: ')"
rec contradicted confirmed confirmed
out="$(bash "$UT" "$T/frame.md" "$T/rec.md")"; code=$?
ck under-test-contradicted-flag "flag: The rows carry the band: contradicted -- resurvey the map" "$(printf '%s\n' "$out" | grep '^flag: ')"
ck under-test-contradicted-exit 1 "$code"
# pending resurvey, or a line the record does not carry at all, is missing
printf '<!-- factory:hansei v5 -->\n7. doors: pending resurvey\n' >"$T/rec.md"
out="$(bash "$UT" "$T/frame.md" "$T/rec.md")"; code=$?
ck under-test-pending-exit 1 "$code"
ck under-test-pending-flags-every-line 3 "$(printf '%s\n' "$out" | grep -c '^flag: .*: missing -- ')"
rec confirmed confirmed bogus
out="$(bash "$UT" "$T/frame.md" "$T/rec.md")"; ck under-test-bad-state-flag "flag: Escalation is one line: missing -- no line of the record says confirmed, contradicted or not exercised for it" "$(printf '%s\n' "$out" | grep '^flag: ')"
# review of slice 4: only measure 7 counts, not a same-named line elsewhere in the record
printf '<!-- factory:hansei v5 -->\n3. rework: x\n   - The rows carry the band: confirmed\n7. doors: per-line list below\n   - The rows carry the band: not exercised\n   - The route is recorded: confirmed\n   - Escalation is one line: confirmed\n8. other: y\n   - Escalation is one line: contradicted\n' >"$T/rec.md"
out="$(bash "$UT" "$T/frame.md" "$T/rec.md")"
ck under-test-scoped-to-measure-7 "flag: The rows carry the band: not exercised -- confirm it or say why it could not be observed" "$(printf '%s\n' "$out" | grep '^flag: ')"
ck under-test-scoped-count "under-test: 2 of 3 confirmed" "$(printf '%s\n' "$out" | tail -1)"
printf '## Question\n\nx\n' >"$T/noframe.md"; rec confirmed confirmed confirmed
bash "$UT" "$T/noframe.md" "$T/rec.md" >/dev/null 2>&1; ck under-test-frame-without-section-exit 2 $?
bash "$UT" "$T/frame.md" "$T/none.md" >/dev/null 2>&1; ck under-test-unreadable-exit 2 $?
done_
