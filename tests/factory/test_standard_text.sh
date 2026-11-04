#!/bin/bash
# The new standard's text: AC-1, AC-6, AC-8, AC-11, AC-13, AC-14, AC-15, AC-16, AC-18, AC-19, AC-20,
# and contract 39-standard-changes. Checks what the Lead is told, not how it behaves in a session
# (that is the acceptance demo's human-only list in reviews/qa-39.md).
. "$(dirname "$0")/lib.sh"
SK="$PLUGIN/skills/run/SKILL.md"
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
ck ac1-plugin-version "1.0.0" "$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")"
ck ac1-version-own-line 1 "$(grep -c '^  "version": "1.0.0",$' "$PLUGIN/.claude-plugin/plugin.json")"
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
has ac8-fetch-then-check "$SK" '1. `git fetch origin main`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-bump.sh"` in the item worktree.'
has ac8-before-pr-create "$SK" 'Before `gh pr create`, always:'
has ac8-exit1-no-pr "$SK" 'Exit 1: do not open the PR.'
has ac8-exit1-feedback-source-lead "$SK" 'Send the developer a feedback brief (`Source: lead`) quoting the refusal'
has ac8-exit1-logged-refused "$SK" 'log the row with `Result` `refused`'
has ac8-exit2-no-pr "$SK" 'Exit 2: do not open the PR'
has ac8-refusal-in-stage-log-format "$HA" 'A refused *Open PR* (bump check) is an `Open PR` row with `Result` `refused`'
# every instruction that opens a PR must run the check first. PR-opening lines, outside the check's own paragraph:
pr_lines="$(grep -nE 'gh pr create|[Oo]pen (one |the )?PR' "$SK" | grep -vE 'check-bump|do not open the PR|opens a PR without this check|Open the PR \(\*Open PR\*\)|Exit 0: open the PR|run \*Open PR\* again|merged on its own PR|has its own branch and one PR')"
if [ -z "$pr_lines" ]; then ck ac8-no-pr-without-check "" ""
else skip ac8-no-pr-without-check "QA-39 F1: PR opened without the bump check at SKILL.md:$(printf '%s' "$pr_lines" | cut -d: -f1 | tr '\n' ' ')(frontier round end) (developer)"; fi
# the tracker patch's Open PR bullet is the command the check guards
has ac8-tracker-open-pr "$TP" '- **Open PR**: `gh pr create --head item/<id>'

# --- AC-11: stage log
has ac11-in-lead-state "$HA" '`work/<id>/00-lead-state.md`'
has ac11-date-u "$HA" 'Times are always taken from `date -u +%FT%TZ` at the moment, never estimated afterwards'
has ac11-columns "$HA" '| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |'
has ac11-feedback-rounds "$HA" 'A feedback round is its own row with ` (round <n>)` appended'
has ac11-acceptance-demo-stage "$HA" '`Acceptance demo`, `Delivery`'
has ac11-waits-kinds "$HA" '| Id | Kind | Start (UTC) | End (UTC) | Held item | What |'
has ac11-limits-wait "$HA" '`limits` from a role'"'"'s failure notice'
has ac11-touches "$HA" '| Time (UTC) | Kind | What |'
has ac11-as-it-happens "$SK" 'Every wait goes to `## Waits` and every touch the person makes to `## Person'"'"'s touches`, as it happens'
has ac11-skill-stamps-each-stage "$SK" '1. Stamp `date -u +%FT%TZ` and open the stage'"'"'s row in the stage log.'
has ac11-skill-close-row-peak "$SK" 'close the row, with the agent ids and the completion notice'"'"'s peak context'
has ac11-interruption-limits-wait "$SK" 'open a `limits` wait in `## Waits`'

# --- AC-13: cross-check written in, before posting
has ac13-git-evidence "$HA" "git log item/<id> --format='%cI %s'"
has ac13-tracker-evidence "$HA" '.created_at, (.body | split("\n")[0])'
has ac13-largest-gap "$HA" 'names the largest gap across rows'
before ac13-cross-check-before-post "$SK" '2. Cross-check the stage log against git and the tracker' '4. Fill the hansei template'

# --- AC-14: marker, header, seven measures in fixed order
ck ac14-marker-first-line '<!-- factory:hansei v1 -->' "$(printf '%s\n' "$TEMPLATE" | sed -n 1p)"
ck ac14-marker-regex-matches 1 "$(printf '%s\n' "$TEMPLATE" | sed -n 1p | grep -Ec '^<!-- factory:hansei v([0-9]+) -->$')"
has ac14-find-hansei-op "$TP" "select(.body | startswith(\"<!-- factory:hansei v\")) | .id"
for k in '- plugin: factory <semver>' '- standard: <64 hex>' '- tooling: <64 hex>' '- active overrides: <none | name (since YYYY-MM-DD); …>' '- stage-log cross-check: largest gap <N>m (<row>: <evidence>)'; do
  ck "ac14-header '${k%%:*}'" 1 "$(printf '%s\n' "$TEMPLATE" | grep -cxF -- "$k")"
done
ck ac14-seven-measures-in-order "1. lead time|2. first-pass yield|3. rework|4. escaped defects|5. tokens|6. person's touches|7. doors" \
  "$(printf '%s\n' "$TEMPLATE" | grep -E '^[1-7]\. ' | cut -d: -f1 | paste -sd'|' -)"
has ac14-overrides-none "$HA" '`none` when the project'"'"'s `docs/agents/factory.md` has no `## Overrides` section or it lists none'
# the worked example follows the template's line keys in the same order
EXAMPLE="$(block_after "$HA" '### Worked example')"
keys() { sed -E 's/^(<!--[^>]*-->|## Hansei:|- [a-z -]+:|[1-7]\. [a-z'"'"' -]+:|   - [a-z-]+:).*/\1/' | grep -vE '^$|^   - <|^   - [A-Z]'; }
ck ac14-example-matches-template "$(printf '%s\n' "$TEMPLATE" | keys)" "$(printf '%s\n' "$EXAMPLE" | keys)"
ck ac14-example-marker '<!-- factory:hansei v1 -->' "$(printf '%s\n' "$EXAMPLE" | sed -n 1p)"

# --- AC-15: each measure says what is counted and where it is read
MT="$(awk '/^### Measures$/ {f=1; next} f && /^\| [1-7] \|/ {print} f && /^Token script exits/ {exit}' "$HA")"
ck ac15-seven-rows 7 "$(printf '%s\n' "$MT" | grep -c .)"
ck ac15-every-row-has-counted-and-source 7 "$(printf '%s\n' "$MT" | awk -F'|' 'NF>=6 && length($4)>10 && length($5)>3 {n++} END {print n+0}')"
has ac15-m1-split "$HA" '**agent working** = total − both waits, so the three parts add up to the total'
has ac15-m2-na "$HA" '`n/a (did not run)` when the stage was skipped'
has ac15-m3-overturned "$HA" 'two-way decisions overturned by a `Source: lead` feedback brief'
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
# lead time: 11:40Z -> 16:13Z = 273m = 4h33m; held person W1 31m + W3 20m = 51m; limits W2 15m; working 273-51-15 = 207 = 3h27m
has example-lead-time "$HA" '1. lead time: total 4h33m; agent working 3h27m; waiting for the person 51m; waiting on limits 15m'
ck example-arithmetic "273 51 15 207" "$(( (16*60+13)-(11*60+40) )) $(( (12*60+41-12*60-10) + (16*60+13-15*60-53) )) $(( 13*60+20-13*60-5 )) $(( 273-51-15 ))"
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
# stage-log example durations = End - Start
SL="$(awk '/^## Stage log$/ {f++} f==2 && /^\| [0-9]+ \|/ {print}' "$HA")"
bad=0
while IFS='|' read -r _ n st ro ag s e d _rest; do
  sm=$(( 10#$(echo "$s" | sed -E 's/.*T([0-9]{2}):.*/\1/')*60 + 10#$(echo "$s" | sed -E 's/.*T[0-9]{2}:([0-9]{2})Z.*/\1/') ))
  em=$(( 10#$(echo "$e" | sed -E 's/.*T([0-9]{2}):.*/\1/')*60 + 10#$(echo "$e" | sed -E 's/.*T[0-9]{2}:([0-9]{2})Z.*/\1/') ))
  m=$((em - sm)); if [ $m -ge 60 ]; then want="$((m / 60))h$(printf '%02d' $((m % 60)))m"; else want="${m}m"; fi
  [ "$(echo $d)" = "$want" ] || { bad=$((bad + 1)); echo "     row$n: $d vs $want"; }
done <<EOT
$SL
EOT
ck example-stage-durations "0 11" "$bad $(printf '%s\n' "$SL" | grep -c .)"

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
before ac20-feedback-issue-in-step9 "$SK" '## 9. Offer factory feedback' 'gh issue create --repo WimSuenens/agent-plugins'
for w in 'the problem in factory terms' 'the standard change' 'before/after numbers against the baseline with item count and release' 'no code, no project names, no business content, and no raw hansei records'; do
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
inline_before merge-recheck-before-merge "$MP" 'First re-run the bump check' 'Exit 0: `gh pr merge <branch> --merge`'
has merge-recheck-fetch-and-script "$TP" 'First re-run the bump check: `git fetch origin main`, then `bash "<plugin root>/scripts/check-bump.sh"` in the branch'"'"'s worktree'
has merge-recheck-refuse-no-merge "$TP" 'Exit 1 or 2: do not merge'
ck merge-pr-no-literal-var 0 "$(printf '%s' "$MP" | grep -cF '${CLAUDE_PLUGIN_ROOT}')"
inline_before tag-semver-before-tag "$(grep -F 'tag only when it is MAJOR.MINOR.PATCH' "$TP")" 'tag only when it is MAJOR.MINOR.PATCH' 'git tag factory-v<version>'
# the tag check must be the contract's semver (no leading zeros); pull the regex out of the patch and run it
RX="$(grep -oE "grep -Eq '[^']+'" "$TP" | head -1 | sed -E "s/^grep -Eq '//; s/'$//")"
ck tag-regex-present 1 "$([ -n "$RX" ] && echo 1)"
okc=0; for v in 1.0.0 0.0.0 10.20.30; do printf '%s' "$v" | grep -Eq "$RX" && okc=$((okc + 1)); done; ck tag-regex-accepts-semver 3 $okc
badc=0; for v in 1.0 v1.0.0 1.0.0-rc1 '1.0.0 x'; do printf '%s' "$v" | grep -Eq "$RX" || badc=$((badc + 1)); done; ck tag-regex-rejects-non-semver 4 $badc
lz=0; for v in 1.08.0 01.0.0 1.0.00; do printf '%s' "$v" | grep -Eq "$RX" || lz=$((lz + 1)); done
ck tag-regex-rejects-leading-zeros 3 $lz   # QA-39 F5, fixed in 9ee1cdc
# SKILL.md step 7 sends the merge through Merge PR (which holds the re-check)
has merge-through-merge-pr "$SK" '7. Merge the PR and remove the worktree and branch (*Merge PR*'
has frontier-merge-through-merge-pr "$SK" 'merge the PR to main and clean up (*Merge PR*)'
has frontier-pr-bump-check "$SK" '2. Run the *Open PR* bump check (`git fetch origin main`, then `check-bump.sh` in the round'"'"'s worktree) with the same exit handling as in step 6, then open one PR from `frontier/<map>`'

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

# --- AC-7 support: the tag step exists in Merge PR
has ac7-tag-in-merge-pr "$TP" 'git tag factory-v<version> "$(gh pr view <branch> --json mergeCommit --jq .mergeCommit.oid)"'

done_
