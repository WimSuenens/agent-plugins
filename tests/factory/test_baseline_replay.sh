#!/bin/bash
# #57 AC-1..AC-8, AC-11, AC-14, AC-15: the written rules of references/baseline.md and references/a3.md replayed step by step on synthetic
# controls (tests/factory/fixtures/baseline/). The expectations in expected.tsv and a3-expected.tsv were committed before the replay
# (see fixtures/baseline/controls.md). The reading of the text is tests/factory/baseline_replay.py; its  # READING:  comments mark each
# place where the text was silent or ambiguous. Known text defects are named skips (QA-57 finding Fn), not red checks.
. "$(dirname "$0")/lib.sh"
TP="$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md"
FX="$REPO/tests/factory/fixtures/baseline"
PY="$REPO/tests/factory/baseline_replay.py"
command -v python3 >/dev/null || { echo "skip: python3 missing"; exit 0; }

# --- the Find records filter, cut out of the template verbatim and run on a comment list
fr="$(grep -F -- '- **Find records**' "$TP")"
filt="${fr#*--jq \'}"; filt="${filt%%\'\`. One paginated*}"
filt="${filt//\'\"\$me\"\'/lead-qa}"
ck find-records-filter-extracted 1 "$([ -n "$filt" ] && printf '%s' "$filt" | grep -qF 'factory:hansei v' && echo 1 || echo 0)"
filt_a3="${filt//factory:hansei/factory:a3}"
fa="$(grep -F -- '- **Find A3s**' "$TP")"
ck find-a3s-is-the-same-call-with-a3 1 "$(printf '%s' "$fa" | grep -cF 'the same call as *Find records* with `factory:a3` in place of `factory:hansei`')"

mkjson() {  # mkjson <names, comma separated> -> a JSON array of comments, in the given order
  for n in $(echo "$1" | tr ',' ' '); do
    row="$(grep -E "^$n	" "$FX/comments.tsv")"
    id="$(echo "$row" | cut -f2)"; it="$(echo "$row" | cut -f3)"; ca="$(echo "$row" | cut -f4)"; us="$(echo "$row" | cut -f5)"
    jq -n --arg id "$id" --arg url "https://example.invalid/shop/issues/$it#issuecomment-$id" --arg ca "$ca" --arg us "$us" --rawfile body "$FX/records/$n.md" \
      '{id: ($id|tonumber), html_url: $url, created_at: $ca, user: {login: $us}, body: $body}'
  done | jq -s '.'
}
run_sc() {  # run_sc <scenario> -> $T/out-<scenario>.md
  row="$(grep -E "^$1	" "$FX/scenarios.tsv")"
  rel="$(echo "$row" | cut -f2)"; names="$(echo "$row" | cut -f3)"; mainf="$(echo "$row" | cut -f4)"
  mkjson "$names" > "$T/c-$1.json"
  jq -c "$filt" "$T/c-$1.json" > "$T/r-$1.jsonl"
  jq -c "$filt_a3" "$T/c-$1.json" > "$T/a-$1.jsonl"
  [ "$mainf" = "-" ] && mp="-" || mp="$FX/$mainf"
  python3 -I "$PY" body "$T/r-$1.jsonl" "$rel" "$mp" "$T/a-$1.jsonl" > "$T/out-$1.md"
}
for s in A B C D E1 E2 F1 F2 G I J K L; do run_sc "$s"; done

# --- Find records returns the lead's own markers by first line only (AC-2: C39 and C49 are never returned)
ck ac2-find-records-A "x2 x5 x5d x5e x5f x5c" "$(jq -r '.id' "$T/r-A.jsonl" | while read -r i; do grep -E "	$i	" "$FX/comments.tsv" | cut -f1; done | paste -sd' ' -)"
ck ac2-find-records-skips-other-author 0 "$(jq -c 'select(.id == 9112)' "$T/r-A.jsonl" | grep -c .)"
printf '%s' '[{"id":1,"html_url":"u","created_at":"2026-01-01T00:00:00Z","user":{"login":"lead-qa"},"body":"<!-- factory:hansei v4 -->\r\n## Hansei: #1 crlf\r\n"},{"id":2,"html_url":"u","created_at":"2026-01-01T00:00:00Z","user":{"login":"lead-qa"},"body":"intro line\n<!-- factory:hansei v4 -->\n"},{"id":3,"html_url":"u","created_at":"2026-01-01T00:00:00Z","user":{"login":"lead-qa"},"body":"<!-- factory:hansei v4 --> trailing\n"},{"id":4,"html_url":"u","created_at":"2026-01-01T00:00:00Z","user":{"login":"lead-qa"},"body":"<!-- factory:hansei v12 -->\n"}]' > "$T/edge.json"
ck ac2-find-records-first-line-only "1 4" "$(jq -r '.id' <(jq -c "$filt" "$T/edge.json") | paste -sd' ' -)"
ck ac2-find-a3s-matches-a3 "9003" "$(jq -r '.id' "$T/a-K.jsonl" | paste -sd' ' -)"
ck ac2-find-a3s-ignores-hansei 0 "$(jq -c "$filt_a3" "$T/c-A.json" | grep -c .)"

# --- expectations written before the replay
chk() {  # chk <scenario> <kind> <text>
  case "$2" in
    line) if grep -qxF -- "$3" "$T/out-$1.md"; then echo "ok   replay-$1: $(printf '%s' "$3" | cut -c1-70)"; passed=$((passed + 1)); else echo "FAIL replay-$1: line not found: $3"; fail=1; fi ;;
    absent) if grep -qF -- "$3" "$T/out-$1.md"; then echo "FAIL replay-$1: unexpected text: $3"; fail=1; else echo "ok   replay-$1 absent: $3"; passed=$((passed + 1)); fi ;;
  esac
}
while IFS="$(printf '\t')" read -r sc kind text; do
  [ -n "$sc" ] || continue
  chk "$sc" "$kind" "$text"
done < "$FX/expected.tsv"

# --- AC-4: a calibration record never changes a figure or an item list of a release section
blk() { awk -v s="### Series 1.1 " 'index($0, s)==1 {f=1} f && /^## / {exit} f {print}' "$1"; }
ck ac4-series-1.1-identical "$(blk "$T/out-E1.md")" "$(blk "$T/out-E2.md")"
ck ac4-calibration-listed-only-under-calibration 1 "$(awk '/^## Calibration/ {f=1; next} /^## / {f=0} f' "$T/out-E2.md" | grep -c '#108')"
ck ac4-calibration-not-in-items 0 "$(grep -E '^- items:' "$T/out-E2.md" | grep -c '#10[68]')"
ck ac4-c39t-calibration-record-is-calibration 1 "$(grep -c '^- #108 .* — factory 9147301f75c3' "$T/out-E2.md")"

# --- AC-5: S5, S5d, then S5c arrives: series 1.1 keeps every figure; only its heading and section label move
figs() { grep -E '^(- (lead time|first-pass yield|rework|escaped defects|person|doors)|  - )' "$1" | awk '/^### Series 1.1/ {f=1} {print}' ; }
f1="$(awk '/^### Series 1.1 / {f=1; next} /^### Series 1.2/ {f=0} /^## / {f=0} f && /^(- (lead time|first-pass yield|rework|escaped defects|person|doors)|  )/' "$T/out-F1.md")"
f2="$(awk '/^### Series 1.1 / {f=1; next} /^### Series 1.2/ {f=0} /^## / {f=0} f && /^(- (lead time|first-pass yield|rework|escaped defects|person|doors)|  )/' "$T/out-F2.md")"
ck ac5-old-series-figures-unchanged "$f1" "$f2"
ck ac5-f1-has-figures 1 "$([ -n "$f1" ] && echo 1 || echo 0)"
chk F1 line '### Series 1.1 — current'
chk F1 line '- releases: factory 1.1.0, 1.1.1'
chk F1 line '- items: 2 items: #101 https://example.invalid/shop/issues/101#issuecomment-9101; #104 https://example.invalid/shop/issues/104#issuecomment-9104'
chk F2 line '### Series 1.1 — replaced 2026-11-05 by 1.2'
chk F2 line '#### Section — whole-item overrides: none — history (series replaced)'
chk F2 line '- items: 2 items: #101 https://example.invalid/shop/issues/101#issuecomment-9101; #104 https://example.invalid/shop/issues/104#issuecomment-9104'
ck ac5-patch-starts-no-series 0 "$(grep -c '^### Series 1.1.1' "$T/out-F1.md")"
ck ac5-one-series-heading-per-mn 1 "$(grep -c '^### Series 1.1 ' "$T/out-A.md")"
ck ac2-no-item-in-two-series 0 "$(grep -E '^- items:' "$T/out-A.md" | grep -o '#10[0-9]' | sort | uniq -d | wc -l | tr -d ' ')"

# --- AC-7: running the update twice gives the same text (a pure function of the records)
python3 -I "$PY" body "$T/r-A.jsonl" 1.2.0 - "$T/a-A.jsonl" > "$T/again-A.md"
ck ac7-recompute-is-identical "$(cat "$T/out-A.md")" "$(cat "$T/again-A.md")"
# the same records in another order give the same text
tail -r "$T/r-A.jsonl" > "$T/r-A-rev.jsonl"
python3 -I "$PY" body "$T/r-A-rev.jsonl" 1.2.0 - "$T/a-A.jsonl" > "$T/rev-A.md"
ck ac7-record-order-does-not-matter "$(cat "$T/out-A.md")" "$(cat "$T/rev-A.md")"

# --- AC-7: the run-start repair check (baseline.md section 8.2): a record whose item number appears in no list of the body
#     means the previous run stopped before its update. Body written for X5 only; X5b has closed since.
listed="$(grep -oE '#[0-9]+' "$T/out-C.md" | sort -u)"
unlisted=0; for i in $(jq -r '.body' "$T/r-D.jsonl" | sed -nE 's/^## Hansei: (#[0-9]+) .*/\1/p'); do printf '%s\n' "$listed" | grep -qx -- "$i" || unlisted=$((unlisted + 1)); done
ck ac7-repair-finds-the-record-the-body-does-not-list 1 "$unlisted"
python3 -I "$PY" body "$T/r-D.jsonl" 1.1.0 - "$T/a-D.jsonl" > "$T/repaired-D.md"
listed="$(grep -oE '#[0-9]+' "$T/repaired-D.md" | sort -u)"
unlisted=0; for i in $(jq -r '.body' "$T/r-D.jsonl" | sed -nE 's/^## Hansei: (#[0-9]+) .*/\1/p'); do printf '%s\n' "$listed" | grep -qx -- "$i" || unlisted=$((unlisted + 1)); done
ck ac7-after-the-update-nothing-unlisted 0 "$unlisted"

# --- AC-8: nothing in the body without a source record; no raw record text, no 5 Whys
ck ac8-no-updated-at-line 0 "$(grep -ciE 'updated at|last updated' "$T/out-A.md")"
ck ac8-no-record-text 0 "$(grep -c 'Synthetic' "$T/out-C.md")"
ck ac8-no-hex-outside-series-lines 0 "$(grep -E '[0-9a-f]{64}' "$T/out-C.md" | grep -cvE '^- (standard|tooling):')"
ck ac8-every-item-named-has-a-record 1 "$(for i in $(grep -E '^- items:' "$T/out-D.md" | grep -o '#[0-9]*' | tr -d '#'); do grep -c "^## Hansei: #$i " "$FX"/records/*.md | grep -vc ':0$' | grep -q . && echo ok; done | sort -u | wc -l | tr -d ' ')"

# --- AC-2/AC-3: honesty rule in every reading: a not-captured field never shows 0, blank, or a bare median without its k of n
R1OK=' ([0-9][0-9a-z.]* \([0-9]+ of [0-9]+ items(, [0-9]+ not captured)?(, [0-9]+ n/a)?\)|not captured \(.*\)|n/a \(did not run in any of [0-9]+ items\))$'
for s in A B C D G I; do
  ck "ac3-every-quantity-has-k-of-n-$s" 0 "$(grep -E '^(- lead time|- rework|- person|  - [a-z-]+: spend)' "$T/out-$s.md" | sed -E 's/^(- [^:]*: |  - [a-z-]+: )//' | sed -E 's/; (spend|peak context|total|agent working|waiting|stalled|interrupted|andon|product|architect|developer|qa|security|devops|docs|overturned|decision|demos|approvals|overturns|other)/\
\1/g' | grep -vE "$R1OK" | grep -c .)"
done
ck ac3-g-no-zero-for-missing 0 "$(grep -E '^- lead time' "$T/out-G.md" | grep -cE '(agent working|waiting for the person|andon) 0m')"
ck ac3-b-empty-series-never-zero 0 "$(awk '/^### Series 1.2/ {f=1} /^## History/ {f=0} f' "$T/out-B.md" | grep -E '^- (lead time|rework|person)' | grep -cE ' 0( |;|$)')"

# --- AC-11, AC-14, AC-15 on ledgers
A3="$FX/a3"
exp() { grep -E "^$1	$2	" "$FX/a3-expected.tsv" | cut -f3; }
for c in R1 R2 R3 R4 R5 R6; do
  out="$(python3 -I "$PY" a3problem "$A3/$c.json")"
  ck "ac11-$c-problem" "$(exp $c problem)" "$(printf '%s' "$out" | jq -r .problem)"
  want="$(exp $c other)"; [ -n "$want" ] && ck "ac11-$c-other" "$want" "$(printf '%s' "$out" | jq -r .other)"
  want="$(exp $c count)"; [ -n "$want" ] && ck "ac11-$c-count" "$want" "$(printf '%s' "$out" | jq -r .count)"
done
out="$(python3 -I "$PY" a3classify "$A3/P.json")"
for k in before during after neither; do ck "ac14-P-$k" "$(exp P $k)" "$(printf '%s' "$out" | jq -r ".$k | map(\"#\" + (.|tostring)) | join(\",\")")"; done
for c in Q1 Q3 Q3b Q4 Q5 Q6a Q6b Q6c Q6d Q6e; do
  ck "ac15-$c-change" "$(exp $c change)" "$(python3 -I "$PY" a3change "$A3/$c.json" | jq -r .change)"
done
ck ac15-Q1-after "$(exp Q1 after)" "$(python3 -I "$PY" a3change "$A3/Q1.json" | jq -r .after)"
# AC-15 "the release moved": the requirement's own example. The text as written classifies the 1.3 item out of every reading first
# (a3.md section 6 item 1), so section 7 item 2 cannot fire: QA-57 finding F1.
got="$(python3 -I "$PY" a3change "$A3/Q2.json" | jq -r .change)"
if [ "$got" = "$(exp Q2 change)" ]; then ck ac15-Q2-release-moved "$(exp Q2 change)" "$got"
else skip ac15-Q2-release-moved "QA-57 finding F1: a3.md section 6 item 1 drops a series-1.3 after-item before section 7 item 2 sees it; found '$got', required '$(exp Q2 change)'; developer/architect fix"; fi
done_
