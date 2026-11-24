#!/bin/bash
# Edits a local copy of the lead's ledger comment body (references/hansei.md, *The ledger*): file in, file out. The lead posts the result with the existing
# *Edit ledger* path; this script never calls the tracker. It replaces the hand edit that once overwrote two tables (#253).
# Usage: bash ledger.sh add-task <in> <out> --task <#n> --stage <s> --role <r> --agents <a> --waits <W1,W2|-> --peak <n|text> --result <r> --notes <text|->
#        bash ledger.sh add-wait <in> <out> --kind <k> --agent <a|-> --start <UTC> --end <UTC> --held <yes|no> --what <text>
#        bash ledger.sh add-touch <in> <out> --time <UTC> --kind <k> --what <text>
#        bash ledger.sh set-wait-end <in> <out> --id <W<n>> --end <UTC>
#        bash ledger.sh check <before> <after>
# A table is found by its `###` heading (`Tasks`, `Waits`, `Person's touches`) and its column header (first cell `#`, `Id`, `Time (UTC)`), and its rows run to the
# first line that does not start with `|`: never by a separator line, which every table has. add-task numbers the row (last number + 1); add-wait gives the next
# `W<n>` id. A row already there (same task; same wait fields; same touch) is not added again: the same call twice changes nothing.
# Before writing, <in> is copied to `<in>.bak` (the previous body), and the edit is compared with it (`check`): no table may lose a row, and the edited table
# grows by at most one. `check` does the same for any two bodies, for a hand edit. out may equal in. A cell may not hold `|` or a newline.
# Exit: 0 written (or `check` ok); 1 an edit would shrink a table (named on stderr), or set-wait-end names no such wait; 2 usage or an unreadable file or a bad cell;
#       3 no such table, or its header is not the expected one; 4 the body would exceed 60,000 bytes. On 1 to 4 nothing is written.
# bash 3.2 compatible; needs awk.

usage() { sed -n '2,/^# bash 3.2/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

# counts <file>: `<heading>\t<data rows>` for every `###` section's tables (fences skipped; header and separator are not data rows)
counts() {
  awk '
    /^(```|~~~)/ { f = !f; next }
    f { next }
    { line = $0; sub(/\r$/, "", line) }
    line ~ /^### / { h = substr(line, 5); if (!(h in c)) { c[h] = 0; ord[++n] = h }; intab = 0; next }
    line ~ /^\|/ { if (h != "") { if (intab >= 2) c[h]++; intab++ }; next }
    { intab = 0 }
    END { for (i = 1; i <= n; i++) print ord[i] "\t" c[ord[i]] }' "$1"
}

# verify <before> <after> <edited heading, or * for any growth>: 0 when no table shrank and only the edited one grew, by at most one
verify() {
  local b a rc=0 h cb ca
  b="$(counts "$1")"; a="$(counts "$2")"
  while IFS="$(printf '\t')" read -r h cb; do
    [ -n "$h" ] || continue
    ca="$(printf '%s\n' "$a" | awk -F'\t' -v h="$h" '$1 == h { print $2; exit }')"
    if [ -z "$ca" ]; then echo "ledger: table '$h' is gone ($cb rows before)" >&2; rc=1; continue; fi
    if [ "$ca" -lt "$cb" ]; then echo "ledger: table '$h' would shrink ($cb -> $ca rows)" >&2; rc=1; continue; fi
    if [ "$ca" -gt "$cb" ]; then
      if [ "$3" != "*" ] && { [ "$h" != "$3" ] || [ "$ca" -gt $((cb + 1)) ]; }; then echo "ledger: table '$h' grew ($cb -> $ca rows) beyond the edit" >&2; rc=1; fi
    fi
  done <<EOF2
$b
EOF2
  return $rc
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  check)
    [ $# -eq 2 ] && [ -r "$1" ] && [ -r "$2" ] || usage
    verify "$1" "$2" "*" || exit 1
    echo "ledger: no table lost a row"
    exit 0
    ;;
  add-task | add-wait | add-touch | set-wait-end) ;;
  *) usage ;;
esac

[ $# -ge 2 ] || usage
in="$1"; out="$2"; shift 2
[ -f "$in" ] && [ -r "$in" ] || { echo "ledger: $(basename "$in"): unreadable" >&2; exit 2; }
task=""; stage=""; role=""; agents=""; waits=""; peak=""; result=""; notes=""; kind=""; agent=""; start=""; end=""; held=""; what=""; time=""; id=""
while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || usage
  case "$1" in
    --task) task="$2" ;; --stage) stage="$2" ;; --role) role="$2" ;; --agents) agents="$2" ;; --waits) waits="$2" ;;
    --peak) peak="$2" ;; --result) result="$2" ;; --notes) notes="$2" ;; --kind) kind="$2" ;; --agent) agent="$2" ;;
    --start) start="$2" ;; --end) end="$2" ;; --held) held="$2" ;; --what) what="$2" ;; --time) time="$2" ;; --id) id="$2" ;;
    *) usage ;;
  esac
  shift 2
done
for v in "$task" "$stage" "$role" "$agents" "$waits" "$peak" "$result" "$notes" "$kind" "$agent" "$start" "$end" "$held" "$what" "$time" "$id"; do
  case "$v" in *'|'* | *$'\n'* | *$'\r'*) echo "ledger: a cell may not hold a pipe or a line break" >&2; exit 2 ;; esac
done
need() { local n; for n in "$@"; do eval "[ -n \"\${$n}\" ]" || { echo "ledger: $cmd needs --$n" >&2; exit 2; }; done; }
case "$cmd" in
  add-task) need task stage role agents waits peak result notes; case "$task" in '#'*) ;; *) task="#$task" ;; esac
    heading="Tasks"; first="#"; ncols=9; row="| @N | $task | $stage | $role | $agents | $waits | $peak | $result | $notes |" ;;
  add-wait) need kind agent start end held what; heading="Waits"; first="Id"; ncols=7; row="| @N | $kind | $agent | $start | $end | $held | $what |" ;;
  add-touch) need time kind what; heading="Person's touches"; first="Time (UTC)"; ncols=3; row="| $time | $kind | $what |" ;;
  set-wait-end) need id end; heading="Waits"; first="Id"; ncols=7; row="" ;;
esac

tmp="$(mktemp)" || exit 2
trap 'rm -f "$tmp"' EXIT
awk -v CMD="$cmd" -v HEAD="$heading" -v FIRST="$first" -v NCOLS="$ncols" -v ROW="$row" -v TASK="$task" -v ID="$id" -v END_="$end" '
  function trim(x) { gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
  function cell(l, k,   p, m) { m = split(l, p, "|"); return trim(p[k + 1]) }
  function ncells(l,   p) { return split(l, p, "|") - 2 }
  function fail(code, msg) { print "ledger: " msg > "/dev/stderr"; bad = code; exit code }
  { L[NR] = $0 }
  END {
    if (bad) exit bad
    n = NR; fence = 0; h = 0
    for (i = 1; i <= n; i++) {
      line = L[i]; sub(/\r$/, "", line)
      if (line ~ /^(```|~~~)/) { fence = !fence; continue }
      if (fence) continue
      if (line == "### " HEAD) { h = i; break }
    }
    if (!h) fail(3, "no `### " HEAD "` table in the body")
    j = h + 1
    while (j <= n && L[j] !~ /^\|/ && L[j] !~ /^### /) j++
    if (j > n || L[j] !~ /^\|/) fail(3, "`### " HEAD "` has no table")
    if (cell(L[j], 1) != FIRST || ncells(L[j]) != NCOLS) fail(3, "the `" HEAD "` table header is not the expected one (first cell `" FIRST "`, " NCOLS " columns)")
    s = j + 1
    if (s > n || L[s] !~ /^\|[ :|-]*-[ :|-]*$/) fail(3, "the `" HEAD "` table has no separator line under its header")
    k = s + 1
    while (k <= n && L[k] ~ /^\|/) k++
    # rows are s+1 .. k-1; k is the first line after the table
    max = 0; dup = 0; hit = 0
    for (r = s + 1; r < k; r++) {
      v = cell(L[r], 1); sub(/^W/, "", v); if (v + 0 > max) max = v + 0
      if (CMD == "add-task" && cell(L[r], 2) == TASK) dup = 1
      if (CMD == "set-wait-end" && cell(L[r], 1) == ID) hit = r
    }
    if (CMD == "set-wait-end") {
      if (!hit) fail(1, "no wait " ID " in the Waits table")
      m = split(L[hit], p, "|")
      p[6] = " " END_ " "
      nl = ""
      for (x = 2; x < m; x++) nl = nl "|" p[x]
      L[hit] = nl "|"
    } else {
      nr = ROW
      if (CMD == "add-task") { sub(/@N/, max + 1, nr) } else if (CMD == "add-wait") { sub(/@N/, "W" (max + 1), nr) }
      if (CMD != "add-task") {
        # a row equal to the new one in every cell but the number/id
        for (r = s + 1; r < k; r++) {
          same = 1
          first_cmp = (CMD == "add-touch") ? 1 : 2
          m1 = split(L[r], a, "|"); m2 = split(nr, b, "|")
          if (m1 != m2) continue
          for (x = first_cmp + 1; x < m1; x++) if (trim(a[x]) != trim(b[x])) same = 0
          if (same) dup = 1
        }
      }
      if (!dup) { for (x = n; x >= k; x--) L[x + 1] = L[x]; L[k] = nr; n++ }
    }
    for (i = 1; i <= n; i++) print L[i]
  }' "$in" >"$tmp"
rc=$?
[ "$rc" = 0 ] || exit "$rc"
[ "$(wc -c <"$tmp" | tr -d ' ')" -le 60000 ] || { echo "ledger: the body would exceed 60,000 bytes; stop and tell the person" >&2; exit 4; }
verify "$in" "$tmp" "$heading" || exit 1
cp "$in" "$in.bak" || exit 2
cat "$tmp" >"$out" || exit 2
echo "ledger: $cmd done ($(basename "$out"))"
exit 0
