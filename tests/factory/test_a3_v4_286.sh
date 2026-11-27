#!/bin/bash
# #286 AC-B2 (the check's side), AC-C1, AC-C2: a3-check.sh knows v4 (v3 plus four lines) and reads v1 to v3 exactly as on main.
# Written before the build. Contract 286-a3-v4-and-runs sections 2 and 3 fix the four lines, the refusal reasons and the exits.
# Fixture: tests/factory/fixtures/a3/v4-ok.md = v3-ok.md with the marker v4 and the four lines after `not detectable from records`.
. "$(dirname "$0")/lib.sh"
AC="$PLUGIN/scripts/a3-check.sh"; FX="$REPO/tests/factory/fixtures/a3"; A3="$PLUGIN/references/a3.md"
V3="$FX/v3-ok.md"; V4="$FX/v4-ok.md"
c4() { OUT="$(/bin/bash "$AC" "$1" 2>/dev/null)"; RC=$?; }
# sub <key> <new value>: v4-ok with that line's value replaced, into $T/m.md
sub() { awk -v k="- $1: " -v v="$2" 'index($0, k) == 1 { print k v; next } { print }' "$V4" > "$T/m.md"; }
okv() { sub "$1" "$2"; c4 "$T/m.md"; ck "$3" "0 ok v4" "$RC $OUT"; }
refv() { sub "$1" "$2"; c4 "$T/m.md"; ck "$3" "1 refused: $1 ($4)" "$RC $OUT"; }
RTL='- run timing: raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m'

# ---------- AC-C1: a valid v4 passes; v5 is the unknown version now ----------
c4 "$V4"; ck c1-v4-ok "0 ok v4" "$RC $OUT"
# the contract's worked example: the section 2.5 block (series 3.10) in v3-ok with the marker v4
awk 'NR == 1 { print "<!-- factory:a3 v4 -->"; next } { print } /^- not detectable from records:/ {
  print "- run timing: raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m"; print "- discipline: off"
  print "- run compared: none (no run with discipline off in series 3.10)"; print "- guardrails: first-pass yield 1 of 2 items passed first time; rework per item 0, 1 (2 of 2 items)" }' "$V3" > "$T/ex.md"
c4 "$T/ex.md"; ck c1-contract-example-ok "0 ok v4" "$RC $OUT"
# the second block of section 2.5 (AC-B2: a run section without started:)
awk 'index($0, "- run timing: ") == 1 { print "- run timing: not captured (run section has no started: line)"; next }
     index($0, "- run compared: ") == 1 { print "- run compared: none (run timing not captured)"; next }
     index($0, "- guardrails: ") == 1 { print "- guardrails: first-pass yield 1 of 1 items passed first time; rework per item 0 (1 of 1 items)"; next } { print }' "$V4" > "$T/b2.md"
c4 "$T/b2.md"; ck b2-not-captured-block-ok "0 ok v4" "$RC $OUT"
sed '1s/v4/v5/' "$V4" > "$T/m.md"; c4 "$T/m.md"; ck c1-marker-v5-skipped "3 skipped: A3 marker v5 (version not known)" "$RC $OUT"
# with a calibration experiments line, the four go after it and its experiment lines
EXP1='  experiment: row Visual result — before: +1 (4 of 5 slices, band Normal) — to measure: 3 of 3 slices — clean: yes'
awk -v e="$EXP1" '{ print } /^- not detectable from records:/ { print "- calibration experiments: 1"; print e }' "$V4" > "$T/cal.md"
c4 "$T/cal.md"; ck c1-after-calibration-ok "0 ok v4" "$RC $OUT"
awk -v e="$EXP1" '/^- still uncertain:/ { print "- calibration experiments: 1"; print e } { print }' "$V4" > "$T/cal2.md"
c4 "$T/cal2.md"; ck c1-before-calibration-refused 1 "$RC"; ck c1-before-calibration-out-of-order 1 "$([ "$(printf '%s\n' "$OUT" | grep -c '(out of order)$')" -ge 1 ] && echo 1 || echo 0)"

# ---------- AC-C1 controls: each of the four left out, the order, repeated, blank ----------
for k in 'run timing' discipline 'run compared' guardrails; do
  grep -v "^- $k: " "$V4" > "$T/m.md"; c4 "$T/m.md"; ck "c1-missing-$k" "1 refused: $k (missing)" "$RC $OUT"
  awk -v k="- $k: " '{ print } index($0, k) == 1 { print }' "$V4" > "$T/m.md"; c4 "$T/m.md"; ck "c1-repeated-$k" "1 refused: $k (repeated)" "$RC $OUT"
  sub "$k" ""; c4 "$T/m.md"; ck "c1-blank-$k" "1 refused: $k (blank)" "$RC $OUT"
done
awk '/^- run timing: / { r = $0; next } { print } /^- discipline: / { print r }' "$V4" > "$T/m.md"; c4 "$T/m.md"
ck c1-run-timing-and-discipline-swapped "1 refused: discipline (out of order)" "$RC $OUT"
awk '/^- guardrails: / { g = $0; next } /^- run timing: / { print g } { print }' "$V4" > "$T/m.md"; c4 "$T/m.md"
ck c1-guardrails-first-refused 1 "$RC"; ck c1-guardrails-first-out-of-order 1 "$([ "$(printf '%s\n' "$OUT" | grep -c '(out of order)$')" -ge 1 ] && echo 1 || echo 0)"

# ---------- discipline ----------
okv discipline on c1-discipline-on-ok
refv discipline maybe c1-discipline-maybe 'not off or on'
refv discipline Off c1-discipline-capital 'not off or on'
refv discipline 'off (no line)' c1-discipline-with-text 'not off or on'

# ---------- run timing (section 2.1 and the table of section 3) ----------
RT='run timing'
okv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m' c1-rt-measured-ok
okv "$RT" 'raw 0m; adjusted 0m; blocked: person 0m, limits 0m, stalled 0m, interrupted 0m' c1-rt-all-zero-ok
okv "$RT" 'raw 12h05m; adjusted 12h05m; blocked: person 0m, limits 0m, stalled 0m, interrupted 0m' c1-rt-hours-ok
okv "$RT" 'raw 4h00m; adjusted not captured (lite); blocked: person 1h05m, limits 15m, stalled not captured (lite), interrupted not captured (lite)' c1-rt-lite-ok
okv "$RT" 'not captured (run section has no Run waits table)' c1-rt-whole-line-not-captured-ok
okv "$RT" 'not captured (ledger of #42 missing)' c1-rt-ledger-missing-ok
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m' c1-rt-kind-missing 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, interrupted 0m, stalled 0m' c1-rt-kinds-reordered 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted ; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m' c1-rt-blank-slot 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 75m, stalled 0m, interrupted 0m' c1-rt-75m 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h5m, limits 15m, stalled 0m, interrupted 0m' c1-rt-1h5m 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 0h40m, limits 15m, stalled 0m, interrupted 0m' c1-rt-0h40m 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h65m, limits 15m, stalled 0m, interrupted 0m' c1-rt-1h65m 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 05m, limits 15m, stalled 0m, interrupted 0m' c1-rt-leading-zero 'not in its grammar'
refv "$RT" 'raw 4h00m; adjusted 2h40m' c1-rt-no-blocked-part 'not in its grammar'
refv "$RT" 'not captured ()' c1-rt-not-captured-empty 'not in its grammar'
refv "$RT" 'not captured (a reason (with) parentheses)' c1-rt-not-captured-parens 'not in its grammar'
refv "$RT" "not captured ($(printf 'x%.0s' $(seq 1 81)))" c1-rt-not-captured-81-chars 'not in its grammar'
okv "$RT" "not captured ($(printf 'x%.0s' $(seq 1 80)))" c1-rt-not-captured-80-chars-ok
refv "$RT" 'raw 4h00m; adjusted 2h50m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m' c1-rt-adjusted-wrong 'adjusted is not raw less the blocked minutes'
refv "$RT" 'raw 1h00m; adjusted 0m; blocked: person 50m, limits 20m, stalled 0m, interrupted 0m' c1-rt-blocked-exceed-raw 'blocked minutes exceed raw'
refv "$RT" 'raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled not captured (lite), interrupted not captured (lite)' c1-rt-adjusted-measured-while-not-captured 'adjusted measured while a blocked kind is not captured'
refv "$RT" 'raw 4h00m; adjusted not captured (lite); blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m' c1-rt-adjusted-not-captured-while-measured 'adjusted not captured while every blocked kind is measured'
# only the first reason that applies: a grammar fault hides the arithmetic
sub "$RT" 'raw 4h00m; adjusted 9h99m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m'; c4 "$T/m.md"
ck c1-rt-one-reason-only "1 refused: run timing (not in its grammar)" "$RC $OUT"

# ---------- run compared (section 2.3) ----------
RC_='run compared'
okv "$RC_" 'none (run timing not captured)' c1-rc-none-not-captured-ok
okv "$RC_" 'not comparable (release moved from 3.9 to 3.10)' c1-rc-not-comparable-ok
okv "$RC_" 'raw 3h00m (2 of 2 runs), this run 4h00m, difference +1h00m; adjusted 2h50m (2 of 2 runs), this run 2h40m, difference -10m' c1-rc-measured-ok
okv "$RC_" 'raw 4h00m (1 of 1 runs), this run 4h00m, difference 0m; adjusted 2h40m (1 of 1 runs), this run 2h40m, difference 0m' c1-rc-measured-zero-ok
refv "$RC_" 'none (first run)' c1-rc-reason-not-in-table 'reason not in the table'
refv "$RC_" 'none' c1-rc-none-bare 'not in its grammar'
refv "$RC_" 'better than last time' c1-rc-prose 'not in its grammar'
refv "$RC_" 'not comparable (release moved)' c1-rc-not-comparable-without-releases 'not in its grammar'
refv "$RC_" 'raw 3h00m (2 of 2 runs), this run 4h00m, difference +1h00m' c1-rc-measured-half 'not in its grammar'

# ---------- guardrails (section 2.4) ----------
G=guardrails
okv "$G" 'first-pass yield 2 of 3 items passed first time; rework per item 0, 2, 0 (3 of 3 items)' c1-g-contract-example-ok
okv "$G" 'first-pass yield 1 of 3 items passed first time, 1 not captured; rework per item 0, 2 (2 of 3 items, 1 not captured)' c1-g-partly-not-captured-ok
okv "$G" 'first-pass yield not captured (2 of 2 items); rework per item not captured (2 of 2 items)' c1-g-all-not-captured-ok
refv "$G" 'first-pass yield good; rework per item low' c1-g-prose 'not in its grammar'
refv "$G" 'rework per item 0, 1 (2 of 2 items); first-pass yield 1 of 2 items passed first time' c1-g-halves-swapped 'not in its grammar'
refv "$G" 'first-pass yield 1 of 2 items passed first time; rework per item 0, 1 (3 of 3 items)' c1-g-list-count 'rework list does not match its count'

# ---------- the four lines are not part of v1, v2 or v3 ----------
for v in 1 2 3; do
  case $v in 1) src="$FX/v1-ok.md" ;; 2) src="$FX/v2-ok.md" ;; 3) src="$V3" ;; esac
  awk -v l="$RTL" '{ print } /^- (evidence|items counted|not detectable from records): / && !d { print l; print "- discipline: off"; d = 1 }' "$src" > "$T/m.md"
  c4 "$T/m.md"; ck "c1-four-lines-not-part-of-v$v" "1 refused: run timing (not part of v$v)|refused: discipline (not part of v$v)" "$RC $(printf '%s\n' "$OUT" | grep -E '^refused: (run timing|discipline|run compared|guardrails) ' | paste -sd'|' -)"
done

# ---------- AC-C1: v1, v2 and v3 give the same output and exit as on main ----------
# ---------- AC-C2: each v3 refusal, as v4 with the four lines, gives the same refused: lines for the v3 keys ----------
MAINAC="$T/a3-check-main.sh"
git -C "$REPO" show origin/main:plugins/factory/scripts/a3-check.sh > "$MAINAC" 2>/dev/null || : > "$MAINAC"
# mut <name> <file in> <file out>: the v3 refusal fixtures of the suite (test_slice2_loop.sh item 1, test_slice7_calibration.sh, test_a3_check.sh) as edits
mut() {
  case "$1" in
    events-missing) grep -v '^- events:' "$2" ;;
    issues-missing) grep -v '^- issues filed during the run:' "$2" ;;
    notdetectable-missing) grep -v '^- not detectable from records:' "$2" ;;
    events-none-bare) sed -e '/^  event: /d' -e 's/^- events: 2/- events: none/' "$2" ;;
    events-count) sed 's/^- events: 2/- events: 3/' "$2" ;;
    events-cause-missing) sed 's/ — cause: the merge approval was asked after the demo//' "$2" ;;
    events-cause-question) sed 's/ — cause: the merge approval was asked after the demo/ — cause: ?/' "$2" ;;
    waste-missing) grep -v '^- waste: ' "$2" ;;
    waste-repeated) awk '{ print } /^- waste: / { print }' "$2" ;;
    target-grammar) sed 's/^- target: .*/- target: 20 - reached/' "$2" ;;
    target-blank) sed 's/^- target: .*/- target:/' "$2" ;;
    gemba-cite-missing) sed 's/ — evidence: gemba Build #6 row 3$/ — evidence: https:\/\/github.com\/example\/shop\/issues\/6#issuecomment-111/' "$2" ;;
    calibration-count) awk -v e="$EXP1" '{ print } /^- not detectable from records:/ { print "- calibration experiments: 2"; print e }' "$2" ;;
    calibration-none-bare) awk '{ print } /^- not detectable from records:/ { print "- calibration experiments: none" }' "$2" ;;
    baseline-missing) grep -v '^- baseline: ' "$2" ;;
    chain-end-missing) grep -v '^  process item to change: ' "$2" ;;
  esac > "$3"
}
MUTS="events-missing issues-missing notdetectable-missing events-none-bare events-count events-cause-missing events-cause-question waste-missing waste-repeated target-grammar target-blank gemba-cite-missing calibration-count calibration-none-bare baseline-missing chain-end-missing"
if [ -s "$MAINAC" ]; then
  for f in "$FX/v1-ok.md" "$FX/v2-ok.md" "$FX/v2-none.md" "$FX/v2-chain-none.md" "$V3"; do
    ck "c1-same-as-main-$(basename "$f" .md)" "$(/bin/bash "$MAINAC" "$f" 2>&1; echo "rc=$?")" "$(/bin/bash "$AC" "$f" 2>&1; echo "rc=$?")"
  done
  for m in $MUTS; do
    mut "$m" "$V3" "$T/m3.md"
    ck "c1-same-as-main-v3-$m" "$(/bin/bash "$MAINAC" "$T/m3.md" 2>&1; echo "rc=$?")" "$(/bin/bash "$AC" "$T/m3.md" 2>&1; echo "rc=$?")"
  done
else
  skip c1-same-as-main "origin/main not fetched (git fetch origin main)"
fi
for m in $MUTS; do
  mut "$m" "$V3" "$T/m3.md"; c4 "$T/m3.md"; w="$RC $OUT"
  mut "$m" "$V4" "$T/m4.md"; c4 "$T/m4.md"
  ck "c2-v4-same-v3-refusals-$m" "$w" "$RC $(printf '%s\n' "$OUT" | grep -vE '^refused: (run timing|discipline|run compared|guardrails) ')"
  ck "c2-v3-fixture-is-refused-$m" 1 "${w%% *}"
done
# the suite's out-of-order v3 fixture (not detectable moved after baseline) gives `still uncertain (out of order)` as v3; as v4 the four lines then
# sit before `not detectable` in the file, so an order check over all keys flags `run timing` and no longer `still uncertain`.
skip c2-v4-same-v3-refusals-not-detectable-after-baseline "QA-286 open question Q1: AC-C2 and the out-of-order rule disagree on this fixture; lead to decide"

# ---------- the standard text (a3.md): sections 4 to 7 unchanged (AC-C2), the v4 subsection, the check's header ----------
s47() { awk '/^## 4\. / { on = 1 } /^## 8\. / { on = 0 } on'; }
if git -C "$REPO" cat-file -e origin/main:plugins/factory/references/a3.md 2>/dev/null; then
  ck c2-a3-sections-4-to-7-unchanged "$(git -C "$REPO" show origin/main:plugins/factory/references/a3.md | s47 | shasum | cut -d' ' -f1)" "$(s47 < "$A3" | shasum | cut -d' ' -f1)"
else
  skip c2-a3-sections-4-to-7-unchanged "origin/main not fetched"
fi
has c1-a3-v4-subsection "$A3" "### 2.3 The v4 lines: the run's timing"
has c1-a3-v4-how "$A3" 'To write a v4 A3, take the v3 form, change its marker to'
has c1-a3-check-header-ok-v4 "$AC" 'ok v4'
done_
