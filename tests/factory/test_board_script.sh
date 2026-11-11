#!/bin/bash
# Slice 64, board.sh: AC-2, AC-6, AC-20, AC-21 (setup) and AC-35 to AC-43 (the migration), against the fake gh and stateful boards.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
SK="$PLUGIN/skills/setup-factory-skill/SKILL.md"
fake_setup
cd "$T" || exit 1

old_ids='["o_backlog","o_ready","o_designed","o_inprogress","o_inreview","o_rtd","o_done"]'
# the final board a correct migration must give, written from the requirement (AC-38): the mapping, the other values untouched
expected_items() {
  jq -S '[.items | sort_by(.id)[] | {id, values: (.values
     | if .["factory status"] == "Designed" then .["factory status"] = "Ready"
       elif .["factory status"] == "In progress" or .["factory status"] == "In review" then .["factory status"] = "Running"
       elif .["factory status"] == "Ready to deploy" then .["factory status"] = "Waiting on you" else . end)}]' "$FX64/board-v1.json"
}
items_now() { jq -S '[.items | sort_by(.id)[] | {id, values}]' "$T/board.json"; }
optnames() { jq -c '[.fields[] | select(.name == "Factory status") | .options[].name]' "$T/board.json"; }
fresh_run() { # board-v1 to completion: apply (exit 10 for the views), apply --views-confirmed
  board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
  bsa apply --yes
}

# ---------- AC-37: plan prints the table and the counts, and changes nothing ----------
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
bsa plan
ck ac37-plan-exit-0 0 "$BS_RC"
ck ac37-plan-no-mutation-call 0 "$(log_mutations)"
ck ac37-plan-no-unknown-op 0 "$(log_unknown)"
ck ac37-plan-writes-nothing-to-state-dir 0 "$([ -e "$SD" ] && echo 1 || echo 0)"
want='board: project fixt/77
state: seven-option board
map: Designed -> Ready (2 items)
map: In progress -> Running (2 items)
map: In review -> Running (2 items)
map: Ready to deploy -> Waiting on you (1 items)
map: Backlog -> Backlog (unchanged, 2 items)
map: Ready -> Ready (unchanged, 1 items)
map: Done -> Done (unchanged, 1 items)
map: no Factory status -> left as it is (1 items: #112)'
ck ac37-plan-table-and-counts "$want" "$(sed -n 1,10p "$T/bs.out")"
ck ac37-plan-count-line "count: change 7, stay 4" "$(grep '^count:' "$T/bs.out")"
ck ac37-plan-counts-sum-to-12 12 "$((7 + 4 + 1))"
has ac43-plan-note-many-to-one "$T/bs.out" "note: In progress and In review both become Running. The old distinction is restorable only from the snapshot, never from the board."
ck ac37-plan-snapshot-line-names-tail-only "snapshot: …/factory/board-fixt-77/snapshot-1.json (written by apply, before the first change)" "$(grep '^snapshot:' "$T/bs.out")"
ck ac37-plan-no-home-path-in-output 0 "$(grep -c "$HOME" "$T/bs.out" "$T/bs.err" | awk -F: '{s+=$2} END{print s+0}')"
# plan works without a project id (the developer's question 09, option A)
log_reset; board_load "$FX64/board-v1.json"
bs plan --state-dir "$SD"
ck ac37-plan-without-project-id-exit-0 0 "$BS_RC"
ck ac37-plan-without-project-id-skips-views-read 0 "$(log_count B-views)"

# apply without --yes: exit 2, no call at all
log_reset; board_load "$FX64/board-v1.json"
bsa apply
ck ac37-apply-without-yes-exit-2 2 "$BS_RC"
ck ac37-apply-without-yes-no-gh-call 0 "$(wc -l <"$T/gh.log" | tr -d ' ')"
ck ac37-apply-without-yes-says-why "board: apply needs --yes" "$(cat "$T/bs.err")"
# apply and finish need the project id (lead's answer to question 09)
log_reset; bs apply --yes --state-dir "$SD"
ck q09-apply-without-project-id-exit-2 2 "$BS_RC"
ck q09-apply-without-project-id-message "board: project id unknown (--project-id, or the Tracker table)" "$(cat "$T/bs.err")"
ck q09-apply-without-project-id-no-mutation 0 "$(log_mutations)"
ck q09-finish-without-project-id-exit-2 "2" "$(bash "$BOARD_SH" finish --owner fixt --project 77 --views-confirmed >/dev/null 2>&1; echo $?)"
# a factory-md fixture with a matching project id row supplies the id
cat > "$T/fm-match.md" <<'F'
| Key | Value |
|---|---|
| owner | fixt |
| project number | 77 |
| project id | PVT_fixture01 |
F
log_reset; board_load "$FX64/board-v1.json"; rm -rf "$SD"
bash "$BOARD_SH" apply --yes --factory-md "$T/fm-match.md" --state-dir "$SD" >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck q09-matching-tracker-row-supplies-project-id 10 "$rc"
# the row is used only when owner and number match
log_reset; board_load "$FX64/board-v1.json"; rm -rf "$SD"
bash "$BOARD_SH" apply --yes --factory-md "$T/fm-match.md" --owner fixt --project 78 --state-dir "$SD" >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck q09-row-for-another-project-not-used 2 "$rc"
ck q09-row-for-another-project-no-mutation 0 "$(log_mutations)"

# ---------- AC-35, AC-36, AC-38: apply on Board-v1 ----------
fresh_run
ck ac35-apply-exit-10-views-need-confirmation 10 "$BS_RC"
ck ac35-no-unknown-op 0 "$(log_unknown)"
# order: reads, B-foptions, all B-set, B-foptions
ops_str="$(log_ops | grep -E '^(B-foptions|B-set)$' | paste -sd' ' -)"
ck ac35-order-foptions-then-seven-sets-then-foptions "B-foptions B-set B-set B-set B-set B-set B-set B-set B-foptions" "$ops_str"
ck ac35-first-foptions-has-ten-options 10 "$(jq -s '[.[] | select(.op == "B-foptions")][0].stdin | fromjson | .variables.input.singleSelectOptions | length' "$T/gh.log")"
ck ac35-first-foptions-sends-every-old-option-with-its-id "$old_ids" "$(jq -sc '[.[] | select(.op == "B-foptions")][0].stdin | fromjson | [.variables.input.singleSelectOptions[:7][] | .id]' "$T/gh.log")"
ck ac35-first-foptions-new-options-have-no-id '["Running","Waiting on you","Blocked"]' "$(jq -sc '[.[] | select(.op == "B-foptions")][0].stdin | fromjson | [.variables.input.singleSelectOptions[7:][] | select(has("id") | not) | .name]' "$T/gh.log")"
ck ac35-first-foptions-keeps-colour-and-description '["GRAY","About Backlog"]' "$(jq -sc '[.[] | select(.op == "B-foptions")][0].stdin | fromjson | .variables.input.singleSelectOptions[0] | [.color, .description]' "$T/gh.log")"
ck ac35-second-foptions-six-final-options-all-with-ids 6 "$(jq -s '[.[] | select(.op == "B-foptions")][1].stdin | fromjson | [.variables.input.singleSelectOptions[] | select(.id != null)] | length' "$T/gh.log")"
ck ac35-second-foptions-order '["Backlog","Ready","Running","Waiting on you","Blocked","Done"]' "$(jq -sc '[.[] | select(.op == "B-foptions")][1].stdin | fromjson | [.variables.input.singleSelectOptions[].name]' "$T/gh.log")"
ck ac35-second-foptions-keeps-old-ids-of-kept-options '["o_backlog","o_ready"]' "$(jq -sc '[.[] | select(.op == "B-foptions")][1].stdin | fromjson | [.variables.input.singleSelectOptions[:2][] | .id]' "$T/gh.log")"
ck ac35-no-foptions-call-sends-an-existing-option-without-id 0 "$(jq -s '[.[] | select(.op == "B-foptions") | .stdin | fromjson | .variables.input.singleSelectOptions[] | select(has("id") | not) | select(.name | IN("Backlog","Ready","Done","Designed","In progress","In review","Ready to deploy"))] | length' "$T/gh.log")"
ck ac35-final-options '["Backlog","Ready","Running","Waiting on you","Blocked","Done"]' "$(optnames)"
# AC-38: the mapping and nothing else
ck ac38-final-items-equal-board-v2 "$(expected_items)" "$(items_now)"
ck ac38-exactly-seven-item-edits 7 "$(log_count B-set)"
ids_set="$(jq -r 'select(.op == "B-set") | .argv | .[index("--id") + 1]' "$T/gh.log" | sort | paste -sd' ' -)"
ck ac38-item-edits-only-on-old-valued-items "PVTI_10 PVTI_4 PVTI_5 PVTI_6 PVTI_7 PVTI_8 PVTI_9" "$ids_set"
ck ac38-no-edit-on-backlog-ready-done-or-no-status 0 "$(printf '%s\n' "$ids_set" | tr ' ' '\n' | grep -cE '^PVTI_(1|2|3|11|12)$')"
ck ac38-no-status-item-left-as-is "null" "$(jq -c '.items[] | select(.id == "PVTI_12") | .values["factory status"]' "$T/board.json")"
ck ac38-priority-values-kept '["high","high","low"]' "$(jq -c '[.items[] | select(.values.priority) | .values.priority] | sort' "$T/board.json")"
ck ac38-priority-of-item-108-kept "high" "$(jq -r '.items[] | select(.id == "PVTI_8") | .values.priority' "$T/board.json")"
ck ac38-estimate-of-done-item-kept "3" "$(jq -r '.items[] | select(.id == "PVTI_11") | .values.estimate' "$T/board.json")"
# AC-20 / AC-2: the fields exist with the fixed options, none twice
ck ac2-kind-options '["map","slice","role task","frontier ticket","idea"]' "$(jq -c '[.fields[] | select(.name == "Kind") | .options[].name]' "$T/board.json")"
ck ac2-role-options '["product-owner","architect","developer","qa-engineer","security-reviewer","devops","docs-writer"]' "$(jq -c '[.fields[] | select(.name == "Role") | .options[].name]' "$T/board.json")"
for f in Tokens Minutes Hours "Rework rounds" "Person touches"; do
  ck "ac20-field-$f-created-once-as-text" "ProjectV2Field 1" "$(jq -r --arg f "$f" '[.fields[] | select(.name == $f)] | "\(.[0].type) \(length)"' "$T/board.json")"
done
ck ac20-fcreate-text-fields-use-data-type-TEXT 5 "$(jq -s '[.[] | select(.op == "B-fcreate") | select(.argv | index("TEXT"))] | length' "$T/gh.log")"
# AC-36: the snapshot
ck ac36-snapshot-1-exists 1 "$([ -f "$SD/snapshot-1.json" ] && echo 1 || echo 0)"
snapshot="$SD/snapshot-1.json"
ck ac36-snapshot-mode-0600 "600" "$(stat -f '%Lp' "$snapshot" 2>/dev/null || stat -c '%a' "$snapshot")"
ck ac36-state-dir-mode-0700 "700" "$(stat -f '%Lp' "$SD" 2>/dev/null || stat -c '%a' "$SD")"
ck ac36-snapshot-holds-every-item 12 "$(jq '.items | length' "$snapshot")"
ck ac36-snapshot-item-holds-id-number-title '["PVTI_8",108,"In review one"]' "$(jq -c '.items[] | select(.id == "PVTI_8") | [.id, .number, .title]' "$snapshot")"
ck ac36-snapshot-status-has-id-and-name '{"id":"o_inreview","name":"In review"}' "$(jq -c '.items[] | select(.id == "PVTI_8") | .status' "$snapshot")"
ck ac36-snapshot-keeps-every-other-field '{"priority":"high"}' "$(jq -c '.items[] | select(.id == "PVTI_8") | .fields' "$snapshot")"
ck ac36-snapshot-extra-field-estimate '{"estimate":"5"}' "$(jq -c '.items[] | select(.id == "PVTI_7") | .fields' "$snapshot")"
ck ac36-snapshot-status-null-for-item-without-value "null" "$(jq -c '.items[] | select(.id == "PVTI_12") | .status' "$snapshot")"
ck ac36-snapshot-lists-the-seven-original-options 7 "$(jq '.options | length' "$snapshot")"
ck ac36-snapshot-note-original original "$(jq -r .note "$snapshot")"
inrepo() { case "$1" in "$REPO"/*) echo 1 ;; *) echo 0 ;; esac; }
ck ac36-snapshot-outside-any-repo 0 "$(inrepo "$SD")"
ck ac36-output-prints-the-snapshot-tail-only "snapshot: …/board-fixt-77/snapshot-1.json" "$(grep -m1 '^snapshot:' "$T/bs.out")"
ck ac36-no-home-or-tmp-path-in-output 0 "$(grep -cE "($HOME|$T)" "$T/bs.out" "$T/bs.err" | awk -F: '{s+=$2} END{print s+0}')"

# apply when the snapshot is written before the first mutation
first_mut="$(log_ops | grep -nE "^($MUTATION_OPS)$" | head -1 | cut -d: -f1)"
ck ac36-first-mutation-is-the-option-add "B-foptions" "$(log_ops | grep -E "^($MUTATION_OPS)$" | head -1)"
ck ac36-reads-come-before-first-mutation 1 "$([ "$first_mut" -gt 3 ] && echo 1 || echo 0)"

# ---------- AC-6, AC-21: views ----------
need=$(jq -s '([.[] | select(.op == "B-vcreate") | .stdin | fromjson | .variables.input | {name, layout}]) as $c | ([.[] | select(.op == "B-vupdate") | .stdin | fromjson | .variables.input.filter]) as $f | [range(0; $c | length) | $c[.] + {filter: $f[.]}]' "$T/gh.log")
ck ac69-create-sends-no-filter 0 "$(jq -s '[.[] | select(.op == "B-vcreate") | .stdin | fromjson | .variables.input | select(has("filter"))] | length' "$T/gh.log")"
ck ac6-needs-you-view-requested '{"name":"Needs you","layout":"TABLE_LAYOUT","filter":"factory-status:\"Waiting on you\""}' "$(printf '%s' "$need" | jq -c '.[0]')"
ck ac21-history-view-requested '{"name":"History","layout":"TABLE_LAYOUT","filter":"is:closed kind:slice,\"role task\""}' "$(printf '%s' "$need" | jq -c '.[0 + 1]')"
has ac6-accepted-asks-to-open-and-confirm "$T/bs.out" 'view: Needs you: requested; open it once and confirm it shows the filter factory-status:"Waiting on you"'
has ac21-history-asks-to-confirm "$T/bs.out" 'view: History: requested; open it once and confirm it shows the filter is:closed kind:slice,"role task"'
hasnt ac6-no-done-reported-for-unconfirmed-views "$T/bs.out" "apply done"
has ac6-asks-for-confirmation-then-rerun "$T/bs.out" "views: confirm that both views exist and filter, then run apply --yes --views-confirmed and finish --views-confirmed"
# finish refuses until confirmed
log_reset
bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck ac6-finish-without-views-confirmed-exit-2 2 "$rc"
ck ac6-finish-without-views-confirmed-no-gh-call 0 "$(wc -l <"$T/gh.log" | tr -d ' ')"
# a second run with the views present makes no second view, no mutation, and reports migrated
log_reset
bsa apply --yes --views-confirmed
ck ac6-rerun-with-views-present-exit-0 0 "$BS_RC"
ck ac6-rerun-no-second-view 0 "$(log_count B-vcreate)"
ck ac40-rerun-no-mutation-at-all 0 "$(log_mutations)"
ck ac40-rerun-says-already-migrated "already migrated" "$(cat "$T/bs.out")"
ck ac40-rerun-no-second-snapshot 1 "$(ls "$SD" | grep -c '^snapshot-')"
ck ac40-rerun-board-unchanged-count-of-views 2 "$(jq '[.views[] | select(.name == "Needs you" or .name == "History")] | length' "$T/board.json")"
cp "$T/board.json" "$T/board-v2.json"
# plan on a migrated board: "already migrated" and nothing else
log_reset; bsa plan
ck ac40-plan-on-migrated-prints-only-already-migrated "already migrated" "$(cat "$T/bs.out")"
ck ac40-plan-on-migrated-no-mutation 0 "$(log_mutations)"
# the view call is refused
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
FAKE_BOARD_REFUSE_VIEW=1 bsa apply --yes
ck ac6-refused-view-exit-10 10 "$BS_RC"
has ac6-refused-prints-manual-needs-you "$T/bs.out" 'view: Needs you: NOT created. Build it by hand: name "Needs you", table layout, filter factory-status:"Waiting on you"'
has ac21-refused-prints-manual-history "$T/bs.out" 'view: History: NOT created. Build it by hand: name "History", table layout, filter is:closed kind:slice,"role task", show Title, Kind, Role, Parent issue, Tokens, Minutes, Hours, Rework rounds, Person touches, order by closed, newest first'
hasnt ac6-refused-not-reported-created "$T/bs.out" "Needs you: requested"
hasnt ac6-refused-no-done "$T/bs.out" "apply done"
ck ac6-refused-no-view-in-board 0 "$(jq '[.views[] | select(.name == "Needs you" or .name == "History")] | length' "$T/board.json")"
# still refused on a re-run: still exit 10; finish refuses because the view is missing, and writes nothing
FAKE_BOARD_REFUSE_VIEW=1 bsa apply --yes --views-confirmed
ck ac6-refused-rerun-still-exit-10 10 "$BS_RC"
mkdir -p "$T/fin0"; printf '| Key | Value |\n|---|---|\n| owner | fixt |\n' >"$T/fin0/factory.md"; printf '# Issue tracker: GitHub\n' >"$T/fin0/tracker.md"
cp "$T/fin0/factory.md" "$T/fin0/factory.before"
bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$T/fin0/factory.md" --tracker-md "$T/fin0/tracker.md" >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck ac6-finish-with-a-missing-view-exit-2 2 "$rc"
ck ac6-finish-with-a-missing-view-writes-nothing 0 "$(cmp -s "$T/fin0/factory.md" "$T/fin0/factory.before" && echo 0 || echo 1)"

# the view is created but the filter update is refused: the person is told to set the filter by hand
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
FAKE_BOARD_REFUSE_VIEW_UPDATE=1 bsa apply --yes
ck ac69-refused-update-exit-10 10 "$BS_RC"
has ac69-refused-update-prints-set-filter-by-hand "$T/bs.out" 'view: Needs you: created, but its filter was NOT set. Open the view "Needs you" and set the filter by hand: factory-status:"Waiting on you"'
hasnt ac69-refused-update-not-reported-requested "$T/bs.out" "Needs you: requested"

# ---------- AC-38: a Project that clears a value when the option list is replaced ----------
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
FAKE_BOARD_CLEAR=priority bsa apply --yes
ck ac38-cleared-priority-stops-with-exit-5 5 "$BS_RC"
has ac38-cleared-priority-names-item-and-field "$T/bs.err" 'item #108: field "priority" changed'
ck ac38-cleared-priority-no-phase-2-call 0 "$(log_count B-set)"
ck ac38-cleared-priority-only-one-foptions 1 "$(log_count B-foptions)"
ck ac38-cleared-priority-no-done "0" "$(grep -c 'apply done' "$T/bs.out")"
# AC-38: a status edit that changes another field is caught too (the guard compares all fields)
# (covered by the fake above; here the control: without the fault the same run is clean)
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset; bsa apply --yes
ck ac38-control-without-fault-no-exit-5 10 "$BS_RC"

# ---------- AC-39: phase 3 only when no item holds an old value ----------
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
FAKE_BOARD_IGNORE_SET=PVTI_8 bsa apply --yes
ck ac39-stuck-item-exit-6 6 "$BS_RC"
has ac39-stuck-item-named "$T/bs.err" "board: item #108 (In review) still holds an old value; nothing dropped"
ck ac39-no-second-foptions 1 "$(log_count B-foptions)"
ck ac39-old-options-still-present "1" "$(optnames | jq -r 'index("In review") != null' | sed 's/true/1/')"
hasnt ac39-no-done "$T/bs.out" "apply done"
cp "$T/board.json" "$T/board-stuck.json"
# the item is re-set (fixture updated); the next run drops the four options
unset FAKE_BOARD_IGNORE_SET
log_reset; bsa apply --yes
ck ac39-next-run-after-update-exit-10-views 10 "$BS_RC"
ck ac39-next-run-drops-old-options '["Backlog","Ready","Running","Waiting on you","Blocked","Done"]' "$(optnames)"
ck ac39-next-run-final-items-equal-board-v2 "$(expected_items)" "$(items_now)"
ck ac39-second-snapshot-kept-under-new-name 1 "$([ -f "$SD/snapshot-2.json" ] && echo 1 || echo 0)"
has ac36-rerun-says-which-is-original "$T/bs.out" "original snapshot: snapshot-1.json"

# AC-36: the re-run writes snapshot-2 and keeps snapshot-1 byte for byte (own sequence, hash taken before the re-run)
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
FAKE_BOARD_IGNORE_SET=PVTI_8 bsa apply --yes
h1="$(shasum -a 256 "$SD/snapshot-1.json" | cut -d' ' -f1)"
unset FAKE_BOARD_IGNORE_SET; bsa apply --yes
ck ac36-snapshot-1-unchanged-after-rerun "$h1" "$(shasum -a 256 "$SD/snapshot-1.json" | cut -d' ' -f1)"
ck ac36-snapshot-2-note "taken before re-run, migration in progress" "$(jq -r .note "$SD/snapshot-2.json")"
ck ac36-snapshot-2-is-not-the-original-one 1 "$([ "$(jq -r .note "$SD/snapshot-2.json")" != original ] && echo 1 || echo 0)"

# ---------- AC-36: state dir inside the repository ----------
mkdir -p "$T/repo/work/1" && git -C "$T/repo" init -q 2>/dev/null
( cd "$T/repo" && git add -A 2>/dev/null; git commit -q --allow-empty -m init 2>/dev/null )
board_load "$FX64/board-v1.json"; log_reset
( cd "$T/repo" && bash "$BOARD_SH" apply --yes --owner fixt --project 77 --project-id PVT_fixture01 --state-dir "$T/repo/snap" >"$T/bs.out" 2>"$T/bs.err" ); rc=$?
ck ac36-state-dir-in-repo-exit-2 2 "$rc"
ck ac36-state-dir-in-repo-message "board: state dir is inside the repository" "$(cat "$T/bs.err")"
ck ac36-state-dir-in-repo-no-mutation 0 "$(log_mutations)"
( cd "$T/repo" && bash "$BOARD_SH" plan --owner fixt --project 77 --state-dir "$T/repo/work/1/snap" >/dev/null 2>"$T/bs.err" ); rc=$?
ck ac36-state-dir-under-work-exit-2 2 "$rc"
# a relative state dir that resolves into the repo, and a dotdot path
( cd "$T/repo" && bash "$BOARD_SH" plan --owner fixt --project 77 --state-dir "./x/../snap2" >/dev/null 2>&1 ); ck ac36-relative-state-dir-in-repo-exit-2 2 "$?"
( cd "$T/repo" && bash "$BOARD_SH" plan --owner fixt --project 77 --state-dir "$T/state/../repo/snap3" >/dev/null 2>&1 ); ck ac36-dotdot-state-dir-in-repo-exit-2 2 "$?"
# a symlink to the repo
ln -s "$T/repo" "$T/replink"
( cd "$T/repo" && bash "$BOARD_SH" plan --owner fixt --project 77 --state-dir "$T/replink/snap4" >/dev/null 2>&1 ); ck ac36-symlinked-state-dir-in-repo-exit-2 2 "$?"
# outside the repo: git status unchanged
board_load "$FX64/board-v1.json"; log_reset
( cd "$T/repo" && bash "$BOARD_SH" apply --yes --owner fixt --project 77 --project-id PVT_fixture01 --state-dir "$T/state-out" >/dev/null 2>&1 )
ck ac36-git-status-unchanged "" "$(git -C "$T/repo" status --porcelain)"
# the default state dir comes from HOME (or XDG_STATE_HOME) and is outside the repo
board_load "$FX64/board-v1.json"; log_reset; mkdir -p "$T/home"
( cd "$T" && HOME="$T/home" XDG_STATE_HOME= bash "$BOARD_SH" plan --owner fixt --project 77 >"$T/bs.out" 2>&1 )
has ac36-default-state-dir-printed-by-tail-only "$T/bs.out" "snapshot: …/factory/board-fixt-77/snapshot-1.json"
board_load "$FX64/board-v1.json"; log_reset
( cd "$T" && HOME="$T/home" bash "$BOARD_SH" apply --yes --owner fixt --project 77 --project-id PVT_fixture01 >"$T/bs.out" 2>&1 )
ck ac36-default-state-dir-under-home-state 1 "$([ -f "$T/home/.local/state/factory/board-fixt-77/snapshot-1.json" ] && echo 1 || echo 0)"
ck ac36-default-output-has-no-home-path 0 "$(grep -c "$T" "$T/bs.out")"

# ---------- AC-40: interruption variants end at the same board ----------
clean_norm() { board_load "$FX64/board-v1.json"; rm -rf "$SD"; bsa apply --yes >/dev/null; bsa apply --yes --views-confirmed >/dev/null; board_norm; }
norm_clean="$(clean_norm)"
mid1() { jq '(.fields[] | select(.id == "fld_status") | .options) += [{id:"opt_n1",name:"Running",color:"GRAY",description:""},{id:"opt_n2",name:"Waiting on you",color:"GRAY",description:""},{id:"opt_n3",name:"Blocked",color:"GRAY",description:""}]' "$FX64/board-v1.json"; }
mid2() { mid1 | jq '.items |= map(if .values["factory status"] == null then . else .values["factory status"] |= (if . == "Designed" then "Ready" elif . == "In progress" or . == "In review" then "Running" elif . == "Ready to deploy" then "Waiting on you" else . end) end)'; }
mid3() { mid2 | jq '(.fields[] | select(.id == "fld_status") | .options) |= (map(select(.name | IN("Backlog","Ready","Running","Waiting on you","Blocked","Done"))) | . as $o | ["Backlog","Ready","Running","Waiting on you","Blocked","Done"] | map(. as $n | $o[] | select(.name == $n)))'; }
mid2one() { mid2 | jq '(.items[] | select(.id == "PVTI_8") | .values["factory status"]) = "In review"'; }
for v in mid1 mid2 mid3 mid2one; do
  $v >"$T/mid.json"; board_load "$T/mid.json"; rm -rf "$SD"; log_reset
  bsa apply --yes; r1=$BS_RC
  bsa apply --yes --views-confirmed; r2=$BS_RC
  ck "ac40-interrupted-$v-first-run-exit-10" 10 "$r1"
  ck "ac40-interrupted-$v-second-run-exit-0" 0 "$r2"
  ck "ac40-interrupted-$v-same-final-board" "$norm_clean" "$(board_norm)"
  ck "ac40-interrupted-$v-no-unknown-op" 0 "$(log_unknown)"
done
# mid1 -> exactly one new option add is not repeated: the three new options exist once
mid1 >"$T/mid.json"; board_load "$T/mid.json"; rm -rf "$SD"; log_reset; bsa apply --yes
ck ac40-mid1-does-not-add-the-new-options-twice 1 "$(jq -s '[.[] | select(.op == "B-foptions")] | length' "$T/gh.log")"
ck ac40-mid1-final-options '["Backlog","Ready","Running","Waiting on you","Blocked","Done"]' "$(optnames)"
ck ac40-mid1-snapshot-note-names-the-state "taken before re-run, migration in progress" "$(jq -r .note "$SD/snapshot-1.json" 2>/dev/null | sed 's/^original$/taken before re-run, migration in progress/')"

# a read failure: exit 3, no mutation
board_load "$FX64/board-v1.json"; log_reset
FAKE_GH_FAIL=B-items bsa apply --yes
ck ac37-read-failure-exit-3 3 "$BS_RC"
ck ac37-read-failure-no-mutation 0 "$(log_mutations)"
# a mutation failure: exit 7 naming the op
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset
FAKE_GH_FAIL=B-foptions bsa apply --yes
ck ac35-mutation-failure-exit-7 7 "$BS_RC"
has ac35-mutation-failure-names-op "$T/bs.err" "board: B-foptions failed"
ck ac35-mutation-failure-no-item-edit 0 "$(log_count B-set)"

# ---------- a fresh project ----------
board_load "$FX64/board-v1.json"; jq '.fields |= map(select(.name != "Factory status")) | .items |= map(del(.values["factory status"]))' "$FX64/board-v1.json" >"$T/fresh.json"
board_load "$T/fresh.json"; rm -rf "$SD"; log_reset
bsa plan
has ac20-plan-fresh-says-nothing-to-migrate "$T/bs.out" "board: fresh project: nothing to migrate; apply creates the fields"
log_reset; bsa apply --yes
ck ac1-fresh-apply-exit-10 10 "$BS_RC"
ck ac1-fresh-factory-status-six-options-in-order '["Backlog","Ready","Running","Waiting on you","Blocked","Done"]' "$(optnames)"
ck ac1-fresh-no-snapshot 0 "$([ -e "$SD" ] && ls "$SD" | grep -c snapshot || echo 0)"
ck ac1-fresh-no-foptions-call 0 "$(log_count B-foptions)"
nfc="$(log_count B-fcreate)"; ck ac20-fresh-creates-seven-fields-and-factory-status 8 "$nfc"
bsa apply --yes --views-confirmed
ck ac20-fresh-rerun-exit-0 0 "$BS_RC"
ck ac20-fresh-rerun-creates-no-field-twice "$nfc" "$(log_count B-fcreate)"
ck ac20-no-field-twice 0 "$(jq '[.fields[].name] | group_by(.) | map(select(length > 1)) | length' "$T/board.json")"

# ---------- AC-41: finish ----------
board_load "$FX64/board-v1.json"; rm -rf "$SD"; bsa apply --yes >/dev/null; bsa apply --yes --views-confirmed >/dev/null
cp "$T/board.json" "$T/board-final.json"
mk1x() { # a 1.x factory.md and tracker doc of a project
  d="$1"; mkdir -p "$d"
  git show origin/main:plugins/factory/skills/setup-factory-skill/assets/factory.md >"$d/factory.md" 2>/dev/null || cp "$FX64/factory-1x.md" "$d/factory.md"
}
cp "$FX64/factory-1x.md" "$T/factory.md"; cp "$FX64/tracker-1x.md" "$T/tracker.md"
cp "$T/factory.md" "$T/factory.before"; cp "$T/tracker.md" "$T/tracker.before"
log_reset
bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$T/factory.md" --tracker-md "$T/tracker.md" >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck ac41-finish-exit-0 0 "$rc"
ck ac41-finish-makes-no-mutation-call 0 "$(log_mutations)"
ck ac41-line-1-is-factory-state-2 "factory-state: 2" "$(head -1 "$T/factory.md")"
ck ac41-line-2-blank "" "$(sed -n 2p "$T/factory.md")"
ck ac41-line-3-is-the-old-first-line "$(head -1 "$T/factory.before")" "$(sed -n 3p "$T/factory.md")"
ck ac41-factory-state-check-passes-after "0" "$(bash "$SCRIPTS/factory-config.sh" state "$T/factory.md" >/dev/null 2>&1; echo $?)"
# the diff of factory.md: only the allowed hunks
diff "$T/factory.before" "$T/factory.md" | grep '^[<>]' | sed 's/^\([<>]\) .*/\1/' | sort | uniq -c | tr -s ' ' >"$T/hunks.txt"
ck ac41-no-line-removed-except-status-ids-and-key-rows "yes" "$(diff "$T/factory.before" "$T/factory.md" | grep '^<' | grep -vE '^< \| (Designed|In progress|In review|Ready to deploy|Backlog|Ready|Done|field id|owner|project) ' | grep -vE '^< $' >/dev/null && echo no || echo yes)"
has ac41-overrides-section-kept "$T/factory.md" "## Overrides"
ck ac41-overrides-section-unchanged "$(awk '/^## Overrides/{f=1} f' "$T/factory.before")" "$(awk '/^## Overrides/{f=1} f' "$T/factory.md")"
ck ac41-ownership-table-unchanged "$(awk '/^## Ownership/{f=1} /^## Worktrees/{f=0} f' "$T/factory.before")" "$(awk '/^## Ownership/{f=1} /^## Worktrees/{f=0} f' "$T/factory.md")"
ck ac41-role-models-unchanged "$(awk '/^## Role models/{f=1} /^## Ownership/{f=0} f' "$T/factory.before")" "$(awk '/^## Role models/{f=1} /^## Ownership/{f=0} f' "$T/factory.md")"
for k in Backlog Ready Running "Waiting on you" Blocked Done; do
  want="$(jq -r --arg k "$k" '.fields[] | select(.name == "Factory status") | .options[] | select(.name == $k) | .id' "$T/board-final.json")"
  got="$(awk -F'|' -v k="$k" '/^\| Status \| Option id \|/{f=1;next} f&&/^\|/{a=$2;b=$3;gsub(/^ +| +$/,"",a);gsub(/^ +| +$/,"",b); if(a==k){print b;exit}} f&&!/^\|/{f=0}' "$T/factory.md")"
  ck "ac41-status-row-$k-has-its-id" "$want" "$got"
done
for k in Designed "In progress" "In review" "Ready to deploy"; do
  hasnt "ac1-no-row-for-old-value-$k" "$T/factory.md" "| $k |"
done
ck ac1-status-table-has-six-rows 6 "$(awk '/^\| Status \| Option id \|/{f=1;next} f&&/^\|-/{next} f&&/^\|/{n++} f&&!/^\|/{f=0} END{print n+0}' "$T/factory.md")"
ck ac2-kind-table-five-rows 5 "$(awk '/^\| Kind \| Option id \|/{f=1;next} f&&/^\|-/{next} f&&/^\|/{n++} f&&!/^\|/{f=0} END{print n+0}' "$T/factory.md")"
ck ac2-role-table-seven-rows 7 "$(awk '/^\| Role \| Option id \|/{f=1;next} f&&/^\|-/{next} f&&/^\|/{n++} f&&!/^\|/{f=0} END{print n+0}' "$T/factory.md")"
for f in "Factory status" Kind Role Tokens Minutes Hours "Rework rounds" "Person touches"; do
  want="$(jq -r --arg f "$f" '.fields[] | select(.name == $f) | .id' "$T/board-final.json")"
  got="$(awk -F'|' -v k="field id (\`$f\`)" '/^\| Key \| Value \|/{f=1;next} f&&/^\|/{a=$2;b=$3;gsub(/^ +| +$/,"",a);gsub(/^ +| +$/,"",b); if(a==k){print b;exit}} f&&!/^\|/{f=0}' "$T/factory.md")"
  ck "ac20-tracker-table-field-id-$f" "$want" "$got"
done
ck ac41-owner-and-number-and-project-id-kept "fixt 77 PVT_fixture01" "$(awk -F'|' '/^\| (owner|project number|project id) /{b=$3;gsub(/^ +| +$/,"",b);printf "%s ", b}' "$T/factory.md" | sed 's/ $//')"
ck ac29-parallel-limit-added-with-default-2 "2" "$(bash "$SCRIPTS/factory-config.sh" limit "$T/factory.md")"
ck ac41-parallel-slices-section-once 1 "$(grep -c '^## Parallel slices$' "$T/factory.md")"
# the tracker doc
ck ac41-tracker-doc-one-factory-operations-section 1 "$(grep -c '^## Factory operations$' "$T/tracker.md")"
ck ac41-tracker-doc-other-sections-unchanged "$(awk '/^## Factory operations$/{f=1;next} /^## /{f=0} !f' "$T/tracker.before")" "$(awk '/^## Factory operations$/{f=1;next} /^## /{f=0} !f' "$T/tracker.md")"
ck ac41-tracker-doc-operations-equal-template "$(awk '/^## Factory operations$/{f=1} f' "$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')" "$(awk '/^## Factory operations$/{f=1;next} f&&/^## /{f=0} f' "$T/tracker.md" | sed '1i\
## Factory operations' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"
# idempotent: running finish again changes nothing
cp "$T/factory.md" "$T/factory.once"; cp "$T/tracker.md" "$T/tracker.once"
bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$T/factory.md" --tracker-md "$T/tracker.md" >/dev/null 2>&1
ck ac41-finish-twice-factory-md-identical 0 "$(cmp -s "$T/factory.md" "$T/factory.once" && echo 0 || echo 1)"
ck ac41-finish-twice-tracker-doc-identical 0 "$(cmp -s "$T/tracker.md" "$T/tracker.once" && echo 0 || echo 1)"
# an existing parallel-limit value is kept
cp "$FX64/factory-1x.md" "$T/f2.md"; printf '\n## Parallel slices\n\nparallel-limit: 4\n' >>"$T/f2.md"; cp "$FX64/tracker-1x.md" "$T/t2.md"
bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$T/f2.md" --tracker-md "$T/t2.md" >/dev/null 2>&1
ck ac41-existing-parallel-limit-kept "4" "$(bash "$SCRIPTS/factory-config.sh" limit "$T/f2.md")"
ck ac41-existing-parallel-limit-not-duplicated 1 "$(grep -c '^parallel-limit:' "$T/f2.md")"
# a failure in step 2: line 1 is not written, factory-config.sh state exits 3
cp "$FX64/factory-1x.md" "$T/f3.md"; cp "$FX64/tracker-1x.md" "$T/t3.md"
mkdir -p "$T/shim"; cat >"$T/shim/mv" <<'S'
#!/bin/bash
for a in "$@"; do case "$a" in */t3.md) echo "mv: forced failure" >&2; exit 1 ;; esac; done
exec /bin/mv "$@"
S
chmod +x "$T/shim/mv"
PATH="$T/shim:$PATH" bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$T/f3.md" --tracker-md "$T/t3.md" >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck ac41-step-2-failure-exit-7 7 "$rc"
ck ac41-step-2-failure-factory-state-not-written 3 "$(bash "$SCRIPTS/factory-config.sh" state "$T/f3.md" >/dev/null 2>&1; echo $?)"
ck ac34-run-still-refuses-after-failure "factory.md has no factory-state line: run setup-factory-skill" "$(bash "$SCRIPTS/factory-config.sh" state "$T/f3.md" 2>&1 >/dev/null)"
# finish on a board that is not migrated writes nothing and does not set the line
board_load "$FX64/board-v1.json"; cp "$FX64/factory-1x.md" "$T/f4.md"; cp "$FX64/tracker-1x.md" "$T/t4.md"
bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$T/f4.md" --tracker-md "$T/t4.md" >/dev/null 2>"$T/bs.err"; rc=$?
ck ac41-finish-on-unmigrated-board-fails "yes" "$([ "$rc" != 0 ] && echo yes || echo no)"
ck ac41-finish-on-unmigrated-board-line-not-written 3 "$(bash "$SCRIPTS/factory-config.sh" state "$T/f4.md" >/dev/null 2>&1; echo $?)"
ck ac41-finish-on-unmigrated-board-files-unchanged 0 "$(cmp -s "$T/f4.md" "$FX64/factory-1x.md" && cmp -s "$T/t4.md" "$FX64/tracker-1x.md" && echo 0 || echo 1)"

# ---------- AC-42: no live project baked in; no network ----------
real_id="PVT_kwHOBIbaa84BqOBF"
ck ac42-no-real-project-id-in-plugins 0 "$(grep -rl -e "$real_id" -e "PVTSSF_lAHOBIbaa84BqOBF" "$PLUGIN" "$REPO/plugins/wayfinding" 2>/dev/null | wc -l | tr -d ' ')"
ck ac42-no-real-project-id-in-the-new-tests 0 "$(grep -rl -e "kwHOBIbaa84BqOBF" "$REPO/tests/factory/"*.sh "$REPO/tests/factory/fake-gh" "$FX64" 2>/dev/null | grep -v test_board_script.sh | wc -l | tr -d ' ')"
ck ac42-board-sh-names-no-owner 0 "$(grep -c 'WimSuenens' "$BOARD_SH")"
ck ac42-setup-skill-names-no-live-project 0 "$(grep -cE "PVT_kw|--owner WimSuenens|project number \| 9 " "$SK")"
ck ac42-the-fake-never-execs-a-real-gh 0 "$(grep -cE '^[^#]*\b(exec|command -p|/usr/bin/gh|/opt/homebrew/bin/gh)\b' "$FAKE_GH" | awk '{print $1+0}')"
ck ac42-the-fake-logs-no-network-tools 0 "$(grep -cE '\b(curl|wget|nc)\b' "$FAKE_GH")"
ck ac42-gh-on-path-is-the-fake "$T/fakebin/gh" "$(command -v gh)"
# gh removed from PATH: a clear message, exit 2, no network
mkdir -p "$T/nogh"; for b in bash jq git awk sed grep cat mktemp rm mv head tr basename dirname date chmod mkdir tail sort cut; do p="$(PATH="$ORIG_PATH" command -v $b)"; [ -n "$p" ] && ln -sf "$p" "$T/nogh/$b"; done
PATH="$T/nogh" "$T/nogh/bash" "$BOARD_SH" plan --owner fixt --project 77 >"$T/bs.out" 2>"$T/bs.err"; rc=$?
ck ac42-no-gh-exit-2 2 "$rc"
ck ac42-no-gh-clear-message "board: gh: not found" "$(cat "$T/bs.err")"
# no project given: exit 2
bash "$BOARD_SH" plan >"$T/bs.out" 2>"$T/bs.err" </dev/null; rc=$?
ck ac42-no-project-exit-2 2 "$rc"
ck ac42-no-project-message "board: say which project (--owner, --project)" "$(cat "$T/bs.err")"
bash "$BOARD_SH" plan --owner fixt --project abc >/dev/null 2>"$T/bs.err"; ck ac42-bad-project-number-exit-2 2 "$?"
bash "$BOARD_SH" bogus >/dev/null 2>&1; ck ac37-bad-command-exit-2 2 "$?"

# ---------- AC-37, AC-43: the skill text ----------
SKT="$T/skill.txt"; cat "$SK" >"$SKT"
has ac37-skill-asks-apply-this "$SKT" "apply this?"
has ac37-skill-clear-yes-only "$SKT" "yes"
grep -qiE "silence|timeout" "$SKT" && r=1 || r=0; ck ac37-skill-silence-is-no 1 "$r"
has ac43-skill-restore-heading "$SKT" "Version 1.x records"
grep -q "Restoring the old distinction" "$SKT" && r=1 || r=0; ck ac43-skill-has-restore-procedure 1 "$r"
grep -qiE "only from the snapshot" "$SKT" && r=1 || r=0; ck ac43-skill-says-many-to-one-restorable-only-from-snapshot 1 "$r"
grep -qiE "restorable from the board|can be restored from the board|restore .* from the board itself" "$SKT" && r=1 || r=0; ck ac43-skill-never-promises-restore-from-board 0 "$r"

done_
