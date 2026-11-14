#!/bin/bash
# #195, kept out of the shipped plugin: the dry-run of the bump check is dev-repo tooling (scripts/release-class.sh at the repo root),
# for the one repository that develops the factory. A project that only uses the factory never sees it.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RC="$REPO/scripts/release-class.sh"
F=plugins/factory
git init -q --bare -b main "$T/origin.git"; git clone -q "$T/origin.git" "$T/r" 2>/dev/null; cd "$T/r" || exit 1; git checkout -q -b main 2>/dev/null
mkdir -p $F/.claude-plugin $F/agents $F/scripts $F/references/sub $F/skills/run docs
echo '{"name":"factory","version":"1.3.0"}' > $F/.claude-plugin/plugin.json
echo a > $F/agents/developer.md; echo s > $F/scripts/s.sh; echo p > $F/references/protocol.md; echo n > $F/references/sub/n.md; echo r > $F/skills/run/SKILL.md; echo d > docs/d.md
git add -A; git commit -qm base; git push -q origin main 2>/dev/null; git fetch -q origin
run() { out="$(bash "$RC" "$@" 2>"$T/err")"; code=$?; }

run origin/main $F/references/hansei.md
ck standard-text-minor "needs: minor bump (standard work), 1.3.0 -> 1.4.0" "$out"; ck standard-text-exit 0 $code
run origin/main $F/agents/architect.md $F/scripts/s.sh
ck agent-and-script-minor "needs: minor bump (standard work), 1.3.0 -> 1.4.0" "$out"
run origin/main $F/skills/run/SKILL.md
ck run-skill-minor "needs: minor bump (standard work), 1.3.0 -> 1.4.0" "$out"
# a change that leaves the meaning of standard text unchanged is still standard work: the class follows the path, not the meaning
run origin/main $F/references/protocol.md
ck meaning-neutral-still-minor "needs: minor bump (standard work), 1.3.0 -> 1.4.0" "$out"
run origin/main $F/references/
ck directory-of-standard-text-minor "needs: minor bump (standard work), 1.3.0 -> 1.4.0" "$out"
run origin/main $F/scripts/s.sh
ck script-only-patch "needs: patch bump (factory files), 1.3.0 -> 1.3.1" "$out"
run origin/main docs/d.md
ck no-factory-paths "needs: no bump (no factory paths intended)" "$out"; ck no-factory-paths-exit 0 $code
run origin/main; ck no-paths-usage 2 $code
run no-such-ref $F/scripts/s.sh; ck bad-base-exit-2 2 $code
# the answer agrees with the real check on the real change, for each class
for f in $F/references/protocol.md $F/scripts/s.sh; do
  git checkout -q main; git branch -q -D w 2>/dev/null; git checkout -q -b w; echo more >> $f; git commit -qam c
  want="$(bash "$REPO/scripts/check-bump.sh" origin/main | head -n1 | sed -E 's/.*needs at least a ([a-z]+) bump.*/\1/')"
  run origin/main $f
  ck "agrees-with-check-bump-$(basename $f)" "$want" "$(printf '%s' "$out" | sed -E 's/^needs: ([a-z]+) bump.*/\1/')"
done
done_
