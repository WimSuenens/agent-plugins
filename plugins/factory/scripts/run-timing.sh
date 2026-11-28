#!/bin/bash
# The run's timing at its close (#286; references/hansei.md section 8, references/run-close-run.md step 9.2).
# Usage: bash run-timing.sh gaps --run-body <body file> --close <UTC> [--ledger <file>]... [--] <cut-offs output file | ->
#        bash run-timing.sh line --run-body <body file> --close <UTC> [--lite] [--ledger <file>]...
# <body file>: the run ticket's body (its `## Factory run` section: `started:`, `closed in this run`, `in flight`, the `### Run waits` table).
# --ledger: one item's ledger comment body (`## Ledger: #<n> <title>`), one per item of the run (the `#<n>` of `closed in this run` and `in flight`).
# --close: the close instant, YYYY-MM-DDTHH:MMZ or YYYY-MM-DDTHH:MM:SS[.fff]Z (the A3 comment's created_at, or the close stamp).
# Every time is cut to the minute. The run window is [started, close); an item is in flight from its ledger's `started:` to the time of the last
#   `approval` row of its Person's touches (the close when it has none), clipped to the run window.
# gaps: the run-close scan. Each line of cut-offs.sh output (<basename> <kind> <start> <end | open> <markers>; markers ^[a-z_:-]+(,[a-z_:-]+)*$), clipped to the run window and with
#   every item's in-flight window removed, prints one line per stretch left: <kind>\t<start>\t<end>\tfound at close: <markers> (times
#   YYYY-MM-DDTHH:MMZ); each is one `run-state.sh add-run-wait`. A line that leaves nothing is named on stderr (`inside items: …` or
#   `outside the run: …`).
# line: prints the A3's line `- run timing: raw <dur>; adjusted <dur>; blocked: person <dur>, limits <dur>, stalled <dur>, interrupted <dur>`.
#   A minute with an item in flight is blocked when every item in flight has a held wait (`Held item` yes, kind person, limits, stalled or
#   interrupted) over it; a minute with none is blocked when a Run waits row covers it. Its kind is the first of person, limits, stalled,
#   interrupted among those waits. --lite: stalled, interrupted and adjusted read `not captured (lite)`.
#   Not captured, all or nothing: `- run timing: not captured (<reason>)` (gaps: the reason on stderr).
# A pure function of its arguments: reads no clock, writes no file, calls no network and reads no line of docs/agents/factory.md.
# Exit: 0 printed; 1 the body has no Factory run section; 2 usage, an unreadable file, a time not in the format, close before started, a cut-offs
#       line not in its format, a ledger whose item is not an item of the run; 4 the run moved to a map; 5 not captured (line: the line on stdout).

usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ $# -ge 1 ] || usage
cmd="$1"; shift
case "$cmd" in gaps | line) ;; *) usage ;; esac

body=""; close=""; lite=0; co=""; nled=0
ledgers=()
while [ $# -gt 0 ]; do
  case "$1" in
    --run-body) [ $# -ge 2 ] || usage; body="$2"; shift 2 ;;
    --close) [ $# -ge 2 ] || usage; close="$2"; shift 2 ;;
    --ledger) [ $# -ge 2 ] || usage; ledgers[$nled]="$2"; nled=$((nled + 1)); shift 2 ;;
    --lite) [ "$cmd" = line ] || usage; lite=1; shift ;;
    --) shift; [ "$cmd" = gaps ] && [ $# -eq 1 ] || usage; co="$1"; shift ;;
    -) [ "$cmd" = gaps ] && [ $# -eq 1 ] || usage; co="$1"; shift ;;
    -*) usage ;;
    *) [ "$cmd" = gaps ] && [ $# -eq 1 ] || usage; co="$1"; shift ;;
  esac
done
[ -n "$body" ] && [ -n "$close" ] || usage
[ "$cmd" = line ] || [ -n "$co" ] || usage

readable() { [ -f "$1" ] && [ -r "$1" ] || { echo "run-timing: $1: unreadable" >&2; exit 2; }; }
argpath() { case "$1" in - | /*) printf '%s' "$1" ;; *) printf './%s' "$1" ;; esac; } # ./ keeps awk from reading name=value as an assignment
readable "$body"
if [ "$co" != "" ] && [ "$co" != - ]; then readable "$co"; fi

# the run section, as run-state.sh reads it
moved="$(tr -d '\r' <"$body" | sed -n 's/^Factory run: moved to \(#[0-9][0-9]*\)[[:space:]]*$/\1/p' | head -1)"
if ! tr -d '\r' <"$body" | grep -q '^## Factory run[[:space:]]*$'; then
  [ -n "$moved" ] && { echo "run-timing: the run moved to $moved: read the body of $moved" >&2; exit 4; }
  echo "run-timing: $body has no Factory run section" >&2; exit 1
fi

# each ledger names its item; one ledger per item
lednums=""
i=0
while [ $i -lt $nled ]; do
  f="${ledgers[$i]}"; readable "$f"
  n="$(tr -d '\r' <"$f" | sed -n 's/^## Ledger: #\([0-9][0-9]*\)\([[:space:]].*\)\{0,1\}$/\1/p' | head -1)"
  [ -n "$n" ] || { echo "run-timing: $f: not a ledger (no \`## Ledger: #<n>\` line)" >&2; exit 2; }
  case " $lednums " in *" $n "*) echo "run-timing: two ledgers of #$n" >&2; exit 2 ;; esac
  lednums="${lednums:+$lednums }$n"
  i=$((i + 1))
done

args=("$(argpath "$body")")
i=0
while [ $i -lt $nled ]; do args[$((i + 1))]="$(argpath "${ledgers[$i]}")"; i=$((i + 1)); done
[ "$cmd" = gaps ] && args[$((nled + 1))]="$(argpath "$co")"

LC_ALL=C awk -v cmd="$cmd" -v closearg="$close" -v lite="$lite" -v nled="$nled" -v lednums="$lednums" '
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function days(y, m, d,   era, yoe, doy, doe) {
  y -= (m <= 2); era = int((y >= 0 ? y : y - 399) / 400); yoe = y - era * 400
  doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
  doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
  return era * 146097 + doe - 719468
}
# tmin: minutes since the epoch, cut to the minute; -1 when not a time. A leading ~ is dropped.
function tmin(s,   t, mo, d, h, mi) {
  t = trim(s); sub(/^~/, "", t)
  if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9](:[0-9][0-9](\.[0-9]+)?)?Z$/) return -1
  mo = substr(t, 6, 2) + 0; d = substr(t, 9, 2) + 0; h = substr(t, 12, 2) + 0; mi = substr(t, 15, 2) + 0
  if (mo < 1 || mo > 12 || d < 1 || d > 31 || h > 23 || mi > 59) return -1
  return days(substr(t, 1, 4) + 0, mo, d) * 1440 + h * 60 + mi
}
function tfmt(m,   z, era, doe, yoe, y, doy, mp, d, mo, r) {
  r = m % 1440; z = (m - r) / 1440 + 719468
  era = int((z >= 0 ? z : z - 146096) / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
  y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100)); mp = int((5 * doy + 2) / 153)
  d = doy - int((153 * mp + 2) / 5) + 1; mo = mp + (mp < 10 ? 3 : -9); y += (mo <= 2)
  return sprintf("%04d-%02d-%02dT%02d:%02dZ", y, mo, d, int(r / 60), r % 60)
}
function dur(n) { return (n >= 60) ? sprintf("%dh%02dm", int(n / 60), n % 60) : sprintf("%dm", n) }
function iskind(k) { return (k == "person" || k == "limits" || k == "stalled" || k == "interrupted") }
function sep(c) { return (c ~ /^:?-+:?$/) }
function nums(v, arr,   n, t) { # the #<n> tokens at the start or after ", "
  n = 0
  while (match(v, /(^|, )#[0-9]+/)) {
    t = substr(v, RSTART, RLENGTH); sub(/^, /, "", t); sub(/^#/, "", t)
    arr[++n] = t; v = substr(v, RSTART + RLENGTH)
  }
  return n
}
function fail(code, msg) { print "run-timing: " msg > "/dev/stderr"; err = code; exit code }
function notcap(why) {
  if (cmd == "line") print "- run timing: not captured (" why ")"
  else print "not captured (" why ")" > "/dev/stderr"
  err = 5; exit 5
}
BEGIN {
  FS = "\n"; fi = 0; curf = "\001"
  nk = split("person limits stalled interrupted", KO, " ")
  for (j = 1; j <= nk; j++) KR[KO[j]] = j
  split(lednums, LN, " ")
}
FILENAME != curf { curf = FILENAME; fi++; on = 0; sub_ = 0; intab = 0; lt = "" }
{ sub(/\r$/, "") }

# ---- the run body
fi == 1 {
  if ($0 ~ /^## /) { on = ($0 ~ /^## Factory run[ \t]*$/) && !secd; if (on) secd = 1; sub_ = 0; intab = 0; next }
  if (!on) next
  if ($0 ~ /^### /) { sub_ = ($0 ~ /^### Run waits[ \t]*$/); intab = 0; next }
  if (!hasS && index($0, "- started:") == 1) { hasS = 1; Sraw = trim(substr($0, 11)) }
  if (!hasCl && index($0, "- closed in this run:") == 1) { hasCl = 1; clv = trim(substr($0, 22)) }
  if (!hasIf && index($0, "- in flight:") == 1) { hasIf = 1; ifv = trim(substr($0, 13)) }
  if (sub_ && !tab && $0 ~ /^\| # \| Kind \| Agent \| Start \| End \| What \|[ \t]*$/) { tab = 1; intab = 1; next }
  if (intab && $0 ~ /^\|/) {
    split($0, c, "|"); if (sep(trim(c[2]))) next
    nr++; rid[nr] = trim(c[2]); rk[nr] = trim(c[3]); rs[nr] = tmin(c[5]); re[nr] = tmin(c[6])
    if (!rbad && (!iskind(rk[nr]) || rs[nr] < 0 || re[nr] < 0 || re[nr] < rs[nr])) rbad = rid[nr]
    next
  }
  intab = 0; next
}

# ---- the ledgers
fi >= 2 && fi <= nled + 1 {
  li = fi - 1
  if ($0 ~ /^#+ /) {
    lt = ""
    if ($0 ~ /^### Waits[ \t]*$/) { lt = "W"; hasW[li] = 1 }
    if ($0 ~ /^### Person.s touches[ \t]*$/) { lt = "P"; hasP[li] = 1 }
    next
  }
  if (!lst[li] && index($0, "- started:") == 1) { lst[li] = 1; a[li] = tmin(substr($0, 11)); if (a[li] < 0) lbad[li] = 1; next }
  if (lt == "W" && $0 ~ /^\|/) {
    split($0, c, "|"); x = trim(c[2]); if (x == "Id" || sep(x)) next
    s = tmin(c[5]); e = tmin(c[6]); if (s < 0 || e < 0) { lbad[li] = 1; next }
    k = trim(c[3])
    if (trim(c[7]) == "yes" && iskind(k)) { nw[li]++; wk[li, nw[li]] = KR[k]; ws[li, nw[li]] = s; we[li, nw[li]] = e }
    next
  }
  if (lt == "P" && $0 ~ /^\|/) {
    split($0, c, "|"); x = trim(c[2]); if (x == "Time (UTC)" || sep(x)) next
    t = tmin(c[2]); if (t < 0) { lbad[li] = 1; next }
    if (trim(c[3]) == "approval") b[li] = t
    next
  }
  next
}

# ---- the cut-offs output (gaps)
fi == nled + 2 {
  if ($0 == "") next
  n = split($0, g, "\t")
  if (n != 5 || g[2] !~ /^(limits|stalled|interrupted)$/ || tmin(g[3]) < 0 || (g[4] != "open" && tmin(g[4]) < 0) || g[5] !~ /^[a-z_:-]+(,[a-z_:-]+)*$/) { if (!cbad) cbad = $0; next }
  ng++; gb[ng] = g[1]; gk[ng] = g[2]; graw[ng] = g[3]; gs[ng] = tmin(g[3]); ge[ng] = (g[4] == "open") ? -2 : tmin(g[4]); gm[ng] = g[5]
  next
}

END {
  if (err) exit err
  C = tmin(closearg)
  if (C < 0 || closearg ~ /^~/) fail(2, "--close must be YYYY-MM-DDTHH:MM[:SS[.fff]]Z")
  if (!hasS) notcap("run section has no started: line")
  S = tmin(Sraw); if (S < 0) fail(2, "the started: line is not a time: " Sraw)
  if (C < S) fail(2, "--close is before started:")
  # the items of the run
  ni = 0
  if (hasCl) { m = nums(clv, tmp); for (j = 1; j <= m; j++) if (!(tmp[j] in isit)) { isit[tmp[j]] = 1; IT[++ni] = tmp[j] } }
  if (hasIf) { delete tmp; m = nums(ifv, tmp); for (j = 1; j <= m; j++) if (!(tmp[j] in isit)) { isit[tmp[j]] = 1; IT[++ni] = tmp[j] } }
  for (j = 1; j <= nled; j++) { if (!(LN[j] in isit)) fail(2, "the ledger of #" LN[j] " is not of an item of this run"); lof[LN[j]] = j }
  if (cbad != "") fail(2, "a cut-offs line not in its format: " cbad)
  if (!tab) notcap("run section has no Run waits table")
  for (j = 1; j <= ni; j++) if (!(IT[j] in lof)) notcap("ledger of #" IT[j] " missing")
  for (j = 1; j <= ni; j++) if (!lst[lof[IT[j]]]) notcap("ledger of #" IT[j] " has no started: line")
  for (j = 1; j <= ni; j++) { li = lof[IT[j]]; if (!hasW[li] || !hasP[li] || lbad[li]) notcap("ledger of #" IT[j] " not in its grammar") }
  if (rbad != "") notcap("Run waits row " rbad " not in its grammar")
  # the in-flight windows [lo, hi)
  for (li = 1; li <= nled; li++) {
    lo[li] = (a[li] > S) ? a[li] : S
    hi[li] = (li in b) ? b[li] : C; if (hi[li] > C) hi[li] = C
  }
  if (cmd == "gaps") {
    for (q = 1; q <= ng; q++) {
      s = (gs[q] > S) ? gs[q] : S; e = (ge[q] == -2) ? C : ge[q]; if (e > C) e = C
      if (s >= e) { print "outside the run: " gb[q] " " gk[q] " " graw[q] > "/dev/stderr"; continue }
      out = 0; st = -1
      for (m = s; m <= e; m++) {
        inside = 0
        if (m < e) for (li = 1; li <= nled; li++) if (lo[li] <= m && m < hi[li]) { inside = 1; break }
        if (m < e && !inside) { if (st < 0) st = m }
        else if (st >= 0) { printf "%s\t%s\t%s\tfound at close: %s\n", gk[q], tfmt(st), tfmt(m), gm[q]; out++; st = -1 }
      }
      if (!out) print "inside items: " gb[q] " " gk[q] " " graw[q] > "/dev/stderr"
    }
    exit 0
  }
  for (j = 1; j <= nk; j++) cnt[j] = 0
  for (m = S; m < C; m++) {
    nf = 0; best = 0; blocked = 1
    for (li = 1; li <= nled; li++) {
      if (!(lo[li] <= m && m < hi[li])) continue
      nf++; held = 0
      for (w = 1; w <= nw[li]; w++) if (ws[li, w] <= m && m < we[li, w]) { held = 1; if (!best || wk[li, w] < best) best = wk[li, w] }
      if (!held) { blocked = 0; break }
    }
    if (nf == 0) {
      for (r = 1; r <= nr; r++) if (rs[r] <= m && m < re[r]) { if (!best || KR[rk[r]] < best) best = KR[rk[r]] }
      blocked = (best > 0)
    }
    if (blocked && best) cnt[best]++
  }
  raw = C - S; sum = 0
  for (j = 1; j <= nk; j++) { sum += cnt[j]; V[j] = dur(cnt[j]) }
  adj = dur(raw - sum)
  if (lite) { NC = "not captured (lite)"; V[3] = NC; V[4] = NC; adj = NC }
  printf "- run timing: raw %s; adjusted %s; blocked: person %s, limits %s, stalled %s, interrupted %s\n", dur(raw), adj, V[1], V[2], V[3], V[4]
  exit 0
}' "${args[@]}"
