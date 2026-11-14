#!/bin/bash
# a3-check.sh: the check before Post A3 and before an Edit A3 that rewrites a v2 or v3 A3 (references/a3.md section 9).
# Usage: bash a3-check.sh <file | ->
# Reads the A3 body, decides the version by the marker on the first line, applies that version's checks.
# Exit 0 prints "ok v1", "ok v2" or "ok v3"; exit 1 prints "refused: <key> (<reason>)" per finding, in template order;
# exit 2 prints a usage line on stderr; exit 3 prints "skipped: ..." (no marker, or a version not 1, 2 or 3).
# Changes no file, reads nothing but its argument, makes no network call.

if [ $# -ne 1 ]; then
  echo "usage: a3-check.sh <file | ->" >&2
  exit 2
fi
if [ "$1" != "-" ] && { [ ! -f "$1" ] || [ ! -r "$1" ]; }; then
  echo "usage: a3-check.sh <file | ->  (cannot read: $1)" >&2
  exit 2
fi

if [ "$1" = "-" ]; then
  awk_in=/dev/stdin
else
  case "$1" in /*) awk_in="$1" ;; *) awk_in="./$1" ;; esac # ./ keeps awk from reading name=value as an assignment
fi

awk -v EM='—' '
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function typeidx(t,   i) { for (i = 1; i <= 8; i++) if (T[i] == t) return i; return 0 }
function paretook(v,   body, parts, np, i, ty, ct, idx, pc, pi, seen) {
  if (v !~ /; untagged (none|[1-9][0-9]*)$/) return 0
  body = v; sub(/; untagged (none|[1-9][0-9]*)$/, "", body)
  if (body == "") return 0
  np = split(body, parts, ", ")
  pc = 0; pi = 0
  for (i = 1; i <= np; i++) {
    if (parts[i] !~ /^[a-z-]+ [1-9][0-9]*$/) return 0
    split(parts[i], kv, " ")
    ty = kv[1]; ct = kv[2] + 0
    idx = typeidx(ty)
    if (idx == 0 || (ty in seen)) return 0
    seen[ty] = 1
    if (i > 1 && (ct > pc || (ct == pc && idx < pi))) return 0
    pc = ct; pi = idx
  }
  return 1
}
function noneshape(v) { return (v ~ /^none \(.*[^ ].*\)$/) }
function nonereason(v,   r) { r = v; sub(/^none \(/, "", r); sub(/\)$/, "", r); return r }
function notcaptured(v,   r) {
  if (v !~ /^not captured \([^()]+\)$/) return 0
  r = v; sub(/^not captured \(/, "", r); sub(/\)$/, "", r)
  return (length(r) >= 1 && length(r) <= 80)
}
function emit(key, why) { out[++nf] = "refused: " key " (" why ")" }

BEGIN {
  nk = split("run|series and release|problem|evidence|waste|gemba (targeted)|5 whys|CHAIN|process item to change|countermeasure|measure targeted|before|after|change|target|items counted|events|issues filed during the run|not detectable from records|still uncertain|other problems seen|other overrides|standard changes proposed|baseline|answer", K, "|")
  split("transport inventory motion waiting overproduction over-processing defects skills", T, " ")
  skip = ""; nf = 0; firstnum = 0; nwl = 0; whysl = 0; cite = 0; nev = 0; evbad = 0
}
{ sub(/\r$/, "") }
NR == 1 {
  if ($0 !~ /^<!-- factory:a3 v[0-9]+ -->$/) { skip = "skipped: no A3 marker on the first line"; exit_code = 3; next }
  ver = $0; sub(/^<!-- factory:a3 v/, "", ver); sub(/ -->$/, "", ver)
  if (ver != "1" && ver != "2" && ver != "3") { skip = "skipped: A3 marker v" ver " (version not known)"; exit_code = 3; next }
  next
}
skip != "" { next }
{
  if (index($0, "  process item to change:") == 1) {
    cnt["CHAIN"]++
    if (cnt["CHAIN"] == 1) first["CHAIN"] = NR
  }
  if (index($0, "  event: ") == 1) {
    nev++
    cp = index($0, " " EM " cause:")
    ct = (cp > 0) ? trim(substr($0, cp + length(" " EM " cause:"))) : ""
    if (ct == "" || ct == "?") evbad++
  }
  if ($0 ~ /^  [0-9]+\. /) {
    if (firstnum == 0) firstnum = NR
    if (index($0, "evidence: gemba ") > 0) cite = 1
  }
  if (index($0, "  gemba: no walk (") == 1 && nwl == 0) nwl = NR
  for (i = 1; i <= nk; i++) {
    if (K[i] == "CHAIN") continue
    p = "- " K[i] ":"
    if (index($0, p) == 1) {
      cnt[K[i]]++
      if (cnt[K[i]] == 1) { first[K[i]] = NR; val[K[i]] = trim(substr($0, length(p) + 1)) }
      if (K[i] == "5 whys" && cnt[K[i]] == 1) whysl = NR
      break
    }
  }
}
END {
  if (NR == 0 && skip == "") skip = "skipped: no A3 marker on the first line"
  if (skip != "") { print skip; exit 3 }
  v2 = (ver == "2" || ver == "3"); v3 = (ver == "3")
  multi = (cnt["5 whys"] > 0 && val["5 whys"] == "")
  prev = 0
  for (i = 1; i <= nk; i++) {
    k = K[i]
    isnew = (k == "waste" || k == "gemba (targeted)" || k == "target")
    kname = (k == "CHAIN") ? "process item to change (chain)" : k
    if (isnew && !v2) {
      for (j = 0; j < cnt[k]; j++) emit(kname, "not part of v1")
      continue
    }
    isv3 = (k == "events" || k == "issues filed during the run" || k == "not detectable from records")
    if (isv3 && !v3) {
      for (j = 0; j < cnt[k]; j++) emit(kname, "not part of v" ver)
      continue
    }
    if (k == "CHAIN" && !multi) continue
    if (cnt[k] == 0) { emit(kname, "missing"); continue }
    if (cnt[k] > 1) emit(kname, "repeated")
    if (k != "5 whys" && k != "CHAIN" && val[k] == "") emit(kname, "blank")
    if (prev > 0 && first[k] < prev) emit(kname, "out of order")
    prev = first[k]
    if (k == "5 whys" && v2 && multi && cnt["gemba (targeted)"] > 0) {
      g = val["gemba (targeted)"]
      if (g ~ /^item #[0-9]+ row [0-9]+ /) {
        if (!cite) emit("5 whys", "gemba cite missing")
      } else if (g ~ /^none/ || g ~ /^not captured/) {
        if (!(nwl > whysl && (firstnum == 0 || nwl < firstnum))) emit("5 whys", "gemba no-walk line missing")
      }
    }
    if (!v2 || k == "CHAIN" || val[k] == "") continue
    v = val[k]
    if (k == "events") {
      if (v ~ /^none/) {
        if (!noneshape(v)) emit(kname, "none needs a reason in parentheses")
        else if (nev > 0) emit(kname, "count does not match the event lines")
      } else if (v !~ /^[1-9][0-9]*$/ || v + 0 != nev) emit(kname, "count does not match the event lines")
      else if (evbad > 0) emit(kname, "event without a cause")
    } else if (k == "issues filed during the run") {
      if (v ~ /^none/) { if (!noneshape(v)) emit(kname, "none needs a reason in parentheses") }
      else if (v !~ /^[1-9][0-9]*: ./) emit(kname, "not in its grammar")
    } else if (k == "not detectable from records") {
      if (v ~ /^none/ && !noneshape(v)) emit(kname, "none needs a reason in parentheses")
    }
    if (k == "waste") {
      if (v ~ /^none/) {
        if (!noneshape(v)) emit(kname, "none needs a reason in parentheses")
        else { r = nonereason(v); if (r != "no tagged entry" && r != "no andon or wait in the run\047s items") emit(kname, "reason not in the table") }
      } else if (v ~ /^not captured/) { if (!notcaptured(v)) emit(kname, "not in its grammar") }
      else if (!paretook(v)) emit(kname, "not in its grammar")
    } else if (k == "target") {
      if (v ~ /^none/) {
        if (!noneshape(v)) emit(kname, "none needs a reason in parentheses")
        else {
          r = nonereason(v)
          if (!(r == "no target set" || r == "after reading not captured" || r == "readings not comparable" || r == "no problem chosen" || r == "needs a plugin change" || r == "no countermeasure was tried" || r == "no measure with a captured before-reading" || r ~ /^no closed item in series [0-9]+\.[0-9]+ to measure against$/ || r ~ /^refused at the fence \(.+\)$/)) emit(kname, "reason not in the table")
        }
      } else if (v !~ ("^[0-9]+(\\.[0-9]+)? " EM " (reached|not reached)$")) emit(kname, "not in its grammar")
    } else if (k == "gemba (targeted)") {
      if (v ~ /^none/) {
        if (!noneshape(v)) emit(kname, "none needs a reason in parentheses")
        else { r = nonereason(v); if (r != "no problem chosen" && r != "problem points at no stage or role") emit(kname, "reason not in the table") }
      } else if (v ~ /^not captured/) { if (!notcaptured(v)) emit(kname, "not in its grammar") }
      else if (v !~ /^item #[0-9]+ row [0-9]+ /) emit(kname, "not in its grammar")
    }
  }
  if (nf == 0) { print "ok v" ver; exit 0 }
  for (i = 1; i <= nf; i++) print out[i]
  exit 1
}
' "$awk_in"
exit $?
