# Shared helpers for the factory script tests. Source it; do not run it.
# Each test file runs under bash 3.2 (macOS /bin/bash) and needs git, jq and a sha256 tool.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN="${FACTORY_ROOT:-$REPO/plugins/factory}"
FP="$PLUGIN/scripts/fingerprint.sh"
CB="$PLUGIN/scripts/check-bump.sh"
TS="$PLUGIN/scripts/token-spend.sh"
CO="$PLUGIN/scripts/cut-offs.sh"

fail=0
passed=0
skipped=0

# ck <name> <want> <got>
ck() {
  if [ "$2" = "$3" ]; then
    echo "ok   $1"; passed=$((passed + 1))
  else
    echo "FAIL $1"; echo "     want: $2"; echo "     got:  $3"; fail=1
  fi
}
# differ <name> <a> <b>: pass when a != b
differ() {
  if [ "$2" != "$3" ]; then
    echo "ok   $1"; passed=$((passed + 1))
  else
    echo "FAIL $1 (values equal: $2)"; fail=1
  fi
}
# skip <name> <reason>: a known defect or a missing optional input; reason names the QA finding.
skip() { echo "skip $1 -- $2"; skipped=$((skipped + 1)); }
# has <name> <file> <fixed string>: pass when the file contains the string
has() {
  if grep -qF -- "$3" "$2"; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$3' not in ${2#$REPO/}"; fail=1; fi
}
hasnt() {
  if grep -qF -- "$3" "$2"; then echo "FAIL $1: '$3' found in ${2#$REPO/}"; fail=1; else echo "ok   $1"; passed=$((passed + 1)); fi
}
done_() { echo "-- $(basename "$0"): $passed passed, $skipped skipped, fail=$fail"; exit $fail; }

T="$(mktemp -d "${TMPDIR:-/tmp}/factory-test.XXXXXX")"
trap 'chmod -R u+rwx "$T" 2>/dev/null; rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=qa GIT_AUTHOR_EMAIL=qa@example.invalid GIT_COMMITTER_NAME=qa GIT_COMMITTER_EMAIL=qa@example.invalid
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
line() { printf '%s\n' "$1" | sed -n "${2}p"; }
