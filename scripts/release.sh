#!/usr/bin/env bash
# Dev-repo tooling, not part of the factory plugin (moved here by #210): the release hook of the repository that develops the factory.
# docs/agents/factory.md declares it with `release-hook: scripts/release.sh`; the plugin's merge train calls it through
# plugins/factory/scripts/release-hook.sh and knows nothing else about releases.
# Usage: bash scripts/release.sh <phase> <worktree> <id> <base> [<extra>]     (base is origin/main)
#   check    the bump check (check-bump.sh) in the worktree: its line and exit code (0 pass, 1 refuse, 2 unusable). The id is not used
#            (a frontier or settle branch passes `-`).
#   resolve  <file>: a clash in the manifest or the changelog during the rebase. Exit 0 resolved and staged (the line says how),
#            1 not a file of this hook (the merge train reports the clash).
#   prepare  after the rebase: `check` must pass; when it refuses, the manifest version is raised to the level it names and the
#            changelog entry `## factory <version> (#<id>)` follows. A missing entry, or two entries for one version, is reported,
#            never dropped. Exit 0, or 4 a bump or changelog problem.
#   tag      <branch>: after the merge, tags `factory-v<version>` on the merge commit when the version changed and pushes the tag.
#            Exit 0, or 1 when the tag failed (the lead reports it).
# See contracts/113-merge-train.md in this repository.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$here/release-lib.sh"
phase="${1:-}"; w="${2:-}"; id="${3:-}"; base="${4:-}"; extra="${5:-}"
[ -n "$phase" ] && [ -d "$w" ] && [ -n "$base" ] || { echo "usage: release.sh <check|resolve|prepare|tag> <worktree> <id> <base> [<extra>]" >&2; exit 2; }
pj="$rel_pj"
cl="CHANGELOG.md"
semver_re='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
version_in() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1; }

do_check() { ( cd "$w" && bash "$here/check-bump.sh" "$base" ); }

do_resolve() {
  f="$extra"
  case "$f" in
    "$pj")
      # a clash in more than the version line is reported, not resolved
      if git -C "$w" diff REBASE_HEAD~ REBASE_HEAD -- "$pj" | grep '^[+-][^+-]' | grep -qv '"version"'; then return 1; fi
      git -C "$w" checkout --ours -- "$f" && git -C "$w" add -- "$f"
      echo "resolved $f: took the version of $base; bump raises it again" ;;
    "$cl")
      awk '
        /^<<<<<<< /{s=1; next}
        /^\|\|\|\|\|\|\| / && s==1 {s=3; next}
        /^=======$/ && (s==1 || s==3) {s=2; next}
        s==3 {next}
        /^>>>>>>> / && s==2 {printf "%s%s", theirs, ours; ours=""; theirs=""; s=0; next}
        s==1 {ours = ours $0 "\n"; next}
        s==2 {theirs = theirs $0 "\n"; next}
        {print}' "$w/$f" >"$w/$f.release" && mv "$w/$f.release" "$w/$f" && git -C "$w" add -- "$f"
      echo "resolved $f: kept both entries, the branch's above $base's" ;;
    *) return 1 ;;
  esac
}

# do_changelog <new>: the entry of this item (found by its id) takes the version <new>
do_changelog() {
  heading="$(grep -E "^## factory [^ ]+ \(#$id\)\$" "$w/$cl" 2>/dev/null | head -n1)"
  if [ -z "$heading" ]; then
    echo "changelog: no entry '## factory <version> (#$id)' in $cl; the docs-writer adds it before the merge"
    exit 4
  fi
  old="$(printf '%s' "$heading" | sed 's/^## factory \([^ ]*\) .*/\1/')"
  awk -v old="$old" -v new="$1" -v id="$id" '
    $0 == "## factory " old " (#" id ")" {print "## factory " new " (#" id ")"; inside=1; next}
    /^## / {inside=0}
    inside && index($0, "Release: `" old "`") == 1 {sub("`" old "`", "`" new "`")}
    {print}' "$w/$cl" >"$w/$cl.release" && mv "$w/$cl.release" "$w/$cl"
  git -C "$w" add -- "$cl"
  echo "changelog: entry for #$id moved from $old to $1"
}

# do_changelog_check: a factory change needs one entry for this item, and no two entries for one version
do_changelog_check() {
  [ -n "$(cd "$w" && git -c core.quotePath=false diff --no-renames --name-only "$base...HEAD" -- plugins/factory/)" ] || return 0
  ver="$(version_in <"$w/$pj")"
  grep -q "^## factory $ver (#$id)\$" "$w/$cl" 2>/dev/null || { echo "changelog: no entry '## factory $ver (#$id)' in $cl; the docs-writer adds it before the merge"; exit 4; }
  [ "$(grep -c "^## factory $ver " "$w/$cl")" -le 1 ] || { echo "changelog: two entries for factory $ver; one slice must take another version"; exit 4; }
}

do_prepare() {
  out="$(do_check 2>&1)"; rc=$?
  case "$rc" in
    0) echo "bump ok: $out" ;;
    1)
      suggested="$(printf '%s\n' "$out" | sed -n '1s/.*(\([0-9.]*\))$/\1/p')"
      old="$(version_in <"$w/$pj")"
      printf '%s' "$suggested" | grep -Eq "$semver_re" || { echo "bump: cannot read the level from: $out"; exit 4; }
      sed "s/\"version\"\([[:space:]]*\):\([[:space:]]*\)\"[^\"]*\"/\"version\"\1:\2\"$suggested\"/" "$w/$pj" >"$w/$pj.release" && mv "$w/$pj.release" "$w/$pj"
      git -C "$w" add -- "$pj"
      echo "bump: $old -> $suggested ($(printf '%s\n' "$out" | sed -n '1s/^refuse: //p'))"
      hits="$(cd "$w" && git grep -lF -- "\"$old\"" -- tests 2>/dev/null | tr '\n' ' ')"
      [ -z "$hits" ] || echo "note: $hits name the version $old; the developer moves such pins and the changelog fingerprints"
      do_changelog "$suggested"
      git -C "$w" commit -q -m "#$id factory: version bump after the rebase ($suggested)" || exit 4
      do_check >/dev/null 2>&1 || { echo "bump: the check still refuses after the bump"; exit 4; }
      ;;
    *) echo "bump: check-bump failed: $out"; exit 4 ;;
  esac
  do_changelog_check
}

do_tag() {
  branch="$extra"
  main="$(git -C "$w" worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
  old="$(git -C "$w" show "$base:$pj" 2>/dev/null | version_in)"
  new="$(version_in <"$w/$pj")"
  [ -n "$new" ] && [ "$new" != "$old" ] || return 0
  printf '%s' "$new" | grep -Eq "$semver_re" || { echo "version '$new' is not MAJOR.MINOR.PATCH; no tag; tell the person"; return 0; }
  if [ -n "$(git -C "$main" ls-remote --tags origin "factory-v$new")" ]; then
    echo "tag factory-v$new exists already; skipped"
    return 0
  fi
  git -C "$main" fetch -q origin main
  sha="$(gh pr view "$branch" --json mergeCommit --jq .mergeCommit.oid 2>/dev/null)"
  if [ -n "$sha" ] && git -C "$main" tag "factory-v$new" "$sha" && git -C "$main" push -q origin "factory-v$new"; then
    echo "tag factory-v$new"
  else
    # a local tag whose push failed would make the retry stop at "already exists"
    [ -n "$(git -C "$main" ls-remote --tags origin "factory-v$new")" ] || git -C "$main" tag -d "factory-v$new" >/dev/null 2>&1
    echo "tag factory-v$new failed; the lead reports it"; return 1
  fi
}

case "$phase" in
  check) do_check ;;
  resolve) do_resolve ;;
  prepare) do_prepare ;;
  tag) do_tag ;;
  *) echo "release.sh: unknown phase '$phase'" >&2; exit 2 ;;
esac
