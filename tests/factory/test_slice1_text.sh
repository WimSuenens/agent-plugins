#!/bin/bash
# Slice 1 of #207, the standard-text seam: one pin per decision that changes wording (#195, #196, #193, #194, #162, #187-leftovers).
# The behaviour behind each wording is tested in the script tests next to it.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RUN="$PLUGIN/skills/run/SKILL.md"; AR="$PLUGIN/agents/architect.md"; HA="$PLUGIN/references/hansei.md"
sect() { awk -v h="$2" '$0==h{f=1;print;next} f&&/^## /{exit} f' "$1"; }

# --- #195: the release class comes from the bump check's dry-run, quoted in the contract
S6="$T/step6.md"; sect "$RUN" '## 6. Run the stages' > "$S6"
has bump-dryrun-step6 "$S6" 'check-bump.sh" --intended origin/main <the paths the slice will change>'
has bump-dryrun-step6-quote "$S6" 'quote its answer line in the contract'
has bump-dryrun-step6-neutral "$S6" 'A change that leaves the meaning of standard text unchanged still counts as standard work.'
has bump-dryrun-architect "$AR" 'check-bump.sh" --intended origin/main'
has bump-dryrun-architect-quote "$AR" 'quote its answer line in the contract'
has bump-dryrun-architect-neutral "$AR" 'A change that leaves the meaning of standard text unchanged still counts as standard work.'

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
done_
