#!/usr/bin/env bash
# The setup scan and the project's flow table (setup-factory-skill, step 9a).
# Usage: bash setup-table.sh scan [<project dir>]
#        bash setup-table.sh write [--dir <project dir>] [--confirmed <text>] [<factory.md>]   (default file docs/agents/factory.md)
# scan:  reads the project and prints one finding per line, nothing else, and changes nothing:
#          type: markdown/LLM plugin | static site | code app | unknown
#          test-command: <the project's own test command> | none
#          ci: workflow <file> runs `<command>` on pull requests | none (<reason>)
#          protected-candidates: <paths or folders> | none     (paths the built-in protected patterns hit)
#          deploy: <pipeline, deploy or production config found> | none
#          contracts: <contracts or interfaces others may use> | none
#          visual: yes (<files>) | no
#        These are findings for the person to confirm, not facts: a guess is a candidate, never a rule.
# write: appends two sections to factory.md and touches no other line: `## Flow table` (the eight triggers of the points table with
#        points, what each adds, a reason from the scan and the status `provisional`; the bands; the starting test depth of the project
#        type; the floor) and `## CI` (the `ci:` line). A section or a `ci:` line that is already there is left as it is, so a
#        re-run on a project that has the table changes nothing and prints `already present`. Run it after the person confirmed the
#        table; --confirmed says how (default `at setup`).
# Exit: 0 ok; 2 usage, a missing project folder or a missing factory.md.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=protected-areas.sh
. "$here/protected-areas.sh"

usage() {
  echo "usage: setup-table.sh scan [<project dir>] | write [--dir <project dir>] [--confirmed <text>] [<factory.md>]" >&2
  exit 2
}

# files <dir>: the project's files, relative, without .git, node_modules and the agent worktrees
files() { (cd "$1" && find . \( -name .git -o -name node_modules -o -path ./.claude/worktrees \) -prune -o -type f -print 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort | head -n 20000); }

# collapse: paths on stdin -> at most a handful of entries; a folder with more than 3 hits is named once
collapse() {
  awk '{
    d = $0; sub(/\/[^\/]*$/, "", d); if (d == $0) d = "."
    n[d]++; if (n[d] <= 3) f[d] = f[d] (f[d] == "" ? "" : "\n") $0
  } END { for (d in n) { if (n[d] <= 3) print f[d]; else print d "/ (" n[d] " files)" } }' | LC_ALL=C sort | head -n 6 | paste -sd'|' - | sed 's/|/, /g'
}

scan() {
  local d="$1" list type cmd ci wf pat found nopr cand paths deploy contracts vis c line p a
  [ -d "$d" ] || { echo "setup-table: no project folder $d" >&2; exit 2; }
  list="$(files "$d")"

  # type
  if printf '%s\n' "$list" | grep -qE '(^|/)\.claude-plugin/plugin\.json$|(^|/)skills/[^/]+/SKILL\.md$'; then
    type="markdown/LLM plugin"
  elif printf '%s\n' "$list" | grep -qE '(^|/)(astro\.config\.[a-z]+|eleventy\.config\.[a-z]+|\.eleventy\.js|_config\.yml|hugo\.(toml|yaml|json)|mkdocs\.yml|docusaurus\.config\.[a-z]+|book\.toml)$|(^|/)\.vitepress/config\.[a-z]+$'; then
    type="static site"
  elif printf '%s\n' "$list" | grep -qE '(^|/)(package\.json|pyproject\.toml|requirements\.txt|go\.mod|Cargo\.toml|pom\.xml|build\.gradle|Gemfile|composer\.json)$|\.csproj$'; then
    type="code app"
  else
    type="unknown"
  fi
  echo "type: $type"

  # the project's own test command (root of the project only)
  cmd=""
  if [ -f "$d/package.json" ]; then
    if command -v jq >/dev/null 2>&1; then c="$(jq -r '.scripts.test // empty' "$d/package.json" 2>/dev/null)"; else c="$(grep -o '"test"[[:space:]]*:[[:space:]]*"[^"]*"' "$d/package.json" | head -n1)"; fi
    case "$c" in '' | *"no test specified"*) ;; *) cmd="npm test" ;; esac
  fi
  if [ -z "$cmd" ] && [ -f "$d/Makefile" ] && grep -q '^test:' "$d/Makefile"; then cmd="make test"; fi
  if [ -z "$cmd" ] && [ -f "$d/tests/run.sh" ]; then cmd="bash tests/run.sh"; fi
  if [ -z "$cmd" ] && { [ -f "$d/pytest.ini" ] || { [ -f "$d/pyproject.toml" ] && grep -q 'pytest' "$d/pyproject.toml"; }; }; then cmd="pytest"; fi
  if [ -z "$cmd" ] && [ -f "$d/go.mod" ]; then cmd='go test ./...'; fi
  if [ -z "$cmd" ] && [ -f "$d/Cargo.toml" ]; then cmd="cargo test"; fi
  echo "test-command: ${cmd:-none}"

  # does a workflow run it on pull requests
  if [ -z "$cmd" ]; then
    ci="ci: none (no test command found; the person names it at setup)"
  else
    case "$cmd" in
      "npm test") pat='npm (run )?test|npm t( |$)|yarn( run)? test|pnpm( run)? test' ;;
      "make test") pat='make( -[a-zA-Z]+)* test' ;;
      "bash tests/run.sh") pat='tests/run\.sh' ;;
      "pytest") pat='pytest|py\.test' ;;
      "cargo test") pat='cargo test' ;;
      *) pat='go test' ;;
    esac
    found=""; nopr=""
    for wf in "$d"/.github/workflows/*.yml "$d"/.github/workflows/*.yaml; do
      [ -f "$wf" ] || continue
      grep -v '^[[:space:]]*#' "$wf" | grep -qE "$pat" || continue
      if grep -v '^[[:space:]]*#' "$wf" | grep -qE 'pull_request'; then found="${wf#"$d"/}"; break; fi
      [ -n "$nopr" ] || nopr="${wf#"$d"/}"
    done
    if [ -n "$found" ]; then ci="ci: workflow $found runs \`$cmd\` on pull requests"
    elif [ -n "$nopr" ]; then ci="ci: none (workflow $nopr runs \`$cmd\` but not on pull requests)"
    else ci="ci: none (no workflow runs \`$cmd\`)"; fi
  fi
  echo "$ci"

  # protected-area candidates: what the built-in patterns hit, folders named once
  cand="$(printf '%s\n' "$list" | grep -iE 'auth|login|signin|secret|credential|(^|/)\.env|\.pem$|\.key$|migrat|\.sql$|(^|/)contracts/' | head -n 2000)"
  paths=""
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    a="$(cd "$d" && protected_path_area "$p")" || continue
    paths="${paths}${p}"$'\n'
  done <<<"$cand"
  line="$(printf '%s' "$paths" | collapse)"
  echo "protected-candidates: ${line:-none}"

  deploy="$(printf '%s\n' "$list" | grep -E '(^|/)(Dockerfile[^/]*|docker-compose[^/]*|vercel\.json|netlify\.toml|fly\.toml|Procfile|serverless\.yml|\.gitlab-ci\.yml|azure-pipelines\.yml|Jenkinsfile)$|^\.github/workflows/|(^|/)(deploy|infra|terraform|k8s|helm)/' | collapse)"
  echo "deploy: ${deploy:-none}"
  contracts="$(printf '%s\n' "$list" | grep -iE '(^|/)contracts?/|openapi|swagger|\.proto$|schema\.graphql|\.graphqls?$' | collapse)"
  echo "contracts: ${contracts:-none}"
  vis="$(printf '%s\n' "$list" | grep -E '\.(html|vue|svelte|tsx|jsx|css|scss|astro)$' | collapse)"
  if [ "$type" = "static site" ] && [ -z "$vis" ]; then vis="the site itself"; fi
  if [ -n "$vis" ]; then echo "visual: yes ($vis)"; else echo "visual: no"; fi
}

# val <findings> <key>: the value of a finding line
val() { printf '%s\n' "$1" | sed -n "s/^$2: //p" | head -n1; }

row() { printf '| %s | %s | %s | %s | provisional |\n' "$1" "$2" "$3" "$(printf '%s' "$4" | tr '|' '/')"; }

write() {
  local dir="." conf="at setup" file="" f type depth ci found
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) [ $# -ge 2 ] || usage; dir="$2"; shift 2 ;;
      --confirmed) [ $# -ge 2 ] || usage; conf="$2"; shift 2 ;;
      -*) usage ;;
      *) file="$1"; shift ;;
    esac
  done
  [ -n "$file" ] || file="docs/agents/factory.md"
  [ -f "$file" ] && [ -r "$file" ] || { echo "setup-table: $file is missing: run setup-factory-skill" >&2; exit 2; }
  f="$(scan "$dir")" || exit $?
  type="$(val "$f" type)"
  case "$type" in "markdown/LLM plugin" | "static site") depth="proof-only" ;; *) depth="targeted" ;; esac
  added=0
  if ! grep -q '^## Flow table[[:space:]]*$' "$file"; then
    [ -z "$(tail -c1 "$file")" ] || printf '\n' >>"$file"
    local prot con vis dep logic
    prot="$(val "$f" protected-candidates)"; con="$(val "$f" contracts)"; vis="$(val "$f" visual)"; dep="$(val "$f" deploy)"
    if [ "$prot" = none ]; then prot="the scan found no path the built-in patterns hit; contracts, authentication, secrets and migrations still count when they appear"; else prot="the scan found: $prot"; fi
    if [ "$con" = none ]; then con="the scan found none; the row fires when a change touches an interface others use"; else con="the scan found: $con"; fi
    if [ "$vis" = no ]; then vis="the scan found no visual output; the row fires when a change has one"; else vis="the scan found: ${vis#yes }"; fi
    if [ "$dep" = none ]; then dep="the scan found no pipeline, deploy or production config; the row fires when a change touches one"; else dep="the scan found: $dep"; fi
    if [ "$type" = "code app" ]; then logic="this is a code app: new logic or data behaviour gets tests first"; else logic="this is a $type, not a code app: the row fires only where code with logic exists"; fi
    {
      printf '\n## Flow table\n\n'
      printf 'The points table the lead sizes each destination and each slice with. The path is the sum of the triggers that fire; the lightest path is zero points. The lead may add and adjust rows within the fence and records every change in the hansei. A row turns `settled` after enough slices without a large calibration error.\n\n'
      printf 'table: provisional\n'
      printf 'confirmed: %s\n' "$conf"
      printf 'project-type: %s\n' "$type"
      printf 'test-depth: %s\n' "$depth"
      printf 'bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more\n'
      printf 'floor: never removed by the table: the independent QA verdict, runtime proof, security review and the person'"'"'s merge approval for protected areas, and one-way doors stay with the person.\n\n'
      printf '`test-depth` is the starting depth for this project type: a markdown/LLM plugin or a static site starts at `proof-only`, a code app at `targeted`; full depth exists only after an escalation or an escaped defect.\n\n'
      printf '| Trigger | Points | Adds | Reason | Status |\n|---|---|---|---|---|\n'
      row "Open one-way door" 3 "decision card, ADR (prototype if visual), stays with the person" "a one-way door costs the most to undo, in any project"
      row "Unresolved research question" 3 "research before slicing, map" "an unknown fact makes the size of a slice a guess"
      row "More than 3 expected slices, or dependencies between them" 2 "map, frontier round" "slices that depend on each other need an order before the first one starts"
      row "Protected area touched" 3 "security review, test depth at least targeted, the person's merge approval" "$prot"
      row "Contract or interface used by others" 2 "architect, contract file" "$con"
      row "New logic or data behaviour in a code project" 2 "tests-first (targeted)" "$logic"
      row "Visual result" 1 "demo" "$vis"
      row "Deploy, pipeline or production config (project row)" 3 "devops role, environment stage" "$dep"
    } >>"$file"
    echo "added: flow table ($file)"
    added=1
  fi
  if ! grep -q '^ci:' "$file"; then
    [ -z "$(tail -c1 "$file")" ] || printf '\n' >>"$file"
    ci="$(printf '%s\n' "$f" | grep -m1 '^ci:')"
    {
      printf '\n## CI\n\n%s\n\n' "$ci"
      printf 'Whether a workflow runs the project'"'"'s test command on pull requests. With `ci: none` the merge gate accepts, in place of a check, a recorded local run of the full test command on the pull request'"'"'s head commit (a `## Local run` section in its description: the commit sha, the command, the last line of its output and the time). The gate prints which checks it read, and `ci: none (local run on <sha>)` when it relied on that record.\n'
    } >>"$file"
    echo "added: ci line ($file)"
    added=1
  fi
  [ "$added" = 1 ] || echo "already present"
  return 0
}

case "${1:-}" in
  scan) [ $# -le 2 ] || usage; scan "${2:-.}" ;;
  write) shift; write "$@" ;;
  *) usage ;;
esac
