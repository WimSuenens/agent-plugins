#!/bin/bash
# #207 slice 3: the setup scan and the flow table (item 1), the `state` gate and `table` (item 2), the `ci:` line and the gate (item 3),
# the shipped text (the setup skill, the run skill's one line, baseline.md). Written before the scripts and text it tests.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
CFG="$PLUGIN/scripts/factory-config.sh"
ST="$PLUGIN/scripts/setup-table.sh"
MG="$PLUGIN/scripts/merge-gate.sh"
SETUP="$PLUGIN/skills/setup-factory-skill/SKILL.md"
RUN="$PLUGIN/skills/run/SKILL.md"
BASE="$PLUGIN/references/baseline.md"
TRIGGERS='Open one-way door|Unresolved research question|More than 3 expected slices|Protected area touched|Contract or interface used by others|New logic or data behaviour|Visual result|Deploy, pipeline or production config'
cd "$T" || exit 1

# a 2.x factory.md: line 1 and a few sections, no table
mk2x() { printf 'factory-state: 2\n\n# Factory\n\n## Decision-maker\n\ndecision-maker: technical\n\n## Run budget\n\nrun-budget: none\n' >"$1"; }

# --- item 2: the gate
mk2x "$T/f.md"
out="$(bash "$CFG" state "$T/f.md" 2>&1)"; code=$?
ck state-no-table-exit 6 "$code"
ck state-no-table-message "factory.md has no flow table: run setup-factory-skill" "$out"
printf 'no state line\n' >"$T/f3.md"; bash "$CFG" state "$T/f3.md" >/dev/null 2>&1; ck state-exit-3-kept $? 3
printf 'factory-state: 1\n\n## Flow table\n' >"$T/f4.md"; bash "$CFG" state "$T/f4.md" >/dev/null 2>&1; ck state-exit-4-kept $? 4
printf 'factory-state: 2\nrun-budget: x y\n' >"$T/f5.md"; bash "$CFG" budget "$T/f5.md" >/dev/null 2>&1; ck budget-exit-5-kept $? 5
bash "$CFG" table "$T/f.md" >/dev/null 2>&1; ck table-no-table-exit 6 $?
ck table-no-table-message "factory.md has no flow table: run setup-factory-skill" "$(bash "$CFG" table "$T/f.md" 2>&1 >/dev/null)"
# a heading alone, or a table with too few rows, is not a table
{ cat "$T/f.md"; printf '\n## Flow table\n\nfloor: x\n\n| Trigger | Points | Adds | Reason | Status |\n|---|---|---|---|---|\n| Open one-way door | 3 | card | r | provisional |\n'; } >"$T/f6.md"
bash "$CFG" state "$T/f6.md" >/dev/null 2>&1; ck state-partial-table-exit 6 $?
ck state-partial-table-message "factory.md has an incomplete flow table: run setup-factory-skill" "$(bash "$CFG" state "$T/f6.md" 2>&1 >/dev/null)"

# --- item 1: the scan
mkdir -p "$T/p1/.claude-plugin" "$T/p1/skills/x" "$T/p1/tests" "$T/p1/contracts" "$T/p1/docs"
echo '{"name":"x"}' >"$T/p1/.claude-plugin/plugin.json"; echo s >"$T/p1/skills/x/SKILL.md"; echo t >"$T/p1/tests/run.sh"; echo c >"$T/p1/contracts/a.md"
echo a >"$T/p1/docs/author.md"
scan() { out="$(bash "$ST" scan "$1" 2>"$T/err")"; code=$?; }
scan "$T/p1"
ck scan-plugin-exit 0 "$code"
ck scan-plugin-type "type: markdown/LLM plugin" "$(printf '%s\n' "$out" | grep '^type:')"
ck scan-plugin-test-command "test-command: bash tests/run.sh" "$(printf '%s\n' "$out" | grep '^test-command:')"
ck scan-plugin-ci-none "yes" "$(printf '%s\n' "$out" | grep -q '^ci: none (no workflow runs `bash tests/run.sh`)' && echo yes || echo no)"
ck scan-contracts-found "yes" "$(printf '%s\n' "$out" | grep '^contracts:' | grep -q 'contracts/' && echo yes || echo no)"
ck scan-author-not-protected "no" "$(printf '%s\n' "$out" | grep '^protected-candidates:' | grep -q 'author' && echo yes || echo no)"
ck scan-no-deploy "deploy: none" "$(printf '%s\n' "$out" | grep '^deploy:')"
ck scan-no-visual "visual: no" "$(printf '%s\n' "$out" | grep '^visual:')"

mkdir -p "$T/p2/src/auth" "$T/p2/db/migrations" "$T/p2/.github/workflows"
cat >"$T/p2/package.json" <<'J'
{"name":"app","scripts":{"test":"jest"}}
J
echo x >"$T/p2/src/auth/login.js"; echo x >"$T/p2/db/migrations/001.sql"; echo x >"$T/p2/Dockerfile"; echo '<p>' >"$T/p2/index.html"
printf 'on:\n  pull_request:\njobs:\n  t:\n    steps:\n      - run: npm test\n' >"$T/p2/.github/workflows/test.yml"
scan "$T/p2"
ck scan-app-type "type: code app" "$(printf '%s\n' "$out" | grep '^type:')"
ck scan-app-test-command "test-command: npm test" "$(printf '%s\n' "$out" | grep '^test-command:')"
ck scan-app-ci-workflow "ci: workflow .github/workflows/test.yml runs \`npm test\` on pull requests" "$(printf '%s\n' "$out" | grep '^ci:')"
ck scan-app-protected "yes" "$(printf '%s\n' "$out" | grep '^protected-candidates:' | grep -q 'src/auth/login.js' && printf '%s\n' "$out" | grep '^protected-candidates:' | grep -q 'db/migrations/001.sql' && echo yes || echo no)"
ck scan-app-deploy "yes" "$(printf '%s\n' "$out" | grep '^deploy:' | grep -q 'Dockerfile' && echo yes || echo no)"
ck scan-app-visual "yes" "$(printf '%s\n' "$out" | grep -q '^visual: yes' && echo yes || echo no)"
# a workflow that runs the tests but not on pull requests is not a CI for the gate
printf 'on:\n  push:\njobs:\n  t:\n    steps:\n      - run: npm test\n' >"$T/p2/.github/workflows/test.yml"
scan "$T/p2"
ck scan-workflow-without-pr "yes" "$(printf '%s\n' "$out" | grep -q '^ci: none (.*test.yml.*not on pull requests' && echo yes || echo no)"
# a workflow for something else does not count
printf 'on:\n  pull_request:\njobs:\n  t:\n    steps:\n      - run: docker build .\n' >"$T/p2/.github/workflows/test.yml"
scan "$T/p2"
ck scan-other-workflow-not-ci "yes" "$(printf '%s\n' "$out" | grep -q '^ci: none (no workflow runs `npm test`)' && echo yes || echo no)"
mkdir -p "$T/p3"; echo '{}' >"$T/p3/package.json"; echo 'x' >"$T/p3/astro.config.mjs"
scan "$T/p3"; ck scan-site-type "type: static site" "$(printf '%s\n' "$out" | grep '^type:')"
ck scan-site-visual "visual: yes" "$(printf '%s\n' "$out" | grep -o '^visual: yes')"
ck scan-no-test-command "test-command: none" "$(printf '%s\n' "$out" | grep '^test-command:')"
ck scan-no-test-command-ci "yes" "$(printf '%s\n' "$out" | grep -q '^ci: none (no test command found' && echo yes || echo no)"
bash "$ST" scan "$T/missing" >/dev/null 2>&1; ck scan-missing-dir-exit 2 $?

# --- item 1: the table is written once, as its own section, and nothing else changes
mk2x "$T/w.md"; cp "$T/w.md" "$T/w.orig"
out="$(bash "$ST" write --dir "$T/p1" --confirmed "at setup" "$T/w.md" 2>&1)"; code=$?
ck write-exit 0 "$code"
ck write-says-added "yes" "$(printf '%s\n' "$out" | grep -q '^added: flow table' && echo yes || echo no)"
n="$(wc -l <"$T/w.orig" | tr -d ' ')"
ck write-touches-no-other-line "yes" "$(head -n "$n" "$T/w.md" | cmp -s - "$T/w.orig" && echo yes || echo no)"
ck write-line-1-kept "factory-state: 2" "$(head -n 1 "$T/w.md")"
ck write-heading-once "1" "$(grep -c '^## Flow table$' "$T/w.md")"
for t in "Open one-way door" "Unresolved research question" "More than 3 expected slices" "Protected area touched" "Contract or interface used by others" "New logic or data behaviour" "Visual result" "Deploy, pipeline or production config"; do
  ck "row-$t" "1" "$(grep -c "^| $t" "$T/w.md")"
done
ck row-points "yes" "$(grep -q '^| Open one-way door[^|]*| 3 |' "$T/w.md" && grep -q '^| Visual result[^|]*| 1 |' "$T/w.md" && grep -q '^| Contract or interface used by others[^|]*| 2 |' "$T/w.md" && echo yes || echo no)"
ck rows-provisional "8" "$(grep -E "^\| ($TRIGGERS)" "$T/w.md" | grep -c '| provisional |$')"
ck rows-have-reasons "0" "$(grep -E "^\| ($TRIGGERS)" "$T/w.md" | awk -F'|' '{r=$5; gsub(/ /,"",r); if (r=="") n++} END{print n+0}')"
ck bands-line "bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more" "$(grep '^bands:' "$T/w.md")"
ck floor-line "yes" "$(grep '^floor:' "$T/w.md" | grep -q 'never removed by the table' && echo yes || echo no)"
ck test-depth-plugin "test-depth: proof-only" "$(grep '^test-depth:' "$T/w.md")"
ck project-type-line "project-type: markdown/LLM plugin" "$(grep '^project-type:' "$T/w.md")"
ck confirmed-line "confirmed: at setup" "$(grep '^confirmed:' "$T/w.md")"
ck table-status-line "table: provisional" "$(grep '^table:' "$T/w.md")"
ck write-contract-row-reason-from-scan "yes" "$(grep '^| Contract or interface' "$T/w.md" | grep -q 'contracts/' && echo yes || echo no)"
ck write-ci-line "yes" "$(grep -q '^ci: none (no workflow runs `bash tests/run.sh`)' "$T/w.md" && echo yes || echo no)"
bash "$CFG" state "$T/w.md" >/dev/null 2>&1; ck state-passes-after-write $? 0
ck table-prints-rows "8" "$(bash "$CFG" table "$T/w.md" | grep -cE "^\| ($TRIGGERS)")"
ck table-stops-at-next-section "0" "$(bash "$CFG" table "$T/w.md" | grep -c '^## ')"
# idempotent: a second run changes nothing
cp "$T/w.md" "$T/w.once"
out="$(bash "$ST" write --dir "$T/p1" --confirmed "at setup" "$T/w.md" 2>&1)"; code=$?
ck write-twice-exit 0 "$code"
ck write-twice-same-file "yes" "$(cmp -s "$T/w.md" "$T/w.once" && echo yes || echo no)"
ck write-twice-says-present "already present" "$out"
# a ci: line the project already has is kept
mk2x "$T/w2.md"; printf '\nci: workflow .github/workflows/t.yml runs `npm test` on pull requests\n' >>"$T/w2.md"
bash "$ST" write --dir "$T/p2" "$T/w2.md" >/dev/null 2>&1
ck write-keeps-own-ci-line "1" "$(grep -c '^ci:' "$T/w2.md")"
ck test-depth-app "test-depth: targeted" "$(grep '^test-depth:' "$T/w2.md")"
# the section goes after a file that does not end in a newline
printf 'factory-state: 2\n\n## Run budget\n\nrun-budget: none' >"$T/w3.md"
bash "$ST" write --dir "$T/p1" "$T/w3.md" >/dev/null 2>&1
ck write-no-final-newline-ok "1" "$(grep -c '^run-budget: none$' "$T/w3.md")"
bash "$ST" write --dir "$T/p1" "$T/nope.md" >/dev/null 2>&1; ck write-missing-file-exit 2 $?
# no name, label or release rule of a repository in the script
ck script-names-no-repo "0" "$(grep -ciE 'plugin:factory|WimSuenens|agent-plugins|factory-v|CHANGELOG' "$ST")"

# --- item 3: the gate and the ci: line
mkdir -p "$T/bin"
cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "pr view" ] && { cat "$PRJSON"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH"; export PRJSON="$T/pr.json"
HEAD40=0123456789abcdef0123456789abcdef01234567
pr() { # pr <body> <head> <check conclusion>...
  local body="$1" head="$2"; shift 2; local c="[]"
  for k in "$@"; do c="$(jq -c --arg k "$k" '. + [{"name":"ci","conclusion":$k}]' <<<"$c")"; done
  jq -n --arg b "$body" --arg h "$head" --argjson c "$c" '{body:$b,headRefOid:$h,statusCheckRollup:$c}' >"$PRJSON"
}
PROOF=$'## Summary\nx\n\n## Proof\n\n![home page](https://example.test/home.png)\n'
LOCAL=$'\n## Local run\n\n- sha: 0123456789ab\n- command: bash tests/run.sh\n- last line: ALL PASSED\n- time: 2026-11-14T10:00Z\n'
run() { out="$(bash "$MG" check "$@" 2>&1)"; rc=$?; }
mkdir -p "$T/g/docs/agents"; cd "$T/g" || exit 1
printf 'factory-state: 2\n' >docs/agents/factory.md
args=(7 --qa pass --security pass --paths "README.md")
# it prints which checks it read, in every case
pr "$PROOF" "$HEAD40" SUCCESS; run "${args[@]}"
ck checks-read-line "yes" "$(printf '%s\n' "$out" | grep -qx 'checks read: ci=SUCCESS' && echo yes || echo no)"; ck green-check-merges 0 "$rc"
pr "$PROOF" "$HEAD40" SUCCESS FAILURE; run "${args[@]}"
ck checks-read-with-failure "yes" "$(printf '%s\n' "$out" | grep -qx 'checks read: ci=SUCCESS, ci=FAILURE' && echo yes || echo no)"
pr "$PROOF" "$HEAD40"; run "${args[@]}"
ck checks-read-none "yes" "$(printf '%s\n' "$out" | grep -qx 'checks read: none' && echo yes || echo no)"
# neither a check nor the declaration: blocked, and the message names both ways
ck neither-blocked 11 "$rc"
ck neither-names-workflow "yes" "$(printf '%s\n' "$out" | grep '^reason: CI is not green' | grep -q 'a workflow that runs the test command on pull requests' && echo yes || echo no)"
ck neither-names-declaration "yes" "$(printf '%s\n' "$out" | grep '^reason: CI is not green' | grep -q 'declare `ci: none`' && echo yes || echo no)"
# ci: none and a recorded local run on the PR head: accepted, and it says so
printf 'factory-state: 2\n\nci: none (no workflow runs `bash tests/run.sh`)\n' >docs/agents/factory.md
pr "$PROOF$LOCAL" "$HEAD40"; run "${args[@]}"
ck local-run-accepted 0 "$rc"
ck local-run-says-so "yes" "$(printf '%s\n' "$out" | grep -qx 'ci: none (local run on 0123456789ab)' && echo yes || echo no)"
ck local-run-still-lists-checks "yes" "$(printf '%s\n' "$out" | grep -qx 'checks read: none' && echo yes || echo no)"
# the local run must be on the PR head, and complete
pr "$PROOF$LOCAL" "ffffffffffffffffffffffffffffffffffffffff"; run "${args[@]}"
ck local-run-wrong-head-blocked 11 "$rc"
ck local-run-wrong-head-says-why "yes" "$(printf '%s\n' "$out" | grep '^reason:' | grep -q 'not on the PR head' && echo yes || echo no)"
for miss in 'sha: 0123456789ab' 'command: bash tests/run.sh' 'last line: ALL PASSED' 'time: 2026-11-14T10:00Z'; do
  pr "$PROOF$(printf '%s\n' "$LOCAL" | grep -vF -- "$miss")" "$HEAD40"; run "${args[@]}"
  ck "local-run-missing-${miss%%:*}-blocked" 11 "$rc"
done
pr "$PROOF" "$HEAD40"; run "${args[@]}"
ck ci-none-without-record-blocked 11 "$rc"
ck ci-none-without-record-says-how "yes" "$(printf '%s\n' "$out" | grep '^reason: CI is not green' | grep -q '## Local run' && echo yes || echo no)"
# a red check stays red under ci: none
pr "$PROOF$LOCAL" "$HEAD40" FAILURE; run "${args[@]}"
ck ci-none-red-check-blocked 11 "$rc"
# a green check merges as before, and a local run is not asked for
pr "$PROOF" "$HEAD40" SUCCESS; run "${args[@]}"
ck ci-none-green-check-merges 0 "$rc"
ck ci-none-green-check-no-local-line "0" "$(printf '%s\n' "$out" | grep -c '^ci: none')"
# the gate pauses and blocks for the other reasons as before
pr "$PROOF$LOCAL" "$HEAD40"; run 7 --qa findings --security pass --paths README.md
ck local-run-does-not-cover-qa 11 "$rc"
run 7 --qa pass --security pass --touches contract
ck local-run-still-pauses-for-contract 10 "$rc"
# a declared workflow that reported nothing is told to wait, not to declare
printf 'factory-state: 2\n\nci: workflow .github/workflows/t.yml runs `npm test` on pull requests\n' >docs/agents/factory.md
pr "$PROOF$LOCAL" "$HEAD40"; run "${args[@]}"
ck declared-workflow-no-checks-blocked 11 "$rc"
ck declared-workflow-says-wait "yes" "$(printf '%s\n' "$out" | grep '^reason: CI is not green' | grep -q 'ci: says a workflow runs the tests' && echo yes || echo no)"
# the line is read from origin/main first: a branch cannot declare ci: none for itself
git init -q -b main . 2>/dev/null; git add -A; git commit -qm base; git update-ref refs/remotes/origin/main HEAD
printf 'factory-state: 2\n\nci: none (branch says so)\n' >docs/agents/factory.md
pr "$PROOF$LOCAL" "$HEAD40"; run "${args[@]}"
ck branch-cannot-declare-ci-none 11 "$rc"
cd "$T" || exit 1

# --- text: the setup skill, the run skill's one line, baseline.md
has setup-names-scan "$SETUP" 'setup-table.sh" scan'
has setup-writes-table "$SETUP" 'setup-table.sh" write'
has setup-one-question "$SETUP" 'one question: confirm this table'
has setup-reruns-append "$SETUP" 'appends the section'
has setup-says-ci-line "$SETUP" '`ci:` line'
has setup-no-devops-offer "$SETUP" 'does not offer a test workflow'
has setup-state-needs-table "$SETUP" 'and the flow table'
hasnt setup-no-state-2-only "$SETUP" 'accepts a project only when line 1 of `docs/agents/factory.md` is `factory-state: 2`;'
has run-exit-6 "$RUN" 'exit 6 means no flow table'
ck run-one-line-only "1" "$(grep -c 'exit 6 means no flow table' "$RUN")"
ck run-size-cap "yes" "$([ "$(wc -c <"$RUN" | tr -d ' ')" -le 115900 ] && echo yes || echo no)"
has baseline-major-new-series "$BASE" 'A new major starts a new series exactly as a new minor does'
ck baseline-no-repo-names "0" "$(grep -c 'check-bump\|release-class' "$BASE")"

# a new major starts a new series, as a new minor does: records of 2.18.0 and 3.0.0 replayed by the written rules
FXB="$REPO/tests/factory/fixtures/baseline"
if command -v python3 >/dev/null; then
  for spec in "9101:101:factory 2.18.0:2026-11-01T10:00:00Z" "9102:102:factory 3.0.0:2026-11-02T10:00:00Z"; do
    IFS=: read -r cid it rel ts <<<"$spec"
    body="$(sed -e "s/#101 /#$it /" -e "s/^- plugin: .*/- plugin: $rel/" "$FXB/records/x5.md")"
    jq -nc --argjson id "$cid" --arg it "$it" --arg ts "$ts" --arg b "$body" '{id:$id,html_url:("https://example.invalid/shop/issues/"+$it+"#issuecomment-"+($id|tostring)),created_at:$ts,user:{login:"lead-qa"},body:$b}'
  done >"$T/major-records.jsonl"
  python3 -I "$REPO/tests/factory/baseline_replay.py" body "$T/major-records.jsonl" 3.0.0 - >"$T/major-out.md" 2>"$T/major-err"
  ck major-replay-exit 0 $?
  ck major-current-series "yes" "$(grep -q '^### Series 3.0 — current' "$T/major-out.md" && echo yes || echo no)"
  ck major-old-series-replaced "yes" "$(grep -q '^### Series 2.18 — replaced 2026-11-02 by 3.0' "$T/major-out.md" && echo yes || echo no)"
  ck major-old-series-keeps-its-item "yes" "$(awk '/^### Series 2.18/{f=1;next} /^### /{f=0} f' "$T/major-out.md" | grep -q '#101' && echo yes || echo no)"
else
  skip major-replay "python3 missing"
fi

# --- item 4: this repository's own table, scanned and committed
OWN="$REPO/docs/agents/factory.md"
bash "$CFG" state "$OWN" >/dev/null 2>&1; ck own-state-passes $? 0
ck own-table-rows "8" "$(bash "$CFG" table "$OWN" | grep -cE "^\| ($TRIGGERS)")"
ck own-type "project-type: markdown/LLM plugin" "$(grep '^project-type:' "$OWN")"
ck own-test-depth "test-depth: proof-only" "$(grep '^test-depth:' "$OWN")"
ck own-rows-provisional "8" "$(grep -E "^\| ($TRIGGERS)" "$OWN" | grep -c '| provisional |$')"
ck own-ci-none "yes" "$(grep -q '^ci: none (no workflow runs `bash tests/run.sh`)' "$OWN" && echo yes || echo no)"
ck own-confirmed-by-merge "yes" "$(grep '^confirmed:' "$OWN" | grep -q 'merging' && echo yes || echo no)"
ck own-line-1-kept "factory-state: 2" "$(head -n 1 "$OWN")"
ck own-release-hook-kept "1" "$(grep -c '^release-hook: scripts/release.sh$' "$OWN")"
# the scan on this repository gives what the table says
ck own-scan-agrees "yes" "$(bash "$ST" scan "$REPO" | grep -q '^type: markdown/LLM plugin' && echo yes || echo no)"

# --- item 5: the ADR for the gate (one-way door)
ADR="$(ls "$REPO"/docs/adr/ | grep -E '^0023-' | head -1)"
ck adr-number-23 "yes" "$([ -n "$ADR" ] && echo yes || echo no)"
ck adr-numbers-unique "0" "$(ls "$REPO/docs/adr" | grep -E '^[0-9]{4}-' | cut -c1-4 | sort | uniq -d | wc -l | tr -d ' ')"
A="$REPO/docs/adr/$ADR"
for h in "status:" "## Context" "## Options considered" "## Decision" "## Consequences" "## Way back"; do has "adr-has-$h" "$A" "$h"; done
has adr-option-refuse "$A" 'Refuse a run without the table'
has adr-option-warn "$A" 'Warn and auto-seed'
has adr-option-leave "$A" 'Leave as is'
ck adr-chosen-is-refuse "yes" "$(grep -E '^- \*\*Refuse a run without the table' "$A" | grep -q 'chosen' && echo yes || echo no)"
has adr-links-decision-card "$A" 'issues/187#issuecomment-6875271136'
has adr-way-back-needs-card "$A" 'decision card'
has adr-says-major "$A" '3.0.0'
# every reason line carries exactly one tag; an (owner) tag only on a quote found in the grill record
bad=0; own=0
while IFS= read -r l; do
  case "$l" in
    "- **"*)
      o=$(printf '%s' "$l" | grep -o '`(owner)`' | wc -l | tr -d ' '); a=$(printf '%s' "$l" | grep -o '`(architect)`' | wc -l | tr -d ' ')
      [ $((o + a)) -ge 1 ] || bad=$((bad + 1))
      if [ "$o" -ge 1 ]; then
        own=$((own + 1))
        q="$(printf '%s' "$l" | sed -n 's/.*"\([^"]*\)".*/\1/p')"
        [ -n "$q" ] && grep -qF -- "$q" "$REPO/tests/factory/fixtures/slice3/grill-record.txt" || bad=$((bad + 1))
      fi ;;
  esac
done <"$A"
ck adr-every-option-line-tagged "0" "$bad"
ck adr-owner-tag-only-on-a-quote "yes" "$([ "$own" -ge 1 ] && echo yes || echo no)"
ck adr-says-no-reason-for-rejection "yes" "$(grep -qi 'gave no reason' "$A" && echo yes || echo no)"
ck adr-no-owner-tag-in-consequences "0" "$(sed -n '/^## Consequences/,$p' "$A" | grep -c '(owner)')"

# --- item 6: the release
PJ="$PLUGIN/.claude-plugin/plugin.json"
ck version-3-0-0 "3.0.0" "$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PJ")"
CL="$REPO/CHANGELOG.md"
ck changelog-entry "1" "$(grep -c '^## factory 3.0.0 (#207, slice 3)$' "$CL")"
ck changelog-declares-major "yes" "$(grep -q '^Release: major (.\+)$' "$CL" && echo yes || echo no)"
ck changelog-names-closes "yes" "$(awk '/^## factory 3.0.0/{f=1;next} /^## /{f=0} f' "$CL" | grep -q 'issues/179' && echo yes || echo no)"
done_
