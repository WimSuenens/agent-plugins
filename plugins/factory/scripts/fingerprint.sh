#!/usr/bin/env bash
# Prints the factory label: release, standard fingerprint, tooling fingerprint.
# Usage: bash fingerprint.sh <plugin-root>
# Exit: 0 ok; 2 not a factory root, an unreadable file, or a version that is not MAJOR.MINOR.PATCH; 3 no sha256 tool.
# See contracts/39-plugin-scripts.md section 1 in the repo that hosts the factory.

root="${1:-}"
if [ -z "$root" ] || [ ! -f "$root/skills/run/SKILL.md" ] || [ ! -f "$root/.claude-plugin/plugin.json" ]; then
  echo "fingerprint: not a factory plugin root: $(basename -- "${root:-.}")" >&2
  exit 2
fi
root="${root%/}"

if command -v sha256sum >/dev/null 2>&1; then
  sha() { sha256sum | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sha() { shasum -a 256 | cut -d' ' -f1; }
else
  echo "fingerprint: no sha256sum or shasum found" >&2
  exit 3
fi

# Release: the "version" string of plugin.json, nothing else.
version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/.claude-plugin/plugin.json" | head -n1)"
if [ -z "$version" ] && grep -Eq '"version"[[:space:]]*:' "$root/.claude-plugin/plugin.json"; then
  echo "fingerprint: version in plugin.json is empty, not MAJOR.MINOR.PATCH" >&2
  exit 2
elif [ -z "$version" ]; then
  name="$(basename -- "$root")"
  release="$name (pre-release install, no semver)"
else
  if ! printf '%s' "$version" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
    echo "fingerprint: version '$version' in plugin.json is not MAJOR.MINOR.PATCH" >&2
    exit 2
  fi
  release="$version"
fi

# fingerprint of a newline-separated list of relative paths on stdin
fingerprint() {
  manifest="$(
    LC_ALL=C sort | while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      printf '%s  %s\n' "$(sha < "$root/$rel")" "$rel"
    done
  )"
  if [ -z "$manifest" ]; then
    printf '' | sha
  else
    printf '%s\n' "$manifest" | sha
  fi
}

standard_files() {
  cd "$root" || exit 2
  for f in skills/run/SKILL.md references/*.md agents/*.md; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
  return 0
}

tooling_files() {
  cd "$root" || exit 2
  for d in hooks scripts; do
    [ -d "$d" ] && find "$d" -type f ! -path '*/.*' -print
  done
  return 0
}

# every listed file must be readable, else no fingerprint is printed
std_list="$(standard_files)" || exit 2
tool_list="$(tooling_files)" || exit 2
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  if [ ! -r "$root/$rel" ]; then
    echo "fingerprint: cannot read $rel" >&2
    exit 2
  fi
done <<EOT
$std_list
$tool_list
EOT

standard="$(printf '%s\n' "$std_list" | fingerprint)"
tooling="$(printf '%s\n' "$tool_list" | fingerprint)"

printf 'release: %s\nstandard: %s\ntooling: %s\n' "$release" "$standard" "$tooling"
