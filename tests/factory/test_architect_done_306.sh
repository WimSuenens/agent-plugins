#!/bin/bash
# #306, #307, #308 (factory 3.11.0): three items of the architect's Done list, one pin per rule. Each pin was written before the text it pins.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
AR="$PLUGIN/agents/architect.md"
done_of() { awk '/^## Done$/ {f=1; next} f && /^## / {f=0} f' "$1"; }
pin() { # pin <name> <fixed string>, in the Done list of the architect
  if done_of "$AR" | grep -qF -- "$2"; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$2' not in the Done list of ${AR#$REPO/}"; fail=1; fi
}
# item <fixed string>: the Done item that holds the string
item() { done_of "$AR" | grep -F -- "$1"; }

# ---- #306 a claim over the whole suite is checked or named unverified
pin a306-claim-over-the-suite-checked "A claim about every fixture, file or case of the suite is checked against the suite before hand-back, or named unverified in the contract."

# ---- #307 the pin table is built from the stale-text table, in the existing search item (not a second item)
pin a307-stale-sentences-searched-in-tests "Each sentence of the stale-text table is also searched over the test suite, and every hit becomes a pin row."
ck a307-extends-the-search-item 1 "$(item 'Each sentence of the stale-text table is also searched over the test suite' | grep -cF 'the repo was searched (`grep -rn`) for every other text that states it')"

# ---- #308 whole-content guards per changed standard file, found by path or name
pin a308-whole-content-guards-listed "For every standard file the slice changes, the release contract lists the tests that guard that file's whole content (allow-files, size caps, line caps), beside its sentence pins"
pin a308-found-by-path-not-sentence "found by searching the test suite for the file's path or name, not for a sentence"

done_
