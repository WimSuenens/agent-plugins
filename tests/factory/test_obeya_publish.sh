#!/bin/bash
# #124 Obeya image publishing: structure of the CI workflow (a workflow cannot be run here; the first real publish is the proof).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
cd "$REPO" || exit 1
w=.github/workflows/obeya-image.yml
if [ ! -f "$w" ]; then echo "FAIL workflow-exists: $w missing"; exit 1; fi
has trigger-dispatch "$w" "workflow_dispatch"
has trigger-main "$w" "branches: [main]"
has trigger-paths "$w" "apps/obeya/**"
has both-arches "$w" "linux/amd64,linux/arm64"
has ghcr "$w" "ghcr.io"
has tag-is-semver "$w" "steps.version.outputs.version"
has version-from-package "$w" "apps/obeya/package.json"
has skip-existing-tag "$w" "imagetools inspect"
has push "$w" "push: true"
hasnt no-latest "$w" "latest"
has least-permissions "$w" "permissions:"
has packages-write "$w" "packages: write"
has contents-read "$w" "contents: read"
hasnt no-write-all "$w" "write-all"
# every third-party action is pinned to a 40-char commit sha
unpinned=$(grep -E '^\s*-?\s*uses:' "$w" | grep -vE '@[0-9a-f]{40}( |$)' | wc -l | tr -d ' ')
ck actions-pinned 0 "$unpinned"
has runbook-step docs/factory/release-runbook.md "Obeya image"
has runbook-bump docs/factory/release-runbook.md "apps/obeya/package.json"
done_
