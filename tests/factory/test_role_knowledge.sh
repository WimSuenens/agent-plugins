#!/bin/bash
# Slice 115, role knowledge in the project. Two seams: the scripts (isolation hook, role-knowledge.sh) and the standard text.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
G="$PLUGIN/scripts/guard-memory.sh"
RK="$PLUGIN/scripts/role-knowledge.sh"
PR_="$PLUGIN/references/protocol.md"
SU="$PLUGIN/skills/setup-factory-skill/SKILL.md"
SK="$PLUGIN/skills/run/SKILL.md"
T="$(cd "$T" && pwd -P)"

# hook <agent_type> <tool_input json>: exit code of the guard
hook() { printf '{"agent_type":"%s","tool_input":%s}' "$1" "$2" | bash "$G" >/dev/null 2>&1; echo $?; }

# --- scripts seam: the isolation hook
ck own-role-file-allowed 0 "$(hook factory:developer '{"file_path":"docs/agents/roles/developer.md"}')"
ck own-skills-folder-allowed 0 "$(hook factory:developer '{"file_path":"docs/agents/skills/developer/tdd/SKILL.md"}')"
ck other-role-file-refused 2 "$(hook factory:developer '{"file_path":"docs/agents/roles/architect.md"}')"
ck other-skills-folder-refused 2 "$(hook factory:developer '{"file_path":"docs/agents/skills/qa-engineer/x/SKILL.md"}')"
ck other-role-by-bash-refused 2 "$(hook qa-engineer '{"command":"cat /p/docs/agents/roles/developer.md"}')"
ck other-role-by-grep-refused 2 "$(hook factory:security-reviewer '{"pattern":"x","path":"docs/agents/roles/integrator.md"}')"
ck wildcard-roles-refused 2 "$(hook developer '{"pattern":"docs/agents/roles/*"}')"
ck wildcard-skills-refused 2 "$(hook developer '{"command":"ls docs/agents/skills/"}')"
ck shared-glossary-allowed 0 "$(hook developer '{"file_path":"CONTEXT.md"}')"
ck shared-factory-md-allowed 0 "$(hook developer '{"file_path":"docs/agents/factory.md"}')"
ck shared-adr-allowed 0 "$(hook developer '{"file_path":"docs/adr/0004-x.md"}')"
ck lead-unguarded 0 "$(hook "" '{"file_path":"docs/agents/roles/architect.md"}')"
ck lead-named-unguarded 0 "$(hook lead '{"file_path":"docs/agents/roles/architect.md"}')"
ck other-memory-still-refused 2 "$(hook developer '{"file_path":"/h/.claude/agent-memory/architect/MEMORY.md"}')"

# --- scripts seam: role-knowledge.sh init
R="$T/proj"; mkdir -p "$R"
out="$(cd "$R" && bash "$RK" init 2>&1)"; rc=$?
ck init-rc 0 "$rc"
for r in product-owner architect developer qa-engineer security-reviewer devops docs-writer integrator; do
  ck init-file-$r yes "$([ -f "$R/docs/agents/roles/$r.md" ] && echo yes || echo no)"
  ck init-skills-$r yes "$([ -d "$R/docs/agents/skills/$r" ] && echo yes || echo no)"
done
has init-says-created "$R/docs/agents/roles/developer.md" '# Role file: developer'
echo "my rule" >>"$R/docs/agents/roles/developer.md"
snap="$(cat "$R/docs/agents/roles/developer.md")"
out="$(cd "$R" && bash "$RK" init 2>&1)"
ck init-second-changes-nothing "$snap" "$(cat "$R/docs/agents/roles/developer.md")"
has init-second-reports "$(printf '%s' "$out" > "$T/o2"; echo "$T/o2")" 'already present'

# --- scripts seam: migrate
M="$T/mem"; mkdir -p "$M/developer" "$M/factory-architect" "$M/other-agent"
echo "dev craft note" >"$M/developer/MEMORY.md"
echo "arch note" >"$M/factory-architect/MEMORY.md"
echo "keep me" >"$M/other-agent/MEMORY.md"
out="$(cd "$R" && bash "$RK" migrate --from "$M" 2>&1)"; rc=$?
ck migrate-rc 0 "$rc"
has migrate-dev-moved "$R/docs/agents/roles/developer.md" 'dev craft note'
has migrate-arch-moved "$R/docs/agents/roles/architect.md" 'arch note'
has migrate-heading "$R/docs/agents/roles/developer.md" '## Migrated memory'
ck migrate-keeps-source-by-default yes "$([ -f "$M/developer/MEMORY.md" ] && echo yes || echo no)"
c1="$(grep -c 'dev craft note' "$R/docs/agents/roles/developer.md")"
( cd "$R" && bash "$RK" migrate --from "$M" >/dev/null 2>&1 )
ck migrate-twice-no-duplicate "$c1" "$(grep -c 'dev craft note' "$R/docs/agents/roles/developer.md")"
( cd "$R" && bash "$RK" migrate --from "$M" --remove-source >/dev/null 2>&1 )
ck migrate-remove-source-dev no "$([ -e "$M/developer" ] && echo yes || echo no)"
ck migrate-remove-source-arch no "$([ -e "$M/factory-architect" ] && echo yes || echo no)"
ck migrate-leaves-foreign yes "$([ -f "$M/other-agent/MEMORY.md" ] && echo yes || echo no)"
ck migrate-none-rc 0 "$(cd "$R" && bash "$RK" migrate --from "$T/nonexistent" >/dev/null 2>&1; echo $?)"

# --- standard-text seam
has std-section "$PR_" '## Role knowledge'
has std-own-file "$PR_" 'docs/agents/roles/<your role>.md'
has std-own-skills "$PR_" 'docs/agents/skills/<your role>/'
has std-hook-refuses "$PR_" 'a hook refuses a read of another role'"'"'s role file or skills folder'
has std-shared-readable "$PR_" 'Shared project documents stay readable'
has std-fence-add-only "$PR_" 'add rules, checks and knowledge'
has std-fence-never-lift "$PR_" 'never lift a protocol guard, an ownership rule or a one-way-door rule'
has std-fence-permanent "$PR_" 'The fence is permanent: it does not expire with the run.'
has std-no-effect "$PR_" 'has no effect'
has std-lead-reports "$PR_" 'the lead reports it'
has std-promotion "$PR_" 'promotes it into the shared glossary (`CONTEXT.md`) or a domain plugin'
has std-one-agent "$PR_" 'There is exactly one agent per role'
has std-user-scope-prefs "$PR_" 'User scope keeps only personal preferences'
hasnt std-no-user-memory-dir "$PR_" 'Your memory directory holds craft'
has run-reads-role-files "$SK" 'Role knowledge'
has run-reports-lift "$SK" 'reports it to the person'
has run-promotes "$SK" 'promote'
has setup-step "$SU" 'role-knowledge.sh" init'
has setup-migrate "$SU" 'role-knowledge.sh" migrate'
has setup-asks-remove "$SU" '--remove-source'
for a in architect developer devops docs-writer product-owner qa-engineer security-reviewer integrator; do
  has agent-$a-reads-role-file "$PLUGIN/agents/$a.md" 'docs/agents/roles/'
  hasnt agent-$a-no-user-memory "$PLUGIN/agents/$a.md" 'memory: user'
done
ck one-agent-per-role 8 "$(ls "$PLUGIN/agents" | wc -l | tr -d ' ')"
has adr4-superseded "$REPO/docs/adr/0004-role-memory-uses-user-scope.md" 'Revised by slice 115'
has glossary-role-file "$REPO/CONTEXT.md" '**Role file**'
done_
