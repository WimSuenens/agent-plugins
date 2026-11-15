#!/usr/bin/env bash
# post-file.sh: post a `work/` file as comments on a role-task ticket, so the person reads it while the item runs (#231). Lead-only: a role never runs it.
# Usage: bash post-file.sh <ticket> <file>
# What it does, in this order:
#   1. scans the file (`post-text.sh scan`: home paths and secrets). A hit posts nothing and changes nothing: the scan lines on stderr, exit 1.
#   2. cuts the file into parts of at most 60,000 bytes (the tracker's limit is 65,536 characters), at a line end, closing and reopening a code fence
#      at a cut; only a single line longer than a part is cut in the middle. Every part starts with
#        <!-- factory:artifact v1 -->
#        <!-- file: <name> part <k>/<m> -->
#      and a bold line with the name (`<name>` is the file's base name).
#   3. finds the earlier comments of the same login on the ticket with the same marker and name, and replaces them in place (PATCH), adds the parts
#      that are new, and deletes the ones a shorter file no longer needs. A re-run never adds a copy. A comment of another login is never touched.
# The file is read here; the caller never has to read it. Nothing else is posted. The role never runs this: the protocol's tracker rule is unchanged.
# Exit: 0 done; 1 a scan hit; 2 usage or an unreadable file; 3 a tracker call failed (stderr names the part).

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAP=60000
usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ $# -eq 2 ] || usage
ticket="$1"; file="$2"
case "$ticket" in '' | *[!0-9]*) usage ;; esac
[ -f "$file" ] && [ -r "$file" ] || { echo "post-file: $(basename "$file"): unreadable" >&2; exit 2; }
name="$(basename "$file")"
case "$name" in *[!A-Za-z0-9._-]*) echo "post-file: the file name may hold letters, digits, dot, dash and underscore only" >&2; exit 2 ;; esac

bash "$here/post-text.sh" scan "$file" >&2 || { rc=$?; [ "$rc" = 1 ] && exit 1; exit 2; }

work="$(mktemp -d)" || exit 2
trap 'rm -rf "${work:?}"' EXIT
m="$(LC_ALL=C awk -v cap="$CAP" -v dir="$work" '
  BEGIN { for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i; part = 1; used = 0; f = dir "/body-1" }
  function newpart() {
    if (fence != "") printf "%s\n", fch > f
    close(f); part++; f = dir "/body-" part; used = 0
    if (fence != "") { printf "%s\n", fence > f; used = length(fence) + 1 }
  }
  {
    s = $0
    base = (fence != "") ? length(fence) + 1 : 0
    while (length(s) + 1 > cap - used - 8) {
      # a whole line goes to the next part when it fits there; only a line longer than a part is cut
      if (used > base && length(s) + 1 <= cap - 8 - base) { newpart(); base = (fence != "") ? length(fence) + 1 : 0; continue }
      room = cap - used - 8 - 1
      cut = room
      while (cut > 0 && ord[substr(s, cut + 1, 1)] >= 128 && ord[substr(s, cut + 1, 1)] < 192) cut--
      if (cut < 1) { newpart(); base = (fence != "") ? length(fence) + 1 : 0; continue }
      print substr(s, 1, cut) > f; s = substr(s, cut + 1); newpart(); base = (fence != "") ? length(fence) + 1 : 0
    }
    print s > f; used += length(s) + 1
    if (match(s, /^ ? ? ?(```+|~~~+)/)) {
      t = substr(s, RSTART, RLENGTH); gsub(/^ +/, "", t)
      if (fence == "") { fence = t; fch = t }
      else if (substr(t, 1, 1) == substr(fence, 1, 1) && length(t) >= length(fence)) { fence = "" }
    }
  }
  END { close(f); print part }' "$file")" || exit 2
# an empty file is one empty part
[ -f "$work/body-1" ] || : >"$work/body-1"

k=1
while [ "$k" -le "$m" ]; do
  {
    echo "<!-- factory:artifact v1 -->"
    echo "<!-- file: $name part $k/$m -->"
    if [ "$m" -gt 1 ]; then echo "**$name** (part $k of $m)"; else echo "**$name**"; fi
    echo
    cat "$work/body-$k"
  } >"$work/part-$k.md"
  k=$((k + 1))
done

me="$(gh api user --jq .login 2>/dev/null)" || { echo "post-file: cannot read the login" >&2; exit 3; }
[ -n "$me" ] || { echo "post-file: cannot read the login" >&2; exit 3; }
gh api "repos/{owner}/{repo}/issues/$ticket/comments" --paginate >"$work/list.json" 2>"$work/err" || { echo "post-file: cannot read the comments of #$ticket ($(head -c 200 "$work/err" | tr '\n' ' '))" >&2; exit 3; }
all="$(jq -s 'add // []' "$work/list.json" 2>/dev/null)" || { echo "post-file: cannot read the comments of #$ticket" >&2; exit 3; }
# ids of our comments for this file, by part number (a CRLF body, edited on the web, reads the same)
ids="$(printf '%s' "$all" | jq -r --arg me "$me" --arg name "$name" '
  .[] | select(.user.login == $me)
      | (.body | gsub("\r"; "") | split("\n")) as $ls
      | select($ls[0] == "<!-- factory:artifact v1 -->")
      | ($ls[1] // "") as $l
      | select($l | startswith("<!-- file: " + $name + " part "))
      | select($l | test("part [0-9]+/"))
      | "\(.id) \($l | capture("part (?<k>[0-9]+)/") | .k)"')" || { echo "post-file: cannot read the comments of #$ticket" >&2; exit 3; }

k=1
while [ "$k" -le "$m" ]; do
  id="$(printf '%s\n' "$ids" | awk -v k="$k" '$2 == k { print $1; exit }')"
  if [ -n "$id" ]; then
    gh api --method PATCH "repos/{owner}/{repo}/issues/comments/$id" -F "body=@$work/part-$k.md" >/dev/null 2>"$work/err" || { echo "post-file: posting part $k failed ($(head -c 200 "$work/err" | tr '\n' ' '))" >&2; exit 3; }
  else
    gh issue comment "$ticket" --body-file "$work/part-$k.md" >/dev/null 2>"$work/err" || { echo "post-file: posting part $k failed ($(head -c 200 "$work/err" | tr '\n' ' '))" >&2; exit 3; }
  fi
  k=$((k + 1))
done
# surplus parts of an earlier, longer file
printf '%s\n' "$ids" | while read -r id pk; do
  [ -n "$id" ] || continue
  [ "$pk" -gt "$m" ] && gh api --method DELETE "repos/{owner}/{repo}/issues/comments/$id" >/dev/null 2>&1
done
exit 0
