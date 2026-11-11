#!/usr/bin/env bash
# The improvement loop: classify a finding, keep a local improvement with a trace, send a fundamental one as an approved proposal.
# Usage: bash improvement.sh classify <issue> <local|fundamental> <reason-file>
#        bash improvement.sh trace <name> <role> <measure|none> <before|not captured> <what> <why>
#        bash improvement.sh report <readings.json>
#        bash improvement.sh check <proposal-file>
#        bash improvement.sh submit <proposal-file> [--approved <sha256>]
# classify: posts the comment <!-- factory:finding v1 --> on the project's issue with the class and the reason. The reason must
#      not be empty and is scanned first (post-text.sh scan).
# trace: appends one row to docs/agents/improvements.md of the main checkout (the file is created with its header): date, name,
#      role, measure, before, what changed, why. The file is committed with the project; nothing in it expires. A name is
#      [a-z0-9]+(-[a-z0-9]+)* and unique; a "|" in the text becomes "/". The text is scanned first.
# report: reads the file and the readings {"<measure>": <value>} and prints one line per improvement,
#      "<name>: <measure>: before <b> / after <a>"; a measure that was not read, or null, reads "not captured", never 0.
# check: the sanitising scan for a proposal that would leave the project. Refuses (exit 6, one line per hit, never the text):
#      what post-text.sh scan refuses (home path, secret, work path), the project's own name, a URL, an issue reference (#<n>)
#      and a code fence. Prints "clean <sha256 of the file>" when it passes. The scan cannot read business content: the Lead
#      still reads the text before it shows it to the person.
# submit: files the proposal as an issue in the marketplace repository (FACTORY_MARKETPLACE_REPO, default
#      WimSuenens/agent-plugins), label plugin:factory, marker <!-- factory:improvement <sha256> -->. It files only with
#      --approved <sha256 of the exact file the person said yes to>; no flag or another hash files nothing (exit 7). The check
#      runs first. The same text is filed once: "existing #<n>". Prints "submitted <url>".
# Exit: 0 ok; 2 usage, a bad name, an empty reason, a duplicate name or a missing file; 3 no sha256 tool; 4 a gh call failed;
#       6 the scan refused the text; 7 no approval for this exact text.
# See contracts/116-improvement-loop.md in the repo that hosts the factory.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-}"
usage() {
  echo "usage: improvement.sh classify <issue> <local|fundamental> <reason-file> | trace <name> <role> <measure|none> <before> <what> <why> | report <readings.json> | check <file> | submit <file> [--approved <sha256>]" >&2
  exit 2
}
if command -v sha256sum >/dev/null 2>&1; then sha() { sha256sum | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then sha() { shasum -a 256 | cut -d' ' -f1; }
else echo "improvement: no sha256 tool" >&2; exit 3; fi

main_checkout() {
  git worktree list --porcelain 2>/dev/null | while IFS= read -r l; do
    case "$l" in "worktree "*) printf '%s\n' "${l#worktree }"; break ;; esac
  done
}
main="$(main_checkout)"
[ -n "$main" ] || { echo "improvement: not a git repository" >&2; exit 2; }
file="$main/docs/agents/improvements.md"
tmp="$(mktemp -d)" || exit 2; trap 'rm -rf "$tmp"' EXIT

# sanitise <file>: scan hits on stdout-merged stderr; returns 6 on any hit
sanitise() {
  local f="$1" b hits=0 pname
  b="$(basename "$f")"
  bash "$here/post-text.sh" scan "$f" >&2 || hits=1
  pname="$(basename "$main" | tr 'A-Z' 'a-z')"
  if [ "${#pname}" -ge 3 ]; then
    grep -inF -- "$pname" "$f" | cut -d: -f1 | while read -r n; do echo "scan: $b:$n: project-name" >&2; done
    grep -iqF -- "$pname" "$f" && hits=1
  fi
  grep -nE 'https?://' "$f" | cut -d: -f1 | while read -r n; do echo "scan: $b:$n: url" >&2; done
  grep -qE 'https?://' "$f" && hits=1
  grep -nE '(^|[^A-Za-z0-9_&])#[0-9]+' "$f" | cut -d: -f1 | while read -r n; do echo "scan: $b:$n: issue-reference" >&2; done
  grep -qE '(^|[^A-Za-z0-9_&])#[0-9]+' "$f" && hits=1
  grep -n '^[[:space:]]*```' "$f" | cut -d: -f1 | while read -r n; do echo "scan: $b:$n: code-fence" >&2; done
  grep -q '^[[:space:]]*```' "$f" && hits=1
  [ $hits = 0 ]
}

case "$cmd" in
  classify)
    [ $# -eq 4 ] || usage
    case "$2" in '' | *[!0-9]*) usage ;; esac
    case "$3" in local | fundamental) ;; *) usage ;; esac
    [ -s "$4" ] || usage
    bash "$here/post-text.sh" scan "$4" >&2 || { echo "improvement: the scan refused the reason; nothing posted" >&2; exit 6; }
    { printf '<!-- factory:finding v1 -->\n## Finding classified\n\n**Classification:** %s\n**Reason:** ' "$3"; tr '\n' ' ' <"$4" | sed 's/ *$//'; printf '\n'; } >"$tmp/c"
    gh issue comment "$2" --body-file "$tmp/c" >/dev/null || { echo "improvement: gh issue comment failed" >&2; exit 4; }
    echo "classified #$2 $3"
    ;;
  trace)
    [ $# -eq 7 ] || usage
    name="$2"; role="$3"; measure="$4"; before="$5"; what="${6//|//}"; why="${7//|//}"
    printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || usage
    printf '%s' "$role" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || usage
    printf '%s' "$measure" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || usage
    before="${before//|//}"
    [ -n "$what" ] && [ -n "$why" ] && [ -n "$before" ] || usage
    printf '%s\n%s\n%s\n' "$what" "$why" "$before" >"$tmp/t"
    bash "$here/post-text.sh" scan "$tmp/t" >&2 || { echo "improvement: the scan refused the text; nothing written" >&2; exit 6; }
    if [ -f "$file" ] && grep -q "^| [0-9-]* | $name |" "$file"; then echo "improvement: $name is already traced" >&2; exit 2; fi
    if [ ! -f "$file" ]; then
      mkdir -p "$(dirname "$file")"
      printf '# Improvements\n\nProject-local improvements the factory applied through the role files. They stay until the person removes them.\n\n| Date | Name | Role | Measure | Before | What changed | Why |\n|---|---|---|---|---|---|---|\n' >"$file"
    fi
    printf '| %s | %s | %s | %s | before %s | %s | %s |\n' "$(date -u +%F)" "$name" "$role" "$measure" "$before" "$what" "$why" >>"$file"
    echo "traced $name"
    ;;
  report)
    [ $# -eq 2 ] || usage
    [ -r "$2" ] && jq -e 'type == "object"' "$2" >/dev/null 2>&1 || { echo "improvement: $2: not a readings file" >&2; exit 2; }
    if [ ! -f "$file" ] || ! grep -q '^| [0-9]' "$file"; then echo "no improvements"; exit 0; fi
    grep '^| [0-9]' "$file" | while IFS='|' read -r _ d n r m b _; do
      n="$(echo "$n" | xargs)"; m="$(echo "$m" | xargs)"; b="$(echo "$b" | xargs)"; b="${b#before }"
      if [ "$m" = none ]; then echo "$n: no measure: before ${b:-not captured} / after not captured"; continue; fi
      a="$(jq -r --arg m "$m" 'if has($m) and .[$m] != null then (.[$m] | tostring) else "not captured" end' "$2")"
      echo "$n: $m: before ${b:-not captured} / after $a"
    done
    ;;
  check)
    [ $# -eq 2 ] && [ -r "$2" ] || usage
    sanitise "$2" || { echo "improvement: the scan refused the proposal; it must not leave the project" >&2; exit 6; }
    echo "clean $(sha <"$2")"
    ;;
  submit)
    [ $# -ge 2 ] && [ -r "$2" ] || usage
    prop="$2"; shift 2; approved=""
    while [ $# -gt 0 ]; do case "$1" in --approved) [ $# -ge 2 ] || usage; approved="$2"; shift 2 ;; *) usage ;; esac; done
    h="$(sha <"$prop")"
    [ -n "$approved" ] && [ "$approved" = "$h" ] || { echo "improvement: no approval for this exact text; show it to the person and submit with --approved $h only after their yes" >&2; exit 7; }
    sanitise "$prop" || { echo "improvement: the scan refused the proposal; nothing filed" >&2; exit 6; }
    repo="${FACTORY_MARKETPLACE_REPO:-WimSuenens/agent-plugins}"
    gh issue list -R "$repo" --label plugin:factory --state all --limit 1000 --json number,body >"$tmp/known.json" 2>/dev/null \
      || { echo "improvement: gh issue list failed" >&2; exit 4; }
    n="$(jq -r --arg m "<!-- factory:improvement $h -->" '[.[] | select(.body | contains($m))][0].number // empty' "$tmp/known.json")"
    [ -n "$n" ] && { echo "existing #$n"; exit 0; }
    title="$(grep -v '^[[:space:]]*#' "$prop" | grep -v '^[[:space:]]*$' | head -1 | cut -c1-100)"
    [ -n "$title" ] || title="Factory improvement proposal"
    { printf '<!-- factory:improvement %s -->\n\n' "$h"; cat "$prop"; } >"$tmp/body"
    url="$(gh issue create -R "$repo" --label plugin:factory --title "$title" --body-file "$tmp/body")" || { echo "improvement: gh issue create failed" >&2; exit 4; }
    echo "submitted $url"
    ;;
  *) usage ;;
esac
