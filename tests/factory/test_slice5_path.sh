#!/bin/bash
# #207 slice 5, items 1 and 2: the role path and the test depth come from the plan; the floor cannot be dropped.
# Written before flow-size.sh (role path, test depth), plan-check.sh (both fields) and skip.sh (--plan) learned them.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
FS="$PLUGIN/scripts/flow-size.sh"; PC="$PLUGIN/scripts/plan-check.sh"; SK="$PLUGIN/scripts/skip.sh"
FX="$REPO/tests/factory/fixtures"
cd "$T" || exit 1
# the project's table: slice 4's fixture plus the starting depth of a markdown plugin (setup-table.sh writes these two lines)
TBL="$T/factory.md"
awk '/^bands: /{print "project-type: markdown/LLM plugin"; print "test-depth: proof-only"} {print}' "$FX/slice4/factory.md" >"$TBL"
# the same table with the words a plan could be tempted to lose edited out of the protected row's Adds
STRIP="$T/stripped.md"
sed "s/^| Protected area touched | 3 | .* | scan |/| Protected area touched | 3 | the person's merge approval | scan |/" "$TBL" >"$STRIP"
ck fixture-stripped-row-lost-the-words 0 "$(grep -c '^| Protected area touched.*security review' "$STRIP")"
size() { out="$(bash "$FS" --table "$TBL" "$@" 2>"$T/err")"; code=$?; }
val() { printf '%s\n' "$out" | sed -n "s/^$1: //p" | head -1; }

# ---- the empty set: the lightest path keeps the floor and nothing else
size
ck empty-role-path "developer, qa-engineer, runtime-proof" "$(val 'role path')"
ck empty-test-depth proof-only "$(val 'test depth')"
# ---- every trigger's Adds
size "Open one-way door";                          ck t-door-path "product-owner, architect, developer, qa-engineer, runtime-proof" "$(val 'role path')"
ck t-door-depth proof-only "$(val 'test depth')"
size "Unresolved research question";               ck t-research-path "developer, qa-engineer, runtime-proof" "$(val 'role path')"
size "More than 3 expected slices, or dependencies between them"; ck t-slices-path "developer, qa-engineer, runtime-proof" "$(val 'role path')"
size "Protected area touched";                     ck t-protected-path "developer, qa-engineer, runtime-proof, security-reviewer" "$(val 'role path')"
ck t-protected-depth targeted "$(val 'test depth')"
size "Contract or interface used by others";       ck t-contract-path "architect, developer, qa-engineer, runtime-proof" "$(val 'role path')"
size "New logic or data behaviour in a code project"; ck t-logic-path "developer, qa-engineer, runtime-proof" "$(val 'role path')"
ck t-logic-depth targeted "$(val 'test depth')"
size "Visual result";                              ck t-visual-path "developer, qa-engineer, runtime-proof" "$(val 'role path')"
ck t-visual-self-review yes "$(val 'ui self-review')"
size;                                              ck empty-no-self-review no "$(val 'ui self-review')"
size "Deploy, pipeline or production config (project row)"; ck t-deploy-path "devops, developer, qa-engineer, runtime-proof" "$(val 'role path')"
# several rows: canonical order, each role once
size "Deploy, pipeline or production config (project row)" "Open one-way door" "Protected area touched" "Contract or interface used by others"
ck sum-all-path "product-owner, architect, devops, developer, qa-engineer, runtime-proof, security-reviewer" "$(val 'role path')"
ck sum-all-depth targeted "$(val 'test depth')"
# --paths fires the protected row itself, and the path and depth follow
size --paths "plugins/factory/skills/run/SKILL.md
contracts/a.md"
ck paths-protected-adds-security "yes" "$(val 'role path' | grep -q security-reviewer && echo yes || echo no)"
ck paths-protected-depth targeted "$(val 'test depth')"

# ---- THE FLOOR (decision 4): the table adds steps, it never removes these
bash "$FS" --table "$STRIP" "Protected area touched" >"$T/o" 2>&1; ck floor-stripped-protected-exit 0 $?
ck floor-stripped-protected-keeps-security "yes" "$(sed -n 's/^role path: //p' "$T/o" | grep -q security-reviewer && echo yes || echo no)"
ck floor-stripped-protected-keeps-depth targeted "$(sed -n 's/^test depth: //p' "$T/o")"
bash "$FS" --table "$STRIP" --paths "contracts/a.md" >"$T/o" 2>&1
ck floor-stripped-paths-keeps-security "yes" "$(sed -n 's/^role path: //p' "$T/o" | grep -q security-reviewer && echo yes || echo no)"
ck floor-stripped-paths-keeps-depth targeted "$(sed -n 's/^test depth: //p' "$T/o")"
# the floor holds for every row set, with or without the words in the table
for t in "$TBL" "$STRIP"; do
  for r in "" "Open one-way door" "Visual result" "Deploy, pipeline or production config (project row)"; do
    out="$(bash "$FS" --table "$t" ${r:+"$r"})"
    p="$(printf '%s\n' "$out" | sed -n 's/^role path: //p')"
    ck "floor-always-qa[$r]" yes "$(printf '%s' "$p" | grep -q 'qa-engineer' && printf '%s' "$p" | grep -q 'runtime-proof' && printf '%s' "$p" | grep -q 'developer' && echo yes || echo no)"
  done
done
# a table without a starting depth is read as targeted, the safer one
grep -v '^test-depth: ' "$TBL" >"$T/nodepth.md"
bash "$FS" --table "$T/nodepth.md" >"$T/o" 2>&1; ck no-start-depth-is-targeted targeted "$(sed -n 's/^test depth: //p' "$T/o")"
# the script names none of the project's rows or roles' triggers; the floor words are the plugin's
ck script-names-no-trigger 0 "$(grep -v '^ *#' "$FS" | grep -v '^ *protlines=.*protrow=' | grep -v 'protrow' | grep -c -i 'open one-way\|unresolved\|protected area\|visual result' 2>/dev/null)"

# ---- plan-check.sh
plan() { cat >"$T/plan.md" <<'P'
## Plan

- route: direct
- role path: product-owner, architect, developer, qa-engineer, runtime-proof
- test depth: proof-only
- triggers: Open one-way door (+3), Visual result (+1)
- points: 4
- band: Normal
- bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more
- reason: one open door, no research, one slice expected
- release: factory 3.5.0
- expected slices: 1. the shell and the first page
- first slice leaves out: none
P
}
setf() { sed -i.bak "s/^- $1: .*/- $1: $2/" "$T/plan.md"; }
chk() { out="$(bash "$PC" "$T/plan.md" --table "$TBL" 2>&1)"; code=$?; }
plan; chk; ck plan-ok-exit 0 "$code"; ck plan-ok-line "plan ok" "$(printf '%s\n' "$out" | head -1)"
# `standard` is no longer a value
plan; setf "role path" standard; chk; ck plan-role-path-standard-refused 1 "$code"
ck plan-role-path-standard-says-derived "role path: write the roles that run; the table gives: product-owner, architect, developer, qa-engineer, runtime-proof" "$(printf '%s\n' "$out" | head -1)"
plan; setf "test depth" standard; chk; ck plan-test-depth-standard-refused 1 "$code"
ck plan-test-depth-standard-says-why "test depth: \"standard\" is not proof-only, targeted or full" "$(printf '%s\n' "$out" | head -1)"
# scaling up is allowed: a role added, the depth raised, full only by the lead's word
plan; setf "role path" "product-owner, architect, developer, qa-engineer, runtime-proof, security-reviewer, docs-writer"; chk; ck plan-scale-up-role-ok 0 "$code"
plan; setf "test depth" targeted; chk; ck plan-scale-up-depth-ok 0 "$code"
plan; setf "test depth" full; chk; ck plan-scale-up-full-ok 0 "$code"
# scaling down is refused: a role of the table's path missing, a depth below the table's
plan; setf "role path" "architect, developer, qa-engineer, runtime-proof"; chk; ck plan-drops-derived-role 1 "$code"
ck plan-drops-derived-role-names-it "role path: missing product-owner, which the table's rows add (scaling down happens at the next slice)" "$(printf '%s\n' "$out" | head -1)"
plan; setf triggers "New logic or data behaviour in a code project (+2)"; setf points 2; setf band Light; setf "role path" "developer, qa-engineer, runtime-proof"; setf "test depth" proof-only; chk
ck plan-depth-below-table 1 "$code"; ck plan-depth-below-table-says "test depth: proof-only is below targeted, which the table's rows give" "$(printf '%s\n' "$out" | head -1)"
# the order is the canonical one, a role is named once, an unknown role is refused
plan; setf "role path" "developer, architect, product-owner, qa-engineer, runtime-proof"; chk; ck plan-order-refused 1 "$code"
plan; setf "role path" "product-owner, architect, developer, developer, qa-engineer, runtime-proof"; chk; ck plan-duplicate-refused 1 "$code"
plan; setf "role path" "product-owner, architect, developer, qa-engineer, runtime-proof, wizard"; chk; ck plan-unknown-role-refused 1 "$code"
# the floor: QA, the runtime proof (and the developer) can never be missing, whatever the table says
for r in qa-engineer runtime-proof developer; do
  plan; setf "role path" "$(printf 'product-owner, architect, developer, qa-engineer, runtime-proof' | sed "s/$r, //; s/, $r\$//")"
  bash "$PC" "$T/plan.md" --table "$STRIP" >"$T/o" 2>&1; ck "plan-floor-drop-$r-refused" 1 $?
  ck "plan-floor-drop-$r-names-it" "yes" "$(head -1 "$T/o" | grep -q "missing $r" && echo yes || echo no)"
done
# a protected plan: security review and depth >= targeted, also with the table's words edited out
protplan() { plan; setf triggers "Protected area touched (+3)"; setf points 3; setf band Normal; setf "role path" "developer, qa-engineer, runtime-proof, security-reviewer"; setf "test depth" targeted; }
protplan; bash "$PC" "$T/plan.md" --table "$STRIP" >"$T/o" 2>&1; ck plan-protected-ok 0 $?
protplan; setf "role path" "developer, qa-engineer, runtime-proof"; bash "$PC" "$T/plan.md" --table "$STRIP" >"$T/o" 2>&1
ck plan-protected-drops-security-refused 1 $?; ck plan-protected-drops-security-says "role path: missing security-reviewer, which the floor keeps for a protected area" "$(head -1 "$T/o")"
protplan; setf "test depth" proof-only; bash "$PC" "$T/plan.md" --table "$STRIP" >"$T/o" 2>&1
ck plan-protected-depth-below-targeted-refused 1 $?; ck plan-protected-depth-says "test depth: proof-only is below targeted, which the floor keeps for a protected area" "$(head -1 "$T/o")"
# the artefact line is optional and checked when present
plan; printf -- '- artefact: cli\n' >>"$T/plan.md"; chk; ck plan-artefact-ok 0 "$code"
plan; printf -- '- artefact: hologram\n' >>"$T/plan.md"; chk; ck plan-artefact-unknown 1 "$code"

# ---- skip.sh and the plan agree
printf 'Paths:\n- docs/a.md\nshared: none\n' >"$T/contract.md"
sk() { out="$(bash "$SK" check "$@" "$T/contract.md" 2>&1)"; code=$?; }
plan; setf "role path" "developer, qa-engineer, runtime-proof"; setf triggers "Visual result (+1)"; setf points 1; setf band Light; setf "test depth" proof-only
sk architect --reason "no contract in this slice" --plan "$T/plan.md"
ck skip-off-path-ok 0 "$code"; ck skip-off-path-line "skip ok architect (not on the plan's role path)" "$out"
sk developer --reason "nothing to build" --plan "$T/plan.md"
ck skip-on-path-refused 1 "$code"; ck skip-on-path-says "refused: developer is on the plan's role path; the plan scales down at the next slice" "$out"
sk architect --plan "$T/plan.md"; ck skip-off-path-still-needs-a-reason 1 "$code"
sk qa-engineer --reason "x" --plan "$T/plan.md"; ck skip-floor-qa-refused 1 "$code"
sk runtime-proof --reason "x" --plan "$T/plan.md"; ck skip-floor-proof-refused 1 "$code"
sk security-reviewer --reason "x" --plan "$T/plan.md" --touches authentication
ck skip-floor-security-protected-refused 1 "$code"
sk architect --reason "x" --plan "$T/nosuch.md"; ck skip-plan-unreadable 2 "$code"
# without --plan nothing changes
sk architect --reason "trivial"; ck skip-without-plan-as-before 0 "$code"; ck skip-without-plan-line "skip ok architect" "$out"
done_
