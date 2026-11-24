#!/usr/bin/env bash
# Calibration of the flow table from the hansei records of the last 5 slices (#187 decision 8; #207 slice 7). It reads and proposes; it never writes the table.
# Usage: bash calibration.sh [--table <factory.md>] [--reopen "<row>: <reason>"]... <hansei record file>...      (table default docs/agents/factory.md)
# The lead saves the hansei record of each slice to a file, oldest first, and passes them in that order; the last 5 given are read.
# A record without the plan fields of slice 6 (`- plan: no plan`, or no `### Plan` section) is skipped and counted; so is a `release crossed` record, whose points are not the table's.
# Output, one line each, in this order:
#   slices read: <n> of <given> given [(the last 5)]
#   skipped: <k> (no plan fields <a>, release crossed <b>)         or `skipped: 0`
#   band <name>: <n> slices; median (actual - estimated) <+x | 0 | -x>      one per band, first seen first
#   row <name>: misses <a>, false alarms <b>                        one per table row, in table order, counted in slices
#   findings: <role> in band <name> <k> of <n> slices                roles that received a rework brief (hansei measure 3); `findings: none`
#   escaped defects: <n> signals; <k> with a regression test; row missing <m>     or `escaped defects: none`
#   settle: <row> (<n> slices read, fired in <k>, no miss, no false alarm)    a provisional row ready to turn settled (5 slices read, no band median of 2 or more away)
#   proposal: raise|lower <row> by 1 point (<k> of <n> slices ...); ...        at most one, only when at least 3 slices agree; or `proposal: none (<reason>)`
# A miss is a row in the record's actual triggers that was not in its fired triggers, or an escaped-defect signal naming the row (escaped-defect.sh). A false alarm is a row fired at
# sizing that is not in the actual triggers. Rows are never proposed when they are the floor's row (Protected area touched) or `settled` without --reopen, which states a reason.
# Exit: 0 printed; 2 usage, an unreadable file, or a table with no trigger rows.

usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
table="docs/agents/factory.md"; reopen=""; files=()
while [ $# -gt 0 ]; do
  case "$1" in
    --table) [ $# -ge 2 ] || usage; table="$2"; shift 2 ;;
    --reopen)
      [ $# -ge 2 ] || usage
      case "$2" in *:*[![:space:]]*) ;; *) echo "calibration: --reopen needs \"<row>: <reason>\" with a reason" >&2; exit 2 ;; esac
      reopen="$reopen$2"$'\n'; shift 2 ;;
    -*) usage ;;
    *) files+=("$1"); shift ;;
  esac
done
[ ${#files[@]} -ge 1 ] || usage
[ -r "$table" ] || { echo "calibration: cannot read $table" >&2; exit 2; }
for f in "${files[@]}"; do [ -r "$f" ] || { echo "calibration: cannot read $f" >&2; exit 2; }; done
given=${#files[@]}
if [ "$given" -gt 5 ]; then files=("${files[@]:$((given - 5))}"); fi

REOPEN="$reopen" awk -v given="$given" -v tablefile="$table" '
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function lc(s) { return tolower(s) }
# names(<triggers line>, <set array>): fills set[name]=1 from "A (+3), B, C (+2)"; splits on the " (+n)" terminator, as hansei-plan.sh does
function names(s, set,   m, n) {
  s = trim(s)
  if (s == "none" || s == "") return
  while (match(s, / \(\+[0-9]+\)(, |$)/)) {
    n = substr(s, 1, RSTART - 1); set[n] = 1
    s = substr(s, RSTART + RLENGTH)
  }
}
function fin(   i, n, r) {
  if (cur == "") return
  if (isplan && rel ~ /^release crossed/) { crossed++; return }
  if (!isplan || est == "" || act == "" || act !~ /^[0-9]+$/ || est !~ /^[0-9]+$/) { noplan++; return }
  nread++
  if (!(band in bseen)) { bseen[band] = 1; border[++nb] = band }
  nd = ++bn[band]; diff[band, nd] = act - est
  delete F; delete A; names(fired, F); names(actrig, A)
  for (i = 1; i <= nrow; i++) {
    r = row[i]
    if (r in F) firedn[i]++
    if ((r in A) && !(r in F)) mflag[i] = 1
    if ((r in F) && !(r in A)) fflag[i] = 1
    if (r in ESC) mflag[i] = 1
    if (mflag[i]) miss[i]++
    if (fflag[i]) fa[i]++
    mflag[i] = 0; fflag[i] = 0
  }
  for (i = 1; i <= nroles; i++) if (rw[i] > 0) { fnd[band, i]++ }
  esig += nsig; ereg += nreg; emiss += nmiss
}
function startrec() {
  cur = FILENAME; isplan = 0; est = ""; act = ""; fired = ""; actrig = ""; band = ""; rel = ""; nsig = 0; nreg = 0; nmiss = 0
  delete ESC; for (i = 1; i <= nroles; i++) rw[i] = 0
}
BEGIN {
  # the table
  nrow = 0
  while ((getline line < tablefile) > 0) {
    if (line !~ /^\|/) continue
    n = split(line, c, "|")
    if (n < 6) continue
    name = trim(c[2])
    if (name == "Trigger" || name ~ /^-+$/ || name == "") continue
    row[++nrow] = name; status[nrow] = trim(c[6])
  }
  close(tablefile)
  if (nrow == 0) { print "calibration: " tablefile " has no trigger rows" > "/dev/stderr"; bad = 1; exit 2 }
  nreo = split(ENVIRON["REOPEN"], RL, "\n")
  nroles = split("product-owner architect developer qa-engineer security-reviewer devops docs-writer", roles, " ")
  cur = ""
}
FNR == 1 { fin(); startrec() }
{
  sub(/\r$/, "")
  if ($0 ~ /^### /) { insec = ($0 == "### Plan"); if (insec) isplan = 1 }
  if ($0 ~ /^- plan: no plan/) { isplan = 0 }
  if ($0 ~ /^3\. rework: feedback briefs /) {
    s = $0; sub(/^3\. rework: feedback briefs /, "", s); sub(/;.*$/, "", s)
    k = split(s, p, ", ")
    for (i = 1; i <= k; i++) { split(p[i], kv, " "); for (j = 1; j <= nroles; j++) if (kv[1] == roles[j]) rw[j] = kv[2] + 0 }
  }
  if (insec) {
    if ($0 ~ /^- estimated points:/) { est = trim(substr($0, index($0, ":") + 1)) }
    else if ($0 ~ /^- fired triggers:/) { fired = trim(substr($0, index($0, ":") + 1)) }
    else if ($0 ~ /^- band:/) { band = trim(substr($0, index($0, ":") + 1)) }
    else if ($0 ~ /^- actual triggers:/) { actrig = trim(substr($0, index($0, ":") + 1)) }
    else if ($0 ~ /^- actual points:/) { act = trim(substr($0, index($0, ":") + 1)) }
    else if ($0 ~ /^- release:/) { rel = trim(substr($0, index($0, ":") + 1)) }
  }
  if ($0 ~ /^- escaped defect: /) {
    nsig++
    s = $0
    if (s ~ /; regression test /) { t = s; sub(/^.*; regression test /, "", t); if (t != "missing" && t != "") nreg++; sub(/; regression test .*$/, "", s) }
    if (s ~ /no trigger fired: row missing$/) nmiss++
    else if (s ~ /; row /) {
      sub(/^.*; row /, "", s); sub(/ \((fired|not fired|not captured[^)]*)\)$/, "", s)
      for (i = 1; i <= nrow; i++) if (lc(row[i]) == lc(s)) ESC[row[i]] = 1
    }
  }
}
END {
  if (bad) exit 2
  fin()
  eff = given > 5 ? 5 : given
  printf "slices read: %d of %d given%s\n", nread, given, (given > 5 ? " (the last 5)" : "")
  if (noplan + crossed == 0) print "skipped: 0"
  else printf "skipped: %d (no plan fields %d, release crossed %d)\n", noplan + crossed, noplan, crossed
  for (b = 1; b <= nb; b++) {
    bn_ = border[b]; m = bn[bn_]
    for (i = 1; i <= m; i++) v[i] = diff[bn_, i]
    for (i = 2; i <= m; i++) { x = v[i]; j = i - 1; while (j >= 1 && v[j] > x) { v[j + 1] = v[j]; j-- }; v[j + 1] = x }
    med = (m % 2) ? v[(m + 1) / 2] : (v[m / 2] + v[m / 2 + 1]) / 2
    ms[bn_] = med
    sg = (med > 0) ? "+" : ""
    t = sg med
    if (med == 0) t = "0"
    printf "band %s: %d slices; median (actual - estimated) %s\n", bn_, m, t
  }
  for (i = 1; i <= nrow; i++) printf "row %s: misses %d, false alarms %d\n", row[i], miss[i] + 0, fa[i] + 0
  anyf = 0
  for (b = 1; b <= nb; b++) for (j = 1; j <= nroles; j++) if (fnd[border[b], j] > 0) { printf "findings: %s in band %s %d of %d slices\n", roles[j], border[b], fnd[border[b], j], bn[border[b]]; anyf = 1 }
  if (!anyf) print "findings: none"
  if (esig == 0) print "escaped defects: none"
  else printf "escaped defects: %d signals; %d with a regression test; row missing %d\n", esig, ereg, emiss
  # settle candidates
  if (nread >= 5) {
    big = 0
    for (b = 1; b <= nb; b++) { x = ms[border[b]]; if (x >= 2 || x <= -2) big = 1 }
    if (!big) for (i = 1; i <= nrow; i++) {
      if (status[i] ~ /^settled/) continue
      if (firedn[i] >= 1 && miss[i] + 0 == 0 && fa[i] + 0 == 0) printf "settle: %s (%d slices read, fired in %d, no miss, no false alarm)\n", row[i], nread, firedn[i]
    }
  }
  # the one proposal
  best = 0; bestn = 0; blocked = ""
  for (i = 1; i <= nrow; i++) {
    dir = ""; cnt = 0
    if (miss[i] >= 3 && fa[i] < 3) { dir = "raise"; cnt = miss[i] }
    else if (fa[i] >= 3 && miss[i] < 3) { dir = "lower"; cnt = fa[i] }
    if (dir == "") continue
    if (lc(row[i]) == "protected area touched") { if (blocked == "") blocked = row[i] " is the floor\047s row and is never changed by calibration"; continue }
    why = ""
    if (status[i] ~ /^settled/) {
      for (k = 1; k <= nreo; k++) { rn = RL[k]; if (rn == "") continue; q = index(rn, ":"); if (lc(trim(substr(rn, 1, q - 1))) == lc(row[i])) why = trim(substr(rn, q + 1)) }
      if (why == "") { if (blocked == "") blocked = row[i] " is settled and no reason to reopen it was given"; continue }
    }
    if (cnt > bestn) { best = i; bestn = cnt; bdir = dir; bwhy = why }
  }
  if (best > 0) {
    if (bdir == "raise") d = sprintf("%d of %d slices missed it", bestn, nread)
    else d = sprintf("%d of %d slices fired it and it did not run", bestn, nread)
    printf "proposal: %s %s by 1 point (%s)%s; the lead decides, nothing is applied\n", bdir, row[best], d, (bwhy != "" ? "; reopened: " bwhy : "")
  } else if (blocked != "") printf "proposal: none (%s)\n", blocked
  else print "proposal: none (no row has 3 agreeing slices)"
}
' "${files[@]}"
