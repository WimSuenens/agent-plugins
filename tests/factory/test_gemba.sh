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
done_
