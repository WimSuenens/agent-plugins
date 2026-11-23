#!/bin/bash
# #207 slice 5, items 3 to 5: the light QA verdict, proof per artefact kind, and the gate's check that the verdict links each criterion to a proof item.
# Written before proof-kind.sh and before merge-gate.sh learned --qa-file, --plan and --kind.
# Fixtures: the verdict of #225 as it was written (read-only, free prose), and a markdown-plugin slice's verdict in the machine-readable form.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
MG="$PLUGIN/scripts/merge-gate.sh"; PK="$PLUGIN/scripts/proof-kind.sh"
FX="$REPO/tests/factory/fixtures/slice5"
cd "$T" || exit 1
mkdir -p "$T/bin"
cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "pr view" ] && { cat "$PRJSON"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH"; export PRJSON="$T/pr.json"
jq -n --arg b $'## Summary\nx\n\n## Proof\n\n```\n$ run\nok\n```\n' '{body:$b,statusCheckRollup:[{name:"ci",conclusion:"SUCCESS"}]}' >"$PRJSON"
run() { out="$(bash "$MG" check 7 --security pass "$@" 2>&1)"; rc=$?; }
reason() { printf '%s\n' "$out" | grep -c "$1"; }

# ---- proof-kind.sh: the artefact kind from --kind, the plan or the table, and what proof it takes
ck pk-exists yes "$([ -f "$PK" ] && echo yes || echo no)"
pk() { pout="$(bash "$PK" resolve "$@" 2>&1)"; pcode=$?; }
pk --kind web-app;              ck pk-web "0 kind: web-app|proof: screenshot" "$pcode $(printf '%s\n' "$pout" | paste -sd'|' -)"
pk --kind cli;                  ck pk-cli "0 kind: cli|proof: run-log" "$pcode $(printf '%s\n' "$pout" | paste -sd'|' -)"
pk --kind library;              ck pk-library "0 kind: library|proof: run-log" "$pcode $(printf '%s\n' "$pout" | paste -sd'|' -)"
pk --kind instruction-markdown; ck pk-markdown "0 kind: instruction-markdown|proof: scenario-transcript" "$pcode $(printf '%s\n' "$pout" | paste -sd'|' -)"
pk --kind docs;                 ck pk-docs "0 kind: docs|proof: render-log, link-check-log" "$pcode $(printf '%s\n' "$pout" | paste -sd'|' -)"
pk --kind hologram;             ck pk-unknown-kind 2 "$pcode"
printf -- '- artefact: web-app\n' >"$T/plan.md"
pk --plan "$T/plan.md";         ck pk-from-plan "0 kind: web-app" "$pcode $(printf '%s\n' "$pout" | head -1)"
pk --kind cli --plan "$T/plan.md"; ck pk-flag-beats-plan "kind: cli" "$(printf '%s\n' "$pout" | head -1)"
tbl() { printf 'project-type: %s\nfloor: x\n' "$1" >"$T/t.md"; pk --table "$T/t.md"; }
tbl "markdown/LLM plugin"; ck pk-table-markdown "0 kind: instruction-markdown" "$pcode $(printf '%s\n' "$pout" | head -1)"
tbl "static site";         ck pk-table-site "0 kind: web-app" "$pcode $(printf '%s\n' "$pout" | head -1)"
tbl "code app";            ck pk-table-code-app-names-the-way-out 3 "$pcode"
ck pk-says-how "yes" "$(printf '%s\n' "$pout" | grep -q -- '--kind' && printf '%s\n' "$pout" | grep -q 'artefact:' && echo yes || echo no)"
pk;                        ck pk-nothing-given 3 "$pcode"

# ---- the verdicts
# a markdown-plugin slice, machine-readable: every criterion links a proof item of the kind
cat >"$T/qa-md.md" <<'V'
# QA verdict: 301

Verdict: pass
Scope: standard

## Criteria

- AC-1: pass | check: the new reference is named in the router | proof: P1
- AC-2: pass | check: a scenario of the lead reading the plan picks the light path | proof: P1, P2

## Proof

- P1 [scenario-transcript]: work/301/scenario-1.md
- P2 [scenario-transcript]: https://example.test/p2

Human-only criteria: none
V
cp "$T/qa-md.md" "$T/qa-nolink.md"; sed -i.bak 's/ | proof: P1, P2$//; s/^- AC-2: pass | check: \(.*\)$/- AC-2: pass | check: \1/' "$T/qa-nolink.md"
cp "$T/qa-md.md" "$T/qa-wrongkind.md"; sed -i.bak 's/^- P1 \[scenario-transcript\]/- P1 [screenshot]/; s/^- P2 \[scenario-transcript\]/- P2 [screenshot]/' "$T/qa-wrongkind.md"
cp "$T/qa-md.md" "$T/qa-dangling.md"; sed -i.bak 's/proof: P1, P2/proof: P9/' "$T/qa-dangling.md"
cp "$T/qa-md.md" "$T/qa-blocked.md"; sed -i.bak 's/^- AC-2: pass/- AC-2: block/' "$T/qa-blocked.md"
cp "$T/qa-md.md" "$T/qa-says-block.md"; sed -i.bak 's/^Verdict: pass/Verdict: block/' "$T/qa-says-block.md"
cp "$T/qa-md.md" "$T/qa-nohuman.md"; grep -v '^Human-only criteria' "$T/qa-md.md" >"$T/qa-nohuman.md"
cp "$T/qa-md.md" "$T/qa-noref.md"; sed -i.bak 's#^- P2 \[scenario-transcript\]: .*#- P2 [scenario-transcript]:#' "$T/qa-noref.md"

run --qa pass --qa-file "$T/qa-md.md" --kind instruction-markdown --paths "plugins/x/skills/a/SKILL.md"
ck md-plugin-verdict-auto-merge 0 "$rc"
ck md-plugin-gate-prints-what-it-read 1 "$(reason '^verdict read: .*qa-md.md: 2 criteria, 2 proof items (scenario-transcript)')"
ck md-plugin-gate-prints-kind 1 "$(reason '^artefact kind: instruction-markdown (proof: scenario-transcript)')"
run --qa pass --qa-file "$T/qa-nolink.md" --kind instruction-markdown
ck missing-link-blocked 11 "$rc"; ck missing-link-names-the-criterion 1 "$(reason '^reason: criterion AC-2 has no proof item linked')"
run --qa pass --qa-file "$T/qa-wrongkind.md" --kind instruction-markdown
ck wrong-kind-blocked 11 "$rc"; ck wrong-kind-names-the-criterion 1 "$(reason '^reason: criterion AC-1 links no scenario-transcript (P1 is a screenshot)')"
run --qa pass --qa-file "$T/qa-md.md" --kind cli
ck kind-cli-wants-run-log 11 "$rc"; ck kind-cli-says-which 1 "$(reason 'criterion AC-1 links no run-log')"
run --qa pass --qa-file "$T/qa-dangling.md" --kind instruction-markdown
ck dangling-proof-blocked 11 "$rc"; ck dangling-proof-names-it 1 "$(reason '^reason: criterion AC-2 links P9, which is not in the Proof list')"
run --qa pass --qa-file "$T/qa-noref.md" --kind instruction-markdown
ck empty-proof-ref-blocked 11 "$rc"; ck empty-proof-ref-names-item 1 "$(reason 'proof item P2 has no link or path')"
run --qa pass --qa-file "$T/qa-blocked.md" --kind instruction-markdown
ck block-criterion-blocked 11 "$rc"; ck block-criterion-names-it 1 "$(reason '^reason: criterion AC-2 is block in the QA verdict')"
run --qa pass --qa-file "$T/qa-says-block.md" --kind instruction-markdown
ck file-says-block-blocked 11 "$rc"; ck file-says-block-why 1 "$(reason '^reason: the QA verdict file says block')"
run --qa pass --qa-file "$T/qa-nohuman.md" --kind instruction-markdown
ck markdown-needs-human-only-list 11 "$rc"; ck markdown-human-only-says 1 "$(reason 'Human-only criteria')"
# the verdict of #225, as written: free prose, no criterion lines
run --qa pass --qa-file "$FX/qa-225.md" --kind web-app
ck old-verdict-225-blocked 11 "$rc"; ck old-verdict-225-says-why 1 "$(reason '^reason: the QA verdict has no criterion lines under "## Criteria"')"
# no file, an unreadable file, no way to know the kind
run --qa pass --kind cli;                      ck no-qa-file-blocked 11 "$rc"; ck no-qa-file-says 1 "$(reason '^reason: no QA verdict file (--qa-file)')"
run --qa pass --qa-file "$T/nosuch.md" --kind cli; ck unreadable-qa-file-blocked 11 "$rc"
run --qa pass --qa-file "$T/qa-md.md";         ck no-kind-blocked 11 "$rc"; ck no-kind-says 1 "$(reason '^reason: the artefact kind is not known')"
# the kind from the plan's `artefact:` line, and from the project's table (the working tree's docs/agents/factory.md where there is no origin/main)
printf -- '- artefact: instruction-markdown\n- band: Normal\n- bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more\n' >"$T/plan-md.md"
run --qa pass --qa-file "$T/qa-md.md" --plan "$T/plan-md.md"; ck kind-from-plan 0 "$rc"
mkdir -p "$T/proj/docs/agents"; printf 'project-type: markdown/LLM plugin\nfloor: x\n' >"$T/proj/docs/agents/factory.md"
out="$(cd "$T/proj" && bash "$MG" check 7 --security pass --qa pass --qa-file "$T/qa-md.md" 2>&1)"; rc=$?; ck kind-from-table 0 "$rc"
# QA verdict must also be `pass` on the command line, as before
run --qa findings --qa-file "$T/qa-md.md" --kind instruction-markdown; ck qa-flag-still-needed 11 "$rc"

# ---- the light verdict: Light band only, the path check and the suite named, never a protected area
cat >"$T/qa-light.md" <<'V'
# QA verdict: 302

Verdict: pass
Scope: light
Path check: ok (paths.sh check: no off-list path)
Suite: bash tests/run.sh pass

## Criteria

- AC-1: pass | check: the page names the three plugins | proof: P1

## Proof

- P1 [run-log]: work/302/run.log
V
printf -- '- artefact: cli\n- band: Light\n- bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more\n' >"$T/plan-light.md"
printf -- '- artefact: cli\n- band: Normal\n- bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more\n' >"$T/plan-normal.md"
run --qa pass --qa-file "$T/qa-light.md" --plan "$T/plan-light.md" --paths "docs/a.md"
ck light-in-light-band-auto-merge 0 "$rc"; ck light-prints-scope 1 "$(reason '^verdict scope: light (band Light)')"
run --qa pass --qa-file "$T/qa-light.md" --kind cli --paths "docs/a.md"
ck light-without-plan-blocked 11 "$rc"; ck light-without-plan-says 1 "$(reason '^reason: a light verdict needs the plan (--plan) to show the slice is in the lightest band')"
run --qa pass --qa-file "$T/qa-light.md" --plan "$T/plan-normal.md" --paths "docs/a.md"
ck light-in-normal-band-blocked 11 "$rc"; ck light-in-normal-says 1 "$(reason '^reason: a light verdict stands for the Light band only; the plan says Normal')"
run --qa pass --qa-file "$T/qa-light.md" --plan "$T/plan-light.md" --paths "contracts/a.md"
ck light-on-protected-blocked 11 "$rc"; ck light-on-protected-says 1 "$(reason '^reason: a light verdict cannot stand for a protected area')"
run --qa pass --qa-file "$T/qa-light.md" --plan "$T/plan-light.md" --touches authentication
ck light-on-touch-blocked 11 "$rc"
grep -v '^Path check' "$T/qa-light.md" >"$T/qa-light-nopath.md"
run --qa pass --qa-file "$T/qa-light-nopath.md" --plan "$T/plan-light.md"; ck light-needs-path-check 11 "$rc"; ck light-needs-path-check-says 1 "$(reason '^reason: a light verdict needs a `Path check:` line')"
grep -v '^Suite' "$T/qa-light.md" >"$T/qa-light-nosuite.md"
run --qa pass --qa-file "$T/qa-light-nosuite.md" --plan "$T/plan-light.md"; ck light-needs-suite-line 11 "$rc"
sed 's/^Path check: ok.*/Path check: off-list: docs\/z.md/' "$T/qa-light.md" >"$T/qa-light-off.md"
run --qa pass --qa-file "$T/qa-light-off.md" --plan "$T/plan-light.md"; ck light-off-list-path-blocked 11 "$rc"
# a standard verdict on a protected area is fine (and the gate pauses for the person as before)
run --qa pass --qa-file "$T/qa-md.md" --kind instruction-markdown --paths "contracts/a.md"; ck standard-protected-pauses 10 "$rc"
# the other blocks are untouched
run --qa pass --qa-file "$T/qa-md.md" --kind instruction-markdown --security findings 2>/dev/null; ck sec-block-still-blocks 11 "$rc"
# review of slice 5: a criterion with any status but exactly `pass` blocks (no silent drop), a CRLF file reads, a mis-pasted plan cannot open the skip
for st in fail Pass pending n/a; do
  sed "s#^- AC-2: pass#- AC-2: $st#" "$T/qa-md.md" >"$T/qa-st.md"
  run --qa pass --qa-file "$T/qa-st.md" --kind instruction-markdown
  ck "status-$st-blocks" 11 "$rc"; ck "status-$st-names-it" 1 "$(reason "^reason: criterion AC-2 is $st in the QA verdict")"
done
sed 's/$/\r/' "$T/qa-md.md" >"$T/qa-crlf.md"
run --qa pass --qa-file "$T/qa-crlf.md" --kind instruction-markdown; ck crlf-verdict-reads 0 "$rc"
tbl "mobile app with a REST client"; ck pk-client-is-not-cli 3 "$pcode"
tbl "Webhook service"; ck pk-webhook-is-not-web 3 "$pcode"
tbl "command line tool"; ck pk-command-line-tool-is-cli "0 kind: cli" "$pcode $(printf '%s\n' "$pout" | head -1)"
done_
