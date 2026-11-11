#!/usr/bin/env bash
# Role knowledge lives in the project: docs/agents/roles/<role>.md and docs/agents/skills/<role>/.
# Usage: role-knowledge.sh init
#        role-knowledge.sh migrate [--from <agent-memory dir>] [--remove-source]
# Run from the project root. init is idempotent; migrate copies each role's user-scope memory into its role file once.
# migrate scans each memory file first (post-text.sh scan: home paths, secrets, work paths). A flagged file is not migrated:
# it is reported ("skipped <file>: flagged by the scan (<kinds>)"), exit stays 0, and --remove-source never removes it.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
  n=0; nskip=0
  for r in $roles; do
    for d in "$from/$r" "$from/factory-$r" "$from/factory:$r"; do
      [ -d "$d" ] || continue
      f="$rdir/$r.md"; skipped=0
      for m in "$d"/*.md; do
        [ -f "$m" ] || continue
        if ! hits="$(bash "$here/post-text.sh" scan "$m" 2>&1)"; then
          kinds="$(printf '%s\n' "$hits" | sed -n 's/^scan: [^:]*:[0-9]*: //p' | sort -u | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
          echo "skipped $(basename "$d")/$(basename "$m"): flagged by the scan (${kinds:-unreadable}); not migrated, source kept"
          skipped=$((skipped + 1)); nskip=$((nskip + 1)); continue
        fi
        mark="<!-- migrated: $(basename "$d")/$(basename "$m") -->"
        if ! grep -qF -- "$mark" "$f"; then
          grep -q '^## Migrated memory$' "$f" || printf '\n## Migrated memory\n' >>"$f"
          { printf '\n%s\n' "$mark"; cat "$m"; } >>"$f"
          n=$((n + 1))
        fi
      done
      if [ "$rm_src" = 1 ]; then
        if [ "$skipped" = 0 ]; then rm -rf "$d"
        else
          # a flagged file stays: remove only the files that were migrated, then the directory if nothing is left
          for m in "$d"/*.md; do
            [ -f "$m" ] && grep -qF -- "<!-- migrated: $(basename "$d")/$(basename "$m") -->" "$f" && rm -f "$m"
          done
          rmdir "$d" 2>/dev/null
        fi
      fi
    done
  done
  echo "migrated $n files"
  [ "$nskip" = 0 ] || echo "skipped $nskip flagged files; the person reviews them before they leave the user scope"
  ;;
*) echo "usage: role-knowledge.sh init | migrate [--from <dir>] [--remove-source]" >&2; exit 64 ;;
esac
