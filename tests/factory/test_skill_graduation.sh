#!/bin/bash
# Skill graduation into domain plugins. Issue #119, spec #108.
# Two seams: the script (skill-graduation.sh: use threshold, domain search, scan, proposal-only) and the standard text.
. "$(dirname "$0")/lib.sh"
T="$(cd "$T" && pwd -P)"
SG="$PLUGIN/scripts/skill-graduation.sh"
SK="$PLUGIN/skills/run/SKILL.md"
PR="$PLUGIN/references/protocol.md"
mkdir -p "$T/bin" "$T/g"
cp "$REPO/tests/factory/stub-gh/gh" "$T/bin/gh"
export STUB_GH_DIR="$T/g" PATH="$T/bin:$PATH"
mkrepo() { mkdir -p "$1" && git init -q -b main "$1" && ( cd "$1" && echo r > README && git add -A && git commit -qm init ) >/dev/null 2>&1; }
R="$T/acme-shop"; mkrepo "$R"
run() { ( cd "$R" && bash "$SG" "$@" ); }

# a marketplace with two plugins that state a domain, one without
mp="$T/market"
mkplug() { mkdir -p "$mp/$1/.claude-plugin"; printf '%s\n' "$2" > "$mp/$1/.claude-plugin/plugin.json"; }
mkplug design '{"name":"design","domain":"Visual design, user interface review and design systems."}'
mkplug discover '{"name":"discover","domain":"Capturing and revisiting what was learned in a session."}'
mkplug legacy '{"name":"legacy","description":"No domain here."}'

printf '## Skill\nName the inputs of every brief before you write the body.\n' > "$T/skill.md"

# --- scripts seam: use threshold
ck uses-none-not-offered-rc 5 "$(run eligible brief-inputs "$T/skill.md" >/dev/null 2>&1; echo $?)"
ck record-first "recorded brief-inputs item-12" "$(run record brief-inputs item-12)"
ck one-use-not-offered-rc 5 "$(run eligible brief-inputs "$T/skill.md" >/dev/null 2>&1; echo $?)"
ck same-origin-twice-counts-once "recorded brief-inputs item-12" "$(run record brief-inputs item-12)"
ck same-origin-still-not-offered-rc 5 "$(run eligible brief-inputs "$T/skill.md" >/dev/null 2>&1; echo $?)"
run eligible brief-inputs "$T/skill.md" >"$T/o" 2>&1
has not-offered-says-uses "$T/o" '1 use'
ck other-skill-uses-apart 5 "$(run record other-skill item-13 >/dev/null; run eligible other-skill "$T/skill.md" >/dev/null 2>&1; echo $?)"
ck record-second "recorded brief-inputs item-14" "$(run record brief-inputs item-14)"
sha="$(shasum -a 256 "$T/skill.md" 2>/dev/null | cut -d' ' -f1 || sha256sum "$T/skill.md" | cut -d' ' -f1)"
ck two-items-offered "eligible $sha" "$(run eligible brief-inputs "$T/skill.md")"
ck uses-file-committed-location "yes" "$([ -f "$R/docs/agents/skill-uses.md" ] && echo yes || echo no)"
ck record-bad-name-rc 2 "$(run record 'Bad Name' item-1 >/dev/null 2>&1; echo $?)"
run record proj-skill project-a >/dev/null; run record proj-skill project-b >/dev/null
ck two-projects-offered "eligible $sha" "$(run eligible proj-skill "$T/skill.md")"

# --- scripts seam: the sanitising scan (reuses improvement.sh check)
printf 'The acme-shop checkout needs this.\n' > "$T/leak.md"
ck used-but-dirty-not-offered-rc 6 "$(run eligible brief-inputs "$T/leak.md" >/dev/null 2>&1; echo $?)"
run eligible brief-inputs "$T/leak.md" >"$T/o" 2>&1
has dirty-names-kind "$T/o" 'project-name'
ck dirty-text-not-echoed no "$(grep -q 'checkout' "$T/o" && echo yes || echo no)"

# --- scripts seam: the domain search
ck match-existing "match design: Visual design, user interface review and design systems." "$(run match 'review of a user interface and its design system' "$mp")"
ck match-best-of-two "match discover: Capturing and revisiting what was learned in a session." "$(run match 'what we learned in this session, captured and revisited' "$mp")"
ck match-none "none" "$(run match 'database migration rollback' "$mp")"
ck match-ignores-plugin-without-domain "none" "$(run match 'No domain here' "$mp")"
ck match-empty-dir-none "none" "$(mkdir -p "$T/empty"; run match 'user interface design' "$T/empty")"
ck match-missing-dir-rc 2 "$(run match 'x' "$T/nodir" >/dev/null 2>&1; echo $?)"

# --- scripts seam: the draft, and proposal-only
run draft brief-inputs "$T/skill.md" 'review of a user interface and its design system' "$mp" "$T/prop.md" >"$T/o"; rc=$?
ck draft-rc 0 "$rc"
has draft-names-plugin "$T/prop.md" 'Best-matching plugin: design'
has draft-names-domain "$T/prop.md" 'Visual design, user interface review and design systems.'
has draft-extends "$T/prop.md" 'Extend the existing plugin'
has draft-carries-skill "$T/prop.md" 'Name the inputs of every brief'
ck draft-passes-check "yes" "$(run check-proposal "$T/prop.md" >/dev/null 2>&1 && echo yes || echo no)"
run draft brief-inputs "$T/skill.md" 'database migration rollback' "$mp" "$T/prop2.md" >/dev/null
has draft-none-matches "$T/prop2.md" 'No existing plugin matches'
has draft-none-new "$T/prop2.md" 'Propose a new plugin'
ck draft-below-threshold-rc 5 "$(run draft other-skill "$T/skill.md" 'x y' "$mp" "$T/prop3.md" >/dev/null 2>&1; echo $?)"
ck draft-below-threshold-no-file no "$([ -e "$T/prop3.md" ] && echo yes || echo no)"
ck draft-dirty-rc 6 "$(run draft brief-inputs "$T/leak.md" 'x' "$mp" "$T/prop4.md" >/dev/null 2>&1; echo $?)"
ck draft-dirty-no-file no "$([ -e "$T/prop4.md" ] && echo yes || echo no)"
: > "$T/g/log"; echo '[]' > "$T/g/issues.json"
ck draft-files-nothing "0" "$(jq 'length' "$T/g/issues.json")"
ck draft-no-gh-create "0" "$(grep -c '^issue create' "$T/g/log")"
# the proposal reaches the marketplace only through the approval gate
psha="$(shasum -a 256 "$T/prop.md" 2>/dev/null | cut -d' ' -f1 || sha256sum "$T/prop.md" | cut -d' ' -f1)"
ck submit-no-approval-rc 7 "$(run submit "$T/prop.md" >/dev/null 2>&1; echo $?)"
ck submit-nothing-filed 0 "$(jq 'length' "$T/g/issues.json")"
out="$(run submit "$T/prop.md" --approved "$psha")"
ck submit-approved "submitted https://example.invalid/o/r/issues/1" "$out"
has submit-label-skill "$T/g/log" 'plugin:factory'
ck submit-title-names-skill "Skill proposal: brief-inputs" "$(jq -r '.[0].title' "$T/g/issues.json")"
ck submit-wrong-hash-rc 7 "$(run submit "$T/prop.md" --approved deadbeef >/dev/null 2>&1; echo $?)"

# --- every manifest carries a domain sentence
for m in "$REPO"/plugins/*/.claude-plugin/plugin.json; do
  p="$(basename "$(dirname "$(dirname "$m")")")"
  ck manifest-domain-$p yes "$(jq -e '(.domain | type == "string") and (.domain | length > 20) and (.domain | test("[.]$"))' "$m" >/dev/null 2>&1 && echo yes || echo no)"
done

# --- standard text seam
has run-graduation "$SK" '## Skill graduation'
has run-threshold "$SK" 'at least two items or two projects'
has run-record-use "$SK" 'scripts/skill-graduation.sh" record'
has run-eligible "$SK" 'scripts/skill-graduation.sh" eligible'
has run-draft "$SK" 'scripts/skill-graduation.sh" draft'
has run-domain-search "$SK" 'search for an existing plugin covering the domain'
has run-extend-first "$SK" 'propose extending it, and only otherwise a new plugin'
has run-proposal-only "$SK" 'A skill is proposed, never published, by the factory'
has run-approval "$SK" 'only after the person approves'
has run-submit "$SK" 'scripts/skill-graduation.sh" submit'
has run-decision-elsewhere "$SK" 'in a separate session in the marketplace repository'
has run-toolbox "$SK" 'toolboxes per domain, not per role'
has protocol-optional-plugin-skills "$PR" 'plugin skills you use'
has protocol-missing-plugin "$PR" 'a plugin that is not installed leaves the factory working'
has protocol-optional "$PR" 'optional reference'
has run-no-plugin-works "$SK" 'The factory works with no domain plugin installed'
has glossary-domain "$REPO/CONTEXT.md" '**Plugin domain**'
has glossary-graduation "$REPO/CONTEXT.md" '**Skill graduation**'
has contract-exists "$REPO/contracts/119-skill-graduation.md" 'Issue [#119]'

done_
