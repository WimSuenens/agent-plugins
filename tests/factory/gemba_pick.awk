# Reader B of the gemba sample rule: written from the text of hansei.md section 6 only, in awk, with no code shared with gemba_pick.py.
# Usage: awk -v id=<id> -f gemba_pick.awk <log.md>   prints  <row> <flag>
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function isrole(r) { return (r == "product-owner" || r == "architect" || r == "developer" || r == "qa-engineer" || r == "security-reviewer" || r == "devops" || r == "docs-writer") }
BEGIN { FS = "|"; nrole = 0; hdr = 0; pos = -1 }
/^\|/ {
  if (!hdr) {
    hdr = 1
    for (i = 2; i < NF; i++) { h = tolower(trim($i)); col[h] = i }
    ag = ("agents" in col) ? col["agents"] : col["agent"]
    next
  }
  if ($0 ~ /^\|[-| :]+\|$/) next
  pos++
  num = ("#" in col) ? trim($(col["#"])) : pos
  role = trim($(col["role"])); a = trim($(ag))
  if (!isrole(role) || a == "-" || a == "") next
  nrole++
  rn[nrole] = num
  res = ("result" in col) ? trim($(col["result"])) : ""
  nt = ("notes" in col) ? $(col["notes"]) : ""
  low = tolower(res)
  bad = 0
  if (!("result" in col)) bad = 1
  else if (!(substr(low, 1, 4) == "done" || substr(low, 1, 4) == "pass")) bad = 1
  paused = ""
  if (match(nt, /paused by A[0-9]+/)) paused = substr(nt, RSTART, RLENGTH)
  if (paused != "") bad = 1
  fl[nrole] = bad
  split(res, w, " "); first = (w[1] == "") ? "-" : w[1]
  if (paused != "" && (substr(low, 1, 4) == "done" || substr(low, 1, 4) == "pass")) first = paused
  fw[nrole] = first
}
END {
  ni = split(ids != "" ? ids : id, idl, " ")   # one line per id
  n = 0
  for (k = 1; k <= nrole; k++) if (!fl[k]) { n++; el[n] = k }
  for (q = 1; q <= ni; q++) {
    if (nrole == 0) { print "none -"; continue }
    if (n > 0) { print rn[el[(idl[q] % n) + 1]], "-"; continue }
    k = (idl[q] % nrole) + 1
    print rn[k], fw[k]
  }
}
