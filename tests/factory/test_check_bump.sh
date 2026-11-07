#!/bin/bash
# check-bump.sh: AC-8 (script side), AC-9 (script side), AC-10 and contract 39-plugin-scripts section 2.
# Runs only on throwaway repos in a temp dir with a local bare "origin"; nothing is pushed anywhere else.
. "$(dirname "$0")/lib.sh"

git init -q --bare -b main "$T/origin.git"
git clone -q "$T/origin.git" "$T/r" 2>/dev/null; cd "$T/r" || exit 1; git checkout -q -b main 2>/dev/null
F=plugins/factory
mkdir -p $F/.claude-plugin $F/agents $F/scripts $F/hooks $F/references/sub $F/skills/run $F/skills/setup-factory-skill docs
echo '{"name":"factory","version":"1.0.0"}' > $F/.claude-plugin/plugin.json
echo a > $F/agents/developer.md; echo s > $F/scripts/s.sh; echo h > $F/hooks/hooks.json; echo p > $F/references/protocol.md
echo n > $F/references/sub/nested.md; echo r > $F/skills/run/SKILL.md; echo x > $F/skills/setup-factory-skill/SKILL.md
echo d > docs/d.md; echo m > README.md; echo o > $F/README.md
git add -A; git commit -qm base; git push -q origin main 2>/dev/null; git fetch -q origin
run() { out="$(bash "$CB" "$@" 2>"$T/err")"; code=$?; }
ver() { echo '{"name":"factory","version":"'"$1"'"}' > $F/.claude-plugin/plugin.json; }
newb() { git checkout -q main; git branch -q -D w 2>/dev/null; git checkout -q -b w; }
refuse_std() { printf 'refuse: standard work changed; plugin.json version %s -> %s; needs at least a minor bump (%s)\n%s' "$1" "$2" "$3" "$4"; }

# --- AC-10: nothing under plugins/factory/ changed
newb; echo y > docs/d.md; echo z >> README.md; git commit -qam c; run
ck ac10-pass "pass: no factory paths changed" "$out"; ck ac10-exit 0 $code
# a sibling folder whose name starts with "factory" is not the factory
newb; mkdir -p plugins/factory-other; echo q > plugins/factory-other/x.md; git add -A; git commit -qm c; run
ck ac10-sibling-prefix "pass: no factory paths changed" "$out"
# a repo with no plugins/factory at all
mkdir "$T/other"; ( cd "$T/other" && git init -q -b main && echo a > a && git add a && git commit -qm a && git update-ref refs/remotes/origin/main HEAD && echo b > b && git add b && git commit -qm b )
out="$(cd "$T/other" && bash "$CB")"; code=$?
ck ac10-other-project "pass: no factory paths changed" "$out"; ck ac10-other-project-exit 0 $code

# --- AC-9: agents/developer.md edited, plugin.json unchanged -> refuse naming the minor bump
newb; echo y >> $F/agents/developer.md; git commit -qam c; run
ck ac9-unbumped "$(refuse_std 1.0.0 1.0.0 1.1.0 '  plugins/factory/agents/developer.md')" "$out"; ck ac9-unbumped-exit 1 $code
ver 1.0.1; git commit -qam v; run
ck ac9-patch-only "$(refuse_std 1.0.0 1.0.1 1.1.0 '  plugins/factory/agents/developer.md')" "$out"; ck ac9-patch-only-exit 1 $code
ver 1.1.0; git commit -qam v; run; ck ac8-minor-passes "pass: minor bump needed, 1.0.0 -> 1.1.0" "$out"; ck ac8-minor-passes-exit 0 $code
ver 2.0.0; git commit -qam v; run; ck ac8-major-passes "pass: minor bump needed, 1.0.0 -> 2.0.0" "$out"
ver 1.10.0; git commit -qam v; run; ck ac8-numeric-not-text-compare "pass: minor bump needed, 1.0.0 -> 1.10.0" "$out"
ver 0.9.0; git commit -qam v; run; ck ac8-lower-refuses 1 $code

# --- AC-8: each standard-work file kind needs a minor
for p in skills/run/SKILL.md references/protocol.md agents/developer.md; do
  newb; echo y >> $F/$p; ver 1.0.1; git commit -qam c; run
  ck "ac8-$p-needs-minor" "$(refuse_std 1.0.0 1.0.1 1.1.0 "  plugins/factory/$p")" "$out"
done
newb; echo h > $F/references/hansei.md; ver 1.0.9; git add -A; git commit -qm c; run; ck ac8-new-reference-needs-minor 1 $code
newb; git rm -q $F/agents/developer.md; ver 1.0.1; git commit -qam c; run; ck ac8-deleted-agent-needs-minor 1 $code
newb; git mv $F/agents/developer.md $F/agents/dev.md; ver 1.0.1; git commit -qam c; run
ck ac8-rename-lists-both "$(refuse_std 1.0.0 1.0.1 1.1.0 '  plugins/factory/agents/dev.md
  plugins/factory/agents/developer.md')" "$out"

# --- AC-8: any other factory path needs at least a patch
for p in scripts/s.sh hooks/hooks.json skills/setup-factory-skill/SKILL.md references/sub/nested.md README.md; do
  newb; echo y >> $F/$p; git commit -qam c; run
  ck "ac8-$p-unbumped-refused" "refuse: factory files changed; plugin.json version 1.0.0 -> 1.0.0; needs at least a patch bump (1.0.1)
  plugins/factory/$p" "$out"; ck "ac8-$p-unbumped-exit" 1 $code
  ver 1.0.1; git commit -qam v; run; ck "ac8-$p-patch-passes" "pass: patch bump needed, 1.0.0 -> 1.0.1" "$out"
done
newb; echo y >> $F/scripts/s.sh; ver 1.1.0; git commit -qam c; run; ck patch-level-minor-bump-passes "pass: patch bump needed, 1.0.0 -> 1.1.0" "$out"
newb; ver 1.0.1; git commit -qam v; run; ck plugin-json-only-patch "pass: patch bump needed, 1.0.0 -> 1.0.1" "$out"
newb; ver 0.9.9; git commit -qam v; run
ck plugin-json-only-lowered-listed "refuse: factory files changed; plugin.json version 1.0.0 -> 0.9.9; needs at least a patch bump (1.0.1)
  plugins/factory/.claude-plugin/plugin.json" "$out"
# contract example: plugin.json description changed alone, version kept -> patch needed, plugin.json listed
newb; echo '{"name":"factory","description":"x","version":"1.0.0"}' > $F/.claude-plugin/plugin.json; git commit -qam d; run
ck contract-example-json-description-only "refuse: factory files changed; plugin.json version 1.0.0 -> 1.0.0; needs at least a patch bump (1.0.1)
  plugins/factory/.claude-plugin/plugin.json" "$out"; ck contract-example-json-description-only-exit 1 $code
# plugin.json left out of the path lines when other paths changed too (developer's resolution of contract example 2)
newb; echo y >> $F/scripts/s.sh; ver 1.0.0; echo '{"name":"factory", "version":"1.0.0"}' > $F/.claude-plugin/plugin.json; git commit -qam c; run
ck plugin-json-not-listed-with-others "refuse: factory files changed; plugin.json version 1.0.0 -> 1.0.0; needs at least a patch bump (1.0.1)
  plugins/factory/scripts/s.sh" "$out"

# --- versions
newb; echo y >> $F/agents/developer.md; git rm -q $F/.claude-plugin/plugin.json; git commit -qam c; run
ck new-version-absent "$(refuse_std 1.0.0 '(absent)' 1.1.0 '  plugins/factory/agents/developer.md')" "$out"
newb; echo y >> $F/agents/developer.md; ver 1.x; git commit -qam c; run; ck new-version-not-semver-exit 1 $code
newb; echo y >> $F/agents/developer.md; ver 1.1.0-rc1; git commit -qam c; run; ck new-version-prerelease-refused 1 $code
# old version absent (this item's own case): counts as 0.0.0
git checkout -q main; git checkout -q -b nov; echo '{"name":"factory"}' > $F/.claude-plugin/plugin.json; git commit -qam nov
git branch -q -f nobase nov
git checkout -q -b w2 nov; echo y >> $F/agents/developer.md; ver 1.0.0; git commit -qam c; run nobase
ck item39-old-absent "pass: minor bump needed, 0.0.0 -> 1.0.0" "$out"
# base is the given ref's tip: main moved ahead to 1.1.0 after the fork, branch at 1.0.1 must refuse
git checkout -q main; git branch -q -D w 2>/dev/null; git checkout -q -b w
echo y >> $F/scripts/s.sh; ver 1.0.1; git commit -qam c
git checkout -q -b ahead main; echo z >> $F/agents/developer.md; ver 1.1.0; git commit -qam m; git checkout -q w; run ahead
ck base-ahead-refuses "refuse: factory files changed; plugin.json version 1.1.0 -> 1.0.1; needs at least a patch bump (1.1.1)
  plugins/factory/scripts/s.sh" "$out"
# main moved ahead with factory changes; branch touches none -> three-dot diff ignores main's own changes
git checkout -q -b docsonly main; echo q >> docs/d.md; git commit -qam d; run ahead
ck three-dot-ignores-base-changes "pass: no factory paths changed" "$out"

# --- uncommitted and staged changes don't count
newb; echo y >> $F/agents/developer.md; run; ck uncommitted-ignored "pass: no factory paths changed" "$out"
git add $F/agents/developer.md; run; ck staged-ignored "pass: no factory paths changed" "$out"; git reset -q --hard

# --- runs from a subdirectory of the worktree
newb; echo y >> $F/agents/developer.md; git commit -qam c
out="$(cd $F/agents && bash "$CB" 2>/dev/null)"; ck runs-from-subdir "$(refuse_std 1.0.0 1.0.0 1.1.0 '  plugins/factory/agents/developer.md')" "$out"

# --- exit 2 cases: nothing on stdout, reason on stderr
run nope; ck bad-base-exit 2 $code; ck bad-base-stdout "" "$out"; ck bad-base-stderr 1 "$([ -s "$T/err" ] && echo 1)"
mkdir "$T/nr"; out="$(cd "$T/nr" && bash "$CB" 2>"$T/err")"; code=$?
ck not-a-repo-exit 2 $code; ck not-a-repo-stdout "" "$out"; ck not-a-repo-stderr 1 "$([ -s "$T/err" ] && echo 1)"
# unrelated histories: no merge base
git checkout -q --orphan lone; git rm -rqf . ; echo l > l; git add l; git commit -qm lone
run main; ck no-merge-base-exit 2 $code; ck no-merge-base-stdout "" "$out"
# default base origin/main missing
mkdir "$T/noorigin"; ( cd "$T/noorigin" && git init -q -b main && echo a > a && git add a && git commit -qm a )
out="$(cd "$T/noorigin" && bash "$CB" 2>/dev/null)"; code=$?; ck default-base-missing-exit 2 $code

# --- leading zeros (contract section 2 as of ed0e627)
# branch version 1.08.0 over main's 1.0.0 with a scripts/ change: refused, smallest valid suggestion (contract example)
cd "$T/r"; newb; echo y >> $F/scripts/s.sh; ver 1.08.0; git commit -qam c; run
ck leading-zero-branch-refuses "refuse: factory files changed; plugin.json version 1.0.0 -> 1.08.0; needs at least a patch bump (1.0.1)
  plugins/factory/scripts/s.sh" "$out"; ck leading-zero-branch-exit 1 $code
newb; echo y >> $F/agents/developer.md; ver 01.1.0; git commit -qam c; run
ck leading-zero-major-branch-refuses "$(refuse_std 1.0.0 01.1.0 1.1.0 '  plugins/factory/agents/developer.md')" "$out"
newb; echo y >> $F/agents/developer.md; ver ""; git commit -qam c; run
# (contract: "<new> printed as found, (absent) when there is none"; an empty string may print either way)
ck empty-branch-version-refuses 1 "$(line "$out" 1 | grep -cE '^refuse: standard work changed; plugin.json version 1\.0\.0 -> (\(absent\))?; needs at least a minor bump \(1\.1\.0\)$')"; ck empty-branch-version-exit 1 $code
# base (origin/main stand-in) holding 1.08.0, or an empty version: exit 2, nothing on stdout, reason on stderr
git checkout -q main; git checkout -q -b lz; ver 1.08.0; git commit -qam lz; git branch -q lzbase
echo y >> $F/agents/developer.md; ver 1.9.0; git commit -qam c; run lzbase
ck leading-zero-base-exit-2 2 $code; ck leading-zero-base-no-stdout "" "$out"; ck leading-zero-base-stderr 1 "$([ -s "$T/err" ] && echo 1)"
ck leading-zero-base-no-abs-path 0 "$(grep -cF "$T" "$T/err")"
git checkout -q main; git checkout -q -b ez; ver ""; git commit -qam ez; git branch -q ezbase
echo y >> $F/agents/developer.md; ver 1.1.0; git commit -qam c; run ezbase
ck empty-base-exit-2 2 $code; ck empty-base-no-stdout "" "$out"
# base with no version key is 0.0.0 (covered by item39-old-absent); base not a semver otherwise
git checkout -q main; git checkout -q -b vb; ver v1.0.0; git commit -qam vb; git branch -q vbase
echo y >> $F/scripts/s.sh; ver 1.0.1; git commit -qam c; run vbase; ck v-prefixed-base-exit-2 2 $code

# --- feedback 15 #5 (security L1): non-ASCII paths are classified by their real names
newb; printf 'c\n' > "$F/references/café.md"; ver 1.0.1; git add -A; git commit -qm c; run
ck nonascii-reference-needs-minor "$(refuse_std 1.0.0 1.0.1 1.1.0 '  plugins/factory/references/café.md')" "$out"; ck nonascii-reference-exit 1 $code
ver 1.1.0; git commit -qam v; run; ck nonascii-reference-minor-passes "pass: minor bump needed, 1.0.0 -> 1.1.0" "$out"
newb; printf 'a\n' > "$F/agents/rôle dev.md"; ver 1.0.1; git add -A; git commit -qm c; run
ck nonascii-space-agent-needs-minor "$(refuse_std 1.0.0 1.0.1 1.1.0 '  plugins/factory/agents/rôle dev.md')" "$out"
# non-ASCII outside standard work stays a patch
newb; printf 's\n' > "$F/scripts/naïve.sh"; ver 1.0.1; git add -A; git commit -qm c; run
ck nonascii-script-patch-passes "pass: patch bump needed, 1.0.0 -> 1.0.1" "$out"
# core.quotePath=true in the user's config must not change the result
newb; printf 'c\n' > "$F/references/ü.md"; ver 1.0.1; git add -A; git commit -qm c
out="$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.quotePath GIT_CONFIG_VALUE_0=true bash "$CB" 2>/dev/null)"; code=$?
ck nonascii-quotepath-true-needs-minor 1 $code
# a tab in a name (git quotes it even with quotePath off)
newb; printf 't\n' > "$F/references/a	b.md"; ver 1.0.1; git add -A; git commit -qm c; run
ck tab-in-name-needs-minor 1 $code

# --- security L1a (fixed in 9ee1cdc): a newline in a name must not split it into two harmless-looking paths.
# Before the fix, agents/dev<LF>.md split into agents/dev and .md and passed with a patch bump.
nl='
'
newb; printf 'a\n' > "$F/agents/dev${nl}.md"; ver 1.0.1; git add -A; git commit -qm c; run
ck newline-agent-refuses 1 $code
ck newline-agent-standard-work "refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.1; needs at least a minor bump (1.1.0)" "$(line "$out" 1)"
ver 1.1.0; git commit -qam v; run; ck newline-agent-minor-passes "pass: minor bump needed, 1.0.0 -> 1.1.0" "$out"; ck newline-agent-minor-exit 0 $code
# a nested reference whose folder name holds a newline: it split into references/x and plugins/y.md (patch) before the fix
newb; mkdir -p "$F/references/x${nl}plugins"; printf 'r\n' > "$F/references/x${nl}plugins/y.md"; ver 1.0.1; git add -A; git commit -qm c; run
ck newline-nested-reference-refuses 1 $code
# fail closed: a newline name anywhere under plugins/factory/ counts as standard work (developer decision, feedback 25)
newb; printf 's\n' > "$F/scripts/a${nl}b.sh"; ver 1.0.1; git add -A; git commit -qm c; run
ck newline-script-fails-closed 1 $code
ck newline-script-standard-work 1 "$(line "$out" 1 | grep -c '^refuse: standard work changed;')"
# a newline name with a minor bump passes
ver 1.1.0; git commit -qam v; run
ck newline-script-minor-passes "pass: minor bump needed, 1.0.0 -> 1.1.0" "$out"

# --- slice 64: a major bump passes, and the unchanged version is refused (contracts/64-release.md section 1)
newb; echo n > $F/agents/developer.md; ver 3.2.1; git add -A; git commit -qm c; git checkout -q main; ver 1.3.0; git commit -qam v13; git push -q origin main 2>/dev/null; git fetch -q origin
newb; echo changed > $F/skills/run/SKILL.md; ver 2.0.0; git add -A; git commit -qm c; run
ck major-bump-from-1.3.0-passes "pass: minor bump needed, 1.3.0 -> 2.0.0" "$out"; ck major-bump-exit 0 $code
newb; echo changed2 > $F/skills/run/SKILL.md; ver 1.3.0; git add -A; git commit -qm c; run
ck same-version-with-standard-work-refused 1 $code
ck same-version-refusal-says-standard-work 1 "$(printf '%s\n' "$out" | grep -c '^refuse: standard work changed;')"

done_
