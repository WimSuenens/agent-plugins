#!/bin/bash
# Bundle B (factory 3.7.0): the text rules of #249, #251, #241 and #242, one pin per rule. Each pin was written before the text it pins.
# The Summary limit sits in references/run-roles.md because protocol *Messages* is byte-pinned by the fence fixture (test_ownership_tdd.sh).
. "$(dirname "$0")/lib.sh"
RUN="$PLUGIN/skills/run/SKILL.md"; PROTO="$PLUGIN/references/protocol.md"; RR="$PLUGIN/references/run-roles.md"
AG="$PLUGIN/agents"
done_of() { awk '/^## Done$/ {f=1; next} f && /^## / {f=0} f' "$1"; }
pin() { # pin <name> <file> <fixed string>, in a Done list of an agent file
  if done_of "$2" | grep -qF -- "$3"; then echo "ok   $1"; passed=$((passed + 1)); else echo "FAIL $1: '$3' not in the Done list of ${2#$REPO/}"; fail=1; fi
}

# ---- #249 conformance before the build
pin b249-qa-checks-responses-against-schema "$AG/qa-engineer.md" "each response shape and status a test reads is checked against the contract's schema"
pin b249-qa-static-read-not-run "$AG/qa-engineer.md" "before the stage ends, as a static read, not a run"
pin b249-qa-no-schema-no-line "$AG/qa-engineer.md" "where the contract defines no schema this line does not apply"
pin b249-architect-public-operations-explicit "$AG/architect.md" "Every operation the slice contract names public carries an explicit statement that no authentication is required"

# ---- #251 agent context across slices
has b251-fresh-agent-first-task "$RUN" "**Fresh or resumed.** The first task of a role in a new slice gets a fresh agent"
has b251-resume-only-rework-same-slice "$RUN" "Resume an agent only for a rework in the same slice"
has b251-number-named "$RUN" "below 200,000 tokens of peak context"
has b251-number-provisional "$RUN" "(provisional)"
has b251-how-the-lead-reads-peak "$RUN" 'token-spend.sh" <the agent'"'"'s transcript>`, the `peak` figure'
has b251-knowledge-in-repo "$RUN" "Project knowledge lives in the repository and the role files, not in the agent's context."
has b251-revisit-trigger "$RUN" "After the next two runs, read the peak per role task and move the number."
has b251-one-agent-per-role-per-slice "$RUN" "there is one agent per role in each slice and never a second in the same slice"
hasnt b251-old-sentence-gone "$RUN" "there is one agent per role and never a second."
ck b251-router-within-cap 1 "$([ "$(wc -c < "$RUN")" -le 70000 ] && echo 1 || echo 0)"

# ---- #241 the stale-text search
pin b241-digit-and-word-form "$AG/architect.md" "a changed figure is searched in its digit and its word form"
pin b241-partial-statement "$AG/architect.md" "a statement that names only part of what the change now covers (one kind where there are now two, one language where there are now two) is searched for as well"
pin b241-search-terms-listed "$AG/architect.md" "The contract lists its search terms next to its list of stale texts, so a reviewer can see which spellings were tried."
has b241-lead-search-points-to-architect "$RUN" "spellings as in the architect's Done list"

# ---- #242 the Summary limit
has b242-rule-stated-once "$RR" "The Summary field of a result, bullets included, is at most 10 lines; detail goes in Progress or Artifacts"
has b242-count-before-hand-back "$RR" "Count the lines before you hand back"
has b242-protocol-states-number "$PROTO" "Summary: <at most 10 lines>"
for f in "$AG"/*.md; do
  pin "b242-pointer-$(basename "$f" .md)" "$f" "Summary at most 10 lines, bullets included (\`references/run-roles.md\`, *Summary limit*)"
done
ck b242-rule-not-copied-into-agents 0 "$(grep -l 'detail goes in Progress or Artifacts' "$AG"/*.md | wc -l | tr -d ' ')"

done_
