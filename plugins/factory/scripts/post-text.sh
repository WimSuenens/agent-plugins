#!/usr/bin/env bash
# The text the lead posts to the tracker: scan it, render a result into a closing comment, elide long blocks, split a long comment.
# Usage: bash post-text.sh scan [--needs-you] <file>...
#        bash post-text.sh render <draft-result> <out>
#        bash post-text.sh elide <in> <out> <ref> [--max <bytes>]
#        bash post-text.sh split <in> <outdir>
# scan: prints "scan: <basename>:<line>: home-path | secret | work-path" per hit; it never prints the text itself.
#       --needs-you also flags a path under work/<n>, work/frontier-<n>, work/settle-<n> and a branch item/<n>, frontier/<n> or settle/<n>.
#       A canary self-check runs first; a canary that does not hit prints "scan: self-check failed (<name>)" on stderr and exits 2.
# render: marker, Status, Abnormality and Summary visible, every other field of the draft inside one <details>, byte for byte.
# elide: replaces each fenced block over --max bytes (default 20000) by one line naming <ref>; prints the number of blocks elided.
# split: writes part-1.md .. part-<m>.md (each at most 60000 bytes) into <outdir> and prints <m>; an over-long line is cut (one newline added) and reported on stderr.
# Exit: scan 0 clean, 1 a hit, 2 usage or a file unreadable; render 0, 3 no Status or Summary or Summary over 10 lines; elide 0; split 0, 4 Status and Summary alone exceed the cap.
# No network; no write outside the named output paths.
# See contracts/64-role-tasks.md sections 5, 6 and 9 in the repo that hosts the factory.

CAP=60000

# awk_operand <path>: a relative path gets ./ so awk reads name=value as a file, not as a variable assignment; an absolute path and - stay.
awk_operand() {
  case "$1" in /* | -) printf '%s' "$1" ;; *) printf './%s' "$1" ;; esac
}

usage() {
  echo "usage: post-text.sh scan [--needs-you] <file>... | render <draft> <out> | elide <in> <out> <ref> [--max <bytes>] | split <in> <outdir>" >&2
  exit 2
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  scan)
    needs=0
    if [ "${1:-}" = "--needs-you" ]; then needs=1; shift; fi
    [ $# -ge 1 ] || usage
    # B: the left boundary; T: the token class. Every prefix is preceded by B. Plain grep -E, no awk intervals.
    B='(^|[^A-Za-z0-9_-])'
    T='[A-Za-z0-9_-]'
    SN=(github github-pat aws slack openai-style google npm gitlab jwt private-key bearer)
    SP=(
      "${B}(ghp|gho|ghs|ghu|ghr)_${T}{20,}"
      "${B}github_pat_${T}{20,}"
      "${B}AKIA[A-Z0-9]{16}"
      "${B}xox[abprs]-${T}{10,}"
      "${B}sk-${T}{20,}"
      "${B}AIza[0-9A-Za-z_-]{35}"
      "${B}npm_[A-Za-z0-9]{36}"
      "${B}glpat-${T}{20,}"
      "${B}eyJ${T}{10,}\\.eyJ${T}{10,}\\.${T}{10,}"
      "-----BEGIN [A-Z ]*PRIVATE KEY-----"
      "Bearer [A-Za-z0-9._~+/=-]{20,}"
    )
    # one fake token per row, assembled from two halves so this file is no hit when scanned
    n20=aaaaaaaaaaaaaaaaaaaaaaaaa
    CAN=(
      "gh""p_${n20}"
      "github""_pat_${n20}"
      "AK""IAABCDEFGHIJKLMNOP"
      "xo""xb-${n20}"
      "s""k-${n20}"
      "AI""zaAbCdEfGhIjKlMnOpQrStUvWxYz012345678"
      "np""m_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789"
      "glp""at-${n20}"
      "ey""Jaaaaaaaaaaa.ey""Jaaaaaaaaaaa.aaaaaaaaaaaa"
      "-----BEGIN ""RSA PRIVATE KEY-----"
      "Bear""er ${n20}"
    )
    HOMEP=(
      '(^|[^A-Za-z0-9_.~-])/Us''ers/[^/ '"$(printf '\t')"']+'
      '(^|[^A-Za-z0-9_.~-])/ho''me/[^/ '"$(printf '\t')"']+'
      '(^|[^A-Za-z0-9_.~-])/ro''ot/'
      '[A-Za-z]:[\\/][Uu]sers[\\/][^\\/ '"$(printf '\t')"']+'
    )
    HOMEC=("/Us""ers/someone/x" "/ho""me/someone/x" "/ro""ot/x" 'C:\Us''ers\someone')
    i=0
    while [ $i -lt ${#SP[@]} ]; do
      if ! printf '%s\n' "${CAN[$i]}" | LC_ALL=C grep -Eq -e "${SP[$i]}"; then
        echo "scan: self-check failed (${SN[$i]})" >&2
        exit 2
      fi
      i=$((i + 1))
    done
    i=0
    while [ $i -lt ${#HOMEP[@]} ]; do
      if ! printf '%s\n' "${HOMEC[$i]}" | LC_ALL=C grep -Eq -e "${HOMEP[$i]}"; then
        echo "scan: self-check failed (home-path)" >&2
        exit 2
      fi
      i=$((i + 1))
    done
    rc=0
    for f in "$@"; do
      if [ ! -f "$f" ] || [ ! -r "$f" ]; then
        echo "scan: $(basename "$f"): unreadable" >&2
        rc=2
        continue
      fi
      b="$(basename "$f")"
      hits=""
      for p in "${HOMEP[@]}"; do
        hits="$hits$(LC_ALL=C grep -En -e "$p" "$f" | cut -d: -f1 | sed 's/$/ home-path/')"$'\n'
      done
      for p in "${SP[@]}"; do
        hits="$hits$(LC_ALL=C grep -En -e "$p" "$f" | cut -d: -f1 | sed 's/$/ secret/')"$'\n'
      done
      if [ "$needs" = 1 ]; then
        for p in '(^|[^A-Za-z0-9_])work/([0-9]|frontier-[0-9]|settle-[0-9])' '(^|[^A-Za-z0-9_])(item|frontier|settle)/[0-9]+'; do
          hits="$hits$(LC_ALL=C grep -En -e "$p" "$f" | cut -d: -f1 | sed 's/$/ work-path/')"$'\n'
        done
      fi
      # one line per (line number, kind), ordered by line number then home-path, secret, work-path
      hits="$(printf '%s' "$hits" | grep -v '^$' | awk '{ k = ($2 == "home-path") ? 1 : ($2 == "secret") ? 2 : 3; print $1, k, $2 }' | sort -n -u -k1,1 -k2,2 | awk -v b="$b" '{ print "scan: " b ":" $1 ": " $3 }')"
      if [ -n "$hits" ]; then
        printf '%s\n' "$hits"
        [ "$rc" = 0 ] && rc=1
      fi
    done
    exit "$rc"
    ;;

  render)
    [ $# -eq 2 ] || usage
    draft="$1"
    out="$2"
    [ -f "$draft" ] && [ -r "$draft" ] || { echo "render: $(basename "$draft"): unreadable" >&2; exit 2; }
    tmpf="$(mktemp)" || exit 2
    trap 'rm -f "$tmpf"' EXIT
    LC_ALL=C awk '
      function flush(   i, t) {
        if (cur == "") return
        t = txt
        sub(/\n+$/, "", t)
        body[cur] = t
        cur = ""; txt = ""
      }
      BEGIN { split("Status|Abnormality|Progress|Summary|Artifacts|Decisions|Open questions|Missing|Decision card", order, "|"); no = 9 }
      {
        key = ""
        for (i = 1; i <= no; i++) {
          k = order[i] ":"
          if (substr($0, 1, length(k)) == k) { key = order[i]; break }
        }
        if (key != "") { flush(); cur = key; txt = $0 "\n"; next }
        if (cur != "") txt = txt $0 "\n"
      }
      END {
        flush()
        if (!("Status" in body) || !("Summary" in body)) exit 3
        n = split(body["Summary"], sl, "\n")
        if (n > 10) exit 3
        print "<!-- factory:result v1 -->"
        print body["Status"]
        if ("Abnormality" in body) print body["Abnormality"]
        print body["Summary"]
        more = 0
        for (i = 1; i <= no; i++) { k = order[i]; if (k != "Status" && k != "Abnormality" && k != "Summary" && (k in body)) more = 1 }
        if (more) {
          print ""
          print "<details>"
          print "<summary>Details</summary>"
          print ""
          for (i = 1; i <= no; i++) {
            k = order[i]
            if (k != "Status" && k != "Abnormality" && k != "Summary" && (k in body)) print body[k]
          }
          print ""
          print "</details>"
        }
      }' "$(awk_operand "$draft")" >"$tmpf"
    rc=$?
    if [ "$rc" != 0 ]; then
      echo "render: $(basename "$draft"): needs Status and a Summary of at most 10 lines" >&2
      exit 3
    fi
    cat "$tmpf" >"$out" || exit 2
    exit 0
    ;;

  elide)
    [ $# -ge 3 ] || usage
    in="$1"
    out="$2"
    ref="$3"
    shift 3
    max=20000
    if [ "${1:-}" = "--max" ]; then
      max="${2:-}"
      case "$max" in '' | *[!0-9]*) usage ;; esac
      shift 2
    fi
    [ -f "$in" ] && [ -r "$in" ] || { echo "elide: $(basename "$in"): unreadable" >&2; exit 2; }
    tmpf="$(mktemp)" || exit 2
    trap 'rm -f "$tmpf"' EXIT
    count="$(LC_ALL=C awk -v max="$max" -v ref="$ref" -v outf="$tmpf" '
      function flushblock(   i) {
        if (bytes > max) { print "[block of " (nb - 2 < 0 ? 0 : nb - 2) " lines omitted; see " ref "]" > outf; elided++ }
        else for (i = 1; i <= nb; i++) print blk[i] > outf
        inblock = 0; nb = 0; bytes = 0
      }
      {
        if (!inblock) {
          if (match($0, /^ ? ? ?(```+|~~~+)/)) {
            s = substr($0, RSTART, RLENGTH); gsub(/^ +/, "", s)
            fch = substr(s, 1, 1); flen = length(s)
            inblock = 1; nb = 1; blk[1] = $0; bytes = length($0) + 1
            next
          }
          print $0 > outf
          next
        }
        blk[++nb] = $0; bytes += length($0) + 1
        if (match($0, /^ ? ? ?(```+|~~~+) *$/)) {
          s = substr($0, RSTART, RLENGTH); gsub(/^ +| +$/, "", s)
          if (substr(s, 1, 1) == fch && length(s) >= flen) flushblock()
        }
      }
      END { if (inblock) flushblock(); print elided + 0 }' "$(awk_operand "$in")")" || exit 2
    cat "$tmpf" >"$out" || exit 2
    printf '%s\n' "$count"
    exit 0
    ;;

  split)
    [ $# -eq 2 ] || usage
    in="$1"
    dir="$2"
    [ -f "$in" ] && [ -r "$in" ] || { echo "split: $(basename "$in"): unreadable" >&2; exit 2; }
    [ -d "$dir" ] || mkdir -p "$dir" || exit 2
    total="$(wc -c <"$in" | tr -d ' ')"
    if [ "$total" -le "$CAP" ]; then
      cat "$in" >"$dir/part-1.md" || exit 2
      echo 1
      exit 0
    fi
    LC_ALL=C awk -v cap="$CAP" -v dir="$dir" '
      BEGIN { for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i }
      { line[NR] = $0 }
      END {
        n = NR
        # header: the lines before the first <details> line; body: between the summary and the blank before </details>
        d = 0; for (i = 1; i <= n; i++) if (line[i] == "<details>") { d = i; break }
        if (d == 0) exit 4
        e = 0; for (i = n; i >= 1; i--) if (line[i] == "</details>") { e = i; break }
        if (e == 0) exit 4
        bs = d + 2; if (line[bs] == "") bs++        # first body line
        be = e - 1; if (be >= bs && line[be] == "") be--
        hbytes = 0
        for (i = 2; i < d; i++) hbytes += length(line[i]) + 1      # Status, Abnormality, Summary and the blank
        # worst-case widths: parts count 999, comment id 20 digits
        o1 = length("<!-- factory:result v1 -->") + 1 + length("<!-- factory:parts 999 -->") + 1 + hbytes + length("<details>") + 1 + length("<summary>Details</summary>") + 1 + 1 + 1 + length("</details>") + 1
        ok = length("<!-- factory:result-cont v1 of=00000000000000000000 part=999/999 -->") + 1 + length("<details><summary>Details, part 999 of 999</summary>") + 1 + 1 + 1 + length("</details>") + 1
        b1 = cap - o1; bk = cap - ok
        if (b1 < 200) exit 4
        m = 1; cb = b1; used = 0; text[1] = ""
        for (i = bs; i <= be; i++) {
          s = line[i]
          pieces = 1
          while (length(s) + 1 > cb - used) {
            # the line does not fit in what is left of this part
            if (used > 0 && length(s) + 1 <= bk) { m++; cb = bk; used = 0; text[m] = ""; continue }
            room = cb - used - 1
            if (room < 1) { m++; cb = bk; used = 0; text[m] = ""; continue }
            cut = room
            while (cut > 0 && (ord[substr(s, cut + 1, 1)] >= 128 && ord[substr(s, cut + 1, 1)] < 192)) cut--
            if (cut == 0) { m++; cb = bk; used = 0; text[m] = ""; continue }
            text[m] = text[m] substr(s, 1, cut) "\n"
            s = substr(s, cut + 1)
            pieces++
            m++; cb = bk; used = 0; text[m] = ""
          }
          text[m] = text[m] s "\n"
          used += length(s) + 1
          if (pieces > 1) print "split: details line " (i - bs + 1) " cut into " pieces " pieces" > "/dev/stderr"
        }
        # write the parts
        f1 = dir "/part-1.md"
        print "<!-- factory:result v1 -->" > f1
        print "<!-- factory:parts " m " -->" > f1
        for (i = 2; i < d; i++) print line[i] > f1
        print "<details>" > f1
        print "<summary>Details</summary>" > f1
        print "" > f1
        printf "%s", text[1] > f1
        print "" > f1
        print "</details>" > f1
        close(f1)
        for (k = 2; k <= m; k++) {
          fk = dir "/part-" k ".md"
          print "<!-- factory:result-cont v1 of=FIRST part=" k "/" m " -->" > fk
          print "<details><summary>Details, part " k " of " m "</summary>" > fk
          print "" > fk
          printf "%s", text[k] > fk
          print "" > fk
          print "</details>" > fk
          close(fk)
        }
        print m
      }' "$(awk_operand "$in")"
    rc=$?
    if [ "$rc" = 4 ]; then
      echo "split: Status and Summary alone exceed the cap" >&2
      exit 4
    fi
    exit "$rc"
    ;;
  *)
    usage
    ;;
esac
