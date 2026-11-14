#!/usr/bin/env bash
# Refuses a factory change that comes without the version bump it needs.
# Usage: bash check-bump.sh [<base-ref>]     (default base: origin/main; run in the item worktree)
#        bash check-bump.sh --intended <base-ref> <path>...     (the dry-run, before any commit: the release class the intended paths need)
# --intended prints `needs: <level> bump (<standard work|factory files>), <old> -> <suggested>` (or `needs: no bump (no factory paths intended)`)
#   with the same classification as the check; the architect quotes the line in the contract before it names a version or a release class.
# Exit: 0 pass (--intended: answered); 1 refuse; 2 not a git repo, base ref missing, base version not a semver, or --intended without paths (reason on stderr).
# See contracts/39-plugin-scripts.md section 2 in the repo that hosts the factory.

intended=0
if [ "${1:-}" = "--intended" ]; then
  intended=1; shift
  [ $# -ge 2 ] || { echo "usage: check-bump.sh --intended <base-ref> <path>..." >&2; exit 2; }
fi
base="${1:-origin/main}"
pj="plugins/factory/.claude-plugin/plugin.json"

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "check-bump: not a git repository" >&2; exit 2; }
cd "$top" || exit 2
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "check-bump: base ref '$base' not found" >&2; exit 2; }
tmp="$(mktemp)" || exit 2
trap 'rm -f "$tmp"' EXIT
if [ "$intended" = 1 ]; then
  shift
  for p in "$@"; do case "$p" in plugins/factory/*) printf '%s\0' "$p" ;; esac; done >"$tmp"
  if [ ! -s "$tmp" ]; then
    echo "needs: no bump (no factory paths intended)"
    exit 0
  fi
else
  git diff -z --no-renames --name-only "$base...HEAD" -- plugins/factory/ >"$tmp" 2>/dev/null || { echo "check-bump: cannot diff $base...HEAD" >&2; exit 2; }
  if [ ! -s "$tmp" ]; then
    echo "pass: no factory paths changed"
    exit 0
  fi
fi

# Needed level: minor for standard work, else patch.
level=patch
what="factory files"
while IFS= read -r -d '' p; do
  case "$p" in
    *$'\n'*) level=minor ;;   # a name holding a newline cannot be classified: standard work
    plugins/factory/skills/run/SKILL.md) level=minor ;;
    plugins/factory/references/*/* | plugins/factory/agents/*/*) ;;
    plugins/factory/references/*.md | plugins/factory/agents/*.md) level=minor ;;
    plugins/factory/references | plugins/factory/references/ | plugins/factory/agents | plugins/factory/agents/) level=minor ;;   # a directory named by --intended
  esac
done <"$tmp"
[ "$level" = minor ] && what="standard work"

# plugin.json version at a revision: prints the version, or nothing when absent.
version_at() {
  git show "$1:$pj" 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1
}
is_semver() { printf '%s' "$1" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; }

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
if [ "$level" = minor ]; then suggested="$o_major.$((o_minor + 1)).0"; else suggested="$o_major.$o_minor.$((o_patch + 1))"; fi

if [ "$intended" = 1 ]; then
  echo "needs: $level bump ($what), $old -> $suggested"
  exit 0
fi

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
