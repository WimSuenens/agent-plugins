#!/usr/bin/env bash
# Role skipping for a trivial slice (spec #108, slice 118). The lead may skip a role; this script says whether a skip is allowed.
# Usage: bash skip.sh check <role> --reason <text> [--touches <area>]... <contract-file>...
#        bash skip.sh protected [--touches <area>]... <contract-file>...
# <role>: product-owner, architect, developer, devops, docs-writer, security-reviewer (skippable); qa-engineer or runtime-proof (never).
# <area> (declared by the lead): contracts, authentication, secrets, data-migration, one-way-door.
# protected: prints "protected: no" (exit 0) or "protected: <why>" (exit 1). A slice is protected when its path list holds a path under
#   contracts/ or a path naming auth, secret or migration, or when the lead declares an area with --touches.
# check: prints "skip ok <role>" (exit 0) or "refused: <why>" (exit 1). Refused: QA and the runtime proof (never skipped), a missing or
#   blank reason, and any protected slice (no role is skipped for it).
# Exit: 0 allowed / not protected; 1 refused / protected; 2 usage, an unknown role or area, an unreadable path list.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="${1:-}"; [ $# -gt 0 ] && shift
usage() { echo "usage: skip.sh check <role> --reason <text> [--touches <area>]... <contract-file>... | skip.sh protected [--touches <area>]... <contract-file>..." >&2; exit 2; }
role=""; reason=""; areas=""; files=()
case "$cmd" in
  check) role="${1:-}"; [ -n "$role" ] || usage; shift ;;
  protected) ;;
  *) usage ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --reason) [ $# -ge 2 ] || usage; reason="$2"; shift 2 ;;
    --touches)
      [ $# -ge 2 ] || usage
      case "$2" in contracts | authentication | secrets | data-migration | one-way-door) areas="$areas $2" ;; *) echo "skip: unknown area: $2" >&2; exit 2 ;; esac
      shift 2 ;;
    -*) usage ;;
    *) files+=("$1"); shift ;;
  esac
done
[ ${#files[@]} -gt 0 ] || usage
for f in "${files[@]}"; do [ -r "$f" ] || { echo "skip: $f: unreadable" >&2; exit 2; }; done

prot=""
[ -n "$areas" ] && prot="declared: ${areas# }"
if [ -z "$prot" ]; then
  list="$(bash "$here/paths.sh" list "${files[@]}")" || { echo "skip: path list unreadable" >&2; exit 2; }
  while read -r kind p; do
    [ "$kind" = path ] || continue
    lp="$(printf '%s' "$p" | LC_ALL=C tr 'A-Z' 'a-z')"
    case "$lp" in
      contracts | contracts/* | *auth* | *secret* | *migrat*) prot="$p"; break ;;
    esac
  done <<LIST
$list
LIST
fi

if [ "$cmd" = protected ]; then
  if [ -n "$prot" ]; then echo "protected: $prot"; exit 1; fi
  echo "protected: no"; exit 0
fi

case "$role" in
  qa-engineer | runtime-proof) echo "refused: $role is never skipped"; exit 1 ;;
  product-owner | architect | developer | devops | docs-writer | security-reviewer) ;;
  *) echo "skip: unknown role: $role" >&2; exit 2 ;;
esac
case "$reason" in *[![:space:]]*) ;; *) echo "refused: a skip needs a written reason"; exit 1 ;; esac
if [ -n "$prot" ]; then echo "refused: the slice touches a protected area ($prot)"; exit 1; fi
echo "skip ok $role"
exit 0
