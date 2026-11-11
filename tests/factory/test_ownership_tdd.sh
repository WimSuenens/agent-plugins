#!/bin/bash
# Slice 73, test ownership and the TDD loop (release 2.1.0): the machine-checkable parts of AC-1 to AC-9.
# Run on its own:  bash tests/factory/test_ownership_tdd.sh     (prints "-- test_ownership_tdd.sh: N passed, N skipped, fail=0|1")
# Scope (AC-3 of this slice applies to this file too): structure, placement, names, byte comparisons against the baseline, the version.
# No broad exact-prose assertions: instruction-following is judged on the scenario cards in tests/factory/scenarios/ (human review).
# Exact text appears only for the gate lines (AC-7), which are taken FROM the baseline commit, never copied here.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
cd "$REPO" || exit 1

BASE=4086c9c   # the run's FREEZE, factory 2.0.0
if ! git cat-file -e "$BASE^{commit}" 2>/dev/null; then
  skip ownership-tdd-all "baseline commit $BASE is not in this clone; the slice-73 text checks need it"
  done_
fi

P="plugins/factory"
PROTO="$REPO/$P/references/protocol.md"
DEV="$REPO/$P/agents/developer.md"
QA="$REPO/$P/agents/qa-engineer.md"
ARCH="$REPO/$P/agents/architect.md"
RUN="$REPO/$P/skills/run/SKILL.md"
TPL="$REPO/$P/skills/setup-factory-skill/assets/factory.md"
SEC="$P/agents/security-reviewer.md"
HANS="$REPO/$P/references/hansei.md"
FILES="$PROTO $DEV $QA $ARCH $RUN $TPL"

base() { git show "$BASE:$P/$1"; }                         # a baseline file on stdout
# sect <file> <heading line>: the lines after the heading up to the next heading of the same or higher level
sect() { awk -v h="$2" 'BEGIN{n=0; while (substr(h,n+1,1)=="#") n++} f==0 && $0==h {f=1; next} f==1 && /^#+ / {m=0; while (substr($0,m+1,1)=="#") m++; if (m<=n) exit} f==1 {print}' "$1"; }
# lineno <file> <fixed string>: first line number holding the string, or 0
lineno() { local n; n="$(grep -nF -- "$2" "$1" | head -1 | cut -d: -f1)"; echo "${n:-0}"; }
# lineno_start <file> <prefix>: first line number starting with the prefix, or 0
lineno_start() { local n; n="$(grep -nF -- "$2" "$1" | awk -v p="$2" -F: '{ s=substr($0, index($0,":")+1); if (index(s,p)==1) {print $1; exit} }')"; echo "${n:-0}"; }
# in <name> <text> <fixed string>: pass when the text holds the string
in_() { if grep -qF -- "$3" <<<"$2"; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$3' missing"; fail=1; fi; }
# inre <name> <text> <ERE, case-insensitive>
inre() { if grep -qiE -- "$3" <<<"$2"; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: /$3/ not matched"; fail=1; fi; }
# kept <name> <new file> <baseline file under plugins/factory> <baseline line prefix>: the whole baseline line that starts with the prefix is still a line of the new file
kept() {
  local l; l="$(base "$3" | grep -F -- "$4" | awk -v p="$4" 'index($0,p)==1 {print; exit}')"
  if [ -z "$l" ]; then echo "FAIL $1: no baseline line starts with '$4'"; fail=1
  elif grep -qxF -- "$l" "$2"; then echo "ok   $1"; passed=$((passed + 1))
  else echo "FAIL $1: baseline line '$4...' is not a line of ${2#$REPO/}"; fail=1; fi
}
# added <file under plugins/factory>: the lines the new file adds against the baseline
added() { diff <(base "$1") "$REPO/$P/$1" | sed -n 's/^> //p'; }

# =============================================================== the section placement in the protocol
ck proto-tests-heading-once 1 "$(grep -c '^## Tests$' "$PROTO")"
o="$(lineno_start "$PROTO" '## Ownership')"; t="$(lineno_start "$PROTO" '## Tests')"; s="$(lineno_start "$PROTO" '## Shell')"
ck proto-tests-after-ownership-before-shell 1 "$([ "$o" -gt 0 ] && [ "$t" -gt "$o" ] && [ "$s" -gt "$t" ] && echo 1 || echo 0)"
PT="$(sect "$PROTO" '## Tests')"

# =============================================================== AC-1 tests/ is QA-owned, the developer never edits it
# the template's ownership table: `tests/` in the Path cell of the qa-engineer row and of no other row
rows="$(awk -F'|' '/^\| / && $2 ~ /`tests\/`/ {gsub(/^ +| +$/,"",$3); print $3}' "$TPL")"
ck ac1-template-tests-on-exactly-one-row 1 "$(printf '%s\n' "$rows" | grep -c .)"
ck ac1-template-tests-row-is-qa-engineer "qa-engineer" "$rows"
ck ac1-template-no-other-row-names-tests-path 1 "$(awk -F'|' '/^\| / && $2 ~ /tests\// {n++} END {print n+0}' "$TPL")"
# one sentence in the developer file: no create, edit or delete under tests/
inre ac1-dev-never-touches-tests "$(grep -F 'tests/' "$DEV")" 'create, edit or delete'
inre ac1-dev-sentence-says-QA-owns "$(grep -F 'create, edit or delete' "$DEV")" 'QA'
inre ac1-qa-owns-tests "$(cat "$QA")" 'own[s]? `tests/`'
inre ac1-qa-prepares-tests-the-developer-runs "$(cat "$QA")" 'prepares? the tests? the developer runs'
inre ac1-protocol-states-ownership "$PT" 'tests/.*(qa-engineer|QA)|(qa-engineer|QA).*tests/'
inre ac1-protocol-developer-never-edits "$PT" '(never|not)[^.]*(creates?|edits?|deletes?)'

# =============================================================== AC-2 the loop, in order, in each file that owns a step
inre ac2-protocol-loop-targeted-test "$PT" 'targeted test'
inre ac2-protocol-unclear-returns-to-QA-or-lead "$PT" 'unclear[^.]*(QA|lead)|(QA|lead)[^.]*unclear'
inre ac2-protocol-developer-runs-until-green "$PT" 'until green'
inre ac2-dev-runs-targeted-test-until-green "$(cat "$DEV")" 'targeted test[^.]*until green|until green[^.]*targeted test'
inre ac2-dev-unclear-goes-to-lead "$(cat "$DEV")" '(question|ask)[^.]*(lead|QA)'
ck ac2-dev-input-names-targeted-test 1 "$(sect "$DEV" '## Inputs needed' | grep -ciE 'targeted test' | awk '{print ($1>0)}')"
inre ac2-qa-prepares-before-build "$(cat "$QA")" 'before (the|its) (build|behaviour)'
inre ac2-qa-names-the-targeted-test "$(cat "$QA")" 'targeted test'
ck ac2-qa-input-lists-contracts "1" "$(sect "$QA" '## Inputs needed' | grep -ciE 'contract' | awk '{print ($1>0)}')"
inre ac2-architect-seams "$(cat "$ARCH")" 'seams?'
inre ac2-architect-expected-behaviour "$(cat "$ARCH")" 'expected behaviou?r'
inre ac2-architect-done-line-qa-can-prepare "$(sect "$ARCH" '## Done')" 'seams?[^.]*expected behaviou?r|expected behaviou?r[^.]*seams?'
# the run skill: the stage table gets a Tests row for qa-engineer between Contracts and Build
c="$(lineno_start "$RUN" '| Contracts and ADRs |')"; tr="$(lineno_start "$RUN" '| Tests')"; b="$(lineno_start "$RUN" '| Build, tracer bullet first |')"
ck ac2-run-table-tests-row-between-contracts-and-build 1 "$([ "$c" -gt 0 ] && [ "$tr" -gt "$c" ] && [ "$b" -gt "$tr" ] && echo 1 || echo 0)"
ck ac2-run-tests-row-role-is-qa-engineer "qa-engineer" "$(sed -n "${tr}p" "$RUN" | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')"
ck ac2-run-build-row-unchanged 1 "$(grep -cxF '| Build, tracer bullet first | developer |' "$RUN")"
inre ac2-run-developer-brief-names-the-targeted-test "$(grep -i 'inputs' "$RUN")" 'targeted test'
inre ac2-run-contracts-define-seams "$(cat "$RUN")" 'seams?|expected behaviou?r'
inre ac2-run-qa-tests-before-build-brief "$(cat "$RUN")" 'Tests (stage|task|result)'
# the ledger stage list gains Tests, after Contracts and ADRs
ck ac2-hansei-stage-list-has-tests-after-contracts 1 "$(grep -cF '`Contracts and ADRs`, `Tests`, `Environment`' "$HANS")"
# nobody gives the developer the suite: the baseline phrases are gone from every file
for f in $FILES; do
  hasnt "ac2-no-test-first-with-in-$(basename "$f")" "$f" 'test first with'
  hasnt "ac9-no-has-a-passing-test-in-$(basename "$f")" "$f" 'has a passing test'
done
# no file lets the developer create or edit under tests/ (lines with a negation are statements of the rule)
for f in $FILES; do
  ck "ac9-no-file-lets-developer-edit-tests-$(basename "$f")" 0 "$(grep -iE 'developer[^|]*(may|can|writes?|creates?|edits?|adds?)[^|]*`tests/`' "$f" | grep -viE "never|not|n't|no " | grep -c .)"
done

# =============================================================== AC-3 test scope
for pair in "protocol|$PT" "qa|$(cat "$QA")"; do
  nm="${pair%%|*}"; txt="${pair#*|}"
  inre "ac3-$nm-automated-behaviour-and-safety-invariants" "$txt" 'automat[^.]*safety invariants?|safety invariants?[^.]*automat'
  inre "ac3-$nm-instruction-following-by-scenarios-and-human-review" "$txt" 'instruction-following[^.]*(scenario|human review)'
  inre "ac3-$nm-exact-text-only-for-machine-readable-and-safety" "$txt" 'exact[- ]text[^.]*machine-readable|machine-readable[^.]*exact'
done
ck ac3-qa-done-line-1-no-longer-plain-test "0" "$(grep -cxF -- '- Every acceptance criterion maps to a test.' "$QA")"
QD="$(sect "$QA" '## Done')"
inre ac3-qa-done-maps-to-test-scenario-or-human-list "$(printf '%s\n' "$QD" | grep -m1 '^- ')" 'maps to a test, a scenario, or the Human-only'
inre ac3-qa-done-verdict-lists-each "$(printf '%s\n' "$QD" | grep -m1 '^- ')" 'verdict lists each'
ck ac3-qa-step-1-no-longer-one-test-per-criterion 0 "$(grep -cF 'Derive at least one test per acceptance criterion.' "$QA")"
inre ac3-qa-step-1-offers-three-kinds "$(sect "$QA" '## Steps')" 'scenario[^.]*Human-only|Human-only[^.]*scenario'
inre ac3-qa-never-needs-a-broad-prose-assertion "$(cat "$QA")" 'exact-prose|prose assertion'

# =============================================================== AC-4 optional code review (run skill)
ck ac4-run-review-heading-once 1 "$(grep -c '^### Optional code review$' "$RUN")"
h="$(lineno_start "$RUN" '### Optional code review')"; e="$(lineno_start "$RUN" '### Environment and shared resources')"
ck ac4-run-review-section-before-environment 1 "$([ "$h" -gt 0 ] && [ "$e" -gt "$h" ] && echo 1 || echo 0)"
RV="$(sect "$RUN" '### Optional code review')"
in_ ac4-trigger-shared-protocols "$RV" 'shared protocols or approval/state rules'
in_ ac4-trigger-broad-cross-plugin "$RV" 'broad cross-plugin changes'
in_ ac4-trigger-significant-refactors "$RV" 'significant refactors'
inre ac4-review-is-optional "$RV" 'optional'
inre ac4-review-covers-standards-spec-scope "$RV" 'standards, spec and scope'
inre ac4-review-does-not-repeat-qa-or-security "$RV" 'not repeat[^.]*QA[^.]*security|QA[^.]*security scan'
inre ac4-duplicates-are-combined "$RV" 'duplicate[^.]*combined|combine[^.]*duplicate'
in_ ac4-decision-line-names-trigger-or-no-trigger "$RV" 'no trigger'
inre ac4-decision-is-written-in-lead-state-and-stage-summary "$RV" 'lead state[^.]*stage summary|stage summary[^.]*lead state'
inre ac4-review-has-no-verdict-and-replaces-nothing "$RV" 'no verdict|cannot replace'
# the decision sits between the contracts stage and the build: a pointer under the table, and the stage-loop done bullet
sg="$(lineno_start "$RUN" 'The **stage** of a slice is the role task')"; pt="$(grep -n 'Optional code review' "$RUN" | awk -F: -v lo="$b" -v hi="$sg" '$1>lo && $1<hi {print $1; exit}')"
ck ac4-run-pointer-under-the-table 1 "$([ -n "$pt" ] && echo 1 || echo 0)"
inre ac4-run-done-bullet-takes-the-decision-then-briefs-qa "$(cat "$RUN")" 'code-review decision[^.]*then brief QA'
# the diff-breadth check: every slice, before Open PR
bk="$(lineno "$RUN" 'check the diff for breadth')"; op="$(lineno_start "$RUN" 'Open the PR (*Open PR*) when the developer is done')"
ck ac4-run-breadth-check-before-open-pr 1 "$([ "$bk" -gt 0 ] && [ "$op" -gt "$bk" ] && echo 1 || echo 0)"
inre ac4-run-breadth-names-breadth-and-scope-creep "$(cat "$RUN")" 'unexpected breadth or scope creep'
# nothing added by this slice makes QA, security or the bump check optional (AC-4 contradiction, AC-7)
for f in references/protocol.md agents/developer.md agents/qa-engineer.md agents/architect.md skills/run/SKILL.md skills/setup-factory-skill/assets/factory.md; do
  ck "ac4-no-added-line-makes-qa-or-security-optional-$(basename "$f")" 0 "$(added "$f" | grep -iE '(security( review)?|QA( verdict)?|verdict|check-bump( gate)?) (is|are|becomes?|be|made|stays?|remains?|as) optional|optional (security|QA|verdict)' | grep -viE 'not (made )?optional|never|no sentence' | grep -c .)"
done
inre ac4-protocol-security-review-stays-mandatory "$PT" 'security[^.]*mandatory'

# =============================================================== AC-5 the developer's Done list and Steps
DD="$(sect "$DEV" '## Done')"; DS="$(sect "$DEV" '## Steps')"
inre ac5-done-requires-running-targeted-test "$DD" 'targeted test'
inre ac5-done-requires-repo-test-and-lint "$DD" 'test and lint'
inre ac5-done-exit-0 "$DD" 'exit(s)? 0'
inre ac5-done-lists-changed-files-and-open-questions "$DD" 'changed files[^.]*open questions'
ck ac5-done-baseline-line-deleted 0 "$(grep -cF 'Every acceptance criterion of the item has a passing test.' "$DEV")"
ck ac5-done-does-not-make-developer-own-acceptance-tests 0 "$(printf '%s\n' "$DD" | grep -ciE 'acceptance (criteri|test|suite)')"
ck ac5-steps-no-derive-or-write-acceptance-tests 0 "$(printf '%s\n' "$DS" | grep -iE '(write|derive|own|create)[^.]*acceptance (criteri|test|suite)' | grep -viE "not|never|n't" | grep -c .)"
ck ac5-steps-run-targeted-test-before-repo-commands 1 "$(printf '%s\n' "$DS" | awk '/targeted test/ && !a {a=NR} /repo.s own test/ && !b {b=NR} END {print (a>0 && b>a) ? 1 : 0}')"
has ac5-tdd-skill-stays-for-own-tests "$DEV" 'mattpocock-skills:tdd'

# =============================================================== AC-6 the developer's own tests, in two places
inre ac6-dev-own-tests-sit-in-the-src-row "$(cat "$DEV")" '`src/`'
inre ac6-dev-own-tests-not-the-acceptance-suite "$(cat "$DEV")" 'not the acceptance suite'
inre ac6-dev-qa-may-read-run-and-ignore "$(cat "$DEV")" 'read, run and ignore'
inre ac6-dev-acceptance-suite-is-tests "$(cat "$DEV")" 'acceptance suite is `tests/`'
inre ac6-dev-harness-case "$(cat "$DEV")" 'harness'
TP="$(awk '/^Tests\./ {f=1} f {print} f && /^$/ {exit}' "$TPL")"
ck ac6-template-has-a-Tests-paragraph 1 "$(printf '%s\n' "$TP" | grep -c '^Tests\.')"
tb="$(lineno_start "$TPL" 'Tests.')"; ow="$(lineno_start "$TPL" '## Ownership')"; nx="$(awk -v s="$ow" 'NR>s && /^## / {print NR; exit}' "$TPL")"
ck ac6-template-Tests-paragraph-inside-ownership-section 1 "$([ "$tb" -gt "$ow" ] && { [ -z "$nx" ] || [ "$tb" -lt "$nx" ]; } && echo 1 || echo 0)"
inre ac6-template-own-tests-under-src-row "$TP" 'src/'
inre ac6-template-not-the-acceptance-suite "$TP" 'not the acceptance suite'
inre ac6-template-qa-may-read-run-and-ignore "$TP" 'read, run and ignore'
inre ac6-template-harness-case "$TP" 'harness'
ck ac6-protocol-does-not-let-developer-create-tests-in-tests 0 "$(printf '%s\n' "$PT" | grep -iE 'developer[^.]*(may|can)[^.]*(create|write|add)[^.]*tests/' | grep -c .)"
ck ac6-template-src-row-still-developer 1 "$(awk -F'|' '/^\| / && $2 ~ /`src\/`/ {gsub(/^ +| +$/,"",$3); print $3}' "$TPL" | grep -cx developer)"
inre ac6-setup-skill-unit-tests-beside-code "$(cat "$REPO/$P/skills/setup-factory-skill/SKILL.md")" 'unit tests[^.]*beside the code'
inre ac6-architect-lists-developer-own-tests-in-paths "$(cat "$ARCH")" 'own tests'

# =============================================================== AC-7 the gates, word for word, taken from the baseline
kept ac7-qa-authority-line "$QA" agents/qa-engineer.md 'Owns the release verdict.'
kept ac7-qa-defect-fields-line "$QA" agents/qa-engineer.md 'Each defect carries reproduction steps'
kept ac7-qa-done-defect-reproduction "$QA" agents/qa-engineer.md '- Every defect has a reproduction.'
kept ac7-qa-done-verdict-recorded "$QA" agents/qa-engineer.md '- The verdict is recorded, with its Human-only criteria list.'
has ac7-qa-done-changed-paths-line "$QA" '- Changed paths checked against the item'  # line later extended by #86, so no longer byte-equal to the baseline
has ac7-qa-reads-requirement-sentence "$QA" 'Tests come from the requirement; read the implementation only to locate the cause of a failure.'
step="$(base agents/qa-engineer.md | grep -F 'Write `reviews/qa-<id>.md`' | sed 's/^[0-9]*\. //')"
if [ -n "$step" ]; then has ac7-qa-verdict-step-with-human-only-list "$QA" "$step"; else echo "FAIL ac7-qa-verdict-step-with-human-only-list: baseline step not found"; fail=1; fi
has ac7-security-reviewer-keeps-changed-paths-line "$SEC" '- Changed paths checked against the item'  # file no longer byte-equal to the baseline since #86
step5="$(base skills/run/SKILL.md | grep -F 'QA and security findings go to the developer' | sed 's/^[0-9]*\. //')"
if [ -n "$step5" ]; then has ac7-run-rework-rule-repeat-until-both-pass "$RUN" "$step5"; else echo "FAIL ac7-run-rework-rule: baseline line not found"; fail=1; fi
has ac7-run-rework-rule-text "$RUN" 'repeat until both verdicts are `pass`'
has ac7-run-done-when-both-verdicts-pass "$RUN" 'both verdicts are `pass`, every Human-only criterion passed its demo'
has ac7-run-qa-and-security-check-the-diff-paragraph "$RUN" '**QA and security check the diff against the list.**'  # extended by #86
kept ac7-run-done-when-line "$RUN" skills/run/SKILL.md '**Done when** every stage has run or was skipped'
kept ac7-run-open-pr-bump-check-line "$RUN" skills/run/SKILL.md '1. `git fetch origin main`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-bump.sh"`'
kept ac7-run-open-pr-no-instruction "$RUN" skills/run/SKILL.md 'No instruction anywhere opens a PR without this check.'
has ac7-run-architect-done-comparison "$RUN" 'After the **architect'"'"'s** `done`, make the path comparison before any other brief (*Parallel slices*).'
kept ac7-protocol-F3-row "$PROTO" references/protocol.md '| F3 |'
for n in 1 2 4 5 6 7; do kept "ac7-protocol-F$n-row" "$PROTO" references/protocol.md "| F$n |"; done
# the QA verdict step still asks for pass or block, and the Done list still holds the five gate lines
ck ac7-qa-done-list-keeps-its-gate-lines 4 "$(printf '%s\n' "$QD" | grep -cE '^- (Every defect has a reproduction|The verdict is recorded|Changed paths checked against|Every acceptance criterion maps to)')"

# =============================================================== AC-8 the fenced section is byte-identical; nothing else changes outside ## Tests
fence() { awk '/^## Never overridable locally$/ {f=1} /^## Overrides$/ {f=0} f' "$1" | shasum -a 256 | cut -d' ' -f1; }
bf="$(base references/protocol.md | sed 's|relative to the repo'"'"'s parent for another worktree (`../wt/<id>`)|relative to the main checkout for another worktree (`.claude/worktrees/<id>`)|' > "$T/proto-base.md"; fence "$T/proto-base.md")"  # the one change since the freeze: the worktree location (#109)
ck ac8-baseline-fenced-section-found 1 "$([ -n "$(awk '/^## Never overridable locally$/ {f=1} f' "$T/proto-base.md")" ] && echo 1 || echo 0)"
ck ac8-fenced-section-byte-identical "$bf" "$(fence "$PROTO")"
ck ac8-question-E-present 1 "$(grep -c '^> \*\*E\. Data egress\.\*\*' "$PROTO")"
# the protocol minus its ## Tests section is the baseline protocol, byte for byte
awk '/^## Tests$/ {skip=1; next} skip && /^## / {skip=0} !skip' "$PROTO" > "$T/proto-minus-tests.md"
# slice 112 adds one shell line for the integrator; it is the only other change allowed here
ck ac8-protocol-minus-tests-section-is-baseline "$(shasum -a 256 < "$T/proto-base.md" | cut -d' ' -f1)" "$(grep -v '^- \*\*integrator\*\*' "$T/proto-minus-tests.md" | shasum -a 256 | cut -d' ' -f1)"

# =============================================================== AC-9 the files agree on whose test to change (script part; the cards are human review)
for f in $FILES; do
  ck "ac9-tests-dir-never-given-to-developer-in-$(basename "$f")" 0 "$(grep -E '^\| .*`tests/`.*\| *developer *\|' "$f" | grep -c .)"
done

# =============================================================== the scenario cards exist and have their parts (the reading is human review)
SC="$REPO/tests/factory/scenarios"
for card in ac1-test-expected-value-looks-wrong ac2-seam-and-test-disagree ac3-lead-must-tell-the-person ac4-code-review-triggers ac5-developer-done-list ac6-deliverable-is-a-test-harness ac9-whose-test-do-i-change; do
  f="$SC/73-$card.md"
  ck "cards-$card-exists" 1 "$([ -f "$f" ] && echo 1 || echo 0)"
  if [ -f "$f" ]; then
    ck "cards-$card-has-text-situation-answer" 1 "$([ "$(grep -c '^Text given:' "$f")" -ge 1 ] && [ "$(grep -c '^Situation:' "$f")" -ge 1 ] && [ "$(grep -c '^Expected answer:' "$f")" -ge 1 ] && echo 1 || echo 0)"
    ck "cards-$card-parts-balance" "$(grep -c '^Situation:' "$f")" "$(grep -c '^Expected answer:' "$f")"
  fi
done
f="$SC/73-ac4-code-review-triggers.md"
[ -f "$f" ] && ck cards-ac4-has-three-cards 3 "$(grep -c '^Situation:' "$f")"
[ -f "$f" ] && ck cards-ac4-answers-are-no-yes-yes 'no|yes|yes' "$(grep '^Expected answer:' "$f" | sed -E 's/^Expected answer: *(no|yes).*/\1/' | paste -sd'|' -)"

# =============================================================== release 2.1.0
PJ="$PLUGIN/.claude-plugin/plugin.json"
ck rel-plugin-json-version "2.7.1" "$(jq -r .version "$PJ")"
ck rel-version-own-line 1 "$(grep -c '^  "version": "2.7.1",$' "$PJ")"
ck rel-marketplace-has-no-version "null" "$(jq -r '.plugins[] | select(.name=="factory") | .version' "$REPO/.claude-plugin/marketplace.json")"
ck rel-factory-state-stays-2 1 "$(head -1 "$TPL" | grep -cx 'factory-state: 2')"
skip rel-delta-against-main "retired by the 2.2.0 triage batch: these rows describe the 2.0.0 to 2.1.0 delta against origin/main, which no longer holds once main is 2.1.0"
# the changelog entry is the docs-writer's, after QA: checked once it exists (as slice 64 did)
if grep -q '^## factory 2.1.0 (#73)' "$REPO/CHANGELOG.md"; then
  CE="$(awk '/^## factory 2.1.0/{f=1;print;next} /^## /{f=0} f' "$REPO/CHANGELOG.md")"
  inre rel-changelog-says-unverified "$CE" 'unverified'
  inre rel-changelog-names-tests-stage "$CE" '`Tests`'
  inre rel-changelog-names-no-adr "$CE" 'no ADR'
  inre rel-changelog-names-the-script-trigger "$CE" 'misjudge'
  inre rel-changelog-names-pilot-comparison "$CE" '1\.3\.0'
  a="$(lineno_start "$REPO/CHANGELOG.md" '## factory 2.1.0')"; z="$(lineno_start "$REPO/CHANGELOG.md" '## factory 2.0.0')"
  ck rel-changelog-2.1.0-above-2.0.0 1 "$([ "$a" -gt 0 ] && [ "$z" -gt "$a" ] && echo 1 || echo 0)"
else
  skip rel-changelog-entry "CHANGELOG.md has no '## factory 2.1.0 (#73)' entry yet: the docs-writer stage runs after QA; the checks run once it exists"
fi
if grep -q '2\.1\.0' "$REPO/README.md"; then echo "ok   rel-readme-has-2.1.0-row"; passed=$((passed + 1))
else skip rel-readme-row "README.md has no 2.1.0 row yet: the docs-writer stage runs after QA"; fi
ck rel-no-home-path-in-slice-text 0 "$(grep -rlF -- "$(printf '%s/' "$HOME")" $FILES "$SC" 2>/dev/null | grep -c .)"
done_
