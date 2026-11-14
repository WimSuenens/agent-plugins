#!/bin/bash
# Slice 1 of #207, the standard-text seam: one pin per decision that changes wording (#195, #196, #193, #194, #162, #187-leftovers).
# The behaviour behind each wording is tested in the script tests next to it.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RUN="$PLUGIN/skills/run/SKILL.md"; AR="$PLUGIN/agents/architect.md"; HA="$PLUGIN/references/hansei.md"
sect() { awk -v h="$2" '$0==h{f=1;print;next} f&&/^## /{exit} f' "$1"; }

# --- #196: briefs name home paths in home-relative form and worktrees repository-relative
PR_="$PLUGIN/references/protocol.md"
RT="$T/roletasks.md"; sect "$RUN" '## Role tasks' > "$RT"
has home-paths-run-rule "$RT" 'A brief never carries a path under the home directory as the substituted absolute path: write `~/...` in prose and `"$HOME/..."` inside a quoted shell command (a leading `~/` inside double quotes is not expanded), and name a worktree as `.claude/worktrees/<id>`.'
has home-paths-template "$PR_" '    Inputs: <file paths and tracker issue numbers; a worktree as `.claude/worktrees/<id>`, a home path as `~/...` in prose or `"$HOME/..."` in a quoted shell command>'

# --- #193: the cross-check reads the author date, which a rebase keeps
S2="$T/sec2.md"; sect "$HA" '## 2. Cross-check before the record' > "$S2"
hasnt crosscheck-no-committer-date "$S2" '%cI'
has crosscheck-author-date "$S2" "git log item/<id> --format='%aI %s'"
has crosscheck-why "$S2" 'Read the author date, not the committer date: a rebase rewrites the committer date of every commit it replays, and the author date stays.'

# --- #194 option (b): parallel items read not captured, no sixth wait kind
HAS="$T/ha-measures.md"; awk '/^### Measures/{f=1} f' "$HA" > "$HAS"
has parallel-flow-efficiency "$HA" 'Flow efficiency and the Lead'"'"'s two token lines (`spend`, `peak context`) read `not captured (items ran in parallel)` when a role task of another item overlaps the item'"'"'s window (`started` to approval): the lead'"'"'s attention went to that item, and no wait kind records it. This check comes first.'
has parallel-token-row "$HA" 'for the Lead, `not captured (items ran in parallel)` when another item'"'"'s role task overlaps the window (see *Flow efficiency* below), else its main-session transcript(s) between the ledger'"'"'s `started` and approval'
ck parallel-no-sixth-wait-kind 0 "$(grep -ci 'sixth wait kind\|lead busy' "$HA")"

# --- kind 3: a role's own role file and skills folder are not a hit
has kind3-own-role-file "$RUN" 'a role'"'"'s own `docs/agents/roles/<role>.md` and `docs/agents/skills/<role>/` (*Role knowledge* tells every role to write them; the fence and what a role may raise are untouched),'
done_
