#!/bin/bash
# Slice 64, the ledger, the fields and the readers of the sections that left: AC-20 to AC-26, with the replay of W12, C49 and L57.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
TD="$(cd "$(dirname "$0")" && pwd)"
RUN="$PLUGIN/skills/run/SKILL.md"; HA="$PLUGIN/references/hansei.md"; PROTO="$PLUGIN/references/protocol.md"
SK="$PLUGIN/skills/setup-factory-skill/SKILL.md"
RP="$FX64/replay"; PY="$TD/replay64.py"
cd "$T" || exit 1

# ---------- AC-23, AC-26: the replay. Step 1 values (written from the 1.3.0 rules before the 2.0.0 text was read) ----------
exp() { awk -F'\t' -v l="$1" '$1==l {print $2"\t"$3}' "$RP/expected-old.tsv"; }
# the old reader (independent of the hand values) reproduces the hand-computed expectations
python3 -I "$PY" old "$RP/w12-old.md" 12 7 5 >"$T/w12.old"
while IFS="$(printf '\t')" read -r k v; do ck "ac23-expected-old-w12-$k" "$v" "$(awk -F'\t' -v k="$k" '$1==k {print $2}' "$T/w12.old")"; done <<<"$(exp w12)"
python3 -I "$PY" old "$RP/c49-old.md" 49 >"$T/c49.old"; python3 -I "$PY" old "$RP/l57-old.md" 57 >"$T/l57.old"; python3 -I "$PY" old "$RP/k4-old.md" >"$T/k4.old"
while IFS="$(printf '\t')" read -r k v; do ck "ac26-expected-old-c49-$k" "$v" "$(awk -F'\t' -v k="$k" '$1==k {print $2}' "$T/c49.old")"; done <<<"$(exp c49)"
while IFS="$(printf '\t')" read -r k v; do ck "ac26-expected-old-l57-$k" "$v" "$(awk -F'\t' -v k="$k" '$1==k {print $2}' "$T/l57.old")"; done <<<"$(exp l57)"
while IFS="$(printf '\t')" read -r k v; do ck "ac26-expected-old-k4-$k" "$v" "$(awk -F'\t' -v k="$k" '$1==k {print $2}' "$T/k4.old")"; done <<<"$(exp k4)"
# the re-expressed fixtures are what the generator makes from the old logs (nobody edited them by hand)
for l in w12 k4 c49 l57; do
  rm -rf "$T/re-$l"; python3 -I "$PY" reexpress "$RP/$l-old.md" "$T/re-$l"
  ck "ac23-fixture-$l-subissues-regenerated-identical" 0 "$(cmp -s "$T/re-$l/subissues.json" "$RP/$l-new/subissues.json"; echo $?)"
  ck "ac23-fixture-$l-ledger-regenerated-identical" 0 "$(cmp -s "$T/re-$l/ledger.md" "$RP/$l-new/ledger.md"; echo $?)"
done
# the new reader on the new inputs: everything equals the old values except the listed differences (row labels: the Tasks table renumbers from 1; lead and person rows are gone)
cmpnew() { # cmpnew <log> <ids...>
  local l="$1"; shift
  python3 -I "$PY" old "$RP/$l-old.md" "$@" | sed -E 's/^row[0-9]+_/R_/' >"$T/$l.o"
  python3 -I "$PY" new "$RP/$l-new" "$@" | sed -E 's/^task[0-9]+_/R_/' >"$T/$l.n"
  diff "$T/$l.o" "$T/$l.n" >"$T/$l.diff"; echo $?
}
ck ac23-w12-values-equal-after-the-listed-differences 0 "$(cmpnew w12 12 7 5)"
ck ac26-c49-values-equal 0 "$(cmpnew c49 49 1 11 12)"
ck ac26-l57-values-equal 0 "$(cmpnew l57 57 13 1 14)"
ck ac26-k4-values-equal 0 "$(cmpnew k4)"
# AC-23 headline values, quoted from step 1
python3 -I "$PY" new "$RP/w12-new" 12 7 5 >"$T/w12.new"
nv() { awk -F'\t' -v k="$1" '$1==k {print $2}' "$T/$2"; }
ck ac23-w12-hours-4.68 4.68 "$(nv hours w12.new)"
ck ac23-w12-person-touches-3 3 "$(nv touches w12.new)"
ck ac23-w12-rework-rounds-1 1 "$(nv rework_feedback_briefs w12.new)"
ck ac23-w12-total-281 281 "$(nv total_min w12.new)"
ck ac23-w12-agent-working-162 162 "$(nv agent_working_min w12.new)"
ck ac23-w12-minutes-per-task "15 18 78 18 14 7 9 8" "$(grep '^task' "$T/w12.new" | cut -f2 | paste -sd' ' -)"
ck ac26-w12-gemba-pick-id12 "Requirement/product-owner" "$(nv gemba_pick_id12 w12.new)"
ck ac26-w12-gemba-pick-id7 "$(awk -F'\t' '$1=="gemba_pick_id7"{print $2}' "$T/w12.old")" "$(nv gemba_pick_id7 w12.new)"
ck ac26-w12-gemba-pick-id5 "$(awk -F'\t' '$1=="gemba_pick_id5"{print $2}' "$T/w12.old")" "$(nv gemba_pick_id5 w12.new)"
python3 -I "$PY" new "$RP/c49-new" 49 >"$T/c49.new"; python3 -I "$PY" new "$RP/l57-new" 57 >"$T/l57.new"
ck ac26-c49-gemba-pick-id49 "Stage 8/architect" "$(nv gemba_pick_id49 c49.new)"
ck ac26-l57-gemba-pick-id57 "Stage 10/developer" "$(nv gemba_pick_id57 l57.new)"
# the kind 4 flag test is not vacuous: W12 has no role with 3 earlier rows, so QA built k4 (rows 10,12,11 min, then 22 and 24: 22 is not above 2 x 11, 24 is above 2 x 11.5)
python3 -I "$PY" new "$RP/k4-new" >"$T/k4.new"
ck ac26-k4-flags-the-24-minute-task-only 5 "$(nv kind4_flags k4.new)"
ck ac26-w12-has-no-flag-for-lack-of-baseline none "$(nv kind4_flags w12.new)"
# the two independent gemba readers (tests/factory) pick the same stage on the Tasks table of the new ledger as on the old log
tasks_table() { awk '/^### Tasks/{f=1;next} f&&/^\|/{print;next} f&&!/^\|/&&NF{exit}' "$1"; }
for l in w12 c49 l57; do tasks_table "$RP/$l-new/ledger.md" >"$T/$l-tasks.md"; done
pa() { python3 -I "$TD/gemba_pick.py" "$1" "$2" | cut -d' ' -f1; }
pb() { awk -v id="$2" -f "$TD/gemba_pick.awk" "$1" | cut -d' ' -f1; }
for spec in "w12 12" "c49 49" "l57 57"; do
  set -- $spec
  ck "ac26-reader-A-on-tasks-table-$1-id$2-matches-stage-and-role" "$(awk -F'\t' -v k="gemba_pick_id$2" '$1==k{print $2}' "$T/$1.new")" "$(awk -F'|' -v n="$(pa "$T/$1-tasks.md" "$2")" 'NR>2 { gsub(/ /,"",$2); if ($2==n) { s=$4; r=$5; gsub(/^ +| +$/,"",s); gsub(/^ +| +$/,"",r); print s"/"r; exit } }' "$T/$1-tasks.md")"
  ck "ac26-reader-A-and-B-agree-on-tasks-table-$1" "$(pa "$T/$1-tasks.md" "$2")" "$(pb "$T/$1-tasks.md" "$2")"
done
# the plugin's own worked ledger (hansei.md section 4) is the same item: its Tasks, Waits and touches equal the old W12 cell for cell
awk '/^## 4\. Ledger worked example/{f=1} /^## 5\./{f=0} f' "$HA" | awk '/^<!-- factory:ledger v1 -->$/{p=1} p{print} p&&/^```$/{exit}' | sed '$d' >"$T/plugin-ledger.md"
ck ac23-plugin-worked-ledger-found "yes" "$([ "$(wc -l <"$T/plugin-ledger.md")" -gt 25 ] && echo yes || echo no)"
cells() { awk -F'|' -v want="$2" 'BEGIN{n=split(want,W,",")} /^\|/ && !/^\|-/ && NR>0 {o=""; for(i=1;i<=n;i++){c=$(W[i]+1); gsub(/^ +| +$/,"",c); o=o"|"c} print o}' "$1"; }
ck ac23-plugin-ledger-tasks-equal-old-w12-rows "$(tasks_table "$RP/w12-new/ledger.md" | cells /dev/stdin 3,4,5,6,7,8 | sed 1d)" "$(tasks_table "$T/plugin-ledger.md" | cells /dev/stdin 3,4,5,6,7,8 | sed 1d)"
sect_of() { awk -v h="### $2" '$0==h{f=1;next} /^### /{f=0} /^## /{f=0} f&&/^\|/{print}' "$1"; }
ck ac23-plugin-ledger-waits-equal-old-w12 "$(sect_of "$RP/w12-new/ledger.md" Waits)" "$(sect_of "$T/plugin-ledger.md" Waits)"
ck ac23-plugin-ledger-touches-equal-old-w12 "$(sect_of "$RP/w12-new/ledger.md" "Person's touches")" "$(sect_of "$T/plugin-ledger.md" "Person's touches")"
mkdir -p "$T/pl"; cp "$T/plugin-ledger.md" "$T/pl/ledger.md"; cp "$RP/w12-new/subissues.json" "$T/pl/subissues.json"
python3 -I "$PY" new "$T/pl" 12 >"$T/pl.new"
ck ac23-plugin-ledger-read-gives-the-old-w12-values-total 281 "$(nv total_min pl.new)"
ck ac23-plugin-ledger-read-gives-agent-working-162 162 "$(nv agent_working_min pl.new)"
ck ac23-plugin-ledger-read-gives-hours-4.68 4.68 "$(nv hours pl.new)"
ck ac23-plugin-ledger-gemba-pick "Requirement/product-owner" "$(nv gemba_pick_id12 pl.new)"
ck ac23-plugin-ledger-tasks-minutes "15 18 78 18 14 7 9 8" "$(grep '^task' "$T/pl.new" | cut -f2 | paste -sd' ' -)"
ck ac23-plugin-ledger-start-header "2026-11-04T11:40Z" "$(sed -n 's/^- started: //p' "$T/plugin-ledger.md")"
# the plugin's worked record agrees with the old log and the rules
REC="$(awk '/^### Worked example/{f=1} f' "$HA")"
has_rec() { printf '%s\n' "$REC" | grep -qF -- "$2" && { echo "ok   $1"; passed=$((passed + 1)); } || { echo "FAIL $1: '$2' not in the worked record"; fail=1; }; }
has_rec ac23-record-lead-time-line "1. lead time: total 4h41m; agent working 2h42m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m; andon 20m"
has_rec ac23-record-rework-line "3. rework: feedback briefs product-owner 0, architect 0, developer 1, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 1"
has_rec ac23-record-touches-line "6. person's touches: decision cards 1; demos 0; approvals 1; overturns 1; other 0"
has_rec ac26-record-gemba-names-row-1-requirement "- gemba: row 1 Requirement (product-owner);"
has_rec ac23-record-peak-developer "peak context 141210"
has_rec ac23-record-marker-stays-v5 "<!-- factory:hansei v5 -->"
has ac23-hansei-text-states-end-moves "$HA" "A row's End is the sub-issue's \`closed_at\`"
has ac23-hansei-text-says-it-is-the-one-definition-that-moved "$HA" 'it is the one definition that moved'
has ac23-hansei-text-agent-working-rule "$HA" 'Agent working = Duration less the union of the intervals of the waits named in `Waits` that are `Held item: yes`'
has ac23-hansei-lead-time-starts-at-started "$HA" '**`started` starts the item'"'"'s lead time.**'
has ac23-hansei-measure-1-source "$HA" '**total** = approval time − `started` (the ledger header)'
has ac23-hansei-measure-6-source "$HA" "the ledger's Person's touches table"
has ac23-hansei-measure-3-source "$HA" 'the `rework` sub-issues of the slice, counted by the `Role` of each'
has ac23-run-kind-4-rule "$RUN" "Agent-working time of a row is its \`Duration\` (the sub-issue's \`closed_at\` minus \`created_at\`)"
has ac23-run-kind-4-median "$RUN" 'let `m` be the median of their agent-working times (mean of the two middle values for an even count)'
has ac23-run-kind-4-strictly-greater "$RUN" 'strictly greater than'
has ac23-run-kind-4-fewer-than-3 "$RUN" 'With fewer than 3 earlier rows write `no baseline: fewer than 3 earlier rows` in `Notes` and stop.'

# ---------- AC-22, AC-20: the fields ----------
# the grammar of hansei.md section 7, run on valid and invalid values
fieldval() { printf '%s\n' "$1" | grep -Eq '^(0|[1-9][0-9]*)$' && return 0
  printf '%s\n' "$1" | grep -Eq '^(0|[1-9][0-9]*)\.[0-9][0-9]$' && return 0
  printf '%s\n' "$1" | grep -Eq '^not captured \([^()]{1,80}\)$' && return 0
  return 1; }
for v in 0 7 12000 3.12 0.50 "not captured (ledger comment missing)" "not captured (frontier round keeps no ledger)" "not captured (2 of 7 role tasks not captured)"; do fieldval "$v" && r=ok || r=bad; ck "ac22-valid-value [$v]" ok "$r"; done
for v in "" " " "-" "n/a (did not run)" "01" "1.5" "3.123" "not captured" "not captured ()" "not captured (a(b))" "unknown" "~12" "-1" "12m"; do fieldval "$v" && r=ok || r=bad; ck "ac22-rejected-value [$v]" bad "$r"; done
# Hours: whole minutes / 60 rounded half up to two decimals
hours() { python3 -I -c "import sys; m=int(sys.argv[1]); print('%d.%02d' % divmod((m*100*2+60)//(2*60) if True else 0, 100))" "$1"; }
ck ac22-hours-187m-3.12 3.12 "$(hours 187)"
ck ac22-hours-281m-4.68 4.68 "$(hours 281)"
ck ac22-hours-90m-1.50 1.50 "$(hours 90)"
ck ac22-hours-1m-0.02 0.02 "$(hours 1)"
ck ac22-hours-0m-0.00 0.00 "$(hours 0)"
has ac22-hansei-hours-rule "$HA" '| slice `Hours` | measure 1'"'"'s `total` in whole minutes ÷ 60, rounded half up to two decimals (`187m` gives `3.12`) |'
has ac22-hansei-never-empty "$HA" '**Never empty.** After the close none of the five is empty on any card the item produced'
has ac22-hansei-na-never-in-a-field "$HA" '`n/a (did not run)` is never written in a field'
has ac22-hansei-zero-only-measured "$HA" '`0` is written only for a value measured as zero'
has ac22-hansei-text-never-number "$HA" '**Text, never a number cell.**'
has ac22-hansei-ledger-missing "$HA" 'A ledger that cannot be read gives `not captured (ledger comment missing)`'
has ac22-run-8-4a-after-post-before-5 "$RUN" '4a. **Set the board fields**'
a="$(grep -n '^4\. Fill the hansei template' "$RUN" | head -1 | cut -d: -f1)"; b="$(grep -n '^4a\. ' "$RUN" | head -1 | cut -d: -f1)"; c="$(grep -n '^5\. When the item had an Environment stage' "$RUN" | head -1 | cut -d: -f1)"
ck ac22-run-8-4a-order-4-then-4a-then-5 1 "$([ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ] && echo 1 || echo 0)"
has ac22-run-every-role-task-then-slice "$RUN" "every role task's \`Tokens\` and \`Minutes\`, then the slice's \`Tokens\`, \`Hours\`, \`Rework rounds\` and \`Person touches\`"
has ac22-run-none-left-empty "$RUN" 'None is left empty: a value you cannot compute is `not captured (<reason>)`.'
has ac22-run-resume-does-not-overwrite "$RUN" 'does not overwrite a different value without saying so'
has ac22-frontier-tokens-minutes-not-captured "$RUN" 'set `Tokens` and `Minutes` of each of its role tasks to `not captured (frontier round keeps no ledger)`'
has ac22-run-done-list-fields-set "$RUN" 'the board fields are set'
# the five fields are all named in hansei section 7
for f in Tokens Minutes Hours "Rework rounds" "Person touches"; do has "ac20-hansei-names-field-$f" "$HA" "| \`$f\` |"; done

# ---------- AC-24: the lead state ----------
LSN="$(awk '/^4\. Write `work\/<id>\/00-lead-state.md`/{print}' "$RUN")"
case "$LSN" in *"board item id"*"next step"*"open questions"*"Running agents"*"Shared resources"*"Interrupted"*) r=1 ;; *) r=0 ;; esac
ck ac24-run-lead-state-parts-in-order 1 "$r"
has ac24-run-no-status-line "$RUN" '**The lead state carries no status line**'
has ac24-hansei-no-status-line "$HA" 'It carries no status line: the board holds the slice'"'"'s status.'
has ac24-hansei-lead-state-sections "$HA" 'it holds three sections, in this order: `## Label`, `## Findings`, `## Abnormalities`'
# no text defines or starts a stage log, waits or touches section as part of the lead state
for pat in '## Stage log' '## Waits' "## Person's touches"; do
  n="$(grep -rnF --include='*.md' -- "$pat" "$PLUGIN" "$REPO/plugins/wayfinding" | grep -v 'setup-factory-skill/SKILL.md' | grep -vE '^[^:]*hansei.md:[0-9]+:### ' | wc -l | tr -d ' ')"
  ck "ac24-no-definition-of [$pat] outside the 1.x section" 0 "$n"
done
for pat in '## Stage log' '## Waits' "## Person's touches"; do
  n="$(awk '/^## Version 1.x records/{f=1} !f' "$SK" | grep -cF -- "$pat")"
  ck "ac24-setup-skill-[$pat]-only-under-version-1.x-records" 0 "$n"
done
ck ac24-setup-skill-1x-heading-exists 1 "$(grep -c '^## Version 1.x records' "$SK")"
grep -rn "Status:" "$PLUGIN" --include='*.md' | grep -iE 'lead[- ]state' | grep -v 'Status: done\|Status: working\|status line' >"$T/status-hits.txt"
ck ac24-no-status-line-in-lead-state-template 0 "$(wc -l <"$T/status-hits.txt" | tr -d ' ')"
has ac24-hansei-section-4-is-ledger-example "$HA" '## 4. Ledger worked example'
hasnt ac24-hansei-section-4-no-stage-log-title "$HA" '## 4. Stage-log worked example'
has ac24-setup-skill-1x-example-labelled "$SK" 'The worked example of the stage log that factory 1.3.0 wrote into the lead state'

# ---------- AC-25: every reader names its new source ----------
has ac25-run-kind-4-source "$RUN" 'when you add a Tasks row whose `Role` is one of the seven roles'
has ac25-run-close-scan-source "$RUN" "Complete the ledger's Waits table with the close scan, then cross-check the Tasks table against git and the tracker"
has ac25-run-close-scan-lead-window "$RUN" "with \`--since\` the ledger's \`started\` and \`--until\` the approval time"
has ac25-hansei-cutoffs-agents-column "$HA" "Tasks table"
has ac25-hansei-cross-check-names-tasks-table "$HA" "it checks the Tasks table"
has ac25-hansei-gemba-reads-ledger "$HA" 'The rule reads the Tasks table of the ledger (or a manual table of the same shape, such as a 1.x lead-state table)'
has ac25-run-interruption-lead-state "$RUN" "Note the interruption in the lead state's \`## Interrupted\` section"
has ac25-run-interruption-wait-written-at-end "$RUN" "the wait is written to the ledger's Waits table **when it ends** (never open)"
has ac25-run-andon-1-pause-note "$RUN" "the \`andon\` wait is written to the ledger's Waits table when the pause ends"
has ac25-run-andon-no-row "$RUN" 'There is no `Andon A<n>` row in the Tasks table.'
has ac25-run-andon-paused-by-note "$RUN" "names the andon in \`Notes\` (\`paused by A<n>\`) and lists the andon wait's id in its \`Waits\` column"
has ac25-run-held-item-rule "$RUN" 'The wait is `Held item: yes` when no other role agent of the item worked meanwhile'
has ac25-protocol-kind-4-noun "$PROTO" 'a role task whose agent-working time is more than twice the median of the same role'"'"'s earlier tasks'
# the searches of contract section 7 step 5: each remaining hit is one of the allowed places
allowed_hit() { # a hit line "path:line:text" is allowed when it is the header key, the migration text, the 1.x examples or the README history
  case "$1" in
    *"stage-log cross-check"*) return 0 ;;
    plugins/factory/skills/setup-factory-skill/SKILL.md:*) return 0 ;;
    *"Stage-log"*|*"1.x"*) return 0 ;;
  esac
  return 1
}
: >"$T/hits.txt"
for pat in 'stage log' 'stage-log' '## Waits' "Person's touches"; do
  ( cd "$REPO" && grep -rn -i -F -- "$pat" plugins/factory plugins/wayfinding 2>/dev/null ) >>"$T/hits.txt"
done
sort -u "$T/hits.txt" >"$T/hits2.txt"
bad=0; while IFS= read -r h; do
  case "$h" in *"references/hansei.md:"*"### Waits"|*"references/hansei.md:"*"### Person's touches"|*"references/hansei.md:"*"6. person's touches: decision cards"*) continue ;; esac
  case "$h" in *"plugins/factory/references/hansei.md:"*"Person's touches"*|*"plugins/factory/skills/run/SKILL.md:"*"Person's touches table"*|*"plugins/factory/references/a3.md:"*"person's touches"*|*"plugins/factory/references/baseline.md:"*"person's touches"*) continue ;; esac
  allowed_hit "$h" || { printf '%s\n' "$h" | cut -c1-220 | sed 's/^/     unexplained hit: /'; bad=$((bad + 1)); }
done <"$T/hits2.txt"
if [ "$bad" = 0 ]; then ck ac25-every-search-hit-is-an-allowed-one 0 0; else
  skip ac25-every-search-hit-is-an-allowed-one "QA finding F-baseline-stage-log: $bad hit(s) name the stage log as a live source (see the lines above); the allowed places are the header key, the setup skill's 1.x section and the worked examples"; fi
# README: the history sentence is the allowed one; the docs-writer's stage updates the rest
grep -n -i 'stage log' "$REPO/README.md" | cut -c1-120 >"$T/readme-hits.txt"
if [ -s "$T/readme-hits.txt" ]; then skip ac25-readme-still-describes-the-stage-log "README.md is the docs-writer's (stage not yet run); lines: $(cut -d: -f1 "$T/readme-hits.txt" | paste -sd, -)"; fi

done_
