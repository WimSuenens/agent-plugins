#!/usr/bin/env bash
# Dev-repo tooling, not part of the factory plugin (moved here by #210): refuses a factory change that comes without the version bump it needs.
# Usage: bash scripts/check-bump.sh [<base-ref>]     (default base: origin/main; run in the item worktree)
# Exit: 0 pass; 1 refuse; 2 not a git repo, base ref missing, or base version not a semver (reason on stderr).
# See contracts/39-plugin-scripts.md section 2 in the repo that hosts the factory.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$here/release-lib.sh"
base="${1:-origin/main}"
pj="$rel_pj"

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "check-bump: not a git repository" >&2; exit 2; }
cd "$top" || exit 2
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "check-bump: base ref '$base' not found" >&2; exit 2; }
tmp="$(mktemp)" || exit 2
trap 'rm -f "$tmp"' EXIT
git diff -z --no-renames --name-only "$base...HEAD" -- plugins/factory/ >"$tmp" 2>/dev/null || { echo "check-bump: cannot diff $base...HEAD" >&2; exit 2; }

if [ ! -s "$tmp" ]; then
  echo "pass: no factory paths changed"
  exit 0
fi

# Needed level: minor for standard work, else patch (release-lib.sh).
rel_reset
while IFS= read -r -d '' p; do rel_add "$p"; done <"$tmp"
level="$REL_LEVEL"; what="$REL_WHAT"

version_at() { rel_version_at "$1"; }
is_semver() { rel_is_semver "$1"; }

old="$(version_at "$base")"
if [ -z "$old" ] && git show "$base:$pj" 2>/dev/null | grep -Eq '"version"[[:space:]]*:'; then
  echo "check-bump: plugin.json version at $base is empty, not MAJOR.MINOR.PATCH" >&2
  exit 2
fi
if [ -n "$old" ] && ! is_semver "$old"; then
  echo "check-bump: plugin.json version '$old' at $base is not MAJOR.MINOR.PATCH" >&2
  exit 2
fi
[ -n "$old" ] || old="0.0.0"
new="$(version_at HEAD)"

o_major="${old%%.*}"; rest="${old#*.}"; o_minor="${rest%%.*}"; o_patch="${rest#*.}"
suggested="$(rel_suggest "$old" "$level")"

ok=0
if is_semver "$new"; then
  n_major="${new%%.*}"; rest="${new#*.}"; n_minor="${rest%%.*}"; n_patch="${rest#*.}"
  if [ "$level" = minor ]; then
    if [ "$n_major" -gt "$o_major" ] || { [ "$n_major" -eq "$o_major" ] && [ "$n_minor" -gt "$o_minor" ]; }; then ok=1; fi
  else
    if [ "$n_major" -gt "$o_major" ] \
      || { [ "$n_major" -eq "$o_major" ] && [ "$n_minor" -gt "$o_minor" ]; } \
      || { [ "$n_major" -eq "$o_major" ] && [ "$n_minor" -eq "$o_minor" ] && [ "$n_patch" -gt "$o_patch" ]; }; then ok=1; fi
  fi
else
  [ -n "$new" ] || new="(absent)"
fi

if [ "$ok" = 1 ]; then
  echo "pass: $level bump needed, $old -> $new"
  exit 0
fi

echo "refuse: $what changed; plugin.json version $old -> $new; needs at least a $level bump ($suggested)"
# plugin.json is the thing being compared; list it only when it is the sole change.
changed="$(tr '\0' '\n' <"$tmp")"   # display only
others="$(printf '%s\n' "$changed" | grep -vxF "$pj")"
printf '%s\n' "${others:-$changed}" | sed 's/^/  /'
exit 1
