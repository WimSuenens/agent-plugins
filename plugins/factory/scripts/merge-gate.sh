#!/usr/bin/env bash
# The auto-merge gate: decides whether the factory may merge its own PR without the person.
# Usage: bash merge-gate.sh check <pr> --qa <verdict> --security <verdict> [--skip-reason <text>] [--touches <list>] [--paths "<file> ..."]
#   <pr>        the PR number or branch; its description and checks are read with `gh pr view <pr> --json body,statusCheckRollup`.
#   --qa, --security   the verdicts of the QA and security tasks; QA must be `pass`; security is `pass`, or `skipped` with --skip-reason when the lead skipped the role by skip.sh's rule (a written reason, no protected area; a skip on a protected slice blocks). Anything else, or a missing verdict, blocks.
#   --touches   comma-separated: contract, authentication, secrets, migration, door (what the lead knows about the slice).
#   --paths     the files the slice changed, one per line (a path may hold a space; a one-line list is still split on whitespace); migration, secret and authentication paths count as touches too.
# Output: `gate <pr>: auto-merge | pause | blocked`, then `reason: ...` lines. A pause is followed by `validation script:`
# and plain-language steps for the person; the lead posts them and sets the card `Waiting on you` (`Cause: validation`).
# Exit: 0 auto-merge; 10 pause (a human must decide); 11 blocked (a gate is not met; the reasons say which); 2 usage or no PR.
# No proof means no auto-merge: the description needs a `## Proof` section with a screenshot link or a log block.

usage() { echo "usage: merge-gate.sh check <pr> --qa <verdict> --security <verdict> [--skip-reason <text>] [--touches <list>] [--paths \"<files>\"]" >&2; exit 2; }
[ "${1:-}" = check ] && [ -n "${2:-}" ] || usage
pr="$2"; shift 2
qa=""; sec=""; touches=""; paths=""; skipreason=""
while [ $# -gt 0 ]; do
  case "$1" in
    --qa) qa="${2-}" ;; --security) sec="${2-}" ;; --touches) touches="${2-}" ;; --paths) paths="${2-}" ;; --skip-reason) skipreason="${2-}" ;;
    *) usage ;;
  esac
  [ $# -ge 2 ] || usage
  shift 2
done
command -v jq >/dev/null 2>&1 || { echo "merge-gate: jq missing" >&2; exit 2; }
json="$(gh pr view "$pr" --json body,statusCheckRollup 2>/dev/null)" && jq -e . >/dev/null 2>&1 <<<"$json" || { echo "merge-gate: cannot read PR $pr" >&2; exit 2; }

blocks=""; humans=""
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=protected-areas.sh
. "$here/protected-areas.sh"
addb() { blocks="${blocks}reason: $1"$'\n'; }
addh() { humans="${humans}$1"$'\n'; }

[ "$qa" = pass ] || addb "QA verdict is ${qa:-missing}, not pass"
# security: `pass`, or `skipped` when the lead skipped the role legitimately (skip.sh allowed it: a written reason, not a protected area)
case "$sec" in
  pass) ;;
  skipped)
    case "$skipreason" in *[![:space:]]*) ;; *) addb "security review skipped without a written reason (--skip-reason)" ;; esac ;;
  *) addb "security verdict is ${sec:-missing}, not pass" ;;
esac

# CI: at least one check, every one finished green (success, neutral or skipped)
notgreen="$(jq -r '(.statusCheckRollup // []) as $c | if ($c|length) == 0 then "none" else ([$c[] | select(((.conclusion // .state // "") | ascii_upcase) as $k | ($k=="SUCCESS" or $k=="NEUTRAL" or $k=="SKIPPED") | not)] | length | tostring) end' <<<"$json")"
[ "$notgreen" = 0 ] || addb "CI is not green ($([ "$notgreen" = none ] && echo "no checks reported" || echo "$notgreen checks not passing"))"

# proof: a `## Proof` section holding an image or a fenced log block
proof="$(jq -r '.body // ""' <<<"$json" | awk '/^## /{p = ($0 ~ /^## Proof[ \t]*$/); next} p')"
if printf '%s\n' "$proof" | grep -Eq '!\[[^]]*\]\([^)]+\)|^```'; then :; else addb "no proof in the PR description (a Proof section with screenshots or a run log)"; fi

# always human
set -f   # no glob expansion of the path and touch lists
for t in $(printf '%s' "$touches" | tr ',' ' '); do
  a="$(protected_touch_area "$t")" && addh "$a"
done
protected_paths_line   # read the project's line once here: the calls below run in subshells
while IFS= read -r p; do
  a="$(protected_path_area "$p")" && addh "$a"
done <<PATHS
$(protected_list_paths "$paths")
PATHS
set +f
[ "$sec" = skipped ] && [ -n "$humans" ] && addb "security review cannot be skipped for a protected area ($(printf '%s' "$humans" | sort -u | tr '\n' ' ' | sed 's/ $//'))"
humans="$(printf '%s' "$humans" | sort -u)"

if [ -n "$blocks" ]; then
  echo "gate $pr: blocked"; printf '%s' "$blocks"
  [ -n "$humans" ] && echo "reason: also needs the person: $(printf '%s' "$humans" | tr '\n' ' ' | sed 's/ $//')"
  exit 11
fi
if [ -n "$humans" ]; then
  list="$(printf '%s' "$humans" | tr '\n' ',' | sed 's/,$/ /; s/,/, /g')"
  echo "gate $pr: pause"
  echo "reason: always human: ${list% }"
  echo "validation script:"
  echo "1. Open the PR and read its description and the proof in it."
  echo "2. Check the change touching ${list% } is what you want, and that nothing else changed in that area."
  echo "3. Try the changed behaviour yourself the way the proof shows it, and compare what you see."
  echo "4. Answer yes to merge and clean up, or tell the factory what to change."
  exit 10
fi
echo "gate $pr: auto-merge"
exit 0
