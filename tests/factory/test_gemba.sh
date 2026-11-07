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

# ---------- T6 (AC-4): the line in the template ----------
# first fenced block under a heading; the heading scan is fence-aware (the template holds a '### Measures' line inside its fence)
fblock() { awk -v h="$2" '/^```/{fence=!fence; if(f&&!fence){exit} if(f&&fence){inb=1} next} !fence&&/^#{2,3} /{f=($0==h)} f&&fence{print}' "$1"; }
LAY="$(fblock "$HA" '### Layout')"
printf '%s\n' "$LAY" > "$T/layout.txt"
ck t6-template-first-line '<!-- factory:hansei v5 -->' "$(sed -n 1p "$T/layout.txt")"
ck t6-exactly-one-gemba-line-in-the-template 1 "$(grep -c '^- gemba: ' "$T/layout.txt")"
ck t6-gemba-directly-after-cross-check "- stage-log cross-check: largest gap <N>m (<row>: <evidence>)|- gemba: <walk>|" "$(grep -A2 '^- stage-log cross-check:' "$T/layout.txt" | head -3 | paste -sd'|' -)"
ck t6-gemba-before-measures-heading "- gemba: <walk>||### Measures" "$(grep -B0 -A2 '^- gemba: ' "$T/layout.txt" | paste -sd'|' - | sed 's/|$//')"
ck t6-gemba-is-not-a-numbered-line 0 "$(grep -cE '^[0-9]+\. gemba' "$T/layout.txt")"
ck t6-measures-numbered-1-to-7-only "1 2 3 4 5 6 7" "$(grep -E '^[0-9]+\. ' "$T/layout.txt" | cut -d. -f1 | paste -sd' ' -)"
if git -C "$REPO" rev-parse --verify --quiet main >/dev/null 2>&1; then
  git -C "$REPO" show main:plugins/factory/references/hansei.md > "$T/hansei-main.md"; fblock "$T/hansei-main.md" '### Layout' > "$T/layout-main.txt"
  ck t6-measures-block-identical-to-v4 "$(awk '/^### Measures/{f=1} f' "$T/layout-main.txt")" "$(awk '/^### Measures/{f=1} f' "$T/layout.txt")"
  trim_end() { awk 'NF{last=NR} {l[NR]=$0} END{for(i=1;i<=last;i++)print l[i]}'; }
  ck t6-header-block-differs-only-by-the-gemba-line-and-marker "$(sed '1d' "$T/layout-main.txt" | awk '/^### Measures/{exit} 1' | trim_end)" "$(sed '1d' "$T/layout.txt" | awk '/^### Measures/{exit} 1' | grep -v '^- gemba: ' | trim_end)"
else skip t6-measures-identical-to-v4 "no main ref in this checkout"; fi
WEX="$(fblock "$HA" '### Worked example')"
ck t6-worked-example-first-line '<!-- factory:hansei v5 -->' "$(printf '%s\n' "$WEX" | sed -n 1p)"
ck t6-worked-example-one-gemba-line 1 "$(printf '%s\n' "$WEX" | grep -c '^- gemba: ')"
ck t6-worked-example-gemba-after-cross-check 1 "$(printf '%s\n' "$WEX" | grep -A1 '^- stage-log cross-check:' | tail -1 | grep -c '^- gemba: ')"
ck t6-worked-example-line-in-grammar OK "$(python3 -I "$GL" "$(printf '%s\n' "$WEX" | grep '^- gemba: ')" | cut -d: -f1)"
ck t6-section-6-example-line-in-grammar OK "$(python3 -I "$GL" "$(printf '%s\n' "$sec6" | grep '^- gemba: ' | head -1)" | cut -d: -f1)"
ck t6-worked-example-still-seven-measures "1 2 3 4 5 6 7" "$(printf '%s\n' "$WEX" | grep -E '^[0-9]+\. ' | cut -d. -f1 | paste -sd' ' -)"
nacc=0; bad=0; while IFS= read -r l; do nacc=$((nacc+1)); [ "$(python3 -I "$GL" "$l" | cut -d: -f1)" = OK ] || { bad=$((bad+1)); echo "     not accepted: $l"; }; done < "$FX/lines-accept.txt"
ck t6-every-contract-form-accepted 0 "$bad"; ck t6-accept-fixture-has-12-forms 12 "$nacc"
nrej=0; bad=0; while IFS=$'\t' read -r why l; do nrej=$((nrej+1)); [ "$(python3 -I "$GL" "$l" | cut -d: -f1)" = REJECT ] || { bad=$((bad+1)); echo "     not rejected: $why"; }; done < "$FX/lines-reject.txt"
ck t6-every-bad-form-rejected 0 "$bad"; ck t6-reject-fixture-has-15-forms 15 "$nrej"
# a record with a second gemba line, or with the line among the measures
ck t6-second-gemba-line-detected 2 "$(printf '%s\n' "$WEX" | sed 's/^\(- gemba: .*\)$/\1\n\1/' | grep -c '^- gemba: ')"
HF="$(awk '/^\| `gemba` \|/' "$HA")"
for w in 'one line, always present, exactly once, directly after `stage-log cross-check`' '`not captured (no role stage ran)`' '`transcript` \| `commits and result file`' '`nothing (<d> Done items and <c> constraints checked)`' '`nothing in the part read (<n> chars of <m>)`' '`none: needs a plugin change`' '`reason` is at most 80 characters'; do
  ck "t6-field-row-has-$(printf '%s' "$w" | tr -c 'a-z\n' '-' | cut -c1-30)" 1 "$(printf '%s\n' "$HF" | grep -cF -- "$w")"
done
has t6-why-v5-not-a-field-in-v4 "$HA" 'which is why it is a new version and not a field inside v4'
has t6-v5-sentence-versions "$HA" 'v5 (release 1.3.0) adds a header line `gemba` after `stage-log cross-check` (section 6); no measure changes, so v3, v4 and v5 measures may be compared.'
has t6-line-holds-no-transcript-text "$HA" 'holds no transcript text'

# ---------- T7 (AC-5): a walk that cannot be done reads not captured ----------
NC="$(sub6 'Not captured')"; printf '%s\n' "$NC" > "$T/nc.md"
has t7-case-a-from-commits "$T/nc.md" 'the walk is done from them: `read commits and result file …`'
has t7-case-b "$T/nc.md" '`row <#> <stage> (<role>); not captured (transcript and commits unreadable)`'
has t7-case-c "$T/nc.md" '`not captured (no role stage ran)`'
has t7-case-d "$T/nc.md" '`row …; not captured (no transcript and no commits for agent <id>)`'
has t7-brief-not-found "$T/nc.md" '`row …; not captured (brief not found)`'
has t7-none-reads-nothing-or-zero "$T/nc.md" 'None reads `nothing`, none reads a count of 0 in place of a missing walk, none is blank or dropped.'
has t7-some-agents-fallback-whole-row "$T/nc.md" 'uses the fallback for the whole row'
has t7-partial-never-plain-nothing "$T/cmp.md" '`nothing in the part read (<n> chars of <m>)`, never plain `nothing`'
for l in "- gemba: row 4 Build (developer); not captured (transcript and commits unreadable)" "- gemba: row 8 Documentation (docs-writer); not captured (no transcript and no commits for agent ag07)" "- gemba: not captured (no role stage ran)" "- gemba: row 3 Contracts (architect); not captured (brief not found)" "- gemba: row 4 Build (developer); read commits and result file 4000 chars; found nothing (3 Done items and 2 constraints checked); changes nothing"; do
  ck "t7-accepted-$(printf '%s' "$l" | cut -c10-50 | tr -c 'a-zA-Z0-9\n' '-')" OK "$(python3 -I "$GL" "$l" | cut -d: -f1)"
done
# (c) no role row: the sample rule gives no row, and the only line is the one the text names
ck t7-c-no-role-row-picks-none "none -" "$(pickA "$FX/logs/v7-no-role-row.md" 14)"
ck t7-c-readerB "none -" "$(pickB "$FX/logs/v7-no-role-row.md" 14)"
# (a) the transcript is gone, the commits and the result file are readable: build the fixture repo and run the text's commands
R="$T/repo"; git init -q -b main "$R"; echo base > "$R/base.txt"; git -C "$R" add -A; GIT_COMMITTER_DATE='2026-01-01T09:00:00Z' GIT_AUTHOR_DATE='2026-01-01T09:00:00Z' git -C "$R" commit -q -m 'base'
git -C "$R" checkout -q -b item/60; mkdir -p "$R/plugins/x" "$R/tests" "$R/work/60"
cm() { d="$1"; shift; GIT_COMMITTER_DATE="$d" GIT_AUTHOR_DATE="$d" git -C "$R" commit -q -m "$1"; }
echo lead > "$R/work/60/00.md"; git -C "$R" add -A; cm '2026-01-01T10:00:00Z' '#60 lead: start'
echo A > "$R/plugins/x/a.md"; git -C "$R" add -A; cm '2026-01-01T10:10:00Z' '#60 developer: first'
echo T > "$R/tests/t.sh"; git -C "$R" add -A; cm '2026-01-01T10:20:00Z' '#60 qa-engineer: tests'
echo O > "$R/plugins/x/other.md"; git -C "$R" add -A; cm '2026-01-01T10:12:00Z' '#61 developer: another item'
echo B > "$R/plugins/x/b.md"; git -C "$R" add -A; cm '2026-01-01T10:30:00Z' '#60 developer: second'
cp "$T/result.md" "$R/work/60/06-result-developer.md"
logcmd="$(printf '%s\n' "$CMDS" | grep -F -- "git -C <worktree> log --no-merges --format='%H %s' item/<id>" | head -1)"
ck t7-a-text-names-the-git-log-command 1 "$([ -n "$(printf '%s\n' "$CMDS" | grep -F -- "git -C <worktree> log --no-merges --format='%H %s' item/<id>")" ] && echo 1 || echo 0)"
ck t7-a-text-names-the-git-show-command 1 "$([ -n "$(printf '%s\n' "$CMDS" | grep -F -- "git -C <worktree> show --unified=0 --format='commit %h %s' <sha>")" ] && echo 1 || echo 0)"
shas="$(git -C "$R" log --no-merges --format='%H %s' item/60 | grep -F ' #60 developer: ' | cut -d' ' -f1 | tail -r 2>/dev/null || true)"
shas="$(git -C "$R" log --no-merges --format='%H %s' item/60 | grep -F ' #60 developer: ' | cut -d' ' -f1)"
view_c() { for s in $shas; do git -C "$R" show --unified=0 --format='commit %h %s' "$s" | grep -E '^(commit |diff --git |\+|-)'; done; sed "s#\"work/<id>/<result file>\"#\"$R/work/60/06-result-developer.md\"#" "$T/awk.sh" | sed "s#$T/result.md#$R/work/60/06-result-developer.md#" | bash; }
view_c | head -c 29000 > "$T/commits.view"
ck t7-a-fallback-has-the-role-commits 2 "$(grep -c '^commit ' "$T/commits.view")"
ck t7-a-fallback-lists-the-changed-files 1 "$(grep -c '^diff --git a/plugins/x/a.md' "$T/commits.view")"
ck t7-a-fallback-has-the-changed-lines 1 "$(grep -c '^+A$' "$T/commits.view")"
ck t7-a-fallback-excludes-another-role 0 "$(grep -c 'qa-engineer\|t\.sh' "$T/commits.view")"
ck t7-a-fallback-excludes-another-item 0 "$(grep -c '#61\|other\.md' "$T/commits.view")"
ck t7-a-fallback-excludes-the-summary 0 "$(grep -ci 'Everything in the brief\|summary' "$T/commits.view")"
nfb="$(wc -c < "$T/commits.view" | tr -d ' ')"
ck t7-a-fallback-line-in-grammar OK "$(python3 -I "$GL" "- gemba: row 2 Build (developer); read commits and result file $nfb chars; found nothing (3 Done items and 2 constraints checked); changes nothing" | cut -d: -f1)"
# the commit window needs the committer time; the format the text prints has none
if [ "$(printf '%s\n' "$CMDS" | grep -F -- "git -C <worktree> log" | grep -cE '%(ct|cI|cd|cs|ci)')" -ge 1 ]; then ck t7-a-window-time-in-the-log-format 1 1; else skip t7-a-window-time-in-the-log-format "QA-60 F3: the text filters the commits by the row's window (committer time) but the printed format '%H %s' holds no time"; fi

# ---------- T7 continued: an unreadable transcript, seen through the walk's own commands ----------
printf 'not json at all\n' > "$T/bad.jsonl"
walk "$T/brief3.md" 29000 "$T/gone.jsonl"; gone_out="$(cat "$T/w.out")"; gone_err="$(cat "$T/w.err")"
ck t7-gone-transcript-view-has-no-call-or-result 0 "$(printf '%s\n' "$gone_out" | grep -cE '^(CALL|RESULT) ')"
ck t7-gone-transcript-jq-error-on-stderr 1 "$(printf '%s\n' "$gone_err" | grep -c 'Could not open file' | sed 's/^[2-9]/1/')"
walk "$T/brief3.md" 29000 "$T/bad.jsonl"
ck t7-non-json-transcript-jq-error-on-stderr 1 "$([ -s "$T/w.err" ] && echo 1 || echo 0)"
# nothing in the text tells the Lead to look at stderr or the exit status, and the commands exit 0 either way (the view hides the failure)
bash "$T/run1.sh" >/dev/null 2>&1; rc=$?
if printf '%s\n' "$sec6" | grep -qiE 'stderr|exit status|exit code|jq: error'; then ck t7-text-says-how-to-detect-an-unreadable-transcript 1 1
else skip t7-text-says-how-to-detect-an-unreadable-transcript "QA-60 F4: a deleted or non-JSON transcript gives exit $rc and a view of the header and an empty FINAL line; only stderr shows it, and section 6 does not say to look"; fi

# ---------- T9 (AC-7): a finding goes to the 5 Whys under the rule already in the standard ----------
has t9-points-to-the-5-whys "$T/sec6.md" 'It reuses the Andon comment, *The 5 Whys*, the refusal and `## Refused drafts`'
has t9-points-not-restates "$T/sec6.md" 'which this section points to and does not restate'
for w in careless sloppy 'too weak' hallucinat 'wrong model' 'did not bother' 'blame the process'; do ck "t9-section-6-does-not-restate-$(printf '%s' "$w" | tr ' ' '-')" 0 "$(grep -ci -- "$w" "$T/sec6.md")"; done
has t9-difference-always-gets-a-5-whys "$T/sec6.md" 'A `difference` always gets a 5 Whys before the record is posted'
has t9-nothing-written-until-accepted "$T/sec6.md" '**Nothing is written to the line until a chain is accepted and its comment posted.**'
has t9-difference-never-changes-nothing "$T/sec6.md" 'A difference never ends as `changes nothing`.'
has t9-refused-draft-stays "$T/sec6.md" 'the refused draft stays under `## Refused drafts`'
ck t9-5-whys-section-exists-in-skill 1 "$(grep -c '^### The 5 Whys$' "$SK")"
ck t9-skill-names-the-section-by-its-title 1 "$(grep -c 'The 5 Whys' "$SK" | sed 's/^[1-9][0-9]*$/1/')"
# the mechanical part of the refusal, applied to the found sentence and to the chain
refuse() {  # refuse <found sentence> <chain file> -> REFUSED:<why> | ACCEPTED
  s="$1"; f="$2"; why=""
  printf '%s' "$s" | grep -qE '^(Done item [0-9]+|Constraint [0-9]+|the path [^ ]+|the row.s (Result|Notes)) .*, process object: (the )?(brief|inputs|standard text|tooling|ownership table|order of stages)$' || why="$why sentence-form"
  printf '%s' "$s" | grep -qiE 'careless|forgot|weak|sloppy|should have|did not bother|hallucinat|wrong model|model is|skipped|ignored|lazy|failed to' && why="$why actor-word"
  [ "$(printf '%s' "$s" | tr -cd ';' | wc -c | tr -d ' ')" = 0 ] || why="$why semicolon"
  [ "${#s}" -le 200 ] || why="$why too-long"
  while IFS= read -r l; do
    case "$l" in [0-9]*". Why "*) printf '%s' "$l" | grep -qE 'evidence: [^ -]' || why="$why no-evidence" ;; esac
  done < "$f"
  # the actor words are looked for on every line of the chain, the closing process-item line included
  grep -qiE 'careless|forgot|weak|sloppy|should have|did not bother|hallucinat|wrong model|model is|skipped' "$f" && why="$why actor-or-model"
  tail -1 "$f" | grep -qE '^process item to change: ' || why="$why no-process-item-last"
  if grep -qE '^countermeasure: .*(Role models|replac(e|ing) the role|swap)' "$f"; then
    [ "$(grep -cE '^examined: the (brief|inputs|role.s standard text|tooling) — adequate — evidence: [^ ]' "$f")" -ge 4 ] || why="$why swap-without-4-examined"; fi
  [ -z "$why" ] && echo ACCEPTED || echo "REFUSED:$why"; }
cat > "$T/ch-a.txt" <<'X'
1. Why was the third Done item missing? — the developer skipped it — evidence: commit 1a2b3c4
process item to change: the developer should have checked
X
cat > "$T/ch-b.txt" <<'X'
1. Why was a three-item brief not followed? — the agent's model is too weak — evidence: transcript 14:02Z
countermeasure: a row in ## Role models
process item to change: swap the model
X
cat > "$T/ch-c.txt" <<'X'
1. Why was Done item 3 untraced? — the brief's third Done item named no output path — evidence: work/14/04-brief-developer.md:9
2. Why did it name none? — the brief template lists no output path per Done item — evidence: plugins/factory/agents/developer.md:15
process item to change: the brief template lists no output path per Done item
X
ck t9-a-refused "REFUSED: sentence-form actor-word actor-or-model" "$(refuse 'the developer skipped the third Done item' "$T/ch-a.txt")"
ck t9-b-refused "REFUSED: sentence-form actor-word actor-or-model swap-without-4-examined" "$(refuse "the agent's model is too weak to follow a three-item brief" "$T/ch-b.txt")"
ck t9-c-accepted ACCEPTED "$(refuse 'Done item 3 named no output path, process object: the brief' "$T/ch-c.txt")"
# controls the word list alone would miss: an actor named with no banned word is refused by the sentence form; a good sentence on a chain that names an actor is refused by the chain
ck t9-control-actor-without-banned-word-refused "REFUSED: sentence-form" "$(refuse 'the developer left Done item 3 untouched, process object: the brief' "$T/ch-c.txt")"
cp "$T/ch-c.txt" "$T/ch-d.txt"; sed -i '' 's/^process item to change: .*/process item to change: the developer should have asked/' "$T/ch-d.txt"
ck t9-control-good-sentence-bad-chain-refused "REFUSED: actor-or-model" "$(refuse 'Done item 3 named no output path, process object: the brief' "$T/ch-d.txt")"
ck t9-control-chain-without-process-item-refused "REFUSED: no-process-item-last" "$(head -2 "$T/ch-c.txt" > "$T/ch-e.txt"; refuse 'Done item 3 named no output path, process object: the brief' "$T/ch-e.txt")"
ck t9-control-semicolon-refused "REFUSED: semicolon" "$(refuse 'Done item 3 has no trace; it is empty, process object: the brief' "$T/ch-c.txt")"
# the line grammar refuses a difference with no process object, so (a) cannot be written even if the Lead skipped the refusal
ck t9-a-line-rejected-by-grammar REJECT "$(python3 -I "$GL" '- gemba: row 4 Build (developer); read transcript 4000 chars; found difference: the developer skipped the third Done item; changes none: needs a plugin change' | cut -d: -f1)"
# honest limit: the grammar checks the form only, so (b) gets through it once it borrows a process-object tail; the word list and the sentence form catch it
ck t9-limit-grammar-alone-accepts-a-borrowed-tail OK "$(python3 -I "$GL" "- gemba: row 4 Build (developer); read transcript 4000 chars; found difference: the agent's model is too weak to follow a three-item brief, process object: tooling; changes none: needs a plugin change" | cut -d: -f1)"
ck t9-b-with-borrowed-tail-refused-by-sentence-form-and-words "REFUSED: sentence-form actor-word" "$(refuse "the agent's model is too weak to follow a three-item brief, process object: tooling" "$T/ch-c.txt")"

# ---------- T10 (AC-7, AC-9): the andon path of a difference ----------
has t10-kind-7-no-paused-agent "$T/sec6.md" 'as an **andon of kind 7 with no paused agent**'
has t10-no-waits-entry "$T/sec6.md" '**no `## Waits` entry**'
has t10-paused-agent-dash "$T/sec6.md" 'None runs. `Paused agent` `-`.'
has t10-no-override "$T/sec6.md" 'Fixed: no override is written, because a commit after the approval would change what was approved.'
has t10-fixed-lines "$T/sec6.md" 'The comment'"'"'s fixed lines: `kind: 7 other`, `raised by: lead`, `paused: no agent paused`, `fence check: not run: no override proposed`'
has t10-row-notes "$T/sec6.md" '`kind 7 other; gemba walk after approval; override none`'
has t10-row-waits-dash "$T/sec6.md" 'is a `lead` row with `Waits` `-`'
has t10-skill-andon-sentence "$SK" 'A kind 7 andon raised by the gemba walk at step 8.3a (`hansei.md`, section 6) takes the rows of that section'"'"'s table: stamp but no `andon` wait, no agent to stop, no override, no resume'
has t10-skill-kind-7-names-the-walk "$SK" 'The gemba walk of `hansei.md`, section 6, raises it when it finds a difference.'
has t10-changes-two-outcomes "$T/sec6.md" 'the outcome is `none: needs a plugin change` and `standard change proposed` is filled'
# replay of measure 1 on W12 plus an andon row after the approval
awk '/^## 4\. Stage-log worked example/{f=1} /^## 5\./{f=0} f && /^\| W[0-9]+ \|/' "$HA" > "$T/w12-waits.txt"
wsum() {  # wsum <kind>: minutes of held waits of that kind (parsed from the Waits table)
  awk -F'|' -v k="$1" '{kind=$3; gsub(/ /,"",kind); held=$7; gsub(/ /,"",held); if(kind==k && held=="yes"){ s=$5; e=$6; gsub(/ /,"",s); gsub(/ /,"",e)
     split(substr(s,12,5),a,":"); split(substr(e,12,5),b,":"); m+=((b[1]*60+b[2])-(a[1]*60+a[2])) } } END{print m+0}' "$2"; }
ck t10-w12-person-51 51 "$(wsum person "$T/w12-waits.txt")"; ck t10-w12-limits-15 15 "$(wsum limits "$T/w12-waits.txt")"; ck t10-w12-stalled-15 15 "$(wsum stalled "$T/w12-waits.txt")"
ck t10-w12-interrupted-18 18 "$(wsum interrupted "$T/w12-waits.txt")"; ck t10-w12-andon-20 20 "$(wsum andon "$T/w12-waits.txt")"
tot=281; held=$((51+15+15+18+20)); ck t10-w12-agent-working-162 162 $((tot - held))
# the walk's andon after the approval (16:21Z): a stage-log row Andon A3 with Waits '-', no Waits entry: the table and every sum are unchanged
cp "$T/w12-waits.txt" "$T/w12-waits-after.txt"
ck t10-after-the-walk-andon-sum-unchanged 20 "$(wsum andon "$T/w12-waits-after.txt")"
# the control that shows why no wait is written: a wait opened after the approval pushes the held total past the item's total
echo '| W9 | andon | lead | 2026-11-04T16:30Z | 2026-11-04T16:40Z | yes | gemba difference |' >> "$T/w12-waits-after.txt"
ck t10-control-a-wait-after-approval-breaks-the-sum 1 "$([ $((tot - 51 - 15 - 15 - 18 - $(wsum andon "$T/w12-waits-after.txt"))) -ne 162 ] && echo 1 || echo 0)"
has t10-hansei-worked-example-sum "$HA" 'Check of line 1: 4h41m = 281m; 51 + 15 + 15 + 18 + 20 = 119m; 281 − 119 = 162m = 2h42m.'

# ---------- T12 (AC-9): the close step is placed once ----------
ck t12-skill-8-3a-after-8-3-before-8-4 "3 3a 4" "$(sed -n '/^## 8\. /,/^## 9\. /p' "$SK" | grep -oE '^(3a|3|4)\. ' | tr -d '. ' | paste -sd' ' - | sed 's/^3 3a 4.*/3 3a 4/')"
has t12-skill-8-3a-after-the-approval "$SK" 'Do the gemba walk of `hansei.md`, section 6 (after the approval of 8.1 and the totals of 8.3, before the template is filled)'
has t12-hansei-5-item-3a-same-place "$HA" '3a. Do the gemba walk (section 6), after the approval and after the token totals, before the template is filled; its result is the `gemba` line.'
ck t12-hansei-5-order-3-3a-4 "3 3a 4" "$(awk '/^## 5\. Close, in order/{f=1;next} /^## 6\./{f=0} f' "$HA" | grep -oE '^(3a|3|4)\. ' | tr -d '. ' | paste -sd' ' - | sed 's/^3 3a 4.*/3 3a 4/')"
has t12-section-6-after-the-approval "$T/sec6.md" 'after the merge approval and the token totals, before the template is filled'
has t12-time-in-no-measure "$T/sec6.md" "The walk's time and cost are in no measure: lead time ended at the approval."
has t12-one-walk-per-item "$T/sec6.md" 'The Lead never starts a second walk of another stage, even when the first found nothing.'
has t12-why-gemba-transfers "$T/sec6.md" "Gemba transfers to an agent factory because an agent's summary is written by the party being checked and the stage log holds clocks and counts, not what was done, so the work shows only in the transcript or the commits; the Lead goes and looks at a sample instead of trusting a report."
ck t12-why-line-once-in-the-plugin 1 "$(grep -rF 'Gemba transfers to an agent factory' "$PLUGIN" | wc -l | tr -d ' ')"
ck t12-the-index-rule-only-in-section-6 0 "$(grep -rlF '<id> mod n' "$PLUGIN" | grep -vc 'references/hansei.md')"
ck t12-the-cap-command-only-in-section-6 0 "$(grep -rl 'head -c 30000' "$PLUGIN" | grep -vc 'references/hansei.md')"
ck t12-the-rule-is-in-section-6-not-elsewhere-in-hansei 0 "$(grep -nF '<id> mod n' "$HA" | cut -d: -f1 | awk -v s="$(grep -n '^## 6\. The gemba walk' "$HA" | cut -d: -f1)" '$1<s' | wc -l | tr -d ' ')"
ck t12-skill-8-3a-has-no-rule-steps 0 "$(grep -E '^3a\. ' "$SK" | grep -cE 'mod n|head -c|eligible|index')"
ck t12-no-second-numbered-walk-in-skill 1 "$(grep -cE '^3a\. ' "$SK")"

# ---------- T13 (AC-10): release and hygiene ----------
ck t13-plugin-json-1.3.0 1.3.0 "$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")"
BASE=""; for b in origin/main main; do git -C "$REPO" rev-parse --verify --quiet "$b^{commit}" >/dev/null 2>&1 && { BASE="$b"; break; }; done
MB=""; [ -n "$BASE" ] && MB="$(git -C "$REPO" merge-base "$BASE" HEAD 2>/dev/null)"
if [ -n "$BASE" ] && [ "$(git -C "$REPO" rev-parse HEAD)" != "$MB" ]; then
  out="$(cd "$REPO" && bash "$CB" "$BASE" 2>&1)"; rc=$?
  ck t13-check-bump-passes 0 "$rc"; ck t13-check-bump-says-minor "pass: minor bump needed, 1.2.0 -> 1.3.0" "$out"
  chg="$(git -C "$REPO" diff --name-only "$MB" HEAD -- plugins/factory | sort | paste -sd' ' -)"
  ck t13-only-the-four-files-change-under-plugins-factory "plugins/factory/.claude-plugin/plugin.json plugins/factory/references/baseline.md plugins/factory/references/hansei.md plugins/factory/skills/run/SKILL.md" "$chg"
  ck t13-no-new-agent-script-or-hook 0 "$(git -C "$REPO" diff --name-only --diff-filter=A "$MB" HEAD -- plugins/factory | grep -c .)"
  ck t13-no-agent-script-hook-changed 0 "$(git -C "$REPO" diff --name-only "$MB" HEAD -- plugins/factory/agents plugins/factory/scripts plugins/factory/hooks | grep -c .)"
  # fingerprints: the standard moves, the tooling does not (plugin 1.2.0 as it is on the merge base)
  mkdir -p "$T/base-export"; git -C "$REPO" archive "$MB" plugins/factory | tar -x -C "$T/base-export"
  fo="$(bash "$FP" "$T/base-export/plugins/factory")"; fn="$(bash "$FP" "$PLUGIN")"
  ck t13-base-release-1.2.0 "release: 1.2.0" "$(line "$fo" 1)"; ck t13-new-release-1.3.0 "release: 1.3.0" "$(line "$fn" 1)"
  differ t13-standard-fingerprint-moved "$(line "$fo" 2)" "$(line "$fn" 2)"
  ck t13-tooling-fingerprint-unchanged "$(line "$fo" 3)" "$(line "$fn" 3)"
  echo "     fingerprints now: $(line "$fn" 2) / $(line "$fn" 3)"
  # no absolute home path, no project data in what the diff adds or changes
  H1='/Us''ers/[A-Za-z0-9_.-]+'; H2='/ho''me/[A-Za-z0-9_.-]+'; H3='[A-Za-z]:[\\/]+Us''ers[\\/]+[A-Za-z0-9_.-]+'
  git -C "$REPO" diff "$MB" HEAD -U0 | grep '^+' | grep -v '^+++' | grep -vE '\$T/|\$\{?T\}?/' > "$T/added.txt"
  ck t13-no-absolute-home-path-in-added-lines 0 "$(grep -cE "(^|[^A-Za-z0-9_.\$/-])($H1|$H2)|$H3" "$T/added.txt")"
  ck t13-added-lines-were-read 1 "$([ "$(wc -l < "$T/added.txt")" -gt 500 ] && echo 1 || echo 0)"
  ck t13-no-link-to-another-project 0 "$(grep -oE 'https?://[A-Za-z0-9./_#-]+' "$T/added.txt" | sed -E 's#(https?://[^/]+/[^/]+/[^/#]+).*#\1#' | sort -u | grep -vE '^https://github.com/WimSuenens/agent-plugins$|^https://github.com/example/|^https://example.invalid/|^https://github.com/anthropics/' | grep -c .)"
  ck t13-no-issue-link-of-another-repository 0 "$(grep -oE 'github.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/(issues|pull)/[0-9]+' "$T/added.txt" | grep -vE 'WimSuenens/agent-plugins|example/shop' | grep -c .)"
else skip t13-diff-against-main "no main ref (or nothing ahead of it) in this checkout"; fi
# the tracked files of the standard and the new fixtures hold no absolute home path at all (git grep over the committed tree)
H1='/Us''ers/[A-Za-z0-9_.-]+'; H2='/ho''me/[A-Za-z0-9_.-]+'
ck t13-git-grep-plugin-and-gemba-fixtures-no-home-path 0 "$(git -C "$REPO" grep -nE "(^|[^A-Za-z0-9_.\$/-])($H1|$H2)" -- plugins tests/factory/fixtures/gemba tests/factory/gemba_pick.py tests/factory/gemba_pick.awk tests/factory/gemba_line.py tests/factory/gemba_transcript.py CONTEXT.md docs/factory 2>/dev/null | grep -c .)"
ck t13-fixtures-carry-no-tracker-text 0 "$(grep -rIlE 'issuecomment-[0-9]{8,}|github.com/WimSuenens' "$FX" | grep -c .)"
# the 1.3.0 changelog entry lists the five unverified items as unverified (the docs-writer's; skipped until the entry exists)
CL="$REPO/CHANGELOG.md"
if [ -f "$CL" ] && grep -qE '^## .*1\.3\.0' "$CL"; then
  ent="$(awk '/^## .*1\.3\.0/{f=1;next} /^## /{f=0} f' "$CL")"
  ck t13-changelog-says-unverified 1 "$(printf '%s\n' "$ent" | grep -ci 'unverified' | sed 's/^[1-9][0-9]*$/1/')"
  for w in 'sample rule' 'cost' 'transcript' 'how often' '5 Whys'; do ck "t13-changelog-unverified-lists-$(printf '%s' "$w" | tr ' ' '-')" 1 "$(printf '%s\n' "$ent" | grep -ci -- "$w" | sed 's/^[1-9][0-9]*$/1/')"; done
else skip t13-changelog-1.3.0-entry "the docs-writer's 1.3.0 entry is not in this checkout yet; reviews/qa-60.md lists what it must say as unverified"; fi

# ---------- T4/T7 continued: the brief of a row is found by ordinal (hansei.md section 6, "Which brief") on a real log shape ----------
# the role's brief files in NN order are the non-dash numbers of that role; row i of the role gets file i (the text's ordinal rule)
ord_map() {  # prints "<row> <brief-or-->" for every role row, by the ordinal rule
  awk -F'\t' '!/^#/ && NF==3 { c[$2]++; rows[NR]=$1; role[NR]=$2; ord[NR]=c[$2]; if ($3 != "-") { k[$2]++; file[$2, k[$2]] = $3 } } END { for (i=1;i<=NR;i++) if (rows[i]!="") print rows[i], ((role[i], ord[i]) in file) ? file[role[i], ord[i]] : "-" }' "$1"
}
want="$(awk -F'\t' '!/^#/ && NF==3 {print $1, $3}' "$FX/l57-briefs.tsv")"; got="$(ord_map "$FX/l57-briefs.tsv")"
if [ "$want" = "$got" ]; then ck t4-ordinal-rule-finds-every-brief-on-L57 1 1
else skip t4-ordinal-rule-finds-every-brief-on-L57 "QA-60 F6: when a role row has no brief file (L57 row 17, brief never written) the ordinal rule shifts the role's later rows: rows $(diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | grep '^>' | cut -c3- | cut -d' ' -f1 | paste -sd, -) get another file or none"; fi
ck t4-ordinal-rule-right-for-every-row-with-a-brief-before-the-gap 1 "$(printf '%s\n' "$got" | awk '$1<17' | diff -q - <(printf '%s\n' "$want" | awk '$1<17') >/dev/null && echo 1 || echo 0)"
done_
