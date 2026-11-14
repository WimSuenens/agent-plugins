#!/bin/bash
# #210: the shipped plugin carries no release step. A grep over plugins/factory/ for the plugin's own path, its manifest, its changelog,
# the release tag and the release tooling finds only what an explicit allow list names. The fingerprint stays (it reads the manifest, read-only).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
cd "$REPO" || exit 1

# allowed <file> <fixed text>: a hit in <file> (relative to plugins/factory/) is allowed only when its line holds <fixed text>.
# Every entry says why. A new hit is a release step in the shipped plugin until proven otherwise.
ALLOW='scripts/fingerprint.sh|plugin.json|the fingerprint reads the manifest version, read-only (kind 6 and the hansei release field)
scripts/skill-graduation.sh|plugin.json|searches the manifests of the installed plugins for their domain sentence
references/a3.md|plugins/factory/|a worked example of an A3, as a target path of a countermeasure
references/protocol.md|plugins/factory/agents/developer.md|a path example for message files
references/hansei.md|dependencies of `plugin.json`|the record field context
references/run-improve.md|(`domain` in `plugin.json`)|the domain search reads the manifests of other plugins (moved out of the run skill by the split)
references/run-parallel.md|(`plugins/factory/` is not a prefix of|the overlap rule explains directory prefixes (moved out of the run skill by the split)
skills/run/SKILL.md|shared files `CHANGELOG.md`, `README.md`|the code-review trigger table names shared files by name
references/run-parallel.md|shared files `CHANGELOG.md`, `README.md`|the overlap rule names shared files by name (moved out of the run skill by the split)
skills/run/SKILL.md|evidence: plugins/factory/skills/run/SKILL.md|a worked A3 example
agents/architect.md|plugins/factory|a contract example for the paths list
skills/setup-factory-skill/assets/factory.md|CHANGELOG.md|the ownership row of a project (the project changelog)'

PAT='plugins/factory|plugin\.json|CHANGELOG\.md|factory-v|check-bump|release-class|forgotten bump'
hits="$(git grep -nIE "$PAT" -- plugins/factory ':!plugins/factory/CHANGELOG.md' | sed 's|^plugins/factory/||')"
left=""
while IFS= read -r l; do
  [ -n "$l" ] || continue
  f="${l%%:*}"; ok=0
  while IFS='|' read -r af a1 _; do
    [ "$af" = "$f" ] || continue
    case "$l" in *"$a1"*) ok=1; break ;; esac
  done <<EOF
$ALLOW
EOF
  [ "$ok" = 1 ] || left="$left$(printf '%s' "$l" | cut -c1-110)
"
done <<EOF
$hits
EOF
ck no-release-step-in-the-shipped-plugin "" "$left"

# --- the plugin's hook dispatcher: no declaration, no release step, nothing printed
RH="$PLUGIN/scripts/release-hook.sh"
mkdir -p "$T/p0/docs/agents" "$T/p1/docs/agents" "$T/p1/scripts"
printf '# Factory\n\nmeasurement: full\n' >"$T/p0/docs/agents/factory.md"
for ph in check prepare tag; do
  out="$(bash "$RH" $ph "$T/p0" 7 origin/main main 2>&1)"; rc=$?
  ck "no-hook-$ph-exit-0" 0 "$rc"; ck "no-hook-$ph-prints-nothing" "" "$out"
done
bash "$RH" resolve "$T/p0" 7 origin/main README.md >/dev/null 2>&1; ck no-hook-resolve-exit-1 1 "$?"
bash "$RH" declared "$T/p0" >/dev/null 2>&1; ck no-hook-declared-exit-1 1 "$?"
mkdir -p "$T/p2"; bash "$RH" check "$T/p2" 7 origin/main >/dev/null 2>&1; ck no-factory-md-is-no-hook 0 "$?"
printf '# Factory\n\n  release-hook: scripts/h.sh\n' >"$T/p0/docs/agents/factory.md"
bash "$RH" declared "$T/p0" >/dev/null 2>&1; ck indented-line-is-no-declaration 1 "$?"

# a declared hook is run with the phase, the worktree, the id, the base and the extra argument, in the worktree
printf '# Factory\n\nrelease-hook: scripts/h.sh\n' >"$T/p1/docs/agents/factory.md"
printf 'echo "phase=$1 id=$3 base=$4 extra=$5 cwd=$(basename "$PWD")"\nexit "${HOOK_RC:-0}"\n' >"$T/p1/scripts/h.sh"
ck declared-prints-the-path "scripts/h.sh" "$(bash "$RH" declared "$T/p1")"
ck hook-gets-its-arguments "phase=check id=7 base=origin/main extra= cwd=p1" "$(bash "$RH" check "$T/p1" 7 origin/main)"
ck hook-gets-the-extra-argument "phase=tag id=7 base=origin/main extra=item/7 cwd=p1" "$(bash "$RH" tag "$T/p1" 7 origin/main item/7)"
HOOK_RC=1 bash "$RH" check "$T/p1" 7 origin/main >/dev/null; ck hook-exit-code-passes-through 1 "$?"
printf '# Factory\n\nrelease-hook: ../x.sh\n' >"$T/p1/docs/agents/factory.md"
bash "$RH" check "$T/p1" 7 origin/main >/dev/null 2>&1; ck hook-outside-the-repository-refused 2 "$?"
printf '# Factory\n\nrelease-hook: scripts/none.sh\n' >"$T/p1/docs/agents/factory.md"
bash "$RH" check "$T/p1" 7 origin/main >/dev/null 2>&1; ck declared-but-missing-exit-2 2 "$?"

# the declaration on the base wins: a branch cannot drop the line that judges it; where the base has none, the branch's own line counts
rm -rf "$T/p3"; mkdir -p "$T/p3/docs/agents" "$T/p3/scripts"; ( cd "$T/p3" && git init -q -b main && printf 'release-hook: scripts/h.sh\n' >docs/agents/factory.md && printf 'echo ran\n' >scripts/h.sh && git add -A && git -c user.name=t -c user.email=t@t commit -qm a && git update-ref refs/remotes/origin/main HEAD && rm docs/agents/factory.md )
ck base-declaration-wins-over-a-branch-that-drops-it "scripts/h.sh" "$(bash "$RH" declared "$T/p3")"
ck base-declaration-runs-the-hook "ran" "$(bash "$RH" check "$T/p3" 7 origin/main)"
rm -rf "$T/p4"; mkdir -p "$T/p4/docs/agents" "$T/p4/scripts"; ( cd "$T/p4" && git init -q -b main && printf 'measurement: full\n' >docs/agents/factory.md && git add -A && git -c user.name=t -c user.email=t@t commit -qm a && git update-ref refs/remotes/origin/main HEAD && printf 'release-hook: scripts/h.sh\n' >docs/agents/factory.md && printf 'echo ran\n' >scripts/h.sh )
ck branch-line-counts-where-the-base-has-none "ran" "$(bash "$RH" check "$T/p4" 7 origin/main)"
printf 'release-hook: scripts/link.sh\n' >"$T/p4/docs/agents/factory.md"; ln -sf h.sh "$T/p4/scripts/link.sh"
bash "$RH" check "$T/p4" 7 origin/main >/dev/null 2>&1; ck symlinked-hook-refused 2 "$?"

# --- this repository declares its hook, and the setup template documents the optional line
ck this-repo-declares-the-hook "scripts/release.sh" "$(bash "$RH" declared "$REPO")"
ck this-repo-hook-exists 1 "$([ -f "$REPO/scripts/release.sh" ] && [ -f "$REPO/scripts/check-bump.sh" ] && [ -f "$REPO/scripts/release-class.sh" ] && echo 1 || echo 0)"
ck check-bump-left-the-plugin 0 "$([ -e "$PLUGIN/scripts/check-bump.sh" ] && echo 1 || echo 0)"
has template-documents-release-hook "$PLUGIN/skills/setup-factory-skill/assets/factory.md" '`release-hook: <path of a script in this repository>`'
has template-says-no-line-no-step "$PLUGIN/skills/setup-factory-skill/assets/factory.md" 'No line means no release step'
has run-skill-open-pr-names-the-hook "$PLUGIN/skills/run/SKILL.md" 'release-hook.sh" check'
has tracker-doc-merge-names-the-hook "$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md" 'release-hook.sh" tag'
has docs-writer-says-what-an-entry-is "$PLUGIN/agents/docs-writer.md" "a line in the project's own changelog that says what changed for its users"

# --- the release class has ONE classification: check-bump and release-class both source release-lib.sh
has check-bump-sources-the-lib "$REPO/scripts/check-bump.sh" 'release-lib.sh'
has release-class-sources-the-lib "$REPO/scripts/release-class.sh" 'release-lib.sh'
ck one-classification "1" "$(grep -lE 'plugins/factory/(skills/run/SKILL.md|references/\*\.md)' "$REPO"/scripts/*.sh | wc -l | tr -d ' ')"

# --- the architect's shell scope (protocol, ## Shell) is unchanged by this issue
OLD=bb3107c
if git -C "$REPO" cat-file -e "$OLD" 2>/dev/null; then
  shell() { awk '/^## Shell$/ {f=1; next} /^## / {f=0} f'; }
  ck architect-shell-scope-unchanged "$(git -C "$REPO" show "$OLD:plugins/factory/references/protocol.md" | shell | shasum -a 256)" "$(shell <"$PLUGIN/references/protocol.md" | shasum -a 256)"

  # --- the baseline exclusion rule means the same: the runs it excludes are the same ones, only the reason is worded generically
  ids() { grep '^A	line	- excluded:' | sed -E 's/.*excluded: (#[0-9]+) .*/\1/' | sort | tr '\n' ' '; }
  ck baseline-excluded-runs-unchanged "$(git -C "$REPO" show "$OLD:tests/factory/fixtures/baseline/expected.tsv" | ids)" "$(ids <"$REPO/tests/factory/fixtures/baseline/expected.tsv")"
  ck baseline-excludes-at-least-one 1 "$([ -n "$(ids <"$REPO/tests/factory/fixtures/baseline/expected.tsv")" ] && echo 1 || echo 0)"
  ck baseline-old-reason-gone 0 "$(grep -c 'forgotten' "$PLUGIN/references/baseline.md" "$PLUGIN/references/hansei.md" | awk -F: '{s+=$2} END {print s+0}')"
  has baseline-generic-reason "$PLUGIN/references/baseline.md" 'an item whose declared release step was skipped'

  # --- the moved check answers like the old one on this repository's recent history (the old script is read from the commit before the move)
  git -C "$REPO" show "$OLD:plugins/factory/scripts/check-bump.sh" >"$T/old-check-bump.sh"
  git -C "$REPO" show "$OLD:scripts/release-class.sh" >"$T/old-release-class.sh"
  W="$T/hist"; git -C "$REPO" worktree add -q --detach "$W" HEAD 2>/dev/null
  n=0; same=0
  for m in $(git -C "$REPO" log --first-parent --merges --format=%h -n 14 "$OLD"); do
    git -C "$W" checkout -q --detach "$m" 2>/dev/null || continue
    base="$m^1"
    o="$(cd "$W" && bash "$T/old-check-bump.sh" "$base" 2>&1; echo "exit $?")"
    nw="$(cd "$W" && bash "$REPO/scripts/check-bump.sh" "$base" 2>&1; echo "exit $?")"
    n=$((n + 1)); [ "$o" = "$nw" ] && same=$((same + 1)); [ "$o" = "$nw" ] || { echo "     $m old: $o"; echo "     $m new: $nw"; }
  done
  ck "check-bump-same-answers-on-history-($n merges)" "$n" "$same"
  ck check-bump-history-not-empty 1 "$([ "$n" -ge 5 ] && echo 1 || echo 0)"
  # release-class: the same answer for a list of paths covering every class
  git -C "$W" checkout -q --detach "$OLD" 2>/dev/null
  cls=0; clsame=0
  for ps in "plugins/factory/references/hansei.md" "plugins/factory/scripts/merge-train.sh" "plugins/factory/skills/run/SKILL.md" "plugins/factory/agents/sub/x.md" "plugins/factory/references/" "docs/agents/factory.md" "plugins/factory/hooks/hooks.json plugins/factory/agents/qa-engineer.md"; do
    # shellcheck disable=SC2086
    o="$(cd "$W" && bash "$T/old-release-class.sh" "$OLD" $ps 2>&1; echo "exit $?")"; nw="$(cd "$W" && bash "$REPO/scripts/release-class.sh" "$OLD" $ps 2>&1; echo "exit $?")"
    cls=$((cls + 1)); [ "$o" = "$nw" ] && clsame=$((clsame + 1)); [ "$o" = "$nw" ] || { echo "     $ps old: $o"; echo "     $ps new: $nw"; }
  done
  ck release-class-same-answers "$cls" "$clsame"
  git -C "$REPO" worktree remove --force "$W" 2>/dev/null
else
  skip release-split-history "commit $OLD not in this clone"
fi

done_
