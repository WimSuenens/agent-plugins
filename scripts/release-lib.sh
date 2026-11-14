#!/usr/bin/env bash
# Dev-repo tooling, not part of the factory plugin. Sourced by check-bump.sh and release-class.sh: the ONE place that says which
# class a change to the factory plugin needs (standard text and the run skill: minor; any other factory file: patch) and how a
# manifest version is read and raised (#210). Do not run it.
rel_pj="plugins/factory/.claude-plugin/plugin.json"

# rel_class <path>: the class one path needs: `minor`, `patch`, or nothing for a path outside plugins/factory/.
rel_class() {
  case "$1" in plugins/factory/*) ;; *) return 0 ;; esac
  case "$1" in
    *$'\n'*) echo minor ;;   # a name holding a newline cannot be classified: standard work
    plugins/factory/skills/run/SKILL.md) echo minor ;;
    plugins/factory/references/*/* | plugins/factory/agents/*/*) echo patch ;;
    plugins/factory/references/*.md | plugins/factory/agents/*.md) echo minor ;;
    plugins/factory/references | plugins/factory/references/ | plugins/factory/agents | plugins/factory/agents/) echo minor ;;
    *) echo patch ;;
  esac
}

# rel_reset, then rel_add <path> for each path: sets REL_ANY (1 when a factory path was added), REL_LEVEL (minor or patch) and REL_WHAT.
rel_reset() { REL_ANY=0; REL_LEVEL=patch; REL_WHAT="factory files"; }
rel_add() {
  local c; c="$(rel_class "$1")"
  [ -n "$c" ] || return 0
  REL_ANY=1
  if [ "$c" = minor ]; then REL_LEVEL=minor; REL_WHAT="standard work"; fi
}

# rel_version_at <rev>: the manifest version at a revision, or nothing when absent.
rel_version_at() {
  git show "$1:$rel_pj" 2>/dev/null | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1
}
rel_is_semver() { printf '%s' "$1" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; }

# rel_suggest <old> <level>: the lowest version that satisfies the level.
rel_suggest() {
  local o_major o_minor o_patch rest
  o_major="${1%%.*}"; rest="${1#*.}"; o_minor="${rest%%.*}"; o_patch="${rest#*.}"
  if [ "$2" = minor ]; then echo "$o_major.$((o_minor + 1)).0"; else echo "$o_major.$o_minor.$((o_patch + 1))"; fi
}
