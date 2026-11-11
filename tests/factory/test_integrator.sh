#!/bin/bash
# Slice 112, the integrator: the scripts seam (a plan from a fake board) and the standard-text seam (events, authority split, no state).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
IN="$PLUGIN/scripts/integrator.sh"
RUN="$PLUGIN/skills/run/SKILL.md"
AG="$PLUGIN/agents/integrator.md"
cd "$T" || exit 1

# lf <name> <shared> <path>...: a contract file with a Paths block
lf() { local n="$1" sh="$2"; shift 2; { echo "# t"; echo; echo "Paths:"; for p in "$@"; do echo "- $p"; done; echo "shared: $sh"; } >"$T/$n"; }
lf c-a.md none "x/"; lf c-b.md none "x/y.md"; lf c-c.md none "z/"; lf c-d.md none "w/"; lf c-run.md none "r/"; lf c-pr.md none "q/"; lf c-qo.md none "q/o.md"
NOW="2026-11-11T12:00:00Z"
plan() { bash "$IN" plan "$1" 2>&1; }

# ---------- scripts seam ----------
# several ready slices: non-overlapping start, overlapping pause with a reason
cat >"$T/b1.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"1","status":"Ready","ready_since":"2026-11-11T10:00:00Z","contracts":["$T/c-a.md"]},
 {"id":"2","status":"Ready","ready_since":"2026-11-11T11:30:00Z","contracts":["$T/c-b.md"]},
 {"id":"3","status":"Ready","ready_since":"2026-11-11T09:00:00Z","contracts":["$T/c-c.md"]}]}
JSON
out="$(plan "$T/b1.json")"; rc=$?
ck plan-exit 0 "$rc"
ck plan-starts-first "start 1 -- no overlap with a slice in flight or an earlier start" "$(printf '%s\n' "$out" | grep '^start 1 ')"
ck plan-pauses-overlap "pause 2 -- overlaps 1 on x/y.md x/" "$(printf '%s\n' "$out" | grep '^pause 2 ')"
ck plan-starts-nonoverlap "start 3 -- no overlap with a slice in flight or an earlier start" "$(printf '%s\n' "$out" | grep '^start 3 ')"
ck plan-order-follows-priority "order: 1 2 3" "$(printf '%s\n' "$out" | grep '^order:')"

# a slice in flight blocks an overlapping ready slice; its list is read too
cat >"$T/b2.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"10","status":"Running","contracts":["$T/c-run.md","$T/c-d.md"]},
 {"id":"11","status":"Ready","contracts":["$T/c-d.md"]}]}
JSON
ck inflight-pauses "pause 11 -- overlaps 10 on w/ w/" "$(plan "$T/b2.json" | grep '^pause 11 ')"

# merges come first and their paths stay held until the merge
cat >"$T/b3.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"20","status":"Ready","contracts":["$T/c-qo.md"]},
 {"id":"21","status":"Waiting on you","pr":"310","merge_ready":true,"contracts":["$T/c-pr.md"]},
 {"id":"22","status":"Ready","contracts":["$T/c-d.md"]}]}
JSON
out="$(plan "$T/b3.json")"
ck merge-first "merge 21 -- PR 310 approved; merges before any start" "$(printf '%s\n' "$out" | grep -E -m1 '^(merge|start|pause)')"
ck merge-holds-paths "pause 20 -- overlaps 21 on q/o.md q/" "$(printf '%s\n' "$out" | grep '^pause 20 ')"
ck merge-others-start "start 22 -- no overlap with a slice in flight or an earlier start" "$(printf '%s\n' "$out" | grep '^start 22 ')"

# a dependency: a different order, and why
cat >"$T/b4.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"30","status":"Ready","depends_on":["31"],"contracts":["$T/c-a.md"]},
 {"id":"31","status":"Ready","contracts":["$T/c-c.md"]}]}
JSON
out="$(plan "$T/b4.json")"
ck dep-order "order: 31 30" "$(printf '%s\n' "$out" | grep '^order:')"
ck dep-advise "advise: 31 before 30 -- 30 depends on 31" "$(printf '%s\n' "$out" | grep '^advise:')"
ck dep-pause "pause 30 -- waits for 31 (dependency not done)" "$(printf '%s\n' "$out" | grep '^pause 30 ')"
ck dep-start "start 31 -- no overlap with a slice in flight or an earlier start" "$(printf '%s\n' "$out" | grep '^start 31 ')"
# a dependency that is done does not hold
cat >"$T/b5.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"32","status":"Done","created":"2026-11-10T12:00:00Z","closed":"2026-11-11T09:30:00Z"},
 {"id":"33","status":"Ready","depends_on":["32"],"contracts":["$T/c-a.md"]},
 {"id":"34","status":"Ready","depends_on":["99"],"contracts":["$T/c-c.md"]}]}
JSON
out="$(plan "$T/b5.json")"
ck dep-done-starts "start 33 -- no overlap with a slice in flight or an earlier start" "$(printf '%s\n' "$out" | grep '^start 33 ')"
ck dep-unknown-pauses "pause 34 -- waits for 99 (dependency not on the board)" "$(printf '%s\n' "$out" | grep '^pause 34 ')"
ck no-advise-when-order-kept "0" "$(printf '%s\n' "$out" | grep -c '^advise:')"

# no path list yet
cat >"$T/b6.json" <<JSON
{"now":"$NOW","slices":[{"id":"40","status":"Ready"},{"id":"41","status":"Ready","contracts":["$T/missing.md"]}]}
JSON
out="$(plan "$T/b6.json")"
ck nolist-pauses "pause 40 -- no path list yet (the architect stage is not done)" "$(printf '%s\n' "$out" | grep '^pause 40 ')"
ck unreadable-list-pauses "pause 41 -- no path list yet (the architect stage is not done)" "$(printf '%s\n' "$out" | grep '^pause 41 ')"

# no state: the same board gives the same plan, from a different directory and run twice
a="$(plan "$T/b1.json")"; mkdir -p "$T/other"; b="$(cd "$T/other" && bash "$IN" plan "$T/b1.json" 2>&1)"
ck same-board-same-plan "$a" "$b"
ck rerun-same-plan "$a" "$(plan "$T/b1.json")"
ck no-state-files "" "$(find "$T/other" -type f | head -1)"
hasnt no-state-in-script "$IN" "mktemp"

# measures, with not captured
cat >"$T/b7.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"50","status":"Ready","ready_since":"2026-11-11T10:30:00Z","contracts":["$T/c-a.md"]},
 {"id":"51","status":"Ready","contracts":["$T/c-c.md"]},
 {"id":"52","status":"Done","created":"2026-11-10T12:00:00Z","closed":"2026-11-11T09:30:00Z"},
 {"id":"53","status":"Done"}]}
JSON
out="$(plan "$T/b7.json")"
ck measure-waiting "measure waiting 50 1h30m" "$(printf '%s\n' "$out" | grep '^measure waiting 50 ')"
ck measure-waiting-missing "measure waiting 51 not captured" "$(printf '%s\n' "$out" | grep '^measure waiting 51 ')"
ck measure-lead "measure lead-time 52 21h30m" "$(printf '%s\n' "$out" | grep '^measure lead-time 52 ')"
ck measure-lead-missing "measure lead-time 53 not captured" "$(printf '%s\n' "$out" | grep '^measure lead-time 53 ')"
ck measure-batch "measure batch-size 2" "$(printf '%s\n' "$out" | grep '^measure batch-size ')"
ck measure-wip "measure in-flight 0" "$(printf '%s\n' "$out" | grep '^measure in-flight ')"
printf '{"slices":[{"id":"60","status":"Ready","ready_since":"2026-11-11T10:30:00Z","contracts":["%s/c-a.md"]}]}' "$T" >"$T/b8.json"
ck measure-no-now "measure waiting 60 not captured" "$(plan "$T/b8.json" | grep '^measure waiting 60 ')"

# empty board and usage
printf '{"now":"%s","slices":[]}' "$NOW" >"$T/b9.json"
ck empty-board-order "order:" "$(plan "$T/b9.json" | grep '^order:')"
bash "$IN" >/dev/null 2>&1; ck usage-exit-2 2 "$?"
bash "$IN" plan "$T/nonexistent.json" >/dev/null 2>&1; ck missing-file-exit-2 2 "$?"
printf 'not json' >"$T/bad.json"; bash "$IN" plan "$T/bad.json" >/dev/null 2>&1; ck bad-json-exit-2 2 "$?"

# regressions from review: a dependency already in order is not advised; a malformed id is refused; a dependency and an overlap both give their reason
cat >"$T/r1.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"A","status":"Ready","contracts":["$T/c-a.md"]},
 {"id":"B","status":"Ready","depends_on":["A"],"contracts":["$T/c-c.md"]}]}
JSON
ck no-advise-when-dependency-already-first "0" "$(plan "$T/r1.json" | grep -c '^advise:')"
printf '{"now":"%s","slices":[{"status":"Ready"}]}' "$NOW" >"$T/r2.json"
bash "$IN" plan "$T/r2.json" >/dev/null 2>&1; ck slice-without-id-exit-2 2 "$?"
cat >"$T/r3.json" <<JSON
{"now":"$NOW","slices":[
 {"id":"10","status":"Running","contracts":["$T/c-run.md"]},
 {"id":"11","status":"Ready","depends_on":["12"],"contracts":["$T/c-run.md"]},
 {"id":"12","status":"Ready","contracts":["$T/c-d.md"]}]}
JSON
ck pause-gives-both-reasons "pause 11 -- waits for 12 (dependency not done); overlaps 10 on r/ r/" "$(plan "$T/r3.json" | grep '^pause 11 ')"

# ---------- standard-text seam ----------
ck agent-exists yes "$([ -f "$AG" ] && echo yes || echo no)"
ck agent-name "name: integrator" "$(sed -n '2p' "$AG")"
has agent-reads-protocol "$AG" 'references/protocol.md'
has agent-board-only-source "$AG" 'The board is your only source of truth'
has agent-no-state "$AG" 'You keep no state between calls'
has agent-same-board-same-plan "$AG" 'the same board gives the same plan'
has agent-priority-stays "$AG" 'Priority stays with the lead and the person'
has agent-advises-dependency "$AG" 'advise a different order'
has agent-no-spawn "$AG" 'subagents cannot spawn subagents'
has agent-no-tracker-write "$AG" 'You make no tracker write'
has agent-lean "$AG" 'pull'
has agent-wip "$AG" 'work in progress'
has agent-measures "$AG" 'waiting time, lead time and batch size'
has agent-not-captured "$AG" 'not captured'
has agent-script "$AG" 'scripts/integrator.sh plan'
has agent-improvement-loop "$AG" 'improvement loop'
for ev in "intake processed" "slice ready" "PR opened" "merge done" "map changed"; do has "run-event-$ev" "$RUN" "$ev"; done
has run-section "$RUN" '## The integrator'
has run-spawns-per-plan "$RUN" 'spawn the roles the plan names'
has run-no-nested-spawn "$RUN" 'subagents cannot spawn subagents'
has run-priority-lead "$RUN" 'Priority stays with you and the person'
has run-eight-roles "$RUN" 'Eight role agents'
has run-integrator-agent "$RUN" '`factory:integrator`'
FM="$REPO/docs/agents/factory.md"; TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"
ck devops-description-unchanged "description: Delivery. Use for pipelines, environments, deployment, rollback, monitoring, and secrets handling." "$(sed -n '3p' "$PLUGIN/agents/devops.md")"
hasnt devops-no-dispatch "$PLUGIN/agents/devops.md" 'dispatch'
has protocol-shell "$PLUGIN/references/protocol.md" '**integrator**'
has guard-role "$PLUGIN/scripts/guard-memory.sh" ' integrator '
ck integrator-model-sonnet "model: sonnet" "$(grep -E "^model:" "$AG")"
ck version-2.10.0 "2.10.0" "$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")"
done_
