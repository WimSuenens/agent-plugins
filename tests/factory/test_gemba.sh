#!/bin/bash
# #60 AC-1 to AC-9: the written rule, walk and line of references/hansei.md section 6 (and SKILL.md 8.3a, baseline.md item 7) replayed step by
# step on fixtures (tests/factory/fixtures/gemba/). Offline: no live session, no network. What only a live run can show is listed in
# reviews/qa-60.md under "Unverified". Known text defects are named skips (QA-60 finding Fn), not red checks.
# The expected rows in fixtures/gemba/expected.tsv were derived by hand from the rule and committed before the readers were written.
. "$(dirname "$0")/lib.sh"
HA="$PLUGIN/references/hansei.md"; SK="$PLUGIN/skills/run/SKILL.md"; BA="$PLUGIN/references/baseline.md"; A3="$PLUGIN/references/a3.md"
FX="$REPO/tests/factory/fixtures/gemba"; TF="$REPO/tests/factory"
PA="$TF/gemba_pick.py"; PB="$TF/gemba_pick.awk"; GL="$TF/gemba_line.py"
command -v python3 >/dev/null || { echo "skip: python3 missing"; exit 0; }
command -v jq >/dev/null || { echo "skip: jq missing"; exit 0; }

sec6="$(awk '/^## 6\. The gemba walk/{f=1} f' "$HA")"
sub6() { printf '%s\n' "$sec6" | awk -v h="### $1" '$0==h{f=1;next} /^### /{f=0} f'; }   # a subsection of section 6
printf '%s\n' "$sec6" > "$T/sec6.md"

# ---------- T1 (AC-1): the sample rule, in the text ----------
RULE="$(sub6 'Which stage: the sample rule')"
printf '%s\n' "$RULE" > "$T/rule.md"
ck t1-section-6-exists 1 "$([ -n "$sec6" ] && echo 1 || echo 0)"
for r in product-owner architect developer qa-engineer security-reviewer devops docs-writer; do has t1-role-$r "$T/rule.md" "\`$r\`"; done
has t1-agents-not-dash "$T/rule.md" 'whose `Agents` cell is not `-`'
has t1-lead-person-dash-not-role "$T/rule.md" 'A `lead` row, a `person` row and a row with `Agents` `-` are not role rows.'
has t1-flag-prefix "$T/rule.md" 'trimmed and lowercased, does not start with `done` or `pass`'
has t1-flag-paused "$T/rule.md" 'its `Notes` contain `paused by A` followed by a digit'
has t1-done-then-stalled-eligible "$T/rule.md" '`done, then stalled` and `pass (3 medium, 2 low)`: not flagged'
has t1-no-notes-column "$T/rule.md" 'A log with no `Notes` column has no row paused by an andon'
has t1-listing-order "$T/rule.md" 'in the order the log lists them, not sorted by the `#` cell'
has t1-index-from-zero "$T/rule.md" 'the eligible row at index `<id> mod n`, counting from 0'
has t1-fallback-all-role-rows "$T/rule.md" 'the eligible set is every role row'
has t1-already-flagged "$T/rule.md" 'the line marks the row `already flagged`'
has t1-no-role-row "$T/rule.md" 'no stage is picked and the line reads `not captured (no role stage ran)`'
has t1-position-when-no-number-column "$T/rule.md" 'its position counted from 0 when the log has no `#` column'
has t1-same-role-two-rows "$T/rule.md" 'Two rows of one role (a feedback round) are two rows.'
has t1-id-is-slice-ticket "$T/rule.md" "\`<id>\`, the slice ticket's number"
steps14="$(grep -E '^[1-4]\. \*\*' "$T/rule.md")"
for w in duration Waits 'Peak ctx' random 'earlier record' judgement; do
  ck t1-steps-1-to-4-never-use-$(echo "$w" | tr ' ' '-') 0 "$(printf '%s\n' "$steps14" | grep -ci -- "$w")"
done
has t1-step-5-excludes-all-of-them "$T/rule.md" 'No duration, no `Waits`, no `Peak ctx`, no judgement, no earlier record, no random choice.'

# ---------- T2 (AC-1): the rule replayed on W12, C49, L57 and the variants, by two independent readers ----------
# W12: the stage log of hansei.md section 4, cut out of the standard itself
awk '/^## 4\. Stage-log worked example/{f=1} /^## 5\./{f=0} f && /^\| (# \||[0-9]+ \|)/ && !/^\| Id/' "$HA" | awk '/^\| # \| Stage \| Role/{f=1} /^\| (W[0-9]|Id)/{f=0} f' > "$T/w12.md"
# the table in section 4 has the stage-log header and 13 rows; the separator line is kept by the next awk
awk '/^## 4\. Stage-log worked example/{f=1} /^## 5\./{f=0} f' "$HA" | awk '/^\| # \| Stage \| Role/{f=1;print;next} f&&/^\|---/{print;next} f&&/^\| [0-9]+ \|/{print;next} f&&!/^\|/{f=0}' > "$T/w12.md"
ck t2-w12-extracted-13-rows 13 "$(grep -cE '^\| [0-9]+ \|' "$T/w12.md")"
logfile() { for d in "$T" "$FX/logs"; do [ -f "$d/$1.md" ] && { echo "$d/$1.md"; return; }; done; }
pickA() { python3 -I "$PA" "$1" "$2"; }
pickB() { awk -v id="$2" -f "$PB" "$1"; }
while IFS=$'\t' read -r log id row flag; do
  case "$log" in \#*|'') continue;; esac
  f="$(logfile "$log")"
  ck "t2-readerA-$log-id$id" "$row $flag" "$(pickA "$f" "$id")"
  ck "t2-readerB-$log-id$id" "$row $flag" "$(pickB "$f" "$id")"
done < "$FX/expected.tsv"
# two readers agree on every id from 1 to 120 on every input
dis=0; ids120="$(seq 1 120 | paste -sd' ' -)"; for log in w12 c49-derived l57-derived contract14 v1-all-flagged v2-one-eligible v3-two-rows-of-a-role v4-done-then-stalled v6-dash-agents v7-no-role-row v8-no-number-column v9-result-spelling v10-notes-paused v11-no-result-column; do
  f="$(logfile "$log")"
  python3 -I "$PA" "$f" $ids120 > "$T/A.out"; awk -v ids="$ids120" -f "$PB" "$f" > "$T/B.out"
  ck "t2-readers-agree-ids-1-120-$log" "$(cat "$T/A.out")" "$(cat "$T/B.out")"
  ck "t2-reader-output-has-120-lines-$log" 120 "$(wc -l < "$T/A.out" | tr -d ' ')"
done
ck t2-two-readers-agree-on-every-input-and-id 0 "$dis"
# the headline rows, and the author's cross-check quoted only after QA's own rows were fixed (see reviews/qa-60.md)
ck t2-w12-row-2-of-6-eligible 2 "$(pickA "$T/w12.md" 12 | cut -d' ' -f1)"
ck t2-c49-row-8-of-11-eligible 8 "$(pickA "$FX/logs/c49-derived.md" 49 | cut -d' ' -f1)"
ck t2-l57-row-10-of-13-eligible 10 "$(pickA "$FX/logs/l57-derived.md" 57 | cut -d' ' -f1)"
# the section-6 example and the contract's: item #14, rows 2,3,4,8 eligible, 14 mod 4 = 2, row 4
has t2-section-6-example-text "$T/rule.md" 'Example, item #14: role rows 2, 3, 4, 5, 7, 8; row 5 (`findings`) and row 7 (`paused by A1`) are flagged; eligible in log order 2, 3, 4, 8, so `n = 4`; `14 mod 4 = 2`: the eligible row at index 2, row 4.'
ck t2-contract-14-row-4 "4 -" "$(pickA "$FX/logs/contract14.md" 14)"
# the worked record of hansei.md names the row the rule picks on its own stage log
w12line="$(grep -m1 '^- gemba: ' <(awk '/^### Worked example/{f=1} f' "$HA"))"
case "$w12line" in "- gemba: row 2 Requirement (product-owner); "*) r=1;; *) r=0;; esac
ck t2-worked-example-line-is-the-row-the-rule-picks 1 "$r"
ck t2-w12-row-2-is-requirement-product-owner "| 2 | Requirement | product-owner |" "$(grep -E '^\| 2 \|' "$T/w12.md" | cut -d'|' -f1-4 | sed 's/  */ /g;s/ *$//' | sed 's/$/ |/')"

# fresh-reader style check 1: a reader that has only the rule's words, in another language (awk) and sharing no code with the first, picks the
# same row; checked above for every id. Check 2: the same log with its columns permuted, renamed (Agent for Agents) and padded must pick the same row.
permute() {  # permute <log.md> <out.md>: reverse the column order, keep the header names
  python3 -I - "$1" "$2" <<'PY'
import sys
L=[l for l in open(sys.argv[1]).read().split('\n') if l.startswith('|')]
out=[]
for l in L:
    c=[x.strip() for x in l.strip().strip('|').split('|')]
    c=c[::-1]
    out.append('| '+' | '.join(c)+' | extra |' if not l.startswith('|---') else '|'+'|'.join(['---']*(len(c)+1))+'|')
open(sys.argv[2],'w').write('\n'.join(out)+'\n')
PY
}
for log in c49-derived l57-derived w12 v10-notes-paused; do
  f="$(logfile "$log")"; permute "$f" "$T/perm-$log.md"
  same=1; for id in 1 5 12 49 57 60 99; do [ "$(pickA "$f" "$id")" = "$(pickA "$T/perm-$log.md" "$id")" ] && [ "$(pickB "$f" "$id")" = "$(pickB "$T/perm-$log.md" "$id")" ] || same=0; done
  ck "t2-permuted-columns-same-pick-$log" 1 "$same"
done
# the rule needs no measure the log lacks: a log with only # Stage Role Agents Result picks (no Notes, no times, no Waits)
printf '%s\n' '| # | Stage | Role | Agents | Result |' '|---|---|---|---|---|' '| 1 | a | lead | - | done |' '| 2 | b | developer | x1 | done |' '| 3 | c | architect | x2 | pass |' > "$T/min.md"
ck t2-minimal-log-picks "3 -" "$(pickA "$T/min.md" 5)"
ck t2-minimal-log-readerB "3 -" "$(pickB "$T/min.md" 5)"

# ---------- the walk's commands, cut out of section 6 and run (T3, T5, T7, T8) ----------
CMDS="$(sub6 'The commands and the cap')"
blk() { printf '%s\n' "$CMDS" | awk -v k="$1" '/^```/{c++; if(c==2*k-1){f=1;next} if(c==2*k){f=0}} f'; }
blk 1 > "$T/blk1.sh"; blk 2 > "$T/blk2.sh"
ck t8-two-command-blocks-extracted 1 "$([ -s "$T/blk1.sh" ] && [ -s "$T/blk2.sh" ] && echo 1 || echo 0)"
G="$TF/gemba_transcript.py"
python3 -I "$G" 400 "$T/big.jsonl" --edit plugins/x/a.md          # a view of about 200,000 characters
python3 -I "$G" 6 "$T/small.jsonl" --edit plugins/x/a.md
# walk <brief> <budget> <transcripts...>: run block 1 with the placeholders filled; stdout in $T/w.out, stderr in $T/w.err
walk() {
  b="$1"; bud="$2"; shift 2
  sed -e "s#work/<id>/<brief file>#$b#" -e "s#<transcript paths>#$*#" -e "s#<budget>#$bud#g" "$T/blk1.sh" > "$T/run1.sh"
  bash "$T/run1.sh" > "$T/w.out" 2> "$T/w.err"
}
# The Lead's two steps: read the brief (its count sets the budget), then the view under 30000 minus the brief. The numeric-only lines of the
# output are the brief's count and the view's count; m (the whole view's size) is the last token (glued to a cut last line, QA-60 F2).
walk_full() {  # walk_full <brief> <transcripts...>: sets bn vn wv n m partial
  b="$1"; shift
  walk "$b" 30000 "$@"; bn="$(grep -E '^ *[0-9]+$' "$T/w.out" | sed -n 1p | tr -d ' ')"
  budget=$((30000 - bn)); [ "$budget" -lt 0 ] && budget=0
  if [ "$budget" -gt 0 ]; then walk "$b" "$budget" "$@"; nums="$(grep -E '^ *[0-9]+$' "$T/w.out" | tr -d ' ')"
    vn="$(printf '%s\n' "$nums" | sed -n 2p)"; wv="$(tail -1 "$T/w.out" | awk '{print $NF}')"   # m can be glued to a cut last line
  else vn=0; walk "$b" 30000 "$@"; wv="$(tail -1 "$T/w.out" | awk '{print $NF}')"; fi
  n=$((bn + vn)); m=$((bn + wv)); partial=0; [ "$n" -lt "$m" ] && partial=1
}
printf '%s\n' 'Brief: example' 'Done:' '- write plugins/x/a.md' '- write plugins/x/b.md' '- write plugins/x/c.md' 'Constraints:' '- touch only plugins/' '- no new agent' > "$T/brief3.md"
BRIEFN="$(wc -c < "$T/brief3.md" | tr -d ' ')"

# T8 (AC-6): a 200,000-character view: the figure is at most 30000, the line reads partial (cap), n equals the characters the commands returned
walk_full "$T/brief3.md" "$T/big.jsonl"
ck t8-big-view-is-over-190000 1 "$([ "$wv" -gt 190000 ] && echo 1 || echo 0)"
ck t8-brief-count-is-wc-c-of-the-brief "$BRIEFN" "$bn"
ck t8-n-at-most-30000 1 "$([ "$n" -le 30000 ] && echo 1 || echo 0)"
ck t8-n-is-exactly-the-cap-when-view-is-longer 30000 "$n"
ck t8-partial-when-view-longer-than-budget 1 "$partial"
printf '%s' "- gemba: row 4 Build (developer); read transcript $n chars, partial (cap); found nothing in the part read ($n chars of $m); changes nothing" > "$T/line.txt"
ck t8-partial-line-is-in-the-grammar OK "$(python3 -I "$GL" "$(cat "$T/line.txt")" | cut -d: -f1)"
# the literal bytes the commands return: the count lines are printed beside the evidence
walk "$T/brief3.md" $((30000 - BRIEFN)) "$T/big.jsonl"; returned="$(wc -c < "$T/w.out" | tr -d ' ')"
if [ "$returned" -le 30000 ]; then ck t8-bytes-returned-at-most-30000 1 1; else skip t8-bytes-returned-at-most-30000 "QA-60 F2: the commands print $returned bytes in all (the evidence is capped at 30000; the count lines and the m line come on top)"; fi
# a smaller view is read whole and is not partial
walk_full "$T/brief3.md" "$T/small.jsonl"
ck t8-small-view-read-whole-not-partial 0 "$partial"
ck t8-small-n-equals-m "$m" "$n"
# the budget shrinks with the brief: a 12000-character brief leaves 18000 for the view
head -c 12000 /dev/zero | tr '\0' 'b' | fold -w 100 > "$T/brief12k.md"; echo >> "$T/brief12k.md"; B12="$(wc -c < "$T/brief12k.md" | tr -d ' ')"
walk_full "$T/brief12k.md" "$T/big.jsonl"
ck t8-budget-shrinks-view-is-30000-minus-brief $((30000 - B12)) "$vn"
ck t8-total-still-30000 30000 "$n"
# a brief longer than the cap is cut at 30000 by its own head -c, and no further read is made
head -c 40000 /dev/zero | tr '\0' 'b' | fold -w 100 > "$T/brief40k.md"; echo >> "$T/brief40k.md"
walk_full "$T/brief40k.md" "$T/big.jsonl"
ck t8-huge-brief-cut-at-30000 30000 "$bn"
ck t8-huge-brief-leaves-no-view 0 "$vn"
# two transcripts share one cap
walk_full "$T/brief3.md" "$T/big.jsonl" "$T/big.jsonl"
ck t8-two-transcripts-one-cap 1 "$([ "$n" -le 30000 ] && echo 1 || echo 0)"
# the text: every read command ends in head -c; no unbounded read anywhere in section 6
has t8-text-30000-cap "$T/sec6.md" 'at most **30,000 characters**'
has t8-text-every-read-ends-in-head-c "$T/sec6.md" 'Every read command ends in `head -c <budget>`'
has t8-text-no-further-read-at-zero "$T/sec6.md" 'when it is 0 or less, no further read is made'
has t8-text-never-a-whole-transcript "$T/sec6.md" 'The walk never reads a whole transcript.'
has t8-text-awk-under-head-c "$T/sec6.md" 'all under `head -c <budget>`'
has t8-text-one-more-bounded-read "$T/sec6.md" 'it may then make **one** more bounded read'
has t8-text-only-through-these-commands "$T/sec6.md" 'The walk reads **only** through the commands below.'
ck t8-no-unbounded-cat-of-transcript-or-gh 0 "$(grep -vE '^(Total read|The walk reads|Every read)' "$T/sec6.md" | grep -E 'cat "?\$?[a-z]*\.jsonl|gh issue view|gh api|git log -p|git show [^ ]+$' | grep -c .)"
ck t8-every-jq-and-view-line-is-bounded 1 "$(grep -E 'view \| head -c <budget>' "$T/blk1.sh" | grep -c .)"
ck t8-brief-read-bounded-by-head-c-30000 1 "$(grep -c 'head -c 30000 "work/<id>/<brief file>"' "$T/blk1.sh")"

# ---------- T3 (AC-2): the evidence, in this order; the Summary is never evidence ----------
EV="$(sub6 'Evidence')"; printf '%s\n' "$EV" > "$T/ev.md"
ck t3-transcript-is-first-commits-second 1 "$([ "$(grep -n '^1\. \*\*The transcript\*\*' "$T/ev.md" | cut -d: -f1)" -lt "$(grep -n '^2\. \*\*The commits and the result file\*\*' "$T/ev.md" | cut -d: -f1)" ] && echo 1 || echo 0)"
has t3-in-this-order-of-preference "$T/ev.md" 'In this order of preference:'
has t3-transcript-found-by-the-close-scan-find "$T/ev.md" "find ~/.claude/projects -name 'agent-<agent id>.jsonl'"
has t3-commits-subject-prefix "$T/ev.md" 'whose subject starts `#<id> <role>: `'
has t3-result-file-without-summary "$T/ev.md" 'with its `Summary` field removed'
has t3-whole-row-from-one-source "$T/ev.md" 'A row is read from transcripts or from commits, never a mix.'
has t3-not-evidence "$T/ev.md" "**Not evidence, never read as such:** the result's \`Summary\`, the completion notice's text, the stage summary comment, and the final reply of a transcript."
has t3-traced-only-by-call-result-diff "$T/ev.md" 'a `Done` item is traced only by a tool call, a tool result or a diff, never by a sentence of the agent'"'"'s'
has t3-artifact-traced-only-by-diff "$T/ev.md" 'an artifact path is traced only when a commit diff touches it'
# every line of section 6 that names the Summary says it is removed or not evidence
ck t3-every-summary-mention-is-a-refusal 0 "$(printf '%s\n' "$sec6" | grep -F 'Summary' | grep -vE 'Not evidence|with its `Summary` field removed|not evidence|dropping|Summary:' | grep -c .)"
# the awk that removes the Summary, cut out of the standard and run on a result with a multi-line Summary
awk_cmd="$(printf '%s\n' "$CMDS" | awk '/^```/{c++; if(c==3){f=1;next} if(c==4){f=0}} f')"
ck t3-awk-block-extracted 1 "$([ -n "$awk_cmd" ] && echo 1 || echo 0)"
cat > "$T/result.md" <<'X'
# Result: developer — 60
Status: done
Progress:
  Done: step one; step two
  Next: none
Summary: Everything in the brief is done and green.
  Second line of the summary, indented.
  Third line says all three Done items are written.
Artifacts: plugins/x/a.md, plugins/x/b.md
Decisions: none
Open questions: none
Known-red tests (a free heading after the fields):
  - one
X
printf '%s\n' "$awk_cmd" | sed "s#\"work/<id>/<result file>\"#\"$T/result.md\"#" > "$T/awk.sh"; bash "$T/awk.sh" > "$T/result.out"
ck t3-summary-field-and-continuations-dropped 0 "$(grep -ci 'summary\|second line of the\|third line says' "$T/result.out")"
ck t3-status-progress-artifacts-decisions-kept 1 "$(grep -c '^Status: done$' "$T/result.out")$(grep -c '^Progress:$' "$T/result.out" | sed 's/^1$//;s/^0$/x/')$(grep -c '^Artifacts:' "$T/result.out" | sed 's/^1$//;s/^0$/x/')$(grep -c '^Decisions:' "$T/result.out" | sed 's/^1$//;s/^0$/x/')"
ck t3-progress-body-kept 2 "$(grep -c '^  Done: step one\|^  Next: none' "$T/result.out")"
ck t3-free-heading-after-fields-kept 1 "$(grep -c '^Known-red tests' "$T/result.out")"
# a Summary that is the last field: its continuation lines run to the end (no later field to stop it): they are still dropped
printf '%s\n' 'Status: done' 'Summary: only field after status' '  and its second line' > "$T/result2.md"
sed "s#\"work/<id>/<result file>\"#\"$T/result2.md\"#" "$T/awk.sh" > /dev/null; printf '%s\n' "$awk_cmd" | sed "s#\"work/<id>/<result file>\"#\"$T/result2.md\"#" > "$T/awk2.sh"
ck t3-summary-last-field-dropped-to-end "Status: done" "$(bash "$T/awk2.sh")"
# a result with no Summary is passed through unchanged
printf '%s\n' 'Status: done' 'Artifacts: x' > "$T/result3.md"; printf '%s\n' "$awk_cmd" | sed "s#\"work/<id>/<result file>\"#\"$T/result3.md\"#" > "$T/awk3.sh"
ck t3-no-summary-unchanged "$(cat "$T/result3.md")" "$(bash "$T/awk3.sh")"
# a Summary whose claim the transcript does not back: the view shows the calls, the claim only on the FINAL line
python3 -I "$G" 3 "$T/claim.jsonl" --edit plugins/x/a.md --edit plugins/x/b.md --final 'All three Done items are written: plugins/x/a.md, plugins/x/b.md and plugins/x/c.md.'
walk "$T/brief3.md" 29000 "$T/claim.jsonl"
ck t3-claim-c-md-appears-on-the-FINAL-line-only 1 "$(sed -n '/^== agent/,$p' "$T/w.out" | grep -c 'c\.md' | tr -d ' ')"
ck t3-claim-line-is-FINAL 1 "$(sed -n '/^== agent/,$p' "$T/w.out" | grep 'c\.md' | grep -c '^FINAL ')"
ck t3-calls-trace-a-and-b 2 "$(grep -E '^CALL Edit' "$T/w.out" | grep -cE 'plugins/x/[ab]\.md')"
ck t3-no-call-or-result-traces-c 0 "$(grep -E '^(CALL|RESULT)' "$T/w.out" | grep -c 'c\.md')"

# ---------- T4 (AC-2, AC-3): what is compared ----------
CMP="$(sub6 'What is compared')"; printf '%s\n' "$CMP" > "$T/cmp.md"
has t4-brief-fields "$T/cmp.md" 'the **brief** of the row (each `Done` item, each `Constraints` item, the `Output` paths)'
has t4-row-fields "$T/cmp.md" 'the **row** in the stage log (`Result`, `Notes`, `Waits`)'
has t4-exactly-three "$T/cmp.md" 'Look for exactly three things:'
has t4-thing-1 "$T/cmp.md" 'a `Done` item with no trace of the work in the evidence'
has t4-thing-2 "$T/cmp.md" "work in the evidence that the brief's \`Constraints\` or the role's ownership forbids"
has t4-ownership-from-origin-main "$T/cmp.md" 'read ownership from `git show origin/main:docs/agents/factory.md`, never the worktree copy'
has t4-thing-3 "$T/cmp.md" 'a row `Result` or `Notes` that the evidence contradicts'
ck t4-three-numbered-things 3 "$(grep -cE '^[1-3]\. ' "$T/cmp.md")"
has t4-stage-log-alone-is-not-a-walk "$T/cmp.md" 'A walk that checks the stage log alone is not a walk.'
has t4-item-is-a-bullet-or-clause "$T/cmp.md" 'An item is a bullet line under the field; where a field is one line, each `;`-separated clause is an item.'
# counting d and c by that rule: bullets under the field, or the ;-separated clauses of a one-line field
count_items() {  # count_items <brief.md> <Field>
  awk -v F="$2:" '$0==F{b=1;n=0;next} index($0,F)==1{rest=substr($0,length(F)+1); gsub(/^ +| +$/,"",rest); k=split(rest,p,";"); print k; done=1; exit} b&&/^- /{n++; next} b&&!/^- /{print n; done=1; exit} END{if(!done&&b)print n}' "$1"; }
ck t4-count-done-bullets 3 "$(count_items "$T/brief3.md" Done)"
ck t4-count-constraints-bullets 2 "$(count_items "$T/brief3.md" Constraints)"
printf '%s\n' 'Done: a thing; another thing; a third' 'Constraints: only one' > "$T/brief1.md"
ck t4-count-done-clauses 3 "$(count_items "$T/brief1.md" Done)"
ck t4-count-constraints-one-clause 1 "$(count_items "$T/brief1.md" Constraints)"

# ---------- T5 (AC-3): three fixtures of one sampled row; the stage-log row is the same for all ----------
# the row: Result done, no note. The view the walk's commands give is what the comparison reads (the filter must keep what the comparison needs).
python3 -I "$G" 4 "$T/fa.jsonl" --edit plugins/x/a.md --edit plugins/x/b.md --final 'All three Done items are written.'
python3 -I "$G" 4 "$T/fb.jsonl" --edit plugins/x/a.md --edit plugins/x/b.md --edit plugins/x/c.md --final 'Done.'
python3 -I "$G" 4 "$T/fc.jsonl" --edit plugins/x/a.md --edit plugins/x/b.md --edit plugins/x/c.md --edit tests/other/test.sh --final 'Done.'
OWN='plugins/'    # the developer's ownership in the fixture's factory.md
compare() {  # compare <view> -> prints  untraced=<k...>; outside=<path...>
  v="$1"; un=""; k=0
  for p in $(sed -n 's/^- write \(.*\)$/\1/p' "$T/brief3.md"); do k=$((k+1)); grep -E '^(CALL|RESULT|diff --git|\+)' "$v" | grep -qF "$p" || un="$un$k "; done
  out="$(grep -E '^CALL (Edit|Write)' "$v" | sed -n 's/.*"file_path":"\([^"]*\)".*/\1/p' | grep -v "^$OWN" | paste -sd' ' -)"
  echo "untraced=[${un% }] outside=[$out]"; }
for x in a b c; do walk "$T/brief3.md" 29000 "$T/f$x.jsonl"; cp "$T/w.out" "$T/view-$x.txt"; done
ck t5-a-third-done-item-untraced-though-final-claims-it "untraced=[3] outside=[]" "$(compare "$T/view-a.txt")"
ck t5-a-final-line-claims-it 1 "$(grep -c '^FINAL All three' "$T/view-a.txt")"
ck t5-b-all-traced-nothing-outside "untraced=[] outside=[]" "$(compare "$T/view-b.txt")"
ck t5-c-edit-outside-ownership-found "untraced=[] outside=[tests/other/test.sh]" "$(compare "$T/view-c.txt")"
ck t5-three-fixtures-three-different-views-one-stage-log-row 3 "$(for x in a b c; do compare "$T/view-$x.txt"; done | sort -u | wc -l | tr -d ' ')"
d=$(count_items "$T/brief3.md" Done); c=$(count_items "$T/brief3.md" Constraints)
la="- gemba: row 4 Build (developer); read transcript 4000 chars; found difference: Done item 3 has no trace in the calls or the commit diffs, process object: the brief; changes process item: the brief named no output path for Done item 3 (https://example.invalid/shop/issues/9#issuecomment-1)"
lb="- gemba: row 4 Build (developer); read transcript 4000 chars; found nothing ($d Done items and $c constraints checked); changes nothing"
lc="- gemba: row 4 Build (developer); read transcript 4000 chars; found difference: the path tests/other/test.sh is outside the role's ownership, process object: ownership table; changes none: needs a plugin change"
ck t5-a-line-accepted OK "$(python3 -I "$GL" "$la" | cut -d: -f1)"
ck t5-b-line-with-counts-accepted OK "$(python3 -I "$GL" "$lb" | cut -d: -f1)"
ck t5-b-counts-are-3-and-2 1 "$(printf '%s' "$lb" | grep -c 'found nothing (3 Done items and 2 constraints checked)')"
ck t5-c-line-accepted OK "$(python3 -I "$GL" "$lc" | cut -d: -f1)"
ck t5-b-without-counts-refused REJECT "$(python3 -I "$GL" "${lb/ (3 Done items and 2 constraints checked)/}" | cut -d: -f1)"
ck t5-b-with-one-count-refused REJECT "$(python3 -I "$GL" "${lb/ and 2 constraints checked/ checked}" | cut -d: -f1)"
ck t5-a-as-nothing-refused REJECT "$(python3 -I "$GL" "${la/found difference: Done item 3 has no trace in the calls or the commit diffs, process object: the brief; changes process item: the brief named no output path for Done item 3 (https:\/\/example.invalid\/shop\/issues\/9#issuecomment-1)/found nothing; changes nothing}" | cut -d: -f1)"
has t5-text-nothing-needs-both-counts "$T/cmp.md" 'it is refused'
has t5-text-nothing-form "$T/cmp.md" '`nothing (<d> Done items and <c> constraints checked)`'
has t5-text-first-difference-by-brief-order "$T/cmp.md" 'for the first by brief order (a lower `Done` item before a higher, then a `Constraints` item, then a path, then a row field)'
has t5-text-sentence-200-no-semicolon "$T/cmp.md" 'one line, at most 200 characters, no `;`, no newline, no copied text of the transcript, the brief or a commit message'
done_
