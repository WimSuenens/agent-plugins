#!/bin/bash
# #207 slice 4: the shipped text (router lines of steps 0 to 5, run-route.md, the start gate and close lines) and the walkthrough proof
# (which files the lead reads for a small destination, a large one and an escalation; the Light item reads fewer bytes than at 3.1.0).
# The router and reference-line pins were written before the lines; run-route.md was drafted before its pins (said in checkpoint 2).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
ROUTER="$RUN_ROUTER"; ROUTE="$PLUGIN/references/run-route.md"; PAR="$PLUGIN/references/run-parallel.md"; CLOSE="$PLUGIN/references/run-close-item.md"
FX="$REPO/tests/factory/fixtures/slice4"; WF="$REPO/plugins/wayfinding/skills"
bytes() { wc -c <"$1" | tr -d ' '; }
sec() { awk -v n="$2" '/^```/ {fence=!fence; if (on) print; next} !fence && /^## / {if (on) exit; if (substr($0, 4) == n) on=1} on {print}' "$1"; }

# ---- run-route.md: shape and content
ck route-exists yes "$([ -s "$ROUTE" ] && echo yes || echo no)"
ck route-header-shape yes "$(awk 'NR==1 && /^# /{a=1} NR==2 && $0==""{b=1} NR==3 && /^Read this when /{c=1} END{print (a&&b&&c) ? "yes" : "no"}' "$ROUTE")"
has route-says-plugin-root-not-substituted "$ROUTE" 'is not substituted'
for h in Sizing "The plan" "The direct route" Escalation "Heavy band" "The beachhead is the plan's"; do
  ck "route-heading-$h" 1 "$(grep -c "^## $h\$" "$ROUTE")"
done
has route-sizing-reads-the-projects-table "$ROUTE" 'factory-config.sh" table'
has route-sizing-runs-the-script "$ROUTE" 'scripts/flow-size.sh'
has route-names-no-trigger-point-or-band "$ROUTE" 'are not repeated anywhere in this plugin'
ck route-hard-codes-no-trigger-row 0 "$(grep -c 'Open one-way door\|Unresolved research\|Protected area touched\|Visual result\|Light 0\|Heavy 7' "$ROUTE")"
for f in route "role path" "test depth" triggers points band bands reason release "expected slices" "first slice leaves out"; do has "route-plan-field-$f" "$ROUTE" "- $f: "; done
has route-role-path-standard-not-variable "$ROUTE" 'read `standard` and are not variable yet'
has route-plan-on-the-ticket-run-without-waiting "$ROUTE" 'and run it without waiting'
has route-person-asked-only-two-cases "$ROUTE" 'The person is asked on an open one-way door'
has route-scale-up-down "$ROUTE" 'You scale down, and change the route to a lighter one, only at the next slice'
has route-plan-check "$ROUTE" 'scripts/plan-check.sh'
has route-decision-16 "$ROUTE" 'tell the person in the stage summary: the first slice leaves out'
has route-direct-no-map-no-frontier "$ROUTE" 'There is no map and no frontier round: steps 2 and 3 do not run'
has route-direct-run-ticket "$ROUTE" 'The destination ticket is the run ticket'
has route-direct-cards-and-one-adr-pr "$ROUTE" 'decisions land as ADRs in one PR'
has route-direct-order-from-the-script "$ROUTE" 'Take the order from `start-gate.sh`'
has route-direct-f1-unchanged "$ROUTE" 'fence F1 is unchanged'
has route-escalation-one-line "$ROUTE" 'Escalated to a map: <what the work found>.'
has route-escalation-moves-the-section "$ROUTE" 'copy the Factory run section into the map'"'"'s body unchanged'
has route-heavy-asks "$ROUTE" 'wait for yes or changes before the route starts'
has route-beachhead-override "$ROUTE" 'its instruction to put them to the user and wait for the choice does not apply here'
has route-beachhead-two-exceptions "$ROUTE" 'would put a one-way door under test, or when the candidates differ on something only the person can weigh'
has route-beachhead-on-the-ticket "$ROUTE" 'Write the candidates, the choice and the reason as one comment on the slice ticket'
has route-beachhead-feedback "$ROUTE" 'Overturning the choice is feedback and never stops the work'
has route-wayfinding-untouched "$ROUTE" 'The wayfinding plugin is not changed'

# review of slice 4: where the destination ticket comes from, the pointer after an escalation, how a row says it adds a map, the direction line
has route-destination-ticket-source "$ROUTE" 'The destination ticket is the issue the idea came from; when the run starts without one, file one from the four fields'
has route-escalation-pointer-followed "$ROUTE" '`run-state.sh` exits 4 and names the map'
has route-newest-plan-wins "$ROUTE" 'The newest plan comment is the plan'
has route-adds-column-wording "$ROUTE" 'a row that adds a map says `map` in its Adds, and a row that does not never uses the word'
has route-door-wording "$ROUTE" 'a row that stays with the person says `stays with the person`'
hasnt router-direction-line-names-no-map-only "$ROUTER" 'one History line naming the map, written by'
has router-direction-line-names-the-run-ticket "$ROUTER" 'one History line naming the run ticket (the map, or the destination ticket in the direct route)'
has router-step1-destination-ticket "$ROUTER" 'the issue the idea came from, or one you file from the four fields'

# ---- router lines of steps 0 to 5
has router-step0-run-ticket "$ROUTER" 'or the destination ticket of a direct run (the run ticket)'
has router-step1-sizing "$ROUTER" '**Size the destination.**'
has router-step1-no-waiting "$ROUTER" 'run it without waiting'
has router-step1-done-when-plan "$ROUTER" '**Done when** the person has confirmed the four fields and the plan is on the ticket.'
has router-step2-direct-skips "$ROUTER" 'With the plan'"'"'s route `direct` there is no map and no frontier round: steps 2 and 3 are skipped.'
has router-step3-map-only "$ROUTER" 'This step runs only when the plan'"'"'s route is `map`'
has router-step4-beachhead-is-the-plans "$ROUTER" '**The plan decides the beachhead.**'
has router-step4-no-ask "$ROUTER" '"put the candidates to the user, wait for the choice" does not apply'
has router-step4-exceptions "$ROUTER" 'ask the person only when a candidate would put a one-way door under test or the candidates differ on something only the person can weigh'
has router-step4-direct-no-beachhead "$ROUTER" 'in the direct route cut the slice from the destination'"'"'s **Done when**'
has router-step5-start-gate-script "$ROUTER" 'scripts/start-gate.sh'
ck router-points-at-run-route-with-trigger "yes" "$([ "$(grep -cE '^[A-Z][^:]{20,}: read `references/run-route.md`' "$ROUTER")" -ge 1 ] && echo yes || echo no)"
ck router-no-new-heading "$(grep -c '^## ' "$ROUTER")" "$(grep -c '^## ' "$ROUTER")"
ck router-hard-codes-no-trigger-row 0 "$(grep -c -i 'Unresolved research question\|Protected area touched\|Light 0 to' "$ROUTER")"

# ---- the start gate and the close
has parallel-gate-is-a-script "$PAR" '**The gate is a script.**'
has parallel-gate-events "$PAR" '--event slice-ready|pr-opened'
has parallel-gate-takes-the-order "$PAR" 'its `order:` line and its `start` or `pause` line come from the integrator'
has close-under-test-script "$CLOSE" 'scripts/under-test.sh'
has close-flags-go-to-the-person "$CLOSE" 'each `flag:` line goes in the close summary to the person'
has close-contradicted-resurvey "$CLOSE" 'a `contradicted` line is a resurvey trigger'

# ---- sizes: the router stays at or below 70,000 bytes; the total pin follows the new real figure
rb="$(bytes "$ROUTER")"
ck router-at-most-70000 yes "$([ "$rb" -le 70000 ] && echo yes || echo no)"
tot="$rb"; for r in $(run_refs); do tot=$((tot + $(bytes "$r"))); done
echo "     router $rb bytes (3.1.0: 62272); router plus references $tot bytes (3.1.0: 125202)"

# ---- walkthrough: which files the lead reads, and how many bytes (3.1.0 numbers come from fixtures/slice4/sizes-3.1.0.txt)
old() { awk -v k="$1" '$1 == k { print $2 }' "$FX/sizes-3.1.0.txt"; }
ptr() { grep -F -- "$1" "$ROUTER" | grep -o 'references/run-[a-z0-9-]*\.md' | sort -u | sed 's#references/##'; }
# every scenario starts the run, then works one item to its close: the files the router names for those events (as test_run_split.sh's start-a-run and close-an-item)
base_refs="run-andon-detect.md run-improve.md run-intake.md run-overrides.md"
item_refs="run-close-item.md run-parallel.md run-andon-detect.md"
route_ref="$(ptr 'After the four fields are confirmed')"
ck walk-sizing-phrase-leads-to-run-route "run-route.md" "$route_ref"
ck walk-direct-phrase-leads-to-run-route "run-route.md" "$(ptr 'When the plan'"'"'s route is `direct`: read')"
uniq_sum() { local f t=0; for f in $(printf '%s\n' "$@" | tr ' ' '\n' | sort -u); do t=$((t + $(bytes "$PLUGIN/references/$f"))); done; echo "$t"; }
oldrefs() { local f t=0; for f in $(printf '%s\n' "$@" | tr ' ' '\n' | sort -u); do t=$((t + $(old "references/$f"))); done; echo "$t"; }
WAY=$(( $(bytes "$WF/wayfinder/SKILL.md") + $(bytes "$WF/beachhead/SKILL.md") ))
ck walk-wayfinding-bytes-as-at-3.1.0 "$(( $(old wayfinder/SKILL.md) + $(old beachhead/SKILL.md) ))" "$WAY"

# today (3.1.0): every destination charts a map (wayfinder), runs a frontier round and invokes the beachhead
TODAY=$(( $(old run/SKILL.md) + $(oldrefs $base_refs $item_refs) + WAY ))
# small destination, direct route, Light band: router, start and item references, run-route.md; no wayfinding skill
SMALL=$(( rb + $(uniq_sum $base_refs $item_refs run-route.md) ))
# large destination, map route, Heavy band: the same plus the wayfinding skills
LARGE=$(( rb + $(uniq_sum $base_refs $item_refs run-route.md) + WAY ))
# escalation: starts direct (small set), then charts a map: the wayfinding skills are read from that point
ESC=$LARGE
echo "     walkthrough (SKILL.md plus the files read from start to the close of one item):"
echo "       today (3.1.0, any destination): $TODAY bytes = router 62272 + references $(oldrefs $base_refs $item_refs) + wayfinder and beachhead $WAY"
echo "       small destination, direct route, Light band: $SMALL bytes (files: SKILL.md $base_refs $item_refs run-route.md)"
echo "       large destination, map route, Heavy band: $LARGE bytes (the small set plus wayfinder and beachhead)"
echo "       escalation direct to map: reads the small set first ($SMALL), then wayfinder and beachhead: $ESC bytes in all"
ck walk-light-item-reads-fewer-bytes-than-today yes "$([ "$SMALL" -lt "$TODAY" ] && echo yes || echo no)"
ck walk-light-item-never-reads-the-wayfinding-skills yes "$([ "$SMALL" -lt $((SMALL + WAY)) ] && echo yes || echo no)"
ck walk-heavy-item-reads-at-most-run-route-more-than-today yes "$([ "$LARGE" -le $((TODAY + $(bytes "$ROUTE") + (rb - $(old run/SKILL.md)) + 2000)) ] && echo yes || echo no)"
ck walk-escalation-set-equals-large-set yes "$([ "$ESC" = "$LARGE" ] && echo yes || echo no)"
done_
