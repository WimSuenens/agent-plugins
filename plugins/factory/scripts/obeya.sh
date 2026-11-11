#!/usr/bin/env bash
# Starts or stops the Obeya for the project you are in.
# Usage: bash obeya.sh [start|stop] [--login-token]     (no word: stops when running, starts otherwise)
#        bash obeya.sh check-pin                         (release check: the pinned image tag exists in the registry)
# Opt-in: line "obeya: on" at column 0 of docs/agents/factory.md. Without it nothing starts.
# Token (passed through the environment, never written to disk):
#   default      GH_TOKEN=<read-only token> read from the untracked file $OBEYA_ENV_FILE (default ~/.config/obeya/env)
#   --login-token  your own `gh auth token`, with a printed warning (broader than needed)
# Port: $OBEYA_PORT (default 4777), published on 127.0.0.1 only.
# Exit: 0 ok; 1 a refusal or failure, with one line on stderr naming what to fix; 2 usage.

die() { echo "obeya: $*" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH"

here="$(cd "${0%/*}" && pwd)"
compose="$(cd "$here/.." && pwd)/obeya/compose.yml"
envfile="${OBEYA_ENV_FILE:-$HOME/.config/obeya/env}"
port="${OBEYA_PORT:-4777}"

image="$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' "$compose" | head -n1)"
dc() { docker compose -f "$compose" "$@"; }

cmd=""; login=0
for a in "$@"; do
  case "$a" in
    start | stop | check-pin) cmd="$a" ;;
    --login-token) login=1 ;;
    *) echo "usage: obeya.sh [start|stop|check-pin] [--login-token]" >&2; exit 2 ;;
  esac
done

if [ "$cmd" = check-pin ]; then
  docker buildx imagetools inspect "$image" >/dev/null 2>&1 || die "pinned image $image does not exist in the registry"
  echo "obeya: pinned image $image exists"
  exit 0
fi

# the project: the main checkout, also when run from one of its worktrees
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || common=""
case "$common" in
  */.git) project="${common%/.git}" ;;
  *) project="$(git rev-parse --show-toplevel 2>/dev/null)" || project="" ;;
esac
[ -n "$project" ] || die "not inside a git project"
project="$(cd "$project" && pwd -P)"

grep -q '^obeya: on[[:space:]]*$' "$project/docs/agents/factory.md" 2>/dev/null ||
  die "not enabled: set 'obeya: on' in docs/agents/factory.md"

export OBEYA_PROJECT_PATH="$project" OBEYA_PORT="$port"

running="$(dc ps -q 2>/dev/null)"
if [ "$cmd" = stop ] || { [ -z "$cmd" ] && [ -n "$running" ]; }; then
  if [ -z "$running" ]; then echo "obeya: not running"; exit 0; fi
  dc down >/dev/null 2>&1 || die "docker could not stop the Obeya: run 'docker compose -p obeya down'"
  echo "obeya: stopped"
  exit 0
fi

if [ -n "$running" ]; then echo "obeya: already running at http://127.0.0.1:$port"; exit 0; fi

if [ "$login" = 1 ]; then
  GH_TOKEN="$(gh auth token 2>/dev/null)" && [ -n "$GH_TOKEN" ] || die "gh auth token gave no token: run 'gh auth login' or use a read-only token in $envfile"
  echo "obeya: warning: --login-token uses your own gh login token, which is broader than needed; prefer a read-only token in $envfile" >&2
else
  GH_TOKEN=""
  [ -f "$envfile" ] && GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' "$envfile" | head -n1)"
  [ -n "${GH_TOKEN:-}" ] || die "no token: put GH_TOKEN=<read-only token> in $envfile or pass --login-token"
fi
export GH_TOKEN

# port probe: a successful connect means something holds it
if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
  die "port $port is in use: stop what holds it or set OBEYA_PORT to a free port"
fi

dc pull -q >/dev/null 2>&1 || die "image $image cannot be pulled: check the tag pinned in $compose and your network"
dc up -d >/dev/null 2>&1 || die "docker could not start the Obeya: run 'docker compose -f $compose up' to see why"
echo "obeya: http://127.0.0.1:$port"
