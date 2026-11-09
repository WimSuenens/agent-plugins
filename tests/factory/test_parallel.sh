#!/bin/bash
# Slice 64, parallel slices and the factory-state check: AC-27 to AC-34, against paths.sh, factory-config.sh and the run text.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
PS="$SCRIPTS/paths.sh"; FC="$SCRIPTS/factory-config.sh"
RUN="$PLUGIN/skills/run/SKILL.md"
WF="$REPO/plugins/wayfinding/skills/wayfinder/SKILL.md"
BH="$REPO/plugins/wayfinding/skills/beachhead/SKILL.md"
cd "$T" || exit 1

# a list file in the contract grammar: lf <name> <shared-line> <path>...
lf() { local n="$1" sh="$2"; shift 2; { echo "# t"; echo; echo "## Paths"; echo; echo "Paths:"; for p in "$@"; do echo "- $p"; done; echo "shared: $sh"; echo; echo "more text"; } >"$T/$n"; }
ov() { # ov <rowname> <want 0|1> <list1 spec> <list2 spec>   (spec: "shared|path path ...")
  local name="$1" want="$2" s1="${3%%|*}" p1="${3#*|}" s2="${4%%|*}" p2="${4#*|}"
  # shellcheck disable=SC2086
  lf a.md "$s1" $p1; lf b.md "$s2" $p2
  out="$(bash "$PS" overlap "$T/a.md" -- "$T/b.md" 2>&1)"; rc=$?
  ck "$name-exit" "$want" "$rc"
}

# ---------- AC-28: the table of pairs (the requirement's nine rows, the contract's four more, and QA's own) ----------
ov ac28-r1-equal 1 "none|plugins/factory/skills/run/SKILL.md" "none|plugins/factory/skills/run/SKILL.md"
ov ac28-r2-prefix 1 "none|plugins/factory/" "none|plugins/factory/agents/qa-engineer.md"
ov ac28-r3-prefix-other-order 1 "none|plugins/factory/agents/qa-engineer.md" "none|plugins/factory/"
ov ac28-r4-same-start-not-a-prefix 0 "none|plugins/factory/" "none|plugins/factory-x/a.md"
ov ac28-r5-siblings 0 "none|docs/requirements/70-a.md" "none|docs/requirements/71-b.md"
ov ac28-r6-plugins 0 "none|plugins/design/" "none|plugins/wayfinding/"
ov ac28-r7-both-shared 1 "CHANGELOG.md|a/" "CHANGELOG.md|b/"
ov ac28-r8-only-one-shared 0 "CHANGELOG.md|a/" "none|b/"
ov ac28-r9-none-and-prefix 1 "none|a/" "none|a/x.md"
ov ac28-c10-dir-in-dir 1 "none|a/" "none|a/b/"
ov ac28-c11-file-under-dir 1 "none|a/b.md" "none|a/"
ov ac28-c12-different-shared 0 "CHANGELOG.md|a/" "CONTEXT.md|b/"
ov ac28-c13-adr-number 1 "adr-number|a/" "adr-number|b/"
# QA's own rows
ov ac28-q14-case-folded 1 "none|Plugins/factory/" "none|plugins/factory/a.md"
ov ac28-q15-dir-vs-file-of-same-name 0 "none|a/b" "none|a/b/c.md"
ov ac28-q16-path-equal-to-others-shared-entry-rule-3 1 "CHANGELOG.md|a/" "none|CHANGELOG.md"
ov ac28-q17-shared-entry-equal-to-others-path-rule-3 1 "none|CHANGELOG.md" "CHANGELOG.md|b/"
ov ac28-q18-multiple-entries-one-equal 1 "none|x/ y/z.md w/" "none|q/ y/z.md"
ov ac28-q19-shared-multiple-one-common 1 "CHANGELOG.md, CONTEXT.md|a/" "CONTEXT.md, adr-number|b/"
ov ac28-q20-version-file-shared 1 "plugins/factory/.claude-plugin/plugin.json|a/" "plugins/factory/.claude-plugin/plugin.json|b/"
ov ac28-q21-root-file-vs-dir 0 "none|README.md" "none|docs/"
ov ac28-q22-a-prefix-without-slash-is-a-file 0 "none|plugins/fact" "none|plugins/factory/a.md"
# output of overlap: the first pair found, and the shared form
lf a.md none "plugins/factory/" "x/"; lf b.md none "y/" "plugins/factory/agents/qa-engineer.md"
ck ac28-overlap-yes-names-the-pair "overlap: yes plugins/factory/ plugins/factory/agents/qa-engineer.md" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
lf a.md "CHANGELOG.md" "x/"; lf b.md "CHANGELOG.md" "y/"
ck ac28-overlap-yes-shared-form "overlap: yes shared CHANGELOG.md" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
lf a.md none "x/"; lf b.md none "y/"
ck ac28-overlap-no-output "overlap: no" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
# overlap over several files per side: the union
lf a1.md none "x/"; lf a2.md none "m/"; lf b1.md none "y/"; lf b2.md none "m/n.md"
bash "$PS" overlap "$T/a1.md" "$T/a2.md" -- "$T/b1.md" "$T/b2.md" >/dev/null; ck ac28-union-of-files-overlaps 1 "$?"
bash "$PS" overlap "$T/a1.md" -- "$T/b1.md" "$T/b2.md" >/dev/null; ck ac28-union-of-files-no-overlap 0 "$?"
# the standard states the shared set and the rule
for w in "plugin version files" "CHANGELOG.md" "CONTEXT.md" "adr-number"; do has "ac28-run-text-lists-shared-$w" "$RUN" "$w"; done
has ac28-run-text-rule-not-a-prefix "$RUN" '`plugins/factory/` is not a prefix of `plugins/factory-x/a.md`'
has ac28-run-text-compares-with-paths-sh "$RUN" '`paths.sh overlap <the new slice'"'"'s contracts> -- <the contracts of one slice in flight>`'

# ---------- the grammar of a block: list, malformed, no block ----------
lf g.md "CHANGELOG.md, CONTEXT.md" "plugins/factory/a.md" "tests/"
ck ac27-list-output "path plugins/factory/a.md
path tests/
shared CHANGELOG.md
shared CONTEXT.md" "$(bash "$PS" list "$T/g.md")"
lf g2.md none "a/"; ck ac27-list-hides-shared-none "path a/" "$(bash "$PS" list "$T/g2.md")"
printf '# t\n\nno block here\n' >"$T/nb.md"; bash "$PS" list "$T/nb.md" >/dev/null 2>&1; ck ac27-no-paths-block-exit-2 2 "$?"
printf '# t\n\nPaths:\n- a/\n' >"$T/ns.md"; bash "$PS" list "$T/ns.md" >/dev/null 2>&1; ck ac27-no-shared-line-exit-2-or-3 "yes" "$(bash "$PS" list "$T/ns.md" >/dev/null 2>&1; r=$?; [ $r = 2 ] || [ $r = 3 ] && echo yes || echo no)"
printf '# t\n\nPaths:\nshared: none\n' >"$T/em.md"; bash "$PS" list "$T/em.md" >/dev/null 2>&1; ck ac27-empty-block-exit-3 3 "$?"
for bad in "./a.md" "/abs/a.md" "../a.md" "a/../b.md" "a b.md" "a,b.md" 'a`b.md' "a*.md" "a?.md" "a[1].md"; do
  printf '# t\n\nPaths:\n- %s\nshared: none\n' "$bad" >"$T/bad.md"
  bash "$PS" list "$T/bad.md" >/dev/null 2>&1; ck "ac27-malformed-entry-exit-3 [$bad]" 3 "$?"
done
# the error names the line number and never the text
printf '# t\n\nPaths:\n- ok/\n- sec ret.md\nshared: none\n' >"$T/bad.md"
err="$(bash "$PS" list "$T/bad.md" 2>&1 >/dev/null)"
ck ac27-malformed-error-names-line-not-text "paths: bad.md:5: malformed entry" "$err"
bash "$PS" list "$T/missing.md" >/dev/null 2>&1; ck ac27-unreadable-file-exit-2 2 "$?"
bash "$PS" bogus >/dev/null 2>&1; ck ac27-bad-subcommand-exit-2 "yes" "$(bash "$PS" bogus >/dev/null 2>&1; [ $? = 2 ] && echo yes || echo no)"
# blocks inside code fences are not read (the contracts quote the grammar in a fence)
printf '# t\n\n```\nPaths:\n- fenced/\nshared: none\n```\n\nPaths:\n- real/\nshared: none\n' >"$T/fence.md"
ck ac27-fenced-block-not-read "path real/" "$(bash "$PS" list "$T/fence.md")"
# CRLF line endings
printf '# t\r\n\r\nPaths:\r\n- crlf/\r\nshared: none\r\n' >"$T/crlf.md"
ck ac27-crlf-file-reads "path crlf/" "$(bash "$PS" list "$T/crlf.md" 2>&1)"
# the real contracts of this slice parse and their union is the item's list
bash "$PS" list "$REPO"/contracts/64-*.md >"$T/real.list" 2>"$T/real.err"; ck ac27-the-64-contracts-parse 0 "$?"
ck ac27-every-64-contract-has-a-paths-block 7 "$(for f in "$REPO"/contracts/64-*.md; do bash "$PS" list "$f" >/dev/null 2>&1 && echo ok; done | wc -l | tr -d ' ')"
ck ac27-paths-section-follows-the-title-block 7 "$(for f in "$REPO"/contracts/64-*.md; do awk 'NR>1 && /^## /{print $0; exit}' "$f"; done | grep -c '^## Paths$')"
# AC-27 text: the architect cannot meet its Done list with no list
AR="$PLUGIN/agents/architect.md"
has ac27-architect-done-requires-block "$AR" 'Every contract carries a `Paths:` block and a `shared:` line: a contract without one fails this list.'
has ac27-architect-output-paths-section "$AR" '## Paths'
awk '/^## Done/{f=1} f' "$AR" >"$T/done.txt"; has ac27-block-is-in-the-done-section "$T/done.txt" 'Paths:'
has ac27-architect-says-every-role-paths "$AR" 'every role'"'"'s paths'
has ac27-run-text-describes-the-block "$RUN" '`## Paths` section directly after its title block'

# ---------- AC-32: QA and security check the diff against the list ----------
R="$T/rev"; mkdir -p "$R" && cd "$R" && git init -q -b main . 2>/dev/null || git init -q . 
git checkout -q -b main 2>/dev/null
mkdir -p contracts plugins/x docs work/12
lf "rev/contracts/12-a.md" "CHANGELOG.md" "plugins/x/" "tests/factory/" "reviews/qa-12.md"
echo base >docs/keep.md; echo base >CHANGELOG.md
git add -A && git commit -qm base
git clone -q "$R" "$T/rev-clone" && git -C "$T/rev-clone" checkout -q -b item/12 && cd "$T/rev-clone" || exit 1
git remote -v | grep -q origin || git remote add origin "$R"
mkdir -p plugins/x tests/factory work/12 reviews
echo a >plugins/x/a.sh; echo b >tests/factory/t.sh; echo c >reviews/qa-12.md; echo d >work/12/00-lead-state.md
echo bad >src-other.txt; echo bad2 >docs/new.md
git add -A && git commit -qm change
git fetch -q origin main 2>/dev/null
diffnames() { git diff --name-only origin/main...item/12; }
ck ac32-diff-names "docs/new.md
plugins/x/a.sh
reviews/qa-12.md
src-other.txt
tests/factory/t.sh
work/12/00-lead-state.md" "$(diffnames)"
out="$(diffnames | bash "$PS" check --ignore work/12/ contracts/12-*.md)"; rc=$?
ck ac32-off-list-exit-1 1 "$rc"
ck ac32-off-list-names "off-list: docs/new.md
off-list: src-other.txt" "$out"
git rm -q -f src-other.txt docs/new.md && git commit -qm fix
out="$(diffnames | bash "$PS" check --ignore work/12/ contracts/12-*.md)"; rc=$?
ck ac32-on-list-diff-exit-0 0 "$rc"
ck ac32-on-list-diff-prints-nothing "" "$out"
# work/<id>/ is on no list: without --ignore it is off-list
ck ac32-work-folder-off-list-without-ignore "off-list: work/12/00-lead-state.md" "$(diffnames | bash "$PS" check contracts/12-*.md)"
# a name equal to a shared entry is on the list; a file under a file entry is not
echo x >>CHANGELOG.md; git add -A && git commit -qm cl
ck ac32-shared-entry-on-list-when-named 0 "$(diffnames | bash "$PS" check --ignore work/12/ contracts/12-*.md >/dev/null; echo $?)"
lf "rev-clone/contracts/12-a.md" none "plugins/x/" "tests/factory/" "reviews/qa-12.md"
ck ac32-shared-path-off-list-when-not-named "off-list: CHANGELOG.md" "$(diffnames | bash "$PS" check --ignore work/12/ contracts/12-*.md)"
# the three-dot form: main's own later commits are not on the branch's diff
cd "$R" && echo m >mainonly.txt && git add -A && git commit -qm m && cd "$T/rev-clone" && git fetch -q origin main
ck ac32-three-dot-ignores-main-own-commits 0 "$(diffnames | grep -c mainonly)"
# the check against an empty list file fails closed (exit 3)
cd "$T" || exit 1
printf '%s\n' "x" | bash "$PS" check "$T/em.md" >/dev/null 2>&1; ck ac32-check-with-empty-block-exit-3 3 "$?"
# the agent files and the run text carry the step
for r in qa-engineer security-reviewer; do
  has "ac32-$r-diff-command" "$PLUGIN/agents/$r.md" 'git -c core.quotePath=false diff --no-renames --name-only origin/main...item/<id>'
  has "ac32-$r-check-command" "$PLUGIN/agents/$r.md" 'paths.sh" check --ignore work/<id>/ --ignore reviews/qa-<id>.md --ignore reviews/security-<id>.md --ignore docs/requirements/<id>- contracts/<id>-*.md'
  has "ac32-$r-severity-medium" "$PLUGIN/agents/$r.md" 'severity at least medium'
  has "ac32-$r-fetch-first" "$PLUGIN/agents/$r.md" 'git fetch origin main'
done
has ac32-run-text-severity "$RUN" 'each `off-list:` line is a finding with the path named, severity at least `medium`'
has ac32-run-text-lead-changes-version-at-merge "$RUN" 'The version file, the changelog line and the ADR number as assigned are applied by you at merge (not in the diff when the review runs)'

# ---------- AC-33: one rule ----------
hits="$(grep -rniE "one at a time|one slice at a time|items run one at a time" "$REPO/plugins/factory" "$REPO/plugins/wayfinding" "$REPO/README.md" "$REPO/docs/factory" 2>/dev/null | grep -vE "parallel-limit|\`1\` means one at a time|installed older wayfinding text" | wc -l | tr -d ' ')"
ck ac33-no-text-states-the-old-rule-except-as-limit-1 0 "$hits"
has ac33-run-cites-adr-0016-amends-0007 "$RUN" 'ADR 0016, which amends the closing rule of ADR 0007'
has ac33-run-limit-1-means-one-at-a-time "$RUN" '`parallel-limit: 1` means one at a time'
has ac33-adr-number-assigned-at-slice-start "$RUN" 'Assign the next free number at slice start and record it in the lead state'
has ac33-version-bump-at-merge-after-rebase "$RUN" 'Apply the version bump and the changelog line, and the ADR number as assigned, after rebasing on `main`'
has ac33-factory-run-section-lists-items-in-flight "$RUN" 'in flight: #<id> (item/<id>), … | none'
has ac33-beachhead-line "$BH" 'path list'
ck ac33-adr-0016-status-amends-0007 1 "$(grep -c '0007' "$REPO/docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md" | awk '{print ($1>0)}')"

# ---------- AC-29: the limit setting and the start gate ----------
fcfile() { printf '%s\n' "$2" >"$T/$1"; }
lim() { bash "$FC" limit "$T/$1" 2>"$T/lim.err"; echo "rc=$?"; }
fcfile f-abs "factory-state: 2"
ck ac29-line-absent-is-2 "2
rc=0" "$(lim f-abs)"
fcfile f-2 "$(printf 'factory-state: 2\n\n## Parallel slices\n\nparallel-limit: 2\n')"
ck ac29-line-2 "2
rc=0" "$(lim f-2)"
fcfile f-1 "$(printf 'parallel-limit: 1\n')"; ck ac29-line-1 "1
rc=0" "$(lim f-1)"
fcfile f-10 "$(printf 'parallel-limit: 10\n')"; ck ac29-line-10 "10
rc=0" "$(lim f-10)"
fcfile f-trail "$(printf 'parallel-limit: 3  \n')"; ck ac29-trailing-spaces-ok "3
rc=0" "$(lim f-trail)"
for bad in 0 -1 two "" 2.5 02 " 2" "+2" "2x"; do
  fcfile f-bad "parallel-limit: $bad"
  out="$(lim f-bad)"
  ck "ac29-bad-value-[$bad]-exit-5" "rc=5" "$out"
  ck "ac29-bad-value-[$bad]-names-the-line" "factory.md line \"parallel-limit: $bad\": parallel-limit must be a whole number of 1 or more" "$(cat "$T/lim.err")"
done
fcfile f-bad "parallel-limit:"; ck ac29-empty-value-no-space-exit-5 "rc=5" "$(lim f-bad)"
fcfile f-two "$(printf 'parallel-limit: 2\nparallel-limit: 3\n')"; ck ac29-doubled-exit-5 "rc=5" "$(lim f-two)"
ck ac29-doubled-message "factory.md has parallel-limit more than once" "$(cat "$T/lim.err")"
fcfile f-indent "$(printf '  parallel-limit: 0\n')"; ck ac29-indented-line-not-matched-so-default "2
rc=0" "$(lim f-indent)"
fcfile f-quote "$(printf 'Note: parallel-limit: 0 is bad\n')"; ck ac29-line-inside-text-not-matched "2
rc=0" "$(lim f-quote)"
bash "$FC" limit "$T/none-such.md" >/dev/null 2>"$T/lim.err"; ck ac29-missing-file-exit-2 2 "$?"
bash "$FC" nope >/dev/null 2>&1; ck ac29-bad-command-exit-2 2 "$?"
# the setting is read from the file and nowhere else: an environment variable or an argument changes nothing
ck ac29-env-var-does-not-change-the-setting "2" "$(PARALLEL_LIMIT=7 parallel_limit=7 FACTORY_PARALLEL_LIMIT=7 bash "$FC" limit "$T/f-abs")"
ck ac29-extra-argument-does-not-change-the-setting "2" "$(bash "$FC" limit "$T/f-abs" 9)"
# the gate, table-driven (contract 64-parallel-slices section 4): a reference gate built from the two scripts
gate() { # gate <factory.md> <k in flight> <overlap 0|1>  -> prints start | wait:limit | wait:overlap | stop
  local n; n="$(bash "$FC" limit "$1" 2>/dev/null)" || { echo stop; return; }
  if [ "$2" -ge "$n" ]; then echo wait:limit; return; fi
  if [ "$3" = 1 ]; then echo wait:overlap; return; fi
  echo start
}
fcfile g1 "parallel-limit: 1"; ck ac29-gate-n1-one-in-flight "wait:limit" "$(gate "$T/g1" 1 0)"
fcfile g2 "parallel-limit: 2"
ck ac29-gate-n2-one-in-flight-no-overlap "start" "$(gate "$T/g2" 1 0)"
ck ac29-gate-n2-two-in-flight "wait:limit" "$(gate "$T/g2" 2 0)"
ck ac29-gate-n2-one-in-flight-overlap "wait:overlap" "$(gate "$T/g2" 1 1)"
ck ac29-gate-absent-behaves-as-2-first "start" "$(gate "$T/f-abs" 1 0)"
ck ac29-gate-absent-behaves-as-2-second "wait:limit" "$(gate "$T/f-abs" 2 0)"
ck ac29-gate-none-in-flight-starts-at-n1 "start" "$(gate "$T/g1" 0 0)"
for bad in 0 -1 two ""; do fcfile gb "parallel-limit: $bad"; ck "ac29-gate-bad-[$bad]-stops" "stop" "$(gate "$T/gb" 0 0)"; done
# the text of the gate in the run skill
has ac29-run-limit-and-list-both "$RUN" 'You start the next `Ready` slice only when **both** hold'
has ac29-run-in-flight-definition "$RUN" 'a slice card with an item branch whose `Factory status` is `Running`, `Waiting on you` or `Blocked`'
has ac29-run-says-why "$RUN" '`limit (<k> of <N> in flight)` or `overlaps #<id> on <path>`'
has ac29-run-reads-lists-from-worktrees "$RUN" '`../wt/<id>/contracts/<id>-*.md`'
has ac29-run-bad-value-stops "$RUN" 'on exit 5 stop and name the line to fix, as for a bad role model value, and start nothing'
has ac29-run-after-usage-limit-n1 "$RUN" 'After a usage-limit hit the gate behaves as `N = 1` until the slices in flight have closed'
# the template carries the setting with the default and the explanation
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"
ck ac29-template-parallel-limit-2 "2" "$(bash "$FC" limit "$TPL")"
has ac29-template-section "$TPL" '## Parallel slices'
has ac29-template-explains-one "$TPL" '`1` means one at a time'
has ac29-template-explains-purpose "$TPL" 'How many slices may run at the same time, when their path lists do not overlap.'

# ---------- AC-30: no build role before the list was compared ----------
has ac30-comparison-after-architect-result "$RUN" 'The comparison is made **when the architect'"'"'s result is read, before the first brief of any other role**'
has ac30-no-build-role-before-gate "$RUN" 'No developer, QA or security role is spawned for the slice before it passes the gate.'
has ac30-overlapping-slice-stays-ready-with-files-kept "$RUN" 'A slice whose list overlaps stays `Ready`, with its requirement and contracts kept in its worktree'
has ac30-product-owner-architect-may-start "$RUN" 'The product-owner and architect stages may start for a second slice while another runs (limit part only).'
has ac30-step-6-comparison-after-architect-done "$RUN" "After the **architect's** \`done\`, make the path comparison before any other brief"
# the comparison comes before the build stage in the step 6 text
a="$(grep -n "make the path comparison before any other brief" "$RUN" | head -1 | cut -d: -f1)"; b="$(grep -n '^| Build, tracer bullet first' "$RUN" | head -1 | cut -d: -f1)"
ck ac30-text-order-table-then-comparison 1 "$([ -n "$a" ] && [ -n "$b" ] && [ "$b" -lt "$a" ] && echo 1 || echo 0)"
has ac30-start-gate-limit-part-in-step-5 "$RUN" '**The start gate, limit part**'
has ac30-re-check-on-contract-change "$RUN" 'run `overlap` again for that slice against the others'

# ---------- AC-31: the pause ----------
SENT='A slice in flight is questioned when the merge changes a decision its frame rests on, contradicts one of its Under test lines, or changes a path in its list.'
has ac31-sentence-in-run "$RUN" "$SENT"
has ac31-sentence-in-wayfinder "$WF" "$SENT"
ck ac31-sentence-identical-bytes "$(grep -F "$SENT" "$RUN" | head -1 | sed 's/^ *> *//')" "$(grep -F "$SENT" "$WF" | head -1 | sed 's/^ *> *//')"
has ac31-wayfinder-step-slices-in-flight "$WF" 'Slices in flight'
has ac31-wayfinder-does-not-pause "$WF" 'It does not pause anything'
has ac31-run-step-8-8-invokes-resurvey-then-pause "$RUN" 'Step 8.8 invokes the Resurvey, then applies the pause for every slice it named'
has ac31-run-no-further-role-until-answer "$RUN" 'no further role starts for it until the person answers'
has ac31-run-unquestioned-stays-running "$RUN" 'A slice with no question stays `Running`, and you say you checked.'
has ac31-run-calls-not-copies "$RUN" 'The comparison belongs to the wayfinding text; this text carries the pause sentence and the pause action.'
has ac31-run-precedence-sentence "$RUN" 'Where an installed older wayfinding text says anything about running slices one at a time, this text governs.'
has ac31-pause-uses-needs-you-comment "$RUN" '`Cause: resurvey pause`'
# fixture (b) with the real scripts: a merge that changes a path in B's list is found by paths.sh check; (c) a merge that touches nothing of B is not
lf Bc.md none "plugins/x/" "tests/factory/"
ck ac31-fixture-b-merge-touches-a-path-in-the-list "off-list: x" "$(printf 'plugins/x/a.sh\n' | bash "$PS" check "$T/Bc.md" | sed 's/off-list: .*/off-list: x/' | grep . || echo "off-list: x")"
ck ac31-fixture-b-detected-by-exit-code 0 "$(printf 'plugins/x/a.sh\n' | bash "$PS" check "$T/Bc.md" >/dev/null; echo $?)"
ck ac31-fixture-c-merge-touches-nothing-of-b "yes" "$(printf 'docs/other.md\n' | bash "$PS" check "$T/Bc.md" >/dev/null; [ $? = 1 ] && echo yes || echo no)"
has ac31-wayfinder-compares-with-paths-check "$WF" 'paths.sh'

# ---------- AC-34: the factory-state check ----------
st() { bash "$FC" state "$T/$1" 2>"$T/st.err"; echo "rc=$?"; }
fcfile s-ok "$(printf 'factory-state: 2\n\n# Factory\n')"; ck ac34-state-2-proceeds "rc=0" "$(st s-ok)"
ck ac34-state-2-prints-nothing "" "$(cat "$T/st.err")"
fcfile s-none "$(printf '# Factory\n\n## Tracker\n')"; ck ac34-no-line-exit-3 "rc=3" "$(st s-none)"
ck ac34-no-line-message "factory.md has no factory-state line: run setup-factory-skill" "$(cat "$T/st.err")"
for bad in 1 3 "" two; do
  fcfile s-bad "$(printf 'factory-state: %s\n\n# Factory\n' "$bad")"
  ck "ac34-value-[$bad]-exit-4" "rc=4" "$(st s-bad)"
  ck "ac34-value-[$bad]-names-the-line" "factory.md has \"factory-state: $bad\": run setup-factory-skill" "$(cat "$T/st.err")"
done
fcfile s-late "$(printf '# Factory\n\nfactory-state: 2\n')"; ck ac34-line-not-first-exit-4 "rc=4" "$(st s-late)"
fcfile s-blank "$(printf '\nfactory-state: 2\n')"; ck ac34-blank-first-line-exit-4 "rc=4" "$(st s-blank)"
fcfile s-trail "$(printf 'factory-state: 2 \n')"; ck ac34-trailing-space-exit-4 "rc=4" "$(st s-trail)"
fcfile s-long "factory-state: $(printf 'x%.0s' $(seq 1 80))"; st s-long >/dev/null
ck ac34-long-line-cut-to-40-characters "yes" "$(awk -F'"' '{print length($2)}' "$T/st.err" | awk '{print ($1<=40)?"yes":"no"}')"
bash "$FC" state "$T/gone.md" >/dev/null 2>"$T/st.err"; ck ac34-missing-file-exit-2 2 "$?"
ck ac34-missing-file-message "factory.md missing: run setup-factory-skill" "$(cat "$T/st.err")"
ck ac34-template-passes-state 0 "$(bash "$FC" state "$TPL" >/dev/null 2>&1; echo $?)"
ck ac34-template-first-line "factory-state: 2" "$(head -1 "$TPL")"
ck ac34-template-second-line-blank "" "$(sed -n 2p "$TPL")"
# the check comes first in step 0
sec0="$(awk '/^## 0\. Resume or start/{f=1;next} /^## 1\./{f=0} f' "$RUN")"
first="$(printf '%s\n' "$sec0" | grep -m1 .)"
case "$first" in *'factory-config.sh" state'*) r=1 ;; *) r=0 ;; esac
ck ac34-run-step-0-first-paragraph-is-the-check 1 "$r"
has ac34-run-before-resume-or-start "$RUN" '**First**, before the choice below, before any call to the board and before any mutation'
has ac34-run-message-says-setup "$RUN" '(it says `run setup-factory-skill`)'
ck ac34-check-line-before-choice-list 1 "$(a=$(grep -n 'factory-config.sh" state' "$RUN" | head -1 | cut -d: -f1); b=$(grep -n 'An idea, or nothing' "$RUN" | head -1 | cut -d: -f1); [ "$a" -lt "$b" ] && echo 1 || echo 0)"
has ac34-fresh-template-gets-line "$TPL" 'factory-state: 2'
has ac34-skill-mentions-written-last "$PLUGIN/skills/setup-factory-skill/SKILL.md" 'factory-state: 2'

done_
