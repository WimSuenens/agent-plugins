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
# QA verdict file (slice 5): `--qa-file <verdict>` is required and is read for what the verdict says per criterion. The format (references/run-roles.md): `Verdict: pass|block`,
#   `Scope: standard|light`, `## Criteria` lines `- <id>: pass|block | check: <text> | proof: P1[, P2]`, `## Proof` lines `- P1 [<kind>]: <link or path>`, `Human-only criteria:`
#   (instruction markdown). The gate blocks, naming the criterion, when a criterion has no proof item, links one that is not in the Proof list or has no link, links none of the kind the
#   artefact takes (proof-kind.sh: --kind, else the plan's `artefact:` line, else the project-type in the table), or is block; and prints `verdict read:` with what it counted.
#   A `Scope: light` verdict also needs `Path check: ok` and a `Suite:` line, the plan (`--plan`) with the lightest band, and no protected area: the light verdict narrows QA for the Light band only.
# No proof means no auto-merge: the description needs a `## Proof` section with a screenshot link or a log block.

usage() { echo "usage: merge-gate.sh check <pr> --qa <verdict> --qa-file <verdict file> --security <verdict> [--plan <plan file>] [--kind <artefact kind>] [--skip-reason <text>] [--touches <list>] [--paths \"<files>\"]" >&2; exit 2; }
[ "${1:-}" = check ] && [ -n "${2:-}" ] || usage
pr="$2"; shift 2
qa=""; sec=""; touches=""; paths=""; skipreason=""; qafile=""; plan=""; kind=""
while [ $# -gt 0 ]; do
  case "$1" in
    --qa) qa="${2-}" ;; --security) sec="${2-}" ;; --touches) touches="${2-}" ;; --paths) paths="${2-}" ;; --skip-reason) skipreason="${2-}" ;;
    --qa-file) qafile="${2-}" ;; --plan) plan="${2-}" ;; --kind) kind="${2-}" ;;
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

# the QA verdict file: each criterion links a proof item of the artefact's kind; a light verdict only for the Light band
check_verdict() {
  local f="$1" k rc kout accepted vv scope us rows c p ncrit nproof kinds lightest pband pk pr t id st ref kd
  us=$'\037'
  if [ -z "$f" ]; then addb "no QA verdict file (--qa-file): the gate cannot check that each criterion links a proof item"; return; fi
  if [ ! -r "$f" ]; then addb "the QA verdict file $f is unreadable"; return; fi
  local tbl=()
  if [ -z "$kind" ] && { [ -z "$plan" ] || ! grep -q '^- artefact:' "$plan" 2>/dev/null; }; then
    local top; top="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [ -n "$top" ] && git -C "$top" rev-parse --verify --quiet origin/main >/dev/null 2>&1 && git -C "$top" cat-file -e origin/main:docs/agents/factory.md 2>/dev/null; then
      tbl=(--table <(git -C "$top" show origin/main:docs/agents/factory.md))
    elif [ -r "${top:-.}/docs/agents/factory.md" ]; then tbl=(--table "${top:-.}/docs/agents/factory.md"); fi
  fi
  kout="$(bash "$here/proof-kind.sh" resolve ${kind:+--kind "$kind"} ${plan:+--plan "$plan"} ${tbl[@]+"${tbl[@]}"} 2>&1)"; rc=$?
  if [ "$rc" != 0 ]; then addb "the artefact kind is not known ($(printf '%s' "$kout" | head -1 | sed 's/^proof-kind: //')): pass --kind or write an \`artefact:\` line in the plan"; return; fi
  k="$(printf '%s\n' "$kout" | sed -n 's/^kind: //p')"; accepted="$(printf '%s\n' "$kout" | sed -n 's/^proof: //p')"
  infos="${infos}artefact kind: $k (proof: $accepted)"$'\n'
  vv="$(sed -n 's/^Verdict:[[:space:]]*//p' "$f" | head -1 | tr -d '\r' | sed 's/[[:space:]]*$//')"
  scope="$(sed -n 's/^Scope:[[:space:]]*//p' "$f" | head -1 | tr -d '\r' | sed 's/[[:space:]]*$//')"
  [ "$vv" = pass ] || addb "the QA verdict file says ${vv:-nothing}, not pass"
  rows="$(awk -v us="$us" '
    { sub(/\r$/, "") }
    /^## /{ sec = ($0 ~ /^## Criteria[ \t]*$/) ? "c" : (($0 ~ /^## Proof[ \t]*$/) ? "p" : ""); next }
    sec == "c" && /^- [^:]+:/ {
      line = $0; sub(/\r$/, "", line); sub(/^- /, "", line); id = line; sub(/:.*/, "", id); rest = line; sub(/^[^:]+:[ \t]*/, "", rest)
      st = rest; sub(/[ \t|].*/, "", st); if (st == "") st = "empty"; pr = ""; if (match(rest, /\| *proof:.*/)) { pr = substr(rest, RSTART, RLENGTH); sub(/^\| *proof:[ \t]*/, "", pr); gsub(/[ \t]/, "", pr) }
      print "C" us id us st us pr; next }
    sec == "p" && /^- [^ ]+ \[[^]]*\]:/ {
      line = $0; sub(/\r$/, "", line); sub(/^- /, "", line); id = line; sub(/ .*/, "", id); kd = line; sub(/^[^[]*\[/, "", kd); sub(/\].*/, "", kd)
      ref = line; sub(/^[^]]*\]:[ \t]*/, "", ref); sub(/[ \t]+$/, "", ref); print "P" us id us kd us ref }' "$f")"
  ncrit="$(printf '%s\n' "$rows" | grep -c '^C')"; nproof="$(printf '%s\n' "$rows" | grep -c '^P')"
  kinds="$(printf '%s\n' "$rows" | awk -F"$us" '$1 == "P" { print $3 }' | sort -u | paste -sd, - | sed 's/,/, /g')"
  infos="${infos}verdict read: $f: $ncrit criteria, $nproof proof items (${kinds:-none})"$'\n'
  if [ "$ncrit" = 0 ]; then addb "the QA verdict has no criterion lines under \"## Criteria\" (\`- <id>: pass | check: <text> | proof: P1\`)"
  else
    while IFS="$us" read -r t id st pr; do
      [ "$t" = C ] || continue
      [ "$st" = pass ] || addb "criterion $id is $st in the QA verdict"
      if [ -z "$pr" ]; then addb "criterion $id has no proof item linked"; continue; fi
      local okkind=0 seen="" missing=0
      for p in $(printf '%s' "$pr" | tr ',' ' '); do
        local row; row="$(printf '%s\n' "$rows" | awk -F"$us" -v p="$p" '$1 == "P" && $2 == p { print; exit }')"
        if [ -z "$row" ]; then addb "criterion $id links $p, which is not in the Proof list"; missing=1; continue; fi
        local pkind pref; pkind="$(printf '%s' "$row" | awk -F"$us" '{ print $3 }')"; pref="$(printf '%s' "$row" | awk -F"$us" '{ print $4 }')"
        seen="${seen:+$seen, }$p is a $pkind"
        case ", $accepted, " in *", $pkind, "*) okkind=1 ;; esac
      done
      [ "$okkind" = 1 ] || [ "$missing" = 1 ] || addb "criterion $id links no $(printf '%s' "$accepted" | sed 's/, / or /') ($seen)"
    done <<ROWS
$rows
ROWS
    while IFS="$us" read -r t id kd ref; do
      [ "$t" = P ] || continue
      [ -n "$ref" ] || addb "proof item $id has no link or path"
    done <<ROWS
$rows
ROWS
  fi
  [ "$k" = instruction-markdown ] && ! grep -q '^Human-only criteria:' "$f" && addb "the QA verdict has no \`Human-only criteria:\` line (an instruction-markdown slice lists them, or says none)"
  if [ "$scope" = light ]; then
    if [ -z "$plan" ] || [ ! -r "$plan" ]; then addb "a light verdict needs the plan (--plan) to show the slice is in the lightest band"
    else
      lightest="$(grep -m 1 '^- bands:' "$plan" | sed 's/^- bands:[[:space:]]*//' | tr -d '\r' | cut -d, -f1 | sed 's/^[[:space:]]*//' | cut -d' ' -f1)"
      pband="$(grep -m 1 '^- band:' "$plan" | sed 's/^- band:[[:space:]]*//' | tr -d '\r' | sed 's/[[:space:]]*$//')"
      if [ -z "$lightest" ] || [ "$pband" != "$lightest" ]; then addb "a light verdict stands for the ${lightest:-lightest} band only; the plan says ${pband:-no band}"; else infos="${infos}verdict scope: light (band $pband)"$'\n'; fi
    fi
    [ -z "$humans" ] || addb "a light verdict cannot stand for a protected area ($(printf '%s' "$humans" | tr '\n' ' ' | sed 's/ $//')): its test depth is at least targeted"
    pk="$(sed -n 's/^Path check:[[:space:]]*//p' "$f" | head -1 | tr -d '\r')"
    if [ -z "$pk" ]; then addb "a light verdict needs a \`Path check:\` line"; else case "$pk" in ok*) ;; *) addb "the light verdict's path check is not ok ($pk)" ;; esac; fi
    grep -q '^Suite:' "$f" || addb "a light verdict needs a \`Suite:\` line (the existing suite and its result, or none)"
  fi
}
check_verdict "$qafile"

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
