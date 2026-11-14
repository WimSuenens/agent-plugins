#!/usr/bin/env bash
# Where the factory's worktrees live: the project's own agent folder, .claude/worktrees, inside the main checkout.
# Usage: bash worktree.sh dir
#        bash worktree.sh add item <id> | frontier <map> | settle <map>
#        bash worktree.sh ignore
#        bash worktree.sh legacy
# dir: prints the folder, relative to the main checkout.
# add: fetches origin/main, creates the worktree in the folder on its branch (item/<id>, frontier/<map>, settle/<map>) from
#      origin/main, and prints its absolute path. The folder is .claude/worktrees/<id>, .../frontier-<map>, .../settle-<map>.
#      When the local main differs from origin/main (ahead, behind or both), one line on stderr names the difference; the local
#      main and its local-only commits are never touched and never enter the new branch.
# ignore: adds /.claude/worktrees/ to the main checkout's .gitignore; prints "added" or "already present" and changes
#      nothing the second time. A line that already ignores the folder (with or without the leading slash or the
#      trailing slash) counts as present.
# legacy: lists worktrees at the old location, ../wt/<name> beside the main checkout, one "<path><TAB><branch>" per line.
# Every command works from the main checkout or from any worktree of it.
# Exit: 0 ok (legacy: none found); 2 usage, a bad id, or not a git repository; 3 add: the folder is not ignored (run ignore
#       first); 4 add: git refused the worktree (message on stderr);
#       5 add: the fetch of origin/main failed (one line on stderr; nothing was created); 10 legacy: at least one found.
# See contracts/109-worktree-folder.md in the repo that hosts the factory.

folder=".claude/worktrees"
cmd="${1:-}"

main_checkout() {
  git worktree list --porcelain 2>/dev/null | while IFS= read -r l; do
    case "$l" in "worktree "*) printf '%s\n' "${l#worktree }"; break ;; esac
  done
}

main="$(main_checkout)"
[ -n "$main" ] || { echo "worktree: not a git repository" >&2; exit 2; }

case "$cmd" in
  dir)
    echo "$folder"
    ;;
  add)
    kind="${2:-}"; n="${3:-}"
    case "$kind" in
      item) name="$n"; branch="item/$n" ;;
      frontier) name="frontier-$n"; branch="frontier/$n" ;;
      settle) name="settle-$n"; branch="settle/$n" ;;
      *) echo "usage: worktree.sh add item|frontier|settle <number>" >&2; exit 2 ;;
    esac
    case "$n" in '' | *[!0-9]*) echo "worktree: the id must be a number" >&2; exit 2 ;; esac
    if ! git -C "$main" check-ignore -q -- "$folder/$name"; then
      echo "worktree: $folder is not ignored in $main: run 'worktree.sh ignore' (setup-factory-skill does it)" >&2
      exit 3
    fi
    if ! git -C "$main" fetch -q origin main >/dev/null 2>&1; then
      echo "worktree: cannot fetch origin/main: no worktree was created; tell the person instead of building on a stale base" >&2
      exit 5
    fi
    if git -C "$main" rev-parse --verify -q refs/heads/main >/dev/null; then
      counts="$(git -C "$main" rev-list --left-right --count main...origin/main 2>/dev/null)"
      ahead="${counts%%[[:space:]]*}"; behind="${counts##*[[:space:]]}"
      if [ -n "$counts" ] && { [ "$ahead" != 0 ] || [ "$behind" != 0 ]; }; then
        echo "worktree: local main differs from origin/main (ahead $ahead, behind $behind); the branch starts from origin/main" >&2
      fi
    fi
    mkdir -p "$main/$folder" || exit 4
    if ! git -C "$main" worktree add -q "$main/$folder/$name" -b "$branch" origin/main >&2; then exit 4; fi
    echo "$main/$folder/$name"
    ;;
  ignore)
    gi="$main/.gitignore"
    if [ -f "$gi" ] && grep -Eqx '/?\.claude/worktrees/?' "$gi"; then
      echo "already present"
      exit 0
    fi
    if [ -s "$gi" ] && [ -n "$(tail -c 1 "$gi")" ]; then printf '\n' >>"$gi"; fi
    printf '/%s/\n' "$folder" >>"$gi"
    echo "added"
    ;;
  legacy)
    old="$(dirname "$main")/wt"
    found=0; path=""
    while IFS= read -r l; do
      case "$l" in
        "worktree "*) path="${l#worktree }" ;;
        "branch "*)
          case "$path" in
            "$old"/*) printf '%s\t%s\n' "$path" "${l#branch refs/heads/}"; found=1 ;;
          esac
          ;;
        "") path="" ;;
      esac
    done < <(git -C "$main" worktree list --porcelain)
    [ "$found" = 0 ] || exit 10
    ;;
  *)
    echo "usage: worktree.sh dir|add|ignore|legacy" >&2
    exit 2
    ;;
esac
