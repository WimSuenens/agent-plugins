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

# ---- #307 the pin table is built from the stale-text table: its own item, right after the repo search item (not a copy of it)
pin a307-stale-sentences-searched-in-tests "Each sentence of the stale-text table is also searched over the test suite, and every hit becomes a pin row."
ck a307-own-item "- Each sentence of the stale-text table is also searched over the test suite, and every hit becomes a pin row." "$(item 'Each sentence of the stale-text table is also searched over the test suite')"
ck a307-follows-the-search-item 1 "$(done_of "$AR" | grep -B1 -F -- '- Each sentence of the stale-text table' | head -n1 | grep -cF 'the repo was searched (`grep -rn`) for every other text that states it')"

# ---- #308 whole-content guards per changed file of standard work, found by path or name
pin a308-whole-content-guards-listed "For every file of standard work the slice changes (the run skill, the references, the agent files), the release contract lists the tests that guard that file's whole content (allow-files, size caps, line caps), beside its pin table"
pin a308-found-by-path-not-sentence "found by searching the test suite for the file's path or name, not for a sentence"

# ---- the terms the three items use are defined once, in the Output section
output_of() { awk '/^## Output$/ {f=1; next} f && /^## / {f=0} f' "$AR"; }
def() { # def <name> <fixed string>, in the Output section of the architect
  if output_of | grep -qF -- "$2"; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$2' not in the Output section of ${AR#$REPO/}"; fail=1; fi
}
def terms-release-contract "A slice that changes the release (a new version) also gets a **release contract**"
def terms-stale-text-table "the **stale-text table** (the list of stale texts: every other text that states a rule, a name or a figure the slice changes, with where it sits and which role changes it)"
def terms-pin-table "the **pin table** (one **pin row** per test check that pins a sentence the slice changes: the test, the check, the text now and the text after)"

done_
