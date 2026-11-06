#!/bin/bash
# #57 per-run A3 and baseline: what the standard's text says (AC-1, 7, 9, 12, 13, 16 to 20, 22 to 27) and the grammars and shell
# fragments it fixes. The rules that measure (AC-2 to AC-6, 11, 14, 15) are replayed in test_baseline_replay.sh.
# Where the Lead's act is a judgment, the tests pin the text and the mechanical part; QA's reading is in reviews/qa-57.md.
. "$(dirname "$0")/lib.sh"
SK="$PLUGIN/skills/run/SKILL.md"; BA="$PLUGIN/references/baseline.md"; A3="$PLUGIN/references/a3.md"; HA="$PLUGIN/references/hansei.md"
PR="$PLUGIN/references/protocol.md"; TP="$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md"
sect() { awk -v h="$2" '/^```/ {fence = !fence} !fence && /^## / {if (f) exit} $0==h && !fence {f=1} f {print}' "$1"; }
ln_of() { n="$(grep -nF -- "$2" "$1" | head -1 | cut -d: -f1)"; echo "${n:-0}"; }
before() { la="$(ln_of "$2" "$3")"; lb="$(ln_of "$2" "$4")"
  if [ "$la" -gt 0 ] && [ "$lb" -gt 0 ] && [ "$la" -lt "$lb" ]; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$3' ($la) not before '$4' ($lb)"; fail=1; fi; }
block_after() { awk -v h="$2" 'f==0 && $0==h {f=1; next} f==1 && /^```/ {f=2; next} f==2 && /^```/ {exit} f==2 {print}' "$1"; }
S9="$T/step9.md"; sect "$SK" '## 9. Close the run' > "$S9"
ck sections-extracted 1 "$([ -s "$S9" ] && echo 1 || echo 0)"

# ---------- the new reference files exist and the run skill reads them ----------
for f in baseline a3; do ck "refs-$f-exists" 1 "$([ -s "$PLUGIN/references/$f.md" ] && echo 1 || echo 0)"; has "refs-skill-links-$f" "$SK" '${CLAUDE_PLUGIN_ROOT}/references/'"$f"'.md'; done

# ---------- AC-1: find or create the one baseline; the commands; the fallback ----------
for b in 'Find baseline' 'Create baseline' 'Pin baseline' 'Read baseline' 'Edit baseline' 'Find records' 'Find A3s' 'Find A3' 'Post A3' 'Edit A3'; do
  has "ac1-template-bullet-$b" "$TP" "- **$b**:"
  has "ac1-fallback-names-$b" "$SK" "*$b*"
done
ck ac1-new-bullets-name-no-repo 0 "$(grep -E '^- \*\*(Find baseline|Create baseline|Pin baseline|Read baseline|Edit baseline|Find records|Find A3s|Find A3|Post A3|Edit A3)\*\*' "$TP" | grep -c -- '--repo')"
has ac1-fallback-sentence "$SK" 'When the section has *Post hansei* but lacks a bullet this standard names for the baseline or the A3'
has ac1-step0 "$SK" 'They also include the baseline check of `references/baseline.md`: *Find baseline* and act on its result (section 2), then the repair check (section 8.2).'
has ac1-step5 "$SK" 'and the baseline check of step 0 again (*Find baseline*, then the repair check, `references/baseline.md` sections 2 and 8.2)'
has ac1-one-open "$BA" '| one open | uses it; creates nothing; says nothing |'
has ac1-none-creates-pins-says "$BA" 'creates it (*Create baseline*, with the empty skeleton of section 7), fills it with the update of section 8, pins it (*Pin baseline*), and tells the person: `Factory baseline: none found; created #<n> and pinned it.`'
has ac1-many-asks "$BA" 'creates nothing and uses none; asks the person which one counts'
has ac1-pin-fail-never-second "$BA" 'The find rule never reads the pin, so **a failed pin can never lead to a second issue**.'
has ac1-create-only-after-find "$TP" 'Run only after *Find baseline* printed nothing.'
has ac1-edit-only-when-differs "$TP" 'and only when they differ `gh issue edit <n> --body-file "$rec"`'
# Find baseline, run: the jq select cut out of the template, on a fixture list
fb="$(grep -F -- '- **Find baseline**' "$TP")"; fbf="${fb#*--jq \'}"; fbf="${fbf%%\'\`*}"; fbf="${fbf//\'\"\$me\"\'/lead-qa}"
printf '%s' '[{"number":4,"state":"OPEN","title":"Factory baseline","author":{"login":"lead-qa"}},{"number":5,"state":"CLOSED","title":"Factory baseline","author":{"login":"lead-qa"}},{"number":6,"state":"OPEN","title":"Factory baseline v2","author":{"login":"lead-qa"}},{"number":7,"state":"OPEN","title":"Factory baseline","author":{"login":"someone-else"}},{"number":8,"state":"OPEN","title":"factory baseline","author":{"login":"lead-qa"}}]' > "$T/issues.json"
ck ac1-find-baseline-exact-title-own-author-any-state "4	OPEN|5	CLOSED" "$(jq -r "$fbf" "$T/issues.json" | paste -sd'|' -)"
ck ac1-find-baseline-none "" "$(printf '[]' | jq -r "$fbf")"

# ---------- AC-7: the update, its place in the close order, the repair at run start ----------
before ac7-update-after-edit-hansei "$SK" '9. Fill measure 7 (*Edit hansei*)' '10. Update the baseline'
before ac7-update-before-advance "$SK" '10. Update the baseline' '11. Advance without waiting'
has ac7-recompute-from-records "$SK" 'recompute the baseline issue from the records and append the `baseline:` note to the map'"'"'s Factory run section'
has ac7-twice-same-text "$BA" 'Running the update twice gives the same text.'
has ac7-write-only-if-differs "$BA" '*Edit baseline*: write only if the composed body differs from the one on the issue.'
has ac7-note-records-and-minutes "$BA" '`#<id> <n> records, <m>m`'
has ac7-stage-log-gone "$BA" 'The stage log is gone by then (step 8.6)'
has ac7-repair-check "$BA" 'means the previous run stopped before its update. Run the update of section 8.1 and say `Factory baseline: recomputed (<n> record(s) it did not list).`'
has ac7-hansei-close-list "$HA" '10. Update the baseline (`references/baseline.md`), then the experiment decision.'
has ac7-hansei-names-run-lines "$HA" "closed in this run"
has ac7-step4-appends-run-list "$SK" 'append the item to its `closed in this run` line as `#<id> <comment URL>`'
ck ac7-no-hand-edit-of-a-figure 1 "$(grep -c 'Do not edit a figure: the next update rewrites this whole body.' "$BA")"

# ---------- honesty rule, in the rules ----------
has honesty-r1 "$BA" 'A not-captured field is **never `0`, blank or left out**.'
has honesty-r5 "$BA" '**R5. No mean, no sum.**'
has honesty-a3-reading "$A3" 'A reading never has a blank, and never `0` for a value not measured.'
has honesty-a3-change "$A3" 'and `0` never stands for a value not captured.'
has honesty-f7-fenced "$PR" 'let a value read as anything other than a measured value, `0`, `n/a (did not run)` or `not captured (<reason>)`?'
has honesty-hansei-rule "$HA" '**Honesty rule**: an uncaptured value is never `0`, never blank, never dropped.'
has ac2-manual-comments-not-records "$BA" 'Manual calibration comments are this case.'
has ac5-forgotten-bump-is-kind6 "$BA" 'the forgotten bump belongs to the andon of kind 6'
has ac4-calibration-no-series "$BA" '`series: calibration (pre-baseline)` → **no series**'
has ac3-median-not-mean "$BA" 'the **median** of the `k` values'
ck ac3-no-instruction-for-a-mean 0 "$(grep -iE '\bmean of (all|the items|the section)|average' "$BA" "$A3" | grep -c .)"

# ---------- AC-9: baseline data and A3 stay in the project ----------
repo_all="$(grep -rnF -- '--repo' "$PLUGIN" | grep -v 'None names `--repo`' | grep -v 'No command here names `--repo`' | grep -v 'only instruction that names `--repo' | grep -vF -- '--repo <owner>/<repo>')"
ck ac9-only-step9-4-names-repo 1 "$(printf '%s\n' "$repo_all" | grep -c .)"
ck ac9-it-is-in-step9 1 "$(printf '%s\n' "$repo_all" | grep -c 'skills/run/SKILL.md:.*gh issue create --repo WimSuenens/agent-plugins')"
ck ac9-issue-create-lines "2" "$(grep -rn 'gh issue create' "$PLUGIN" | grep -c .)"
ck ac9-create-baseline-is-project-local 0 "$(grep -F -- '- **Create baseline**' "$TP" | grep -c 'agent-plugins')"
ck ac9-baseline-and-a3-files-no-write-to-plugin-repo 0 "$(grep -nE 'agent-plugins' "$BA" "$A3" | grep -vE 'Never in `WimSuenens/agent-plugins`' | grep -c .)"
ck ac9-no-plugin-path-write 0 "$(grep -nE '> *"?\$\{CLAUDE_PLUGIN_ROOT\}|tee .*CLAUDE_PLUGIN_ROOT' "$SK" "$BA" "$A3" "$TP" | grep -c .)"
has ac9-step9-restates "$S9" 'This is the only instruction that names `--repo WimSuenens/agent-plugins`. Everything else you measure or record, the stage log, the hansei record, the baseline and the A3 included, stays in the project'"'"'s own tracker'

# ---------- AC-16: the A3 template: marker, fixed lines, fixed order ----------
TEMPL="$(block_after "$A3" '## 2. The template')"
ck ac16-marker-first-line '<!-- factory:a3 v1 -->' "$(printf '%s\n' "$TEMPL" | sed -n 1p)"
ck ac16-marker-regex 1 "$(printf '%s\n' "$TEMPL" | sed -n 1p | grep -Ec '^<!-- factory:a3 v([0-9]+) -->$')"
keys() { grep -E '^- [a-z0-9 ]+:|^  process item to change:' | sed -E 's/^(- [a-z0-9 ]+|  process item to change):.*/\1/'; }
WANT='- run|- series and release|- problem|- evidence|- 5 whys|  process item to change|- process item to change|- countermeasure|- measure targeted|- before|- after|- change|- items counted|- still uncertain|- other problems seen|- other overrides|- standard changes proposed|- baseline|- answer'
ck ac16-line-keys-in-order "$WANT" "$(printf '%s\n' "$TEMPL" | keys | paste -sd'|' -)"
EXA="$(block_after "$A3" '## 3. Worked example')"
ck ac16-example-same-keys-as-template "$(printf '%s\n' "$TEMPL" | keys | paste -sd'|' -)" "$(printf '%s\n' "$EXA" | keys | paste -sd'|' -)"
ck ac16-example-marker '<!-- factory:a3 v1 -->' "$(printf '%s\n' "$EXA" | sed -n 1p)"
has ac16-marker-prose-is-the-templates "$A3" 'The body'"'"'s first line is exactly `'"$(printf '%s\n' "$TEMPL" | sed -n 1p)"'`.'
has ac16-marker-prose-regex "$A3" 'A reader finds an A3 by `^<!-- factory:a3 v([0-9]+) -->$` on the first line'
has ac16-no-line-left-out "$A3" 'Fixed lines, fixed order, **no line may be left out**; a line with nothing to say reads `none (<reason>)`.'
has ac16-unknown-version-skipped "$A3" 'a reader that meets a version it does not know skips the comment and says so'
has ac16-no-experiment-line "$A3" 'There is no line keyed `experiment` in the A3'
# the six allowed reasons
for r in 'no closed item in series <M.N> to measure against' 'needs a plugin change' 'no measure with a captured before-reading' 'refused at the fence (<fenced item>)' 'no problem chosen' 'no countermeasure was tried'; do has "ac16-reason-$r" "$A3" "| \`$r\` |"; done
# the answer line grammar, cut out of the text and run
ag="$(grep -F -- '- **`answer`**' "$A3" | sed -E 's/.*Grammar of an entry: `([^`]*)`.*/\1/')"
ck ac16-answer-grammar-extracted 1 "$([ -n "$ag" ] && echo 1 || echo 0)"
oka=0; for e in 'qa-brief-names-runner (experiment): pending' 'x: keep 2026-11-12' 'ownership-each-stage: drop 2026-11-12' 'a-b-c: promote 2026-01-31'; do printf '%s\n' "$e" | grep -Eq -- "$ag" && oka=$((oka + 1)); done
ck ac16-answer-grammar-accepts-4-good 4 "$oka"
bad=0; for e in 'X: keep 2026-11-12' 'x: maybe 2026-11-12' 'x: keep 12-11-2026' 'x (experiment) : pending' 'x: keep' 'x: pending later'; do printf '%s\n' "$e" | grep -Eq -- "$ag" && bad=$((bad + 1)); done
ck ac16-answer-grammar-rejects-6-bad 0 "$bad"
printf '%s\n' "$EXA" | grep -E '^- answer: ' | sed 's/^- answer: //' | tr ';' '\n' | sed 's/^ //' > "$T/ans.txt"
ck ac16-example-answers-match-grammar 0 "$(grep -Evc -- "$ag" "$T/ans.txt")"
fk="$(grep -c . "$T/ans.txt")"; ck ac16-example-answer-present 1 "$([ "$fk" -ge 1 ] && echo 1 || echo 0)"

# ---------- AC-17, AC-19: reading lines and 'still uncertain' ----------
has ac17-check-before-post "$A3" 'Do not post an A3 whose `before`, `after` or `change` line is blank, missing, or `0` for a value that was not measured.'
has ac17-no-experiment-reasons "$A3" 'A run with no experiment posts `before`, `after` and `change` as `none (<reason>)` with a reason from section 2'"'"'s table.'
has ac17-reading-form "$A3" '`<value> (<k> of <n>; items #<a>, #<b>; factory <semver>[, <semver>])`'
for k in before after change; do ck "ac17-example-has-$k" 1 "$(printf '%s\n' "$EXA" | grep -c "^- $k: ")"; done
ck ac17-example-no-zero-without-k 0 "$(printf '%s\n' "$EXA" | grep -E '^- (before|after): ' | grep -vcE '\([0-9]+ of [0-9]+; items #')"
UNC="$(printf '%s\n' "$EXA" | grep '^- still uncertain:')"
has ac19-never-none "$A3" 'The line is **never `none` and never empty**.'
ck ac19-example-five-clauses-in-order "sample|other overrides in force|kind of work|not captured in the readings|no significance is claimed" "$(printf '%s\n' "$UNC" | sed 's/; /\n/g' | sed -E 's/^- still uncertain: //; s/^(sample|other overrides in force|kind of work|not captured in the readings|no significance is claimed).*/\1/' | paste -sd'|' -)"
has ac19-clause-sample "$A3" '1. `sample: before <k> of <n> items, after <k> of <n> items`; a count of 1 reads `one item`.'
has ac19-clause-significance "$A3" '5. `no significance is claimed: these are counts with item numbers, what moved and not that it is proven`.'
has ac19-no-reading-clause "$A3" 'With `none (<reason>)` readings, clause 1 reads `sample: no reading`.'

# ---------- AC-18: the 5 Whys rule is pointed to, not restated ----------
has ac18-pointer "$A3" 'follow the one rule in `skills/run/SKILL.md`, *The 5 Whys*, and **the A3 text does not restate it**'
ck ac18-rule-words-not-in-a3 0 "$(grep -ciE 'careless|sloppy|too weak|hallucinated|examined: the brief|substitute a process object' "$A3")"
ck ac18-rule-once-in-skill 1 "$(grep -c 'examined: the brief' "$SK")"
ck ac18-a3-names-no-other-whys-rule 0 "$(grep -c 'a role.s care or competence' "$A3")"
has ac18-refused-chain-not-posted "$A3" 'A refused chain is not posted.'
ck ac18-skill-section-exists 1 "$(grep -c '^### The 5 Whys$' "$SK")"

# ---------- AC-12, AC-13: the experiment is one override with a measure and a before-reading ----------
has ac12-fence-first "$A3" '1. **Fence first.**'
has ac12-never-before-nc "$A3" '**An experiment is never written with `before: not captured`.**'
has ac12-closed-item-needed "$A3" '2. **A closed item to measure against.**'
has ac12-at-most-one "$A3" '**The run has at most one experiment.**'
has ac12-other-overrides-not-measured "$A3" 'every later or other override is listed under `other overrides` as `not measured (not this run'"'"'s experiment)`'
has ac12-measures-outside-table "$A3" 'An experiment that names a measure outside this table is not written.'
has ac12-skill-eight-lines "$SK" 'carries eight more lines after `fence check`'
has ac12-skill-andon-none-experiment "$SK" '- andon: <URL of the andon comment | pending | none (experiment)>'
has ac13-no-plugin-edit "$SK" 'Never edit `plugins/` to apply a countermeasure.'
has ac13-needs-plugin-change "$A3" 'A countermeasure whose only form is a plugin change writes no override: the A3 reads `none (needs a plugin change)`'
# the experiment block, validated by the text's own grammar
EXPB="$T/exp.md"; awk '/^The run.s experiment \(`references\/a3.md`, section 5\) carries eight more lines/ {f=1; next} f==1 && /^```/ {f=2; next} f==2 && /^```/ {exit} f==2 {print}' "$SK" > "$EXPB"
ck ac12-skill-experiment-keys "experiment|problem|measure|direction|series|reference|before|a3" "$(sed -E 's/^- ([a-z0-9]+):.*/\1/' "$EXPB" | paste -sd'|' -)"
MEAS='^[1356] ([a-z0-9 -]+)$'
valid_exp() {  # valid_exp <file>: keys in order, measure from the table, direction down|up, before never not captured, a3 pending or URL
  awk -F': ' '
    function bad(m) { print "bad: " m; e=1 }
    /^- experiment:/ {i++; if ($2 != "yes") bad("experiment") }
    /^- problem:/ {i++; if ($2 == "") bad("problem") }
    /^- measure:/ {i++; if ($2 !~ /^(1 (total|agent working|waiting for the person|waiting on limits|stalled|interrupted|andon)|3 (product-owner|architect|developer|qa-engineer|security-reviewer|devops|docs-writer|overturned)|5 (lead|product-owner|architect|developer|qa-engineer|security-reviewer|devops|docs-writer) (spend|peak context)|6 (decision cards|demos|approvals|overturns|other))$/) bad("measure") }
    /^- direction:/ {i++; if ($2 != "down" && $2 != "up") bad("direction") }
    /^- series:/ {i++; if ($2 !~ /^[0-9]+\.[0-9]+$/) bad("series") }
    /^- reference:/ {i++}
    /^- before:/ {i++; if ($2 !~ /^[0-9.]+[hm0-9]* \([0-9]+ of [0-9]+; items #[0-9]+(, #[0-9]+)*; factory [0-9.]+\)$/) bad("before") }
    /^- a3:/ {i++; if ($2 != "pending" && $2 !~ /^https:\/\//) bad("a3") }
    END { if (i != 8) bad("count " i); exit e }' "$1"
}
cat > "$T/exp-good.md" <<'EOF'
- experiment: yes
- problem: the developer brief has no line for the runner
- measure: 3 developer
- direction: down
- series: 1.2
- reference: none
- before: 1 (2 of 2; items #5, #6; factory 1.2.0)
- a3: pending
EOF
valid_exp "$T/exp-good.md" >/dev/null 2>&1; ck ac12-validator-accepts-good 0 $?
for mut in 's/^- before: .*/- before: not captured (no closed item)/' 's/^- measure: .*/- measure: 2 qa/' 's/^- measure: .*/- measure: 4 escaped defects/' 's/^- direction: .*/- direction: sideways/' '/^- a3:/d' 's/^- experiment: yes/- experiment: no/' 's/^- before: .*/- before: 1/'; do
  sed "$mut" "$T/exp-good.md" > "$T/exp-bad.md"; valid_exp "$T/exp-bad.md" >/dev/null 2>&1; rc=$?
  ck "ac12-validator-refuses-mutant-$(printf '%s' "$mut" | tr -c 'a-z0-9' '_' | cut -c1-30)" 1 "$([ $rc -ne 0 ] && echo 1 || echo 0)"
done

# ---------- AC-20: one A3 per run, in the project's tracker, no raw data ----------
has ac20-one-comment-on-map "$A3" '**One comment per run, on the run'"'"'s map issue `#<map>`**'
has ac20-posted-once "$A3" '**Posted once at the run close, step 9.2.**'
has ac20-post-a3-find-first "$TP" '- **Post A3**: run *Find A3* first. When it prints nothing:'
has ac20-never-second "$TP" 'Never a second A3 for the run.'
has ac20-empty-run "$A3" '**No A3 for a run with no closed item**: say `0 items closed: nothing to measure` and post nothing.'
has ac20-skill-empty-run "$S9" 'say `0 items closed: nothing to measure`, post nothing, and go on to 9.3'
has ac20-run-stopped-line "$A3" 'the `run:` line reads `run stopped`'
has ac20-content-rules "$A3" 'no raw hansei record, transcript text, secret, absolute or home path, or instruction-like sentence is copied'
has ac20-names-baseline "$A3" 'It names the baseline issue by link.'
has ac20-settled-no-second "$A3" 'an answer is already recorded: the run'"'"'s A3 is settled and no second one is written'
# Find A3, run: the filter cut out of the template, on a map's comment list
fa3="$(grep -F -- '- **Find A3**' "$TP")"; fa3f="${fa3#*--jq \'}"; fa3f="${fa3f%%\'\`*}"; fa3f="${fa3f//\'\"\$me\"\'/lead-qa}"
printf '%s' '[{"id":1,"html_url":"u1","user":{"login":"lead-qa"},"body":"<!-- factory:a3 v1 -->\n## A3"},{"id":2,"html_url":"u2","user":{"login":"someone-else"},"body":"<!-- factory:a3 v1 -->\n## A3"},{"id":3,"html_url":"u3","user":{"login":"lead-qa"},"body":"text\n<!-- factory:a3 v1 -->"},{"id":4,"html_url":"u4","user":{"login":"lead-qa"},"body":"<!-- factory:hansei v4 -->"},{"id":5,"html_url":"u5","user":{"login":"lead-qa"},"body":"<!-- factory:a3 v2 -->\r\nx"}]' > "$T/map.json"
ck ac20-find-a3-own-first-line-only "1 5" "$(jq -r "$fa3f | .id" "$T/map.json" | paste -sd' ' -)"

# ---------- AC-22: the run close is written once, in order ----------
for p in '0. **Entry.**' '1. **Update the current section from the records.**' '2. **Write the experiment'"'"'s before/after reading and post the A3**' '3. **The settle round**' '4. **The feedback offer.**' '5. **Report the run closed**'; do ck "ac22-present-$(printf '%s' "$p" | cut -c1-6)" 1 "$(grep -cF -- "$p" "$S9")"; done
before ac22-1-before-2 "$S9" '1. **Update the current section' '2. **Write the experiment'
before ac22-2-before-3 "$S9" '2. **Write the experiment' '3. **The settle round**'
before ac22-3-before-4 "$S9" '3. **The settle round**' '4. **The feedback offer.**'
before ac22-4-before-5 "$S9" '4. **The feedback offer.**' '5. **Report the run closed**'
ck ac22-no-step-10 0 "$(grep -c '^## 10\.' "$SK")"
ck ac22-one-step-9 1 "$(grep -c '^## 9\. ' "$SK")"
ck ac22-no-old-offer-step 0 "$(grep -c 'Offer factory feedback' "$SK")"
ck ac22-no-other-batch-step 0 "$(grep -nE 'gather(s)? (the )?(findings|abnormalit)|batch' "$SK" | grep -v 'no other batch step gathers findings at the end of the run' | grep -c .)"
has ac22-no-report-before-answer "$S9" 'Do not report the run closed before 9.3 has an answer, applied and merged, for every override of the run.'
has ac22-stop-asks-once "$S9" 'ask once: `Close the run now? That posts the A3 and settles the overrides.` Silence, a timeout or an assumption is no yes. On no, write nothing'
has ac22-stopped-run-line "$S9" 'with the A3'"'"'s `run:` line reading `run stopped`'
# 'report ... closed' appears as an instruction only at 9.5 and in the settle round's pointer to 9.5
ck ac22-report-closed-instructions 2 "$(grep -nE '(^|[^a-z])Report the run closed' "$SK" | grep -c .)"
before ac22-report-after-settle "$SK" '3. **The settle round**' '5. **Report the run closed**'
has ac22-entry-from-8-11 "$SK" '- **The map dissolves** → step 9.'
has ac22-skill-run-identity "$SK" 'from the map'"'"'s creation (step 2) to its dissolving (step 8.11 to step 9)'

# ---------- AC-23: the settle line ----------
has ac23-experiment-line "$SK" '- The experiment: `<name> — started <date> — before <reading> / after <reading> — keep, promote or drop?`'
has ac23-other-line "$SK" '- Any other override: `<name> — started <date> — before/after: not measured (not this run'"'"'s experiment) — keep, promote or drop?`'
has ac23-not-comparable "$SK" 'When the A3'"'"'s `change` starts with `not comparable` or `not captured`, it follows the readings'
has ac23-no-figure-beyond-a3 "$SK" 'The line never shows a figure the A3 does not.'
ck ac23-no-baseline-yet-anywhere 0 "$(grep -rF 'before/after: no baseline yet' "$PLUGIN" | grep -c .)"
ck ac23-no-baseline-yet-phrase-anywhere 0 "$(grep -rFi 'no baseline yet' "$PLUGIN" | grep -c .)"
# the reading form in the settle line is the A3's reading form
ck ac23-reading-form-same "1" "$(grep -F -- '`<value> (<k> of <n>; items #<a>, #<b>; factory <semver>)`' "$SK" | grep -c .)"
has ac23-answers-edit-a3 "$SK" '2. **On each answer, *Edit A3* now**'
has ac23-recompute-after-merge "$SK" '6. **After the merge, recompute the baseline**'

# ---------- AC-24: promote is a card, never a plugin change ----------
has ac24-chosen-stays-in-force "$SK" '`promote chosen <date>` is written in the settle commit and the override **stays in force**.'
has ac24-one-way-door "$SK" '**`promote` is a one-way door** (the change goes to every project) and takes the route of step 7'
has ac24-brief-po "$SK" 'Brief the product-owner (step 7.2): Goal, a decision card for the yokoten of the override'
has ac24-recommendation-and-undo "$SK" 'the recommendation and each option'"'"'s undo cost'
has ac24-post-on-map "$SK" 'Post the card on the map issue `#<map>` (*Decision card*)'
has ac24-nothing-written "$SK" 'Nothing is written under `plugins/` and nothing is sent to `WimSuenens/agent-plugins` until the person decides the card'
has ac24-close-with-card-open "$SK" 'The run may be reported closed with the card open'
has ac24-no-route-without-card "$SK" 'No route promotes without a card: no automatic promotion, no `promote` by silence or default, no promotion that a later run start applies on its own.'
has ac24-silence-no-answer "$SK" 'Silence, a timeout or a default is no answer (F1).'
ck ac24-decision-card-ref-exists 1 "$([ -s "$PLUGIN/references/decision-card.md" ] && echo 1 || echo 0)"
has ac24-f1-covers-promote "$PR" "This covers the person's keep, promote or drop answer at a run close"
has ac24-settle-place-in-protocol "$PR" 'with messages in `work/settle-<map>/`'
has ac24-settle-place-in-skill "$SK" 'The settle worktree is a third place for role messages besides an item and a frontier round'
# no instruction anywhere promotes by writing the plugin
ck ac24-no-instruction-edits-plugins-on-promote 0 "$(grep -n 'promote' "$SK" "$A3" "$BA" | grep -iE 'edit .*plugins/|write .*plugins/|change .*plugins/factory' | grep -v 'Nothing is written under `plugins/`' | grep -c .)"

# ---------- AC-25: step 9.4 ----------
S94="$(grep -F '4. **The feedback offer.**' "$S9")"
ck ac25-asks-before-drafting 1 "$(printf '%s' "$S94" | awk '{a=index($0,"Ask the person what felt clumsy, before drafting."); b=index($0,"Then draft a factory issue"); print (a>0 && b>a) ? 1 : 0}')"
has ac25-only-what-a3-lists "$S9" 'only for what the A3 lists, plus the person'"'"'s remark'
has ac25-sources "$S9" 'the A3'"'"'s `standard changes proposed` entries (plugin changes an andon proposed, and `other` (kind 7) abnormalities), the A3'"'"'s `problem` and `other problems seen`, and the person'"'"'s remark'
has ac25-reason-per-draft "$S9" 'Each draft states why it is listed'
has ac25-blocked-and-role-work-not-drafted "$S9" 'What the A3 does not list (briefs that came back `blocked` for an input the protocol should have named, a role that did another'"'"'s work) stays in the project'"'"'s hansei and andon records and is not drafted.'
has ac25-no-project-data "$S9" 'It holds no code, no project names, no business content and no raw hansei records.'
has ac25-only-approved "$S9" 'post only those the person approves'
has ac25-promoted-not-drafted "$S9" "A promoted override's plugin change is not drafted until its decision card is decided."
# fixture: the five events of the AC and where each goes under the rule's sources
src_ok() { case "$1" in "kind 7 abnormality"|"andon none: needs a plugin change"|"person's remark") echo drafted;; *) echo "not drafted";; esac; }
ck ac25-fixture-kind7 drafted "$(src_ok 'kind 7 abnormality')"
ck ac25-fixture-needs-plugin-change drafted "$(src_ok 'andon none: needs a plugin change')"
ck ac25-fixture-remark drafted "$(src_ok "person's remark")"
ck ac25-fixture-three-blocked-briefs "not drafted" "$(src_ok 'three blocked briefs')"
ck ac25-fixture-role-did-other-work "not drafted" "$(src_ok 'role did another role work')"

# ---------- hansei v4: the label line, the extent grammar, the reading of v3 ----------
LAB="$(block_after "$HA" '### `## Label`')"
ck v4-label-line-between-tooling-and-wayfinding "tooling|overrides at start|wayfinding" "$(printf '%s\n' "$LAB" | sed -nE 's/^- (tooling|overrides at start|wayfinding): .*/\1/p' | paste -sd'|' -)"
has v4-label-never-changed "$HA" 'Like the rest of the label it is never changed afterwards.'
has v4-reads-v3-and-v4 "$HA" '**Which versions the standard reads.** v3 and v4.'
has v4-v3-list-excluded "$HA" 'a list leaves each override'"'"'s extent unrecorded, so the item is excluded from the baseline'
has v4-no-measure-changes "$HA" 'no measure changes, so v3 and v4 measures may be compared'
ext='^([a-z0-9]+(-[a-z0-9]+)* \(since [0-9]{4}-[0-9]{2}-[0-9]{2}; (whole item|from [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z|until [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z)\)(; )?)+$|^none$'
exline() { printf '%s\n' "$1" | sed 's/^- active overrides: //'; }
hexs="$(block_after "$HA" '### Worked example')"
ck v4-example-override-line-matches-grammar 1 "$(exline "$(printf '%s\n' "$hexs" | grep '^- active overrides:')" | grep -Ec "$ext")"
ck v4-fixture-override-line-from-hansei-md 1 "$(exline "- active overrides: replay-before-build (since 2026-11-07; whole item); fixtures-first (since 2026-11-08; from 2026-11-08T15:02Z); old-rule (since 2026-11-05; until 2026-11-08T15:30Z)" | grep -Ec "$ext")"
ck v4-grammar-rejects-v3-entry 0 "$(exline "- active overrides: replay-before-build (since 2026-11-08)" | grep -Ec "$ext")"
ck v4-grammar-rejects-bad-time 0 "$(exline "- active overrides: x (since 2026-11-08; from 15:02)" | grep -Ec "$ext")"
ck v4-hansei-md-has-the-worked-line 1 "$(grep -cF 'replay-before-build (since 2026-11-07; whole item); fixtures-first (since 2026-11-08; from 2026-11-08T15:02Z); old-rule (since 2026-11-05; until 2026-11-08T15:30Z)' "$HA")"
has v4-marker-prose-is-v4 "$HA" 'The body'"'"'s **first line** is exactly `<!-- factory:hansei v4 -->`.'
ck v4-no-v3-marker-in-template 0 "$(block_after "$HA" '### Layout' | grep -c 'hansei v3')"

# ---------- AC-26: standard work stays inside its paths ----------
base="$(git -C "$REPO" merge-base origin/main HEAD 2>/dev/null || git -C "$REPO" merge-base main HEAD 2>/dev/null)"
if [ -n "$base" ] && [ "$base" != "$(git -C "$REPO" rev-parse HEAD)" ]; then
  chg="$(git -C "$REPO" diff --name-only "$base" HEAD -- plugins/factory)"
  out_of_list="$(printf '%s\n' "$chg" | grep -vE '^plugins/factory/(skills/run/SKILL\.md|references/[^/]+\.md|scripts/[^/]+|\.claude-plugin/plugin\.json)$' | grep . || true)"
  ck ac26-the-one-exception "plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md" "$out_of_list"
  ck ac26-no-new-agent-file 0 "$(git -C "$REPO" diff --name-only --diff-filter=ACR "$base" HEAD -- plugins/factory/agents | grep -c .)"
  ck ac26-no-agent-changed 0 "$(git -C "$REPO" diff --name-only "$base" HEAD -- plugins/factory/agents plugins/factory/hooks plugins/factory/scripts | grep -c .)"
  ck ac26-no-new-script 0 "$(git -C "$REPO" diff --name-only --diff-filter=A "$base" HEAD -- plugins/factory/scripts plugins/factory/hooks | grep -c .)"
else
  skip ac26-diff-against-main "no merge base with main in this checkout (clean export)"
fi

# ---------- AC-27: the release; the tooling fingerprint did not move ----------
ver="$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")"
ck ac27-version-is-minor-above-1.1.0 1 "$(printf '%s' "$ver" | awk -F. '{print ($1==1 && $2>=2) ? 1 : 0}')"
if git -C "$REPO" rev-parse -q --verify refs/tags/factory-v1.1.0 >/dev/null 2>&1; then
  mkdir -p "$T/v110"; git -C "$REPO" archive factory-v1.1.0 plugins/factory | tar -x -C "$T/v110"
  old="$(bash "$FP" "$T/v110/plugins/factory")"; new="$(bash "$FP" "$PLUGIN")"
  ck ac27-tooling-did-not-move "$(line "$old" 3)" "$(line "$new" 3)"
  differ ac27-standard-moved "$(line "$old" 2)" "$(line "$new" 2)"
  ck ac27-old-release-is-1.1.0 "release: 1.1.0" "$(line "$old" 1)"
else
  skip ac27-fingerprint-vs-1.1.0 "tag factory-v1.1.0 not in this clone"
fi
done_
