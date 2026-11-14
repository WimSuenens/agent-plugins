#!/usr/bin/env bash
# Dev-repo tooling, not part of the factory plugin: the repository that develops the factory asks, before a contract names a version
# or a release class, which class the intended paths need (#195). A project that only uses the factory has no such file.
# Usage: bash scripts/release-class.sh <base-ref> <path>...
# Prints `needs: <minor|patch> bump (<standard work|factory files>), <old> -> <suggested>`, or `needs: no bump (no factory paths intended)`.
# The classification is the one of plugins/factory/scripts/check-bump.sh (standard text and the run skill: minor; otherwise patch); the
# test tests/factory/test_release_class.sh holds the two together until the release tooling is moved out of the plugin.
# Exit: 0 answered; 2 usage, not a git repository, base ref missing, or a base version that is not MAJOR.MINOR.PATCH.
pj="plugins/factory/.claude-plugin/plugin.json"
[ $# -ge 2 ] || { echo "usage: release-class.sh <base-ref> <path>..." >&2; exit 2; }
base="$1"; shift
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "release-class: not a git repository" >&2; exit 2; }
cd "$top" || exit 2
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "release-class: base ref '$base' not found" >&2; exit 2; }
level=patch; what="factory files"; any=0
for p in "$@"; do
  case "$p" in
    plugins/factory/*) any=1 ;;
    *) continue ;;
  esac
  case "$p" in
    plugins/factory/skills/run/SKILL.md) level=minor ;;
    plugins/factory/references/*/* | plugins/factory/agents/*/*) ;;
    plugins/factory/references/*.md | plugins/factory/agents/*.md) level=minor ;;
    plugins/factory/references | plugins/factory/references/ | plugins/factory/agents | plugins/factory/agents/) level=minor ;;
  esac
done
if [ "$any" = 0 ]; then echo "needs: no bump (no factory paths intended)"; exit 0; fi
[ "$level" = minor ] && what="standard work"
old="$(git show "$base:$pj" 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
printf '%s' "$old" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || { echo "release-class: plugin.json version at $base is not MAJOR.MINOR.PATCH" >&2; exit 2; }
major="${old%%.*}"; rest="${old#*.}"; minor="${rest%%.*}"; patch="${rest#*.}"
if [ "$level" = minor ]; then sug="$major.$((minor + 1)).0"; else sug="$major.$minor.$((patch + 1))"; fi
echo "needs: $level bump ($what), $old -> $sug"
