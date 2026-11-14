#!/bin/bash
# Slice 113, the integrator's merge train: the scripts seam (train steps, failure path) and the standard-text seam (who owns the steps).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
T="$(cd "$T" && pwd -P)"
MT="$PLUGIN/scripts/merge-train.sh"
RUN="$PLUGIN/skills/run/SKILL.md"
AG="$PLUGIN/agents/integrator.md"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# a fake gh: `pr merge <branch> --merge` merges the branch into the bare origin's main; FAKE_GH_FAIL=1 refuses
mkdir -p "$T/bin"
cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "${FAKE_GH_FAIL:-}" = 1 ] && { echo "refused" >&2; exit 1; }
case "$1 $2" in
  "pr merge")
    b="$3"; c="$(mktemp -d)"
    git clone -q "$ORIGIN" "$c" && git -C "$c" checkout -q main && git -C "$c" merge -q --no-ff "origin/$b" -m "Merge $b" && git -C "$c" push -q origin main; rm -rf "$c" ;;
  "pr view") git -C "$ORIGIN" rev-parse main ;;
esac
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH"

ORIGIN="$T/origin.git"; export ORIGIN
git init -q --bare -b main "$ORIGIN"
M="$T/m"; git clone -q "$ORIGIN" "$M" 2>/dev/null; cd "$M" || exit 1; git checkout -q -b main 2>/dev/null
mkdir -p plugins/factory/.claude-plugin plugins/factory/agents docs/adr
printf '{\n  "name": "factory",\n  "version": "1.0.0"\n}\n' >plugins/factory/.claude-plugin/plugin.json
printf '# Changelog\n\nintro\n\n## factory 1.0.0 (#1)\n\nold\n' >CHANGELOG.md
# this repository's release tooling and the one line that switches it on (#210): the merge train itself knows no release step
mkdir -p scripts docs/agents; cp "$REPO"/scripts/release.sh "$REPO"/scripts/release-lib.sh "$REPO"/scripts/check-bump.sh scripts/
printf 'release-hook: scripts/release.sh\n' >docs/agents/factory.md
echo a >docs/adr/0001-a.md; touch plugins/factory/agents/.gitkeep; echo r >README.md; printf '/.claude/worktrees/\n' >.gitignore
git add -A && git commit -qm init && git push -q origin main
git branch --set-upstream-to=origin/main main >/dev/null 2>&1

# slice <id> <file>: item worktree with a factory change, its version bump to 1.1.0, its changelog entry and an ADR numbered 0002
slice() {
  local id="$1" f="$2" v="${3:-1.1.0}" w; w="$(cd "$M" && bash "$PLUGIN/scripts/worktree.sh" add item "$id")" || return 1
  ( cd "$w" || exit 1
    echo "$id" >"plugins/factory/agents/$f.md"
    sed -i.bak "s/1\\.0\\.0/$v/" plugins/factory/.claude-plugin/plugin.json && rm -f plugins/factory/.claude-plugin/plugin.json.bak
    [ -n "${NOCL:-}" ] || { sed -n '1,3p' CHANGELOG.md; printf '## factory %s (#%s)\n\nRelease: `%s`, slice %s.\nSee docs/adr/0002-s%s.\n\n' "$v" "$id" "$v" "$id" "$id"; sed -n '4,$p' CHANGELOG.md; } >C ; [ ! -f C ] || mv C CHANGELOG.md
    echo "adr $id" >"docs/adr/0002-s$id.md"
    git add -A && git commit -qm "#$id slice" )
  echo "$w"
}
W2="$(slice 2 two)"; W3="$(slice 3 three 1.1.1)"
cd "$T" || exit 1

# --- usage and approval
bash "$MT" >/dev/null 2>&1; ck usage-exit-2 2 "$?"
bash "$MT" merge "$W2" 2 >/dev/null 2>&1; ck merge-without-approval-exit-2 2 "$?"
bash "$MT" run "$W2" x --approved now >/dev/null 2>&1; ck bad-id-exit-2 2 "$?"
bash "$MT" run "$M" 2 --approved now >/dev/null 2>&1; ck main-checkout-refused-exit-2 2 "$?"
bash "$MT" run "$W3" 2 --approved now >/dev/null 2>&1; ck wrong-branch-refused-exit-2 2 "$?"
ck unapproved-nothing-merged "no" "$(git -C "$ORIGIN" log --format=%s main | grep -q 'Merge item/2' && echo yes || echo no)"

# --- the train: slice 2 first, then slice 3 rebased on slice 2's result
out="$(bash "$MT" run "$W2" 2 --approved 2026-11-11T12:00Z 2>&1)"; rc=$?
ck first-slice-exit-0 0 "$rc"
ck first-slice-merged "yes" "$(git -C "$ORIGIN" log --format=%s main | grep -q 'Merge item/2' && echo yes || echo no)"
ck first-slice-tag "factory-v1.1.0" "$(git -C "$ORIGIN" tag -l 'factory-v*')"
ck first-slice-worktree-removed "no" "$([ -e "$W2" ] && echo yes || echo no)"
ck first-slice-branch-removed-local "" "$(git -C "$M" branch --list item/2)"
ck first-slice-branch-removed-remote "" "$(git -C "$ORIGIN" branch --list item/2)"
ck first-slice-done-line "done 2 -- the lead sets the card Done" "$(printf '%s\n' "$out" | tail -n1)"

out="$(bash "$MT" run "$W3" 3 --approved 2026-11-11T12:05Z 2>&1)"; rc=$?
ck second-slice-exit-0 0 "$rc"
ck second-slice-version-clash-resolved "yes" "$(printf '%s\n' "$out" | grep -q 'resolved plugins/factory/.claude-plugin/plugin.json' && echo yes || echo no)"
ck second-slice-bump-reported "yes" "$(printf '%s\n' "$out" | grep -q '^bump: 1.1.0 -> 1.2.0' && echo yes || echo no)"
ck second-slice-changelog-clash-resolved "yes" "$(printf '%s\n' "$out" | grep -q 'resolved CHANGELOG.md: kept both' && echo yes || echo no)"
ck second-slice-bumped-above-first "1.2.0" "$(git -C "$ORIGIN" show main:plugins/factory/.claude-plugin/plugin.json | jq -r .version)"
ck second-slice-tag "factory-v1.1.0 factory-v1.2.0" "$(git -C "$ORIGIN" tag -l 'factory-v*' | sort | tr '\n' ' ' | sed 's/ $//')"
CL="$(git -C "$ORIGIN" show main:CHANGELOG.md)"
ck changelog-keeps-first-entry "1" "$(printf '%s\n' "$CL" | grep -c '^## factory 1.1.0 (#2)$')"
ck changelog-moves-second-entry "1" "$(printf '%s\n' "$CL" | grep -c '^## factory 1.2.0 (#3)$')"
ck changelog-release-line-follows "1" "$(printf '%s\n' "$CL" | grep -c '^Release: `1.2.0`, slice 3.$')"
ck changelog-newest-first "## factory 1.2.0 (#3)" "$(printf '%s\n' "$CL" | grep '^## factory' | sed -n 1p)"
ck adr-renumbered "docs/adr/0003-s3.md" "$(git -C "$ORIGIN" ls-tree -r --name-only main docs/adr | grep s3)"
ck adr-first-keeps-number "docs/adr/0002-s2.md" "$(git -C "$ORIGIN" ls-tree -r --name-only main docs/adr | grep s2)"
ck adr-reference-follows "1" "$(printf '%s\n' "$CL" | grep -c 'docs/adr/0003-s3')"
ck adr-line-printed "yes" "$(printf '%s\n' "$out" | grep -q '^adr 0002 -> 0003 docs/adr/0003-s3.md' && echo yes || echo no)"
ck second-slice-worktree-removed "no" "$([ -e "$W3" ] && echo yes || echo no)"

# --- the bump check gates the merge: a missing changelog entry is reported, nothing merged
W4="$(NOCL=1 slice 4 four)"
before="$(git -C "$ORIGIN" rev-parse main)"
out="$(bash "$MT" run "$W4" 4 --approved now 2>&1)"; rc=$?
ck missing-changelog-exit-4 4 "$rc"
ck missing-changelog-reported "yes" "$(printf '%s\n' "$out" | grep -q '^changelog: no entry' && echo yes || echo no)"
ck missing-changelog-nothing-merged "$before" "$(git -C "$ORIGIN" rev-parse main)"
ck missing-changelog-worktree-kept "yes" "$([ -e "$W4" ] && echo yes || echo no)"
git -C "$M" worktree remove --force "$W4"; git -C "$M" branch -D item/4 >/dev/null

# --- a clash outside the shared files is reported and the worktree kept
W5="$(slice 5 five)"
echo "branch side" >"$W5/README.md"; git -C "$W5" add -A; git -C "$W5" commit -qm "#5 readme"
( cd "$M" && git pull -q && echo "main side" >README.md && git commit -qam "main readme" && git push -q origin main )
out="$(bash "$MT" run "$W5" 5 --approved now 2>&1)"; rc=$?
ck conflict-exit-3 3 "$rc"
ck conflict-names-file "yes" "$(printf '%s\n' "$out" | grep -q '^conflict in: README.md' && echo yes || echo no)"
ck conflict-worktree-kept "yes" "$([ -e "$W5" ] && echo yes || echo no)"
ck conflict-rebase-aborted "no" "$([ -d "$(git -C "$W5" rev-parse --git-path rebase-merge)" ] && echo yes || echo no)"
git -C "$M" worktree remove --force "$W5"; git -C "$M" branch -D item/5 >/dev/null

# --- a failed merge keeps the worktree and reports it
( cd "$M" && git pull -q )
W6="$(slice 6 six)"
out="$(FAKE_GH_FAIL=1 bash "$MT" run "$W6" 6 --approved now 2>&1)"; rc=$?
ck failed-merge-exit-5 5 "$rc"
ck failed-merge-reported "yes" "$(printf '%s\n' "$out" | grep -q '^merge failed:' && echo yes || echo no)"
ck failed-merge-worktree-kept "yes" "$([ -e "$W6" ] && echo yes || echo no)"
ck failed-merge-branch-kept "item/6" "$(git -C "$M" branch --list item/6 | tr -d ' *+')"
ck failed-merge-no-done-line "0" "$(printf '%s\n' "$out" | grep -c '^done ')"

# --- a project without `release-hook:` gets a purely mechanical train: no release line, no tag, no version or changelog touched (#210)
( cd "$M" && git pull -q && git rm -q docs/agents/factory.md && git commit -qm "no release hook" && git push -q origin main )
W7="$(NOCL=1 slice 7 seven)"
sed -i.bak "s/1\\.2\\.0/9.9.9/" "$W7/plugins/factory/.claude-plugin/plugin.json" && rm -f "$W7/plugins/factory/.claude-plugin/plugin.json.bak"; git -C "$W7" commit -qam "#7 version"
tags_before="$(git -C "$ORIGIN" tag -l | wc -l | tr -d ' ')"
out="$(bash "$MT" run "$W7" 7 --approved now 2>&1)"; rc=$?
ck nohook-exit-0 0 "$rc"
ck nohook-merged "yes" "$(git -C "$ORIGIN" log --format=%s main | grep -q 'Merge item/7' && echo yes || echo no)"
ck nohook-no-release-words "0" "$(printf '%s\n' "$out" | grep -ciE 'bump|changelog|tag|release|version')"
ck nohook-no-new-tag "$tags_before" "$(git -C "$ORIGIN" tag -l | wc -l | tr -d ' ')"
ck nohook-version-as-the-branch-had-it "9.9.9" "$(git -C "$ORIGIN" show main:plugins/factory/.claude-plugin/plugin.json | jq -r .version)"
ck nohook-worktree-removed "no" "$([ -e "$W7" ] && echo yes || echo no)"

# --- standard-text seam: who owns the steps
has agent-runs-train "$AG" 'scripts/merge-train.sh'
has agent-merge-needs-approval "$AG" 'Approved:'
has agent-no-merge-without-approval "$AG" 'never merge a slice the lead did not mark approved'
has agent-failure-reported "$AG" 'Keep the worktree'
has agent-card-is-lead "$AG" 'the lead sets the card Done'
has run-integrator-merges "$RUN" 'the integrator does the mechanical merge'
has run-approval-or-gate "$RUN" 'approved by the person or has passed the gate'
has protocol-shell-train "$PLUGIN/references/protocol.md" 'scripts/merge-train.sh'
done_
