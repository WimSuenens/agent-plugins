#!/usr/bin/env bash
# The integrator's merge train: the mechanical steps that put a finished, approved slice on main, each in its turn.
# Usage: bash merge-train.sh rebase  <worktree>
#        bash merge-train.sh adr     <worktree> <id>
#        bash merge-train.sh release <worktree> <id>
#        bash merge-train.sh merge   <worktree> <id> --approved <time>
#        bash merge-train.sh run     <worktree> <id> --approved <time>     (rebase, adr, release, merge, in this order)
# The lead gives the slices in the order of the dispatch plan (integrator.sh plan, the `merge` lines); each slice is run
# after the one before it has merged, so it is rebased on that result. Run in the main checkout or any worktree.
# rebase:  fetches origin main and rebases the item branch on it. A clash in a file the project's release hook resolves
#          (release-hook.sh, phase `resolve`) is resolved by it; a clash anywhere else aborts the rebase and is reported.
# adr:     a new docs/adr/NNNN-*.md whose number main already uses for another file gets the next free number; its
#          references in the branch's changed files follow. Prints `adr <old> -> <new>`.
# release: runs the project's release hook, phase `prepare`, when docs/agents/factory.md declares one (`release-hook:`).
#          No declaration: nothing is run and nothing is printed.
# merge:   only with `--approved <time>` (the person's approval, from the lead). Runs the hook's phase `check` (a refusal
#          merges nothing), pushes the branch, merges the PR with `gh pr merge --merge`, runs the hook's phase `tag`, then
#          removes the worktree and the branch (local and remote). The board and the tracker are the lead's: this prints
#          `done <id>` and the lead sets the card Done.
# Exit: 0 ok; 2 usage or not a git repository; 3 a rebase clash the hook did not resolve (rebase aborted, worktree kept);
#       4 a release-hook problem (reported, nothing merged); 5 the merge failed (worktree and branch kept);
#       6 merged, but the hook's `tag` or the clean-up did not finish (the lead reports it).
# See contracts/113-merge-train.md in the repo that hosts the factory.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$here/release-hook.sh"

usage() { echo "usage: merge-train.sh rebase <worktree> | adr|release <worktree> <id> | merge|run <worktree> <id> --approved <time>" >&2; exit 2; }

cmd="${1:-}"; w="${2:-}"; id="${3:-}"
case "$cmd" in
  rebase) [ $# -eq 2 ] || usage ;;
  adr | release) [ $# -eq 3 ] || usage ;;
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
      bash "$hook" resolve "$w" "${id:--}" "$base" "$f" || other="$other $f"
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

do_release() {
  bash "$hook" prepare "$w" "$id" "$base"; rc=$?
  [ "$rc" = 0 ] || { [ "$rc" = 4 ] || echo "release: the release hook stopped with exit $rc"; exit 4; }
}

do_merge() {
  if ! chk="$(bash "$hook" check "$w" "$id" "$base" 2>&1)"; then
    echo "merge refused: the release hook does not pass; nothing merged"; printf '%s\n' "$chk"; exit 4
  fi
  main="$(git -C "$w" worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
  cd "$main" || exit 2
  if ! perr="$(git -C "$w" push -q --force-with-lease origin "$branch" 2>&1)"; then
    echo "merge failed: cannot push $branch: $(printf '%s' "$perr" | tr '\n' ' ') -- worktree kept: $w"; exit 5
  fi
  if ! gh pr merge "$branch" --merge >/dev/null 2>&1; then
    echo "merge failed: gh pr merge $branch was refused -- worktree and branch kept: $w"; exit 5
  fi
  echo "merged $id: PR of $branch (approved $approved)"
  fail=0
  bash "$hook" tag "$w" "$id" "$base" "$branch" || fail=1
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
  release) do_release ;;
  merge) do_merge ;;
  run) do_rebase; do_adr; do_release; do_merge ;;
esac
