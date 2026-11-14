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
# Checks: every outcome prints `checks read: <name>=<state>, ...` (or `none`) after the first line, so the reader sees which checks the gate read.
# `ci:` line (column 0 of docs/agents/factory.md, read from origin/main so a branch cannot declare it for itself; the working tree's copy only where there is no origin/main): with `ci: none` a PR with no
#   check at all is accepted on a recorded local run on its head: a `## Local run` section in the description with `sha:`, `command:`,
#   `last line:` and `time:` lines (a list dash is allowed), the sha being the head of the PR. The gate then prints `ci: none (local run on <sha>)`.
#   A failing or pending check stays blocking. With neither a check nor the declaration the gate blocks and the reason names both ways out.
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
json="$(gh pr view "$pr" --json body,statusCheckRollup,headRefOid 2>/dev/null)" && jq -e . >/dev/null 2>&1 <<<"$json" || { echo "merge-gate: cannot read PR $pr" >&2; exit 2; }

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

# CI: at least one check, every one finished green (success, neutral or skipped); or, with `ci: none`, a recorded local run on the PR head
notgreen="$(jq -r '(.statusCheckRollup // []) as $c | if ($c|length) == 0 then "none" else ([$c[] | select(((.conclusion // .state // "") | ascii_upcase) as $k | ($k=="SUCCESS" or $k=="NEUTRAL" or $k=="SKIPPED") | not)] | length | tostring) end' <<<"$json")"
checks_read="$(jq -r '(.statusCheckRollup // []) as $c | if ($c|length) == 0 then "none" else ([$c[] | "\(.name // .context // "check")=\((.conclusion // .state // "") | ascii_upcase)"] | join(", ")) end' <<<"$json")"
infos="checks read: $checks_read"$'\n'
ci_declared() {   # the project's ci: line, from origin/main: a branch cannot declare it for itself. The working tree's copy is read only where there is no origin/main to read
  local top l=""
  top="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -n "$top" ] && git -C "$top" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
    l="$(git -C "$top" show origin/main:docs/agents/factory.md 2>/dev/null | grep -m 1 '^ci:')"
  elif [ -r "${top:-.}/docs/agents/factory.md" ]; then
    l="$(grep -m 1 '^ci:' "${top:-.}/docs/agents/factory.md")"
  fi
  printf '%s' "$l" | tr -d '\r'
}
ciline="$(ci_declared)"
if [ "$notgreen" = none ]; then
  case "$ciline" in
    "ci: none" | "ci: none "*)
      body="$(jq -r '.body // ""' <<<"$json")"
      lr="$(printf '%s\n' "$body" | awk '/^## /{p = ($0 ~ /^## Local run[ \t]*$/); next} p' | sed 's/^[-*][[:space:]]*//')"
      rsha="$(printf '%s\n' "$lr" | sed -n 's/^sha:[[:space:]]*//p' | head -n1 | tr -d ' \r')"
      rcmd="$(printf '%s\n' "$lr" | sed -n 's/^command:[[:space:]]*//p' | head -n1)"
      rlast="$(printf '%s\n' "$lr" | sed -n 's/^last line:[[:space:]]*//p' | head -n1)"
      rtime="$(printf '%s\n' "$lr" | sed -n 's/^time:[[:space:]]*//p' | head -n1)"
      headsha="$(jq -r '.headRefOid // ""' <<<"$json" | tr 'A-F' 'a-f')"
      lsha="$(printf '%s' "$rsha" | tr 'A-F' 'a-f')"
      if [ -z "${rsha}${rcmd}${rlast}${rtime}" ]; then
        addb "CI is not green (no checks reported); the project declares \`ci: none\`, so record a local run on the PR head in the description: a \`## Local run\` section with sha, command, last line and time"
      elif [ -z "$rsha" ] || [ -z "${rcmd//[[:space:]]/}" ] || [ -z "${rlast//[[:space:]]/}" ] || [ -z "${rtime//[[:space:]]/}" ]; then
        addb "CI is not green (no checks reported); the \`## Local run\` section needs all four lines: sha, command, last line and time"
      elif ! printf '%s' "$lsha" | grep -Eq '^[0-9a-f]{7,40}$' || [ -z "$headsha" ] || [ "${headsha#"$lsha"}" = "$headsha" ]; then
        addb "CI is not green (no checks reported); the local run is not on the PR head (it names ${rsha:-no sha}, the head is ${headsha:0:12})"
      else
        infos="${infos}ci: none (local run on $rsha)"$'\n'
      fi ;;
    "ci: "*) addb "CI is not green (no checks reported); ci: says a workflow runs the tests: wait for its check on the PR head, or fix the workflow's trigger" ;;
    *) addb "CI is not green (no checks reported); two ways out: a workflow that runs the test command on pull requests, or declare \`ci: none\` in docs/agents/factory.md (setup-factory-skill writes the line) and record a local run on the PR head in a \`## Local run\` section" ;;
  esac
elif [ "$notgreen" != 0 ]; then
  addb "CI is not green ($notgreen checks not passing)"
fi

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
  echo "gate $pr: blocked"; printf '%s' "$infos"; printf '%s' "$blocks"
  [ -n "$humans" ] && echo "reason: also needs the person: $(printf '%s' "$humans" | tr '\n' ' ' | sed 's/ $//')"
  exit 11
fi
if [ -n "$humans" ]; then
  list="$(printf '%s' "$humans" | tr '\n' ',' | sed 's/,$/ /; s/,/, /g')"
  echo "gate $pr: pause"
  printf '%s' "$infos"
  echo "reason: always human: ${list% }"
  echo "validation script:"
  echo "1. Open the PR and read its description and the proof in it."
  echo "2. Check the change touching ${list% } is what you want, and that nothing else changed in that area."
  echo "3. Try the changed behaviour yourself the way the proof shows it, and compare what you see."
  echo "4. Answer yes to merge and clean up, or tell the factory what to change."
  exit 10
fi
echo "gate $pr: auto-merge"
printf '%s' "$infos"
exit 0
