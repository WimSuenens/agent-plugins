#!/bin/bash
# The code fences of the run skill are balanced, and the sections after the Overrides example are real sections.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
RUN="$PLUGIN/skills/run/SKILL.md"
for f in "$RUN" "$PLUGIN"/references/*.md "$PLUGIN"/agents/*.md; do
  n="$(grep -c '^[[:space:]]*```' "$f")"
  ck "fences-balanced-$(basename "$f")" 0 "$((n % 2))"
done
# no top-level heading sits inside a fence in SKILL.md except the Overrides example's own two
inside="$(awk '/^```/{f=!f; next} f && /^## (Skill graduation|Role knowledge)/' "$(run_all_file)" | wc -l | tr -d ' ')"
ck sections-outside-fence 0 "$inside"
ck overrides-example-intact 1 "$(awk '/^```/{f=!f; next} f && /^## Overrides$/{c++} END{print c+0}' "$(run_all_file)")"
done_
