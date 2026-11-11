#!/usr/bin/env bash
# The auto-merge gate: decides whether the factory may merge its own PR without the person.
# Usage: bash merge-gate.sh check <pr> --qa <verdict> --security <verdict> [--touches <list>] [--paths "<file> ..."]
#   <pr>        the PR number or branch; its description and checks are read with `gh pr view <pr> --json body,statusCheckRollup`.
#   --qa, --security   the verdicts of the QA and security tasks; only `pass` lets the slice merge.
#   --touches   comma-separated: contract, authentication, secrets, migration, door (what the lead knows about the slice).
#   --paths     the files the slice changed; migration, secret and authentication paths count as touches too.
# Output: `gate <pr>: auto-merge | pause | blocked`, then `reason: ...` lines. A pause is followed by `validation script:`
# and plain-language steps for the person; the lead posts them and sets the card `Waiting on you` (`Cause: validation`).
# Exit: 0 auto-merge; 10 pause (a human must decide); 11 blocked (a gate is not met; the reasons say which); 2 usage or no PR.
# No proof means no auto-merge: the description needs a `## Proof` section with a screenshot link or a log block.

usage() { echo "usage: merge-gate.sh check <pr> --qa <verdict> --security <verdict> [--touches <list>] [--paths \"<files>\"]" >&2; exit 2; }
[ "${1:-}" = check ] && [ -n "${2:-}" ] || usage
pr="$2"; shift 2
qa=""; sec=""; touches=""; paths=""
while [ $# -gt 0 ]; do
  case "$1" in
    --qa) qa="${2-}" ;; --security) sec="${2-}" ;; --touches) touches="${2-}" ;; --paths) paths="${2-}" ;;
    *) usage ;;
  esac
  [ $# -ge 2 ] || usage
  shift 2
done
command -v jq >/dev/null 2>&1 || { echo "merge-gate: jq missing" >&2; exit 2; }
json="$(gh pr view "$pr" --json body,statusCheckRollup 2>/dev/null)" && jq -e . >/dev/null 2>&1 <<<"$json" || { echo "merge-gate: cannot read PR $pr" >&2; exit 2; }

blocks=""; humans=""
addb() { blocks="${blocks}reason: $1"$'\n'; }
addh() { humans="${humans}$1"$'\n'; }

[ "$qa" = pass ] || addb "QA verdict is ${qa:-missing}, not pass"
[ "$sec" = pass ] || addb "security verdict is ${sec:-missing}, not pass"

# CI: at least one check, every one finished green (success, neutral or skipped)
notgreen="$(jq -r '(.statusCheckRollup // []) as $c | if ($c|length) == 0 then "none" else ([$c[] | select(((.conclusion // .state // "") | ascii_upcase) as $k | ($k=="SUCCESS" or $k=="NEUTRAL" or $k=="SKIPPED") | not)] | length | tostring) end' <<<"$json")"
[ "$notgreen" = 0 ] || addb "CI is not green ($([ "$notgreen" = none ] && echo "no checks reported" || echo "$notgreen checks not passing"))"

# proof: a `## Proof` section holding an image or a fenced log block
proof="$(jq -r '.body // ""' <<<"$json" | awk '/^## /{p = ($0 ~ /^## Proof[ \t]*$/); next} p')"
if printf '%s\n' "$proof" | grep -Eq '!\[[^]]*\]\([^)]+\)|^```'; then :; else addb "no proof in the PR description (a Proof section with screenshots or a run log)"; fi

# always human
for t in $(printf '%s' "$touches" | tr ',' ' '); do
  case "$t" in
    contract|authentication|secrets|migration|door) addh "$t" ;;
    *) ;;
  esac
done
for p in $paths; do
  case "$p" in
    */migrations/*|migrations/*|*/migrate/*|*.sql) addh migration ;;
    .env*|*/.env*|*secret*|*credential*|*.pem|*.key) addh secrets ;;
    */auth/*|auth/*|*/authentication/*|*oauth*|*login*) addh authentication ;;
    */contracts/*|contracts/*) addh contract ;;
  esac
done
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
