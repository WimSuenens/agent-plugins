#!/bin/bash
# Worktrees live in the project's agent folder (.claude/worktrees). Contract 109, issue #109.
# Two seams: the script (worktree.sh) and the standard text (run skill, protocol, hansei, setup, templates, records).
. "$(dirname "$0")/lib.sh"
T="$(cd "$T" && pwd -P)"
WT="$PLUGIN/scripts/worktree.sh"
SK="$PLUGIN/skills/run/SKILL.md"
HN="$PLUGIN/references/hansei.md"
PR_="$PLUGIN/references/protocol.md"
SU="$PLUGIN/skills/setup-factory-skill/SKILL.md"
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"

mkrepo() { mkdir -p "$1" && git init -q -b main "$1" && ( cd "$1" && echo r > README && git add -A && git commit -qm init ) >/dev/null 2>&1; }

# --- scripts seam
ck dir-prints-folder ".claude/worktrees" "$(bash "$WT" dir)"

R="$T/r1"; mkrepo "$R"
out="$(cd "$R" && bash "$WT" add item 12 2>&1)"; rc=$?
ck add-refused-until-ignored-rc 3 "$rc"
ck add-refused-no-worktree "no" "$([ -e "$R/.claude/worktrees/12" ] && echo yes || echo no)"

ck ignore-first "added" "$(cd "$R" && bash "$WT" ignore)"
ck ignore-writes-rule "/.claude/worktrees/" "$(cat "$R/.gitignore")"
snap="$(cat "$R/.gitignore")"
ck ignore-second "already present" "$(cd "$R" && bash "$WT" ignore)"
ck ignore-second-unchanged "$snap" "$(cat "$R/.gitignore")"
ck ignore-third-rc 0 "$(cd "$R" && bash "$WT" ignore >/dev/null; echo $?)"

# the ignore rule keeps the folder out of status, and an equivalent existing line counts as present
( cd "$R" && git add .gitignore && git commit -qm ignore ) >/dev/null 2>&1
out="$(cd "$R" && bash "$WT" add item 12)"; rc=$?
ck add-item-rc 0 "$rc"
ck add-item-path "$R/.claude/worktrees/12" "$out"
ck add-item-branch "item/12" "$(git -C "$R/.claude/worktrees/12" branch --show-current)"
ck add-item-main-status-clean "" "$(git -C "$R" status --porcelain)"
out="$(cd "$R" && bash "$WT" add frontier 7)"
ck add-frontier-path "$R/.claude/worktrees/frontier-7" "$out"
ck add-frontier-branch "frontier/7" "$(git -C "$out" branch --show-current)"
out="$(cd "$R" && bash "$WT" add settle 7)"
ck add-settle-path "$R/.claude/worktrees/settle-7" "$out"
ck add-settle-branch "settle/7" "$(git -C "$out" branch --show-current)"

# from inside a worktree the new one still lands beside the others, in the main checkout's folder
out="$(cd "$R/.claude/worktrees/12" && bash "$WT" add item 13)"
ck add-from-worktree-path "$R/.claude/worktrees/13" "$out"

# bad input and git refusals
ck add-nonnumeric-rc 2 "$(cd "$R" && bash "$WT" add item '../x' >/dev/null 2>&1; echo $?)"
ck add-empty-rc 2 "$(cd "$R" && bash "$WT" add item '' >/dev/null 2>&1; echo $?)"
ck add-unknown-kind-rc 2 "$(cd "$R" && bash "$WT" add prototype 1 >/dev/null 2>&1; echo $?)"
ck add-duplicate-rc 4 "$(cd "$R" && bash "$WT" add item 12 >/dev/null 2>&1; echo $?)"
ck unknown-command-rc 2 "$(cd "$R" && bash "$WT" bogus >/dev/null 2>&1; echo $?)"
ck not-a-repo-rc 2 "$(cd "$T" && bash "$WT" dir >/dev/null 2>&1; echo $?)"

# ignore: a .gitignore with no final newline, and an existing equivalent line
R2="$T/r2"; mkrepo "$R2"; printf 'node_modules' > "$R2/.gitignore"
( cd "$R2" && bash "$WT" ignore ) >/dev/null
ck ignore-no-final-newline "node_modules|/.claude/worktrees/" "$(paste -sd'|' "$R2/.gitignore")"
R3="$T/r3"; mkrepo "$R3"; printf '.claude/worktrees\n' > "$R3/.gitignore"
ck ignore-equivalent-line "already present" "$(cd "$R3" && bash "$WT" ignore)"

# legacy: a worktree at ../wt/<id> is found; the new location is not
L="$T/leg/main"; mkdir -p "$T/leg"; mkrepo "$L"
( cd "$L" && bash "$WT" ignore >/dev/null && git add -A && git commit -qm ign && git worktree add -q "$T/leg/wt/5" -b item/5 && bash "$WT" add item 6 >/dev/null ) >/dev/null 2>&1
out="$(cd "$L" && bash "$WT" legacy)"; rc=$?
ck legacy-rc 10 "$rc"
ck legacy-lists-old-only "$T/leg/wt/5	item/5" "$out"
ck legacy-none-rc 0 "$(cd "$R" && bash "$WT" legacy >/dev/null; echo $?)"
ck legacy-none-silent "" "$(cd "$R" && bash "$WT" legacy)"

# --- standard-text seam: the new location, and no old one left in the standard
for f in "$HN" "$PR_" "$TPL" "$REPO/docs/agents/factory.md"; do
  hasnt "no-old-location-$(basename "$f")" "$f" '../wt/'
done
# the run skill and setup name the old location only to find and migrate it, never to create a worktree there
hasnt skill-no-git-add-at-old-location "$SK" 'git worktree add ../wt'
hasnt setup-no-git-add-at-old-location "$SU" 'git worktree add ../wt'
has skill-item-worktree "$SK" 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" add item <id>'
has skill-frontier-worktree "$SK" 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" add frontier <map>'
has skill-settle-worktree "$SK" 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" add settle <map>'
has skill-legacy-finish "$SK" 'worktree.sh" legacy'
has protocol-path-rule "$PR_" 'relative to the main checkout for another worktree (`.claude/worktrees/<id>`)'
has template-item-location "$TPL" 'Item worktrees live at `.claude/worktrees/<id>`, on branch `item/<id>`.'
has template-frontier-location "$TPL" 'Frontier-round worktrees live at `.claude/worktrees/frontier-<map>`, on branch `frontier/<map>`.'
has repo-item-location "$REPO/docs/agents/factory.md" 'Item worktrees live at `.claude/worktrees/<id>`, on branch `item/<id>`.'
has repo-frontier-location "$REPO/docs/agents/factory.md" 'Frontier-round worktrees live at `.claude/worktrees/frontier-<map>`, on branch `frontier/<map>`.'
has template-excludes "$TPL" 'test, lint and search'
has setup-ignore-step "$SU" 'worktree.sh" ignore'
has setup-legacy-step "$SU" 'worktree.sh" legacy'
has setup-move-or-finish "$SU" 'move or finish'
has setup-excludes "$SU" '.claude/worktrees'
has hansei-guard-main-checkout "$HN" 'close: worktree is the main checkout'
has adr-revised "$REPO/docs/adr/0002-one-branch-and-worktree-per-item.md" '.claude/worktrees'
has glossary-worktree "$REPO/CONTEXT.md" '**Worktree folder**'
has contract-exists "$REPO/contracts/109-worktree-folder.md" 'Issue [#109]'

# the clean-up guard, run as the skill writes it, at the new location
close_guard() { awk '/^ +0\. Guard:$/ {f=1; next} f==1 && /^ *```/ {f=2; next} f==2 && /^ *```/ {exit} f==2 {sub(/^ +/, ""); print}' "$HN" | sed "s/<id>/$1/g"; }
G="$(close_guard 12)"
ck guard-text-found "yes" "$([ -n "$G" ] && echo yes || echo no)"
gout="$(cd "$R" && bash -c "$G" 2>&1)"; ck guard-ok-at-new-location-rc 0 "$?"
# no worktree for the item: refuses
ck guard-no-worktree-rc 1 "$(cd "$R" && bash -c "$(close_guard 99)" >/dev/null 2>&1; echo $?)"
# the item branch is checked out in the main checkout itself: refuses
R4="$T/r4"; mkrepo "$R4"; ( cd "$R4" && git checkout -q -b item/12 )
gout="$(cd "$R4" && bash -c "$G" 2>&1)"; grc=$?
ck guard-main-checkout-rc 1 "$grc"
ck guard-main-checkout-message "close: worktree is the main checkout" "$gout"

done_
