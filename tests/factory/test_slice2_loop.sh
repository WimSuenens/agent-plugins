#!/bin/bash
# Slice 2 of #207 (the improvement loop). One block per item, in the order built. Each block was red before its change.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
AD="$PLUGIN/scripts/andon-detect.sh"; SK="$PLUGIN/skills/run/SKILL.md"; PR="$PLUGIN/references/protocol.md"
cd "$T" || exit 1

# ---- item 6 (#211): kind 3 and the tie line ----
# (b) the committing role is one of the tied owners: no tie line (it is working in a place its own role shares); another role still gets it
D="$T/k3"; mkdir -p "$D/docs/agents" "$D/x"; git -C "$D" init -q -b main
printf '%s\n' '| Path | Owner |' '|---|---|' '| `x/*.md` | developer |' '| `x/*.md` | qa-engineer |' > "$D/docs/agents/factory.md"
echo b > "$D/README.md"; git -C "$D" add -A; git -C "$D" commit -qm base; git -C "$D" checkout -q -b item/9
echo 1 > "$D/x/a.md"; git -C "$D" add -A; git -C "$D" commit -qm "#9 developer: a"
ck item6b-tied-owner-commits-no-line "" "$(bash "$AD" kind3 --in "$D" --table "$D/docs/agents/factory.md" --base main)"
echo 2 > "$D/x/b.md"; git -C "$D" add -A; git -C "$D" commit -qm "#9 qa-engineer: b"
ck item6b-second-tied-owner-no-line "" "$(bash "$AD" kind3 --in "$D" --table "$D/docs/agents/factory.md" --base main)"
echo 3 > "$D/x/c.md"; git -C "$D" add -A; git -C "$D" commit -qm "#9 devops: c"
ck item6b-other-role-gets-the-tie "role-outside-role: $(git -C "$D" rev-parse --short=7 HEAD) devops changed x/c.md (ambiguous owner: developer qa-engineer)" "$(bash "$AD" kind3 --in "$D" --table "$D/docs/agents/factory.md" --base main)"
# (a) the run skill describes the line the script prints
has item6a-skill-names-the-tie-line "$SK" '(ambiguous owner: <A> <B>)'
has item6a-skill-says-tie-not-decided "$SK" 'a tie between two owners is reported, not decided'
has item6b-skill-says-own-tie-silent "$SK" 'no tie line when the committing role is one of the tied owners'

# ---- item 3 (#164, D7, provisional): intake.sh filed-since ----
# gh is a stub answering `issue list` with the issues of the first site run (tests/factory/fixtures/a3events/issues-window.json, read from the tracker; bodies left out)
IN="$PLUGIN/scripts/intake.sh"; FX="$REPO/tests/factory/fixtures/a3events"
mkdir -p "$T/bin"; cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "issue list" ] && { echo "$*" >>"$STUB_LOG"; cat "$STUB_ISSUES"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH" STUB_LOG="$T/gh.log" STUB_ISSUES="$FX/issues-window.json"
R="$T/proj"; mkdir -p "$R/docs/agents"; git init -q -b main "$R"; ( cd "$R" && echo r > README && git add -A && git commit -qm init ) >/dev/null
printf '%s\n' '| Label in mattpocock/skills | Label in our tracker | Meaning |' '|---|---|---|' '| `needs-triage` | `needs-triage` | evaluate |' '| `wontfix` | `wontfix` | no |' > "$R/docs/agents/triage-labels.md"
cd "$R" || exit 1
START=2026-11-12T19:55:27Z; END=2026-11-13T22:54:00Z
got="$(bash "$IN" filed-since $START $END --state all | cut -f1 | tr '\n' ' ')"
ck item3-real-run-ten-issues "158 159 160 162 164 166 167 173 179 187 " "$got"
ck item3-before-the-run-start-not-counted 0 "$(bash "$IN" filed-since $START $END --state all | grep -c '^14[35]	')"
ck item3-open-only-drops-closed "0" "$(bash "$IN" filed-since $START $END | grep -c '^162	')"
ck item3-open-count "9" "$(bash "$IN" filed-since $START $END | wc -l | tr -d ' ')"
ck item3-line-form "new issues since $START: 9 open: #158 factory: a frontier round that only records answered decision cards should not need a second approval;" "$(bash "$IN" filed-since $START $END --line | sed 's/ #159.*//')"
has item3-line-names-sources-label <(bash "$IN" filed-since $START $END --line) '(sources: label needs-triage, marker factory:improvement)'
# the label is the project's own: a different vocabulary changes what is counted
sed -i '' 's/| `needs-triage` | `needs-triage` |/| `needs-triage` | `inbox` |/' "$R/docs/agents/triage-labels.md"
ck item3-reads-the-label-from-the-table 0 "$(bash "$IN" filed-since $START $END --state all | wc -l | tr -d ' ')"
# the marker source counts an issue that has no triage label at all
jq '. + [{number:900,title:"marked",createdAt:"2026-11-13T10:00:00Z",state:"OPEN",labels:[],body:"<!-- factory:improvement abc -->\n\nbody"}]' "$FX/issues-window.json" > "$T/with-marker.json"
STUB_ISSUES="$T/with-marker.json" bash "$IN" filed-since $START $END >"$T/o"; ck item3-marker-source "900	marked	marker" "$(cat "$T/o")"
# an issue with both is listed once
jq '. + [{number:901,title:"both",createdAt:"2026-11-13T10:00:00Z",state:"OPEN",labels:[{name:"inbox"}],body:"<!-- factory:improvement def -->"}]' "$FX/issues-window.json" > "$T/both.json"
STUB_ISSUES="$T/both.json" bash "$IN" filed-since $START $END >"$T/o"; ck item3-both-once "901	both	label+marker" "$(cat "$T/o")"
# no triage-labels.md: only the marker is counted, and the line says so
rm "$R/docs/agents/triage-labels.md"
ck item3-no-table-says-marker-only "new issues since $START: 1 open: #900 marked (sources: marker factory:improvement only, no docs/agents/triage-labels.md)" "$(STUB_ISSUES="$T/with-marker.json" bash "$IN" filed-since $START $END --line 2>/dev/null)"
ck item3-none-line "new issues since $START: none (sources: marker factory:improvement only, no docs/agents/triage-labels.md)" "$(bash "$IN" filed-since $START $END --line 2>/dev/null)"
bash "$IN" filed-since >/dev/null 2>&1; ck item3-usage-exit-2 2 "$?"
bash "$IN" filed-since not-a-time >/dev/null 2>&1; ck item3-bad-time-exit-2 2 "$?"
cd "$T" || exit 1
# the trigger is written where a reader of the run skill finds it, and the shipped text names neither this repository's label nor its release rules
has item3-skill-trigger "$SK" 'revisit after two runs, or when a report says nothing new more than once'
has item3-skill-names-subcommand "$SK" 'intake.sh" filed-since'
ck item3-script-names-no-repository-label 0 "$(grep -c 'plugin:factory' "$IN")"

# ---- item 2 (#167, D6): kind 1 is blocked or defective input; no kind 8 ----
has item2-protocol-kind1-name "$PR" '| 1 | `blocked-input` | a result with `Status: blocked` whose `Missing` lists an input'
has item2-protocol-kind1-defective "$PR" 'a defect in an input that another role or an earlier stage produced'
has item2-protocol-blocked-or-defective "$PR" 'Kind 1 is blocked or defective input'
has item2-protocol-needs-decision "$PR" 'A `Status: needs-decision` question about such an input opens an andon of kind 1 beside the question'
has item2-skill-kind1-defective "$SK" '**Kind 1, at each result.** Blocked or defective input.'
has item2-skill-kind1-defect-rule "$SK" 'a defect in an input that another role or an earlier stage produced'
has item2-skill-needs-decision "$SK" 'a `Status: needs-decision` question about such an input opens an andon of kind 1 beside the question'
ck item2-still-seven-kinds 0 "$(grep -c '^| 8 |' "$PR")"
ck item2-no-kind-8-in-skill 0 "$(grep -ci 'kind 8' "$SK")"
# widening is not narrowing: every earlier observation of kind 1 is still in the row
has item2-old-observation-kept "$PR" 'not in that role'"'"'s `## Inputs needed` in `agents/<role>.md`'
has item2-old-exclusions-kept "$PR" 'Never kind 1: a fixed port taken (*Processes and ports*), and a blocked result that lists only listed entries'

# ---- item 4 (#166, D10): docs/direction.md ----
PO="$PLUGIN/agents/product-owner.md"; GL="$REPO/CONTEXT.md"
has item4-po-section "$PO" '## Direction document'
has item4-po-creates-when-destination-settled "$PO" 'When the destination is settled (run skill, steps 1 and 2) and `docs/direction.md` is missing, create it'
has item4-po-minimal-file "$PO" 'front matter `goal:` (the destination'"'"'s What) and `current:` (the map'"'"'s current focus), and under `## History` one line naming the map'
has item4-po-updates-only-on-destination-change "$PO" 'Update it later only when the map'"'"'s Destination changes'
has item4-po-never-overwrites "$PO" 'Never overwrite a line the factory did not write'
has item4-po-two-way "$PO" 'two-way step: ask no question, report it in your result'
has item4-po-intake-rule-kept "$PO" 'When intake triage decided an idea changes the direction'
has item4-skill-step1 "$SK" 'the product owner creates `docs/direction.md` if it is missing'
has item4-skill-step2 "$SK" 'the product owner updates `current` and adds one History line'
has item4-skill-boundary "$SK" 'say so in one line'
has item4-glossary-not-the-design-brief "$GL" '**Direction document**'
has item4-glossary-sentence "$GL" 'not the direction brief that the design plugin writes'
ck item4-glossary-sentence-in-skill "1" "$(grep -c "not the design plugin's direction brief" "$SK")"

# ---- item 5 (#158, D4): ADR provenance tags ----
AR="$PLUGIN/agents/architect.md"
has item5-template-section "$AR" '### ADR template'
has item5-tag-owner "$AR" '`(owner)`'
has item5-tag-architect "$AR" '`(architect)`'
has item5-owner-means-quote "$AR" '`(owner)` only for a reason quoted from the person'"'"'s answer on the decision card'
has item5-architect-means-assessment "$AR" '`(architect)` for your own assessment'
has item5-no-untagged-reason "$AR" 'Every stated reason carries exactly one tag'
has item5-owner-gave-none "$AR" 'When the person gave no reason for rejecting an option, say so and tag the reasons you give `(architect)`'
has item5-template-shape "$AR" '- <option>: rejected. <reason> `(owner)` or `(architect)`'
has item5-frontier-approval-stays "$PLUGIN/skills/run/SKILL.md" 'merge and clean up?'
ck item5-no-auto-merge-text 0 "$(grep -ci 'auto-merge\|without asking' "$AR")"

# ---- item 1 (#167, D5): a3-events.sh on the real records of the first site run (map #146; items #156, #168, #188) ----
# The records are read-only copies from the tracker (tests/factory/fixtures/a3events/). The A3 of that run listed none of the events below.
EV="$PLUGIN/scripts/a3-events.sh"
cd "$R" || exit 1
printf '%s\n' '| Label in mattpocock/skills | Label in our tracker | Meaning |' '|---|---|---|' '| `needs-triage` | `needs-triage` | evaluate |' > "$R/docs/agents/triage-labels.md"
STUB_ISSUES="$FX/issues-window.json" bash "$IN" filed-since $START $END --state all > "$T/filed.tsv"
cd "$T" || exit 1
ev() { bash "$EV" --item 146 --comments "$FX/comments-146.md" \
  --item 156 --ledger "$FX/ledger-156.md" --hansei "$FX/hansei-156.md" --comments "$FX/comments-156.md" \
  --item 168 --ledger "$FX/ledger-168.md" --hansei "$FX/hansei-168.md" --comments "$FX/comments-168.md" \
  --item 188 --ledger "$FX/ledger-188.md" --hansei "$FX/hansei-188.md" --comments "$FX/comments-188.md" "$@"; }
ev --filed "$T/filed.tsv" > "$T/events.txt"; ck item1-exit-0 0 "$?"
hasl() { has "$1" "$T/events.txt" "$2"; }
# CAN be detected from the records (structure, or a keyword in free text where marked):
hasl item1-detects-skip-withdrawn-168 '  event: withdrawn-skip #168 comment line 24 — cause: ?'
hasl item1-detects-gate-refusal-168 '  event: refusal #168 comment line 24 — cause: ?'
hasl item1-detects-bump-refusal-168 '  event: refusal #168 comment line 19 — cause: ?'
hasl item1-detects-rework-after-bump-168 '  event: rework #168 row 4 Build (round 2) (developer) — cause: ?'
hasl item1-detects-strict-yaml-defect-as-needs-decision-156 '  event: needs-decision #156 row 4 (developer) — cause: ?'
hasl item1-detects-heading-rework-156 '  event: rework #156 row 6 Build (round 2) (developer) — cause: ?'
hasl item1-detects-adr-correction-146 '  event: correction #146 comment line 9 — cause: ?'
hasl item1-detects-stop-with-188-in-flight '  event: person-stop #188 W1 — cause: ?'
hasl item1-detects-the-contract-rework-rounds-188 '  event: rework #188 row 4 Contracts and ADRs (round 2) (architect) — cause: ?'
hasl item1-detects-overturned-156 '  event: overturned #156 1 two-way decision — cause: ?'
hasl item1-detects-overturned-168 '  event: overturned #168 1 two-way decision — cause: ?'
hasl item1-detects-person-wait-188 '  event: wait #188 W1 person 1349m — cause: ?'
ck item1-event-count 20 "$(grep -c '^  event: ' "$T/events.txt")"
has item1-count-line "$T/events.txt" '- events: 20'
ck item1-every-event-has-a-cause-slot 20 "$(grep -c ' — cause: ?$' "$T/events.txt")"
# issues filed during the run, from the two sources: the ten factory issues of the run (#143 and #145 were filed before it started)
hasl item1-issues-line '- issues filed during the run: 10: #158 factory: a frontier round that only records answered decision cards should not n…; #159 '
hasl item1-issues-last '; #179 '
ck item1-issues-are-ten 10 "$(wc -l <"$T/filed.tsv" | tr -d ' ')"
# CANNOT be detected: the line says so, and no event line pretends otherwise
hasl item1-not-detectable-line '- not detectable from records: a brief refused by the scan; why a rework round happened; a contradiction between two contract rules (only the rework round it caused shows)'
ck item1-no-event-for-the-scan-refusal 0 "$(grep -c 'event: .*scan' "$T/events.txt")"
ck item1-no-event-names-a-contradiction 0 "$(grep -c 'event: .*contradict' "$T/events.txt")"
# what the script prints never carries a record's free text (a note, a title of a wait): only kinds, numbers, stages and roles
ck item1-no-free-text-copied 0 "$(grep -c 'Astro\|owner stopped\|YAML' "$T/events.txt")"
# a run with no record at all
bash "$EV" > "$T/empty.txt"; ck item1-empty-run-events "- events: none (no event in the records read)" "$(sed -n 1p "$T/empty.txt")"
ck item1-empty-run-issues "- issues filed during the run: none (no issue carried the triage label or the marker)" "$(sed -n 2p "$T/empty.txt")"
bash "$EV" --item x >/dev/null 2>&1; ck item1-bad-item-exit-2 2 "$?"
bash "$EV" --ledger "$FX/ledger-156.md" >/dev/null 2>&1; ck item1-ledger-without-item-exit-2 2 "$?"
bash "$EV" --item 1 --ledger "$T/none.md" >/dev/null 2>&1; ck item1-unreadable-exit-2 2 "$?"
ck item1-script-reads-no-network 0 "$(grep -v '^ *#' "$EV" | grep -cE '(^|[^a-z_-])(gh|curl|wget) ')"

# ---- item 1, the check: a3-check.sh refuses a v3 A3 without the events lines ----
AC="$PLUGIN/scripts/a3-check.sh"; A3F="$REPO/tests/factory/fixtures/a3"
c3() { OUT="$(/bin/bash "$AC" "$1" 2>&1)"; RC=$?; }
c3 "$A3F/v3-ok.md"; ck item1-v3-ok "0 ok v3" "$RC $OUT"
c3 "$A3F/v2-ok.md"; ck item1-v2-still-ok "0 ok v2" "$RC $OUT"
c3 "$A3F/v1-ok.md"; ck item1-v1-still-ok "0 ok v1" "$RC $OUT"
drop() { grep -v "$2" "$1" > "$T/m.md"; c3 "$T/m.md"; }
drop "$A3F/v3-ok.md" '^- events:'; ck item1-missing-events "1" "$RC"; echo "$OUT" | grep -qx 'refused: events (missing)' && ck item1-missing-events-reason 1 1 || ck item1-missing-events-reason "refused: events (missing)" "$OUT"
drop "$A3F/v3-ok.md" '^- issues filed during the run:'; echo "$OUT" | grep -qx 'refused: issues filed during the run (missing)' && ck item1-missing-issues-reason 1 1 || ck item1-missing-issues-reason "refused: issues filed during the run (missing)" "$OUT"
drop "$A3F/v3-ok.md" '^- not detectable from records:'; echo "$OUT" | grep -qx 'refused: not detectable from records (missing)' && ck item1-missing-notdetectable-reason 1 1 || ck item1-missing-notdetectable-reason "refused: not detectable from records (missing)" "$OUT"
# a line may read none (<reason>) as today
sed -e '/^  event: /d' -e 's/^- events: 2/- events: none (no event in the records read)/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-events-none-with-reason "0 ok v3" "$RC $OUT"
sed -e '/^  event: /d' -e 's/^- events: 2/- events: none/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-events-none-without-reason "1 refused: events (none needs a reason in parentheses)" "$RC $OUT"
sed -e 's/^- issues filed during the run: .*/- issues filed during the run: none (no issue carried the triage label or the marker)/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-issues-none-with-reason "0 ok v3" "$RC $OUT"
sed -e 's/^- not detectable from records: .*/- not detectable from records: none (every event kind is in the records)/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-notdetectable-none-with-reason "0 ok v3" "$RC $OUT"
# the count matches the event lines, and every event line carries a cause the lead wrote (a `?` left by the script is refused)
sed 's/^- events: 2/- events: 3/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-count-mismatch "1 refused: events (count does not match the event lines)" "$RC $OUT"
sed 's/ — cause: the merge approval was asked after the demo/ — cause: ?/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-cause-left-as-question-mark "1 refused: events (event without a cause)" "$RC $OUT"
sed 's/ — cause: the merge approval was asked after the demo//' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-cause-missing "1 refused: events (event without a cause)" "$RC $OUT"
sed 's/ — cause: the merge approval was asked after the demo/ — cause:   /' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-cause-blank "1 refused: events (event without a cause)" "$RC $OUT"
# the lines are part of v3 only
sed 's/^<!-- factory:a3 v3 -->/<!-- factory:a3 v2 -->/' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-v2-with-events-refused "1" "$RC"
echo "$OUT" | grep -qx 'refused: events (not part of v2)' && ck item1-v2-events-reason 1 1 || ck item1-v2-events-reason "refused: events (not part of v2)" "$OUT"
# order: after items counted, before still uncertain
awk '/^- not detectable/ {n=$0; next} {print} /^- baseline:/ {print n}' "$A3F/v3-ok.md" > "$T/m.md"; c3 "$T/m.md"; ck item1-out-of-order "1 refused: still uncertain (out of order)" "$RC $OUT"
# the script's own output, with a cause written for each event, passes the check (the two halves agree)
{ sed -n '1,/^- items counted/p' "$A3F/v3-ok.md"; ev --filed "$T/filed.tsv" | sed 's/ — cause: ?$/ — cause: written by the lead/'; sed -n '/^- still uncertain/,$p' "$A3F/v3-ok.md"; } > "$T/real.md"; c3 "$T/real.md"; ck item1-script-output-passes-the-check "0 ok v3" "$RC $OUT"
{ sed -n '1,/^- items counted/p' "$A3F/v3-ok.md"; ev --filed "$T/filed.tsv"; sed -n '/^- still uncertain/,$p' "$A3F/v3-ok.md"; } > "$T/real.md"; c3 "$T/real.md"; ck item1-script-output-without-causes-is-refused "1 refused: events (event without a cause)" "$RC $OUT"
# the standard names the lines and who writes what
A3S="$PLUGIN/references/a3.md"
has item1-standard-v3-marker "$A3S" '<!-- factory:a3 v3 -->'
has item1-standard-events-line "$A3S" '- events: <n | none (<reason>)>'
has item1-standard-lead-adds-cause "$A3S" 'The lead adds the cause of each event and nothing else'
has item1-standard-not-detectable "$A3S" '- not detectable from records:'
has item1-skill-runs-script "$SK" 'scripts/a3-events.sh'

done_
