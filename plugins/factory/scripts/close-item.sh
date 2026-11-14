#!/bin/bash
# Step 8.6 of skills/run/SKILL.md: remove work/<id>/ in the item worktree, in one script that stops at the first failure.
# Usage: close-item.sh <id>      (run it from the main checkout; every command names the worktree by its absolute path)
# Guard first: <id> numeric, a worktree on branch item/<id>, that worktree is not the main checkout, and neither work/ nor work/<id> is a
# symlink. Then the lead-state commit `#<id> lead: close`, staging only the protocol's files (`work/<id>/NN-*.md`, never a nested
# directory, plus changes to files already tracked) and only when something is staged. Then `git rm`, `git clean -fdx` on work/<id>
# alone, a check that nothing is left (a nested git repository stays on purpose), and the commit `#<id> lead: remove work/`.
# Other untracked files under work/<id>/ are never staged: a commit stays in the project's history for good.
# Exit: 0 done; 1 the guard stopped (a message on stderr, nothing removed) or a step failed (a nested repository: `git rm` staged,
# nothing committed), or `git diff --cached` itself failed (so the lead state is never removed uncommitted). On 1, stop the close and put it to the person.
case "${1:-}" in ''|*[!0-9]*) echo "close: id not numeric" >&2; exit 1 ;; esac
id="$1"
w="$(git worktree list --porcelain | awk -v b="branch refs/heads/item/$id" '/^worktree /{p=substr($0,10)} $0==b{print p}')"
[ -n "$w" ] || { echo "close: no worktree for item/$id" >&2; exit 1; }
m="$(git worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')"
[ "$w" != "$m" ] || { echo "close: worktree is the main checkout" >&2; exit 1; }
if [ -L "${w:?}/work" ] || [ -L "${w:?}/work/$id" ]; then echo "close: work/ is a symlink" >&2; exit 1; fi
git -C "${w:?}" add -- ":(glob)work/$id/[0-9][0-9]-*.md" || exit 1
git -C "${w:?}" add -u -- "work/$id" || exit 1
git -C "${w:?}" diff --cached --quiet
d=$?
if [ $d = 1 ]; then git -C "${w:?}" commit -m "#$id lead: close" || exit 1
elif [ $d != 0 ]; then echo "close: the staged-changes check failed ($d); nothing removed" >&2; exit 1; fi
git -C "${w:?}" rm -r -q -- "work/$id" && git -C "${w:?}" clean -f -d -x -q -- "work/$id" && [ ! -e "${w:?}/work/$id" ] && git -C "${w:?}" commit -m "#$id lead: remove work/"
