#!/usr/bin/env bash
# stage-publish.sh: make a stage's content readable on the remote and the tracker while an item runs (#231). Lead-only: a role never runs it.
# Usage: bash stage-publish.sh push [<dir>]
#        bash stage-publish.sh links [--github <owner/repo>] <rev | base..head>
#        bash stage-publish.sh append [--github <owner/repo>] <comment-file> <rev | base..head>
# push:   pushes the checked-out branch of <dir> (default the current directory) to origin, with upstream on the first push.
#         It first scans the files of the commits not yet on the remote (`post-text.sh scan`); a hit pushes nothing and exits 5.
#         A failed push prints `stage-publish: push failed (<reason>)` on stderr and exits 4; the lead reports either and the item goes on.
# links:  one line per file the commit (or the range) added or changed: `- [<path>](https://github.com/<repo>/blob/<sha>/<path>)`, the
#         sha being the full sha of the commit (of the range's head). A sha permalink does not depend on a branch, so it resolves after
#         the branch is deleted and after the path is removed again. At most 40 files, then `- and <n> more`. <repo> is read from `origin`.
# append: inserts the `links` block into a rendered closing comment (post-text.sh render), before its first <details> line, between the
#         markers `<!-- factory:files -->`; a second call replaces the block.
# Exit: 0 done; 2 usage, an unknown rev, a repo that is not github.com owner/repo; 4 the push failed; 5 the push was refused: the scan of the
#       files it would publish found a home path or a secret (the scan lines on stderr, never the text; nothing is pushed).
# No tracker call. No write outside <comment-file>.

usage() { sed -n '2,/^# No tracker/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
cmd="${1:-}"; [ $# -gt 0 ] && shift

repo_of_origin() {
  local u r
  u="$(git remote get-url origin 2>/dev/null)" || return 1
  case "$u" in
    https://github.com/*) r="${u#https://github.com/}" ;;
    git@github.com:*) r="${u#git@github.com:}" ;;
    ssh://git@github.com/*) r="${u#ssh://git@github.com/}" ;;
    *) return 1 ;;
  esac
  printf '%s' "${r%.git}"
}

encode() { printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/#/%23/g' -e 's/?/%3F/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g' -e 's/</%3C/g' -e 's/>/%3E/g' -e 's/"/%22/g' -e 's/\\/%5C/g'; }
label() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g'; }

links() {
  local repo="" rev head parent files n=0 total f
  while [ $# -gt 0 ]; do
    case "$1" in
      --github) repo="${2:-}"; shift 2 || usage ;;
      -*) usage ;;
      *) [ -z "${rev:-}" ] || usage; rev="$1"; shift ;;
    esac
  done
  [ -n "${rev:-}" ] || usage
  if [ -z "$repo" ]; then repo="$(repo_of_origin)" || { echo "stage-publish: origin is not a github.com repository; pass --github <owner/repo>" >&2; exit 2; }; fi
  printf '%s' "$repo" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' || { echo "stage-publish: --github must be <owner>/<repo>" >&2; exit 2; }
  case "$rev" in
    *..*) head="$(git rev-parse --verify --quiet "${rev##*..}^{commit}")" || { echo "stage-publish: unknown revision" >&2; exit 2; }
          git rev-parse --verify --quiet "${rev%%..*}^{commit}" >/dev/null || { echo "stage-publish: unknown revision" >&2; exit 2; }
          files="$(git -c core.quotePath=false diff --no-renames --name-only --diff-filter=ACMR "${rev%%..*}" "$head" 2>/dev/null)" ;;
    *) head="$(git rev-parse --verify --quiet "$rev^{commit}")" || { echo "stage-publish: unknown revision" >&2; exit 2; }
       parent="$(git rev-parse --verify --quiet "$head^" || echo 4b825dc642cb6eb9a060e54bf8d69288fbc3b9b)"
       files="$(git -c core.quotePath=false diff --no-renames --name-only --diff-filter=ACMR "$parent" "$head" 2>/dev/null)" ;;
  esac
  total="$(printf '%s\n' "$files" | grep -c .)"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    [ "$n" -le 40 ] || continue
    printf -- '- [%s](https://github.com/%s/blob/%s/%s)\n' "$(label "$f")" "$repo" "$head" "$(encode "$f")"
  done <<EOF2
$files
EOF2
  [ "$total" -le 40 ] || printf -- '- and %s more\n' "$((total - 40))"
}

case "$cmd" in
  push)
    dir="${1:-.}"
    err="$(mktemp)" || exit 2
    trap 'rm -f "$err"' EXIT
    # what this push would publish is scanned first (home paths, secrets): files of the commits not yet on the remote
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    base="$(git -C "$dir" rev-parse --verify --quiet '@{u}' || git -C "$dir" merge-base HEAD origin/main 2>/dev/null || echo 4b825dc642cb6eb9a060e54bf8d69288fbc3b9b)"
    top="$(git -C "$dir" rev-parse --show-toplevel)" || exit 2
    list="$(cd "$dir" && git -c core.quotePath=false diff --no-renames --name-only --diff-filter=ACMR "$base" HEAD 2>/dev/null)"
    hit=0
    while IFS= read -r f; do
      [ -n "$f" ] && [ -f "$top/$f" ] && grep -Iq . "$top/$f" 2>/dev/null || continue
      bash "$here/post-text.sh" scan "$top/$f" >>"$err.scan" 2>&1 || hit=1
    done <<EOF3
$list
EOF3
    if [ "$hit" = 1 ]; then
      cat "$err.scan" >&2; rm -f "$err.scan"
      echo "stage-publish: push refused: a file of this stage has a home path or a secret; fix the file, commit, push again" >&2
      exit 5
    fi
    rm -f "$err.scan"
    if git -C "$dir" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
      git -C "$dir" push >/dev/null 2>"$err"; rc=$?
    else
      git -C "$dir" push -u origin HEAD >/dev/null 2>"$err"; rc=$?
    fi
    if [ "$rc" != 0 ]; then
      echo "stage-publish: push failed ($(tr '\n' ' ' <"$err" | cut -c1-200 | sed 's/ *$//'))" >&2
      exit 4
    fi
    exit 0
    ;;
  links) links "$@" ;;
  append)
    repo=""
    while [ "${1:-}" = "--github" ]; do repo="${2:-}"; shift 2 || usage; done
    [ $# -eq 2 ] || usage
    file="$1"; rev="$2"
    [ -f "$file" ] && [ -r "$file" ] && [ -w "$file" ] || { echo "stage-publish: $(basename "$file"): not a writable file" >&2; exit 2; }
    blk="$(mktemp)" || exit 2; out="$(mktemp)" || exit 2
    trap 'rm -f "$blk" "$out"' EXIT
    if [ -n "$repo" ]; then links --github "$repo" "$rev" >"$blk"; else links "$rev" >"$blk"; fi
    rc=$?; [ "$rc" = 0 ] || exit "$rc"
    LC_ALL=C awk -v blk="$blk" '
      BEGIN { while ((getline l < blk) > 0) b = b l "\n"; blockt = "<!-- factory:files -->\nFiles of this stage (permalinks):\n" b "<!-- factory:files -->\n" }
      /^<!-- factory:files -->$/ { skip = !skip; if (!skip) eat = 1; next }
      skip { next }
      eat && $0 == "" { eat = 0; next }
      { eat = 0 }
      /^<details>/ && !done { buf[++n] = "BLOCK"; done = 1 }
      { buf[++n] = $0 }
      END {
        if (!done) { while (n > 0 && buf[n] == "") n--; buf[++n] = ""; buf[++n] = "BLOCK" }
        for (i = 1; i <= n; i++) {
          if (buf[i] == "BLOCK") { printf "%s", blockt; if (i < n) print "" }
          else print buf[i]
        }
      }' "$file" >"$out" || exit 2
    cat "$out" >"$file" || exit 2
    exit 0
    ;;
  *) usage ;;
esac
