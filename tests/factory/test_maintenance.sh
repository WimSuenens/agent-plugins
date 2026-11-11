#!/bin/bash
# The autonomous maintenance cycle. Issue #117, spec #108.
# Two seams: the scripts (maintenance.sh against a stub gh, integrator.sh) and the standard text.
. "$(dirname "$0")/lib.sh"
T="$(cd "$T" && pwd -P)"
MT="$PLUGIN/scripts/maintenance.sh"; IN="$PLUGIN/scripts/integrator.sh"
RUN="$PLUGIN/skills/run/SKILL.md"; AG="$PLUGIN/agents/integrator.md"
mkdir -p "$T/bin" "$T/g"
cp "$REPO/tests/factory/stub-gh/gh" "$T/bin/gh"
export STUB_GH_DIR="$T/g" PATH="$T/bin:$PATH"
reset() { echo '[]' >"$T/g/issues.json"; : >"$T/g/log"; }
sig() { printf '{"backlog_ready":%s,"ci":"%s","rework":%s,"merges_since_cycle":%s,"inbox_aged":%s,"vulnerable_deps":%s}\n' "$1" "$2" "$3" "$4" "$5" "$6" >"$T/s.json"; }
dec() { bash "$MT" decide "$T/s.json" 2>&1; }

# --- scripts seam: signal evaluation (backlog, ci, rework paths, merges, aged inbox, vulnerable deps)
sig 5 green '[]' 0 0 0
ck no-signal-no-cycle "maintenance: skip -- no signal" "$(dec)"
sig 0 green '[]' 0 0 0;  ck signal-backlog-empty "maintenance: run -- signal: backlog empty or nearly empty (0 ready)" "$(dec)"
sig 1 green '[]' 0 0 0;  ck signal-backlog-nearly-empty "maintenance: run -- signal: backlog empty or nearly empty (1 ready)" "$(dec)"
sig 2 green '[]' 0 0 0;  ck backlog-two-is-not-low "maintenance: skip -- no signal" "$(dec)"
sig 5 red '[]' 0 0 0;    ck signal-red-ci "maintenance: run -- signal: red CI" "$(dec)"
sig 5 green '[{"path":"plugins/x/","count":2}]' 0 0 0
ck signal-rework "maintenance: run -- signal: repeated rework on plugins/x/ (2)" "$(dec)"
sig 5 green '[{"path":"plugins/x/","count":1}]' 0 0 0
ck one-rework-is-not-repeated "maintenance: skip -- no signal" "$(dec)"
sig 5 green '[]' 5 0 0;  ck signal-merges "maintenance: run -- signal: 5 merges since the last cycle" "$(dec)"
sig 5 green '[]' 4 0 0;  ck four-merges-no-signal "maintenance: skip -- no signal" "$(dec)"
sig 5 green '[]' 0 1 0;  ck signal-aged-inbox "maintenance: run -- signal: 1 untriaged inbox item older than a run" "$(dec)"
sig 5 green '[]' 0 0 1;  ck signal-vulnerable-dep "maintenance: run -- signal: 1 known vulnerable dependency" "$(dec)"
sig 5 red '[]' 0 0 1;    ck first-signal-named-first "maintenance: run -- signal: red CI; 1 known vulnerable dependency" "$(dec)"
ck decide-one-line "1" "$(dec | wc -l | tr -d ' ')"
echo '{"ci":"green"}' >"$T/s.json"; ck missing-fields-read-as-quiet "maintenance: skip -- no signal" "$(dec)"
echo 'nope' >"$T/s.json"; bash "$MT" decide "$T/s.json" >/dev/null 2>&1; ck malformed-snapshot-exit-2 2 "$?"
bash "$MT" decide "$T/none" >/dev/null 2>&1; ck missing-snapshot-exit-2 2 "$?"
bash "$MT" bogus >/dev/null 2>&1; ck unknown-exit-2 2 "$?"

# --- scripts seam: candidates only, per-cycle budget
printf 'factory-state: 2\n' >"$T/f0"; printf 'maintenance-budget: 2 candidates\n' >"$T/f2"
ck budget-default "10" "$(bash "$MT" budget "$T/f0")"
ck budget-set "2" "$(bash "$MT" budget "$T/f2")"
printf 'maintenance-budget: zero\n' >"$T/fb"; bash "$MT" budget "$T/fb" >/dev/null 2>&1; ck budget-bad-exit-5 5 "$?"
reset; printf 'The ledger test is flaky on slow disks.\n' >"$T/b.md"
out="$(bash "$MT" candidate c1 diagnose "Diagnose flaky ledger test" "$T/b.md" "$T/f2")"; rc=$?
ck cand-rc 0 "$rc"
ck cand-line "candidate https://example.invalid/o/r/issues/1 diagnose" "$out"
ck cand-label "yes" "$(grep -q -- '--label maintenance' "$T/g/log" && echo yes || echo no)"
ck cand-marker "<!-- factory:maintenance c1 diagnose -->" "$(jq -r '.[0].body' "$T/g/issues.json" | head -1)"
ck cand-only-creates "0" "$(grep -c -E '^(pr|issue edit|issue close)' "$T/g/log")"
bash "$MT" candidate c1 review "Review last merge" "$T/b.md" "$T/f2" >/dev/null; ck cand-second-ok 0 "$?"
bash "$MT" candidate c1 triage "Third" "$T/b.md" "$T/f2" >"$T/o" 2>"$T/e"; ck budget-stops-cycle-exit-7 7 "$?"
ck budget-stop-message "maintenance budget reached: 2 of 2 candidates this cycle; stop the cycle" "$(cat "$T/e")"
ck budget-nothing-filed-over "2" "$(jq 'length' "$T/g/issues.json")"
bash "$MT" candidate c2 triage "New cycle" "$T/b.md" "$T/f2" >/dev/null; ck budget-is-per-cycle 0 "$?"
bash "$MT" candidate c3 gardening "x" "$T/b.md" "$T/f2" >/dev/null 2>&1; ck bad-activity-exit-2 2 "$?"
printf 'my path is /%s/someone/secret\n' Users >"$T/leak.md"
bash "$MT" candidate c4 triage "x" "$T/leak.md" "$T/f2" >/dev/null 2>&1; ck scan-refused-exit-6 6 "$?"
reset
bash "$MT" candidate c5 architecture "Deepen the board module" "$T/b.md" "$T/f2" --one-way-door >/dev/null; ck door-cand-rc 0 "$?"
ck door-label "yes" "$(grep -q -- 'one-way-door' "$T/g/log" && echo yes || echo no)"
has door-body-not-executed "$T/g/issues.json" 'Not executed: touches a one-way door; it needs a decision card'

# --- scripts seam: the integrator ranks maintenance beside features and does not start a door
lf() { { echo "# t"; echo; echo "Paths:"; echo "- $2"; echo "shared: none"; } >"$T/$1"; }
lf c-a.md a/; lf c-b.md b/; lf c-c.md c/
cat >"$T/bd.json" <<JSON
{"now":"2026-11-11T12:00:00Z","slices":[
 {"id":"1","status":"Ready","kind":"feature","contracts":["$T/c-a.md"]},
 {"id":"2","status":"Ready","kind":"maintenance","contracts":["$T/c-b.md"]},
 {"id":"3","status":"Ready","kind":"maintenance","one_way_door":true,"contracts":["$T/c-c.md"]}]}
JSON
out="$(bash "$IN" plan "$T/bd.json")"
ck rank-beside-features "order: 1 2 3" "$(printf '%s\n' "$out" | grep '^order:')"
ck maint-starts-like-feature "start 2 -- no overlap with a slice in flight or an earlier start" "$(printf '%s\n' "$out" | grep '^start 2 ')"
ck door-not-started "pause 3 -- one-way door: waits for the person's decision card, not executed" "$(printf '%s\n' "$out" | grep '^pause 3 ')"

# --- standard text seam
has text-section "$RUN" '## Maintenance cycle'
has text-signals "$RUN" 'backlog empty or nearly empty (at most 1 ready slice), red CI or repeated rework on a path (2 or more), 5 or more merges since the last cycle, an untriaged inbox item older than a run, a known vulnerable dependency'
has text-none-no-cycle "$RUN" 'With none present, no cycle runs'
has text-announce "$RUN" 'At run start, before intake, state in one line whether maintenance runs and on which signal'
has text-announce-script "$RUN" 'maintenance.sh" decide'
has text-skills "$RUN" 'triage, bug diagnosis, architecture improvement, code review and retrospective'
has text-read-and-follow "$RUN" 'those a model cannot invoke are read and followed by hand'
has text-candidates-only "$RUN" 'Maintenance produces backlog candidates of the maintenance kind and changes no code, file or issue directly'
has text-one-way-door "$RUN" 'A candidate that touches a one-way door is filed with `--one-way-door` and is not executed'
has text-budget "$RUN" 'The per-cycle budget is `maintenance-budget` in `docs/agents/factory.md`'
has text-budget-stop "$RUN" 'exit 7 stops the cycle'
has text-ranked "$RUN" 'the integrator ranks them beside the feature candidates'
has agent-ranks "$AG" 'maintenance candidates beside feature candidates'
has agent-door "$AG" 'one-way door'
has template-budget "$PLUGIN/skills/setup-factory-skill/assets/factory.md" 'maintenance-budget: 10 candidates'
has glossary "$REPO/CONTEXT.md" '**Maintenance cycle**'
has adr-0017-amended "$REPO/docs/adr/0017-a-run-is-a-cycle-over-a-standing-backlog.md" 'maintenance cycle'
done_
