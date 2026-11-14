#!/usr/bin/env bash
# Runs the project's release hook, when the project declares one. The plugin knows nothing about what a release is: a project that
# wants a step at *Open PR* or in the merge train puts one line at column 0 of its docs/agents/factory.md:
#   release-hook: <path of a script in the repository>
# and no such line means no release step and nothing printed.
# Usage: bash release-hook.sh <phase> <worktree> <id> <base> [<extra>]     (id is `-` when there is none; base defaults to origin/main)
#        bash release-hook.sh declared <worktree> [<base>]
# The declaration is read from docs/agents/factory.md at <base> first, so a branch cannot drop the line that judges it; only
# where <base> has no such line is the worktree's own file read (the branch that introduces a hook).
# The hook is run as `bash <worktree>/<path> <phase> <worktree> <id> <base> [<extra>]` with the worktree as the current directory.
# Phases: check (before a PR opens and before the merge; exit 0 pass, 1 refuse, 2 unusable), resolve <file> (a clash during the
# rebase; exit 0 resolved and staged, 1 not the hook's), prepare (after the rebase, before the merge; exit 4 a problem),
# tag <branch> (after the merge; exit 1 failed). The hook's own lines and exit code are passed through.
# Exit: the hook's; 0 and no output when none is declared (`resolve`: 1; `declared`: 1); 2 usage, or the declared hook is unusable.
phase="${1:-}"; w="${2:-}"
[ -n "$phase" ] && [ -d "$w" ] || { echo "usage: release-hook.sh <phase> <worktree> <id> <base> [<extra>]" >&2; exit 2; }
w="$(cd "$w" && pwd)"
if [ "$phase" = declared ]; then base="${3:-origin/main}"; else base="${4:-origin/main}"; fi
decl() { sed -n 's/^release-hook:[[:space:]]*//p' | head -n1 | sed 's/[[:space:]]*$//'; }
hook="$(git -C "$w" show "$base:docs/agents/factory.md" 2>/dev/null | decl)"
if [ -z "$hook" ] && [ -f "$w/docs/agents/factory.md" ]; then hook="$(decl <"$w/docs/agents/factory.md")"; fi
if [ -z "$hook" ]; then
  case "$phase" in declared | resolve) exit 1 ;; *) exit 0 ;; esac
fi
[ "$phase" != declared ] || { echo "$hook"; exit 0; }
case "$hook" in /* | ../* | */../* | *..) echo "release-hook: '$hook' must be a path inside the repository" >&2; exit 2 ;; esac
[ -f "$w/$hook" ] && [ ! -L "$w/$hook" ] || { echo "release-hook: no script (a regular file) at '$hook'" >&2; exit 2; }
shift 2
cd "$w" || exit 2
exec bash "$w/$hook" "$phase" "$w" "${1:--}" "${2:-origin/main}" "${3:-}"
