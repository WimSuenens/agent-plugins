#!/bin/bash
# AC-3: the written rule for kind 2 ("same finding twice"), applied to #39's findings.
# The signatures (fixtures/ac3-signatures.tsv) are the Lead's judgment, filled by QA from each finding's text alone
# (fixtures/ac3-findings-39.tsv); the controls (fixtures/ac3-controls.tsv) were committed before the signatures.
# This file applies clauses M1 and M2 of contracts/49-abnormality-list.md section 4.3 mechanically to those signatures.
. "$(dirname "$0")/lib.sh"
FX="$(dirname "$0")/fixtures"
LED="$FX/ac3-findings-39.tsv"; SIG="$FX/ac3-signatures.tsv"; CTL="$FX/ac3-controls.tsv"

# the ledger holds exactly five columns and every row has a signature
ck ac3-ledger-five-columns 0 "$(grep -v '^#' "$LED" | awk -F'\t' 'NF!=5' | grep -c .)"
ck ac3-ledger-rows-have-signature "$(grep -v '^#' "$LED" | awk -F'\t' '{print $1" "$2" "$3}' | sort | paste -sd'|' -)" \
  "$(grep -v '^#' "$SIG" | awk -F'\t' '{print $1" "$2" "$3}' | sort | paste -sd'|' -)"
ck ac3-at-least-five-controls 1 "$([ "$(grep -vc '^#' "$CTL")" -ge 5 ] && echo 1 || echo 0)"
ck ac3-every-control-has-reason 0 "$(grep -v '^#' "$CTL" | awk -F'\t' 'length($4)<30' | grep -c .)"
# no control may be a pair the rule never compares (same Role and Round)
ck ac3-controls-are-comparable-pairs 0 "$(grep -v '^#' "$CTL" | awk -F'\t' '{split($2,a," "); split($3,b," "); if (a[1]==b[1] && a[2]==b[2]) print}' | grep -c .)"

# the rule: all pairs of different (Role, Round); M1 then M2; prints "A=B clause"
flag="$(grep -v '^#' "$SIG" | awk -F'\t' '
  {n++; key[n]=$1" r"$2" "$3; rk[n]=$1" "$2; rd[n]=$2; obj[n]=$4; trg[n]=$5; gd[n]=$6; cr[n]=$7; fl[n]=$8}
  END {
    for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) {
      if (rk[i]==rk[j]) continue
      c=""
      if (gd[i]!="-" && gd[i]==gd[j] && ((obj[i]!="-" && obj[i]==obj[j]) || (trg[i]!="-" && trg[i]==trg[j]))) c="M1"
      else if (cr[i]!="-" && cr[i]==cr[j] && fl[i]!="-" && fl[i]==fl[j] && rd[i]!=rd[j]) c="M2"
      if (c!="") print key[i] " = " key[j] " " c
    }}' | sort)"
echo "$flag" | sed 's/^/     flagged: /'
isflag() { echo "$flag" | grep -qxF -- "$1"; }
# the five abnormalities of #39
for p in "qa-engineer r1 F2 = security-reviewer r1 L4 M1" "qa-engineer r2 F6 = security-reviewer r1 L6 M1" \
         "security-reviewer r1 L7 = security-reviewer r5 L12 M1" "security-reviewer r5 L11 = qa-engineer r5 F4 M1"; do
  # the awk prints pairs in file order; accept either order
  a="${p% M1}"; l="${a%% = *}"; r="${a##* = }"
  if isflag "$l = $r M1" || isflag "$r = $l M1"; then echo "ok   ac3-flag $l = $r"; passed=$((passed+1)); else echo "FAIL ac3-flag $l = $r"; fail=1; fi
done
if echo "$flag" | grep -qE '^qa-engineer r4 AC-17 = demo r1 AC-17 M2$|^demo r1 AC-17 = qa-engineer r4 AC-17 M2$'; then echo "ok   ac3-flag AC-17 demo r1 = QA r4 (M2, across rounds)"; passed=$((passed+1)); else echo "FAIL ac3-flag AC-17 across rounds"; fail=1; fi
# the controls: none flagged
while IFS="$(printf '\t')" read -r c a b _why; do
  case "$c" in '#'*|'') continue ;; esac
  ka="$(echo "$a" | awk '{print $1" r"$2" "$3}')"; kb="$(echo "$b" | awk '{print $1" r"$2" "$3}')"
  if echo "$flag" | grep -qF -e "$ka = $kb" -e "$kb = $ka"; then echo "FAIL ac3-control-$c flagged ($ka / $kb)"; fail=1; else echo "ok   ac3-control-$c not flagged"; passed=$((passed+1)); fi
done < "$CTL"
# the whole flag set: five pairs plus the genuine repeats QA found outside the controls (listed in the verdict, not a failure)
ck ac3-flag-count-5-plus-extras 9 "$(echo "$flag" | grep -c .)"
ck ac3-extras "qa-engineer r2 F4 = security-reviewer r6 L13 M1|security-reviewer r1 L1 = security-reviewer r2 L1a M1|security-reviewer r1 L5 = qa-engineer r2 F4 M1|security-reviewer r1 L5 = security-reviewer r6 L13 M1" \
  "$(echo "$flag" | grep -vE 'F2 = security-reviewer r1 L4|L6 = qa-engineer r2 F6|L7 = security-reviewer r5 L12|L11 = qa-engineer r5 F4|AC-17' | paste -sd'|' -)"
done_
