# Shared helpers for the factory script tests. Source it; do not run it.
# Each test file runs under bash 3.2 (macOS /bin/bash) and needs git, jq and a sha256 tool.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN="${FACTORY_ROOT:-$REPO/plugins/factory}"
FP="$PLUGIN/scripts/fingerprint.sh"
CB="$REPO/scripts/check-bump.sh"
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
# flow_table_text: a minimal valid flow table section (what setup-table.sh writes), for tests where `state` has to pass (#207 slice 3)
flow_table_text() {
  printf '\n## Flow table\n\ntable: provisional\nfloor: never removed by the table\n\n| Trigger | Points | Adds | Reason | Status |\n|---|---|---|---|---|\n'
  for i in 1 2 3 4 5 6 7 8; do printf '| Trigger %s | 1 | x | r | provisional |\n' "$i"; done
}
line() { printf '%s\n' "$1" | sed -n "${2}p"; }

# The run skill is a router (skills/run/SKILL.md) plus reference files (references/run-*.md), #207 split before slice 4.
# run_refs: the reference files, sorted. run_all: router then every reference, concatenated.
# run_all_file: that text in a file under $T (made once), for the pins that grep the whole skill.
# run_section <heading text>: the section that starts at that heading, from the reference that holds it, else from the router;
#   it ends at the next heading of the same or a higher level; headings inside a code fence are not headings.
# run_section_file <heading text>: the name of the file that holds that section (the references first).
RUN_ROUTER="$PLUGIN/skills/run/SKILL.md"
run_refs() { ls "$PLUGIN"/references/run-*.md 2>/dev/null | LC_ALL=C sort; }
run_all() { cat "$RUN_ROUTER"; local r; for r in $(run_refs); do printf '\n'; cat "$r"; done; }
run_all_file() { local f="$T/run-all.md"; [ -s "$f" ] || run_all >"$f"; printf '%s\n' "$f"; }
_run_sect_awk() {
  awk -v n="$1" '
    /^```/ { fence = !fence; if (on) print; next }
    !fence && /^#+ / { match($0, /^#+/); lvl = RLENGTH; t = substr($0, lvl + 2)
      if (on && lvl <= L) exit
      if (!on && t == n) { on = 1; L = lvl } }
    on { print }' "$2"
}
run_section() { local f s; for f in $(run_refs) "$RUN_ROUTER"; do s="$(_run_sect_awk "$1" "$f")"; if [ -n "$s" ]; then printf '%s\n' "$s"; return 0; fi; done; return 1; }
run_section_file() { local f; for f in $(run_refs) "$RUN_ROUTER"; do if [ -n "$(_run_sect_awk "$1" "$f")" ]; then printf '%s\n' "$f"; return 0; fi; done; return 1; }
# run_step8: step 8 as one text (the router's section: heading, intro and 8.1; then the reference with 8.2 to 8.11 and the Done when).
# run_andon: the old "## Andon" section as one text in its old order: Andon and Detection, then Procedure, The 5 Whys, Overrides, Run identity, Run start, Settle round, The comment.
run_step8() { _run_sect_awk "8. Close the item and resurvey" "$RUN_ROUTER"; cat "$PLUGIN/references/run-close-item.md"; }
run_andon() { run_section Andon; local h; for h in Procedure "The 5 Whys" Overrides "Run identity" "Run start" "Settle round" "The comment"; do run_section "$h"; done; }
