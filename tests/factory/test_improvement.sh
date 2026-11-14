#!/bin/bash
# Improvement loop: local or fundamental. Issue #116, spec #108.
# Two seams: the script (improvement.sh against a stub gh: sanitising scan, approval gate, trace, report) and the standard text.
. "$(dirname "$0")/lib.sh"
T="$(cd "$T" && pwd -P)"
IM="$PLUGIN/scripts/improvement.sh"
SK="$(run_all_file)"
PR="$PLUGIN/references/protocol.md"
HP="/Us""ers"
mkdir -p "$T/bin" "$T/g"
cp "$REPO/tests/factory/stub-gh/gh" "$T/bin/gh"
export STUB_GH_DIR="$T/g" PATH="$T/bin:$PATH"
mkrepo() { mkdir -p "$1" && git init -q -b main "$1" && ( cd "$1" && echo r > README && git add -A && git commit -qm init ) >/dev/null 2>&1; }
reset() { echo '[]' >"$T/g/issues.json"; : >"$T/g/log"; unset STUB_GH_FAIL; }
nissues() { jq 'length' "$T/g/issues.json"; }
R="$T/acme-shop"; mkrepo "$R"
run() { ( cd "$R" && bash "$IM" "$@" ); }

# --- scripts seam: the sanitising scan
printf '## Problem\nA brief that names no inputs makes a role stop.\n\n## Change\nName the inputs in every brief.\n' > "$T/ok.md"
sha="$(shasum -a 256 "$T/ok.md" 2>/dev/null | cut -d' ' -f1 || sha256sum "$T/ok.md" | cut -d' ' -f1)"
out="$(run check "$T/ok.md")"; rc=$?
ck check-clean-rc 0 "$rc"
ck check-clean-prints-sha "clean $sha" "$out"
chk() { printf '%s\n' "$2" > "$T/p.md"; run check "$T/p.md" >"$T/o" 2>&1; echo $?; }
ck check-home-path-refused 6 "$(chk x "see $HP/someone/work")"
ck check-project-name-refused 6 "$(chk x 'The acme-shop checkout broke')"
ck check-project-name-case-refused 6 "$(chk x 'The Acme-Shop checkout broke')"
ck check-url-refused 6 "$(chk x 'see https://example.com/page')"
ck check-issue-ref-refused 6 "$(chk x 'as in #42')"
ck check-code-fence-refused 6 "$(chk x '```
rm -rf x
```')"
printf 'The acme-shop checkout broke\n' > "$T/p.md"
run check "$T/p.md" >"$T/o" 2>&1
ck check-hit-names-line-not-text "no" "$(grep -q 'checkout' "$T/o" && echo yes || echo no)"
has check-hit-names-kind "$T/o" 'project-name'
ck check-missing-file-rc 2 "$(run check "$T/none.md" >/dev/null 2>&1; echo $?)"

# --- scripts seam: the approval gate
reset
ck submit-no-approval-rc 7 "$(run submit "$T/ok.md" >/dev/null 2>&1; echo $?)"
ck submit-wrong-approval-rc 7 "$(run submit "$T/ok.md" --approved deadbeef >/dev/null 2>&1; echo $?)"
ck submit-gate-nothing-filed 0 "$(nissues)"
ck submit-gate-no-gh-create "0" "$(grep -c '^issue create' "$T/g/log")"
printf 'The acme-shop checkout broke\n' > "$T/leak.md"
leaksha="$(shasum -a 256 "$T/leak.md" 2>/dev/null | cut -d' ' -f1 || sha256sum "$T/leak.md" | cut -d' ' -f1)"
ck submit-approved-but-dirty-rc 6 "$(run submit "$T/leak.md" --approved "$leaksha" >/dev/null 2>&1; echo $?)"
ck submit-approved-but-dirty-nothing-filed 0 "$(nissues)"
out="$(run submit "$T/ok.md" --approved "$sha")"; rc=$?
ck submit-approved-rc 0 "$rc"
ck submit-approved-url "submitted https://example.invalid/o/r/issues/1" "$out"
ck submit-one-issue 1 "$(nissues)"
ck submit-marketplace-repo "yes" "$(grep '^issue create' "$T/g/log" | grep -q -- '-R WimSuenens/agent-plugins' && echo yes || echo no)"
ck submit-label "yes" "$(grep '^issue create' "$T/g/log" | grep -q -- '--label plugin:factory' && echo yes || echo no)"
ck submit-marker "<!-- factory:improvement $sha -->" "$(jq -r '.[0].body' "$T/g/issues.json" | head -1)"
has submit-body-text "$T/g/issues.json" 'Name the inputs in every brief.'
ck submit-title-from-first-heading "A brief that names no inputs makes a role stop." "$(jq -r '.[0].title' "$T/g/issues.json")"
# an edit after the approval breaks it
printf 'Another sentence.\n' >> "$T/ok.md"
ck submit-edited-after-approval-rc 7 "$(run submit "$T/ok.md" --approved "$sha" >/dev/null 2>&1; echo $?)"
# the same approved text is never filed twice
sed -i.bak '$d' "$T/ok.md"; rm -f "$T/ok.md.bak"
out="$(run submit "$T/ok.md" --approved "$sha")"
ck submit-twice-existing "existing #1" "$out"
ck submit-twice-one-issue 1 "$(nissues)"
reset
ck submit-gh-failure-rc 4 "$(STUB_GH_FAIL=create bash -c "cd '$R' && bash '$IM' submit '$T/ok.md' --approved '$sha'" >/dev/null 2>&1; echo $?)"
ck submit-env-repo "yes" "$(reset; FACTORY_MARKETPLACE_REPO=o/other run submit "$T/ok.md" --approved "$sha" >/dev/null; grep '^issue create' "$T/g/log" | grep -q -- '-R o/other' && echo yes || echo no)"

# --- scripts seam: classification recorded in the project
reset
echo '[{"number":9,"title":"t","body":"","state":"open","comments":[]}]' > "$T/g/issues.json"
printf 'It names a path of this project, so it would not hold in another stack.\n' > "$T/why.md"
ck classify-local "classified #9 local" "$(run classify 9 local "$T/why.md")"
ck classify-marker "<!-- factory:finding v1 -->" "$(jq -r '.[0].comments[0].body' "$T/g/issues.json" | head -1)"
ck classify-line "**Classification:** local" "$(jq -r '.[0].comments[0].body' "$T/g/issues.json" | grep '^\*\*Classification')"
ck classify-reason "**Reason:** It names a path of this project, so it would not hold in another stack." "$(jq -r '.[0].comments[0].body' "$T/g/issues.json" | grep '^\*\*Reason')"
ck classify-fundamental "classified #9 fundamental" "$(run classify 9 fundamental "$T/why.md")"
ck classify-bad-class-rc 2 "$(run classify 9 maybe "$T/why.md" >/dev/null 2>&1; echo $?)"
: > "$T/empty.md"
ck classify-empty-reason-rc 2 "$(run classify 9 local "$T/empty.md" >/dev/null 2>&1; echo $?)"
printf 'see %s/someone/x\n' "$HP" > "$T/leak2.md"
ck classify-scan-refused-rc 6 "$(run classify 9 local "$T/leak2.md" >/dev/null 2>&1; echo $?)"

# --- scripts seam: local improvements persist and leave a trace
TR="$R/docs/agents/improvements.md"
ck trace-first "traced qa-names-runner" "$(run trace qa-names-runner qa-engineer test-rework-rounds 2 'Name the test runner in the QA brief' 'QA lost a round guessing the runner')"
has trace-header "$TR" '# Improvements'
has trace-line-name "$TR" '| qa-names-runner |'
has trace-line-role "$TR" '| qa-engineer |'
has trace-line-what "$TR" 'Name the test runner in the QA brief'
has trace-line-why "$TR" 'QA lost a round guessing the runner'
has trace-line-before "$TR" '| before 2 |'
ck trace-line-date "yes" "$(grep -q '^| 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] | qa-names-runner |' "$TR" && echo yes || echo no)"
run trace dev-names-paths developer none 'not captured' 'List paths in the brief' 'Paths were guessed' >/dev/null
ck trace-appends-two-rows 2 "$(grep -c '^| 20' "$TR")"
ck trace-header-once 1 "$(grep -c '^# Improvements' "$TR")"
ck trace-duplicate-name-rc 2 "$(run trace dev-names-paths developer none 'not captured' 'x' 'y' >/dev/null 2>&1; echo $?)"
ck trace-bad-name-rc 2 "$(run trace 'Bad Name' developer none 'not captured' 'x' 'y' >/dev/null 2>&1; echo $?)"
# a table row stays one line
run trace multi-line-row developer none 'not captured' $'line one\nline two | x' $'why\r\nmore' >/dev/null
ck trace-multiline-one-row 1 "$(grep -c 'multi-line-row' "$TR")"
ck trace-multiline-rows-total 3 "$(grep -c '^| 20' "$TR")"
has trace-multiline-collapsed "$TR" '| line one line two / x | why'
grep -v multi-line-row "$TR" >"$T/tr.tmp" && cp "$T/tr.tmp" "$TR"   # keep the later row counts as they were
ck trace-newline-in-name-rc 2 "$(run trace $'ok-name\nbad name' developer none 'not captured' 'x' 'y' >/dev/null 2>&1; echo $?)"
ck trace-newline-in-role-rc 2 "$(run trace nl-role $'developer\nx' none 'not captured' 'x' 'y' >/dev/null 2>&1; echo $?)"
ck trace-newline-in-measure-rc 2 "$(run trace nl-measure developer $'none\nx' 'not captured' 'x' 'y' >/dev/null 2>&1; echo $?)"
# project name: whole words, at least 4 characters, not generic, never a worktree's name
ck check-name-substring-clean 0 "$(chk x 'The acme-shopping cart is slow')"
S="$T/app"; mkrepo "$S"
ck check-short-name-clean 0 "$(cd "$S" && printf 'The app broke\n' >"$T/p.md" && bash "$IM" check "$T/p.md" >/dev/null 2>&1; echo $?)"
G="$T/project"; mkrepo "$G"
ck check-generic-name-clean 0 "$(cd "$G" && printf 'This project broke\n' >"$T/p.md" && bash "$IM" check "$T/p.md" >/dev/null 2>&1; echo $?)"
git -C "$R" worktree add -q "$T/wt-zebra-lane" -b wt-branch >/dev/null 2>&1
ck check-worktree-name-not-used 0 "$(cd "$T/wt-zebra-lane" && printf 'The wt-zebra-lane checkout\n' >"$T/p.md" && bash "$IM" check "$T/p.md" >/dev/null 2>&1; echo $?)"
ck check-worktree-uses-main-name 6 "$(cd "$T/wt-zebra-lane" && printf 'The acme-shop checkout\n' >"$T/p.md" && bash "$IM" check "$T/p.md" >/dev/null 2>&1; echo $?)"
ck trace-scan-refused-rc 6 "$(run trace leaky developer none 'not captured' "See $HP/someone/x" 'y' >/dev/null 2>&1; echo $?)"
ck trace-leaky-not-written 0 "$(grep -c '| leaky |' "$TR")"
ck trace-pipe-in-text-kept-one-row 2 "$(run trace pipe-ok developer none 'not captured' 'a | b' 'c' >/dev/null; grep -c '^| 20' "$TR" | awk '{print $1-1}')"
# permanence: a second run (a fresh process, a fresh checkout state) still finds them
( cd "$R" && git add -A && git commit -qm trace ) >/dev/null 2>&1
ck trace-survives-a-commit-and-new-process 3 "$(grep -c '^| 20' "$R/docs/agents/improvements.md")"

# --- scripts seam: the next cycle reports before and after
echo '{"test-rework-rounds": 1}' > "$T/now.json"
rep="$(run report "$T/now.json")"
ck report-measured "qa-names-runner: test-rework-rounds: before 2 / after 1" "$(printf '%s\n' "$rep" | sed -n 1p)"
ck report-no-measure "dev-names-paths: no measure: before not captured / after not captured" "$(printf '%s\n' "$rep" | sed -n 2p)"
echo '{}' > "$T/now.json"
ck report-after-not-captured "qa-names-runner: test-rework-rounds: before 2 / after not captured" "$(run report "$T/now.json" | sed -n 1p)"
echo '{"x": 0}' > "$T/now.json"
run trace zero developer x 'not captured' 'w' 'y' >/dev/null
ck report-before-not-captured-after-zero "zero: x: before not captured / after 0" "$(run report "$T/now.json" | grep '^zero')"
echo '{"x": null}' > "$T/now.json"
ck report-null-is-not-captured "zero: x: before not captured / after not captured" "$(run report "$T/now.json" | grep '^zero')"
ck report-no-file-rc 0 "$(cd "$T" && mkdir -p empty && cd empty && git init -q && bash "$IM" report "$T/now.json" >/dev/null 2>&1; echo $?)"
ck report-no-file-says "no improvements" "$(cd "$T/empty" && bash "$IM" report "$T/now.json")"
ck usage-rc 2 "$(run bogus >/dev/null 2>&1; echo $?)"

# --- standard-text seam
has run-section "$SK" '## Improvement loop'
has run-classify-test "$SK" 'would this hold in a project with a different stack, business and person?'
has run-no-is-local "$SK" '**project-local**'
has run-yes-is-fundamental "$SK" '**factory-fundamental**'
has run-classify-records "$SK" 'scripts/improvement.sh" classify'
has run-every-finding "$SK" 'Every finding (an andon, repeated rework, a research result) is classified'
has run-local-via-role-files "$SK" 'A project-local improvement is applied by you in the project through the role files'
has run-local-permanent "$SK" 'kept permanently: it does not expire at the end of a run'
has run-local-trace "$SK" 'scripts/improvement.sh" trace'
has run-local-fence "$SK" 'The fence binds it as it binds any role file'
has run-fundamental-sanitised "$SK" 'drafted as a sanitised proposal'
has run-fundamental-a3-format "$SK" 'The A3 is the proposal format'
has run-fundamental-check "$SK" 'scripts/improvement.sh" check'
has run-fundamental-approval "$SK" 'Nothing leaves the project without the person'"'"'s approval'
has run-fundamental-submit "$SK" 'scripts/improvement.sh" submit'
has run-decision-elsewhere "$SK" 'in a separate session in that repository, never in the project where the factory ran'
has run-report-next-cycle "$SK" 'scripts/improvement.sh" report'
has run-report-not-captured "$SK" 'with `not captured` where it was not measured'
has run-start-reports "$SK" 'At run start, report each applied improvement'
has run-existing-andon-unchanged "$SK" 'The andon, the A3 and the baseline work as before'
hasnt protocol-e-unchanged-fence "$PR" 'Improvement loop'
has glossary-override "$REPO/CONTEXT.md" '**Override**'
has glossary-local-countermeasure "$REPO/CONTEXT.md" '**Local countermeasure**'
has glossary-local-permanent "$REPO/CONTEXT.md" 'kept permanently'
has glossary-fundamental "$REPO/CONTEXT.md" '**Factory-fundamental**'
has glossary-improvement-trace "$REPO/CONTEXT.md" '**Improvement trace**'
has adr-0011-revised "$REPO/docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md" '## Revision (#116)'
has adr-0011-persist "$REPO/docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md" 'A project-local improvement is kept permanently'
has contract-exists "$REPO/contracts/116-improvement-loop.md" 'Issue [#116]'

done_
