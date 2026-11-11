#!/bin/bash
# Lite measurement and role skipping. Issue #118, spec #108.
# Two seams: the scripts (factory-config.sh measurement/analysis, skip.sh, integrator.sh plan) and the standard text.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
FC="$PLUGIN/scripts/factory-config.sh"; SK="$PLUGIN/scripts/skip.sh"; IN="$PLUGIN/scripts/integrator.sh"
RUN="$PLUGIN/skills/run/SKILL.md"; HA="$PLUGIN/references/hansei.md"; AG="$PLUGIN/agents/integrator.md"
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"
f() { printf '%b' "$2" >"$T/$1"; }
cd "$T" || exit 1

# --- scripts seam: reading the setting
f none 'factory-state: 2\n'
ck measurement-absent-full "full" "$(bash "$FC" measurement "$T/none")"
f m1 'measurement: full\n'; ck measurement-full "full" "$(bash "$FC" measurement "$T/m1")"
f m2 'measurement: lite  \n'; ck measurement-lite "lite" "$(bash "$FC" measurement "$T/m2")"
for bad in "heavy" "" "Lite" "full lite"; do
  f mb "measurement: $bad\n"; bash "$FC" measurement "$T/mb" >/dev/null 2>&1; ck "measurement-bad-[$bad]-exit-5" 5 "$?"
done
f md 'measurement: lite\nmeasurement: full\n'; bash "$FC" measurement "$T/md" >/dev/null 2>&1; ck measurement-doubled-exit-5 5 "$?"
f mi '  measurement: lite\nNote: measurement: lite\n'; ck measurement-indented-not-matched "full" "$(bash "$FC" measurement "$T/mi")"
ck measurement-env-ignored "full" "$(MEASUREMENT=lite FACTORY_MEASUREMENT=lite bash "$FC" measurement "$T/none")"
bash "$FC" measurement "$T/nosuch" >/dev/null 2>&1; ck measurement-missing-file-exit-2 2 "$?"

# --- scripts seam: cut-offs and token spend are computed under full, and under lite only when asked
bash "$FC" analysis "$T/none"; ck analysis-default-computed 0 "$?"
bash "$FC" analysis "$T/m1"; ck analysis-full-computed 0 "$?"
bash "$FC" analysis "$T/m2"; ck analysis-lite-not-computed 1 "$?"
bash "$FC" analysis --asked "$T/m2"; ck analysis-lite-asked-computed 0 "$?"
bash "$FC" analysis x "$T/m2" >/dev/null 2>&1; ck analysis-bad-arg-exit-2 2 "$?"

# --- scripts seam: the skip check
lf() { local n="$1"; shift; { echo "# t"; echo; echo "Paths:"; for p in "$@"; do echo "- $p"; done; echo "shared: none"; } >"$T/$n"; }
lf plain.md docs/guide.md plugins/x/readme.md
lf ctr.md contracts/api.md
lf auth.md src/auth/login.ts
lf sec.md config/secrets/keys.yml
lf mig.md db/migrations/001.sql
bash "$SK" check docs-writer --reason "typo fix" "$T/plain.md" >/dev/null; ck skip-trivial-ok 0 "$?"
ck skip-ok-line "skip ok docs-writer" "$(bash "$SK" check docs-writer --reason "typo fix" "$T/plain.md")"
bash "$SK" check architect --reason "x" "$T/plain.md" >/dev/null; ck skip-architect-ok 0 "$?"
bash "$SK" check qa-engineer --reason "trivial" "$T/plain.md" >/dev/null 2>&1; ck qa-never-skipped 1 "$?"
ck qa-refusal-line "refused: qa-engineer is never skipped" "$(bash "$SK" check qa-engineer --reason "trivial" "$T/plain.md" 2>&1)"
bash "$SK" check runtime-proof --reason "trivial" "$T/plain.md" >/dev/null 2>&1; ck proof-never-skipped 1 "$?"
bash "$SK" check docs-writer "$T/plain.md" >/dev/null 2>&1; ck skip-needs-reason 1 "$?"
ck skip-no-reason-line "refused: a skip needs a written reason" "$(bash "$SK" check docs-writer "$T/plain.md" 2>&1)"
bash "$SK" check docs-writer --reason "   " "$T/plain.md" >/dev/null 2>&1; ck skip-blank-reason 1 "$?"
bash "$SK" check wizard --reason "x" "$T/plain.md" >/dev/null 2>&1; ck unknown-role-exit-2 2 "$?"
for p in ctr auth sec mig; do
  bash "$SK" check docs-writer --reason "trivial" "$T/$p.md" >/dev/null 2>&1; ck "protected-path-$p-no-skip" 1 "$?"
done
ck protected-line "refused: the slice touches a protected area (contracts/api.md)" "$(bash "$SK" check docs-writer --reason r "$T/ctr.md" 2>&1)"
for a in contracts authentication secrets data-migration one-way-door; do
  bash "$SK" check docs-writer --reason r --touches "$a" "$T/plain.md" >/dev/null 2>&1; ck "declared-$a-no-skip" 1 "$?"
done
bash "$SK" check docs-writer --reason r --touches "colour" "$T/plain.md" >/dev/null 2>&1; ck declared-unknown-area-exit-2 2 "$?"
bash "$SK" protected "$T/plain.md"; ck protected-none 0 "$?"
bash "$SK" protected "$T/mig.md" >/dev/null; ck protected-migration 1 "$?"
bash "$SK" check docs-writer --reason r "$T/nosuch.md" >/dev/null 2>&1; ck missing-path-list-exit-2 2 "$?"

# --- scripts seam: the integrator counts skipped roles and compares rework
cat >"$T/b.json" <<JSON
{"now":"2026-11-11T12:00:00Z","slices":[
 {"id":"1","status":"Done","skipped":["docs-writer"],"rework_rounds":3},
 {"id":"2","status":"Done","skipped":["architect","devops"],"rework_rounds":1},
 {"id":"3","status":"Done","rework_rounds":0},
 {"id":"4","status":"Done","rework_rounds":1},
 {"id":"5","status":"Done"}]}
JSON
out="$(bash "$IN" plan "$T/b.json")"
ck measure-skipped-roles "measure skipped 3 roles in 2 slices" "$(printf '%s\n' "$out" | grep '^measure skipped')"
ck measure-rework-skipped "measure rework skipped 2.0 (2 slices)" "$(printf '%s\n' "$out" | grep '^measure rework skipped')"
ck measure-rework-full "measure rework full 0.5 (2 slices)" "$(printf '%s\n' "$out" | grep '^measure rework full')"
cat >"$T/b0.json" <<JSON
{"now":"2026-11-11T12:00:00Z","slices":[{"id":"1","status":"Done"}]}
JSON
out="$(bash "$IN" plan "$T/b0.json")"
ck no-skips-zero "measure skipped 0 roles in 0 slices" "$(printf '%s\n' "$out" | grep '^measure skipped')"
ck rework-not-captured-skipped "measure rework skipped not captured" "$(printf '%s\n' "$out" | grep '^measure rework skipped')"
ck rework-not-captured-full "measure rework full not captured" "$(printf '%s\n' "$out" | grep '^measure rework full')"

# --- standard-text seam
has template-measurement "$TPL" 'measurement: full'
ck template-reads-full "full" "$(bash "$FC" measurement "$TPL")"
has run-lite "$RUN" '`measurement: lite`'
has run-lite-analysis "$RUN" 'factory-config.sh" analysis'
has run-skip-reason "$RUN" 'writes the reason on the ticket'
has run-never-qa "$RUN" 'QA and the runtime proof are never skipped'
has run-never-protected "$RUN" 'no role is skipped when the slice touches contracts, authentication, secrets, a data migration or a one-way door'
has run-skip-script "$RUN" 'scripts/skip.sh" check'
has run-baseline-a3-same "$RUN" 'Baseline and A3 are the same under full and lite'
has hansei-lite "$HA" '### The lite record'
has hansei-lite-reason "$HA" 'not captured (lite)'
has hansei-skipped "$HA" 'the `skipped` roles noted in the ledger'
has integrator-skipped "$AG" 'measure skipped'
has integrator-rework "$AG" 'measure rework skipped'
has glossary-profile "$REPO/CONTEXT.md" '**Measurement profile**'
has glossary-skip "$REPO/CONTEXT.md" '**Role skip**'
done_
