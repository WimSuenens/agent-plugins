#!/bin/bash
# #94 (release 2.3.0): the written rules of the lean extensions, replayed from the contracts' worked examples (lean_replay.py), and the text the
# standard must carry for them. AC-3 to AC-14, AC-17, AC-19. The A3 check itself is test_a3_check.sh. Instruction-following (does the lead tag,
# walk and write the lines as asked) is a scenario read in reviews/qa-94.md, not asserted here; only formats and rules that a script or a safety
# rule needs are pinned as text. Expected values below were written from contracts/94-hansei-lean.md section 6 and contracts/94-a3-v2.md
# sections 3.1 and 3.2 before the build.
. "$(dirname "$0")/lib.sh"
command -v python3 >/dev/null || { echo "skip: python3 missing"; exit 0; }
SK="$PLUGIN/skills/run/SKILL.md"; BA="$PLUGIN/references/baseline.md"; A3="$PLUGIN/references/a3.md"; HA="$PLUGIN/references/hansei.md"
PY="$REPO/tests/factory/lean_replay.py"; FX="$REPO/tests/factory/fixtures/a3"; BFX="$REPO/tests/factory/fixtures/baseline"
fblock() { awk -v h="$2" '/^```/{fence=!fence; if(f&&!fence){exit} next} !fence&&/^#{2,3} /{f=($0==h)} f&&fence{print}' "$1"; }
# a heading's text (fence-aware), up to the next heading of the same or a higher level
hsect() { awk -v h="$2" 'BEGIN{lv=0; while (substr(h, lv+1, 1) == "#") lv++} /^```/{fence=!fence} !fence && /^#+ / {n=0; while (substr($0, n+1, 1) == "#") n++; if (f && n <= lv) exit; if ($0 == h) f=1} f {print}' "$1"; }
rp() { python3 -I "$PY" "$@"; }

# ---------- AC-6: flow efficiency, the percent rule (half up, integer) ----------
for c in '52 404 13%' '162 281 58%' '45 60 75%' '100 100 100%' '0 50 0%' '1 200 1%' '1 8 13%' '1 3 33%' '2 3 67%' '0 0 not captured (total is 0m)'; do
  set -- $c; w=$1; t=$2; shift 2; ck "ac6-pct-$w-of-$t" "$*" "$(rp pct $w $t)"; done

# ---------- AC-7: the per-stage minute rule, replayed on the three worked examples of the contract ----------
ck ac7-item12-per-stage "Requirement 20m / 0m; Contracts and ADRs 11m / 39m; Build 65m / 45m; QA 64m / 4m; Security 0m / 0m; Documentation 1m / 11m; Merge approval 1m / 20m" "$(rp stages $FX/stage/item12.json | sed -n 1p)"
ck ac7-item12-sums-equal-measure-1 "working 162 waiting 119" "$(rp stages $FX/stage/item12.json | sed -n 2p)"
ck ac7-item73-per-stage "Requirement 10m / 0m; Contracts and ADRs 12m / 0m; Build 18m / 0m; QA 6m / 0m; Documentation 4m / 0m; Merge approval 2m / 352m" "$(rp stages $FX/stage/item73.json | sed -n 1p)"
ck ac7-item73-sums-equal-measure-1 "working 52 waiting 352" "$(rp stages $FX/stage/item73.json | sed -n 2p)"
ck ac7-item73-352-waiting-minutes-on-merge-approval-only 1 "$(rp stages $FX/stage/item73.json | sed -n 1p | tr ';' '\n' | grep -c '/ 352m')"
ck ac7-item73-no-other-stage-waits 0 "$(rp stages $FX/stage/item73.json | sed -n 1p | tr ';' '\n' | grep -v 'Merge approval' | grep -vc '/ 0m')"
ck ac7-overlap-per-stage "Build 24m / 11m; QA 10m / 0m; Security 10m / 0m; Merge approval 1m / 4m" "$(rp stages $FX/stage/overlap.json | sed -n 1p)"
ck ac7-overlap-sums "working 45 waiting 15" "$(rp stages $FX/stage/overlap.json | sed -n 2p)"
ck ac7-item73-flow-efficiency "13%" "$(rp pct 52 404)"
ck ac7-item12-flow-efficiency "58%" "$(rp pct 162 281)"
ck ac7-overlap-flow-efficiency "75%" "$(rp pct 45 60)"

# ---------- the record: where the two lines sit, what the standard says about them (AC-6 to AC-9) ----------
LAY="$(fblock "$HA" '### Layout')"; WEX="$(fblock "$HA" '### Worked example')"
subs() { awk '/^1\. lead time: /{f=1; print; next} f && /^2\. first-pass yield/{exit} f{print}'; }
ck ac8-layout-sub-lines "1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>; stalled <dur>; interrupted <dur>; andon <dur>|   - flow efficiency: <pct>%|   - per stage: <stage> <working>m / <waiting>m; …" "$(printf '%s\n' "$LAY" | subs | paste -sd'|' -)"
ck ac8-marker-still-v5 '<!-- factory:hansei v5 -->' "$(printf '%s\n' "$LAY" | sed -n 1p)"
ck ac8-worked-example-marker-still-v5 '<!-- factory:hansei v5 -->' "$(printf '%s\n' "$WEX" | sed -n 1p)"
ck ac9-worked-example-measure-1-line-unchanged "1. lead time: total 4h41m; agent working 2h42m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m; andon 20m" "$(printf '%s\n' "$WEX" | grep '^1\. lead time:')"
ck ac9-worked-example-still-seven-measures "1 2 3 4 5 6 7" "$(printf '%s\n' "$WEX" | grep -E '^[0-9]+\. ' | cut -d. -f1 | paste -sd' ' -)"
ck ac6-worked-example-flow-efficiency "   - flow efficiency: $(rp pct 162 281)" "$(printf '%s\n' "$WEX" | grep '^   - flow efficiency:')"
ck ac7-worked-example-per-stage "   - per stage: $(rp stages $FX/stage/item12.json | sed -n 1p)" "$(printf '%s\n' "$WEX" | grep '^   - per stage:')"
ck ac7-worked-example-sub-lines-directly-under-measure-1 2 "$(printf '%s\n' "$WEX" | subs | grep -c '^   - ')"
# the example's per-stage minutes add up to the record's own measure 1 (agent working 2h42m = 162m, waiting 119m)
ps="$(printf '%s\n' "$WEX" | grep '^   - per stage:' | sed 's/^   - per stage: //')"
ck ac7-worked-example-working-sum-is-agent-working 162 "$(printf '%s\n' "$ps" | tr ';' '\n' | sed -E 's/.* ([0-9]+)m \/ ([0-9]+)m$/\1/' | awk '{s+=$1} END {print s}')"
ck ac7-worked-example-waiting-sum-is-held-waits 119 "$(printf '%s\n' "$ps" | tr ';' '\n' | sed -E 's/.* ([0-9]+)m \/ ([0-9]+)m$/\2/' | awk '{s+=$1} END {print s}')"
# the standard states what is derived, from what, and that nothing is stored
ck ac8-sub-lines-said-derived 1 "$([ "$(grep -i 'derived' "$HA" | grep -ci 'flow efficiency')" -ge 1 ] && echo 1 || echo 0)"
has ac8-versions-paragraph-keeps-v5 "$HA" 'Release 2.3.0 keeps v5'
for r in 'not captured (total is 0m)' 'not captured (agent working not captured)' 'not captured (no task row)' 'not captured (task times not readable)'; do has "ac6-7-standard-names-$r" "$HA" "$r"; done
has ac7-standard-names-merge-approval-stage "$HA" 'Merge approval'
ck ac6-standard-says-half-up 1 "$([ "$(grep -ci 'half up\|half-up' "$HA")" -ge 1 ] && echo 1 || echo 0)"
ck ac8-no-schema-bump-no-v6 0 "$(grep -c 'factory:hansei v6 -->' "$HA" "$SK" "$BA" | awk -F: '{s+=$2} END {print s+0}')"
# header fields: the layout names no new header key (the measure-1 sub-lines are the only change; test_gemba compares the rest with main)
ck ac8-layout-header-keys-unchanged "series|plugin|standard|tooling|context|active overrides|abnormalities|stage-log cross-check|gemba" "$(printf '%s\n' "$LAY" | sed -n '/^## Hansei/,/^### Measures/p' | grep -E '^- [a-z -]+:' | sed -E 's/^- ([a-z -]+):.*/\1/' | paste -sd'|' -)"

# ---------- AC-8: every record fixture of 2.2.0 is read with the same result, with or without the sub-lines ----------
TP="$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md"
fr="$(grep -F -- '- **Find records**' "$TP")"; filt="${fr#*--jq \'}"; filt="${filt%%\'\`. One paginated*}"; filt="${filt//\'\"\$me\"\'/lead-qa}"
mk() { jq -n --rawfile body "$1" '{id: 9131, html_url: "https://example.invalid/shop/issues/131#issuecomment-9131", created_at: "2026-01-02T00:00:00Z", user: {login: "lead-qa"}, body: $body}' | jq -s '.'; }
read_rec() { mk "$1" > "$T/c.json"; jq -c "$filt" "$T/c.json" > "$T/r.jsonl"; python3 -I "$REPO/tests/factory/baseline_replay.py" body "$T/r.jsonl" 1.1.0 - /dev/null; }
for rec in x5v5 x5v4 x5; do
  awk '{print} /^1\. lead time: / {print "   - flow efficiency: 58%"; print "   - per stage: Requirement 20m / 0m; Build 10m / 17m; Merge approval 0m / 0m"}' "$BFX/records/$rec.md" > "$T/with-$rec.md"
  ck "ac8-baseline-reads-$rec-the-same-with-sub-lines" "$(read_rec "$BFX/records/$rec.md")" "$(read_rec "$T/with-$rec.md")"
  ck "ac8-baseline-$rec-sub-lines-were-added" 2 "$(grep -c '^   - \(flow efficiency\|per stage\):' "$T/with-$rec.md")"
done
ck ac8-baseline-reads-something 1 "$([ -n "$(read_rec "$BFX/records/x5v5.md")" ] && echo 1 || echo 0)"
# the baseline text and the A3 measure table do not read the sub-lines (that is #92)
ck ac8-baseline-md-does-not-read-flow-efficiency 0 "$(grep -ci 'flow efficiency\|- per stage:' "$BA")"

# ---------- AC-3, AC-4: the waste count, replayed on the fixtures ----------
W() { rp waste "$FX/waste/$1"; }
ck ac3-three-waits-one-finding-one-untagged-andon "waiting 3, defects 1; untagged 1" "$(W c1-three-waits-one-finding | sed -n 1p)"
ck ac3-andon-kind-wait-and-seen-line-and-touches-not-counted 1 "$(W c1-three-waits-one-finding | wc -l | tr -d ' ')"
ck ac3-tie-goes-in-the-timwoods-order "transport 1, waiting 1, defects 1; untagged none" "$(W c2-tie-order | sed -n 1p)"
ck ac3-bad-tag-counted-nowhere "waiting 1; untagged none" "$(W c3-bad-tag | sed -n 1p)"
ck ac3-bad-tag-named "skipped: W2 (waste tag not in its grammar)" "$(W c3-bad-tag | sed -n 2p)"
ck ac4-2.2.0-ledger-and-andons-valid-unchanged "none (no tagged entry)" "$(W c4-untagged-2.2.0)"
ck ac4-2.2.0-ledger-worked-example-has-no-tag 0 "$(grep -c 'waste:' "$FX/waste/c4-untagged-2.2.0/ledger.md")"
ck ac3-nothing-to-tag "none (no andon or wait in the run's items)" "$(W c5-nothing)"
ck ac3-no-ledger-readable "not captured (no ledger comment readable)" "$(W c6-no-ledger)"
# the fixtures agree with the standard's example of the line
ck ac3-example-line-in-a3-md-section-10 1 "$([ "$(grep -c 'waste: waiting 3, defects 1; untagged 1' "$A3")" -ge 1 ] && echo 1 || echo 0)"
# the standard: the order, the skip line, and that tagging never changes the problem
has ac3-standard-timwoods-order "$A3" 'transport, inventory, motion, waiting, overproduction, over-processing, defects, skills'
has ac3-standard-skip-line "$A3" '(waste tag not in its grammar)'
S4="$(hsect "$A3" '## 4. Rule: the run'"'"'s one problem')"
ck ac3-problem-section-extracted 1 "$([ -n "$S4" ] && echo 1 || echo 0)"
ck ac3-problem-rule-reads-no-tag 0 "$(printf '%s\n' "$S4" | grep -ci 'waste\|tag')"
ck ac3-section-10-exists 1 "$(grep -c '^## 10\. A3 v2' "$A3")"
# AC-4: the three places where a tag is optional
ANDON="$(awk '/^### The comment$/ {f=1} f && /^```$/ {g++; next} f && g==1 {print} g==2 {exit}' "$SK")"
ck ac4-andon-template-last-line "- waste: <type | ->" "$(printf '%s\n' "$ANDON" | grep -v '^$' | tail -1)"
ck ac4-andon-template-carried-on-before-waste "- carried on: <YYYY-MM-DDTHH:MMZ>" "$(printf '%s\n' "$ANDON" | grep -v '^$' | tail -2 | head -1)"
ck ac4-andon-template-marker-still-v1 '<!-- factory:andon v1 -->' "$(printf '%s\n' "$ANDON" | sed -n 1p)"
has ac4-andon-waste-line-is-optional "$SK" 'Optional. A reader that does not know the line ignores it.'
has ac4-findings-table-sixth-column "$HA" '| Role | Round | Id | Severity | Text | Waste |'
has ac4-findings-table-five-columns-stay-valid "$HA" '| Role | Round | Id | Severity | Text |'
ck ac4-kind-2-row-names-waste "1" "$([ "$(grep -i 'Kind 2' "$SK" | grep -c 'Waste')" -ge 1 ] && echo 1 || echo 0)"

# ---------- AC-5: the tagging guide ----------
TG="$(hsect "$HA" '### Tagging waste')"
ck ac5-guide-exists 1 "$([ -n "$TG" ] && echo 1 || echo 0)"
for t in transport inventory motion waiting overproduction over-processing defects skills; do
  ck "ac5-guide-names-$t" 1 "$(printf '%s\n' "$TG" | grep -c "^| \`$t\` |")"
done
ck ac5-guide-has-the-when-column 1 "$(printf '%s\n' "$TG" | grep -c '^| Type | In the factory | Tag it when')"
ck ac5-guide-rows-have-three-cells 8 "$(printf '%s\n' "$TG" | grep '^| `' | awk -F'|' 'NF>=5 && length($3)>5 && length($4)>5 {n++} END {print n+0}')"
ck ac5-guide-says-untagged-is-valid 1 "$([ "$(printf '%s\n' "$TG" | grep -ci 'untagged')" -ge 1 ] && echo 1 || echo 0)"
ck ac5-tagging-guide-is-in-section-1 1 "$(awk '/^## 1\. /{s=1} /^## 2\. /{s=0} s && /^### Tagging waste$/ {n++} END {print n+0}' "$HA")"

# ---------- AC-10, AC-11, AC-12: the target ----------
T() { rp target "$@"; }
ck ac11-down-18-reached "20 — reached" "$(T down 20 18)"
ck ac11-down-25-not-reached "20 — not reached" "$(T down 20 25)"
ck ac11-up-25-reached "20 — reached" "$(T up 20 25)"
ck ac11-up-18-not-reached "20 — not reached" "$(T up 20 18)"
ck ac11-down-equal-is-reached-inclusive "20 — reached" "$(T down 20 20)"
ck ac11-up-equal-is-reached-inclusive "20 — reached" "$(T up 20 20)"
ck ac11-down-zero-target "0 — reached" "$(T down 0 0)"
ck ac11-after-not-captured-is-never-reached "none (after reading not captured)" "$(T down 20 'not captured (no after-item)')"
ck ac11-after-n/a-is-never-reached "none (after reading not captured)" "$(T down 20 'n/a (did not run in any of 2 items)')"
ck ac11-not-comparable-is-never-reached "none (readings not comparable)" "$(T down 20 18 'not comparable (release moved from 1.2 to 1.3)')"
has ac11-standard-says-inclusive "$A3" 'after <= target'
has ac11-standard-says-inclusive-up "$A3" 'after >= target'
has ac11-reason-no-target-set "$A3" '`no target set`'
# the worked example of the standard agrees with the rule: direction down, target 0, after 0
EXA2="$(awk '/^## 3\. Worked example/ {s=1} s && /^```/ {g++; next} s && g==1 {print} g==2 {exit}' "$A3")"
ck ac11-example-target-line "- target: $(T down 0 0)" "$(printf '%s\n' "$EXA2" | grep '^- target:')"
# AC-10: the experiment's override
EXPB="$T/exp.md"; awk '/^The run.s experiment \(`references\/a3.md`, section 5\) carries eight more lines/ {f=1; next} f==1 && /^```/ {f=2; next} f==2 && /^```/ {exit} f==2 {print}' "$SK" > "$EXPB"
ck ac10-target-directly-after-direction "- direction|- target" "$(grep -A1 '^- direction:' "$EXPB" | sed -E 's/^(- [a-z]+):.*/\1/' | paste -sd'|' -)"
ck ac10-skill-never-edited-names-target 1 "$([ "$(grep 'never edited' "$SK" | grep -c 'target')" -ge 1 ] && echo 1 || echo 0)"
ck ac10-a3-md-never-edited-names-target 1 "$([ "$(grep 'never edited' "$A3" | grep -c 'target')" -ge 1 ] && echo 1 || echo 0)"
has ac10-skill-keeps-the-substring "$SK" 'carries eight more lines after `fence check`'
ck ac10-target-is-optional-in-the-standard 1 "$([ "$(grep -i 'target' "$A3" | grep -ci 'optional\|without')" -ge 1 ] && echo 1 || echo 0)"
# AC-12: step 9.3 shows before, target and after
has ac12-step-9-3-shows-target "$SK" 'before, target and after'

# ---------- AC-13, AC-14: the targeted walk (the text; whether the lead does it well is read in reviews/qa-94.md) ----------
TW="$(hsect "$HA" '### The targeted walk')"
ck ac13-targeted-walk-subsection-exists 1 "$([ -n "$TW" ] && echo 1 || echo 0)"
ck ac13-subsection-in-section-6 1 "$(awk '/^## 6\. /{s=1} /^## 7\. /{s=0} s && /^### The targeted walk$/ {n++} END {print n+0}' "$HA")"
ck ac13-says-step-9-2 1 "$([ "$(printf '%s\n' "$TW" | grep -c '9\.2')" -ge 1 ] && echo 1 || echo 0)"
ck ac13-says-at-most-one 1 "$([ "$(printf '%s\n' "$TW" | grep -ci 'at most one\|once per run')" -ge 1 ] && echo 1 || echo 0)"
ck ac13-says-no-andon-no-kind-7 1 "$([ "$(printf '%s\n' "$TW" | grep -ci 'kind 7')" -ge 1 ] && echo 1 || echo 0)"
ck ac13-says-outside-the-measures 1 "$([ "$(printf '%s\n' "$TW" | grep -ci 'measure')" -ge 1 ] && echo 1 || echo 0)"
ck ac13-sample-walk-section-still-there 1 "$(grep -c '^### The line$' "$HA")"
ck ac13-sample-walk-is-still-one-per-item 1 "$([ "$(grep -c 'One walk per item, done at step 8.3a' "$HA")" -ge 1 ] && echo 1 || echo 0)"
has ac14-5-whys-accepts-gemba-evidence "$SK" 'gemba <stage> #<item> row <#>'
has ac14-skill-9-2-names-targeted-walk "$SK" 'The targeted walk'
S92="$(awk '/^## 9\. Close the run/ {s=1} /^## 10\. |^## Context/ {s=0} s' "$SK")"
ck ac17-step-9-2-runs-the-check-script 1 "$([ "$(printf '%s\n' "$S92" | grep -c 'a3-check.sh')" -ge 1 ] && echo 1 || echo 0)"
ck ac17-step-9-2-posts-v2 1 "$([ "$(printf '%s\n' "$S92" | grep -ci 'v2')" -ge 1 ] && echo 1 || echo 0)"
has ac17-a3-md-section-9-runs-the-script "$A3" 'a3-check.sh'
has ac17-v1-found-is-left-as-it-is "$A3" 'left as it is'
has ac15-baseline-reads-v1-or-v2 "$BA" 'an A3 of marker v1 or v2 is read; any other version is skipped and named'
ck ac15-no-tracker-template-bullet-names-v2 0 "$(grep -c 'a3 v2' "$TP")"

# ---------- AC-19: the release: changelog names the four changes; the fingerprints in its last line are the plugin's ----------
if grep -q '^## factory 2.3.0 (#94)' "$REPO/CHANGELOG.md"; then
  CE="$(awk '/^## factory 2.3.0/{f=1;print;next} /^## /{f=0} f' "$REPO/CHANGELOG.md")"
  for n in 87 88 89 90; do ck "ac19-changelog-names-#$n" 1 "$([ "$(printf '%s\n' "$CE" | grep -c "#$n")" -ge 1 ] && echo 1 || echo 0)"; done
  ck ac19-changelog-release-line 1 "$([ "$(printf '%s\n' "$CE" | grep -c 'Release: `2.3.0`')" -ge 1 ] && echo 1 || echo 0)"
  ck ac19-changelog-says-minor 1 "$([ "$(printf '%s\n' "$CE" | grep -ci 'minor')" -ge 1 ] && echo 1 || echo 0)"
  ck ac19-changelog-says-unverified 1 "$([ "$(printf '%s\n' "$CE" | grep -ci 'unverified')" -ge 1 ] && echo 1 || echo 0)"
  # the fingerprints are the plugin's now, so they sit in the newest entry (2.8.0, #113); the 2.3.0 entry keeps the ones it had
  CE="$(awk '/^## factory 2.8.0/{f=1;print;next} /^## /{f=0} f' "$REPO/CHANGELOG.md")"
  fpout="$(bash "$PLUGIN/scripts/fingerprint.sh" "$PLUGIN" 2>/dev/null)"
  ck ac19-changelog-has-the-standard-fingerprint 1 "$(printf '%s\n' "$CE" | grep -c "$(printf '%s\n' "$fpout" | sed -n 's/^standard: //p')")"
  ck ac19-changelog-has-the-tooling-fingerprint 1 "$(printf '%s\n' "$CE" | grep -c "$(printf '%s\n' "$fpout" | sed -n 's/^tooling: //p')")"
else skip ac19-changelog-2.3.0 "CHANGELOG.md has no '## factory 2.3.0 (#94)' entry yet (docs-writer, after QA); QA's verification pass requires it"; fi
RB="$REPO/docs/factory/release-runbook.md"
if grep -q '2\.3\.0' "$RB"; then ck ac19-runbook-note-says-no-migration 1 "$([ "$(grep -i '2\.3\.0' "$RB" | grep -ci 'migrat')" -ge 1 ] && echo 1 || echo 0)"
else skip ac19-runbook-2.3.0-note "docs/factory/release-runbook.md has no 2.3.0 note yet (docs-writer)"; fi
ck ac19-tooling-fingerprint-counts-the-new-script 1 "$([ -f "$PLUGIN/scripts/a3-check.sh" ] && echo 1 || echo 0)"
# README and reference.md state the marker the run posts (docs-writer); checked when they have changed
if grep -q 'factory:a3 v2' "$REPO/README.md" "$REPO/docs/factory/reference.md" 2>/dev/null; then ck ac17-docs-say-v2 1 1
else skip ac17-docs-say-v2 "README.md line 158 and docs/factory/reference.md line 84 still state the v1 marker (docs-writer, contract 94-a3-v2 section 0 paths)"; fi
done_
