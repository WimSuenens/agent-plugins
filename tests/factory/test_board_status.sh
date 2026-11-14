#!/bin/bash
# Slice 64, the board as status: AC-1, AC-2, AC-3, AC-4, AC-7, AC-8 against the run text, the template and the operations list.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
RUN="$(run_all_file)"
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"
OPS="$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md"
SK="$PLUGIN/skills/setup-factory-skill/SKILL.md"
TD="$(cd "$(dirname "$0")" && pwd)"
cd "$T" || exit 1

tbl_rows() { # tbl_rows <file> <header-line-prefix>: the first cells of the rows of the table whose header starts so
  awk -v h="$2" 'index($0, h) == 1 {f=1; next} f && /^\|-/ {next} f && /^\|/ { s=$0; sub(/^\| */, "", s); sub(/ *\|.*$/, "", s); print s; next } f {exit}' "$1"
}
# ---------- AC-1: six values, in order; no row for an old value ----------
ck ac1-template-status-rows-in-order "Backlog
Ready
Running
Waiting on you
Blocked
Done" "$(tbl_rows "$TPL" '| Status | Option id |')"
ck ac2-template-kind-rows "map
slice
role task
frontier ticket
idea" "$(tbl_rows "$TPL" '| Kind | Option id |')"
ck ac2-template-role-rows "product-owner
architect
developer
qa-engineer
security-reviewer
devops
docs-writer" "$(tbl_rows "$TPL" '| Role | Option id |')"
ck ac2-template-role-table-has-seven-explicit-rows 7 "$(tbl_rows "$TPL" '| Role | Option id |' | grep -c .)"
for f in Kind Role Tokens Minutes Hours "Rework rounds" "Person touches"; do has "ac2-template-tracker-table-field-id-$f" "$TPL" "| field id (\`$f\`) |"; done
has ac1-template-field-id-factory-status "$TPL" '| field id (`Factory status`) |'
for k in owner "project number" "project id"; do has "ac1-template-key-$k" "$TPL" "| $k |"; done
ck ac1-template-id-cells-empty "0" "$(awk '/^\| (Backlog|Ready|Running|Waiting on you|Blocked|Done|map|slice|role task|frontier ticket|idea|product-owner) \| [^ |]/{n++} END{print n+0}' "$TPL")"
ck ac1-run-board-table-options "\`Backlog\`, \`Ready\`, \`Running\`, \`Waiting on you\`, \`Blocked\`, \`Done\`" "$(grep -m1 '^| `Factory status` | single select |' "$RUN" | sed 's/^| `Factory status` | single select | //;s/ |$//')"
ck ac2-run-board-table-kind "\`map\`, \`slice\`, \`role task\`, \`frontier ticket\`, \`idea\`" "$(grep -m1 '^| `Kind` | single select |' "$RUN" | sed 's/^| `Kind` | single select | //;s/ |$//')"
has ac2-role-only-on-role-task "$RUN" 'set only on a `role task` card'
has ac2-kind-mapping-wayfinder-slice "$RUN" 'a child of the map labelled `wayfinder:slice` is `slice`; a child of any other `wayfinder:*` type is `frontier ticket`'
has ac1-board-built-in-status-unused "$RUN" 'The project'"'"'s built-in `Status` field is not used.'
has ac1-run-missing-cell-stops "$RUN" 'a missing cell stops the run and names the cell'
# the repository's own docs/agents copy migrates after the run closes (the build does not edit it): reported, not asserted
if grep -q 'Designed' "$REPO/docs/agents/factory.md" 2>/dev/null; then skip ac1-repo-own-docs-agents-factory-md "this repository's docs/agents/factory.md still holds the 1.x table by design (contracts/64-release.md section 2: it migrates through the step after the run closes)"; fi

# ---------- AC-7: no old value outside the migration ----------
hits="$(grep -rnE 'Designed|In progress|In review|Ready to deploy' "$REPO/plugins" 2>/dev/null | grep -v '^'"$REPO"'/plugins/factory/scripts/board.sh' | grep -v '^'"$REPO"'/plugins/factory/skills/setup-factory-skill/SKILL.md' | grep -v '^'"$REPO"'/plugins/toolkit' )"
ck ac7-no-old-value-outside-board-sh-and-setup-skill 0 "$(printf '%s' "$hits" | grep -c .)"
[ -n "$hits" ] && printf '%s\n' "$hits" | cut -c1-200 | sed 's/^/     hit: /'
ck ac7-template-has-no-old-value 0 "$(grep -cE 'Designed|In progress|In review|Ready to deploy' "$TPL")"
ck ac7-ops-list-has-no-old-value 0 "$(grep -cE 'Designed|In progress|In review|Ready to deploy' "$OPS")"
# within the migration step the old values are in the table and the snapshot text only
ck ac7-setup-skill-old-values-only-in-step-7 "7. Prepare the Project board" "$(awk '/^#+ /{sec=$0; sub(/^#+ /,"",sec)} /Designed|In progress|In review|Ready to deploy/{print sec}' "$SK" | sort -u)"

# ---------- AC-4: every transition tied to an observable event; the narrated run ----------
BT="$(awk '/^## The board$/{f=1;next} /^### Needs you$/{f=0} f' "$RUN" | awk '/^\| Card \| Event \| Status \|/{t=1;next} t&&/^\|---/{next} t&&/^\|/{print;next} t{exit}')"
ck ac4-board-table-has-rows "yes" "$([ "$(printf '%s\n' "$BT" | grep -c .)" -ge 17 ] && echo yes || echo no)"
ck ac4-no-row-needs-work-folder-or-branch 0 "$(printf '%s\n' "$BT" | grep -cE 'work/|item/|frontier/|branch')"
has ac4-precedence-rule "$RUN" 'the precedence is `Waiting on you`, then `Blocked`, then `Running`'
has ac4-observable-without-work-or-branch "$RUN" 'Every status below is tied to an event you can observe without `work/` or a branch.'
has ac4-stage-is-the-running-role-task "$RUN" 'The **stage** of a slice is the role task that is `Running`; no field holds it.'
has ac4-running-event-first-spawn "$RUN" '| slice | the first role task of the item is spawned | `Running` |'
has ac4-done-event-merge "$RUN" '| slice | its PR is merged | `Done` |'
has ac4-blocked-role-task "$RUN" '| role task | its result is `blocked`, comment posted and issue closed | `Blocked` |'
has ac4-andon-stops-agent-blocked "$RUN" '| role task | you stop its agent for an andon | `Blocked`; `Running` when the agent is resumed |'
has ac4-slice-blocked-on-andon "$RUN" '| slice | you stop work on the slice for an andon |'
has ac4-working-stays-running "$RUN" '| role task | its result is `working` (cut off) | stays `Running`, issue open |'
has ac4-ready-waits-on-overlap "$RUN" '| slice | the start gate fails (budget reached, or a path overlap) | stays `Ready`; you say why |'
has ac4-map-done-on-close "$RUN" '| map | the run is reported closed (step 9) | `Backlog`; `Running` when the next run starts |'
has ac4-map-running-on-adopt "$RUN" '| map | you create or adopt it (step 2) | `Running` |'
has ac4-frontier-ticket-row "$RUN" '| frontier ticket | it waits on the frontier | `Backlog`'
while IFS="$(printf '\t')" read -r step card ev st; do
  case "$step" in \#*|'') continue ;; esac
  row="$(printf '%s\n' "$BT" | grep -F "| $card | " | grep -F "$ev" | head -1)"
  got="$(printf '%s' "$row" | awk -F'|' '{s=$4; gsub(/^ +| +$/,"",s); gsub(/`/,"",s); sub(/;.*$/,"",s); sub(/,.*$/,"",s); sub(/ \(.*$/,"",s); print s}')"
  [ -z "$row" ] && got="(no row)"
  ck "ac4-narrated-step-$step-$card-[$ev]" "$st" "$got"
done <"$TD/fixtures/board/board-run.tsv"
# step 5 and 12: the person's wait is posted with a comment first
has ac4-waiting-needs-the-comment-first "$RUN" '`Waiting on you`, with the needs-you comment first'
# the slice row covers every cause of the requirement's list
for c in "a decision card" "the merge approval" "a task request" "the delivery approval" "a resurvey pause" "a missing project permission"; do has "ac4-waiting-cause-$c" "$RUN" "$c"; done
# lead state has no status line, and the board is the only place a status lives
has ac4-board-only-place-for-status "$RUN" 'The board is the only place a status lives'
has ac4-lead-state-no-status-line "$RUN" '**The lead state carries no status line**'

# ---------- AC-3: the cards are on the board with their fields ----------
has ac3-run-start-adds-map-and-children "$RUN" 'Add the map and every child ticket of the map to the board (*Add to board*, then *Set status* for `Factory status` and `Kind`)'
has ac3-resume-adds-missing-cards "$RUN" 'On a resumed run read the board (*List board*) and add any card that is missing; *Add to board* never makes one twice.'
has ac3-step-2-adds-map "$RUN" 'Add the map and every child ticket of the map to the board now'
has ac3-step-4-adds-slice "$RUN" 'Add the new ticket to the board now: `Kind` slice, `Factory status` `Ready`.'
has ac3-role-task-three-sets "$RUN" '*Add to board*, then *Set status* three times'
has ac3-frontier-role-task-parent "$RUN" 'Each role task is a sub-issue of the **frontier ticket** (never the map'
has ac3-ops-add-twice-returns-existing "$OPS" 'Adding twice returns the existing item.'
has ac3-ops-one-field-per-call "$OPS" 'One field per call'
# the calls of a card are in the closed list (checked for every command in test_role_tasks.sh); here the run text names only operations of the list
for op in "Add to board" "Set status" "Set field text" "List board" "List role tasks" "Find unlinked role task" "Create role task" "Link role task" "Find result comments" "Post result" "Close role task" "Find ledger" "Post ledger" "Edit ledger"; do
  case "$op" in "Set field text") bullet="Set field text" ;; *) bullet="$op" ;; esac
  has "ac3-ops-list-has-bullet-$op" "$OPS" "- **$bullet**"
done
# every italic operation name the run text uses exists as a bullet in the list
miss=0; for n in $(grep -o '\*[A-Z][A-Za-z ]*\*' "$RUN" | tr -d '*' | sort -u | tr ' ' '_'); do :; done
grep -o '\*\(Add to board\|Set status\|Set field text\|List board\|List role tasks\|Find unlinked role task\|Create role task\|Link role task\|Find result comments\|Post result\|Close role task\|Find ledger\|Post ledger\|Edit ledger\|Needs you\|Answered\|Decision card\|Task request\|Stage summary\|Run state\|Open PR\|Merge PR\|Find baseline\|Post hansei\|Edit hansei\)\*' "$RUN" | tr -d '*' | sort -u >"$T/used-ops.txt"
for n in $(sed 's/ /_/g' "$T/used-ops.txt"); do nn="$(printf '%s' "$n" | tr '_' ' ')"; grep -q -- "- \*\*$nn\*\*" "$OPS" || { echo "FAIL ac3-run-uses-operation-not-in-list: $nn"; fail=1; miss=1; }; done
ck ac3-every-operation-the-run-text-names-is-in-the-list 0 "$miss"

# ---------- AC-8: the map's Factory run section keeps no status ----------
FR="$(awk '/^```$/{c++} /^## Factory run$/ && c%2==1 {f=1} f&&!/^```$/{print} f&&/^```$/{exit}' "$RUN")"
ck ac8-factory-run-template-found "yes" "$([ "$(printf '%s\n' "$FR" | grep -c .)" -ge 6 ] && echo yes || echo no)"
for w in Backlog Ready Running "Waiting on you" Blocked Done; do ck "ac8-factory-run-template-has-no-status-word-$w" 0 "$(printf '%s\n' "$FR" | grep -cw -- "$w")"; done
has ac8-factory-run-lists-items-in-flight "$RUN" '- in flight: #<id> (item/<id>), … | none'
has ac8-factory-run-holds-no-status-sentence "$RUN" '**It holds no status word**: the board is the only place a status lives.'
has ac8-factory-run-keeps-freeze-line "$RUN" '- FREEZE: <sha> (<semver>)'
has ac8-factory-run-step-line "$RUN" '- step: <step>'
has ac8-map-and-children-on-board-at-step-2 "$RUN" '**Done when** the map exists with the destination as its Destination, the Factory run section is written, and the map and its children are on the board.'

done_
