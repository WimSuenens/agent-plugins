# Sourced, not run. The one definition of the protected areas, shared by skip.sh and merge-gate.sh:
# contracts, authentication (auth, oauth, login), secrets, migrations, and the one-way door (declared, never a path).
# protected_path_area <path>: prints the area (contract, authentication, secrets, migration, project) and returns 0 for a protected path;
#   the built-in patterns read one path component at a time (*auth*, *login*, *signin*, *secret*, *credential*, .env*, *.pem, *.key, *migrat*, *.sql)
#   after the words that only look like them (author, secretar, immigrat, emigrat, blogin) are taken out, so author and secretary are no hit;
#   `project` is a path matching a glob of the project's line `protected-paths: <glob>, <glob>` at column 0 of docs/agents/factory.md (origin/main's first, see protected_paths_line);
#   prints nothing and returns 1 otherwise. ASCII case is folded.
# protected_touch_area <name>: prints the area for a declared name (contract|contracts, authentication, secrets,
#   migration|data-migration, door|one-way-door) and returns 0; returns 1 for an unknown name.
# protected_paths_line: sets _PP_LINE to the `protected-paths:` line of docs/agents/factory.md and returns 0, or returns 1 when there is none.
#   Read from origin/main first, so a branch cannot drop the line that judges it; the working tree's own file only where origin/main
#   has no such line (the branch that introduces it). Relative to the repository top level, not the current directory; outside a
#   repository, the current directory. Sets _PP_LINE (cached per directory); call it without a command substitution to keep the cache.
protected_paths_line() {
  local top l=""
  if [ "${_PP_KEY-}" != "$PWD" ]; then
    top="$(git rev-parse --show-toplevel 2>/dev/null)"
    [ -n "$top" ] && l="$(git -C "$top" show origin/main:docs/agents/factory.md 2>/dev/null | grep -m 1 '^protected-paths:')"
    if [ -z "$l" ] && [ -r "${top:-.}/docs/agents/factory.md" ]; then l="$(grep -m 1 '^protected-paths:' "${top:-.}/docs/agents/factory.md")"; fi
    _PP_KEY="$PWD"; _PP_LINE="$l"
  fi
  [ -n "$_PP_LINE" ]
}
protected_path_area() {
  local lp rest c w b a="" noglob=0 line g
  lp="$(printf '%s' "$1" | LC_ALL=C tr 'A-Z' 'a-z')"
  # one path component at a time. The word may sit inside a name (authService, userauth, my-secret); the words that only look like it
  # (author, secretary, immigration, blogin) are taken out first, and authoriz* is kept as authz.
  rest="$lp"
  while [ -n "$rest" ]; do
    c="${rest%%/*}"
    case "$rest" in */*) rest="${rest#*/}" ;; *) rest="" ;; esac
    w="${c//authoriz/authz}"
    for b in author secretar immigrat emigrat blogin; do w="${w//$b/_}"; done
    case "$c" in contracts) a=contract ;; esac
    if [ -z "$a" ]; then
      case "$w" in
        *auth* | *login* | *signin*) a=authentication ;;
        .env* | *secret* | *credential* | *.pem | *.key) a=secrets ;;
        *migrat* | *.sql) a=migration ;;
      esac
    fi
    [ -n "$a" ] && { echo "$a"; return 0; }
  done
  # the project's own extension: one line at column 0 in docs/agents/factory.md, `protected-paths: <glob>, <glob>` (shell globs, case folded)
  protected_paths_line || return 1
  line="$(printf '%s' "$_PP_LINE" | tr -d '\r' | LC_ALL=C tr 'A-Z' 'a-z')"
  line="${line#protected-paths:}"
  case "$-" in *f*) noglob=1 ;; esac
  set -f
  local old_ifs="$IFS"; IFS=','
  for g in $line; do
    g="${g#"${g%%[![:space:]]*}"}"; g="${g%"${g##*[![:space:]]}"}"
    [ -n "$g" ] || continue
    # shellcheck disable=SC2254
    case "$lp" in $g) a=project; break ;; esac
  done
  IFS="$old_ifs"
  [ "$noglob" = 1 ] || set +f
  [ -n "$a" ] && { echo "$a"; return 0; }
  return 1
}
# protected_list_paths <list>: the paths to test for a changed-path list (--paths), one per line. A list of several lines is one path per
#   line (a path may hold a space) and is tested as it stands. A one-line list from an older caller may be several paths split by
#   spaces, so a single line is tested whole and, when it holds whitespace, piece by piece as well. Never expands a glob.
protected_list_paths() {
  local e w
  case "$1" in
    *$'\n'*) printf '%s\n' "$1" | while IFS= read -r e; do [ -n "$e" ] && printf '%s\n' "$e"; done; return 0 ;;
  esac
  [ -n "$1" ] || return 0
  printf '%s\n' "$1"
  case "$1" in *[[:space:]]*) set -f; for w in $1; do printf '%s\n' "$w"; done ;; esac
}
protected_touch_area() {
  case "$1" in
    contract | contracts) echo contract ;;
    authentication) echo authentication ;;
    secrets) echo secrets ;;
    migration | data-migration) echo migration ;;
    door | one-way-door) echo door ;;
    *) return 1 ;;
  esac
}
