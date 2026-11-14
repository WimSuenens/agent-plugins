#!/bin/bash
# The new standard's text: AC-1, AC-6, AC-8, AC-11, AC-13, AC-14, AC-15, AC-16, AC-18, AC-19, AC-20,
# and contract 39-standard-changes. Checks what the Lead is told, not how it behaves in a session
# (that is the acceptance demo's human-only list in reviews/qa-39.md).
. "$(dirname "$0")/lib.sh"
SK="$(run_all_file)"
HA="$PLUGIN/references/hansei.md"
TP="$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md"
MK="$REPO/.claude-plugin/marketplace.json"
# first line number of a fixed string in a file (0 when absent)
ln_of() { n="$(grep -nF -- "$2" "$1" | head -1 | cut -d: -f1)"; echo "${n:-0}"; }
before() { # name file a b: a appears, b appears, a before b
  la="$(ln_of "$2" "$3")"; lb="$(ln_of "$2" "$4")"
  if [ "$la" -gt 0 ] && [ "$lb" -gt 0 ] && [ "$la" -lt "$lb" ]; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$3' (line $la) not before '$4' (line $lb)"; fail=1; fi
}
# the fenced block that follows a heading line, without the fences
block_after() { awk -v h="$2" 'f==0 && $0==h {f=1; next} f==1 && /^```/ {f=2; next} f==2 && /^```/ {exit} f==2 {print}' "$1"; }

# --- AC-1
PV="$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")"
ck ac1-plugin-version-semver 1 "$(printf "%s" "$PV" | grep -Ec "^[0-9]+\.[0-9]+\.[0-9]+$")"
ck ac1-version-own-line 1 "$(grep -c "^  \"version\": \"$PV\",\$" "$PLUGIN/.claude-plugin/plugin.json")"
ck ac1-marketplace-factory-no-version "null" "$(jq -r '.plugins[] | select(.name=="factory") | .version' "$MK")"

# --- contract 39-standard-changes section 3: plugin root and the pre-1.0.0 tracker fallback
has plugin-root-line "$SK" 'Plugin root: ${CLAUDE_PLUGIN_ROOT}'
has fallback-older-tracker-doc "$SK" 'has no *Post hansei* bullet'
has fallback-points-at-patch "$SK" '${CLAUDE_PLUGIN_ROOT}/skills/setup-factory-skill/references/issue-tracker-github.factory.md'
has fallback-never-edit "$SK" "Never edit the project's tracker doc yourself."
has step5-runs-fingerprint "$SK" 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh" "${CLAUDE_PLUGIN_ROOT}"'
has skill-links-hansei "$SK" '(${CLAUDE_PLUGIN_ROOT}/references/hansei.md)'

# --- AC-6
TEMPLATE="$(block_after "$HA" '### Layout')"
ck ac6-context-line 1 "$(printf '%s\n' "$TEMPLATE" | grep -c '^- context: wayfinding <version>; mattpocock-skills <version>$')"
has ac6-context-only "$HA" 'context only, never a reset trigger'
has ac6-unreadable-not-captured "$HA" 'Otherwise `not captured (<reason>)`'
has ac6-label-wayfinding "$HA" '- wayfinding: <version> (<source>)'

# --- AC-8: the Open PR check
has ac8-fetch-then-check "$SK" '1. `git fetch origin main`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/release-hook.sh" check <item worktree> <id> origin/main`.'
has ac8-before-pr-create "$SK" 'Before `gh pr create`, always:'
has ac8-exit1-no-pr "$SK" 'Exit 1: do not open the PR.'
has ac8-exit1-feedback-source-lead "$SK" 'Create a rework task for the developer (`Source: lead`) quoting the refusal'
has ac8-exit1-logged-refused "$SK" 'and run *Open PR* again when it is done'
has ac8-exit2-no-pr "$SK" 'Exit 2: do not open the PR'
has ac8-refusal-in-stage-log-format "$HA" 'A refused *Open PR* (the release hook, when the project declares one) is told in the session and handled as a `Source: lead` rework task'
# every instruction that opens a PR must run the check first. PR-opening lines, outside the check's own paragraph:
pr_lines="$(grep -nE 'gh pr create|[Oo]pen (one |the )?PR' "$SK" | grep -vE 'release-hook|do not open the PR|opens a PR without this step|Open the PR \(\*Open PR\*\)|Exit 0: open the PR|run \*Open PR\* again|merged on its own PR|has its own branch and one PR|once over the whole branch before \*Open PR\* and at the merge approval')"
if [ -z "$pr_lines" ]; then ck ac8-no-pr-without-check "" ""
else skip ac8-no-pr-without-check "QA-39 F1: PR opened without the bump check at SKILL.md:$(printf '%s' "$pr_lines" | cut -d: -f1 | tr '\n' ' ')(frontier round end) (developer)"; fi
# the tracker patch's Open PR bullet is the command the check guards
has ac8-tracker-open-pr "$TP" '- **Open PR**: `gh pr create --head item/<id>'

# --- AC-11: stage log
has ac11-in-lead-state "$HA" '`work/<id>/00-lead-state.md`'
has ac11-date-u "$HA" 'Times are always taken from `date -u +%FT%TZ` at the moment, never estimated afterwards'
has ac11-columns "$HA" '| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |'
has ac11-feedback-rounds "$HA" 'A rework task appends ` (round <n>)` (`Build (round 2)`).'
has ac11-acceptance-demo-stage "$HA" '`Requirement`, `Contracts and ADRs`, `Tests`, `Environment`, `Build`, `QA`, `Security`, `Delivery`, `Documentation`'
# v2: the Waits table names the agent each wait stopped, and four wait kinds each have a detection row
has ac11-waits-kinds "$HA" '| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |'
has ac11-waits-agent-column "$HA" '`Agent`: the agent id the wait stopped, `lead` when it stopped the Lead itself, `-` for a `person` wait.'
KT="$(awk '/^\| Kind \| What it is \| Detected by \| Start \| End \|$/ {f=1; next} f && /^\|---/ {next} f && /^\| `/ {print} f && !/^\|/ {exit}' "$HA")"
ck ac11-five-wait-kinds-in-order '`person`|`limits`|`stalled`|`interrupted`|`andon`' "$(printf '%s\n' "$KT" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | paste -sd'|' -)"
ck ac11-every-kind-has-detection-start-end 5 "$(printf '%s\n' "$KT" | awk -F'|' 'NF>=7 && length($4)>10 && length($5)>5 && length($6)>5 {n++} END {print n+0}')"
has ac11-limits-wait "$HA" 'a role'"'"'s failure notice `failed … You'"'"'ve hit your … limit`'
has ac11-stalled-watchdog "$HA" 'the stream watchdog, `no progress for 600s`'
has ac11-interrupted-sleep "$HA" 'a `stalled` gap in which the machine was asleep at any moment is `interrupted`'
has ac11-sleep-log-through-script "$HA" '`cut-offs.sh --sleep-log -` applies this when you pipe in the sleep log, and only then'
has ac11-stall-start-from-transcript "$HA" 'the line'"'"'s start: the `timestamp` of the last entry before the gap that is not itself a cut-off marker'
has ac11-stall-start-never-tail "$HA" 'Never `tail -n 1`: the stream watchdog writes its `[Request interrupted by user]` entry at the notice'
has ac11-start-unreadable-marked "$HA" 'When the transcript cannot be read (exit 3 or 4), the start is your `date -u` stamp at the notice, marked `~`'
has ac11-lead-wait-stops-role "$HA" '**The Lead'"'"'s own wait stops a role'"'"'s.** While you are in a wait yourself, no role wait accrues'
has ac11-skill-start-via-cut-offs "$SK" 'the start is the last line'"'"'s start from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/cut-offs.sh" [--sleep-log -] -- <transcript>` on the stopped agent'"'"'s transcript, never the file'"'"'s last entry'
has ac11-one-wait-one-kind "$HA" 'A stretch that changes cause midway (a stall, then a limit hit on the resume) is two entries, back to back.'
has ac11-touches "$HA" '| Time (UTC) | Kind | What |'
has ac11-as-it-happens "$SK" 'Every wait goes to the ledger'"'"'s Waits table when it ends, and every touch the person makes to its Person'"'"'s touches table when you read the answer'
has ac11-skill-stamps-each-stage "$SK" '1. **Create the role task and spawn the role**'
has ac11-skill-close-row-peak "$SK" 'add its row to the ledger'"'"'s Tasks table with the agent ids and the completion notice'"'"'s peak context'
has ac11-interruption-wait-kinds "$SK" '`limits` for a usage limit, `stalled` for no progress (the stream watchdog), `interrupted` for a server or connection error or a machine sleep'
has ac11-interruption-names-agent "$SK" 'with the stopped agent in its `Agent` column (`lead` for yourself)'
# v2 (#45): done, then stopped -- in hansei.md and in the run skill's Interruptions
has done-then-stopped-heading "$HA" '### Done, then stopped'
has done-then-stopped-no-resume "$HA" 'and do **not** resume or respawn the agent'
has done-then-stopped-commits-on-branch "$HA" '(`git branch --contains <sha>` lists it)'
has done-then-stopped-paths-clean "$HA" 'the role'"'"'s paths have no uncommitted changes in the worktree'
has done-then-stopped-else-resume "$HA" 'When either check fails, it is an ordinary interruption: resume the agent.'
has done-then-stopped-skill "$SK" '**Done, then stopped.** When the agent stalled or failed after writing a complete result with `Status: done`'
has done-then-stopped-skill-no-resume "$SK" 'do not resume or respawn it, log the wait as its kind, and put `done, then <kind>` in the Tasks row'"'"'s Notes'

# --- AC-13: cross-check written in, before posting
has ac13-git-evidence "$HA" "git log item/<id> --format='%aI %s'"
has ac13-tracker-evidence "$HA" '.created_at, (.body | split("\n")[0])'
has ac13-largest-gap "$HA" 'names the largest gap across rows'
before ac13-cross-check-before-post "$SK" '2. Complete the ledger'"'"'s Waits table with the close scan, then cross-check the Tasks table' '4. Fill the hansei template'
before ac13-close-scan-before-cross-check-ha "$HA" '2. Complete the ledger'"'"'s Waits table with the close scan (*Cut-offs at close*), then cross-check the Tasks table (section 2).' '4. Fill the template, measure 7 reading `pending resurvey`, and *Post hansei*'
before ac13-close-scan-before-spend-ha "$HA" '2. Complete the ledger'"'"'s Waits table with the close scan' '3. Total the token spend per role.'
# v2 round 5 (#44 F3): the close scan, in hansei.md and in the run skill
has close-scan-heading "$HA" '### Cut-offs at close'
has close-scan-every-role "$HA" 'Run `cut-offs.sh` once over every role agent'"'"'s transcript of this item'
has close-scan-lead-window "$HA" 'once over each session under `lead sessions`, with `--since` the ledger'"'"'s `started` and `--until` the approval time'
has close-scan-reconcile "$HA" 'it is the same wait: set its Start to the line'"'"'s start when they differ'
has close-scan-new-wait "$HA" '`What` `found at close: <markers>`'
has close-scan-open-end "$HA" 'an `open` end takes the End of that agent'"'"'s last Tasks row'
has close-scan-unreadable "$HA" '`cut-offs not captured (transcript <basename> unreadable)`'
has close-scan-skill "$SK" 'The scan runs `bash "${CLAUDE_PLUGIN_ROOT}/scripts/cut-offs.sh"` once over every role agent'"'"'s transcript of the item'
has m5-recovered-cut-counts "$HA" 'A recovered cut-off counts as much as a final one'
has m5-require-end-any-cut "$HA" 'a `stalled` or `interrupted` line other than `silent-gap`, even one the agent recovered from'
# the pmset filter is the same exact line in hansei.md, the run skill names it, and no looser grep of pmset appears
ck pmset-exact-filter-once 1 "$(grep -cF "pmset -g log | awk -F'\\t' '\$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *\$/ {print \$1}' | bash \"<plugin root>/scripts/cut-offs.sh\" --sleep-log -" "$HA")"
ck pmset-no-loose-grep 0 "$(grep -hE 'pmset[^|]*\| *grep' "$HA" "$SK" | grep -c .)"
has pmset-copy-utc-only "$HA" '**Copy only UTC start and end times** of a sleep into `What`'

# --- AC-14: marker, header, seven measures in fixed order
# #57: the record is v4 (contract 57-records-and-overrides section 1); a v3 record is still read, pinned in test_baseline_a3.sh
ck ac14-marker-first-line '<!-- factory:hansei v5 -->' "$(printf '%s\n' "$TEMPLATE" | sed -n 1p)"
ck ac14-marker-regex-matches 1 "$(printf '%s\n' "$TEMPLATE" | sed -n 1p | grep -Ec '^<!-- factory:hansei v([0-9]+) -->$')"
has ac14-find-hansei-op "$TP" "select(.body | startswith(\"<!-- factory:hansei v\")) | .id"
for k in '- plugin: factory <semver>' '- standard: <64 hex>' '- tooling: <64 hex>' '- active overrides: <none | <name> (since YYYY-MM-DD; whole item | from <YYYY-MM-DDTHH:MMZ> | until <YYYY-MM-DDTHH:MMZ>); …>' '- stage-log cross-check: largest gap <N>m (<row>: <evidence>)'; do
  ck "ac14-header '${k%%:*}'" 1 "$(printf '%s\n' "$TEMPLATE" | grep -cxF -- "$k")"
done
ck ac14-seven-measures-in-order "1. lead time|2. first-pass yield|3. rework|4. escaped defects|5. tokens|6. person's touches|7. doors" \
  "$(printf '%s\n' "$TEMPLATE" | grep -E '^[1-7]\. ' | cut -d: -f1 | paste -sd'|' -)"
has ac14-overrides-none "$HA" '`none` when both sets are empty, or when the file has no `## Overrides` section.'
# the worked example follows the template's line keys in the same order
EXAMPLE="$(block_after "$HA" '### Worked example')"
# 2.3.0 (#94): the two derived sub-lines under measure 1 are keyed `   - flow efficiency:` and `   - per stage:` (a key with a space)
keys() { sed -E 's/^(<!--[^>]*-->|## Hansei:|- [a-z -]+:|[1-7]\. [a-z'"'"' -]+:|   - [a-z -]+:).*/\1/' | grep -vE '^$|^   - <|^   - [A-Z]'; }
ck ac14-example-matches-template "$(printf '%s\n' "$TEMPLATE" | keys)" "$(printf '%s\n' "$EXAMPLE" | keys)"
ck ac14-example-marker '<!-- factory:hansei v5 -->' "$(printf '%s\n' "$EXAMPLE" | sed -n 1p)"
ck ac14-no-v1-marker-left 0 "$(grep -c 'factory:hansei v1 -->' "$HA" "$SK" "$TP" | awk -F: '{s+=$2} END {print s+0}')"
has ac14-v1-v2-not-compared "$HA" 'never compare measure 1 or 2 across v1 and v2'

# --- AC-15: each measure says what is counted and where it is read
MT="$(awk '/^### Measures$/ {f=1; next} f && /^\| [1-7] \|/ {print} f && /^Token script exits/ {exit}' "$HA")"
ck ac15-seven-rows 7 "$(printf '%s\n' "$MT" | grep -c .)"
ck ac15-every-row-has-counted-and-source 7 "$(printf '%s\n' "$MT" | awk -F'|' 'NF>=6 && length($4)>10 && length($5)>3 {n++} END {print n+0}')"
has ac15-m1-split "$HA" '**agent working** = total − the five waits, so agent working + person + limits + stalled + interrupted + andon = total.'
ck ac15-m1-template-line 1 "$(printf '%s\n' "$TEMPLATE" | grep -cxF '1. lead time: total <dur>; agent working <dur>; waiting for the person <dur>; waiting on limits <dur>; stalled <dur>; interrupted <dur>; andon <dur>')"
has ac15-m1-overlap-order "$HA" 'across kinds to the kind that comes first in this line'"'"'s order (person, limits, stalled, interrupted, andon)'
# measure 2 (v2, #46): the FPY grammar and the severity rule
has ac15-m2-fpy-grammar "$HA" '`<fpy>`: `pass first time` | `pass first time (<n> low)` | `failed first time` | `n/a (did not run)` | `not captured (<reason>)`.'
has ac15-m2-pass-needs-no-minor "$HA" '**Pass first time** = the first verdict is `pass` **and** that run lists no finding at or above minor.'
has ac15-m2-below-minor "$HA" 'Below minor means a severity of `low`, `info`, `trivial` or `note`'
has ac15-m2-no-severity-fails-closed "$HA" 'and a finding with no severity, counts as at or above minor'
has ac15-m2-failed "$HA" '**Failed first time** = the first verdict is not `pass`, or it lists a finding at or above minor, or (demo) any criterion failed.'
# measure 5 (v2): truncated transcripts read "not captured", by either signal
has ac15-m5-truncated "$HA" 'the role'"'"'s spend then reads `not captured (transcript truncated by <kind>)`, never a number'
has ac15-m5-signal-notice "$HA" 'names one of the role'"'"'s agents (or `lead`) in its `Agent` column'
has ac15-m5-signal-require-end "$HA" '`token-spend.sh --require-end` exits 6 for one of the role'"'"'s transcripts'
has ac15-m5-unlogged "$HA" '`<kind>` is then `unlogged`'
has ac15-m5-exit6-row "$HA" '| 6 | `not captured (transcript truncated by <kind>)`'
has ac15-m5-require-end-at-close "$HA" 'At close pass `--require-end` for every role transcript (never for the Lead'"'"'s own session, still running).'
has ac15-m2-na "$HA" '`n/a (did not run)` when the stage was skipped'
has ac15-m3-overturned "$HA" 'two-way decisions overturned by a `Source: lead` rework task'
has ac15-m5-script "$HA" 'bash "<plugin root>/scripts/token-spend.sh" <transcripts>'
has ac15-m5-lead-included "$HA" '   - lead: spend <tok>; peak context <n>'
has ac15-m6-touches "$HA" '6. person'"'"'s touches: decision cards <n>; demos <n>; approvals <n>; overturns <n>; other <n>'

# --- AC-16: honesty rule
has ac16-rule "$HA" 'an uncaptured value is never `0`, never blank, never dropped. The line stays in its place. `n/a` never stands in for `not captured`.'
has ac16-escaped-defects "$HA" '4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)'
has ac16-na-scope "$HA" 'Allowed only in measures 2 and 5, and only for a stage or role that did not run.'
has ac16-token-exit-never-0 "$HA" 'any non-zero exit: write the value as below, never `0`'
has ac16-example-uncaptured-spend "$HA" '   - security-reviewer: spend not captured (transcript agent-a41f09.jsonl unreadable); peak context 48820'
has ac16-example-zero-is-0 "$HA" 'feedback briefs product-owner 0, architect 0'
has ac16-cross-check-not-captured "$HA" 'With no evidence for any row it reads `not captured (<reason>)`'
has ac16-label-script-fails "$HA" 'When the script fails, each reads `not captured (<script'"'"'s message>)`'
# (the one line allowed to end in ':' is "7. doors:" with sub-lines, and "5. tokens:")
ck ac16-only-list-heads-end-in-colon "5. tokens:|7. doors:" "$(printf '%s\n' "$EXAMPLE" | grep -E ':[[:space:]]*$' | paste -sd'|' -)"

# --- worked examples add up
# lead time, computed from the stage-log example (section 4) and compared with the record example's line 1:
# total = Start item start -> Merge approval end; each kind = its held waits; agent working = total - the five
hm() { echo "$1" | sed -E 's/.*T([0-9]{2}):([0-9]{2})Z.*/\1 \2/' | awk '{print $1*60+$2}'; }
dur() { if [ "$1" -ge 60 ]; then echo "$(($1 / 60))h$(printf '%02d' $(($1 % 60)))m"; else echo "${1}m"; fi; }
WT="$(awk '/^### Waits$/ {f++} f==2 && /^\| W[0-9]+ \|/ {print}' "$HA")"
ck example-waits-rows 8 "$(printf '%s\n' "$WT" | grep -c .)"
SL1="$(awk '/^### Tasks$/ {f++} f==2 && /^\| [0-9]+ \|/ {print}' "$HA")"
t0="$(hm "$(awk '/^- started:/ {c++} c==2 {print; exit}' "$HA")")"
t1="$(hm "$(awk '/^### Person'"'"'s touches$/ {f++} f==2 && /\| approval \|/ {print $2; exit}' FS='|' "$HA")")"
tot=$((t1 - t0))
kindsum() { s=0; while IFS='|' read -r _ id kind ag st en held _r; do
    [ "$(echo $kind)" = "\`$1\`" ] || [ "$(echo $kind)" = "$1" ] || continue
    [ "$(echo $held)" = yes ] || continue
    s=$((s + $(hm "$en") - $(hm "$st"))); done <<EOT
$WT
EOT
  echo $s; }
p=$(kindsum person); l=$(kindsum limits); st=$(kindsum stalled); it=$(kindsum interrupted); an=$(kindsum andon)
w=$((tot - p - l - st - it - an))
want_m1="1. lead time: total $(dur $tot); agent working $(dur $w); waiting for the person $(dur $p); waiting on limits $(dur $l); stalled $(dur $st); interrupted $(dur $it); andon $(dur $an)"
ck example-lead-time-from-log "$want_m1" "$(printf '%s\n' "$EXAMPLE" | grep '^1\. lead time:')"
ck example-lead-time-value "1. lead time: total 4h41m; agent working 2h42m; waiting for the person 51m; waiting on limits 15m; stalled 15m; interrupted 18m; andon 20m" "$want_m1"
# the example holds a wait found at close (W6), and it names its markers
ck example-found-at-close-wait 1 "$(printf '%s\n' "$WT" | grep -c 'found at close: cut-mid-stream')"
ck example-five-parts-add-up "$tot" "$((w + p + l + st + it + an))"
ck example-has-stall-and-interruption "1 1" "$([ $st -gt 0 ] && echo 1 || echo 0) $([ $it -gt 0 ] && echo 1 || echo 0)"
# no two held waits overlap in the example (the text claims so; an overlap would double-count)
ov=0; prev_end=0
for r in $(printf '%s\n' "$WT" | awk -F'|' '$7 ~ /yes/ {print $5 "|" $6}' | sed 's/ //g' | sort); do
  s="$(hm "${r%%|*}")"; e="$(hm "${r##*|}")"; [ "$s" -lt "$prev_end" ] && ov=$((ov + 1)); [ "$e" -gt "$prev_end" ] && prev_end=$e
done
ck example-held-waits-do-not-overlap 0 "$ov"
# measure 5: every stalled/interrupted wait's agent marks that role's spend as truncated by that kind
bad=0
while IFS='|' read -r _ id kind ag _rest; do
  k="$(echo $kind | tr -d '`')"; a="$(echo $ag)"
  case "$k" in stalled|interrupted) ;; *) continue ;; esac
  role="$(printf '%s\n' "$SL1" | awk -F'|' -v a="$a" '$6 ~ a {gsub(/ /,"",$5); print $5; exit}')"
  printf '%s\n' "$EXAMPLE" | grep -qF "   - $role: spend not captured (transcript truncated by $k)" || { bad=$((bad + 1)); echo "     $id $k $a ($role) not marked truncated"; }
done <<EOT
$WT
EOT
ck example-truncated-roles-match-waits 0 "$bad"
# measure 2: the security row's notes ("2 low", verdict pass) give "pass first time (2 low)"; QA's first run had a finding
ck example-fpy "2. first-pass yield: qa failed first time; security pass first time (2 low); acceptance demo n/a (did not run)" "$(printf '%s\n' "$EXAMPLE" | grep '^2\. first-pass yield:')"
ck example-security-row-2-low 1 "$(printf '%s\n' "$SL1" | awk -F'|' '$4 ~ /^ Security $/ && $9 ~ /pass/ && $10 ~ /2 low/' | grep -c .)"
# done, then stopped shows in the example: the docs-writer row
ck example-done-then-stalled-row 1 "$(printf '%s\n' "$SL1" | awk -F'|' '$4 ~ /Documentation/ && $9 ~ /done/ && $10 ~ /done, then stalled/' | grep -c .)"
# every token line: total = i + w + r + o
bad=0
while IFS= read -r l; do
  t="$(printf '%s' "$l" | sed -E 's/.*spend ([0-9]+) \(.*/\1/')"
  s="$(printf '%s' "$l" | sed -E 's/.*input ([0-9]+), cache write ([0-9]+), cache read ([0-9]+), output ([0-9]+)\).*/\1+\2+\3+\4/' | bc)"
  [ "$t" = "$s" ] || { bad=$((bad + 1)); echo "     $l: $t vs $s"; }
done <<EOT
$(printf '%s\n' "$EXAMPLE" | grep -E 'spend [0-9]+ \(input')
EOT
ck example-token-totals-add-up 0 "$bad"
# the ledger example has one row per role task (8); a row's duration comes from its sub-issue, not from the table
SL="$SL1"
ck example-task-rows 8 "$(printf '%s\n' "$SL" | grep -c .)"

# --- AC-18: posted after approval and before work/<id>/ goes
before ac18-approval-before-post "$SK" '1. Once delivery and documentation are done' '4. Fill the hansei template'
before ac18-post-before-remove-work "$SK" '4. Fill the hansei template' '6. The last commit on `item/<id>` removes `work/<id>/`'
has ac18-posted-before-commit "$SK" 'The record is posted before this commit.'
before ac18-remove-work-before-merge "$SK" '6. The last commit on `item/<id>` removes `work/<id>/`' '7. Merge the PR'
has ac18-done-when "$SK" 'the hansei record is posted on the slice ticket'

# --- AC-19: measure 7 pending, then the same comment edited after the resurvey
has ac19-pending "$SK" 'measure 7 reading `pending resurvey`'
before ac19-resurvey-before-edit "$SK" '8. Invoke `/wayfinding:wayfinder` to resurvey' '9. Fill measure 7 (*Edit hansei*)'
has ac19-stopped "$SK" 'edit measure 7 to `not captured (run stopped before the resurvey)`'
has ac19-post-finds-first "$TP" '- **Post hansei**: run *Find hansei* first.'
has ac19-never-second "$TP" 'Never post a second record.'
has ac19-edit-patches-same "$TP" 'gh api --method PATCH "repos/{owner}/{repo}/issues/comments/<comment-id>" -F body=@<record>.md'
has ac19-pointer-in-map "$SK" 'hansei: <comment URL> (measure 7 pending)'
has ac19-done-when "$SK" 'measure 7 of the record is filled'

# --- AC-20: measurements stay in the project
repo_lines="$(grep -rnF -- '--repo' "$PLUGIN" | grep -v 'None names `--repo`' | grep -v 'No command here names `--repo`' | grep -v 'only instruction that names `--repo' | grep -vF -- '--repo <owner>/<repo>')"  # setup links the project to its own repo
ck ac20-only-step9-names-repo 1 "$(printf '%s\n' "$repo_lines" | grep -c .)"
ck ac20-the-one-is-feedback-issue 1 "$(printf '%s\n' "$repo_lines" | grep -c 'gh issue create --repo WimSuenens/agent-plugins --label plugin:factory')"
# #57: the feedback offer is step 9.4 of the run close (contract 57-run-close section 6); the rule's four parts are kept, reworded
before ac20-feedback-issue-in-step9 "$SK" '## 9. Close the run' 'gh issue create --repo WimSuenens/agent-plugins'
for w in 'the problem in factory terms' 'the exact standard change' 'the before and after figures from the A3 against the baseline with the item count and the release' 'a neutral kind of work' 'no code, no project names, no business content and no raw hansei records'; do
  has "ac20-step9-rule '$w'" "$SK" "$w"
done
has ac20-hansei-rule "$HA" 'None names `--repo`, and none is written to `WimSuenens/agent-plugins`.'
ck ac20-tracker-ops-no-repo 0 "$(grep -E 'Find hansei|Post hansei|Edit hansei' "$TP" | grep -c -- '--repo ')"
# no hansei instruction writes into the plugin's own tree
ck ac20-no-write-into-plugin-root 0 "$(grep -nE '> *"?\$\{CLAUDE_PLUGIN_ROOT\}|tee .*CLAUDE_PLUGIN_ROOT' "$SK" "$HA" "$TP" | grep -c .)"

# --- feedback 15 #4 / contract 39-standard-changes section 3: hansei.md names <plugin root>, never runs ${CLAUDE_PLUGIN_ROOT}
ck plugin-root-no-literal-var-in-commands 0 "$(grep -cF '"${CLAUDE_PLUGIN_ROOT}' "$HA")"
has plugin-root-placeholder-explained "$HA" '`<plugin root>` is the path on the `Plugin root:` line of `skills/run/SKILL.md`'
has label-fingerprint-uses-placeholder "$HA" 'bash "<plugin root>/scripts/fingerprint.sh" "<plugin root>"'
ck label-example-root-as-tilde 0 "$(grep -cE '^- plugin root: /(Users|home)/' "$HA")"

# --- feedback 15 #6 (security L2): bump re-check before merge; semver before tag
# inline_before name text a b: within one line of text, a occurs before b
inline_before() { awk -v a="$3" -v b="$4" 'BEGIN{ia=0; ib=0} {i=index($0,a); j=index($0,b); if(i&&!ia) ia=i; if(j&&!ib) ib=j} END{exit !(ia && ib && ia<ib)}' <<EOT
$2
EOT
  if [ $? = 0 ]; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$3' not before '$4'"; fail=1; fi; }
MP="$(grep -F -- '- **Merge PR**' "$TP")"
ck merge-pr-one-bullet 1 "$(printf '%s\n' "$MP" | grep -c .)"
inline_before merge-recheck-before-merge "$MP" 'First re-run the release check' 'Exit 0: `gh pr merge <branch> --merge`'
has merge-recheck-fetch-and-script "$TP" 'First re-run the release check: `git fetch origin main`, then `bash "<plugin root>/scripts/release-hook.sh" check <worktree> <id> origin/main`'
has merge-recheck-refuse-no-merge "$TP" 'Exit 1 or 2: do not merge'
ck merge-pr-no-literal-var 0 "$(printf '%s' "$MP" | grep -cF '${CLAUDE_PLUGIN_ROOT}')"
# the tag step moved out of the plugin (#210): it is the repository's release hook, with the same semver rule
RH="$REPO/scripts/release.sh"
ck tag-semver-before-tag 1 "$([ "$(grep -n 'MAJOR.MINOR.PATCH; no tag' "$RH" | head -1 | cut -d: -f1)" -lt "$(grep -n 'tag "factory-v' "$RH" | head -1 | cut -d: -f1)" ] && echo 1 || echo 0)"
# the tag check must be the contract's semver (no leading zeros); pull the regex out of the hook and run it
RX="$(sed -n "s/^semver_re='\(.*\)'\$/\1/p" "$RH" | head -1)"
ck tag-regex-present 1 "$([ -n "$RX" ] && echo 1)"
okc=0; for v in 1.0.0 0.0.0 10.20.30; do printf '%s' "$v" | grep -Eq "$RX" && okc=$((okc + 1)); done; ck tag-regex-accepts-semver 3 $okc
badc=0; for v in 1.0 v1.0.0 1.0.0-rc1 '1.0.0 x'; do printf '%s' "$v" | grep -Eq "$RX" || badc=$((badc + 1)); done; ck tag-regex-rejects-non-semver 4 $badc
lz=0; for v in 1.08.0 01.0.0 1.0.00; do printf '%s' "$v" | grep -Eq "$RX" || lz=$((lz + 1)); done
ck tag-regex-rejects-leading-zeros 3 $lz   # QA-39 F5, fixed in 9ee1cdc
# SKILL.md step 7 sends the merge through Merge PR (which holds the re-check)
has merge-through-merge-pr "$SK" '7. Merge the PR and remove the worktree and branch (*Merge PR*'
has frontier-merge-through-merge-pr "$SK" 'merge the PR to main and clean up (*Merge PR*)'
has frontier-pr-bump-check "$SK" '2. Run the *Open PR* release check (`git fetch origin main`, then `release-hook.sh check` in the round'"'"'s worktree, as in step 6) with the same exit handling, then open one PR from `frontier/<map>`'

# --- feedback 15 #7 (security L3): Find hansei keeps only the Lead's own comments with the marker; run its jq on sample comments
FH="$(grep -F -- '- **Find hansei**' "$TP")"
ck find-hansei-me-from-gh 1 "$(printf '%s' "$FH" | grep -cF 'me="$(gh api user --jq .login)"')"
JQ="${FH#*--paginate --jq \'}"; JQ="${JQ%%\'\`*}"   # the filter between --jq ' and the closing '`
me=lead-bot
JQ="$(printf '%s' "$JQ" | sed "s/'\"\$me\"'/$me/")"
cat > "$T/comments.json" <<'EOJ'
[{"id":1,"user":{"login":"mallory"},"body":"<!-- factory:hansei v1 -->\nfake"},
 {"id":2,"user":{"login":"lead-bot"},"body":"stage summary"},
 {"id":3,"user":{"login":"lead-bot"},"body":"<!-- factory:hansei v1 -->\n## Hansei: #1"},
 {"id":4,"user":{"login":"lead-bot"},"body":"quote: <!-- factory:hansei v1 -->"},
 {"id":5,"user":{"login":"Lead-Bot"},"body":"<!-- factory:hansei v2 -->"}]
EOJ
ck find-hansei-jq-filters-author-and-marker 3 "$(jq -r "$JQ" "$T/comments.json" | paste -sd, -)"
printf '[{"id":9,"user":{"login":"mallory"},"body":"<!-- factory:hansei v1 -->"}]' > "$T/c2.json"
ck find-hansei-others-only-prints-nothing "" "$(jq -r "$JQ" "$T/c2.json")"
ck find-hansei-no-repo 0 "$(printf '%s' "$FH" | grep -c -- '--repo')"

# --- feedback 15 #9 (security L6): Edit hansei scratch file from mktemp, removed afterwards
ED="$(grep -F -- '- **Edit hansei**' "$TP")"
ck edit-hansei-mktemp 1 "$(printf '%s' "$ED" | grep -cF 'rec="$(mktemp)"')"
ck edit-hansei-rm 1 "$(printf '%s' "$ED" | grep -cF 'rm -f "$rec"')"
ck edit-hansei-outside-repo-not-committed 1 "$(printf '%s' "$ED" | grep -cF 'outside the repo, never committed')"
ck edit-hansei-patch-same-comment 1 "$(printf '%s' "$ED" | grep -cF -- '--method PATCH "repos/{owner}/{repo}/issues/comments/<comment-id>"')"
PH="$(grep -F -- '- **Post hansei**' "$TP")"
# QA-39 F6, fixed in 9ee1cdc: scratch file from mktemp, posted from it, removed afterwards, in that order
ck post-hansei-mktemp 1 "$(printf '%s' "$PH" | grep -cF 'rec="$(mktemp)"')"
ck post-hansei-body-file 1 "$(printf '%s' "$PH" | grep -cF -- '--body-file "$rec"')"
ck post-hansei-rm 1 "$(printf '%s' "$PH" | grep -cF 'rm -f "$rec"')"
inline_before post-hansei-mktemp-before-post "$PH" 'rec="$(mktemp)"' '--body-file "$rec"'
inline_before post-hansei-post-before-rm "$PH" '--body-file "$rec"' 'rm -f "$rec"'

# --- close order (v2 #47; round 5 L8/L9; final round L11): the close of step 8.6 is scripts/close-item.sh (slice 0 of #207 moved it out of
# the prose, where hansei.md carried a second copy). The script is one shell call by construction, so the old "w is gone in a split call"
# case (7) has no counterpart; the other cases (1 to 6) run unchanged against the script. The text still pins what the person reads.
SK_CI="$PLUGIN/scripts/close-item.sh"
C6="$(awk '/^6\. The last commit on `item\/<id>` removes `work\/<id>\/`/ {f=1} f && /^7\. Merge the PR/ {exit} f' "$SK" | tr '\n' ' ')"
H6="$(awk '/^6\. Remove `work\/<id>\/`, in the item worktree/ {f=1} f && /^7\. \*Merge PR\*/ {exit} f' "$HA" | tr '\n' ' ')"
ck close-step6-one-bullet 1 "$(grep -cF '6. The last commit on `item/<id>` removes `work/<id>/`' "$SK")"
ck close-ha-step6-present 1 "$([ -n "$H6" ] && echo 1)"
for X in C6 H6; do
  eval "Y=\"\$$X\""
  ck "close-$X-points-at-the-script" 1 "$(printf '%s' "$Y" | grep -cF 'scripts/close-item.sh')"
  ck "close-$X-stops-to-person" 1 "$(printf '%s' "$Y" | grep -cF 'stop the close and put it to the person')"
  ck "close-$X-no-inline-git" 0 "$(printf '%s' "$Y" | grep -cE 'git -C|rm -rf')"
done
has close-posted-before-lead-state-commit "$SK" 'It is posted before the lead-state commit too.'
has close-untracked-never-staged "$SK" 'Other untracked files under `work/<id>/` are never staged.'
has close-ha-untracked-never-staged "$HA" 'are never staged: a commit stays in the project'"'"'s history for good'
before close-ha-post-before-remove "$HA" '4. Fill the template, measure 7 reading `pending resurvey`, and *Post hansei*' '6. Remove `work/<id>/`, in the item worktree'
# the script's own text: every use of w is "${w:?}" (the only bare "$w" is the guard's emptiness test), no rm -rf, and the order
CI1="$(tr '\n' ' ' < "$SK_CI" | tr -s ' ')"; W='"${w:?}"'
ck close-script-only-guarded-w '[ -n "$w"|[ "$w"' "$(grep -v '^#' "$SK_CI" | grep -oE '.{0,6}"\$w[/"]' | sed 's/^ *//' | paste -sd'|' -)"
ck close-script-no-rm-rf 0 "$(grep -v '^#' "$SK_CI" | grep -c 'rm -rf')"
ck close-script-every-git-names-worktree 0 "$(grep -v '^#' "$SK_CI" | grep -oE 'git (add|commit|rm|diff|clean) ' | grep -c .)"
inline_before close-script-id-before-worktree "$CI1" 'case "${1:-}" in' 'w="$(git worktree list --porcelain'
inline_before close-script-symlink-guard-before-add "$CI1" 'if [ -L "${w:?}/work" ] || [ -L "${w:?}/work/$id" ]' "git -C $W add -- \":(glob)work/\$id/[0-9][0-9]-*.md\""
inline_before close-script-add-nn-before-add-u "$CI1" "git -C $W add -- \":(glob)work/\$id/[0-9][0-9]-*.md\"" "git -C $W add -u -- \"work/\$id\""
inline_before close-script-add-before-commit "$CI1" "git -C $W add -u -- \"work/\$id\"" "git -C $W commit -m \"#\$id lead: close\""
inline_before close-script-commit-staged-only "$CI1" "git -C $W diff --cached --quiet" "git -C $W commit -m \"#\$id lead: close\""
inline_before close-script-lead-state-before-rm "$CI1" "git -C $W commit -m \"#\$id lead: close\"" "git -C $W rm -r -q -- \"work/\$id\""
ck close-script-rm-chain 1 "$(printf '%s' "$CI1" | grep -cF "git -C $W rm -r -q -- \"work/\$id\" && git -C $W clean -f -d -x -q -- \"work/\$id\" && [ ! -e \"\${w:?}/work/\$id\" ] && git -C $W commit -m \"#\$id lead: remove work/\"")"
ck close-script-glob-keeps-one-level 1 "$(grep -cF ':(glob)work/$id/[0-9][0-9]-*.md' "$SK_CI")"
ck close-no-add-all 0 "$(grep -cF 'git add -A' "$SK" "$HA" "$SK_CI" | awk -F: '{s+=$2} END {print s+0}')"
ck close-no-force-git-rm 0 "$(grep -cE 'git rm -[a-z]*f' "$SK" "$HA" "$SK_CI" | awk -F: '{s+=$2} END {print s+0}')"
ck close-no-shell-rm-on-var 0 "$(grep -hoE '(^|[;&|`(] *)rm -[a-z]*r[a-z]* [^`]*' "$SK" "$HA" "$SK_CI" | grep -cE '\$\{?w')"
close_script() { printf 'bash "%s" %q\n' "$SK_CI" "$1"; }   # the close as the Lead runs it: the script, from the main checkout
mkclose() { # dir worktree-dir: main checkout + item/12 worktree with work/12 committed
  git init -q -b main "$1" && ( cd "$1" && printf '.DS_Store\n' > .gitignore && echo r > README && git add -A && git commit -qm init \
    && git worktree add -q "$2" -b item/12 && mkdir -p "$2/work/12" && echo a > "$2/work/12/00-lead-state.md" && echo b > "$2/work/12/01-brief-developer.md" \
    && git -C "$2" add -A && git -C "$2" commit -qm "#12 lead: start" ) >/dev/null 2>&1; }
# 1. dirty lead state, untracked brief, stray .env and dump, ignored .DS_Store; worktree path with a space; a neighbour item/123
CM="$T/cl1/main"; CW="$T/cl1/wt x/12"; mkclose "$CM" "$CW"
( cd "$CM" && git worktree add -q "$T/cl1/wt x/123" -b item/123 && mkdir -p "$T/cl1/wt x/123/work/123" && echo n > "$T/cl1/wt x/123/work/123/00-lead-state.md" ) >/dev/null 2>&1
echo 'close rows' >> "$CW/work/12/00-lead-state.md"; echo c > "$CW/work/12/09-brief-docs-writer.md"
echo 'TOKEN=qa-fake-secret' > "$CW/work/12/.env"; echo dump > "$CW/work/12/dump.txt"; echo x > "$CW/work/12/.DS_Store"
mh="$(git -C "$CM" rev-parse HEAD)"
( cd "$CM" && bash -c "$(close_script 12)" ) >"$T/close.out" 2>&1; ck close-run-clean 0 $?
ck close-run-work-gone "no" "$([ -e "$CW/work/12" ] && echo yes || echo no)"
ck close-run-commits "#12 lead: remove work/|#12 lead: close" "$(git -C "$CW" log -2 --format=%s | paste -sd'|' -)"
ck close-run-lead-state-in-history "close rows" "$(git -C "$CW" show HEAD~1:work/12/00-lead-state.md 2>/dev/null | tail -1)"
ck close-run-untracked-brief-in-history c "$(git -C "$CW" show HEAD~1:work/12/09-brief-docs-writer.md 2>/dev/null)"
ck close-run-no-stray-in-history "" "$(git -C "$CW" log --format= --name-only | grep -E '\.env|dump\.txt|\.DS_Store' | sort -u)"
ck close-run-worktree-clean "" "$(git -C "$CW" status --porcelain --ignored)"
ck close-run-main-untouched "main $mh" "$(git -C "$CM" branch --show-current) $(git -C "$CM" rev-parse HEAD)"
ck close-run-neighbour-untouched n "$(cat "$T/cl1/wt x/123/work/123/00-lead-state.md" 2>/dev/null)"
# 2. nothing to commit in the lead state: no close commit, the removal still runs
CM="$T/cl2/main"; CW="$T/cl2/wt/12"; mkclose "$CM" "$CW"
( cd "$CM" && bash -c "$(close_script 12)" ) >/dev/null 2>&1; ck close-run-clean-state 0 $?
ck close-run-clean-state-commits "#12 lead: remove work/|#12 lead: start" "$(git -C "$CW" log -2 --format=%s | paste -sd'|' -)"
# 3. a committed work symlink (and a work/12 symlink): the guard stops, nothing outside is removed, no commit
for kind in work work12; do
  CM="$T/cl3$kind/main"; CW="$T/cl3$kind/wt/12"; O3="$T/cl3$kind/outside"; mkdir -p "$O3/12"; echo keep > "$O3/12/precious.md"
  git init -q -b main "$CM"; ( cd "$CM" && echo r > README && git add -A && git commit -qm init && git worktree add -q "$CW" -b item/12 ) >/dev/null 2>&1
  if [ $kind = work ]; then ln -s "$O3" "$CW/work"; else mkdir "$CW/work"; ln -s "$O3/12" "$CW/work/12"; fi
  git -C "$CW" add -A >/dev/null 2>&1; git -C "$CW" commit -qm "#12 dev: symlink" >/dev/null 2>&1; h="$(git -C "$CW" rev-parse HEAD)"
  ( cd "$CM" && bash -c "$(close_script 12)" ) >"$T/close.out" 2>&1; code=$?
  ck "close-guard-$kind-symlink-stops" "1 close: work/ is a symlink" "$code $(cat "$T/close.out")"
  ck "close-guard-$kind-symlink-nothing-removed" "keep $h" "$(cat "$O3/12/precious.md" 2>/dev/null) $(git -C "$CW" rev-parse HEAD)"
done
# 4. a non-numeric id, and an id with no worktree: the guard stops before any git command
( cd "$CM" && bash -c "$(close_script '12;x')" ) >"$T/close.out" 2>&1; ck close-guard-id-not-numeric "1 close: id not numeric" "$? $(cat "$T/close.out")"
( cd "$CM" && bash -c "$(close_script '')" ) >"$T/close.out" 2>&1; ck close-guard-id-empty "1 close: id not numeric" "$? $(cat "$T/close.out")"
( cd "$CM" && bash -c "$(close_script 99)" ) >"$T/close.out" 2>&1; ck close-guard-no-worktree "1 close: no worktree for item/99" "$? $(cat "$T/close.out")"
# 5. a directory named like a message (work/12/03-dump/, holding *.md files a bare pathspec glob would match): not staged, removed
CM="$T/cl5/main"; CW="$T/cl5/wt/12"; mkclose "$CM" "$CW"
mkdir -p "$CW/work/12/03-dump/04-x"; echo s > "$CW/work/12/03-dump/notes.md"; echo s > "$CW/work/12/03-dump/04-x/05-y.md"
echo 'close rows' >> "$CW/work/12/00-lead-state.md"
( cd "$CM" && bash -c "$(close_script 12)" ) >"$T/close.out" 2>&1; ck close-dump-dir-run-clean 0 $?
ck close-dump-dir-not-in-history "" "$(git -C "$CW" log --format= --name-only | grep '03-dump' | sort -u)"
ck close-dump-dir-lead-state-committed "close rows" "$(git -C "$CW" show HEAD~1:work/12/00-lead-state.md 2>/dev/null | tail -1)"
ck close-dump-dir-removed "no" "$([ -e "$CW/work/12" ] && echo yes || echo no)"
# 6. a nested git repository under work/12/ (git clean -f leaves it): the [ ! -e ] test stops the chain; rc 1, git rm staged,
# no remove commit, the nested repo and its files kept for the person
CM="$T/cl6/main"; CW="$T/cl6/wt/12"; mkclose "$CM" "$CW"
git init -q "$CW/work/12/sub"; echo keep > "$CW/work/12/sub/f.md"; h6="$(git -C "$CW" rev-parse HEAD)"
( cd "$CM" && bash -c "$(close_script 12)" ) >"$T/close.out" 2>&1; ck close-nested-repo-stops 1 $?
ck close-nested-repo-nothing-committed "$h6" "$(git -C "$CW" rev-parse HEAD)"
ck close-nested-repo-rm-staged "D  work/12/00-lead-state.md|D  work/12/01-brief-developer.md" "$(git -C "$CW" status --porcelain -- work/12 | grep '^D' | paste -sd'|' -)"
ck close-nested-repo-kept keep "$(cat "$CW/work/12/sub/f.md" 2>/dev/null)"

# --- v2 F1 (round 5): the stall/interruption start, taken with hansei.md's own command (*Taking the start*: cut-offs.sh on
# the stopped transcript, last line's start, cut to minutes), is the last entry before the gap, not the notice.
# Fixture: the acceptance demo's developer transcript shape (factory-sandbox #2, agent a37df…): the watchdog notice
# arrived at 00:05:54 and wrote "[Request interrupted by user]" at that same moment; the last entry before the gap is
# the tool result at 23:50:46. Wanted start: 2026-11-04T23:50Z (stall 15m, not ~0m).
SC="$(grep -F '**Taking the start from the transcript.**' "$HA" | grep -oE '`bash "<plugin root>/scripts/cut-offs.sh" [^`]+`' | head -1 | tr -d '`')"
ck stall-start-command-present 'bash "<plugin root>/scripts/cut-offs.sh" [--sleep-log -] -- <transcript>' "$SC"
cat > "$T/dev-stalled.jsonl" <<'EOJ'
{"type":"assistant","timestamp":"2026-11-04T23:50:41.956Z","message":{"id":"d0","content":[{"type":"thinking","thinking":""}]}}
{"type":"assistant","timestamp":"2026-11-04T23:50:45.512Z","message":{"id":"d1","content":[{"type":"tool_use","id":"t1","name":"Bash","input":{}}]}}
{"type":"user","timestamp":"2026-11-04T23:50:46.823Z","message":{"content":[{"tool_use_id":"t1","type":"tool_result","content":"ok"}]}}
{"type":"user","timestamp":"2026-11-05T00:05:54.064Z","message":{"content":[{"type":"text","text":"[Request interrupted by user]"}]}}
EOJ
run_sc() { cmd="$(printf '%s' "$SC" | sed -e "s|<plugin root>|$PLUGIN|" -e 's| \[--sleep-log -\]||' -e "s|<transcript>|$1|")"; (cd "$T" && eval "$cmd") 2>/dev/null; }
got="$(run_sc dev-stalled.jsonl | tail -n 1 | cut -f3 | cut -c1-16)Z"
ck stall-start-is-last-entry-before-gap "2026-11-04T23:50Z" "$got"
ck stall-start-not-tail "2026-11-05T00:05:54.064Z" "$(tail -n 1 "$T/dev-stalled.jsonl" | jq -r .timestamp)"   # what the v2 text's tail -n 1 gave

# --- v2 F2 (round 5): the Lead's own interruption in the demo. The session's last working entry (01:43:18) is followed by the
# assistant line "API Error: Your computer went to sleep mid-response." (isApiErrorMessage, error server_error, 02:00:45),
# and the person's "continue" (06:49:23) set it going; the Lead's next output is at 06:49:32. The close scan over the
# Lead session (hansei.md: --since the Start item start, --until the approval time) must give one interrupted line.
has lead-api-error-detected "$HA" 'such as your own `API Error: Your computer went to sleep mid-response`'
cat > "$T/lead.jsonl" <<'EOJ'
{"type":"user","timestamp":"2026-11-05T01:40:00.000Z","message":{"content":"next step"}}
{"type":"assistant","timestamp":"2026-11-05T01:43:18.500Z","message":{"id":"l1","content":[{"type":"text","text":"Briefing QA."}]}}
{"type":"assistant","timestamp":"2026-11-05T02:00:45.100Z","isApiErrorMessage":true,"error":"server_error","message":{"id":"l2","model":"<synthetic>","content":[{"type":"text","text":"API Error: Your computer went to sleep mid-response."}]}}
{"type":"user","timestamp":"2026-11-05T06:49:23.000Z","message":{"content":"continue"}}
{"type":"assistant","timestamp":"2026-11-05T06:49:32.900Z","message":{"id":"l3","content":[{"type":"text","text":"Resuming."}]}}
EOJ
ck lead-api-error-close-scan "lead.jsonl|interrupted|2026-11-05T01:43:18Z|2026-11-05T06:49:32Z|api-error:server_error" \
  "$(cd "$T" && bash "$PLUGIN/scripts/cut-offs.sh" --since 2026-11-04T21:52Z --until 2026-11-05T07:08Z -- lead.jsonl | tr '\t' '|')"

# --- v2 F3 (round 5): cut-offs an agent recovered from with no notice. The demo's QA agent (a85f55…) lost ~72m to three
# "cut off mid-stream" entries and two "API Error … went to sleep" entries before its final stall. The close scan finds
# them; a role transcript holding one marks its spend not captured (--require-end exit 6, tested in test_token_spend.sh).
has in-run-cutoffs-detected "$HA" 'this finds the cut-offs an agent recovered from by itself, which send no notice'
cat > "$T/qa-recovered.jsonl" <<'EOJ'
{"type":"user","timestamp":"2026-11-05T00:07:00.000Z","message":{"content":"You are the QA engineer."}}
{"type":"assistant","timestamp":"2026-11-05T00:08:06.200Z","message":{"id":"q1","content":[{"type":"thinking","thinking":""}]}}
{"type":"user","timestamp":"2026-11-05T00:14:49.000Z","isMeta":true,"message":{"role":"user","content":"Your response above was cut off mid-stream and only your next message is delivered."}}
{"type":"assistant","timestamp":"2026-11-05T00:14:53.000Z","message":{"id":"q2","content":[{"type":"text","text":"Again."}]}}
{"type":"assistant","timestamp":"2026-11-05T01:04:10.000Z","isApiErrorMessage":true,"error":"server_error","message":{"id":"q3","model":"<synthetic>","content":[{"type":"text","text":"API Error: Your computer went to sleep mid-response."}]}}
{"type":"user","timestamp":"2026-11-05T01:04:28.000Z","message":{"content":"continue"}}
{"type":"assistant","timestamp":"2026-11-05T01:04:31.000Z","message":{"id":"q4","content":[{"type":"text","text":"Done."}]}}
EOJ
ck in-run-cutoffs-close-scan "stalled|2026-11-05T00:08:06Z|2026-11-05T00:14:53Z|cut-mid-stream;interrupted|2026-11-05T00:14:53Z|2026-11-05T01:04:31Z|api-error:server_error" \
  "$(cd "$T" && bash "$PLUGIN/scripts/cut-offs.sh" -- qa-recovered.jsonl | cut -f2- | tr '\t' '|' | paste -sd';' -)"

# --- contract 39-standard-changes section 9 / ADR 0013 (#48 option A): the path rule, the security checklist line, --merge kept
PR_="$PLUGIN/references/protocol.md"; SR="$PLUGIN/agents/security-reviewer.md"
has path-rule-three-forms "$PR_" 'Paths in a message file are worktree-relative (`plugins/factory/agents/developer.md`), relative to the main checkout for another worktree (`.claude/worktrees/<id>`), or start with `~/` for anything under the home directory (`~/.claude/plugins/cache/...`).'
has path-rule-never-home "$PR_" 'Never write an absolute path under the home directory: `work/` is merged into the project'"'"'s history with every commit and stays there for good.'
has path-rule-every-type-lead-state "$PR_" 'This covers every message type, the lead state included'
has path-rule-commands "$PR_" 'commands in a message (`~/` or `"$HOME"/...`)'
has path-rule-spawn-prompt-outside "$PR_" 'A spawn prompt is chat, not a file, and is outside the rule.'
# placed in Messages: after the line naming the files (both folders, so frontier rounds too), before the Brief format
before path-rule-after-file-names "$PR_" 'Files in `work/<id>/` (or `work/frontier-<id>/`) are named `NN-<type>-<role>.md`' 'Paths in a message file are worktree-relative'
before path-rule-before-brief "$PR_" 'Paths in a message file are worktree-relative' 'Brief (lead → role), the body of the role-task issue'
before path-rule-in-messages "$PR_" '## Messages' 'Paths in a message file are worktree-relative'
# the rule's own conforming examples conform, and no shipped standard file carries an absolute home path
ck path-rule-no-home-path-in-plugin "" "$(grep -rlE '/(Users|home)/[A-Za-z0-9._-]+/' "$PLUGIN/references" "$PLUGIN/agents" "$PLUGIN/skills" 2>/dev/null)"
# the run skill points the Lead's own files at the rule, where step 4 writes the lead state
L4="$(grep -E '^4\. Write `work/<id>/00-lead-state.md`' "$SK")"
ck skill-step4-path-rule 1 "$(printf '%s' "$L4" | grep -cF 'The lead state and every brief follow the protocol'"'"'s path rule (*Messages*): no absolute path under the home directory, only worktree-relative, `.claude/worktrees/<id>` or `~/` paths.')"
# security-reviewer.md Steps 1 carries the checklist line, inside step 1 (before step 2)
has sec-checklist-expected "$SR" '`work/<id>/` in the merge history is expected: items merge with `--merge` and keep every role commit. Not a finding.'
has sec-checklist-finding "$SR" 'The finding is an absolute home path, a secret, or a file not named `NN-<type>-<role>.md`, in any commit of the item that touches `work/`.'
has sec-checklist-low-no-rewrite "$SR" 'any line is a finding, severity low'
has sec-checklist-no-rewrite "$SR" 'not to rewrite history'
before sec-checklist-in-step1 "$SR" '1. Review every changed file' '`work/<id>/` in the merge history is expected'
before sec-checklist-before-step2 "$SR" '`work/<id>/` in the merge history is expected' '2. Run the dependency audit.'
ck sec-checklist-only-in-security 1 "$(grep -lF 'in the merge history is expected' "$PLUGIN"/agents/*.md | grep -c .)"
# run the checklist's command verbatim: a scratch item with one slipped home path in a brief, a home path outside work/,
# and a conforming ~/ path. The command lists exactly the commit that put the home path into work/.
SRC="$(grep -oE '`git log -S"\$HOME/"[^`]+`' "$SR" | tr -d '`')"
ck sec-checklist-command 'git log -S"$HOME/" --format='"'"'%h %s'"'"' origin/main..HEAD -- work/' "$SRC"
H9="$T/h9/home/qa"; R9="$T/h9/repo"; mkdir -p "$H9"
git init -q -b main "$T/h9/origin.git" --bare; git clone -q "$T/h9/origin.git" "$R9" 2>/dev/null
( cd "$R9" && echo r > README && git add -A && git commit -qm init && git push -q origin main && git checkout -q -b item/9 \
  && mkdir -p work/9 && echo 'Inputs: ~/.claude/plugins/cache/x' > work/9/01-brief-developer.md && git add -A && git commit -qm '#9 lead: brief ok' \
  && echo "Inputs: $H9/Projects/shop/wt/9/plugins" > work/9/02-brief-qa-engineer.md && git add -A && git commit -qm '#9 lead: QA brief' \
  && echo "see $H9/x" > notes.md && git add -A && git commit -qm '#9 dev: notes outside work' ) >/dev/null 2>&1
ck sec-checklist-command-finds-slip "#9 lead: QA brief" "$(cd "$R9" && HOME="$H9" eval "$SRC" | cut -d' ' -f2-)"
( cd "$R9" && git rm -q work/9/02-brief-qa-engineer.md && git commit -qm '#9 lead: remove' ) >/dev/null 2>&1
ck sec-checklist-command-history-kept 2 "$(cd "$R9" && HOME="$H9" eval "$SRC" | grep -c .)"   # added and removed: both in history
R9c="$T/h9/clean"; git clone -q "$T/h9/origin.git" "$R9c" 2>/dev/null
( cd "$R9c" && git checkout -q -b item/9 && mkdir -p work/9 && echo 'Inputs: ../wt/9' > work/9/01-brief-developer.md && git add -A && git commit -qm '#9 lead: brief' ) >/dev/null 2>&1
ck sec-checklist-command-clean-item "" "$(cd "$R9c" && HOME="$H9" eval "$SRC")"
# Merge PR keeps --merge, with the reason clause; no squash or rebase merge anywhere in the standard
inline_before merge-style-reason "$MP" 'gh pr merge <branch> --merge` (`--merge`, never squash or rebase' 'the role commits are the evidence the hansei record is re-checked against'
ck merge-style-no-squash-or-rebase 0 "$(grep -rhoE 'gh pr merge[^`]*--(squash|rebase)' "$PLUGIN" | grep -c .)"
# contract section 8: this repo's issue-tracker doc and the CHANGELOG carry the merge-style rule (docs-writer)
if grep -qF -- '`--merge`, never squash or rebase' "$REPO/docs/agents/issue-tracker.md"; then ck docs-tracker-merge-reason 1 1
else skip docs-tracker-merge-reason "QA-39 final F1 (low): docs/agents/issue-tracker.md Merge PR lacks the --merge reason clause (contract 39-standard-changes s8; docs-writer)"; fi
if grep -qF 'The merge style is open (#48)' "$REPO/CHANGELOG.md"; then
  skip docs-changelog-merge-style "QA-39 final F1 (low): CHANGELOG.md still says 'The merge style is open (#48)'; contract s8 wants the 1.0.0 entry to name the merge-style rule (docs-writer)"
else ck docs-changelog-merge-style 1 "$(grep -c -- '--merge' "$REPO/CHANGELOG.md" | awk '{print ($1>0)}')"; fi

# --- AC-7 support: the tag step exists in Merge PR
has ac7-tag-in-merge-pr "$TP" 'release-hook.sh" tag <worktree> <id> origin/main <branch>'
has ac7-tag-command-in-the-hook "$REPO/scripts/release.sh" 'git -C "$main" tag "factory-v$new" "$sha"'

done_
