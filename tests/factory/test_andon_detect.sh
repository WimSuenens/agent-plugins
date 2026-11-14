#!/bin/bash
# andon-detect.sh on real inputs of this repository (slice 0 of #207): the ledgers of closed items #156 and #168 (read from the tracker,
# kept as fixtures under fixtures/ledgers/) and the commits of the merged item branches (PR 176, 182, 202). The cases of
# test_andon_kind3_kind4.sh prove the rules on synthetic repos; these show the script gives what the prose procedure gave on real history.
. "$(dirname "$0")/lib.sh"
AD="$PLUGIN/scripts/andon-detect.sh"
FX="$REPO/tests/factory/fixtures/ledgers"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

# ---- kind 4 and working time on the ledgers of #168 and #156: Duration = closed_at - created_at in whole minutes, no listed waits ----
got="$(bash "$AD" working --ledger "$FX/ledger-168.md" --times "$FX/times-168.tsv" | tr '\n' ';')"
ck k4-real-168-working-minutes "1 architect 1;2 qa-engineer 4;3 developer 9;4 developer 10;5 docs-writer 4;6 qa-engineer 3;7 security-reviewer 1;" "$got"
got="$(bash "$AD" working --ledger "$FX/ledger-156.md" --times "$FX/times-156.tsv" | tr '\n' ';')"
ck k4-real-156-working-minutes "1 product-owner 2;2 architect 4;3 qa-engineer 5;4 developer 24;5 devops 1;6 developer 1;7 docs-writer 4;8 qa-engineer 3;9 security-reviewer 2;" "$got"
# no role has 3 earlier rows in either item, so the prose says: no baseline, for every row
for n in 156 168; do
  rows="$(grep -cE '^\| [0-9]+ \| #' "$FX/ledger-$n.md")"; bad=0; i=1
  while [ $i -le $rows ]; do
    [ "$(bash "$AD" kind4 --ledger "$FX/ledger-$n.md" --times "$FX/times-$n.tsv" $i)" = "no baseline: fewer than 3 earlier rows" ] || bad=$((bad+1)); i=$((i+1))
  done
  ck k4-real-$n-every-row-no-baseline 0 "$bad"
done
# the same ledger with every role read as developer: rows 1 to 4 last 1, 4, 9 and 10 minutes, so row 4 is slow against median 4 (10 > 2 x 4)
sed -E 's/\| (architect|qa-engineer|docs-writer|security-reviewer) \|/| developer |/' "$FX/ledger-168.md" > "$T/dev168.md"
ck k4-real-168-as-one-role-row4-slow "slow: 10 against median 4 of 3 earlier rows" "$(bash "$AD" kind4 --ledger "$T/dev168.md" --times "$FX/times-168.tsv" 4)"
ck k4-real-168-as-one-role-row5-not-flagged "not flagged" "$(bash "$AD" kind4 --ledger "$T/dev168.md" --times "$FX/times-168.tsv" 5)"
ck k4-real-168-as-one-role-row6-not-flagged "not flagged" "$(bash "$AD" kind4 --ledger "$T/dev168.md" --times "$FX/times-168.tsv" 6)"
# a held person wait listed in a row's Waits column leaves the row's agent working time: row 4 (22:08 to 22:18) with W9 22:08 to 22:18
awk -F'|' 'BEGIN{OFS="|"} /^\| 4 \| #174/ {$7=" W9 "} {print} /^\| W1 \|/ {print "| W9 | person | - | 2026-11-12T22:08Z | 2026-11-12T22:18Z | yes | test |"}' "$T/dev168.md" > "$T/dev168w.md"
ck k4-real-168-listed-wait-removes-time "4 developer 0" "$(bash "$AD" working --ledger "$T/dev168w.md" --times "$FX/times-168.tsv" | grep '^4 ')"
sed 's/| W9 | person | - |/| W9 | other | - |/' "$T/dev168w.md" > "$T/dev168o.md"
ck k4-real-168-unlisted-kind-keeps-time "4 developer 10" "$(bash "$AD" working --ledger "$T/dev168o.md" --times "$FX/times-168.tsv" | grep '^4 ')"
bash "$AD" kind4 --ledger "$FX/ledger-168.md" --times "$FX/times-168.tsv" 99 >/dev/null 2>&1; ck k4-unknown-row-exit-2 2 "$?"
bash "$AD" bogus >/dev/null 2>&1; ck usage-exit-2 2 "$?"

# ---- kind 3 on the commits of the merged item branches, judged by the ownership table of the base they started from ----
# PR 176 (item 168): its ledger says `abnormalities: none`. PR 182 (item 156) and PR 202 (item 188): the rule as written finds the lines pinned below.
k3() { # <base> <head> -> lines; skips when the history is not in this clone
  git -C "$REPO" cat-file -e "$1^{commit}" 2>/dev/null && git -C "$REPO" cat-file -e "$2^{commit}" 2>/dev/null || return 99
  git -C "$REPO" show "$1:docs/agents/factory.md" > "$T/tbl-$1.md" || return 99
  bash "$AD" kind3 --in "$REPO" --table "$T/tbl-$1.md" --base "$1" --head "$2"; }
real3() { # <name> <base> <head> <expected lines, ; separated>
  out="$(k3 "$2" "$3")"; rc=$?
  if [ $rc = 99 ]; then skip "$1" "history of PR not present in this clone (shallow)"; return; fi
  ck "$1" "$4" "$(printf '%s' "$out" | tr '\n' ';')"; }
real3 k3-real-pr176-item168-none 0127389 3b135c3 ""
real3 k3-real-pr182-item156 3da67e7 1347782 "role-outside-role: bf9de7e developer changed docs/agents/roles/developer.md (owner docs-writer)"
real3 k3-real-pr202-item188 fa8d15c ba2d3aa "role-outside-role: b81bec5 developer changed docs/agents/roles/developer.md (owner docs-writer);role-outside-role: 72da26a qa-engineer changed docs/agents/roles/qa-engineer.md (owner docs-writer)"
done_
