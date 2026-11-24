#!/bin/bash
# Bundle A item 3 (#253): ledger.sh edits a local copy of the ledger comment body, by table heading and column header, never by separator line.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
LG="$PLUGIN/scripts/ledger.sh"
cd "$T" || exit 1
cat >body.md <<'L'
<!-- factory:ledger v1 -->
## Ledger: #12 Export a report as CSV

- started: 2026-11-04T11:40Z
- start checks: author test: ok

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #31 | Requirement | product-owner | a1c9e2 | - | 48210 | done | 6 criteria |
| 2 | #32 | Contracts and ADRs | architect | b7d031 | W1 | 61450 | done | 3 ADRs |

### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:10Z | 2026-11-04T12:41Z | yes | decision card |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B |
L
rows() { grep -c "^| " "$1"; }

# the old way, reproduced: the first separator line is taken as the table to append to. A Waits row lands in Tasks.
naive_add() { awk -v row="$2" '!d && /^\|---/ { print; getline; while ($0 ~ /^\|/) { print; getline } print row; d=1 } { print }' "$1"; }
naive_add body.md '| W2 | limits | - | 2026-11-04T13:00Z | 2026-11-04T13:10Z | yes | hit a limit |' >naive.md
tasks_after="$(awk '/^### Tasks/{t=1;next} /^### /{t=0} t&&/^\| W2/{print "wrong-table"}' naive.md)"
ck naive-approach-hits-the-wrong-table "wrong-table" "$tasks_after"

# the script: add-wait goes to Waits
bash "$LG" add-wait body.md out1.md --kind limits --agent - --start 2026-11-04T13:00Z --end 2026-11-04T13:10Z --held yes --what "hit a limit" >/dev/null; ck add-wait-rc 0 "$?"
ck add-wait-in-waits "W2" "$(awk '/^### Waits/{t=1;next} /^### /{t=0} t&&/^\| W2/{print "W2"}' out1.md)"
ck add-wait-tasks-unchanged "$(awk '/^### Tasks/{t=1;next} /^### /{t=0} t' body.md)" "$(awk '/^### Tasks/{t=1;next} /^### /{t=0} t' out1.md)"
ck add-wait-touches-unchanged "$(awk "/^### Person/{t=1} t" body.md)" "$(awk "/^### Person/{t=1} t" out1.md)"
# add-task: numbered 3, in Tasks
bash "$LG" add-task out1.md out2.md --task '#33' --stage Build --role developer --agents c0ffee --waits - --peak 90000 --result done --notes "2 rounds" >/dev/null; ck add-task-rc 0 "$?"
ck add-task-row "| 3 | #33 | Build | developer | c0ffee | - | 90000 | done | 2 rounds |" "$(grep '^| 3 |' out2.md)"
ck add-task-count "3" "$(awk '/^### Tasks/{t=1;next} /^### /{t=0} t&&/^\| [0-9]/' out2.md | wc -l | tr -d ' ')"
# add-touch
bash "$LG" add-touch out2.md out3.md --time 2026-11-04T14:00Z --kind demo --what "ran the demo" >/dev/null; ck add-touch-rc 0 "$?"
ck add-touch-row "| 2026-11-04T14:00Z | demo | ran the demo |" "$(grep '^| 2026-11-04T14:00Z' out3.md)"
# set-wait-end
bash "$LG" set-wait-end out3.md out4.md --id W1 --end 2026-11-04T12:50Z >/dev/null; ck set-wait-end-rc 0 "$?"
ck set-wait-end-row "| W1 | person | - | 2026-11-04T12:10Z | 2026-11-04T12:50Z | yes | decision card |" "$(grep '^| W1 ' out4.md)"
bash "$LG" set-wait-end out4.md out5.md --id W9 --end 2026-11-04T12:50Z >/dev/null 2>&1; ck set-wait-end-unknown-id 1 "$?"

# a backup of the previous body is kept before writing; in-place works too
cp body.md inplace.md
bash "$LG" add-task inplace.md inplace.md --task '#40' --stage QA --role qa-engineer --agents aa --waits - --peak 1 --result pass --notes - >/dev/null
ck backup-exists "yes" "$([ -f inplace.md.bak ] && echo yes || echo no)"
ck backup-is-previous-body "$(cat body.md)" "$(cat inplace.md.bak)"
ck inplace-has-row "yes" "$(grep -q '| #40 |' inplace.md && echo yes || echo no)"

# idempotent re-run: the same event again changes nothing
bash "$LG" add-task out2.md again.md --task '#33' --stage Build --role developer --agents c0ffee --waits - --peak 90000 --result done --notes "2 rounds" >/dev/null; ck rerun-task-rc 0 "$?"
ck rerun-task-same "$(cat out2.md)" "$(cat again.md)"
bash "$LG" add-wait out1.md again2.md --kind limits --agent - --start 2026-11-04T13:00Z --end 2026-11-04T13:10Z --held yes --what "hit a limit" >/dev/null
ck rerun-wait-same "$(cat out1.md)" "$(cat again2.md)"
bash "$LG" add-touch out3.md again3.md --time 2026-11-04T14:00Z --kind demo --what "ran the demo" >/dev/null
ck rerun-touch-same "$(cat out3.md)" "$(cat again3.md)"

# an edit that would shrink another table is refused: check compares before and after by heading
awk '/^### Waits/{print; w=1; next} w&&/^\| W1/{next} {print}' body.md >shrunk.md   # a hand edit that lost the Waits row
out="$(bash "$LG" check body.md shrunk.md 2>&1)"; ck check-shrink-refused 1 "$?"
printf '%s' "$out" | grep -q 'Waits'; ck check-shrink-names-table 0 "$?"
bash "$LG" check body.md out4.md >/dev/null; ck check-growth-ok 0 "$?"
# a body whose tables are found by header, not by order: Waits before Tasks
awk '/^### Tasks/{t=1} /^### Waits/{t=0;w=1} /^### Person/{w=0} t{a=a $0 "\n";next} w{b=b $0 "\n";next} {if(!p&&/^### Person/){printf "%s%s", b, a; p=1} print}' body.md >swapped.md
bash "$LG" add-wait swapped.md sw.md --kind person --agent - --start 2026-11-04T15:00Z --end 2026-11-04T15:05Z --held yes --what q >/dev/null; ck swapped-order-rc 0 "$?"
ck swapped-order-right-table "W2" "$(awk '/^### Waits/{t=1;next} /^### /{t=0} t&&/^\| W2/{print "W2"}' sw.md)"
# a missing table or a wrong column header refuses and writes nothing
printf '### Tasks\n\n| # | Task |\n|---|---|\n' >bad.md; rm -f nope.md
bash "$LG" add-wait bad.md nope.md --kind person --agent - --start a --end b --held yes --what q >/dev/null 2>&1; ck missing-table-refused 3 "$?"
ck missing-table-no-output "no" "$([ -e nope.md ] && echo yes || echo no)"
# a cell with a pipe is refused
bash "$LG" add-touch body.md nope.md --time t --kind demo --what 'a | b' >/dev/null 2>&1; ck pipe-in-cell-refused 2 "$?"
# the text names the script
has hansei-names-script "$PLUGIN/references/hansei.md" 'scripts/ledger.sh'
has hansei-no-hand-edit "$PLUGIN/references/hansei.md" 'never by hand'
done_
