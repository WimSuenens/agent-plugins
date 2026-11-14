#!/usr/bin/env bash
# Dev-repo tooling, not part of the factory plugin: the repository that develops the factory asks, before a contract names a version
# or a release class, which class the intended paths need (#195). A project that only uses the factory has no such file.
# Usage: bash scripts/release-class.sh <base-ref> [--declared '<class> (<reason>)'] <path>...
# Prints `needs: <major|minor|patch> bump (<standard work|factory files|declared: <reason>>), <old> -> <suggested>`, or `needs: no bump (no factory paths intended)`.
# The classification is the one of check-bump.sh: both source scripts/release-lib.sh.
# --declared takes the declaration a slice will write in its changelog entry (`Release: major (<reason>)`) before that entry exists. It can
#   only raise the class; a major needs its reason in brackets. Without it the answer is the computed class, as before.
# Exit: 0 answered; 1 the declaration is below the computed class; 2 usage (also a major without a reason, or an unknown class), not a git
#   repository, base ref missing, or a base version that is not MAJOR.MINOR.PATCH.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$here/release-lib.sh"
usage() { echo "usage: release-class.sh <base-ref> [--declared '<class> (<reason>)'] <path>..." >&2; exit 2; }
[ $# -ge 2 ] || usage
base="$1"; shift
declared=""; paths=()
while [ $# -gt 0 ]; do
  case "$1" in
    --declared) [ $# -ge 2 ] || usage; declared="$2"; shift 2 ;;
    *) paths+=("$1"); shift ;;
  esac
done
[ ${#paths[@]} -ge 1 ] || usage
REL_DECL=""; REL_DECL_WHY=""; REL_DECL_BAD=""
if [ -n "$declared" ]; then
  rel_parse_decl "$declared"
  [ -n "$REL_DECL" ] || { echo "release-class: --declared takes major, minor or patch, for example 'major (<reason>)'" >&2; exit 2; }
  [ -z "$REL_DECL_BAD" ] || { echo "release-class: Release: major needs a reason in brackets, for example 'major (<reason>)'" >&2; exit 2; }
fi
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "release-class: not a git repository" >&2; exit 2; }
cd "$top" || exit 2
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "release-class: base ref '$base' not found" >&2; exit 2; }
rel_reset
for p in "${paths[@]}"; do rel_add "$p"; done
if [ "$REL_ANY" = 0 ]; then echo "needs: no bump (no factory paths intended)"; exit 0; fi
old="$(rel_version_at "$base")"
rel_is_semver "$old" || { echo "release-class: plugin.json version at $base is not MAJOR.MINOR.PATCH" >&2; exit 2; }
computed="$REL_LEVEL"
rel_apply_declared
if [ "$REL_LOWER" = 1 ]; then
  echo "refuse: declared $REL_DECL but $REL_WHAT needs at least a $computed bump ($(rel_suggest "$old" "$computed"))"
  exit 1
fi
echo "needs: $REL_LEVEL bump ($REL_WHAT), $old -> $(rel_suggest "$old" "$REL_LEVEL")"
