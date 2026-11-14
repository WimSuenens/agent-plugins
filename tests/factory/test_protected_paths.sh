#!/bin/bash
# Slice 1 of #207 (#192, #187 decision 5): one definition of a protected change, read by the skip check and the merge gate on one path list.
# Seams: protected-areas.sh (sourced), skip.sh, merge-gate.sh, and one line of standard text in the run skill.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PA="$PLUGIN/scripts/protected-areas.sh"; SK="$PLUGIN/scripts/skip.sh"; MG="$PLUGIN/scripts/merge-gate.sh"
RUN="$(run_all_file)"
cd "$T" || exit 1
area() { ( . "$PA"; protected_path_area "$1" ) ; }

# --- tighter patterns: a word that merely contains auth, login, secret or migrat is not a protected area
for p in docs/author.md src/authors/list.ts docs/authority.md src/secretary.ts docs/immigration.md apps/site/src/blogin.ts; do
  ck "not-protected-$(printf '%s' "$p" | tr '/.' '__')" "" "$(area "$p")"
done
# ... and what is protected stays protected
ck auth-dir "authentication" "$(area src/auth/session.ts)"
ck auth-file "authentication" "$(area src/auth.ts)"
ck authentication-file "authentication" "$(area src/authentication.ts)"
ck authorization-file "authentication" "$(area src/authorization.ts)"
ck authz-file "authentication" "$(area src/authz.ts)"
ck oauth-dir "authentication" "$(area src/oauth/cb.js)"
ck login-file "authentication" "$(area web/login.ts)"
ck auth-hyphen "authentication" "$(area src/auth-middleware.ts)"
ck secrets-dir "secrets" "$(area config/secrets.yml)"
ck env-file "secrets" "$(area apps/x/.env.local)"
ck credentials-file "secrets" "$(area config/credentials.json)"
ck pem-file "secrets" "$(area keys/server.pem)"
ck migrate-dir "migration" "$(area db/migrate/1.rb)"
ck migrations-dir "migration" "$(area db/migrations/001.sql)"
ck sql-file "migration" "$(area schema.sql)"
ck contract-file "contract" "$(area contracts/168-x.md)"
ck case-folded "authentication" "$(area SRC/Auth/Session.ts)"

# code review: names that hold the word inside (camel case, prefixes) stay protected
for p in src/authService.ts src/userauth.ts web/loginPage.tsx web/signinForm.ts config/my-secret.txt db_credentials.json src/apiSecrets.ts src/AuthorizationGuard.ts; do
  ck "word-inside-still-protected-$(printf '%s' "$p" | tr '/.' '__')" "yes" "$([ -n "$(area "$p")" ] && echo yes || echo no)"
done
ck author-service-not-protected "" "$(area src/authorService.ts)"
ck authorization-still-auth "authentication" "$(area src/authorization.ts)"

# --- a project extends the table with one line in docs/agents/factory.md: `protected-paths: <glob>, <glob>`
mkdir -p "$T/p1/docs/agents" "$T/p2/docs/agents"
printf 'factory-state: 2\nprotected-paths: infra/*, apps/billing/*\n' >"$T/p1/docs/agents/factory.md"
printf 'factory-state: 2\n' >"$T/p2/docs/agents/factory.md"
ck extension-glob-hit "project" "$(cd "$T/p1" && area infra/main.tf)"
ck extension-second-glob-hit "project" "$(cd "$T/p1" && area apps/billing/src/x.ts)"
ck extension-no-hit "" "$(cd "$T/p1" && area apps/site/src/x.ts)"
ck extension-absent-line-no-hit "" "$(cd "$T/p2" && area infra/main.tf)"
ck extension-no-file-no-hit "" "$(cd "$T" && area infra/main.tf)"
ck extension-keeps-builtin "authentication" "$(cd "$T/p1" && area src/auth/x.ts)"
# the extension is read from the line at column 0 only
printf 'factory-state: 2\n  protected-paths: infra/*\nNote: protected-paths: infra/*\n' >"$T/p2/docs/agents/factory.md"
ck extension-indented-line-ignored "" "$(cd "$T/p2" && area infra/main.tf)"

# the skip check and the gate read the same extension
printf 'Paths:\n- infra/main.tf\nshared: none\n' >"$T/ext.md"
( cd "$T/p1" && bash "$SK" protected "$T/ext.md" >/dev/null ); ck skip-protected-by-extension 1 "$?"
( cd "$T/p2" && printf 'factory-state: 2\n' >docs/agents/factory.md && bash "$SK" protected "$T/ext.md" >/dev/null ); ck skip-not-protected-without-extension 0 "$?"

# --- the same path list: the skip check adds the slice's own contract files, or takes the PR's changed paths (the #168 case)
mkdir -p "$T/r/contracts" "$T/bin"
printf 'Paths:\n- plugins/x/a.md\nshared: none\n' >"$T/r/contracts/168-fix.md"
( cd "$T/r" && bash "$SK" check security-reviewer --reason "one-line fix" contracts/168-fix.md >/dev/null ); ck skip-refuses-own-contract-file 1 "$?"
ck skip-own-contract-line "refused: the slice touches a protected area (contracts/168-fix.md)" "$(cd "$T/r" && bash "$SK" check security-reviewer --reason r contracts/168-fix.md 2>&1)"
( cd "$T/r" && bash "$SK" protected contracts/168-fix.md >/dev/null ); ck protected-counts-own-contract-file 1 "$?"
printf 'Paths:\n- plugins/x/a.md\nshared: none\n' >"$T/plain.md"
( cd "$T" && bash "$SK" check security-reviewer --reason r plain.md >/dev/null ); ck skip-contract-outside-contracts-dir-not-added 0 "$?"
# the PR's changed paths: the very list the gate gets
( cd "$T" && bash "$SK" check security-reviewer --reason r --paths "plugins/x/a.md contracts/168-fix.md" plain.md >/dev/null ); ck skip-paths-contract-refused 1 "$?"
( cd "$T" && bash "$SK" check security-reviewer --reason r --paths "plugins/x/a.md docs/author.md" plain.md >/dev/null ); ck skip-paths-clean-ok 0 "$?"
( cd "$T" && bash "$SK" check security-reviewer --reason r --paths "src/oauth/cb.js" plain.md >/dev/null ); ck skip-paths-oauth-refused 1 "$?"
( cd "$T" && set -f && bash "$SK" check security-reviewer --reason r --paths "*" plain.md >/dev/null ); ck skip-paths-not-glob-expanded 0 "$?"

# the gate, given the same list, blocks the skip: the #168 case end to end (the skip check and the gate agree)
cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "pr view" ] && { cat "$PRJSON"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH"; export PRJSON="$T/pr.json"
jq -n --arg b $'## Proof\n\n```\nok\n```\n' '{body:$b,statusCheckRollup:[{name:"ci",conclusion:"SUCCESS"}]}' >"$PRJSON"
for list in "plugins/x/a.md contracts/168-fix.md" "plugins/x/a.md src/oauth/cb.js" "plugins/x/a.md docs/author.md" "plugins/x/a.md"; do
  ( cd "$T" && bash "$SK" check security-reviewer --reason r --paths "$list" plain.md >/dev/null ); s=$?
  bash "$MG" check 7 --qa pass --security skipped --skip-reason r --paths "$list" >/dev/null 2>&1; g=$?
  want=0; [ $s = 1 ] && want=11
  ck "skip-and-gate-agree-[$list]" "$want" "$g"
done

# --- standard text: one line in Skipping roles
has run-skip-same-path-list "$RUN" 'the skip check runs on the same path list as the gate'
done_
