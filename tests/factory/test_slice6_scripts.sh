#!/bin/bash
# #207 slice 6, items 1 to 4 (scripts): the hansei plan fields, the carry-over comparison, the release-crossed detection and the integrator's per-band measures.
# Written before hansei-plan.sh, plan-check.sh (release, --release) and integrator.sh (measure band) learned them.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PC="$PLUGIN/scripts/plan-check.sh"; HP="$PLUGIN/scripts/hansei-plan.sh"; IN="$PLUGIN/scripts/integrator.sh"
FX="$REPO/tests/factory/fixtures"
cd "$T" || exit 1
TBL="$FX/slice4/factory.md"
CUR="$(bash "$FP" "$PLUGIN" | sed -n 's/^release: //p')"
CURSTD="$(bash "$FP" "$PLUGIN" | sed -n 's/^standard: //p')"
BANDS="Light 0 to 2, Normal 3 to 6, Heavy 7 or more"
# mkplan <file> <release> <triggers> <points> <band> <role path> <depth>
mkplan() { cat >"$1" <<PLAN
## Plan
- route: direct
- role path: $6
- test depth: $7
- triggers: $3
- points: $4
- band: $5
- bands: $BANDS
- reason: a synthetic slice
- release: factory $2
- expected slices: one
- first slice leaves out: none
PLAN
}
TRIG1="Open one-way door (+3), Contract or interface used by others (+2)"
PATH1="product-owner, architect, developer, qa-engineer, runtime-proof"
TRIG2="$TRIG1, Visual result (+1)"
PATH2="product-owner, architect, developer, qa-engineer, runtime-proof"

# ---- item 3: the release the plan was written under against the one running
mkplan same.md "$CUR" "$TRIG1" 5 Normal "$PATH1" targeted
mkplan old.md 3.4.0 "$TRIG1" 5 Normal "$PATH1" targeted
ck plan-same-release same "$(bash "$PC" release same.md "$PLUGIN")"
ck plan-old-release release-crossed "$(bash "$PC" release old.md "$PLUGIN")"
bash "$PC" release old.md "$PLUGIN" >/dev/null; ck release-detect-exit-0 0 $?
# a patch release is not a release change (baseline.md section 6, item 1): only major.minor is compared
mkplan patch.md "${CUR%.*}.99" "$TRIG1" 5 Normal "$PATH1" targeted
ck plan-other-patch-is-same same "$(bash "$PC" release patch.md "$PLUGIN")"
bash "$PC" patch.md --table "$TBL" --release "$PLUGIN" >"$T/o" 2>&1; ck plan-other-patch-checked-as-before-first-line "plan ok" "$(head -1 "$T/o")"
# the known case: a plan written under 3.4.0 holds `role path: standard`
mkplan std340.md 3.4.0 "$TRIG1" 5 Normal standard targeted
bash "$PC" std340.md --table "$TBL" >"$T/o" 2>&1; ck known-case-fails-without-release-flag 1 $?
ck known-case-names-the-path "role path: write the roles that run; the table gives: product-owner, architect, developer, qa-engineer, runtime-proof" "$(head -1 "$T/o")"
bash "$PC" std340.md --table "$TBL" --release "$PLUGIN" >"$T/o" 2>&1; ck known-case-crossed-exit-0 0 $?
ck known-case-crossed-first-line release-crossed "$(head -1 "$T/o")"
ck known-case-crossed-says-what "yes" "$(grep -q '^plan written under factory 3.4.0; running '"$CUR"'$' "$T/o" && echo yes || echo no)"
ck known-case-crossed-no-plan-ok "0" "$(grep -c '^plan ok' "$T/o")"
# a plan under the running release stays an error
mkplan stdnow.md "$CUR" "$TRIG1" 5 Normal standard targeted
bash "$PC" stdnow.md --table "$TBL" --release "$PLUGIN" >"$T/o" 2>&1; ck same-release-standard-still-fails 1 $?
bash "$PC" same.md --table "$TBL" --release "$PLUGIN" >"$T/o" 2>&1; ck same-release-ok-exit 0 $?
ck same-release-ok-first-line "plan ok" "$(head -1 "$T/o")"
# a crossed plan still needs the fields the record reads; the fields a later release added are not required of it
grep -v '^- first slice leaves out:' old.md >old-noleave.md
bash "$PC" old-noleave.md --table "$TBL" --release "$PLUGIN" >"$T/o" 2>&1; ck crossed-later-field-not-required-exit 0 $?
ck crossed-later-field-not-required-text release-crossed "$(head -1 "$T/o")"
grep -v '^- points:' old.md >old-nopoints.md
bash "$PC" old-nopoints.md --table "$TBL" --release "$PLUGIN" >"$T/o" 2>&1; ck crossed-missing-field-exit 1 $?
ck crossed-missing-field-text "missing: points" "$(head -1 "$T/o")"
grep -v '^- release:' old.md >norel.md
bash "$PC" release norel.md "$PLUGIN" >"$T/o" 2>&1; ck release-detect-missing-exit 1 $?
ck release-detect-missing-text "missing: release" "$(head -1 "$T/o")"
bash "$PC" release nonexistent.md "$PLUGIN" >/dev/null 2>&1; ck release-detect-unreadable-exit 2 $?
bash "$PC" release same.md "$T/not-a-plugin" >/dev/null 2>&1; ck release-detect-bad-root-exit 2 $?

# ---- item 1: the hansei plan fields, computed from the plan and the table
mkplan first.md "$CUR" "$TRIG1" 5 Normal "$PATH1" targeted
mkplan latest.md "$CUR" "$TRIG2" 6 Normal "$PATH2" targeted
bash "$HP" fields latest.md --first first.md --table "$TBL" --root "$PLUGIN" >"$T/f" 2>&1; ck fields-exit 0 $?
ck fields-heading "### Plan" "$(sed -n 1p "$T/f")"
ck fields-estimated-points "- estimated points: 5" "$(grep '^- estimated points:' "$T/f")"
ck fields-fired-triggers "- fired triggers: $TRIG1" "$(grep '^- fired triggers:' "$T/f")"
ck fields-band "- band: Normal" "$(grep '^- band:' "$T/f")"
ck fields-route "- route: direct" "$(grep '^- route:' "$T/f")"
ck fields-role-path "- role path: $PATH2" "$(grep '^- role path:' "$T/f")"
ck fields-test-depth "- test depth: targeted" "$(grep '^- test depth:' "$T/f")"
ck fields-actual-triggers "- actual triggers: $TRIG2" "$(grep '^- actual triggers:' "$T/f")"
ck fields-actual-points "- actual points: 6" "$(grep '^- actual points:' "$T/f")"
ck fields-release "- release: same" "$(grep '^- release:' "$T/f")"
ck fields-order "estimated points|fired triggers|band|route|role path|test depth|actual triggers|actual points|release" "$(sed -n 's/^- \([a-z ]*\): .*/\1/p' "$T/f" | paste -sd'|' -)"
# one plan: actual equals estimated
bash "$HP" fields first.md --table "$TBL" --root "$PLUGIN" >"$T/f" 2>&1; ck fields-single-plan-exit 0 $?
ck fields-single-plan-actual "- actual points: 5" "$(grep '^- actual points:' "$T/f")"
# the actual points are the table's sum, not the plan's claim: a plan whose points line is wrong still gets the table's figure
sed 's/^- points: 5/- points: 9/' first.md >lying.md
bash "$HP" fields lying.md --table "$TBL" --root "$PLUGIN" >"$T/f" 2>&1
ck fields-actual-from-table "- actual points: 5" "$(grep '^- actual points:' "$T/f")"
# a trigger that is not a row of the table is refused
sed 's/Visual result (+1)/No such row (+1)/' latest.md >badrow.md
bash "$HP" fields badrow.md --table "$TBL" --root "$PLUGIN" >"$T/f" 2>&1; ck fields-bad-row-exit 1 $?
# a plan from an older release: fields filled, marked, actual points not computed against another table
bash "$HP" fields old.md --table "$TBL" --root "$PLUGIN" >"$T/f" 2>&1; ck fields-crossed-exit 0 $?
ck fields-crossed-release "- release: release crossed (factory 3.4.0 to $CUR)" "$(grep '^- release:' "$T/f")"
ck fields-crossed-actual "- actual points: not captured (release crossed)" "$(grep '^- actual points:' "$T/f")"
ck fields-crossed-keeps-estimate "- estimated points: 5" "$(grep '^- estimated points:' "$T/f")"
# the standard-role-path plan of the known case also gets its record
bash "$HP" fields std340.md --table "$TBL" --root "$PLUGIN" >"$T/f" 2>&1; ck fields-known-case-exit 0 $?
ck fields-known-case-role-path "- role path: standard" "$(grep '^- role path:' "$T/f")"
bash "$HP" fields nonexistent.md --table "$TBL" --root "$PLUGIN" >/dev/null 2>&1; ck fields-unreadable-exit 2 $?

# the check: a record for a slice with a plan holds all the fields
rec() { { echo "<!-- factory:hansei v5 -->"; echo "## Hansei: #12 Export a report as CSV"; echo; echo "### Measures"; echo; echo "1. lead time: total 10m"; echo; cat "$1"; } >"$2"; }
bash "$HP" fields latest.md --first first.md --table "$TBL" --root "$PLUGIN" >sec-full.md
rec sec-full.md rec-full.md
ck check-full-with-plan "ok" "$(bash "$HP" check rec-full.md --plan latest.md)"
bash "$HP" check rec-full.md --plan latest.md >/dev/null; ck check-full-exit 0 $?
for f in "estimated points" "fired triggers" band route "role path" "test depth" "actual triggers" "actual points" release; do
  grep -v "^- $f:" sec-full.md >sec-miss.md; rec sec-miss.md rec-miss.md
  out="$(bash "$HP" check rec-miss.md --plan latest.md)"; code=$?
  ck "check-missing-$f-exit" 1 "$code"
  ck "check-missing-$f-text" "refused: $f (missing)" "$out"
done
sed 's/^- band: Normal/- band: /' sec-full.md >sec-empty.md; rec sec-empty.md rec-empty.md
ck check-empty-value "refused: band (empty)" "$(bash "$HP" check rec-empty.md --plan latest.md)"
sed 's/^- release: same/- release: maybe/' sec-full.md >sec-rel.md; rec sec-rel.md rec-rel.md
ck check-bad-release "refused: release (\"maybe\" is neither same nor release crossed)" "$(bash "$HP" check rec-rel.md --plan latest.md)"
printf '### Plan\n\n- plan: no plan\n' >sec-np.md; rec sec-np.md rec-np.md
ck check-no-plan-section-ok "ok (no plan)" "$(bash "$HP" check rec-np.md --no-plan)"
bash "$HP" check rec-np.md --no-plan >/dev/null; ck check-no-plan-exit 0 $?
out="$(bash "$HP" check rec-np.md --plan latest.md)"; code=$?
ck check-no-plan-but-plan-exists-exit 1 "$code"
ck check-no-plan-but-plan-exists-text "refused: plan (the slice has a plan; the record says no plan)" "$out"
{ echo "<!-- factory:hansei v5 -->"; echo "## Hansei: #3 x"; echo; echo "### Measures"; } >rec-none.md
out="$(bash "$HP" check rec-none.md --no-plan)"; code=$?
ck check-section-missing-exit 1 "$code"
ck check-section-missing-text "refused: plan (section missing)" "$out"
bash "$HP" check nonexistent.md --no-plan >/dev/null 2>&1; ck check-unreadable-exit 2 $?
# the lead must say which: a record checked with neither --plan nor --no-plan is a usage error, so `no plan` cannot pass by omission
bash "$HP" check rec-np.md >/dev/null 2>&1; ck check-needs-plan-or-no-plan-exit 2 $?
bash "$HP" check rec-full.md --plan latest.md --no-plan >/dev/null 2>&1; ck check-both-flags-exit 2 $?
out="$(bash "$HP" check rec-full.md --no-plan)"; code=$?
ck check-fields-but-no-plan-exit 1 "$code"
ck check-fields-but-no-plan-text "refused: plan (the record holds plan fields; the slice has no plan)" "$out"
# the values, not only the presence
vrec() { sed "s|^- $1: .*|- $1: $2|" sec-full.md >sec-v.md; rec sec-v.md rec-v.md; bash "$HP" check rec-v.md --plan latest.md; }
ck check-points-not-a-number "refused: estimated points (\"abc\" is not a whole number)" "$(vrec 'estimated points' abc)"
ck check-route-not-a-route "refused: route (\"sideways\" is neither direct nor map)" "$(vrec route sideways)"
ck check-depth-not-a-depth "refused: test depth (\"deep\" is not proof-only, targeted or full)" "$(vrec 'test depth' deep)"
ck check-actual-not-a-number "refused: actual points (\"x\" is not a whole number or not captured (...))" "$(vrec 'actual points' x)"
ck check-actual-not-captured-ok ok "$(vrec 'actual points' 'not captured (release crossed)')"
# a crossed record passes with its fields filled
bash "$HP" fields old.md --table "$TBL" --root "$PLUGIN" >sec-x.md; rec sec-x.md rec-x.md
ck check-crossed-ok "ok" "$(bash "$HP" check rec-x.md --plan old.md)"

# ---- item 2: the carry-over comparison reads the standard fingerprint through fingerprint.sh
ck carry-unchanged "reference (standard unchanged)" "$(bash "$HP" carry "$CURSTD" "$PLUGIN")"
OLDSTD="0000000000000000000000000000000000000000000000000000000000000000"
ck carry-changed "indicative (standard changed)" "$(bash "$HP" carry "$OLDSTD" "$PLUGIN")"
cp -R "$PLUGIN" "$T/plug-copy"; echo "an edited line" >>"$T/plug-copy/references/hansei.md"
ck carry-edited-standard-is-indicative "indicative (standard changed)" "$(bash "$HP" carry "$CURSTD" "$T/plug-copy")"
cp -R "$PLUGIN" "$T/plug-tool"; echo "# tooling only" >>"$T/plug-tool/scripts/board.sh"
ck carry-tooling-only-stays-reference "reference (standard unchanged)" "$(bash "$HP" carry "$CURSTD" "$T/plug-tool")"
bash "$HP" carry nothex "$PLUGIN" >/dev/null 2>&1; ck carry-bad-hex-exit 2 $?
bash "$HP" carry "$CURSTD" "$T/not-a-plugin" >/dev/null 2>&1; ck carry-bad-root-exit 2 $?

# ---- item 4: the integrator's measures per band
cat >"$T/bands.json" <<'JSON'
{"now":"2026-11-11T12:00:00Z","slices":[
 {"id":"1","status":"Done","band":"Light","lead_minutes":60,"agent_working_minutes":30,"waiting_minutes":30,"role_tasks":3,"rework_rounds":0},
 {"id":"2","status":"Done","band":"Light","lead_minutes":120,"agent_working_minutes":50,"waiting_minutes":70,"role_tasks":5,"rework_rounds":1},
 {"id":"3","status":"Done","band":"Normal","lead_minutes":300,"agent_working_minutes":100,"waiting_minutes":200,"role_tasks":8,"rework_rounds":2},
 {"id":"4","status":"Done","lead_minutes":10},
 {"id":"5","status":"Done","band":"Normal","release_crossed":true,"lead_minutes":999,"agent_working_minutes":1,"waiting_minutes":1,"role_tasks":1,"rework_rounds":9},
 {"id":"6","status":"Running","band":"Heavy","lead_minutes":5}]}
JSON
out="$(bash "$IN" plan "$T/bands.json" 2>&1)"; ck bands-exit 0 $?
ck bands-light "measure band Light n 2 lead-time 1h30m agent-working 0h40m waiting 0h50m role-tasks 4.0 rework 0.5" "$(printf '%s\n' "$out" | grep '^measure band Light ')"
ck bands-normal "measure band Normal n 1 lead-time 5h0m agent-working 1h40m waiting 3h20m role-tasks 8.0 rework 2.0" "$(printf '%s\n' "$out" | grep '^measure band Normal ')"
ck bands-no-plan "measure band no plan n 1 lead-time 0h10m agent-working not captured waiting not captured role-tasks not captured rework not captured" "$(printf '%s\n' "$out" | grep '^measure band no plan ')"
ck bands-crossed-apart "measure band release crossed n 1 lead-time 16h39m agent-working 0h1m waiting 0h1m role-tasks 1.0 rework 9.0" "$(printf '%s\n' "$out" | grep '^measure band release crossed ')"
ck bands-heavy-not-done-no-line 0 "$(printf '%s\n' "$out" | grep -c '^measure band Heavy ')"
ck bands-order "Light|Normal|no plan|release crossed" "$(printf '%s\n' "$out" | grep '^measure band ' | sed -E 's/^measure band (.*) n [0-9]+ .*/\1/' | paste -sd'|' -)"
# the older measures are unchanged
ck bands-older-measure-kept 1 "$(printf '%s\n' "$out" | grep -c '^measure batch-size ')"
# a numeric band is a name; a band named like a synthetic group stays a group of its own
cat >"$T/bands2.json" <<'JSON'
{"now":"2026-11-11T12:00:00Z","slices":[
 {"id":"1","status":"Done","band":2,"lead_minutes":60},
 {"id":"2","status":"Done","band":"no plan","lead_minutes":30},
 {"id":"3","status":"Done","lead_minutes":10}]}
JSON
out2="$(bash "$IN" plan "$T/bands2.json" 2>&1)"
ck bands-numeric-band-named "measure band 2 n 1 lead-time 1h0m agent-working not captured waiting not captured role-tasks not captured rework not captured" "$(printf '%s\n' "$out2" | grep '^measure band 2 ')"
ck bands-name-collision-two-groups 2 "$(printf '%s\n' "$out2" | grep -c '^measure band no plan n 1 ')"
# a board with no Done slice prints no band line
echo '{"now":"2026-11-11T12:00:00Z","slices":[{"id":"1","status":"Ready"}]}' >"$T/nodone.json"
ck bands-none-when-no-done 0 "$(bash "$IN" plan "$T/nodone.json" | grep -c '^measure band ')"
done_
