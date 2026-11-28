#!/bin/bash
# #309 and #310 (factory 3.12.0).
# #309: measure 3 counts a two-way decision as overturned only through an `Overturns:` line of a rework task, per decision, whatever its
#       `Source`; hansei records become v6; v5 records keep their meaning; a3-events.sh and the baseline read v6.
# #310: post-text.sh render refuses a draft whose `Artifacts:` line is not a list of repository paths, and anything it accepts the
#       close script parses entry for entry.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PROTO="$PLUGIN/references/protocol.md"
HA="$PLUGIN/references/hansei.md"
BL="$PLUGIN/references/baseline.md"
RUN="$PLUGIN/skills/run/SKILL.md"
OV="$PLUGIN/scripts/overturns.sh"
AE="$PLUGIN/scripts/a3-events.sh"
PT="$PLUGIN/scripts/post-text.sh"
CI="$PLUGIN/scripts/close-item.sh"
PY="$REPO/tests/factory/baseline_replay.py"
cd "$T" || exit 1

# ============================================================ #309: the feedback template and the texts
has ac1-feedback-template-overturns-line "$PROTO" '    Overturns: none | <role> — <the decision, in the words the role listed it under Decisions>'
has ac1-overturns-line-mandatory "$PROTO" '`Overturns:` is mandatory in every feedback'
has ac1-one-line-per-decision "$PROTO" 'A task that overturns two decisions has two lines.'
has ac1-source-says-who-routed "$PROTO" '`Source` says only who routed the work'
has ac1-doors-paragraph "$PROTO" 'may overturn it later through a feedback brief whose `Overturns:` line names it'
ck ac1-doors-no-source-lead-route 0 "$(grep -c 'overturn it later through a feedback brief with `Source: lead`' "$PROTO")"
# the template lines are in order: Source, Overturns, Findings
ck ac1-template-order "Source Overturns Findings" "$(awk '/^    # Feedback: /{f=1} f && /^    (Source|Overturns|Findings):/ {sub(/^    /, ""); sub(/:.*/, ""); printf "%s%s", s, $0; s=" "} /^    Re-verify:/{f=0}' "$PROTO")"
has ac1-run-rework-body-names-overturns "$RUN" 'the protocol'"'"'s feedback template (`Source`, `Overturns`, `Findings`, `Re-verify`; `Overturns: none` when the task overturns no decision)'
has ac1-run-overturn-names-decision "$RUN" 'its body names the decision on an `Overturns:` line'

has ac2-measure-3-counts-lines "$HA" 'then the number of two-way decisions overturned: the `Overturns:` lines that are not `none`, over every rework task of the slice, whatever its `Source`'
ck ac2-measure-3-no-source-lead-count 0 "$(grep -c 'overturned by a `Source: lead` rework task' "$HA")"
ck ac2-measure-3-source-cell-no-source-lead 0 "$(grep -c 'overturned = those whose body has `Source: lead`' "$HA")"
has ac2-measure-3-script "$HA" '`bash "<plugin root>/scripts/overturns.sh" <rework bodies>`'
has ac2-missing-line-not-zero "$HA" 'never `0` for a missing line'

# v6 marker in the template and the worked example; the versions paragraph says what v6 changed
TEMPLATE="$(awk '/^### Layout$/{f=1;next} f && /^```$/{n++; if(n==2) exit; next} f && n==1' "$HA")"
EXAMPLE="$(awk '/^### Worked example$/{f=1;next} f && /^```$/{n++; if(n==2) exit; next} f && n==1' "$HA")"
ck ac5-template-marker-v6 '<!-- factory:hansei v6 -->' "$(printf '%s\n' "$TEMPLATE" | sed -n 1p)"
ck ac5-example-marker-v6 '<!-- factory:hansei v6 -->' "$(printf '%s\n' "$EXAMPLE" | sed -n 1p)"
has ac5-marker-prose-v6 "$HA" 'The body'"'"'s **first line** is exactly `<!-- factory:hansei v6 -->`.'
has ac5-versions-v6 "$HA" 'v6 (release 3.12.0) changes the meaning of one count'
has ac5-v5-not-recomputed "$HA" 'A v5 record keeps its old meaning and is never recomputed.'
has ac5-reads-v3-to-v6 "$HA" '**Which versions the standard reads.** v3, v4, v5 and v6.'
has ac5-baseline-reads-v6 "$BL" '`v3`, `v4`, `v5` and `v6` are readable. Any other version is **skipped and named**'
has ac5-worked-example-overturns-line "$HA" '`Overturns: architect — CSV delimiter: semicolon`'

# ============================================================ #309: overturns.sh
fb() { # fb <file> <source> <overturns lines...>
  f="$1"; s="$2"; shift 2
  { echo "<!-- factory:task v1 role=developer n=4 -->"; echo "# Feedback: developer — 12"; echo "Source: $s"
    for l in "$@"; do echo "$l"; done
    echo "Findings:"; echo "1. src/a.ts — minor — fix"; echo "Re-verify: tests"; } >"$f"
}
# the 3.9.1 case: three lead-routed rework tasks (a security finding, a contract update, a regression test), no overturn
fb r1.md lead "Overturns: none"; fb r2.md lead "Overturns: none"; fb r3.md lead "Overturns: none"
out="$(bash "$OV" r1.md r2.md r3.md 2>&1)"; rc=$?
ck ac3-three-source-lead-no-overturn-rc 0 "$rc"
ck ac3-three-source-lead-no-overturn-zero 0 "$out"
# one task overturning two decisions adds 2; Source plays no part (qa-routed overturn counts)
fb r4.md lead "Overturns: architect — CSV delimiter: semicolon" "Overturns: developer — retry count: 3"
fb r5.md qa "Overturns: product-owner — export limit: 10000 rows"
ck ac4-two-lines-add-two 2 "$(bash "$OV" r4.md 2>/dev/null)"
ck ac4-sum-over-tasks-any-source 3 "$(bash "$OV" r1.md r4.md r5.md 2>/dev/null)"
ck ac4-no-rework-reads-zero 0 "$(bash "$OV" 2>/dev/null)"
printf '# Feedback: developer — 12\r\nSource: lead\r\nOverturns: architect — CSV delimiter: semicolon\r\nFindings:\r\n' >crlf.md
ck ac4-crlf-body 1 "$(bash "$OV" crlf.md 2>/dev/null)"
# a missing line is a template error, not a zero
fb r6.md lead
out="$(bash "$OV" r1.md r6.md 2>&1 >/dev/null)"; rc=$?
ck ac2-missing-line-rc 3 "$rc"
ck ac2-missing-line-names-file 1 "$(printf '%s' "$out" | grep -c 'r6.md: no Overturns line')"
ck ac2-missing-line-prints-no-count "" "$(bash "$OV" r1.md r6.md 2>/dev/null)"
fb r7.md lead "Overturns: none" "Overturns: architect — CSV delimiter: semicolon"
bash "$OV" r7.md >/dev/null 2>&1; ck ac2-none-beside-a-decision-rc 3 "$?"
fb r8.md lead "Overturns: the delimiter"
out="$(bash "$OV" r8.md 2>&1 >/dev/null)"; rc=$?
ck ac2-no-role-rc 3 "$rc"
ck ac2-no-role-names-line 1 "$(printf '%s' "$out" | grep -c 'r8.md:4: ')"
bash "$OV" nothere.md >/dev/null 2>&1; ck ov-unreadable-rc 2 "$?"
# a line quoted inside the findings is not counted (only the head before `Findings:` is read)
{ cat r1.md; echo "Overturns: architect — quoted in a finding"; } >r9.md
ck ov-findings-text-not-counted 0 "$(bash "$OV" r9.md 2>/dev/null)"

# ============================================================ #309: a3-events.sh reads v6
rec6() { # rec6 <file> <n>
  { echo "<!-- factory:hansei v6 -->"; echo "## Hansei: #40 x"; echo; echo "### Measures"; echo
    echo "3. rework: feedback briefs product-owner 0, architect 0, developer 3, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions $2"; } >"$1"
}
rec6 h1.md 1; rec6 h0.md 0
ck ac6-v6-overturned-raised 1 "$(bash "$AE" --item 40 --hansei h1.md 2>/dev/null | grep -c '^  event: overturned #40 1 two-way decision — cause: ?$')"
ck ac6-v6-zero-silent 0 "$(bash "$AE" --item 40 --hansei h0.md 2>/dev/null | grep -c 'overturned')"

# ============================================================ #309: the baseline reads v6, skips v7
if command -v python3 >/dev/null; then
  FX="$REPO/tests/factory/fixtures/baseline/records"
  b6="$(sed -e 's/^<!-- factory:hansei v5 -->$/<!-- factory:hansei v6 -->/' -e 's/^- plugin: factory 1.1.0$/- plugin: factory 3.12.0/' "$FX/x5v5.md")"
  jq -n --arg b "$b6" '{id: 9131, html_url: "u6", created_at: "2026-12-01T00:00:00Z", user: {login: "lead-qa"}, body: $b}' -c >v6.jsonl
  out="$(python3 -I "$PY" body v6.jsonl 3.12.0 - /dev/null)"
  ck ac5-baseline-v6-read 1 "$(printf '%s\n' "$out" | grep -c '^- items: 1 items: #131 u6')"
  ck ac5-baseline-v6-not-skipped 0 "$(printf '%s\n' "$out" | grep -c 'schema v6')"
  ck ac5-baseline-v6-overturned-read 1 "$(printf '%s\n' "$out" | grep -c 'overturned two-way decisions 0 (1 of 1 items)')"
  b7="$(printf '%s' "$b6" | sed 's/^<!-- factory:hansei v6 -->$/<!-- factory:hansei v7 -->/')"
  jq -n --arg b "$b7" '{id: 9132, html_url: "u7", created_at: "2026-12-01T00:00:00Z", user: {login: "lead-qa"}, body: $b}' -c >v7.jsonl
  ck ac5-baseline-v7-skipped 1 "$(python3 -I "$PY" body v7.jsonl 3.12.0 - /dev/null | grep -c 'skipped: #131 u7 (schema v7)')"
else
  echo "skip: python3 missing (baseline v6 replay)"; skipped=$((skipped + 1))
fi

# ============================================================ #310: render checks the Artifacts line
has ac310-template-grammar "$PROTO" '    Artifacts: <repository paths, separated by ", ", or none>'
has ac310-template-grammar-prose "$PROTO" '`Artifacts:` is one line: repository paths relative to the repository root, separated by a comma and one space, and nothing else'
has ac310-run-skill-names-check "$RUN" 'an `Artifacts:` line that is not a list of repository paths'
dr() { # dr <file> <artifacts line or "-" for none>
  { echo "# Result: developer — 12"; echo "Status: done"; echo "Abnormality: none"; echo "Summary: built it"
    [ "$2" = "-" ] || echo "Artifacts:$2"; echo "Decisions: none"; } >"$1"
}
dr ok.md " plugins/factory/scripts/a.sh, tests/factory/test_a.sh, docs/x.md"
bash "$PT" render ok.md out-ok.md >/dev/null 2>&1; ck ac310-valid-list-rc 0 "$?"
dr none.md " none"
bash "$PT" render none.md out-none.md >/dev/null 2>&1; ck ac310-none-rc 0 "$?"
dr noline.md "-"
bash "$PT" render noline.md out-noline.md >/dev/null 2>&1; ck ac310-no-artifacts-line-rc 0 "$?"
dr bt.md ' `docs/x.md`, `tests/y.sh`'
bash "$PT" render bt.md out-bt.md >/dev/null 2>&1; ck ac310-backticked-paths-rc 0 "$?"
# output unchanged from the release before for valid drafts
OLD="$(git -C "$REPO" show origin/main:plugins/factory/scripts/post-text.sh 2>/dev/null)"
if [ -n "$OLD" ] && ! printf '%s' "$OLD" | grep -q 'Artifacts entry'; then
  printf '%s\n' "$OLD" >old-pt.sh
  for d in ok none noline bt; do
    bash old-pt.sh render "$d.md" "old-$d.md" >/dev/null 2>&1
    ck "ac310-output-unchanged-$d" "$(cat "old-$d.md")" "$(cat "out-$d.md")"
  done
else
  echo "skip: origin/main already has the Artifacts check (output comparison)"; skipped=$((skipped + 1))
fi
# prose is refused, naming the bad entry; nothing written
dr prose.md " tests/factory/a.sh, the test files b.sh and c.sh"
out="$(bash "$PT" render prose.md out-prose.md 2>&1)"; rc=$?
ck ac310-prose-rc 3 "$rc"
ck ac310-prose-names-entry 1 "$(printf '%s\n' "$out" | grep -cF 'render: prose.md: Artifacts entry is not a repository path: the test files b.sh and c.sh')"
ck ac310-prose-good-entry-not-named 0 "$(printf '%s\n' "$out" | grep -cF 'path: tests/factory/a.sh')"
ck ac310-prose-no-output "no" "$([ -e out-prose.md ] && echo yes || echo no)"
dr paren.md " tests/factory/a.sh (new), docs/x.md"
out="$(bash "$PT" render paren.md out-paren.md 2>&1)"; rc=$?
ck ac310-parenthetical-rc 3 "$rc"
ck ac310-parenthetical-names-entry 1 "$(printf '%s\n' "$out" | grep -cF 'render: paren.md: Artifacts entry is not a repository path: tests/factory/a.sh (new)')"
dr sentence.md " Updated the contract and the tests."
bash "$PT" render sentence.md out-s.md >/dev/null 2>&1; ck ac310-sentence-rc 3 "$?"
dr empty.md ""
out="$(bash "$PT" render empty.md out-e.md 2>&1)"; rc=$?
ck ac310-empty-value-rc 3 "$rc"
ck ac310-empty-value-says-none 1 "$(printf '%s\n' "$out" | grep -cF 'render: empty.md: Artifacts is empty; write none')"
for bad in "/abs/x.md" "../x.md" "a/../../x.md" "~/x.md" "#12" "https://example.invalid/x" "docs/*.md" "None" "-" "a.md,b.md" "a.md, "; do
  dr bad.md " $bad"
  bash "$PT" render bad.md out-b.md >/dev/null 2>&1; ck "ac310-refused-[$bad]" 3 "$?"
done
# a list continued on a second line is refused (the close script reads the first line only)
{ echo "Status: done"; echo "Summary: s"; echo "Artifacts: docs/x.md,"; echo "  tests/y.sh"; echo; echo "Decisions: none"; } >cont.md
out="$(bash "$PT" render cont.md out-c.md 2>&1)"; rc=$?
ck ac310-continuation-rc 3 "$rc"
ck ac310-continuation-named 1 "$(printf '%s\n' "$out" | grep -cF 'render: cont.md: Artifacts continues on a second line:   tests/y.sh')"
# the scan still runs first: a secret in a bad entry is never echoed
{ echo "Status: done"; echo "Summary: s"; echo "Artifacts: x (gh""p_aaaaaaaaaaaaaaaaaaaaaaaaa)"; } >sec.md
out="$(bash "$PT" render sec.md out-sec.md 2>&1)"; rc=$?
ck ac310-secret-scan-first-rc 1 "$rc"
ck ac310-secret-not-echoed 0 "$(printf '%s\n' "$out" | grep -c 'gh''p_')"

# render accepts -> the close script parses the same entries: every accepted entry is checked at HEAD, by its own name
mk() { rm -rf m m-wt; mkdir m && (cd m && git init -q -b main . && git config commit.gpgsign false && echo b >R && git add -A && git commit -q -m b && git worktree add -q -b item/5 ../m-wt >/dev/null 2>&1); mkdir -p m-wt/work/5; }
mk
cp bt.md m-wt/work/5/01-result-developer.md
out="$(cd m && bash "$CI" 5 2>&1)"; rc=$?
ck ac310-close-refuses-uncommitted-accepted-entries 1 "$rc"
ck ac310-close-names-each-accepted-entry "docs/x.md tests/y.sh" "$(printf '%s\n' "$out" | sed -n 's/^close: \([^ ]*\) is named by .*/\1/p' | tr '\n' ' ' | sed 's/ $//')"
mkdir -p m-wt/docs m-wt/tests; echo x >m-wt/docs/x.md; echo y >m-wt/tests/y.sh; git -C m-wt add docs tests; git -C m-wt commit -q -m files
(cd m && bash "$CI" 5 >/dev/null 2>&1); ck ac310-close-passes-once-committed 0 "$?"

echo "-- $(basename "$0"): $passed passed, $skipped skipped, fail=$fail"
exit $fail
