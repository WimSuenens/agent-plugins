#!/bin/bash
# #207 slice 3, item 6: this repository's release tooling learns a declared major. A slice declares it in its CHANGELOG entry as
# `Release: major (<reason>)`; scripts/release-lib.sh reads it once, so check-bump.sh, release-class.sh and release.sh prepare agree.
# A declaration only raises the class: the class computed from the changed paths is the floor. Dev-repo tooling, never in the plugin.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RC="$REPO/scripts/release-class.sh"
RS="$REPO/scripts/release.sh"
F=plugins/factory
git init -q --bare -b main "$T/origin.git"; git clone -q "$T/origin.git" "$T/r" 2>/dev/null; cd "$T/r" || exit 1; git checkout -q -b main 2>/dev/null
mkdir -p $F/.claude-plugin $F/agents $F/scripts $F/references $F/skills/run
echo '{"name":"factory","version":"2.18.0"}' > $F/.claude-plugin/plugin.json
echo a > $F/agents/developer.md; echo s > $F/scripts/s.sh; echo p > $F/references/protocol.md; echo r > $F/skills/run/SKILL.md
printf '# Changelog\n\n## factory 2.18.0 (#1)\n\nRelease: `2.18.0`, a **minor** release.\n' > CHANGELOG.md
git add -A; git commit -qm base; git push -q origin main 2>/dev/null; git fetch -q origin
run() { out="$(bash "$CB" "$@" 2>"$T/err")"; code=$?; }
rc() { out="$(bash "$RC" "$@" 2>"$T/err")"; code=$?; }
ver() { echo '{"name":"factory","version":"'"$1"'"}' > $F/.claude-plugin/plugin.json; }
newb() { git checkout -q main; git branch -q -D w 2>/dev/null; git checkout -q -b w; }
# entry <id> <version> <release line...>: this branch's changelog entry
entry() { local id="$1" v="$2"; shift 2; { printf '# Changelog\n\n## factory %s (#%s)\n\n' "$v" "$id"; for l in "$@"; do printf '%s\n' "$l"; done; printf '\n'; sed -n '3,$p' CHANGELOG.md; } > CHANGELOG.new; mv CHANGELOG.new CHANGELOG.md; }

# --- check-bump.sh
newb; echo y >> $F/references/protocol.md; ver 3.0.0; entry 7 3.0.0 'Release: major (a project without the table can no longer run)' 'Release: `3.0.0`, a **major** release.'; git add -A; git commit -qm c; run
ck declared-major-accepted "pass: major bump needed, 2.18.0 -> 3.0.0" "$out"; ck declared-major-accepted-exit 0 $code
newb; echo y >> $F/references/protocol.md; ver 2.19.0; entry 7 2.19.0 'Release: major (a reason)'; git add -A; git commit -qm c; run
ck declared-major-minor-bump-refused-exit 1 $code
ck declared-major-minor-bump-says-3.0.0 "yes" "$(printf '%s' "$out" | head -n1 | grep -q 'needs at least a major bump (3.0.0)' && echo yes || echo no)"
newb; echo y >> $F/references/protocol.md; ver 3.0.0; entry 7 3.0.0 'Release: major'; git add -A; git commit -qm c; run
ck bare-major-refused-exit 1 $code
ck bare-major-says-reason "yes" "$(printf '%s' "$out" | grep -q 'Release: major needs a reason in brackets' && echo yes || echo no)"
newb; echo y >> $F/references/protocol.md; ver 3.0.0; entry 7 3.0.0 'Release: major ()'; git add -A; git commit -qm c; run
ck empty-brackets-refused-exit 1 $code
newb; echo y >> $F/references/protocol.md; ver 3.0.0; entry 7 3.0.0 'Release: major (   )'; git add -A; git commit -qm c; run
ck blank-brackets-refused-exit 1 $code
# a declaration lower than what the paths need is refused, whatever the version
newb; echo y >> $F/references/protocol.md; ver 2.19.0; entry 7 2.19.0 'Release: patch (small)'; git add -A; git commit -qm c; run
ck declared-patch-on-minor-paths-refused-exit 1 $code
ck declared-patch-on-minor-paths-says-why "yes" "$(printf '%s' "$out" | head -n1 | grep -q 'declared patch' && echo yes || echo no)"
newb; echo y >> $F/references/protocol.md; ver 2.19.0; entry 7 2.19.0 'Release: minor (small)'; git add -A; git commit -qm c; run
ck declared-minor-on-minor-paths-passes "pass: minor bump needed, 2.18.0 -> 2.19.0" "$out"
# a declaration can raise: minor declared on script-only paths needs a minor
newb; echo y >> $F/scripts/s.sh; ver 2.18.1; entry 7 2.18.1 'Release: minor (new behaviour)'; git add -A; git commit -qm c; run
ck declared-minor-raises-patch-refused-exit 1 $code
newb; echo y >> $F/scripts/s.sh; ver 2.19.0; entry 7 2.19.0 'Release: minor (new behaviour)'; git add -A; git commit -qm c; run
ck declared-minor-raises-patch-passes-exit 0 $code
# an entry that main already holds is no declaration of this branch
git checkout -q main; entry 5 2.18.0 'Release: major (old)'; git commit -qam old; git push -q origin main 2>/dev/null; git fetch -q origin
newb; echo y >> $F/scripts/s.sh; ver 2.18.1; git commit -qam c; run
ck declaration-on-main-not-this-branch "pass: patch bump needed, 2.18.0 -> 2.18.1" "$out"
git checkout -q main; git reset -q --hard HEAD~1; git push -q -f origin main 2>/dev/null; git fetch -q origin
# undeclared behaves as before
newb; echo y >> $F/references/protocol.md; git commit -qam c; run
ck undeclared-unbumped-refused "refuse: standard work changed; plugin.json version 2.18.0 -> 2.18.0; needs at least a minor bump (2.19.0)" "$(printf '%s' "$out" | head -n1)"
ver 3.0.0; git commit -qam v; run
ck undeclared-major-bump-still-passes "pass: minor bump needed, 2.18.0 -> 3.0.0" "$out"
# no factory paths: a declaration is ignored
newb; mkdir -p docs; echo d > docs/d.md; entry 7 2.19.0 'Release: major (x)'; git add -A; git commit -qm c; run
ck declaration-without-factory-paths "pass: no factory paths changed" "$out"

# --- release-class.sh
rc origin/main --declared 'major (a project without the table can no longer run)' $F/references/protocol.md
ck class-declared "needs: major bump (declared: a project without the table can no longer run), 2.18.0 -> 3.0.0" "$out"; ck class-declared-exit 0 $code
rc origin/main $F/references/protocol.md
ck class-undeclared-as-before "needs: minor bump (standard work), 2.18.0 -> 2.19.0" "$out"
rc origin/main --declared major $F/references/protocol.md; ck class-bare-major-refused 2 $code
rc origin/main --declared 'major ()' $F/references/protocol.md; ck class-empty-brackets-refused 2 $code
rc origin/main --declared 'patch (x)' $F/references/protocol.md; ck class-lower-refused 1 $code
ck class-lower-says-why "yes" "$(printf '%s' "$out" | grep -q 'declared patch' && echo yes || echo no)"
rc origin/main --declared 'minor (x)' $F/scripts/s.sh
ck class-declared-minor-raises "needs: minor bump (declared: x), 2.18.0 -> 2.19.0" "$out"
rc origin/main --declared 'major (x)' docs/d.md
ck class-declared-no-factory-paths "needs: no bump (no factory paths intended)" "$out"
rc origin/main --declared 'huge (x)' $F/references/protocol.md; ck class-unknown-class-usage 2 $code
# the three agree on this slice's kind of change: the dry-run suggestion is accepted by the check
newb; echo y >> $F/references/protocol.md; want="$(bash "$RC" origin/main --declared 'major (agree)' $F/references/protocol.md | sed -E 's/.* -> //')"
ver "$want"; entry 7 "$want" 'Release: major (agree)'; git add -A; git commit -qm c; run
ck class-and-check-agree "pass: major bump needed, 2.18.0 -> 3.0.0" "$out"

# --- release.sh prepare: raises a branch to the declared major and moves the entry
newb; echo y >> $F/references/protocol.md; entry 7 2.19.0 'Release: major (agree)' 'Release: `2.19.0`, a **minor** release.'; ver 2.19.0; git add -A; git commit -qm c
pout="$(bash "$RS" prepare "$T/r" 7 origin/main 2>&1)"; pcode=$?
ck prepare-raises-to-major-exit 0 $pcode
ck prepare-version "3.0.0" "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $F/.claude-plugin/plugin.json)"
ck prepare-entry-moved "yes" "$(grep -q '^## factory 3.0.0 (#7)$' CHANGELOG.md && echo yes || echo no)"
run; ck prepare-then-check-passes "pass: major bump needed, 2.18.0 -> 3.0.0" "$out"
# a bare declaration stops the train
newb; echo y >> $F/references/protocol.md; entry 8 2.19.0 'Release: major'; ver 2.19.0; git add -A; git commit -qm c
pout="$(bash "$RS" prepare "$T/r" 8 origin/main 2>&1)"; ck prepare-bare-major-stops-exit 4 $?

# --- review: a malformed or capitalised declaration is read, not ignored
newb; echo y >> $F/references/protocol.md; ver 2.19.0; entry 7 2.19.0 'Release: major(breaking)'; git add -A; git commit -qm c; run
ck no-space-before-brackets-read-as-major-exit 1 $code
ck no-space-before-brackets-says-3.0.0 "yes" "$(printf '%s' "$out" | head -n1 | grep -q 'needs at least a major bump (3.0.0)' && echo yes || echo no)"
newb; echo y >> $F/references/protocol.md; ver 2.19.0; entry 7 2.19.0 'Release: Major (reason)'; git add -A; git commit -qm c; run
ck capitalised-read-as-major-exit 1 $code
newb; echo y >> $F/references/protocol.md; ver 3.0.0; entry 7 3.0.0 'Release: major because it breaks'; git add -A; git commit -qm c; run
ck major-without-brackets-refused-exit 1 $code
ck major-without-brackets-says-reason "yes" "$(printf '%s' "$out" | grep -q 'needs a reason in brackets' && echo yes || echo no)"
newb; echo y >> $F/references/protocol.md; ver 2.19.0; entry 7 2.19.0 'Release: majority view' 'Release: `2.19.0`, a **minor** release.'; git add -A; git commit -qm c; run
ck other-word-is-no-declaration "pass: minor bump needed, 2.18.0 -> 2.19.0" "$out"
done_
