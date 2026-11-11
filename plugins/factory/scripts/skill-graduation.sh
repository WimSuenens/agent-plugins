#!/usr/bin/env bash
# Skill graduation: a project skill that proved itself is drafted as a proposal for a domain plugin; it is never published.
# Usage: bash skill-graduation.sh record <skill> <origin>
#        bash skill-graduation.sh eligible <skill> <skill-file>
#        bash skill-graduation.sh match <domain-text> <plugins-dir>
#        bash skill-graduation.sh draft <skill> <skill-file> <domain-text> <plugins-dir> <out-file>
#        bash skill-graduation.sh check-proposal <file>
#        bash skill-graduation.sh submit <file> [--approved <sha256>]
# record: appends "| <skill> | <origin> |" to docs/agents/skill-uses.md of the main checkout. <origin> is an item (item-12) or a
#      project label; the same pair is recorded once. A skill and an origin are [a-z0-9]+(-[a-z0-9]+)*.
# eligible: the use threshold, then the sanitising scan. A skill is offered only with at least two distinct origins and a clean
#      text: prints "eligible <sha256 of the file>". Exit 5 when it has fewer ("not offered: N use(s)"), 6 when the scan refuses.
# match: searches <plugins-dir>/*/.claude-plugin/plugin.json for the "domain" sentence sharing the most words (4 letters or
#      more, at least two) with <domain-text>. Prints "match <plugin>: <domain>" or "none". Plugins without a domain are ignored.
# draft: eligible, match, then writes the proposal to <out-file> (nothing is written when the skill is not offered). It names
#      the best-matching plugin, or says none matches. Files nothing.
# check-proposal and submit: the improvement loop's scan and approval gate (improvement.sh check, submit): a proposal reaches
#      the marketplace repository only with --approved <sha256 of the exact file the person said yes to>.
# Exit: 0 ok; 2 usage or a missing input; 5 below the use threshold; 6 the scan refused; 7 no approval; others as improvement.sh.
# See contracts/119-skill-graduation.md in the repo that hosts the factory.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-}"
usage() {
  echo "usage: skill-graduation.sh record <skill> <origin> | eligible <skill> <file> | match <domain-text> <plugins-dir> | draft <skill> <file> <domain-text> <plugins-dir> <out> | check-proposal <file> | submit <file> [--approved <sha256>]" >&2
  exit 2
}
name_ok() { printf '%s' "$1" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; }
main_checkout() {
  git worktree list --porcelain 2>/dev/null | while IFS= read -r l; do
    case "$l" in "worktree "*) printf '%s\n' "${l#worktree }"; break ;; esac
  done
}
main="$(main_checkout)"
[ -n "$main" ] || { echo "skill-graduation: not a git repository" >&2; exit 2; }
uses="$main/docs/agents/skill-uses.md"

count_uses() { [ -f "$uses" ] || { echo 0; return; }; grep "^| $1 |" "$uses" | awk -F'|' '{gsub(/ /,"",$3); print $3}' | sort -u | grep -c .; }

# eligible_check <skill> <file>: threshold then scan; prints the eligible line
eligible_check() {
  name_ok "$1" || usage
  [ -r "$2" ] || { echo "skill-graduation: $2: no such file" >&2; exit 2; }
  n="$(count_uses "$1")"
  if [ "$n" -lt 2 ]; then
    s=s; [ "$n" = 1 ] && s=""
    echo "skill-graduation: not offered: $1 has $n use$s; it needs at least two items or two projects" >&2; exit 5
  fi
  out="$(bash "$here/improvement.sh" check "$2")"
  rc=$?; [ $rc = 0 ] || exit $rc
  echo "eligible ${out#clean }"
}

words() { tr 'A-Z' 'a-z' | tr -c 'a-z0-9\n' '\n' | awk 'length($0) >= 4' | sort -u; }

find_match() {
  local text="$1" dir="$2" best="" bestscore=1 m p d score
  words <<<"$text" >"$tmpw"
  for m in "$dir"/*/.claude-plugin/plugin.json; do
    [ -f "$m" ] || continue
    d="$(jq -r '.domain // empty' "$m" 2>/dev/null)"; [ -n "$d" ] || continue
    p="$(jq -r '.name // empty' "$m")"; [ -n "$p" ] || continue
    score="$(words <<<"$d" | comm -12 - "$tmpw" | grep -c .)"
    if [ "$score" -gt "$bestscore" ]; then bestscore="$score"; best="match $p: $d"; fi
  done
  echo "${best:-none}"
}
tmpw="$(mktemp)"; trap 'rm -f "$tmpw"' EXIT

case "$cmd" in
  record)
    [ $# -eq 3 ] || usage
    name_ok "$2" && name_ok "$3" || usage
    if [ ! -f "$uses" ]; then
      mkdir -p "$(dirname "$uses")"
      printf '# Skill uses\n\nWhere each project skill proved itself: an item or a project. A skill with two distinct origins can graduate.\n\n| Skill | Origin |\n|---|---|\n' >"$uses"
    fi
    grep -q "^| $2 | $3 |" "$uses" || printf '| %s | %s |\n' "$2" "$3" >>"$uses"
    echo "recorded $2 $3"
    ;;
  eligible)
    [ $# -eq 3 ] || usage
    eligible_check "$2" "$3"
    ;;
  match)
    [ $# -eq 3 ] || usage
    [ -d "$3" ] || { echo "skill-graduation: $3: no such directory" >&2; exit 2; }
    find_match "$2" "$3"
    ;;
  draft)
    [ $# -eq 6 ] || usage
    [ -d "$5" ] || { echo "skill-graduation: $5: no such directory" >&2; exit 2; }
    eligible_check "$2" "$3" >/dev/null
    res="$(find_match "$4" "$5")"
    { printf 'Skill proposal: %s\n\n## Domain of the skill\n\n%s\n\n## Where it goes\n\n' "$2" "$4"
      if [ "$res" = none ]; then
        printf 'No existing plugin matches this domain. Propose a new plugin for it, named for the domain and not for a role.\n'
      else
        rest="${res#match }"
        printf 'Best-matching plugin: %s\n\nIts domain: %s\n\nExtend the existing plugin with this skill.\n' "${rest%%:*}" "${rest#*: }"
      fi
      printf '\n## Evidence\n\nThe skill proved itself in %s distinct items or projects.\n\n## The skill\n\n' "$(count_uses "$2")"
      cat "$3"; } >"$tmpw.prop"
    bash "$here/improvement.sh" check "$tmpw.prop" >/dev/null || { rc=$?; rm -f "$tmpw.prop"; exit $rc; }
    mv "$tmpw.prop" "$6"
    echo "drafted $6"
    ;;
  check-proposal) shift; exec bash "$here/improvement.sh" check "$@" ;;
  submit) shift; exec bash "$here/improvement.sh" submit "$@" ;;
  *) usage ;;
esac
