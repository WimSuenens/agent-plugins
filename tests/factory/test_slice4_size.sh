#!/bin/bash
# #207 slice 4, item 1 and item 2's mechanical part: flow-size.sh (sum, band, steps, route, who is asked) and plan-check.sh (the plan's fields).
# Written before the scripts it tests. The table is a fixture; the script reads it through factory-config.sh table.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
FS="$PLUGIN/scripts/flow-size.sh"
PC="$PLUGIN/scripts/plan-check.sh"
FX="$REPO/tests/factory/fixtures/slice4"
TBL="$FX/factory.md"
cd "$T" || exit 1

size() { out="$(bash "$FS" --table "$TBL" "$@" 2>"$T/err")"; code=$?; }
val() { printf '%s\n' "$out" | sed -n "s/^$1: //p" | head -1; }

# every trigger alone: points, band, route
check1() { # <name> <points> <band> <route>
  size "$1"
  ck "alone-$1-exit" 0 "$code"
  ck "alone-$1-points" "$2" "$(val points)"
  ck "alone-$1-band" "$3" "$(val band)"
  ck "alone-$1-route" "$4" "$(val route)"
}
check1 "Open one-way door" 3 Normal direct
check1 "Unresolved research question" 3 Normal map
check1 "More than 3 expected slices, or dependencies between them" 2 Light map
check1 "Protected area touched" 3 Normal direct
check1 "Contract or interface used by others" 2 Light direct
check1 "New logic or data behaviour in a code project" 2 Light direct
check1 "Visual result" 1 Light direct
check1 "Deploy, pipeline or production config (project row)" 3 Normal direct

# the empty set: the lightest path is zero points
size
ck empty-exit 0 "$code"
ck empty-points 0 "$(val points)"
ck empty-band Light "$(val band)"
ck empty-route direct "$(val route)"
ck empty-triggers "none" "$(val triggers)"
ck empty-person "no question" "$(val person)"

# sums and band edges (Light 0 to 2, Normal 3 to 6, Heavy 7 or more)
size "Visual result" "Contract or interface used by others"; ck sum-3-is-normal "3 Normal" "$(val points) $(val band)"
size "Open one-way door" "Protected area touched"; ck sum-6-normal-edge "6 Normal" "$(val points) $(val band)"
size "Open one-way door" "Protected area touched" "Visual result"; ck sum-7-heavy-edge "7 Heavy" "$(val points) $(val band)"
size "Visual result" "Visual result"; ck a-trigger-counts-once "1 Light" "$(val points) $(val band)"
size "Open one-way door" "Protected area touched" "Contract or interface used by others" "Deploy, pipeline or production config (project row)"
ck sum-all-four-heavy "11 Heavy" "$(val points) $(val band)"
size "Visual result" "New logic or data behaviour in a code project"; ck sum-3-edge-low "3 Normal" "$(val points) $(val band)"

# the steps each fired trigger adds, one line per trigger, in table order
size "Visual result" "Open one-way door"
ck steps-lines "2" "$(printf '%s\n' "$out" | grep -c '^trigger: ')"
ck steps-order-and-text "trigger: Open one-way door +3 -- decision card, ADR (prototype if visual), stays with the person" "$(printf '%s\n' "$out" | grep '^trigger: ' | head -1)"
ck steps-visual "trigger: Visual result +1 -- demo" "$(printf '%s\n' "$out" | grep '^trigger: ' | tail -1)"

# route: a fired row whose Adds say `map` makes the route a map, whichever the band
size "Visual result" "Unresolved research question"; ck route-map-by-research map "$(val route)"
size "Visual result" "More than 3 expected slices, or dependencies between them"; ck route-map-by-slices map "$(val route)"
size "Open one-way door" "Protected area touched" "Visual result"; ck route-direct-in-heavy-without-map-row direct "$(val route)"

# who is asked: the person on an open one-way door (a row that stays with the person) and in the Heavy band; nobody otherwise
size "Open one-way door"; ck person-one-way "one-way door: decision card" "$(val person)"
size "Protected area touched" "Contract or interface used by others" "Visual result" "New logic or data behaviour in a code project"
ck person-heavy-band "Heavy band: ask before running" "$(val person)"
size "Visual result"; ck person-none "no question" "$(val person)"

# review of slice 4: in the Heavy band a fired one-way-door row is still reported next to the Heavy question
size "Open one-way door" "Protected area touched" "Visual result"
ck person-heavy-and-door "Heavy band: ask before running; one-way door: decision card" "$(val person)"

# the bands as recorded at sizing: a change of the boundaries applies to new slices only (the output carries the line it used)
size "Open one-way door" "Visual result"
ck bands-recorded "Light 0 to 2, Normal 3 to 6, Heavy 7 or more" "$(val bands)"
out="$(bash "$FS" --table "$FX/factory-bands2.md" "Open one-way door" "Visual result" 2>&1)"
ck bands2-same-points-other-band "4 Normal Light 0 to 3, Normal 4 to 5, Heavy 6 or more" "$(printf '%s\n' "$out" | sed -n 's/^points: //p') $(printf '%s\n' "$out" | sed -n 's/^band: //p') $(printf '%s\n' "$out" | sed -n 's/^bands: //p')"

# names: a unique case-insensitive prefix works; an unknown or ambiguous trigger is refused (exit 2), and nothing is printed to stdout
size "visual result"; ck name-case-insensitive "1" "$(val points)"
size "Unresolved"; ck name-unique-prefix "3 map" "$(val points) $(val route)"
size "Made-up trigger"; ck unknown-refused-exit 2 "$code"; ck unknown-refused-stdout "" "$out"
ck unknown-refused-message "flow-size: unknown trigger \"Made-up trigger\"" "$(cut -c1-47 "$T/err")"
size "Contract"; ck ambiguous-or-unique-prefix-ok "2" "$(val points)"
size "Open" "Made-up"; ck one-bad-of-two-refused 2 "$code"
bash "$FS" --table "$T/nothing.md" "Visual result" >/dev/null 2>&1; ck missing-table-exit 2 $?
printf 'factory-state: 2\n' >"$T/notable.md"; bash "$FS" --table "$T/notable.md" "Visual result" >/dev/null 2>&1; ck no-table-exit 6 $?
# the plugin names no trigger: the script holds none of the project's trigger names
ck script-names-no-trigger 0 "$(grep -v '^ *#' "$FS" | grep -c -i 'open one-way\|unresolved\|protected area\|visual result' 2>/dev/null)"
ck script-exists yes "$([ -f "$FS" ] && echo yes || echo no)"

# ---- plan-check.sh
plan() { cat >"$T/plan.md" <<'P'
## Plan

- route: direct
- role path: standard
- test depth: standard
- triggers: Open one-way door (+3), Visual result (+1)
- points: 4
- band: Normal
- bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more
- reason: one open door, no research, one slice expected
- release: factory 3.2.0
- expected slices: 1. the shell and the first page; 2. the content pages
- first slice leaves out: the wiki structure of the approved ADR
P
}
plan
out="$(bash "$PC" "$T/plan.md" --table "$TBL" 2>&1)"; code=$?
ck plan-ok-exit 0 "$code"
ck plan-names-leave-out "tell the person in the stage summary: the first slice leaves out: the wiki structure of the approved ADR" "$(printf '%s\n' "$out" | grep '^tell the person')"
sed -i.bak 's/^- first slice leaves out: .*/- first slice leaves out: none/' "$T/plan.md"
out="$(bash "$PC" "$T/plan.md" --table "$TBL" 2>&1)"
ck plan-leave-out-none-says-nothing 0 "$(printf '%s\n' "$out" | grep -c '^tell the person')"
for f in route "role path" "test depth" triggers points band bands reason release "expected slices" "first slice leaves out"; do
  plan; grep -v "^- $f: " "$T/plan.md" >"$T/p2.md"
  out="$(bash "$PC" "$T/p2.md" --table "$TBL" 2>&1)"; code=$?
  ck "plan-missing-$f-refused" "1 missing: $f" "$code $(printf '%s\n' "$out" | head -1)"
done
plan; sed -i.bak 's/^- role path: standard/- role path: light/' "$T/plan.md"; bash "$PC" "$T/plan.md" >/dev/null 2>&1; ck plan-role-path-not-variable-yet 1 $?
plan; sed -i.bak 's/^- test depth: standard/- test depth: targeted/' "$T/plan.md"; bash "$PC" "$T/plan.md" >/dev/null 2>&1; ck plan-test-depth-not-variable-yet 1 $?
plan; sed -i.bak 's/^- route: direct/- route: shortcut/' "$T/plan.md"; bash "$PC" "$T/plan.md" >/dev/null 2>&1; ck plan-bad-route 1 $?
plan; sed -i.bak 's/^- points: 4/- points: 5/' "$T/plan.md"; out="$(bash "$PC" "$T/plan.md" --table "$TBL" 2>&1)"; ck plan-points-must-match-triggers "1 points: plan says 5, its triggers add up to 4" "$? $(printf '%s\n' "$out" | head -1)"
plan; sed -i.bak 's/^- band: Normal/- band: Light/' "$T/plan.md"; out="$(bash "$PC" "$T/plan.md" --table "$TBL" 2>&1)"; ck plan-band-must-match "1 band: plan says Light, the bands line gives Normal" "$? $(printf '%s\n' "$out" | head -1)"
plan; sed -i.bak 's/^- route: direct/- route: map/' "$T/plan.md"; out="$(bash "$PC" "$T/plan.md" --table "$TBL" 2>&1)"; ck plan-route-must-match "1 route: plan says map, the table gives direct" "$? $(printf '%s\n' "$out" | head -1)"
plan; sed -i.bak 's/^- triggers: .*/- triggers: Made-up (+2)/' "$T/plan.md"; bash "$PC" "$T/plan.md" --table "$TBL" >/dev/null 2>&1; ck plan-unknown-trigger 1 $?
# review of slice 4: without --table the plan is checked against docs/agents/factory.md of the project (cwd); no sum-only mode, no made-up table
mkdir -p "$T/pc/docs/agents"; cp "$TBL" "$T/pc/docs/agents/factory.md"; plan
out="$(cd "$T/pc" && bash "$PC" "$T/plan.md" 2>&1)"; code=$?
ck plan-default-table-ok-exit 0 "$code"
plan; sed -i.bak 's/^- triggers: .*/- triggers: Visual result (+9), none-such (+0)/; s/^- points: 4/- points: 9/' "$T/plan.md"
out="$(cd "$T/pc" && bash "$PC" "$T/plan.md" 2>&1)"; code=$?
ck plan-default-table-refuses-invented-trigger "1 triggers: flow-size: unknown trigger \"none-such\"" "$code $(printf '%s\n' "$out" | head -1)"
plan; out="$(cd "$T" && bash "$PC" "$T/plan.md" 2>&1)"; code=$?
ck plan-no-table-at-all-exit 2 "$code"
ck plan-script-makes-no-table-of-its-own 0 "$(grep -c 'mktemp' "$PC")"
# a Heavy plan says the person is asked
cat >"$T/heavy.md" <<'P'
- route: map
- role path: standard
- test depth: standard
- triggers: Open one-way door (+3), Unresolved research question (+3), Visual result (+1)
- points: 7
- band: Heavy
- bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more
- reason: an open door and an unknown
- release: factory 3.2.0
- expected slices: 1. a; 2. b; 3. c; 4. d
- first slice leaves out: none
P
out="$(bash "$PC" "$T/heavy.md" --table "$TBL" 2>&1)"; code=$?
ck heavy-plan-ok "0" "$code"
ck heavy-plan-asks-the-person "ask the person before running: Heavy band" "$(printf '%s\n' "$out" | grep '^ask the person')"
done_
