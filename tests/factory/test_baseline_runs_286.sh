#!/bin/bash
# #286 AC-B2 (Runs side), AC-C3, AC-C4: the baseline's Runs section (contract 286-a3-v4-and-runs section 4, references/baseline.md section 9).
# The Lead composes the section by hand; no script ships. Two parts:
#  1. the text: baseline.md carries section 9, its headings and the empty-half line, and reads A3 markers v1 to v4 (written before the build);
#  2. the rule replayed: QA's reading (runs_replay.py) on v4 A3 fixtures built from fixtures/a3/v4-ok.md with the values of
#     fixtures/runs286/a3s.tsv; the expected blocks (fixtures/runs286/E*.expected) were committed before the replay.
. "$(dirname "$0")/lib.sh"
BL="$PLUGIN/references/baseline.md"; FX="$REPO/tests/factory/fixtures/runs286"; V4="$REPO/tests/factory/fixtures/a3/v4-ok.md"
V3="$REPO/tests/factory/fixtures/a3/v3-ok.md"; PY="$REPO/tests/factory/runs_replay.py"

# ---------- 1. the text ----------
has text-section-9 "$BL" '## 9. The Runs section'
has text-heading-off "$BL" '#### Runs — discipline: off'
has text-heading-on "$BL" '#### Runs — discipline: on'
has text-empty-half "$BL" '- none (no run in series)'
has text-not-counted-run-stopped "$BL" 'run stopped #<map> <A3 url>'
has text-reads-v4-markers "$BL" 'an A3 of marker v1, v2, v3 or v4 is read; any other version is skipped and named'
# the marker of the baseline itself does not move (AC-C5)
has text-baseline-marker-v1 "$BL" '<!-- factory:baseline v1 -->'
hasnt text-no-baseline-marker-v2 "$BL" '<!-- factory:baseline v2 -->'
# the body template (section 7) ends each series block with both headings
s7() { awk '/^## 7\. / { on = 1 } /^## 8\. / { on = 0 } on' "$BL"; }
ck text-template-has-both-headings "yes yes" "$([ "$(s7 | grep -c '^#### Runs — discipline: off$')" -ge 1 ] && echo yes || echo no) $([ "$(s7 | grep -c '^#### Runs — discipline: on$')" -ge 1 ] && echo yes || echo no)"

# ---------- 2. the rule replayed ----------
command -v python3 >/dev/null || { skip runs-replay "python3 missing"; done_; }
mkbody() { # mkbody <tsv row fields...> -> the A3 body on stdout
  local name="$1" mk="$2" map="$3" st="$4" ser="$5" rt="$7" disc="$8" g="$9"
  if [ "$mk" = v3 ]; then sed "s/^- run: .*/- run: #$map — $st/; s/^- series and release: [0-9.]*;/- series and release: $ser;/" "$V3"; return; fi
  awk -v map="$map" -v st="$st" -v ser="$ser" -v rt="$rt" -v disc="$disc" -v g="$g" '
    index($0, "- run: ") == 1 { print "- run: #" map " — " st; next }
    index($0, "- series and release: ") == 1 { sub(/^- series and release: [0-9.]+;/, "- series and release: " ser ";"); print; next }
    index($0, "- run timing: ") == 1 { print "- run timing: " rt; next }
    index($0, "- discipline: ") == 1 { print "- discipline: " disc; next }
    index($0, "- run compared: ") == 1 && rt ~ /^not captured/ { print "- run compared: none (run timing not captured)"; next }
    index($0, "- guardrails: ") == 1 { print "- guardrails: " g; next }
    { print }' "$V4"
}
mkjsonl() { # mkjsonl <names, comma separated>
  local n row
  for n in $(echo "$1" | tr ',' ' '); do
    row="$(grep -E "^$n	" "$FX/a3s.tsv")"
    IFS="$(printf '\t')" read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 <<EOF
$row
EOF
    mkbody "$f1" "$f2" "$f3" "$f4" "$f5" "$f6" "$f7" "$f8" "$f9" > "$T/body-$n.md"
    jq -cn --arg url "https://example.invalid/issues/$f3#issuecomment-$f3" --arg ca "$f6" --rawfile body "$T/body-$n.md" '{html_url: $url, created_at: $ca, body: $body}'
  done
}
# each v4 A3 built for the replay passes the check (once the check knows v4): the fixtures are A3s the standard can post
for n in c278 c300 c301 c302 c303 c240; do
  mkjsonl "$n" > /dev/null
  OUT="$(/bin/bash "$PLUGIN/scripts/a3-check.sh" "$T/body-$n.md" 2>/dev/null)"; RC=$?; ck "fixture-$n-passes-a3-check" "0 ok v4" "$RC $OUT"
done
grep -v '^#' "$FX/scenarios.tsv" | while IFS="$(printf '\t')" read -r sc names blocks what; do
  mkjsonl "$names" > "$T/$sc.jsonl"
  python3 -I "$PY" runs "$T/$sc.jsonl" "$blocks" > "$T/$sc.out" 2>"$T/$sc.err"
  if diff "$FX/$sc.expected" "$T/$sc.out" > "$T/$sc.diff"; then echo "ok   replay-$sc ($what)"; else echo "FAIL replay-$sc ($what)"; sed 's/^/     /' "$T/$sc.diff" "$T/$sc.err"; echo fail > "$T/replay-failed"; fi
done
ck replay-all-scenarios-match 0 "$([ -f "$T/replay-failed" ] && echo 1 || echo 0)"
# AC-C3: the replay reads only the five lines: every other line of each A3 changed or dropped gives the same blocks
mkjsonl c278,c300,c303 > "$T/full.jsonl"
jq -c '.body |= (split("\n") | map(select(test("^(<!-- factory:a3 |- run: |- series and release: |- run timing: |- discipline: |- guardrails: )"))) | join("\n"))' "$T/full.jsonl" > "$T/five.jsonl"
ck c3-five-lines-are-enough "$(python3 -I "$PY" runs "$T/full.jsonl" 3.10)" "$(python3 -I "$PY" runs "$T/five.jsonl" 3.10)"
done_
