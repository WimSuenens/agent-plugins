#!/usr/bin/env bash
# Role knowledge lives in the project: docs/agents/roles/<role>.md and docs/agents/skills/<role>/.
# Usage: role-knowledge.sh init
#        role-knowledge.sh migrate [--from <agent-memory dir>] [--remove-source]
# Run from the project root. init is idempotent; migrate copies each role's user-scope memory into its role file once.
roles="product-owner architect developer qa-engineer security-reviewer devops docs-writer integrator"
rdir="docs/agents/roles"; sdir="docs/agents/skills"
cmd="${1:-}"; [ $# -gt 0 ] && shift

case "$cmd" in
init)
  made=0
  for r in $roles; do
    mkdir -p "$rdir" "$sdir/$r"
    [ -e "$sdir/$r/.gitkeep" ] || [ -n "$(ls -A "$sdir/$r")" ] || : >"$sdir/$r/.gitkeep"
    if [ -e "$rdir/$r.md" ]; then continue; fi
    cat >"$rdir/$r.md" <<EOT
# Role file: $r

Project rules, checks and knowledge for the $r role, kept under version control. Only the $r role reads this file and its skills folder, \`docs/agents/skills/$r/\`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

## Knowledge

## Skills used
EOT
    made=$((made + 1))
  done
  [ "$made" -gt 0 ] && echo "created $made role files" || echo "already present"
  ;;
migrate)
  from="$HOME/.claude/agent-memory"; rm_src=0
  while [ $# -gt 0 ]; do
    case "$1" in --from) from="$2"; shift ;; --remove-source) rm_src=1 ;; esac
    shift
  done
  [ -d "$from" ] || { echo "nothing to migrate"; exit 0; }
  bash "$0" init >/dev/null
  n=0
  for r in $roles; do
    for d in "$from/$r" "$from/factory-$r" "$from/factory:$r"; do
      [ -d "$d" ] || continue
      f="$rdir/$r.md"
      for m in "$d"/*.md; do
        [ -f "$m" ] || continue
        mark="<!-- migrated: $(basename "$d")/$(basename "$m") -->"
        if ! grep -qF -- "$mark" "$f"; then
          grep -q '^## Migrated memory$' "$f" || printf '\n## Migrated memory\n' >>"$f"
          { printf '\n%s\n' "$mark"; cat "$m"; } >>"$f"
          n=$((n + 1))
        fi
      done
      [ "$rm_src" = 1 ] && rm -rf "$d"
    done
  done
  echo "migrated $n files"
  ;;
*) echo "usage: role-knowledge.sh init | migrate [--from <dir>] [--remove-source]" >&2; exit 64 ;;
esac
