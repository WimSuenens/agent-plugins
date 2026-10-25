#!/usr/bin/env bash
# PreToolUse guard, registered once for the whole plugin in hooks/hooks.json.
# Rejects tool calls in which one factory role touches another role's agent-memory
# directory. The calling role comes from the hook input's agent_type field.
# Guards against accidental peeking; it is not a security boundary.
roles=" product-owner architect developer qa-engineer security-reviewer devops docs-writer "

raw="$(cat)"
if command -v jq >/dev/null 2>&1; then
  caller="$(printf '%s' "$raw" | jq -r '.agent_type // empty' 2>/dev/null)"
else
  caller="$(printf '%s' "$raw" | grep -oE '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*"([^"]*)"$/\1/')"
fi
caller="${caller##*:}"
# The lead, the person, and agents outside the factory are not guarded.
case "$roles" in *" $caller "*) ;; *) exit 0 ;; esac

# Normalise slashes so Windows paths match too.
input="$(printf '%s' "$raw" | sed -E 's#\\+#/#g; s#/+#/#g')"
while IFS= read -r seg; do
  # Memory directories of plugin agents may carry the plugin name: factory:developer, factory-developer.
  target="${seg##*:}"
  target="${target#factory-}"
  # An empty target is a wildcard across every role's memory.
  if [ -n "$target" ]; then
    case "$roles" in *" $target "*) ;; *) continue ;; esac
    [ "$target" = "$caller" ] && continue
  fi
  echo "Blocked: agent memory of other factory roles is private. Ask the lead for what you need." >&2
  exit 2
done < <(printf '%s' "$input" | grep -oE "agent-memory(-local)?/[^/\"' ,*]*" | sed -E 's#.*/##')
exit 0
