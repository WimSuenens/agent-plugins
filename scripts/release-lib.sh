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
  case "$2" in
    major) echo "$((o_major + 1)).0.0" ;;
    minor) echo "$o_major.$((o_minor + 1)).0" ;;
    *) echo "$o_major.$o_minor.$((o_patch + 1))" ;;
  esac
}

# A slice may DECLARE its class in its changelog entry: a line `Release: major (<reason>)` (or minor, or patch; the reason is
# mandatory for a major). The declaration can only raise the class: the class computed from the changed paths is the floor, and a
# declaration below it is refused. These functions are the one reading of a declaration (#207 slice 3).
rel_rank() { case "$1" in major) echo 3 ;; minor) echo 2 ;; *) echo 1 ;; esac; }

# rel_parse_decl <text>, the text after `Release: `: sets REL_DECL (major|minor|patch, or empty when it is no declaration),
# REL_DECL_WHY (the reason in brackets) and REL_DECL_BAD (`reason` for a major without a reason).
rel_parse_decl() {
  local t cls rest why
  REL_DECL=""; REL_DECL_WHY=""; REL_DECL_BAD=""
  t="$(printf '%s' "$1" | tr -d '\r')"
  cls="$(printf '%s' "$t" | sed -n 's/^\([A-Za-z][A-Za-z]*\).*/\1/p' | tr 'A-Z' 'a-z')"
  case "$cls" in major | minor | patch) ;; *) return 0 ;; esac
  rest="${t#"${t%%[![:space:]]*}"}"; rest="${rest:${#cls}}"; rest="${rest#"${rest%%[![:space:]]*}"}"
  why=""
  case "$rest" in "("*")") why="${rest#(}"; why="${why%)}" ;; esac
  why="${why#"${why%%[![:space:]]*}"}"; why="${why%"${why##*[![:space:]]}"}"
  REL_DECL="$cls"; REL_DECL_WHY="$why"
  if [ "$cls" = major ] && [ -z "$why" ]; then REL_DECL_BAD=reason; fi
  return 0
}

# rel_read_declared <base>: the declaration among the changelog lines this branch ADDED (not the entries main already holds).
# Sets REL_DECL, REL_DECL_WHY, REL_DECL_BAD; the highest class wins, a bad one stops the reading.
rel_read_declared() {
  local line bd="" bw="" bad="" added
  added="$(git diff -U0 --no-renames "$1...HEAD" -- CHANGELOG.md 2>/dev/null)"
  while IFS= read -r line; do
    case "$line" in "+Release: "*) ;; *) continue ;; esac
    rel_parse_decl "${line#+Release: }"
    [ -n "$REL_DECL" ] || continue
    if [ -n "$REL_DECL_BAD" ]; then bad="$REL_DECL_BAD"; bd="$REL_DECL"; bw=""; break; fi
    if [ -z "$bd" ] || [ "$(rel_rank "$REL_DECL")" -gt "$(rel_rank "$bd")" ]; then bd="$REL_DECL"; bw="$REL_DECL_WHY"; fi
  done <<<"$added"
  REL_DECL="$bd"; REL_DECL_WHY="$bw"; REL_DECL_BAD="$bad"
}

# rel_apply_declared: after rel_add, with REL_DECL set. REL_LOWER=1 when the declaration is below the computed class (refuse);
# REL_RAISED=1 when it raises it (REL_LEVEL and REL_WHAT then say the declared class).
rel_apply_declared() {
  REL_LOWER=0; REL_RAISED=0
  [ -n "$REL_DECL" ] || return 0
  if [ "$(rel_rank "$REL_DECL")" -lt "$(rel_rank "$REL_LEVEL")" ]; then REL_LOWER=1; return 0; fi
  if [ "$(rel_rank "$REL_DECL")" -gt "$(rel_rank "$REL_LEVEL")" ]; then
    REL_RAISED=1; REL_LEVEL="$REL_DECL"
    REL_WHAT="declared${REL_DECL_WHY:+: $REL_DECL_WHY}"
  fi
}
