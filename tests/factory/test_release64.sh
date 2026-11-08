#!/bin/bash
# Slice 64, release 2.0.0: AC-44 (version, bump check, fingerprints), AC-45 (paths, home paths, secrets, no snapshot), AC-46 (changelog, once the docs-writer has run).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
PS="$SCRIPTS/paths.sh"
cd "$REPO" || exit 1
PJ="$PLUGIN/.claude-plugin/plugin.json"

# ---------- AC-44 ----------
ck ac44-plugin-json-version-2.0.0 "2.0.0" "$(jq -r .version "$PJ")"
ck ac44-version-is-semver 1 "$(jq -r .version "$PJ" | grep -Ec '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$')"
if git rev-parse --verify -q origin/main >/dev/null; then
  ck ac44-main-version-1.3.0 "1.3.0" "$(git show origin/main:plugins/factory/.claude-plugin/plugin.json | jq -r .version)"
  out="$(bash "$CB" 2>&1)"; rc=$?
  ck ac44-check-bump-exit-0 0 "$rc"
  ck ac44-check-bump-line "pass: minor bump needed, 1.3.0 -> 2.0.0" "$out"
  # fingerprints: both move against main, and are quoted for the verdict
  rm -rf "$T/mainfp"; mkdir -p "$T/mainfp"; git archive origin/main plugins/factory | tar -x -C "$T/mainfp"
  new="$(bash "$FP" "$PLUGIN" 2>&1)"; old="$(bash "$FP" "$T/mainfp/plugins/factory" 2>&1)"
  echo "info fingerprint 2.0.0 build: $(printf '%s' "$new" | tr '\n' ' ')"
  echo "info fingerprint 1.3.0 main:  $(printf '%s' "$old" | tr '\n' ' ')"
  differ ac44-standard-fingerprint-moved "$(printf '%s\n' "$old" | grep '^standard')" "$(printf '%s\n' "$new" | grep '^standard')"
  differ ac44-tooling-fingerprint-moved "$(printf '%s\n' "$old" | grep '^tooling')" "$(printf '%s\n' "$new" | grep '^tooling')"
  ck ac44-new-release-line "release: 2.0.0" "$(printf '%s\n' "$new" | grep '^release')"
  # ---------- AC-45 ----------
  git diff --name-only origin/main...HEAD | bash "$PS" check --ignore work/64/ contracts/64-*.md >"$T/offlist.txt"
  ck ac45-off-list-paths-are-only-the-earlier-roles-files "docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md
docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md
docs/requirements/64-board-as-run-state.md" "$(sed 's/^off-list: //' "$T/offlist.txt" | sort)"
  # every changed path outside work/ is accounted for; no snapshot file is committed
  ck ac45-no-snapshot-file-committed 0 "$(git ls-files | grep -ci 'snapshot-[0-9]*\.json')"
  ck ac45-no-state-dir-file-in-the-diff 0 "$(git diff --name-only origin/main...HEAD | grep -c 'factory/board-')"
  # no home path or token in any file the diff adds or changes (work/ is the lead's and roles' record; it is scanned too)
  git diff --name-only --diff-filter=AM origin/main...HEAD >"$T/changed.txt"
  : >"$T/scanlist.txt"; while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f" >>"$T/scanlist.txt"; done <"$T/changed.txt"
  : >"$T/scanhits.txt"; hits=0
  while IFS= read -r f; do
    case "$f" in reviews/security-64.md) continue ;; esac   # the security reviewer's file quotes the patterns it searched for
    bash "$SCRIPTS/post-text.sh" scan "$f" 2>/dev/null | while IFS=: read -r _ _ ln kind; do
      txt="$(sed -n "${ln}p" "$f")"
      # known false positive F-sk-prefix: the ADR file name 0014-each-role-task-is-a-sub-issue-... contains the s""k- shape
      case "$txt" in *role-task-is-a-sub-issue*) continue ;; esac
      # a line that main already carries (an old fixture of an earlier item) is not added by this diff
      git show "origin/main:$f" 2>/dev/null | grep -qxF -- "$txt" && continue
      echo "$f:$ln:$kind"
    done >>"$T/scanhits.txt"
  done <"$T/scanlist.txt"
  hits="$(wc -l <"$T/scanhits.txt" | tr -d ' ')"
  [ -s "$T/scanhits.txt" ] && sed 's/^/     hit: /' "$T/scanhits.txt" | head -20
  ck ac45-no-home-path-or-token-in-changed-files 0 "$hits"
else
  skip ac44-ac45-need-origin-main "origin/main is not available in this checkout"
fi
for s in board paths factory-config post-text; do
  ck "ac45-script-$s-parses-under-bash" 0 "$(bash -n "$SCRIPTS/$s.sh" 2>&1 >/dev/null; echo $?)"
  [ -x /bin/bash ] && ck "ac45-script-$s-parses-under-/bin/bash" 0 "$(/bin/bash -n "$SCRIPTS/$s.sh" 2>&1 >/dev/null; echo $?)"
done
ck ac45-scripts-have-a-shebang 4 "$(for s in board paths factory-config post-text; do head -1 "$SCRIPTS/$s.sh" | grep -c '^#!'; done | paste -sd+ - | bc)"
# the wayfinding plugin stays unversioned
ck ac45-wayfinding-still-unversioned 0 "$(grep -c '"version"' "$REPO/plugins/wayfinding/.claude-plugin/plugin.json" 2>/dev/null)"
ck ac45-check-bump-unchanged-by-the-build 0 "$(git diff --name-only origin/main...HEAD -- plugins/factory/scripts/check-bump.sh plugins/factory/scripts/cut-offs.sh plugins/factory/scripts/token-spend.sh plugins/factory/scripts/fingerprint.sh plugins/factory/scripts/guard-memory.sh plugins/factory/hooks | wc -l | tr -d ' ')"

# ---------- AC-46: the changelog and the pages (the docs-writer's stage runs after QA) ----------
if grep -q '^## factory 2.0.0' CHANGELOG.md; then
  E="$(awk '/^## factory 2.0.0/{f=1;print;next} /^## /{f=0} f' CHANGELOG.md)"
  chk() { printf '%s\n' "$E" | grep -qiF -- "$2" && { echo "ok   $1"; passed=$((passed + 1)); } || { echo "FAIL $1: '$2' not in the 2.0.0 entry"; fail=1; }; }
  chk ac46-major-release "major release"
  chk ac46-1x-must-run-setup "/factory:setup-factory-skill"
  chk ac46-table-and-yes "yes"
  chk ac46-undo-is-3.0.0 "3.0.0"
  chk ac46-unverified-heading "Unverified"
  for n in "limits" "live Project" "tell what to do next" "Parallel running" "Hansei numbers" "other than agent-plugins" "factory-status" "item-list" "frontier"; do chk "ac46-unverified-names-$n" "$n"; done
  chk ac46-none-exercised "none was exercised"
  chk ac46-frozen-1.3.0 "1.3.0"
  chk ac46-scratch-project "scratch Project"
  chk ac46-removed-stage-log "Stage log"
  chk ac46-removed-brief-files "NN-brief"
  chk ac46-wayfinding-unversioned "wayfinding (unversioned)"
else
  skip ac46-changelog-entry "CHANGELOG.md has no 2.0.0 entry yet: the docs-writer stage runs after QA; the checks above run when it exists"
fi
done_
