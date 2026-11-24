#!/usr/bin/env bash
# The calibration signal of an escaped defect: a defect found after a QA pass (#187 decision 10; #207 slice 7).
# Usage: bash escaped-defect.sh <defect issue> [--table <factory.md>]      (table default docs/agents/factory.md)
# The defect issue's body carries these lines at column 0, written by the lead when it files the defect:
#   escaped from: #<slice>             the slice whose QA pass it escaped
#   escaped at level: <level>          where the regression test belongs: the level at which the defect escaped (unit, integration, end-to-end, proof, ...)
#   should have fired: <row | none>    the table row that should have caught it, or none when no row fits
#   regression test: <path>            optional until the test exists; absent it prints `regression test missing`
# Output, two lines: the signal line to put in the hansei record's `### Escaped defects` section (references/hansei.md), then the row it counts against.
#   - escaped defect: #<n> from #<slice>; level <level>; row <row> (fired | not fired | not captured: no hansei record on #<slice>); regression test <path | missing>
#   - escaped defect: #<n> from #<slice>; level <level>; no trigger fired: row missing; regression test <path | missing>
#   counts against: <row> | none (row missing)
# `fired` is read from the slice's hansei record (the last comment on the slice ticket headed `## Hansei: #<slice>`): the row is among its actual triggers.
# calibration.sh reads the first line. Exit: 0 printed; 1 refused (a missing field, or a row that is not in the table); 2 usage or an unreadable issue or table.

usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
table="docs/agents/factory.md"; n=""
while [ $# -gt 0 ]; do
  case "$1" in
    --table) [ $# -ge 2 ] || usage; table="$2"; shift 2 ;;
    -*) usage ;;
    *) [ -z "$n" ] || usage; n="$1"; shift ;;
  esac
done
case "$n" in '' | *[!0-9]*) usage ;; esac
[ -r "$table" ] || { echo "escaped-defect: cannot read $table" >&2; exit 2; }
j="$(gh issue view "$n" --json body 2>/dev/null)" || { echo "escaped-defect: cannot read issue #$n" >&2; exit 2; }
body="$(printf '%s' "$j" | jq -r '.body // ""' | tr -d '\r')"
get() { printf '%s\n' "$body" | grep -m 1 "^$1:" | sed "s/^$1:[[:space:]]*//; s/[[:space:]]*\$//"; }
from="$(get 'escaped from' | sed 's/^#//')"; level="$(get 'escaped at level')"; want="$(get 'should have fired')"; test_="$(get 'regression test')"
refuse=0
case "$from" in '' | *[!0-9]*) echo "refused: escaped from (missing, or not #<slice>)"; refuse=1 ;; esac
[ -n "$level" ] || { echo "refused: escaped at level (missing)"; refuse=1; }
[ -n "$want" ] || { echo "refused: should have fired (missing; write none when no row fits)"; refuse=1; }
[ "$refuse" = 0 ] || exit 1
[ -n "$test_" ] || test_="missing"
if [ "$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]')" = none ]; then
  echo "- escaped defect: #$n from #$from; level $level; no trigger fired: row missing; regression test $test_"
  echo "counts against: none (row missing)"
  exit 0
fi
row="$(awk -F'|' -v w="$(printf '%s' "$want" | tr '[:upper:]' '[:lower:]')" '/^\|/ { s = $2; gsub(/^[ \t]+|[ \t]+$/, "", s); if (tolower(s) == w) { print s; exit } }' "$table")"
[ -n "$row" ] || { echo "refused: should have fired ($want is not a row of the table; write none when no row fits)"; exit 1; }
state="not captured: no hansei record on #$from"
if sj="$(gh issue view "$from" --json comments 2>/dev/null)"; then
  rec="$(printf '%s' "$sj" | jq -r --arg h "## Hansei: #$from" '[.comments[].body | select(contains($h))] | last // ""' | tr -d '\r')"
  if [ -n "$rec" ]; then
    act="$(printf '%s\n' "$rec" | grep -m 1 '^- actual triggers:' | sed 's/^- actual triggers:[[:space:]]*//')"
    state="not fired"
    # the actual triggers line is `Row (+n), Row (+n)`; a row name may hold a comma, so match the row followed by its ` (+n)` terminator
    case "$act" in "$row ("[+]*) state="fired" ;; *", $row (+"*) state="fired" ;; esac
  fi
fi
echo "- escaped defect: #$n from #$from; level $level; row $row ($state); regression test $test_"
echo "counts against: $row"
