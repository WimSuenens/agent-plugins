#!/bin/bash
# #122 Obeya ADRs: structure of the three one-way ADRs and the glossary terms (structure only, no prose assertions).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
cd "$REPO" || exit 1

pick() { ls docs/adr/ | grep -E "^[0-9]{4}-.*$1" | head -1; }
for key in lens nuxt read-only; do
  f=$(pick "$key")
  if [ -z "$f" ]; then echo "FAIL adr-$key: no ADR file with '$key' in its name"; fail=1; continue; fi
  p="docs/adr/$f"
  has "adr-$key-status" "$p" "status:"
  for h in "## Context" "## Decision" "## Consequences" "## Way back"; do has "adr-$key $h" "$p" "$h"; done
done
# numbers are unique
n=$(ls docs/adr | grep -E '^[0-9]{4}-' | cut -c1-4 | sort | uniq -d | wc -l | tr -d ' ')
ck adr-no-duplicate-numbers 0 "$n"
adr2=$(pick nuxt)
[ -n "$adr2" ] && has adr-nuxt-visibility "docs/adr/$adr2" "GHCR"
for t in "Obeya room" "Lens" "Source (seam)" "Read model" "Provenance" "Theme"; do has "glossary-$t" CONTEXT.md "**$t**"; done
done_
