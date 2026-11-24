#!/bin/bash
# #207 slice 7 (closes #187): calibration.sh (decision 8), the experiment line of the A3 (decision 9) and the escaped-defect loop (decision 10).
# Written before calibration.sh, escaped-defect.sh, the a3-check.sh line and the text they test. All records are synthetic.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
CA="$PLUGIN/scripts/calibration.sh"; ED="$PLUGIN/scripts/escaped-defect.sh"; AC="$PLUGIN/scripts/a3-check.sh"
FX="$REPO/tests/factory/fixtures"; TBL="$FX/slice4/factory.md"; A3F="$FX/a3"
HA="$PLUGIN/references/hansei.md"; A3="$PLUGIN/references/a3.md"; RI="$PLUGIN/references/run-improve.md"
RCI="$PLUGIN/references/run-close-item.md"; RR="$PLUGIN/references/run-route.md"; QA="$PLUGIN/agents/qa-engineer.md"
cd "$T" || exit 1

OWD="Open one-way door"; CON="Contract or interface used by others"; VIS="Visual result"; PRO="Protected area touched"
# mkrec <file> <band> <estimated> <fired> <actual triggers> <actual points> <developer rework> [<release line> [<escaped lines>]]
mkrec() {
  {
    echo "## Hansei: #1 a synthetic slice"; echo
    echo "### Measures"; echo
    echo "3. rework: feedback briefs product-owner 0, architect 0, developer $7, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 0"
    echo "4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)"; echo
    echo "### Plan"; echo
    echo "- estimated points: $3"; echo "- fired triggers: $4"; echo "- band: $2"; echo "- route: direct"
    echo "- role path: developer, qa-engineer, runtime-proof"; echo "- test depth: proof-only"
    echo "- actual triggers: $5"; echo "- actual points: $6"; echo "- release: ${8:-same}"
    if [ -n "${9:-}" ]; then echo; echo "### Escaped defects"; echo; printf '%s\n' "$9"; fi
  } >"$1"
}
cal() { bash "$CA" --table "$TBL" "$@" 2>&1; }

# ---- calibration.sh: medians, per band
for i in 1 2 3 4 5; do mkrec n$i.md Normal 4 "$OWD (+3), $VIS (+1)" "$OWD (+3), $VIS (+1)" 4 0; done
mkrec n1.md Normal 4 "$OWD (+3), $VIS (+1)" "$OWD (+3), $VIS (+1)" 5 0
mkrec n2.md Normal 4 "$OWD (+3), $VIS (+1)" "$OWD (+3), $VIS (+1)" 6 0
mkrec n3.md Normal 4 "$OWD (+3), $VIS (+1)" "$OWD (+3), $VIS (+1)" 5 0
out="$(cal n1.md n2.md n3.md n4.md n5.md)"; rc=$?
ck cal-exit-0 0 "$rc"
echo "$out" | grep -qx 'band Normal: 5 slices; median (actual - estimated) +1' && ck cal-median-per-band 1 1 || ck cal-median-per-band "band Normal: 5 slices; median (actual - estimated) +1" "$out"
mkrec l1.md Light 1 "$VIS (+1)" "$VIS (+1)" 1 0
out="$(cal n1.md l1.md)"
echo "$out" | grep -qx 'band Light: 1 slices; median (actual - estimated) 0' && ck cal-light-band-separate 1 1 || ck cal-light-band-separate "band Light: 1 slices; median (actual - estimated) 0" "$out"
mkrec e1.md Normal 4 none none 4 0; mkrec e2.md Normal 5 none none 8 0
out="$(cal e1.md e2.md)"
echo "$out" | grep -qx 'band Normal: 2 slices; median (actual - estimated) +1.5' && ck cal-even-median "1" 1 || ck cal-even-median "band Normal: 2 slices; median (actual - estimated) +1.5" "$out"

# ---- the last 5 records only; records without the slice-6 fields and release-crossed ones are skipped and counted
for i in 1 2 3 4 5 6 7; do mkrec s$i.md Normal 4 none none 4 0; done
out="$(cal s1.md s2.md s3.md s4.md s5.md s6.md s7.md)"
echo "$out" | grep -qx 'slices read: 5 of 7 given (the last 5)' && ck cal-last-five 1 1 || ck cal-last-five "slices read: 5 of 7 given (the last 5)" "$out"
printf '## Hansei: #2 old\n\n### Measures\n\n3. rework: feedback briefs developer 1\n' >old.md
printf '## Hansei: #3 no plan\n\n### Plan\n\n- plan: no plan\n' >noplan.md
mkrec x.md Normal 4 none none "not captured (release crossed)" 0 "release crossed (factory 3.7.0 to 3.8.0)"
out="$(cal old.md noplan.md x.md n1.md)"
echo "$out" | grep -qx 'skipped: 3 (no plan fields 2, release crossed 1)' && ck cal-skipped-counted 1 1 || ck cal-skipped-counted "skipped: 3 (no plan fields 2, release crossed 1)" "$out"
echo "$out" | grep -qx 'band Normal: 1 slices; median (actual - estimated) +1' && ck cal-skipped-not-in-median 1 1 || ck cal-skipped-not-in-median "band Normal: 1 slices; median (actual - estimated) +1" "$out"
cal >/dev/null; ck cal-no-record-is-usage 2 $?
cal missing.md >/dev/null; ck cal-unreadable-record-is-usage 2 $?
bash "$CA" --table nowhere.md n1.md >/dev/null 2>&1; ck cal-unreadable-table-is-usage 2 $?

# ---- misses and false alarms per row; findings per role and band
for i in 1 2 3; do mkrec m$i.md Normal 3 "$OWD (+3)" "$OWD (+3), $CON (+2)" 5 1; done
mkrec m4.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0; mkrec m5.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0
out="$(cal m1.md m2.md m3.md m4.md m5.md)"
echo "$out" | grep -qx "row $CON: misses 3, false alarms 0" && ck cal-row-misses 1 1 || ck cal-row-misses "row $CON: misses 3, false alarms 0" "$out"
echo "$out" | grep -qx "row $OWD: misses 0, false alarms 0" && ck cal-row-quiet 1 1 || ck cal-row-quiet "row $OWD: misses 0, false alarms 0" "$out"
echo "$out" | grep -qx 'findings: developer in band Normal 3 of 5 slices' && ck cal-findings-share 1 1 || ck cal-findings-share "findings: developer in band Normal 3 of 5 slices" "$out"
for i in 1 2 3; do mkrec f$i.md Normal 4 "$OWD (+3), $VIS (+1)" "$OWD (+3)" 3 0; done
out="$(cal f1.md f2.md f3.md)"
echo "$out" | grep -qx "row $VIS: misses 0, false alarms 3" && ck cal-row-false-alarms 1 1 || ck cal-row-false-alarms "row $VIS: misses 0, false alarms 3" "$out"

# ---- the one proposal: 3 agreeing slices, one row, never the floor, never a settled row
echo "$(cal m1.md m2.md m3.md m4.md m5.md)" | grep -qx "proposal: raise $CON by 1 point (3 of 5 slices missed it); the lead decides, nothing is applied" && ck cal-proposes-raise 1 1 || ck cal-proposes-raise "proposal: raise $CON ..." "$(cal m1.md m2.md m3.md m4.md m5.md | grep proposal)"
echo "$(cal f1.md f2.md f3.md)" | grep -qx "proposal: lower $VIS by 1 point (3 of 3 slices fired it and it did not run); the lead decides, nothing is applied" && ck cal-proposes-lower 1 1 || ck cal-proposes-lower "proposal: lower $VIS ..." "$(cal f1.md f2.md f3.md | grep proposal)"
echo "$(cal m1.md m2.md m4.md m5.md)" | grep -qx 'proposal: none (no row has 3 agreeing slices)' && ck cal-two-is-not-enough 1 1 || ck cal-two-is-not-enough "proposal: none (no row has 3 agreeing slices)" "$(cal m1.md m2.md m4.md m5.md | grep proposal)"
for i in 1 2 3; do mkrec g$i.md Normal 3 "$OWD (+3)" "$OWD (+3), $CON (+2), $VIS (+1)" 6 0; done
ck cal-only-one-proposal 1 "$(cal g1.md g2.md g3.md | grep -c '^proposal:')"
ck cal-one-proposal-is-first-row-in-table-order "proposal: raise $CON by 1 point (3 of 3 slices missed it); the lead decides, nothing is applied" "$(cal g1.md g2.md g3.md | grep '^proposal:')"
for i in 1 2 3; do mkrec p$i.md Normal 3 "$OWD (+3)" "$OWD (+3), $PRO (+3)" 6 0; done
echo "$(cal p1.md p2.md p3.md)" | grep -qx "proposal: none ($PRO is the floor's row and is never changed by calibration)" && ck cal-never-the-floor 1 1 || ck cal-never-the-floor "proposal: none ($PRO is the floor's row ...)" "$(cal p1.md p2.md p3.md | grep proposal)"
sed "s/^\(| $CON .*\)| provisional |$/\1| settled |/" "$TBL" >settled.md
out="$(bash "$CA" --table settled.md m1.md m2.md m3.md m4.md m5.md 2>&1)"
echo "$out" | grep -qx "proposal: none ($CON is settled and no reason to reopen it was given)" && ck cal-settled-row-held 1 1 || ck cal-settled-row-held "proposal: none ($CON is settled ...)" "$(echo "$out" | grep proposal)"
out="$(bash "$CA" --table settled.md --reopen "$CON: the contract rows changed in the last slice" m1.md m2.md m3.md m4.md m5.md 2>&1)"
echo "$out" | grep -q "^proposal: raise $CON by 1 point" && ck cal-settled-row-reopened-with-reason 1 1 || ck cal-settled-row-reopened-with-reason "proposal: raise $CON" "$(echo "$out" | grep proposal)"
bash "$CA" --table settled.md --reopen "$CON:" m1.md >/dev/null 2>&1; ck cal-reopen-needs-a-reason 2 $?
sum="$(shasum -a 256 "$TBL" | cut -d' ' -f1)"; cal m1.md m2.md m3.md >/dev/null
ck cal-never-writes-the-table "$sum" "$(shasum -a 256 "$TBL" | cut -d' ' -f1)"

# ---- settling: the provisional number is 5 slices without a miss or a false alarm
for i in 1 2 3 4 5; do mkrec q$i.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0; done
echo "$(cal q1.md q2.md q3.md q4.md q5.md)" | grep -qx "settle: $OWD (5 slices read, fired in 5, no miss, no false alarm)" && ck cal-settle-candidate 1 1 || ck cal-settle-candidate "settle: $OWD (5 slices read, fired in 5, ...)" "$(cal q1.md q2.md q3.md q4.md q5.md | grep settle)"
echo "$(cal q1.md q2.md q3.md q4.md)" | grep -q '^settle: ' && ck cal-four-slices-settle-nothing "no settle line" "a settle line" || ck cal-four-slices-settle-nothing 1 1
echo "$(cal m1.md m2.md m3.md m4.md m5.md)" | grep -q "^settle: $CON" && ck cal-missed-row-not-settled "no" "yes" || ck cal-missed-row-not-settled 1 1

# ---- escaped-defect signals are read from the records
SIG="- escaped defect: #40 from #7; level integration; row $CON (not fired); regression test tests/a.sh"
SIG2="- escaped defect: #41 from #8; level proof; no trigger fired: row missing; regression test missing"
mkrec d1.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0 same "$SIG"; mkrec d2.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0 same "$SIG2"
out="$(cal d1.md d2.md)"
echo "$out" | grep -qx 'escaped defects: 2 signals; 1 with a regression test; row missing 1' && ck cal-escaped-counted 1 1 || ck cal-escaped-counted "escaped defects: 2 signals; 1 with a regression test; row missing 1" "$out"
echo "$out" | grep -qx "row $CON: misses 1, false alarms 0" && ck cal-escaped-is-a-miss-on-its-row 1 1 || ck cal-escaped-is-a-miss-on-its-row "row $CON: misses 1, false alarms 0" "$out"
for i in 1 2 3; do mkrec dd$i.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0 same "- escaped defect: #5$i from #$i; level unit; row $CON (fired); regression test t.sh"; done
echo "$(cal dd1.md dd2.md dd3.md)" | grep -q "^proposal: raise $CON by 1 point" && ck cal-three-escaped-signals-propose 1 1 || ck cal-three-escaped-signals-propose "proposal: raise $CON" "$(cal dd1.md dd2.md dd3.md | grep proposal)"

# ---- escaped-defect.sh: the signal line and the row it counts against
mkdir -p bin ed; EDD="$T/ed"; cat >bin/gh <<'STUB'
#!/bin/bash
# synthetic gh: `issue view <n> --json ...` prints $EDD/<n>.json
[ "$1 $2" = "issue view" ] && [ -f "$EDD/$3.json" ] && { cat "$EDD/$3.json"; exit 0; }
exit 1
STUB
chmod +x bin/gh; export EDD="$T/ed" PATH="$T/bin:$PATH"
# mkdef <n> <body>; the slice 7 hansei is a comment on #7
mkdef() { jq -n --arg b "$2" --arg c "$3" '{body: $b, comments: [{body: $c}]}' >"$EDD/$1.json"; }
SLICEREC="$(cat n1.md)"
mkdef 7 "slice" "$(printf '<!-- factory:hansei v5 -->\n## Hansei: #7 a synthetic slice\n\n### Plan\n\n- estimated points: 4\n- fired triggers: %s (+3)\n- band: Normal\n- actual triggers: %s (+3), %s (+1)\n- actual points: 4\n- release: same\n' "$OWD" "$OWD" "$VIS")"
mkdef 40 "$(printf 'The export drops a column.\n\nescaped from: #7\nescaped at level: integration\nshould have fired: %s\nregression test: tests/export.sh\n' "$CON")"
out="$(bash "$ED" 40 --table "$TBL" 2>&1)"; rc=$?
ck ed-exit-0 0 "$rc"
ck ed-signal-line-row-not-fired "- escaped defect: #40 from #7; level integration; row $CON (not fired); regression test tests/export.sh" "$(echo "$out" | sed -n 1p)"
ck ed-counts-against "counts against: $CON" "$(echo "$out" | sed -n 2p)"
mkdef 41 "$(printf 'x\n\nescaped from: #7\nescaped at level: unit\nshould have fired: %s\nregression test: tests/v.sh\n' "$VIS")"
ck ed-row-fired-still-counts "- escaped defect: #41 from #7; level unit; row $VIS (fired); regression test tests/v.sh" "$(bash "$ED" 41 --table "$TBL" 2>&1 | sed -n 1p)"
mkdef 42 "$(printf 'x\n\nescaped from: #7\nescaped at level: proof\nshould have fired: none\n')"
out="$(bash "$ED" 42 --table "$TBL" 2>&1)"
ck ed-row-missing-line "- escaped defect: #42 from #7; level proof; no trigger fired: row missing; regression test missing" "$(echo "$out" | sed -n 1p)"
ck ed-row-missing-counts-against "counts against: none (row missing)" "$(echo "$out" | sed -n 2p)"
mkdef 43 "$(printf 'x\n\nescaped from: #7\nescaped at level: unit\nshould have fired: Not a row\n')"
bash "$ED" 43 --table "$TBL" >o 2>&1; ck ed-unknown-row-refused 1 $?
grep -q 'refused: should have fired' o && ck ed-unknown-row-reason 1 1 || ck ed-unknown-row-reason "refused: should have fired" "$(cat o)"
mkdef 44 "$(printf 'x\n\nescaped at level: unit\nshould have fired: none\n')"
bash "$ED" 44 --table "$TBL" >o 2>&1; ck ed-missing-escaped-from-refused 1 $?
mkdef 45 "$(printf 'x\n\nescaped from: #99\nescaped at level: unit\nshould have fired: %s\n' "$VIS")"
ck ed-no-slice-record-says-so "- escaped defect: #45 from #99; level unit; row $VIS (not captured: no hansei record on #99); regression test missing" "$(bash "$ED" 45 --table "$TBL" 2>&1 | sed -n 1p)"
bash "$ED" >/dev/null 2>&1; ck ed-usage 2 $?
bash "$ED" 999 --table "$TBL" >/dev/null 2>&1; ck ed-unreadable-issue 2 $?
# the line it prints is the line calibration.sh reads
bash "$ED" 40 --table "$TBL" | sed -n 1p >sig.txt
mkrec r1.md Normal 3 "$OWD (+3)" "$OWD (+3)" 3 0 same "$(cat sig.txt)"
echo "$(cal r1.md)" | grep -qx "row $CON: misses 1, false alarms 0" && ck ed-line-is-read-by-calibration 1 1 || ck ed-line-is-read-by-calibration "row $CON: misses 1, false alarms 0" "$(cal r1.md)"

# ---- a3-check.sh: the calibration experiments line (a v3 line that may be left out; checked when present)
c3() { OUT="$(bash "$AC" "$1" 2>&1)"; RC=$?; }
EXP1='  experiment: row Visual result — before: +1 (4 of 5 slices, band Normal) — to measure: 3 of 3 slices — clean: yes'
withexp() { # <count> <lines...>: inserts the line after `not detectable from records`
  n="$1"; shift
  LINES="$(printf '%s\n' "$@")" awk -v n="$n" '{print} /^- not detectable from records:/ {print "- calibration experiments: " n; if (ENVIRON["LINES"] != "") print ENVIRON["LINES"]}' "$A3F/v3-ok.md" >"$T/e.md"
}
c3 "$A3F/v3-ok.md"; ck a3-v3-without-the-line-still-ok "0 ok v3" "$RC $OUT"
withexp 1 "$EXP1"; c3 "$T/e.md"; ck a3-experiment-ok "0 ok v3" "$RC $OUT"
withexp 2 "$EXP1" '  experiment: band Light — before: 0 (3 of 3 slices, band Light) — to measure: 1 of 3 slices — clean: no (standard changed)'; c3 "$T/e.md"; ck a3-two-experiments-ok "0 ok v3" "$RC $OUT"
withexp 1 '  experiment: Visual result — before: +1 (4 of 5 slices, band Normal) — to measure: 3 of 3 slices — clean: yes'; c3 "$T/e.md"; ck a3-experiment-names-row-or-band "1 refused: calibration experiments (experiment must name row <name> or band <name>)" "$RC $OUT"
withexp 1 '  experiment: row Visual result — to measure: 3 of 3 slices — clean: yes'; c3 "$T/e.md"; ck a3-experiment-needs-before-reading "1 refused: calibration experiments (experiment without a before reading)" "$RC $OUT"
withexp 1 '  experiment: row Visual result — before: none (no baseline) — to measure: 3 of 3 slices — clean: yes'; c3 "$T/e.md"; ck a3-before-none-refused "1 refused: calibration experiments (experiment without a before reading)" "$RC $OUT"
withexp 1 '  experiment: row Visual result — before: +1 (4 of 5 slices, band Normal) — clean: yes'; c3 "$T/e.md"; ck a3-experiment-needs-slices-to-measure "1 refused: calibration experiments (experiment without the slices still to measure)" "$RC $OUT"
withexp 1 '  experiment: row Visual result — before: +1 (4 of 5 slices, band Normal) — to measure: 4 of 3 slices — clean: yes'; c3 "$T/e.md"; ck a3-to-measure-over-three-refused "1 refused: calibration experiments (experiment without the slices still to measure)" "$RC $OUT"
withexp 1 '  experiment: row Visual result — before: +1 (4 of 5 slices, band Normal) — to measure: 3 of 3 slices'; c3 "$T/e.md"; ck a3-experiment-needs-clean-flag "1 refused: calibration experiments (experiment without clean: yes or no (standard changed))" "$RC $OUT"
withexp 2 "$EXP1"; c3 "$T/e.md"; ck a3-experiment-count-mismatch "1 refused: calibration experiments (count does not match the experiment lines)" "$RC $OUT"
withexp "none (no calibration experiment is open)"; c3 "$T/e.md"; ck a3-experiments-none-with-reason "0 ok v3" "$RC $OUT"
withexp "none"; c3 "$T/e.md"; ck a3-experiments-none-needs-reason "1 refused: calibration experiments (none needs a reason in parentheses)" "$RC $OUT"
withexp 1 "$EXP1"; sed 's/^<!-- factory:a3 v3 -->/<!-- factory:a3 v2 -->/' "$T/e.md" >"$T/e2.md"; c3 "$T/e2.md"
echo "$OUT" | grep -qx 'refused: calibration experiments (not part of v2)' && ck a3-experiment-line-not-in-v2 1 1 || ck a3-experiment-line-not-in-v2 "refused: calibration experiments (not part of v2)" "$OUT"
withexp 1 "$EXP1"; awk '/^- calibration experiments:/ {c=$0; next} {print} /^- baseline:/ {print c}' "$T/e.md" | grep -v '^  experiment:' >"$T/e3.md"; c3 "$T/e3.md"
echo "$OUT" | grep -q 'refused: calibration experiments (out of order)\|refused: still uncertain (out of order)' && ck a3-experiment-order 1 1 || ck a3-experiment-order "an out of order refusal" "$OUT"

# ---- the text (one definition per rule, in the existing references)
has t-hansei-calibration-section "$HA" '### Calibration'
has t-hansei-who-runs-it "$HA" 'The lead runs `calibration.sh` at the hansei'
has t-hansei-change-recorded "$HA" 'a change of the table is recorded in the hansei'
has t-hansei-settled-number "$HA" 'A row turns `settled` after 5 slices'
has t-hansei-settled-provisional "$HA" 'The number 5 is provisional'
has t-hansei-escaped-section "$HA" '### Escaped defects'
has t-hansei-escaped-script "$HA" 'escaped-defect.sh'
has t-a3-experiments-section "$A3" '## 11. Calibration experiments'
has t-a3-experiment-per-row-or-band "$A3" 'A calibration experiment is per row or band'
has t-a3-before-from-baseline-band "$A3" "taken from the baseline's section of the same band"
has t-a3-next-3-slices "$A3" 'measured over the next 3 slices of that band'
has t-a3-per-run-only-reports "$A3" 'The run A3 stays per run and only reports them'
has t-a3-not-clean-on-standard-change "$A3" 'is not clean when the `standard` fingerprint changed'
has t-a3-uses-the-comparison "$A3" 'hansei-plan.sh" carry'
has t-a3-check-names "$A3" '`a3-check.sh` checks that an experiment names its row or band'
has t-improve-points-to-calibration "$RI" 'references/hansei.md'
has t-improve-calibration-experiment "$RI" 'calibration experiment'
has t-route-destination-identifies-the-run "$RR" 'The destination ticket is the run ticket'
has t-close-item-escaped-defect "$RCI" 'regression test at the level where it escaped'
has t-close-item-signal "$RCI" 'escaped-defect.sh'
has t-close-item-row-missing "$RCI" 'no trigger fired: row missing'
has t-qa-escaped-line "$QA" 'regression test at the level where it escaped'
ck t-qa-escaped-line-counted 1 "$(grep -c 'regression test at the level where it escaped' "$QA")"
ck t-one-definition-of-the-settle-number 1 "$(cat "$PLUGIN"/references/*.md "$PLUGIN"/agents/*.md "$PLUGIN"/skills/*/SKILL.md | grep -c 'A row turns `settled` after 5 slices')"
ck t-router-at-most-70000-bytes 1 "$([ "$(wc -c <"$PLUGIN/skills/run/SKILL.md")" -le 70000 ] && echo 1 || echo 0)"
hasnt t-no-home-path-in-new-script "$CA" "/Users/"
done_
