#!/usr/bin/env bash
# Dev-repo tooling, not part of the factory plugin: the repository that develops the factory asks, before a contract names a version
# or a release class, which class the intended paths need (#195). A project that only uses the factory has no such file.
# Usage: bash scripts/release-class.sh <base-ref> <path>...
# Prints `needs: <minor|patch> bump (<standard work|factory files>), <old> -> <suggested>`, or `needs: no bump (no factory paths intended)`.
# The classification is the one of check-bump.sh: both source scripts/release-lib.sh.
# Exit: 0 answered; 2 usage, not a git repository, base ref missing, or a base version that is not MAJOR.MINOR.PATCH.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$here/release-lib.sh"
[ $# -ge 2 ] || { echo "usage: release-class.sh <base-ref> <path>..." >&2; exit 2; }
base="$1"; shift
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "release-class: not a git repository" >&2; exit 2; }
cd "$top" || exit 2
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "release-class: base ref '$base' not found" >&2; exit 2; }
rel_reset
for p in "$@"; do rel_add "$p"; done
if [ "$REL_ANY" = 0 ]; then echo "needs: no bump (no factory paths intended)"; exit 0; fi
old="$(rel_version_at "$base")"
rel_is_semver "$old" || { echo "release-class: plugin.json version at $base is not MAJOR.MINOR.PATCH" >&2; exit 2; }
echo "needs: $REL_LEVEL bump ($REL_WHAT), $old -> $(rel_suggest "$old" "$REL_LEVEL")"
