#!/bin/bash
# Slice 114, auto-merge with runtime proof: the scripts seam (gate evaluation, proof presence, validation script)
# and the standard-text seam (always-human list, no-proof rule, revised approval rule).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
MG="$PLUGIN/scripts/merge-gate.sh"
RUN="$(run_all_file)"
AG="$PLUGIN/agents/integrator.md"
PROTO="$PLUGIN/references/protocol.md"
cd "$T" || exit 1

# a fake gh: `pr view <n> --json body,statusCheckRollup` answers from $PRJSON
mkdir -p "$T/bin"
cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "pr view" ] && { cat "$PRJSON"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH"; export PRJSON="$T/pr.json"

pr() { # pr <body> <check conclusion>...
  local body="$1"; shift; local c="[]"
  for k in "$@"; do c="$(jq -c --arg k "$k" '. + [{"name":"ci","conclusion":$k}]' <<<"$c")"; done
  jq -n --arg b "$body" --argjson c "$c" '{body:$b,statusCheckRollup:$c}' >"$PRJSON"
}
PROOF=$'## Summary\nx\n\n## Proof\n\n![home page](https://example.test/home.png)\n'
LOG=$'## Proof\n\n```\n$ tool --version\n1.2.3\n```\n'
run() { out="$(bash "$MG" check "$@" 2>&1)"; rc=$?; }

pr "$PROOF" SUCCESS SUCCESS
run 7 --qa pass --security pass --paths "src/a.js README.md"
ck all-gates-auto-merge 0 "$rc"; ck all-gates-line "yes" "$(printf '%s\n' "$out" | grep -qx 'gate 7: auto-merge' && echo yes || echo no)"
pr "$LOG" SUCCESS
run 7 --qa pass --security pass
ck log-proof-accepted 0 "$rc"

pr $'## Summary\nonly words\n' SUCCESS
run 7 --qa pass --security pass
ck no-proof-blocked 11 "$rc"; ck no-proof-says-why "yes" "$(printf '%s\n' "$out" | grep -q '^reason: no proof in the PR description' && echo yes || echo no)"
pr $'## Proof\n\n' SUCCESS
run 7 --qa pass --security pass
ck empty-proof-blocked 11 "$rc"

pr "$PROOF" SUCCESS FAILURE
run 7 --qa pass --security pass
ck red-ci-blocked 11 "$rc"; ck red-ci-says-why "yes" "$(printf '%s\n' "$out" | grep -q '^reason: CI is not green' && echo yes || echo no)"
pr "$PROOF" PENDING
run 7 --qa pass --security pass
ck pending-ci-blocked 11 "$rc"
pr "$PROOF"
run 7 --qa pass --security pass
ck no-ci-blocked 11 "$rc"

pr "$PROOF" SUCCESS
run 7 --qa findings --security pass
ck qa-not-pass-blocked 11 "$rc"; ck qa-says-why "yes" "$(printf '%s\n' "$out" | grep -q '^reason: QA verdict is findings' && echo yes || echo no)"
run 7 --qa pass --security needs-decision
ck security-not-pass-blocked 11 "$rc"
run 7 --qa pass
ck missing-verdict-blocked 11 "$rc"

# always human
for t in contract authentication secrets migration door; do
  run 7 --qa pass --security pass --touches "$t"
  ck "touch-$t-pauses" 10 "$rc"
done
run 7 --qa pass --security pass --paths "db/migrations/001_add.sql"
ck path-migration-pauses 10 "$rc"
run 7 --qa pass --security pass --paths "app/.env.production"
ck path-secrets-pauses 10 "$rc"
run 7 --qa pass --security pass --paths "src/auth/login.js"
ck path-auth-pauses 10 "$rc"
run 7 --qa pass --security pass --touches contract
ck pause-line "yes" "$(printf '%s\n' "$out" | grep -qx 'gate 7: pause' && echo yes || echo no)"
ck pause-has-script "yes" "$(printf '%s\n' "$out" | grep -qx 'validation script:' && echo yes || echo no)"
ck pause-script-plain-steps "yes" "$(printf '%s\n' "$out" | grep -q '^1\. ' && echo yes || echo no)"
ck pause-script-names-reason "yes" "$(printf '%s\n' "$out" | grep -q 'contract' && echo yes || echo no)"
ck pause-no-branch-names "0" "$(printf '%s\n' "$out" | grep -c 'item/')"

# blocked wins over pause
pr $'## Summary\nx\n' SUCCESS
run 7 --qa pass --security pass --touches contract
ck blocked-beats-pause 11 "$rc"

# a legitimately skipped security role: accepted with a reason; QA and proof stay mandatory
pr "$PROOF" SUCCESS
run 7 --qa pass --security skipped --skip-reason "typo fix" --paths "docs/readme.md"
ck skipped-security-auto-merge 0 "$rc"
run 7 --qa pass --security skipped --paths "docs/readme.md"
ck skipped-security-needs-reason 11 "$rc"
run 7 --qa pass --security skipped --skip-reason "   "
ck skipped-security-blank-reason 11 "$rc"
run 7 --qa pass --security skipped --skip-reason "typo" --paths "src/auth/login.js"
ck skipped-security-protected-path-blocked 11 "$rc"
run 7 --qa pass --security skipped --skip-reason "typo" --touches door
ck skipped-security-protected-touch-blocked 11 "$rc"
run 7 --qa skipped --security pass
ck skipped-qa-blocked 11 "$rc"
run 7 --qa pass --security skip --skip-reason "typo"
ck other-security-verdict-blocked 11 "$rc"
pr $'## Summary\nx\n' SUCCESS
run 7 --qa pass --security skipped --skip-reason "typo"
ck skipped-security-no-proof-blocked 11 "$rc"
pr "$PROOF" SUCCESS
# shared protected-area definition: the gate pauses on exactly what skip.sh refuses
for p in contracts/api.md src/oauth/cb.js web/login.ts db/migrate/1.rb config/secrets.yml; do
  printf 'Paths:\n- %s\nshared: none\n' "$p" >"$T/pa.md"
  bash "$PLUGIN/scripts/skip.sh" protected "$T/pa.md" >/dev/null; sk=$?
  run 7 --qa pass --security pass --paths "$p"
  ck "same-definition-$p" "$sk" "$([ $rc = 10 ] && echo 1 || echo 0)"
done
# paths are never glob-expanded
mkdir -p "$T/g" && : >"$T/g/x.sql"; cd "$T/g" && run 7 --qa pass --security pass --paths "*"; cd "$T"
ck path-glob-not-expanded 0 "$rc"

run
ck usage-exit-2 2 "$rc"

# standard-text seam
has run-always-human "$RUN" 'contract, authentication, secrets, a data migration or a one-way door'
has run-no-proof-no-merge "$RUN" 'No proof means no auto-merge'
has run-auto-merge-gates "$RUN" 'QA and security pass, CI is green, proof is attached and no one-way door is open'
has run-pause-waiting "$RUN" 'Cause: validation'
has run-approval-not-widened "$RUN" "earlier approvals"
hasnt run-old-rule-gone "$RUN" 'Merging is never automatic'
has run-script "$RUN" 'scripts/merge-gate.sh'
has run-skipped-security "$RUN" '--security skipped --skip-reason'
has proto-skipped-security "$PROTO" 'the merge gate then accepts the verdict `skipped`'
has agent-runs-gate "$AG" 'scripts/merge-gate.sh'
has agent-no-proof "$AG" 'no proof, no merge'
has protocol-shell-gate "$PROTO" 'scripts/merge-gate.sh'
has adr-supersedes "$REPO/docs/adr/0018-the-factory-merges-its-own-pr-on-runtime-proof.md" 'status: proposed'
done_
