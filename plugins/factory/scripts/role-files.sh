#!/bin/bash
# The one definition of a role's OWN knowledge files (protocol, *Role knowledge*), shared by andon-detect.sh and paths.sh.
# A role's own files are `docs/agents/roles/<role>.md` and everything under `docs/agents/skills/<role>/`. A commit's role is read from its subject
# `^#[0-9]+ ([a-z-]+): ` and only the seven roles count. A symlink (mode 120000) there never counts: it can point anywhere. Nothing else is excused.
# Source it for the functions; run it for `allowed`.
# Usage: bash role-files.sh allowed [--in <dir>] [--base <ref>] [--head <ref>]
#   Commits <base>..<head>, not merges (defaults: dir = the current directory, head = HEAD, base = `git merge-base origin/main <head>`).
#   Prints, one per line, each own knowledge path that changed, where every commit that touched it was made by that path's role and held it as a regular file,
#   and where it is a regular file at <head> (or gone). Another role's file, a symlink and a path any other commit touched are not printed.
# Exit: 0 done; 2 usage or no merge base.
# bash 3.2 compatible; needs git.

RF_ROLES="product-owner architect developer qa-engineer security-reviewer devops docs-writer"

# rf_role_of_subject <subject>: the role named by a commit subject, empty when none of the seven
rf_role_of_subject() {
  local r
  r="$(printf '%s' "$1" | sed -nE 's/^#[0-9]+ ([a-z-]+): .*/\1/p')"
  case " $RF_ROLES " in *" $r "*) printf '%s' "$r" ;; esac
}

# rf_own_name <role> <path>: 0 when the path is the role's own role file or inside its own skills folder (by name only)
rf_own_name() {
  case "$2" in
    "docs/agents/roles/$1.md" | "docs/agents/skills/$1/"*) return 0 ;;
  esac
  return 1
}

# rf_any_name <path>: 0 when the path is some role's knowledge file or folder entry (by name only)
rf_any_name() {
  local r
  for r in $RF_ROLES; do rf_own_name "$r" "$1" && return 0; done
  return 1
}

# rf_is_symlink <repo> <rev> <path>: 0 when the path is a symlink (mode 120000) at <rev>
rf_is_symlink() {
  [ "$(git --literal-pathspecs -C "$1" ls-tree "$2" -- "$3" 2>/dev/null | cut -c1-6)" = 120000 ]
}

# rf_own_commit_path <repo> <rev> <role> <path>: 0 when the commit's role owns the path by name and the path is no symlink at <rev>
rf_own_commit_path() {
  rf_own_name "$3" "$4" || return 1
  rf_is_symlink "$1" "$2" "$4" && return 1
  return 0
}

rf_allowed() { # <repo> <base> <head>
  local repo="$1" base="$2" head="$3" tmp
  tmp="$(mktemp)" || return 2
  git -C "$repo" log --no-merges --format='%H%x09%s' "$base".."$head" | while IFS="$(printf '\t')" read -r sha subj; do
    r="$(rf_role_of_subject "$subj")"
    git -C "$repo" diff-tree -z --no-commit-id --name-only -r --no-renames "$sha" | while IFS= read -r -d '' p; do
      rf_any_name "$p" || continue
      if [ -n "$r" ] && rf_own_commit_path "$repo" "$sha" "$r" "$p"; then echo "ok $p"; else echo "bad $p"; fi
    done
  done > "$tmp"
  # a path is allowed when it has an ok line, no bad line, and is no symlink at head
  awk '$1=="ok"{sub(/^ok /,""); ok[$0]=1} $1=="bad"{sub(/^bad /,""); bad[$0]=1} END{for(p in ok) if(!(p in bad)) print p}' "$tmp" | LC_ALL=C sort | while IFS= read -r p; do
    rf_is_symlink "$repo" "$head" "$p" || echo "$p"
  done
  rm -f "$tmp"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  [ "${1:-}" = allowed ] || { sed -n '2,/^# bash 3.2/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
  shift; repo=.; base=""; head=HEAD
  while [ $# -gt 0 ]; do
    case "$1" in
      --in) repo="${2:?}"; shift 2 ;;
      --base) base="${2:?}"; shift 2 ;;
      --head) head="${2:?}"; shift 2 ;;
      *) echo "role-files: usage: allowed [--in <dir>] [--base <ref>] [--head <ref>]" >&2; exit 2 ;;
    esac
  done
  [ -n "$base" ] || base="$(git -C "$repo" merge-base origin/main "$head")" || { echo "role-files: no merge base with origin/main" >&2; exit 2; }
  rf_allowed "$repo" "$base" "$head"
fi
