#!/bin/bash
# Slice 64, round 2: the rows for the contract text of feedback round 13 (path grammar, case folding, overlap rule 3, the review diff command,
# rule 5.6, scan scope, canary, needs-you places, brief check, exit 6 rows of AC-39, the --name-only search) and the map of security's findings S1 to S8.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
PS="$SCRIPTS/paths.sh"; PT="$SCRIPTS/post-text.sh"
RUN="$(run_all_file)"; OPS="$PLUGIN/skills/setup-factory-skill/references/issue-tracker-github.factory.md"
UD="Us""ers"; GH="gh""p_"; TOK="abcdefghijklmnopqrstuvwxyz0123456789"
fake_setup; cd "$T" || exit 1
lf() { local n="$1" sh="$2"; shift 2; { echo "# t"; echo; echo "Paths:"; for p in "$@"; do echo "- $p"; done; echo "shared: $sh"; } >"$T/$n"; }

# ---------- path grammar (S2) ----------
for bad in "p//q/x.md" "p/./q/x.md" "p/../q" "./p" "/p" "p/." "p/.." ".." "." "p//"; do
  lf g.md none "$bad"; bash "$PS" list "$T/g.md" >/dev/null 2>&1; ck "r2-grammar-malformed-exit-3 [$bad]" 3 "$?"
done
for good in "p/q/" "p/q/x.md" "p/.hidden/x" "p/..x/y" "a-b/c_d.e/"; do
  lf g.md none "$good"; bash "$PS" list "$T/g.md" >/dev/null 2>&1; ck "r2-grammar-ok-exit-0 [$good]" 0 "$?"
done
# a directory entry without its slash: a warning, not a rejection, only where the directory exists
mkdir -p "$T/wd/realdir"; lf g.md none "realdir"
( cd "$T/wd" && bash "$PS" list "$T/g.md" >"$T/o.out" 2>"$T/o.err" ); ck r2-dir-without-slash-exit-0 0 "$?"
ck r2-dir-without-slash-warns-on-stderr 1 "$([ -s "$T/o.err" ] && echo 1 || echo 0)"
ck r2-dir-without-slash-still-listed "path realdir" "$(cat "$T/o.out")"
lf g.md none "nodir"; ( cd "$T/wd" && bash "$PS" list "$T/g.md" >/dev/null 2>"$T/o.err" ); ck r2-no-such-directory-no-warning "" "$(cat "$T/o.err")"
# list prints entries as written, not folded
lf g.md none "A/B.md"; ck r2-list-prints-as-written "path A/B.md" "$(bash "$PS" list "$T/g.md")"

# ---------- case folding (S2) ----------
ov() { lf a.md "$2" $3; lf b.md "$4" $5; bash "$PS" overlap "$T/a.md" -- "$T/b.md" >"$T/ov.out" 2>&1; ck "$1-exit" "$6" "$?"; }
ov r2-fold-dir-vs-file 'none' 'A/b.md' 'none' 'a/' 1
ov r2-fold-equal-files 'none' 'A/B.md' 'none' 'a/b.md' 1
ov r2-fold-non-ascii-compares-exactly 'none' 'é/' 'none' 'É/x' 0
ov r2-fold-still-not-a-prefix 'none' 'Plugins/factory/' 'none' 'plugins/factory-x/a.md' 0
lf c.md none "a/b.md"
ck r2-check-folds-names "" "$(printf 'A/B.md\n' | bash "$PS" check "$T/c.md")"
ck r2-check-folds-under-a-dir "" "$(lf c.md none 'a/'; printf 'A/Sub/x.md\n' | bash "$PS" check "$T/c.md")"
ck r2-check-ignore-prefix-folds "" "$(lf c.md none 'x/'; printf 'WORK/64/a.md\n' | bash "$PS" check --ignore work/64/ "$T/c.md")"
ck r2-check-still-reports-others "off-list: other/y.md" "$(lf c.md none 'x/'; printf 'other/y.md\n' | bash "$PS" check --ignore work/64/ "$T/c.md")"

# ---------- overlap rule 3 (S8) ----------
lf a.md none "plugins/factory/" "x/"; lf b.md "plugins/factory/.claude-plugin/plugin.json" "b/"
ck r2-rule3-prefix-of-shared-output "overlap: yes plugins/factory/ plugins/factory/.claude-plugin/plugin.json" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
ck r2-rule3-exit-1 1 "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md" >/dev/null; echo $?)"
lf a.md none "CHANGELOG.md"; lf b.md "CHANGELOG.md" "b/"
ck r2-rule3-equal-output "overlap: yes CHANGELOG.md CHANGELOG.md" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
bash "$PS" overlap "$T/b.md" -- "$T/a.md" >/dev/null; ck r2-rule3-other-order-exit-1 1 "$?"
lf a.md none "a/"; lf b.md "adr-number" "b/"; ck r2-rule3-adr-number-is-not-a-path "overlap: no" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
lf a.md "CHANGELOG.md" "a/"; lf b.md none "a/x.md"; ck r2-rule1-still-first "overlap: yes a/ a/x.md" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
lf a.md "CHANGELOG.md" "a/"; lf b.md "CHANGELOG.md" "b/"; ck r2-rule2-still-shared-form "overlap: yes shared CHANGELOG.md" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
# one list's own paths and shared are never compared with each other
lf a.md "CHANGELOG.md" "CHANGELOG.md"; lf b.md none "z/"; ck r2-own-paths-and-shared-not-compared "overlap: no" "$(bash "$PS" overlap "$T/a.md" -- "$T/b.md")"
# the shared entry is a version file under a directory the other slice owns (the case the rule is for)
lf a.md none "plugins/factory/"; lf b.md "plugins/factory/.claude-plugin/plugin.json" "docs/"; bash "$PS" overlap "$T/a.md" -- "$T/b.md" >/dev/null; ck r2-owner-of-dir-collides-with-version-bump 1 "$?"
# the run text states the rule the script applies (AC-28: a rule that cannot yield the table is a defect)
if grep -qi 'case' <(awk '/^\*\*Overlap\.\*\*/{print}' "$RUN") && grep -qiE 'shared entry|rule 3|shared:.*prefix' <(awk '/^\*\*Overlap\.\*\*/{print}' "$RUN"); then ck r2-run-text-states-folding-and-rule-3 1 1
else skip r2-run-text-states-folding-and-rule-3 "QA finding F7: the run skill's Overlap paragraph states rules 1 and 2 only, case-sensitively; paths.sh also folds ASCII case and applies rule 3, so the text cannot yield the contract's new table rows (AC-28)"; fi

# ---------- the review diff command (S1) ----------
R="$T/mv"; mkdir -p "$R" && cd "$R" && git init -q -b main . 2>/dev/null; mkdir -p a b; echo g >b/g; echo h >b/h.md; echo base >README.md
git add -A && git commit -qm base; git clone -q "$R" "$T/mv2" && cd "$T/mv2" && git checkout -q -b item/9
mkdir -p contracts a b c; printf '# t\n\nPaths:\n- a/\n- contracts/\nshared: none\n' >contracts/9-a.md
git mv b/g a/g; git rm -q b/h.md; mkdir -p a b c; printf 'x\n' >"a/é.txt"; printf 'y\n' >"b/é.txt"; printf 'z\n' >"c/ünï.md"; git add -A; git commit -qm change; git fetch -q origin main 2>/dev/null
D() { git -c core.quotePath=false diff --no-renames --name-only origin/main...item/9; }
ck r2-diff-lists-both-names-of-a-move "yes" "$(D | grep -qx 'a/g' && D | grep -qx 'b/g' && echo yes || echo no)"
ck r2-old-command-lists-only-the-new-name "no" "$(git diff --name-only origin/main...item/9 | grep -qx 'b/g' && echo yes || echo no)"
ck r2-diff-lists-the-deleted-off-list-file "yes" "$(D | grep -qx 'b/h.md' && echo yes || echo no)"
out="$(D | bash "$PS" check contracts/9-*.md)"
case "$out" in *"off-list: b/g"*) r=1 ;; *) r=0 ;; esac; ck r2-moved-off-list-source-is-reported 1 "$r"
case "$out" in *"off-list: b/h.md"*) r=1 ;; *) r=0 ;; esac; ck r2-deleted-off-list-file-is-reported 1 "$r"
ck r2-non-ascii-on-list-no-finding 0 "$(printf '%s\n' "$out" | grep -c 'a/é.txt')"
ck r2-non-ascii-off-list-printed-unquoted 1 "$(printf '%s\n' "$out" | grep -cx 'off-list: b/é.txt')"
ck r2-non-ascii-off-list-dir-printed-unquoted 1 "$(printf '%s\n' "$out" | grep -cx 'off-list: c/ünï.md')"
ck r2-quoted-form-would-have-been-wrong "yes" "$(git diff --no-renames --name-only origin/main...item/9 | grep -q '^"' && echo yes || echo no)"
cd "$T" || exit 1
# the command is the same text in every place it appears; the --name-only search finds only the intended forms
for f in "$PLUGIN/agents/qa-engineer.md" "$PLUGIN/agents/security-reviewer.md" "$RUN" "$REPO/plugins/wayfinding/skills/wayfinder/SKILL.md"; do
  has "r2-two-option-form-in-$(basename "$(dirname "$f")")-$(basename "$f")" "$f" 'git -c core.quotePath=false diff --no-renames --name-only'
done
bad="$(cd "$REPO" && grep -rn -- '--name-only' plugins | grep -v 'git -c core.quotePath=false diff --no-renames --name-only' | grep -v 'plugins/factory/scripts/check-bump.sh' | grep -v 'diff-tree -z --no-commit-id --name-only -r --no-renames' | grep -v '^plugins/toolkit' | wc -l | tr -d ' ')"
ck r2-name-only-only-the-intended-forms 0 "$bad"
ck r2-check-bump-uses-the-z-form "yes" "$(grep -q 'diff -z --no-renames --name-only' "$REPO/scripts/check-bump.sh" && echo yes || echo no)"

# ---------- rule 5.6 on run-budget and factory-state (S7) ----------
has r2-rule-5-6-names-both-lines "$RUN" 'or a line that starts at column 0 with `run-budget:` or `factory-state:` (a line changed, added or removed; compare before and after the commit; any difference counts)'
has r2-rule-5-6-lead-exception "$RUN" 'unless both hold: the subject starts `#<id> lead: `'
# the comparison the rule asks for, run on a scratch repo: a developer commit that changes the limit differs before and after; a commit on another line does not
G="$T/r56"; mkdir -p "$G" && cd "$G" && git init -q -b main . 2>/dev/null
printf 'factory-state: 2\n\n# Factory\n\n## Parallel slices\n\nrun-budget: 2\n\nother text\n' >factory.md; git add -A; git commit -qm base
line_changes() { git diff "$1^" "$1" -- factory.md | grep -cE '^[+-](run-budget:|factory-state:)'; }
sed -i.bak 's/run-budget: 2/run-budget: 9/' factory.md; rm -f factory.bak; git commit -qam "#12 developer: raise the limit"; ck r2-5-6-limit-change-is-seen 2 "$(line_changes HEAD)"
sed -i.bak 's/^factory-state: 2/factory-state: 1/' factory.md; rm -f factory.bak; git commit -qam "#12 developer: edit line 1"; ck r2-5-6-state-change-is-seen 2 "$(line_changes HEAD)"
sed -i.bak 's/other text/other words/' factory.md; rm -f factory.bak; git commit -qam "#12 developer: prose"; ck r2-5-6-other-change-not-flagged 0 "$(line_changes HEAD)"
printf 'run-budget: 3\n' >>factory.md; git commit -qam "#12 developer: add a second line"; ck r2-5-6-added-line-is-seen 1 "$(line_changes HEAD)"
cd "$T" || exit 1

# ---------- scan scope (S3), S4 ----------
for k in "role-task titles" "the **ledger** (the post and every edit)" "**stage summaries**" "the **hansei record** (post and edit)" "**andon comments**" "**task requests**" "decision cards" "the A3 and the baseline (post and edit)" "the run-close texts"; do
  has "r2-scan-scope-names-$k" "$RUN" "$k"
done
has r2-scan-scope-no-exception "$RUN" 'with no exception by kind'
has r2-scan-title-as-one-line-file "$RUN" 'a title as a one-line file'
has r2-scan-exit-2-posts-nothing "$RUN" 'Exit 2 (usage, an unreadable file, or `self-check failed`): post nothing and tell the person; a scan that cannot find its own canary never reads as clean.'
has r2-scan-every-posting-op-points-here "$RUN" 'Every `T-create`, `T-comment`, `T-edit-comment`, stage summary, task request and hansei post or edit in this skill points here.'
ck r2-ops-list-no-body-in-quotes 0 "$(grep -c -- '--body "' "$OPS")"
ck r2-run-text-no-body-in-quotes 0 "$(grep -c -- '--body "' "$RUN")"
has r2-ops-stage-summary-body-file "$OPS" '**Stage summary**'
ck r2-stage-summary-uses-body-file 1 "$(grep -- '- \*\*Stage summary\*\*' "$OPS" | grep -c -- '--body-file')"
ck r2-task-request-uses-body-file 1 "$(grep -- '- \*\*Task request\*\*' "$OPS" | grep -c -- '--body-file')"
ck r2-ops-list-title-from-variable 1 "$([ "$(grep -c -- '--title "\$title"' "$OPS")" -ge 1 ] && echo 1 || echo 0)"
ck r2-ops-list-no-literal-title-text 0 "$(grep -c -- '--title "<title>"' "$OPS")"
# the fake: a posting call is not made when the text holds a token (the lead's order is scan, then post; the scan result is what decides)
for kind in "rework title" "ledger edit" "stage summary" "hansei record" "andon comment" "task request"; do
  printf 'text for the %s: %s%s\n' "$kind" "$GH" "$TOK" >"$T/post.md"
  bash "$PT" scan "$T/post.md" >/dev/null; rc=$?; ck "r2-scan-stops-the-post [$kind]" 1 "$rc"
  printf 'text for the %s: nothing secret\n' "$kind" >"$T/post.md"; bash "$PT" scan "$T/post.md"; ck "r2-clean-text-posts [$kind]" 0 "$?"
done

# ---------- secret patterns, boundary, the new tokens, the ADR file name (S6, F1) ----------
adr="0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md"
printf '%s\n' "$adr" >"$T/s.md"; bash "$PT" scan "$T/s.md" >/dev/null; ck r2-adr-0014-file-name-bare-exit-0 0 "$?"
printf '[ADR 0014](docs/adr/%s)\n' "$adr" >"$T/s.md"; bash "$PT" scan "$T/s.md" >/dev/null; ck r2-adr-0014-in-a-link-exit-0 0 "$?"
for w in "disk-usage-report-for-the-whole-machine" "risk-assessment-for-the-new-release-plan" "a ris""k-based-approach-to-testing-things" "tas""k-description-for-the-build-step"; do
  printf '%s\n' "$w" >"$T/s.md"; bash "$PT" scan "$T/s.md" >/dev/null; ck "r2-ordinary-word-exit-0 [$w]" 0 "$?"
done
hit() { printf '%s\n' "$2" >"$T/s.md"; bash "$PT" scan "$T/s.md" >/dev/null; ck "r2-token-hit [$1]" 1 "$?"; }
N20="aaaaaaaaaaaaaaaaaaaaaaaaa"
hit github-ghp "x ${GH}${N20}"; hit github-ghu "gh""u_${N20}"; hit github-ghr "gh""r_${N20}"; hit github-pat "github""_pat_${N20}"
hit aws "AK""IAABCDEFGHIJKLMNOP"; hit slack "xo""xb-${N20}"; hit openai "s""k-${N20}"; hit google "AI""zaAbCdEfGhIjKlMnOpQrStUvWxYz012345678"
hit npm "np""m_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789"; hit gitlab "glp""at-${N20}"; hit jwt "ey""Jaaaaaaaaaaa.ey""Jaaaaaaaaaaa.aaaaaaaaaaaa"
hit private-key "-----BEGIN ""EC PRIVATE KEY-----"; hit bearer "Bear""er ${N20}"
hit after-equals "TOKEN=s""k-${N20}"; hit after-quote "\"s""k-${N20}\""; hit start-of-line "s""k-${N20}"; hit in-a-url "https://x.test/?k=${GH}${N20}"
# mawk-safety: a grep that does not know intervals makes the canary fail, so the scan exits 2 instead of reading clean
mkdir -p "$T/shim"; cat >"$T/shim/grep" <<'S'
#!/bin/bash
# a grep whose {n,} intervals are literal text: strip them from the pattern before matching
args=(); for a in "$@"; do args[${#args[@]}]="$(printf '%s' "$a" | sed -E 's/\{[0-9]+(,[0-9]*)?\}/{LITERAL}/g')"; done
exec /usr/bin/grep "${args[@]}"
S
chmod +x "$T/shim/grep"; [ -x /usr/bin/grep ] || skip r2-canary-shim "no /usr/bin/grep here"
printf 'clean\n' >"$T/s.md"
PATH="$T/shim:$PATH" bash "$PT" scan "$T/s.md" >"$T/c.out" 2>"$T/c.err"; ck r2-canary-intervals-unsupported-exit-2 2 "$?"
case "$(cat "$T/c.err")" in "scan: self-check failed ("*")") r=1 ;; *) r=0 ;; esac; ck r2-canary-message-on-stderr 1 "$r"
ck r2-canary-failure-prints-nothing-on-stdout "" "$(cat "$T/c.out")"
printf 'x %s%s y\n' "$GH" "$TOK" >"$T/s.md"; PATH="$T/shim:$PATH" bash "$PT" scan "$T/s.md" >/dev/null 2>&1; ck r2-canary-a-token-never-reads-clean-without-intervals 2 "$?"
bash "$PT" scan "$T/s.md" >/dev/null 2>&1; ck r2-canary-normal-grep-still-hits 1 "$?"
# the script itself is no scan hit (patterns and canaries are assembled from halves), and holds no awk interval
bash "$PT" scan "$PT" >/dev/null; ck r2-post-text-sh-is-not-a-scan-hit 0 "$?"
ck r2-post-text-sh-no-awk-intervals 0 "$(grep -n 'awk' "$PT" | grep -cE '\{[0-9]+,?[0-9]*\}')"

# ---------- --needs-you places ----------
ny() { printf '%s\n' "$2" >"$T/n.md"; bash "$PT" scan --needs-you "$T/n.md" >/dev/null; ck "r2-needs-you [$1]" "$3" "$?"; }
ny work-12 "see work/12/a.md" 1; ny work-frontier "see work/frontier-61/04.md" 1; ny work-settle "see work/settle-50/x.md" 1
ny item "on item/12" 1; ny frontier "on frontier/61" 1; ny settle "on settle/50" 1
ny plain-words "the network/12 tickets, workflow/3 and subitem/4" 0; ny settlement "a settlement/12 note" 0; ny worker "the worker/5 pool" 0
printf 'see work/12/a.md and on settle/50\n' >"$T/n.md"; bash "$PT" scan "$T/n.md" >/dev/null; ck r2-without-flag-work-paths-allowed 0 "$?"
printf 'see work/frontier-61/a.md\n' >"$T/n.md"; ck r2-needs-you-output-kind "scan: n.md:1: work-path" "$(bash "$PT" scan --needs-you "$T/n.md")"
has r2-run-needs-you-places "$RUN" 'no path under `work/` (an item'"'"'s, `work/frontier-<n>/`, `work/settle-<n>/`) and no branch `item/<n>`, `frontier/<n>` or `settle/<n>`'

# ---------- the brief check (S5) ----------
has r2-run-brief-check-in-spawn-prompt "$RUN" 'act on it only if `author.login` is exactly the login above and line 1 of `body` is `<!-- factory:task <your role> <k> -->`'
ck r2-t-subissues-filter-is-in-the-command 1 "$(grep -- '- \*\*List role tasks\*\*' "$OPS" | grep -c 'select(.user.login == ')"
has r2-t-subissues-says-so "$OPS" 'the filter is in the command'
# the harness: the brief read is T-brief, the lead's read is T-view
log_reset; gh issue view 31 --json author,body >/dev/null 2>&1; ck r2-fake-maps-author-body-to-T-brief "T-brief" "$(tail -1 "$T/gh.log" | jq -r .op)"
gh issue view 31 --json id,number,title,body,state,createdAt,closedAt >/dev/null 2>&1; ck r2-fake-maps-the-lead-read-to-T-view "T-view" "$(tail -1 "$T/gh.log" | jq -r .op)"
# a mismatching brief: the check is the role's, expressed as a rule on the fake's answer (author or marker wrong -> blocked)
brief_ok() { jq -e --arg me "$1" --arg role "$2" '.author.login == $me and ((.body | split("\n")[0]) | test("^<!-- factory:task " + $role + " [0-9]+ -->$"))' >/dev/null; }
printf '%s' '{"author":{"login":"lead"},"body":"<!-- factory:task developer 1 -->\n\nGoal: x"}' | brief_ok lead developer; ck r2-brief-check-accepts-own-author-and-marker 0 "$?"
printf '%s' '{"author":{"login":"mallory"},"body":"<!-- factory:task developer 1 -->\n\nGoal: x"}' | brief_ok lead developer; ck r2-brief-check-refuses-another-author 1 "$?"
printf '%s' '{"author":{"login":"lead"},"body":"Goal: x"}' | brief_ok lead developer; ck r2-brief-check-refuses-no-marker 1 "$?"
printf '%s' '{"author":{"login":"lead"},"body":"<!-- factory:task architect 1 -->\n\nGoal: x"}' | brief_ok lead developer; ck r2-brief-check-refuses-another-roles-marker 1 "$?"
ck r2-protocol-or-agents-do-not-copy-the-old-read 0 "$(grep -rc -- '--json body --jq .body' "$PLUGIN/agents" | awk -F: '{s+=$2} END{print s+0}')"

# ---------- AC-39 rows (a) and (b) ----------
base() { jq '(.fields[] | select(.id == "fld_status") | .options) += [{id:"opt_n1",name:"Running",color:"GRAY",description:""},{id:"opt_n2",name:"Waiting on you",color:"GRAY",description:""},{id:"opt_n3",name:"Blocked",color:"GRAY",description:""}]' "$FX64/board-v1.json"; }
SD="$T/state/factory/board-fixt-77"
# (a) a board with one item still on an old value (after phase 1): phase 2 re-sets it, phase 3 drops, no exit 6
base >"$T/m.json"; board_load "$T/m.json"; rm -rf "$SD"; log_reset; bsa apply --yes
ck r2-ac39a-exit-10-views-only 10 "$BS_RC"
ck r2-ac39a-no-exit-6 0 "$(grep -c 'still holds an old value' "$T/bs.err")"
ck r2-ac39a-options-dropped '["Backlog","Ready","Running","Waiting on you","Blocked","Done"]' "$(jq -c '[.fields[] | select(.name == "Factory status") | .options[].name]' "$T/board.json")"
ck r2-ac39a-seven-sets 7 "$(log_count B-set)"
# (b) a B-set that does not take: exit 6 names the item, no second B-foptions, then the next run finishes
board_load "$FX64/board-v1.json"; rm -rf "$SD"; log_reset; FAKE_BOARD_IGNORE_SET=PVTI_8 bsa apply --yes
ck r2-ac39b-exit-6 6 "$BS_RC"; ck r2-ac39b-one-foptions 1 "$(log_count B-foptions)"
has r2-ac39b-names-the-item "$T/bs.err" "#108"
unset FAKE_BOARD_IGNORE_SET; log_reset; bsa apply --yes; ck r2-ac39b-next-run-completes 10 "$BS_RC"
has r2-board-script-contract-exit-6-text "$REPO/contracts/64-board-script.md" 'a `B-set` did not take'

# ---------- the map of security's findings S1 to S8 ----------
# S1 rename: r2-diff-lists-both-names-of-a-move, r2-moved-off-list-source-is-reported.  S2 path spellings: r2-grammar-*, r2-fold-*.
# S3 scan scope: r2-scan-scope-*.  S4 stage summary body: r2-ops-list-no-body-in-quotes, r2-stage-summary-uses-body-file.
# S5 author filter and brief check: r2-t-subissues-*, r2-brief-check-*, ac16-agent-*-checks-author.  S6 patterns, mawk: r2-token-hit, r2-canary-*.
# S7 rule 5.6: r2-5-6-*.  S8 shared against paths: r2-rule3-*.
# ---------- round 3: the restated statements of the path grammar and of the overlap rule ----------
has r3-run-overlap-states-rule-3 "$RUN" 'or a path in one list equals a `shared:` entry of the other list or is a directory prefix of it (rule 3: `adr-number` is not a path and takes no part)'
has r3-run-overlap-states-case-folding "$RUN" 'Names are compared character for character, ASCII case folded (`A/b.md` and `a/` overlap).'
has r3-run-overlap-keeps-rules-1-and-2 "$RUN" 'or their `shared:` lines both name the same entry'
has r3-run-path-list-states-the-grammar "$RUN" 'no empty, `.` or `..` component: `paths.sh` exits 3 on one; a directory ends in `/`, and a directory written without it is read as a file, with a warning on stderr'
has r3-architect-states-the-grammar "$PLUGIN/agents/architect.md" 'no empty, `.` or `..` component, which `paths.sh` rejects; a directory without its slash is read as a file'
# the paragraph yields the table rows it must (AC-28): each row answered by the script and named by the text
lf a.md none "A/b.md"; lf b.md none "a/"; bash "$PS" overlap "$T/a.md" -- "$T/b.md" >/dev/null; ck r3-ac28-folded-row-yes 1 "$?"
lf a.md none "plugins/factory/"; lf b.md "plugins/factory/.claude-plugin/plugin.json" "b/"; bash "$PS" overlap "$T/a.md" -- "$T/b.md" >/dev/null; ck r3-ac28-rule-3-row-yes 1 "$?"
lf a.md none "a/"; lf b.md "adr-number" "b/"; bash "$PS" overlap "$T/a.md" -- "$T/b.md" >/dev/null; ck r3-ac28-adr-number-row-no 0 "$?"
echo "info S1..S8 each map to the tests named in the comment block of test_round2_64.sh"
done_
