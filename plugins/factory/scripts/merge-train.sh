#!/usr/bin/env bash
# The integrator's merge train: the mechanical steps that put a finished, approved slice on main, each in its turn.
# Usage: bash merge-train.sh rebase <worktree>
#        bash merge-train.sh adr    <worktree> <id>
#        bash merge-train.sh bump   <worktree> <id>
#        bash merge-train.sh merge  <worktree> <id> --approved <time>
#        bash merge-train.sh run    <worktree> <id> --approved <time>     (rebase, adr, bump, merge, in this order)
# The lead gives the slices in the order of the dispatch plan (integrator.sh plan, the `merge` lines); each slice is run
# after the one before it has merged, so it is rebased on that result. Run in the main checkout or any worktree.
# rebase: fetches origin main and rebases the item branch on it. A clash in plugin.json (the version) or CHANGELOG.md is
#         resolved (plugin.json takes main's version, which `bump` raises again; CHANGELOG.md keeps both entries, the
#         branch's above main's); a clash anywhere else aborts the rebase and is reported.
# adr:    a new docs/adr/NNNN-*.md whose number main already uses for another file gets the next free number; its
#         references in the branch's changed files follow. Prints `adr <old> -> <new>`.
# bump:   after the rebase, `check-bump.sh` must pass; when it refuses, plugin.json is raised to the level it names and
#         the changelog entry `## factory <version> (#<id>)` follows. A missing entry, or two entries for one version,
#         is reported, never dropped.
# merge:  only with `--approved <time>` (the person's approval, from the lead). Re-runs the bump check, pushes the
#         branch, merges the PR with `gh pr merge --merge`, tags `factory-v<version>` when the version changed, then
#         removes the worktree and the branch (local and remote). The board and the tracker are the lead's: this prints
#         `done <id>` and the lead sets the card Done.
# Exit: 0 ok; 2 usage or not a git repository; 3 a rebase clash outside the shared files (rebase aborted, worktree kept);
#       4 a bump or changelog problem (reported, nothing merged); 5 the merge failed (worktree and branch kept);
#       6 merged, but the clean-up did not finish (the lead reports it).
# See contracts/113-merge-train.md in the repo that hosts the factory.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pj="plugins/factory/.claude-plugin/plugin.json"
cl="CHANGELOG.md"

usage() { echo "usage: merge-train.sh rebase <worktree> | adr|bump <worktree> <id> | merge|run <worktree> <id> --approved <time>" >&2; exit 2; }
semver_re='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

cmd="${1:-}"; w="${2:-}"; id="${3:-}"
case "$cmd" in
  rebase) [ $# -eq 2 ] || usage ;;
  adr | bump) [ $# -eq 3 ] || usage ;;
  merge | run) [ $# -eq 5 ] && [ "${4:-}" = "--approved" ] && [ -n "${5:-}" ] || usage ;;
  *) usage ;;
esac
[ -d "$w" ] || { echo "merge-train: no worktree at '$w'" >&2; exit 2; }
w="$(cd "$w" && pwd)"
git -C "$w" rev-parse --show-toplevel >/dev/null 2>&1 || { echo "merge-train: not a git repository: $w" >&2; exit 2; }
if [ "$cmd" != rebase ]; then
  case "$id" in '' | *[!0-9]*) echo "merge-train: the id must be a number" >&2; exit 2 ;; esac
fi
base="origin/main"
branch="$(git -C "$w" rev-parse --abbrev-ref HEAD)"
[ "$(git -C "$w" rev-parse --git-dir)" != "$(git -C "$w" rev-parse --git-common-dir)" ] || { echo "merge-train: '$w' is the main checkout, not an item worktree" >&2; exit 2; }
if [ "$cmd" != rebase ] && [ "$branch" != "item/$id" ]; then echo "merge-train: '$w' is on branch '$branch', not item/$id" >&2; exit 2; fi

version_in() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1; }

do_rebase() {
  git -C "$w" fetch -q origin main || { echo "rebase: cannot fetch origin main" >&2; exit 3; }
  if git -C "$w" rebase "$base" >/dev/null 2>&1; then echo "rebase ok: $branch on $base"; return 0; fi
  n=0
  if [ ! -d "$(git -C "$w" rev-parse --git-path rebase-merge)" ] && [ ! -d "$(git -C "$w" rev-parse --git-path rebase-apply)" ]; then
    echo "rebase failed (not a clash): $(git -C "$w" rebase "$base" 2>&1 | tr '\n' ' ') -- worktree kept: $w"
    exit 3
  fi
  while [ -d "$(git -C "$w" rev-parse --git-path rebase-merge)" ] || [ -d "$(git -C "$w" rev-parse --git-path rebase-apply)" ]; do
    n=$((n + 1))
    [ "$n" -le 100 ] || { git -C "$w" rebase --abort >/dev/null 2>&1; echo "conflict: the rebase did not finish after 100 steps" >&2; exit 3; }
    files="$(cd "$w" && git -c core.quotePath=false diff --no-renames --name-only --diff-filter=U)"
    other=""
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in
        "$pj")
          # a clash in more than the version line is reported, not resolved
          if git -C "$w" diff REBASE_HEAD~ REBASE_HEAD -- "$pj" | grep '^[+-][^+-]' | grep -qv '"version"'; then other="$other $f"; continue; fi
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
            {print}' "$w/$f" >"$w/$f.merge-train" && mv "$w/$f.merge-train" "$w/$f" && git -C "$w" add -- "$f"
          echo "resolved $f: kept both entries, the branch's above $base's" ;;
        *) other="$other $f" ;;
      esac
    done <<EOF
$files
EOF
    if [ -n "$other" ]; then
      git -C "$w" rebase --abort >/dev/null 2>&1
      echo "conflict in:$other -- rebase aborted, worktree kept: $w"
      exit 3
    fi
    if ! GIT_EDITOR=true git -C "$w" -c commit.cleanup=whitespace rebase --continue >/dev/null 2>&1; then
      # a resolution that leaves the commit empty is skipped
      if [ -z "$(cd "$w" && git -c core.quotePath=false diff --no-renames --name-only --diff-filter=U)" ]; then GIT_EDITOR=true git -C "$w" rebase --skip >/dev/null 2>&1 || true; fi
    fi
  done
  echo "rebase ok: $branch on $base"
}

do_adr() {
  added="$(cd "$w" && git -c core.quotePath=false diff --no-renames --name-only --diff-filter=A "$base...HEAD" -- docs/adr/ | grep -E '^docs/adr/[0-9]{4}-[^/]+\.md$')"
  [ -n "$added" ] || { echo "adr ok: no new ADR"; return 0; }
  main_list="$(git -C "$w" ls-tree "$base" docs/adr/ | cut -f2 | sed 's|^docs/adr/||')"
  max=0
  for f in $(printf '%s\n' "$main_list"; printf '%s\n' "$added" | sed 's|^docs/adr/||'); do
    num="${f%%-*}"; case "$num" in [0-9][0-9][0-9][0-9]) [ "$((10#$num))" -gt "$max" ] && max="$((10#$num))" ;; esac
  done
  changed=0
  for f in $added; do
    b="${f#docs/adr/}"; num="${b%%-*}"
    if printf '%s\n' "$main_list" | grep -q "^$num-"; then
      max=$((max + 1)); new="$(printf '%04d' "$max")"; nb="$new-${b#*-}"
      git -C "$w" mv "docs/adr/$b" "docs/adr/$nb" || { echo "adr: cannot rename $b" >&2; exit 4; }
      for t in $(cd "$w" && git -c core.quotePath=false diff --no-renames --name-only --diff-filter=AM "$base...HEAD"; git -c core.quotePath=false diff --no-renames --name-only --cached); do
        [ -f "$w/$t" ] || continue
        sed -e "s|${b%.md}|${nb%.md}|g" "$w/$t" >"$w/$t.merge-train" && mv "$w/$t.merge-train" "$w/$t"
        git -C "$w" add -- "$t"
      done
      sed -E "s/ADR $num([^0-9]|\$)/ADR $new\1/g" "$w/docs/adr/$nb" >"$w/docs/adr/$nb.merge-train" && mv "$w/docs/adr/$nb.merge-train" "$w/docs/adr/$nb" && git -C "$w" add -- "docs/adr/$nb"
      echo "adr $num -> $new docs/adr/$nb"
      changed=1
    fi
  done
  if [ "$changed" = 1 ]; then git -C "$w" commit -q -m "#$id factory: ADR number assigned after the rebase" || exit 4; else echo "adr ok: no number in use on main"; fi
}

do_bump() {
  # check-bump runs in the repository of the current directory
  out="$(cd "$w" && bash "$here/check-bump.sh" "$base" 2>&1)"; rc=$?
  case "$rc" in
    0) echo "bump ok: $out" ;;
    1)
      suggested="$(printf '%s\n' "$out" | sed -n '1s/.*(\([0-9.]*\))$/\1/p')"
      old="$(version_in <"$w/$pj")"
      printf '%s' "$suggested" | grep -Eq "$semver_re" || { echo "bump: cannot read the level from: $out"; exit 4; }
      sed "s/\"version\"\([[:space:]]*\):\([[:space:]]*\)\"[^\"]*\"/\"version\"\1:\2\"$suggested\"/" "$w/$pj" >"$w/$pj.merge-train" && mv "$w/$pj.merge-train" "$w/$pj"
      git -C "$w" add -- "$pj"
      echo "bump: $old -> $suggested ($(printf '%s\n' "$out" | sed -n '1s/^refuse: //p'))"
      hits="$(cd "$w" && git grep -lF -- "\"$old\"" -- tests 2>/dev/null | tr '\n' ' ')"
      [ -z "$hits" ] || echo "note: $hits name the version $old; the developer moves such pins and the changelog fingerprints"
      do_changelog "$suggested"
      git -C "$w" commit -q -m "#$id factory: version bump after the rebase ($suggested)" || exit 4
      ( cd "$w" && bash "$here/check-bump.sh" "$base" >/dev/null 2>&1 ) || { echo "bump: the check still refuses after the bump"; exit 4; }
      ;;
    *) echo "bump: check-bump failed: $out"; exit 4 ;;
  esac
  do_changelog_check
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
    {print}' "$w/$cl" >"$w/$cl.merge-train" && mv "$w/$cl.merge-train" "$w/$cl"
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

do_merge() {
  ( cd "$w" && bash "$here/check-bump.sh" "$base" >/dev/null 2>&1 ) || { echo "merge refused: the bump check does not pass; nothing merged"; exit 4; }
  main="$(git -C "$w" worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
  cd "$main" || exit 2
  old="$(git -C "$w" show "$base:$pj" 2>/dev/null | version_in)"
  new="$(version_in <"$w/$pj")"
  if ! perr="$(git -C "$w" push -q --force-with-lease origin "$branch" 2>&1)"; then
    echo "merge failed: cannot push $branch: $(printf '%s' "$perr" | tr '\n' ' ') -- worktree kept: $w"; exit 5
  fi
  if ! gh pr merge "$branch" --merge >/dev/null 2>&1; then
    echo "merge failed: gh pr merge $branch was refused -- worktree and branch kept: $w"; exit 5
  fi
  echo "merged $id: PR of $branch (approved $approved)"
  fail=0
  if [ -n "$new" ] && [ "$new" != "$old" ]; then
    if printf '%s' "$new" | grep -Eq "$semver_re"; then
      if [ -n "$(git -C "$main" ls-remote --tags origin "factory-v$new")" ]; then
        echo "tag factory-v$new exists already; skipped"
      else
        git -C "$main" fetch -q origin main
        sha="$(gh pr view "$branch" --json mergeCommit --jq .mergeCommit.oid 2>/dev/null)"
        if [ -n "$sha" ] && git -C "$main" tag "factory-v$new" "$sha" && git -C "$main" push -q origin "factory-v$new"; then
          echo "tag factory-v$new"
        else echo "tag factory-v$new failed; the lead reports it"; fail=1; fi
      fi
    else echo "version '$new' is not MAJOR.MINOR.PATCH; no tag; tell the person"; fi
  fi
  clean=1
  git -C "$main" worktree remove "$w" || clean=0
  git -C "$main" branch -D "$branch" >/dev/null 2>&1 || clean=0
  if [ -n "$(git -C "$main" ls-remote --heads origin "$branch")" ]; then git -C "$main" push -q origin --delete "$branch" 2>/dev/null || clean=0; fi
  if [ "$clean" = 1 ]; then echo "cleaned $id: worktree and branch $branch removed"
  else echo "clean-up of $id did not finish: worktree $w or branch $branch is left; the lead reports it"; fail=1; fi
  echo "done $id -- the lead sets the card Done"
  [ "$fail" = 0 ] || exit 6
}

approved="${5:-}"
case "$cmd" in
  rebase) do_rebase ;;
  adr) do_adr ;;
  bump) do_bump ;;
  merge) do_merge ;;
  run) do_rebase; do_adr; do_bump; do_merge ;;
esac
