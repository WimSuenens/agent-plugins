#!/usr/bin/env bash
# Idea intake: the inbox folder, filing an idea, and recording a triage outcome.
# Usage: bash intake.sh dir
#        bash intake.sh init
#        bash intake.sh file <title> [<body-file>]
#        bash intake.sh drop
#        bash intake.sh untriaged
#        bash intake.sh triage <issue> <outcome> <reason-file>
#        bash intake.sh filed-since <start> [<end>] [--state open|all] [--line]
# dir: prints the inbox folder, relative to the main checkout (.claude/factory-inbox).
# init: creates the inbox folder and adds /.claude/factory-inbox/ to the main checkout's .gitignore; prints "created" or
#      "already present" and changes nothing the second time. Setup runs it only after the person said yes.
# file: files one idea as a tracker issue with the label `idea`; prints the issue URL. The body is the file ('-' reads stdin).
# drop: turns each regular file of the inbox into one tracker issue (label `idea`) and removes the file once the issue exists
#      (or is found: the issue body carries <!-- factory:inbox <sha256 of the file> -->, so a file is never filed twice).
#      A file holding one URL becomes a reference; any other text file (no NUL byte, at most 60000 bytes) goes into the body.
#      A file the body cannot carry (binary, too large, a symlink) or that the scan refuses stays in the folder and is reported;
#      nothing is deleted that did not reach the tracker. Dotfiles are ignored. One line per file on stdout:
#      "created <url> <name>", "existing #<n> <name>" or "kept <name>: <reason>".
# untriaged: lists open `idea` issues without an outcome comment of the lead, one "<n><TAB><title><TAB><new|waiting>" per line;
#      "waiting" is an idea whose decision card (needs-you comment) is open and not yet marked "Answered:".
# filed-since: issues filed from <start> (UTC, `YYYY-MM-DDTHH:MM:SSZ`) to <end> (default: now), counted from two sources and nothing else:
#      (a) issues carrying the project's own triage label, read from the `needs-triage` row of `docs/agents/triage-labels.md` (the second
#      cell; the role name in the first cell is the vocabulary's, the label string is the project's), and (b) issues whose body carries the
#      marker `<!-- factory:improvement `. One `<n><TAB><title><TAB><label|marker|label+marker>` per issue, oldest first; an issue with both
#      is listed once. `--state open` (default) lists open issues, `all` also closed ones. `--line` prints one line for a stage boundary:
#      `new issues since <start>: <k> open: #<n> <title>; ... (sources: ...)` or `... : none (sources: ...)`. Without the table only the
#      marker is counted and the line says so. Reads and ingests nothing else; an issue filed under neither source is not seen.
#      The report is provisional: revisit after two runs, or when a report says nothing new more than once.
# triage: posts the outcome comment <!-- factory:triage v1 --> on the issue. <outcome> is one of direction, slice-candidate,
#      research-ticket, parked, rejected; <reason-file> holds the reason and must not be empty. A rejected idea is closed as
#      not planned. The reason is scanned first (post-text.sh scan).
# Exit: 0 ok; 2 usage, a bad outcome, an empty reason, or not a git repository; 3 no sha256 tool; 4 a gh call failed (message on
#       stderr); 5 drop: at least one file was kept; 6 a text the scan refused (file, triage).
# See contracts/110-idea-intake.md in the repo that hosts the factory.

folder=".claude/factory-inbox"
cap=60000
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-}"

main_checkout() {
  git worktree list --porcelain 2>/dev/null | while IFS= read -r l; do
    case "$l" in "worktree "*) printf '%s\n' "${l#worktree }"; break ;; esac
  done
}

usage() {
  echo "usage: intake.sh dir | init | file <title> [<body-file>] | drop | untriaged | triage <issue> <outcome> <reason-file> | filed-since <start> [<end>] [--state open|all] [--line]" >&2
  exit 2
}

if command -v sha256sum >/dev/null 2>&1; then
  sha() { sha256sum | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sha() { shasum -a 256 | cut -d' ' -f1; }
else
  sha() { :; }
  no_sha=1
fi

[ "$cmd" = dir ] && { echo "$folder"; exit 0; }
case "$cmd" in init | file | drop | untriaged | triage | filed-since) ;; *) usage ;; esac

main="$(main_checkout)"
[ -n "$main" ] || { echo "intake: not a git repository" >&2; exit 2; }
inbox="$main/$folder"

ensure_label() {
  gh label create idea --description "An idea or reference for the factory to triage" >/dev/null 2>&1 || true
}

# create_issue <title> <body-file>: prints the URL; exit 4 on failure
create_issue() {
  local url
  url="$(gh issue create --title "$1" --label idea --body-file "$2")" || { echo "intake: gh issue create failed" >&2; return 4; }
  printf '%s\n' "$url"
}

case "$cmd" in
  init)
    status=created
    [ -d "$inbox" ] && status="already present"
    mkdir -p "$inbox" || exit 2
    gi="$main/.gitignore"
    if ! { [ -f "$gi" ] && grep -Eqx '/?\.claude/factory-inbox/?' "$gi"; }; then
      if [ -s "$gi" ] && [ -n "$(tail -c 1 "$gi")" ]; then printf '\n' >>"$gi"; fi
      printf '/%s/\n' "$folder" >>"$gi"
      [ "$status" = "already present" ] && status="created"
    fi
    echo "$status"
    ;;

  file)
    title="${2:-}"; src="${3:-}"
    [ -n "$title" ] || usage
    tmp="$(mktemp)" || exit 2
    trap 'rm -f "$tmp"' EXIT
    { printf '<!-- factory:idea -->\n'; if [ -n "$src" ]; then cat -- "$src" 2>/dev/null || { echo "intake: cannot read $src" >&2; exit 2; }; fi; } >"$tmp"
    printf '%s\n' "$title" >"$tmp.t"
    trap 'rm -f "$tmp" "$tmp.t"' EXIT
    bash "$here/post-text.sh" scan "$tmp" "$tmp.t" >&2 || { echo "intake: the scan refused the idea; nothing filed" >&2; exit 6; }
    ensure_label
    create_issue "$title" "$tmp" || exit 4
    ;;

  drop)
    [ -z "${no_sha:-}" ] || { echo "intake: no sha256 tool" >&2; exit 3; }
    [ -d "$inbox" ] || exit 0
    tmp="$(mktemp -d)" || exit 2
    trap 'rm -rf "$tmp"' EXIT
    listed=0; kept=0; labelled=0
    for f in "$inbox"/*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      name="${f##*/}"
      if [ -L "$f" ] || [ ! -f "$f" ]; then echo "kept $name: not a regular file"; kept=1; continue; fi
      size="$(wc -c <"$f" | tr -d ' ')"
      if [ "$size" -gt "$cap" ]; then echo "kept $name: over $cap bytes; put a link in a file instead"; kept=1; continue; fi
      if [ "$(LC_ALL=C tr -d '\000' <"$f" | wc -c | tr -d ' ')" != "$size" ]; then
        echo "kept $name: not a text file; host it and drop a file holding its link"; kept=1; continue
      fi
      h="$(sha <"$f")"
      if [ "$listed" = 0 ]; then
        gh issue list --label idea --state all --limit 1000 --json number,body >"$tmp/known.json" 2>"$tmp/err" \
          || { echo "intake: gh issue list failed" >&2; exit 4; }
        listed=1
      fi
      n="$(jq -r --arg m "<!-- factory:inbox $h -->" '[.[] | select(.body | contains($m)) | .number][0] // empty' "$tmp/known.json")"
      if [ -n "$n" ]; then rm -f -- "$f"; echo "existing #$n $name"; continue; fi
      first="$(grep -m1 -v '^[[:space:]]*$' "$f" | sed 's/^[[:space:]#]*//;s/[[:space:]]*$//')"
      nonblank="$(grep -c -v '^[[:space:]]*$' "$f")"
      case "$first" in
        http://* | https://*) [ "$nonblank" = 1 ] && is_url=1 || is_url=0 ;;
        *) is_url=0 ;;
      esac
      [ -n "$first" ] || first="$name"
      title="$(printf '%s' "$first" | cut -c 1-80)"
      {
        printf '<!-- factory:inbox %s -->\n' "$h"
        printf 'Dropped in the inbox as `%s`.\n\n' "$name"
        if [ "$is_url" = 1 ]; then printf 'Reference: %s\n' "$first"; else cat -- "$f"; fi
      } >"$tmp/body"
      printf '%s\n' "$title" >"$tmp/title"
      if ! bash "$here/post-text.sh" scan "$tmp/body" "$tmp/title" >"$tmp/scan" 2>&1; then
        echo "kept $name: the scan refused it ($(tr '\n' ' ' <"$tmp/scan" | sed 's/ *$//')); clean the file and drop it again"; kept=1; continue
      fi
      [ "$labelled" = 1 ] || { ensure_label; labelled=1; }
      url="$(create_issue "$title" "$tmp/body")" || exit 4
      jq --arg m "<!-- factory:inbox $h -->" --argjson n "${url##*/}" '. + [{number: $n, body: $m}]' "$tmp/known.json" >"$tmp/known.new" 2>/dev/null && mv "$tmp/known.new" "$tmp/known.json"
      rm -f -- "$f"
      echo "created $url $name"
    done
    [ "$kept" = 0 ] || exit 5
    ;;

  untriaged)
    me="$(gh api user --jq .login)" || { echo "intake: gh api user failed" >&2; exit 4; }
    list="$(gh issue list --label idea --state open --limit 1000 --json number,title,comments)" \
      || { echo "intake: gh issue list failed" >&2; exit 4; }
    printf '%s' "$list" | jq -r --arg me "$me" '.[]
          | (.comments // []) as $c
          | [ $c[] | select(.author.login == $me) | .body ] as $mine
          | select(all($mine[]; startswith("<!-- factory:triage ") | not))
          | [ .number, .title, (if any($mine[]; startswith("<!-- factory:needs-you v1 -->") and (contains("\nAnswered:") | not)) then "waiting" else "new" end) ] | @tsv'
    ;;

  filed-since)
    shift; start=""; end=""; state=open; line=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --state) state="${2:-}"; shift 2 || usage ;;
        --line) line=1; shift ;;
        -*) usage ;;
        *) if [ -z "$start" ]; then start="$1"; elif [ -z "$end" ]; then end="$1"; else usage; fi; shift ;;
      esac
    done
    case "$state" in open | all) ;; *) usage ;; esac
    ts='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
    printf '%s' "$start" | grep -Eq "$ts" || usage
    [ -n "$end" ] || end="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s' "$end" | grep -Eq "$ts" || usage
    label=""
    tbl="$main/docs/agents/triage-labels.md"
    [ ! -f "$tbl" ] || label="$(awk -F'|' '{ a=$2; gsub(/[ `]/,"",a); if (a=="needs-triage") { b=$3; gsub(/[ `]/,"",b); print b; exit } }' "$tbl")"
    if [ -n "$label" ]; then src="label $label, marker factory:improvement"; else
      src="marker factory:improvement only, no docs/agents/triage-labels.md"
      [ -f "$tbl" ] && src="marker factory:improvement only, no triage label row in docs/agents/triage-labels.md"
      echo "intake: $src" >&2
    fi
    list="$(gh issue list --state all --limit 1000 --search "created:>=${start%%T*}" --json number,title,createdAt,state,labels,body)" \
      || { echo "intake: gh issue list failed" >&2; exit 4; }
    cut=""
    if [ "$(printf '%s' "$list" | jq 'length' 2>/dev/null)" -ge 1000 ] 2>/dev/null; then
      cut="; list cut at 1000: the count is a lower bound"; echo "intake: the issue list was cut at 1000 issues: the count is a lower bound" >&2
    fi
    rows="$(printf '%s' "$list" | jq -r --arg s "$start" --arg e "$end" --arg l "$label" --arg st "$state" '
        [ .[] | select(.createdAt >= $s and .createdAt <= $e)
          | select($st == "all" or (.state | ascii_downcase) == "open")
          | ((($l != "") and (any(.labels[]?; .name == $l))) as $a
             | ((.body // "") | contains("<!-- factory:improvement ")) as $b
             | select($a or $b) | [ .number, .title, (if $a and $b then "label+marker" elif $a then "label" else "marker" end) ]) ]
        | sort_by(.[0])[] | @tsv')" || { echo "intake: cannot read the issue list" >&2; exit 4; }
    if [ "$line" = 0 ]; then [ -z "$rows" ] || printf '%s\n' "$rows"; exit 0; fi
    [ "$state" = open ] && what=" open" || what=""
    src="$src$cut"
    if [ -z "$rows" ]; then printf 'new issues since %s: none (sources: %s)\n' "$start" "$src"; exit 0; fi
    k="$(printf '%s\n' "$rows" | wc -l | tr -d ' ')"
    items="$(printf '%s\n' "$rows" | awk -F'\t' '{ printf "#%s %s; ", $1, $2 }' | sed 's/; $//')"
    printf 'new issues since %s: %s%s: %s (sources: %s)\n' "$start" "$k" "$what" "$items" "$src"
    ;;

  triage)
    n="${2:-}"; outcome="${3:-}"; rf="${4:-}"
    case "$n" in '' | *[!0-9]*) usage ;; esac
    case "$outcome" in direction | slice-candidate | research-ticket | parked | rejected) ;; *)
      echo "intake: outcome must be direction, slice-candidate, research-ticket, parked or rejected" >&2; exit 2 ;; esac
    [ -f "$rf" ] && [ -n "$(tr -d '[:space:]' <"$rf")" ] || { echo "intake: the reason is missing or empty" >&2; exit 2; }
    tmp="$(mktemp)" || exit 2
    trap 'rm -f "$tmp"' EXIT
    { printf '<!-- factory:triage v1 -->\n## Triage: %s\n\n**Outcome:** %s\n\n**Reason:** ' "$outcome" "$outcome"; cat -- "$rf"; printf '\n'; } >"$tmp"
    bash "$here/post-text.sh" scan "$tmp" >&2 || { echo "intake: the scan refused the reason; nothing posted" >&2; exit 6; }
    gh issue comment "$n" --body-file "$tmp" >/dev/null || { echo "intake: gh issue comment failed" >&2; exit 4; }
    if [ "$outcome" = rejected ]; then
      gh issue close "$n" --reason "not planned" >/dev/null || { echo "intake: gh issue close failed" >&2; exit 4; }
    fi
    echo "triaged #$n $outcome"
    ;;
esac
