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
pin b249-architect-public-operations-explicit "$AG/architect.md" "every operation the slice contract names public carries an explicit statement that no authentication is required"

# ---- #251 agent context across slices (the router's Role tasks and Role knowledge are byte-pinned by test_run_split.sh: the rule lives in run-roles.md)
has b251-router-points-to-rule "$RUN" "read \`references/run-roles.md\` (*Fresh or resumed*)"
has b251-fresh-agent-first-task "$RR" "The first task of a role in a new slice gets a fresh agent"
has b251-resume-only-rework-same-slice "$RR" "Resume an agent only for a rework in the same slice"
has b251-number-named "$RR" "below 200,000 tokens of peak context (provisional)"
has b251-how-the-lead-reads-peak "$RR" 'token-spend.sh" <the agent'"'"'s transcript>`, the `peak` figure'
has b251-knowledge-in-repo "$RR" "Project knowledge lives in the repository and the role files, not in the agent's context."
has b251-revisit-trigger "$RR" "After the next two runs, read the peak per role task and move the number."
has b251-one-live-agent-per-role-per-slice "$RR" "there is one live agent per role in each slice, and a fresh agent replaces an over-limit one"
has b251-interruption-and-andon-exempt "$RR" "A resume of the same task after an interruption (\`run-interruptions.md\`) or an andon (\`run-andon.md\`) is not a rework and is exempt"
has b251-unreadable-peak-counts-as-over "$RR" "when the figure cannot be read (a non-zero exit of the script), the agent counts as over the limit: spawn a fresh agent"
has b251-protocol-role-knowledge "$PROTO" "one live agent of it in each slice"
ck b251-router-within-cap 1 "$([ "$(wc -c < "$RUN")" -le 70000 ] && echo 1 || echo 0)"

# ---- #241 the stale-text search
pin b241-digit-and-word-form "$AG/architect.md" "a changed figure is searched in its digit and its word form"
pin b241-partial-statement "$AG/architect.md" "a statement that names only part of what the change now covers (one kind where there are now two, one language where there are now two) is searched for as well"
pin b241-search-terms-listed "$AG/architect.md" "The contract lists its search terms next to its list of stale texts, so a reviewer can see which spellings were tried."

# ---- #242 the Summary limit
has b242-rule-stated-once "$RR" "The Summary field of a result, bullets included, is at most 10 lines; detail goes in Progress or Artifacts"
has b242-header-line-counts "$RR" "The \`Summary:\` line itself is the first of the 10, and a blank line inside the field counts"
has b242-count-before-hand-back "$RR" "Count the lines before you hand back"
# the rule agrees with the lead's render step: 10 lines (the header line included) are accepted, 11 are refused
mk() { { echo "# Result: dev — 1"; echo "Status: done"; echo "Abnormality: none"; echo "Summary: one"; for i in $(seq 2 "$1"); do echo "- line $i"; done; echo "Artifacts: none"; } >"$T/s$1.md"; }
mk 10; mk 11
bash "$PLUGIN/scripts/post-text.sh" render "$T/s10.md" "$T/s10.out" 2>/dev/null; ck b242-render-accepts-10-lines 0 "$?"
bash "$PLUGIN/scripts/post-text.sh" render "$T/s11.md" "$T/s11.out" 2>/dev/null; ck b242-render-refuses-11-lines 3 "$?"
has b242-protocol-states-number "$PROTO" "Summary: <at most 10 lines>"
for f in "$AG"/*.md; do
  pin "b242-pointer-$(basename "$f" .md)" "$f" "Summary at most 10 lines, bullets included (\`references/run-roles.md\`, *Summary limit*)"
done
ck b242-rule-not-copied-into-agents 0 "$(grep -l 'detail goes in Progress or Artifacts' "$AG"/*.md | wc -l | tr -d ' ')"

done_
