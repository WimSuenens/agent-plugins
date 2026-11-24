#!/usr/bin/env bash
# The plan fields of the hansei record, the check that a record holds them, and the baseline's carry-over comparison (#187 decisions 8, 13, 14; #207 slice 6).
# Usage: bash hansei-plan.sh fields <latest plan file> [--first <plan file>] --root <plugin root> [--table <factory.md>]    (default docs/agents/factory.md)
#        bash hansei-plan.sh check <record file | -> [--plan <plan file>]
#        bash hansei-plan.sh carry <64 hex standard of the older series> <plugin root>
# fields: prints the record's `### Plan` section from the plan comments on the ticket (the plan files are the comments' text). The estimate is the sizing: points, triggers
#   and band of the --first plan (the first plan comment; after a re-size under a new table, the re-size plan; default the latest). Route, role path and test depth are the
#   latest plan's (what ran); `actual triggers` are the latest plan's, and `actual points` is re-added from the table through flow-size.sh with the latest plan's own bands line,
#   never read from the plan's `points:` line. The lead adds nothing by hand. `release:` is `same`, or `release crossed (factory <old> to <new>)` when the first plan was
#   written under another release (plan-check.sh release); `actual points` then reads `not captured (release crossed)`, because the table of another release is not the plan's.
# check: the record's `### Plan` section. With --plan (the slice has a plan) every field is present and not empty, `release:` reads same or release crossed;
#   without --plan the section may read only `- plan: no plan` (an item run without a plan). Prints `ok`, `ok (no plan)` or `refused: <field> (<reason>)` per finding.
# carry: `reference (standard unchanged)` when the older series' standard fingerprint equals the one fingerprint.sh prints for the plugin root, else `indicative (standard changed)`.
#   A tooling-only change is not a change of the standard.
# Exit: 0 printed (check: ok); 1 a plan is wrong, or check refused; 2 usage, an unreadable file, or the root is not a factory plugin root.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usage() { sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ $# -ge 1 ] || usage
cmd="$1"; shift
FIELDS="estimated points|fired triggers|band|route|role path|test depth|actual triggers|actual points|release"

case "$cmd" in
  carry)
    [ $# -eq 2 ] || usage
    case "$1" in *[!0-9a-f]* | "") usage ;; esac
    [ "${#1}" = 64 ] || usage
    cur="$(bash "$here/fingerprint.sh" "$2" 2>/dev/null | sed -n 's/^standard: //p')"
    [ -n "$cur" ] || { echo "hansei-plan: $2: not a factory plugin root" >&2; exit 2; }
    if [ "$cur" = "$1" ]; then echo "reference (standard unchanged)"; else echo "indicative (standard changed)"; fi
    ;;
  fields)
    latest="${1:-}"; shift 2>/dev/null
    first=""; root=""; table="docs/agents/factory.md"
    while [ $# -gt 0 ]; do
      case "$1" in
        --first) [ $# -ge 2 ] || usage; first="$2"; shift 2 ;;
        --root) [ $# -ge 2 ] || usage; root="$2"; shift 2 ;;
        --table) [ $# -ge 2 ] || usage; table="$2"; shift 2 ;;
        *) usage ;;
      esac
    done
    [ -n "$first" ] || first="$latest"
    [ -n "$latest" ] && [ -r "$latest" ] && [ -r "$first" ] && [ -n "$root" ] || usage
    get() { grep -m 1 "^- $2:" "$1" | sed "s/^- $2:[[:space:]]*//" | tr -d '\r' | sed 's/[[:space:]]*$//'; }
    rel="$(bash "$here/plan-check.sh" release "$first" "$root")"; rc=$?
    case "$rc" in 0) ;; 1) echo "$rel"; exit 1 ;; *) exit "$rc" ;; esac
    cur="$(bash "$here/fingerprint.sh" "$root" 2>/dev/null | sed -n 's/^release: //p')"
    for f in points triggers band; do [ -n "$(get "$first" "$f")" ] || { echo "missing: $f"; exit 1; }; done
    for f in route "role path" "test depth" triggers bands; do [ -n "$(get "$latest" "$f")" ] || { echo "missing: $f"; exit 1; }; done
    if [ "$rel" = same ]; then
      relline="same"
      trig="$(get "$latest" triggers)"
      names=()
      if [ "$trig" != none ]; then
        while IFS= read -r n; do [ -n "$n" ] && names+=("$n"); done <<NAMES
$(printf '%s\n' "$trig" | sed -E 's/ \(\+[0-9]+\)(, |$)/\n/g')
NAMES
      fi
      got="$(bash "$here/flow-size.sh" --table "$table" --bands "$(get "$latest" bands)" ${names[@]+"${names[@]}"} 2>&1)"; rc=$?
      [ "$rc" = 0 ] || { echo "triggers: $(printf '%s\n' "$got" | head -1)"; exit 1; }
      actual="$(printf '%s\n' "$got" | sed -n 's/^points: //p')"
    else
      relline="release crossed (factory $(get "$first" release | sed 's/^factory[[:space:]]*//') to $cur)"
      actual="not captured (release crossed)"
    fi
    echo "### Plan"
    echo
    echo "- estimated points: $(get "$first" points)"
    echo "- fired triggers: $(get "$first" triggers)"
    echo "- band: $(get "$first" band)"
    echo "- route: $(get "$latest" route)"
    echo "- role path: $(get "$latest" "role path")"
    echo "- test depth: $(get "$latest" "test depth")"
    echo "- actual triggers: $(get "$latest" triggers)"
    echo "- actual points: $actual"
    echo "- release: $relline"
    ;;
  check)
    rec="${1:-}"; shift 2>/dev/null
    plan=""
    while [ $# -gt 0 ]; do
      case "$1" in --plan) [ $# -ge 2 ] || usage; plan="$2"; shift 2 ;; *) usage ;; esac
    done
    [ -n "$rec" ] && { [ "$rec" = - ] || [ -r "$rec" ]; } || usage
    sec="$(cat "$rec" | tr -d '\r' | awk '/^### Plan[[:space:]]*$/ { on = 1; next } /^### / { on = 0 } on')"
    has_sec="$(cat "$rec" 2>/dev/null | tr -d '\r' | grep -c '^### Plan[[:space:]]*$')"
    [ "$rec" = - ] && has_sec=1
    if [ "$has_sec" = 0 ]; then echo "refused: plan (section missing)"; exit 1; fi
    if printf '%s\n' "$sec" | grep -qx -- '- plan: no plan'; then
      if [ -n "$plan" ]; then echo "refused: plan (the slice has a plan; the record says no plan)"; exit 1; fi
      echo "ok (no plan)"; exit 0
    fi
    bad=0
    old_ifs="$IFS"; IFS='|'
    for f in $FIELDS; do
      IFS="$old_ifs"
      line="$(printf '%s\n' "$sec" | grep -m 1 -- "^- $f:")"
      if [ -z "$line" ]; then echo "refused: $f (missing)"; bad=1; continue; fi
      v="$(printf '%s' "$line" | sed "s/^- $f:[[:space:]]*//" | sed 's/[[:space:]]*$//')"
      if [ -z "$v" ]; then echo "refused: $f (empty)"; bad=1; continue; fi
      if [ "$f" = release ]; then
        case "$v" in same | "release crossed"*) ;; *) echo "refused: release (\"$v\" is neither same nor release crossed)"; bad=1 ;; esac
      fi
    done
    IFS="$old_ifs"
    [ "$bad" = 0 ] && { echo ok; exit 0; }
    exit 1
    ;;
  *) usage ;;
esac
