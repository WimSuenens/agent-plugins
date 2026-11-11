#!/bin/bash
# #125 Obeya plugin shell: obeya.sh start/stop, the compose file, the pin check. Stub docker, stub gh; nothing real is started.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
OB="$PLUGIN/scripts/obeya.sh"
CF="$PLUGIN/obeya/compose.yml"
SD="$REPO/tests/factory/stub-docker"
chmod +x "$SD/docker"

# a project folder (git repo) with a factory.md; $2 = extra factory.md text
mkproj() {
  local p="$T/$1"; mkdir -p "$p/docs/agents" && git -C "$p" init -q
  printf 'factory-state: 2\n\n# Factory\n%s\n' "${2:-}" >"$p/docs/agents/factory.md"
  echo "$p"
}
export STUB_DOCKER_DIR="$T/dk"; mkdir -p "$STUB_DOCKER_DIR"
TOKEN_ENV="$T/obeya.env"
SHIM="$T/shim"; mkdir -p "$SHIM"
printf '#!/bin/bash\n[ "$1 $2" = "auth token" ] && { echo "gho_LOGINTOKEN"; exit 0; }\nexit 99\n' >"$SHIM/gh"; chmod +x "$SHIM/gh"
# run <project> <args...>: runs obeya.sh from inside the project with the stubs first on PATH
run() {
  local p="$1"; shift
  ( cd "$p" && PATH="$SD:$SHIM:$PATH" OBEYA_ENV_FILE="$TOKEN_ENV" OBEYA_PORT="${PORT:-47731}" bash "$OB" "$@" 2>"$T/err"; echo $? >"$T/rc" ) >"$T/out"
}
reset() { rm -f "$STUB_DOCKER_DIR"/*; rm -f "$TOKEN_ENV"; unset STUB_DOCKER_NOIMAGE; }
lines() { wc -l <"$1" | tr -d ' '; }

# opt-in missing
reset; P=$(mkproj off "obeya: off")
run "$P" start
ck optin-missing-exit 1 "$(cat "$T/rc")"
has optin-missing-line "$T/err" "obeya: not enabled: set 'obeya: on' in docs/agents/factory.md"
ck optin-missing-one-line 1 "$(lines "$T/err")"
ck optin-missing-no-docker-call "" "$(cat "$STUB_DOCKER_DIR/log" 2>/dev/null)"
P2=$(mkproj absent ""); run "$P2" start
ck optin-absent-exit 1 "$(cat "$T/rc")"

# docker missing (a PATH with no docker)
P=$(mkproj on1 "obeya: on")
EMPTY="$T/empty"; mkdir -p "$EMPTY"
( cd "$P" && EMPTY="$EMPTY" /bin/bash -c 'PATH="$EMPTY"; /bin/bash "$0" start' "$OB" ) >/dev/null 2>"$T/err"; echo $? >"$T/rc"
ck docker-missing-exit 1 "$(cat "$T/rc")"
has docker-missing-line "$T/err" "obeya: docker is not installed or not on PATH"
ck docker-missing-one-line 1 "$(lines "$T/err")"

# no token
reset; run "$P" start
ck no-token-exit 1 "$(cat "$T/rc")"
has no-token-line "$T/err" "obeya: no token: put GH_TOKEN=<read-only token> in $TOKEN_ENV or pass --login-token"
ck no-token-not-started "" "$(ls "$STUB_DOCKER_DIR/running" 2>/dev/null)"

# env-file token (documented path): starts, prints URL, no warning
reset; printf 'GH_TOKEN=github_pat_READONLY\n' >"$TOKEN_ENV"
run "$P" start
ck start-exit 0 "$(cat "$T/rc")"
has start-url "$T/out" "http://127.0.0.1:47731"
ck start-running yes "$([ -f "$STUB_DOCKER_DIR/running" ] && echo yes)"
has envfile-token-passed "$STUB_DOCKER_DIR/env" "GH_TOKEN=github_pat_READONLY"
hasnt envfile-no-warning "$T/err" "broader than needed"
PR="$(cd "$P" && pwd -P)"
has project-path-env "$STUB_DOCKER_DIR/env" "OBEYA_PROJECT_PATH=$PR"
# compose arguments: no secret literal anywhere in the docker command lines
hasnt args-no-token "$STUB_DOCKER_DIR/log" "READONLY"
hasnt args-no-login-token "$STUB_DOCKER_DIR/log" "LOGINTOKEN"
has args-compose-file "$STUB_DOCKER_DIR/log" "-f $PLUGIN/obeya/compose.yml"
# a second call stops it
run "$P"
ck second-call-exit 0 "$(cat "$T/rc")"
ck second-call-stopped "" "$(ls "$STUB_DOCKER_DIR/running" 2>/dev/null)"
has second-call-down "$STUB_DOCKER_DIR/log" " down"
has second-call-says "$T/out" "obeya: stopped"
# explicit stop on a stopped Obeya is fine and says so
run "$P" stop
ck stop-when-stopped-exit 0 "$(cat "$T/rc")"
has stop-when-stopped-says "$T/out" "obeya: not running"

# login token: warning, no file written
reset
run "$P" start --login-token
ck login-exit 0 "$(cat "$T/rc")"
has login-token-passed "$STUB_DOCKER_DIR/env" "GH_TOKEN=gho_LOGINTOKEN"
has login-warning "$T/err" "obeya: warning: --login-token uses your own gh login token, which is broader than needed; prefer a read-only token in $TOKEN_ENV"
ck login-not-written "" "$(ls "$TOKEN_ENV" 2>/dev/null)"
leak=$(grep -rlF "LOGINTOKEN" "$P" "$STUB_DOCKER_DIR/log" 2>/dev/null | wc -l | tr -d ' ')
ck login-token-not-in-project-or-args 0 "$leak"
run "$P" stop

# image not found
reset; printf 'GH_TOKEN=x\n' >"$TOKEN_ENV"; export STUB_DOCKER_NOIMAGE=1
run "$P" start
ck image-exit 1 "$(cat "$T/rc")"
has image-line "$T/err" "obeya: image ghcr.io/wimsuenens/obeya:"
has image-line-fix "$T/err" "cannot be pulled: check the tag pinned in $PLUGIN/obeya/compose.yml and your network"
ck image-one-line 1 "$(lines "$T/err")"
ck image-not-started "" "$(ls "$STUB_DOCKER_DIR/running" 2>/dev/null)"

# port in use
reset; printf 'GH_TOKEN=x\n' >"$TOKEN_ENV"
if command -v python3 >/dev/null 2>&1; then
  python3 -c 'import socket,time
s=socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(("127.0.0.1",47732)); s.listen(1); print("ready",flush=True); time.sleep(30)' >"$T/listen" &
  LP=$!; for _ in 1 2 3 4 5 6 7 8 9 10; do grep -q ready "$T/listen" && break; sleep 0.3; done
  PORT=47732 run "$P" start
  kill $LP 2>/dev/null
  ck port-exit 1 "$(cat "$T/rc")"
  has port-line "$T/err" "obeya: port 47732 is in use: stop what holds it or set OBEYA_PORT to a free port"
  ck port-one-line 1 "$(lines "$T/err")"
else skip port-in-use "python3 missing"; fi

# compose file content
has compose-ro-same-path "$CF" '${OBEYA_PROJECT_PATH}:${OBEYA_PROJECT_PATH}:ro'
has compose-loopback "$CF" '127.0.0.1:${OBEYA_PORT:-4777}:3000'
has compose-token-passthrough "$CF" "- GH_TOKEN"
hasnt compose-no-token-literal "$CF" "GH_TOKEN="
hasnt compose-no-latest "$CF" ":latest"
V=$(jq -r .version "$REPO/apps/obeya/package.json")
pin=$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' "$CF")
ck compose-pin-is-app-version "ghcr.io/wimsuenens/obeya:$V" "$pin"

# review fixes (#121): tracker config reaches the container, the image has gh, the compose project is per project
reset; printf 'GH_TOKEN=x\n' >"$TOKEN_ENV"
PT=$(mkproj tracked $'obeya: on\n\n| Key | Value |\n|---|---|\n| owner | SomeOwner |\n| project number | 42 |')
run "$PT" start
ck tracker-start-exit 0 "$(cat "$T/rc")"
PTR="$(cd "$PT" && pwd -P)"
has tracker-in-projects "$STUB_DOCKER_DIR/env" '"tracker":{"owner":"SomeOwner","projectNumber":42}'
has tracker-path-in-projects "$STUB_DOCKER_DIR/env" "\"path\":\"$PTR\""
has dockerfile-has-gh "$REPO/apps/obeya/Dockerfile" "apk add --no-cache git github-cli"
# a project without a tracker table still starts, with no tracker key
reset; printf 'GH_TOKEN=x\n' >"$TOKEN_ENV"
run "$P" start
hasnt no-tracker-no-key "$STUB_DOCKER_DIR/env" '"tracker"'
has no-tracker-valid-json "$STUB_DOCKER_DIR/env" '"id":"project"'
# the compose project name is per project: two projects get two names, and each only sees its own container
reset; printf 'GH_TOKEN=x\n' >"$TOKEN_ENV"
run "$P" start
nameA="$(grep -o -- '-p [^ ]*' "$STUB_DOCKER_DIR/log" | tail -n1)"
run "$PT" start
nameB="$(grep -o -- '-p [^ ]*' "$STUB_DOCKER_DIR/log" | tail -n1)"
differ compose-name-per-project "$nameA" "$nameB"
has compose-name-prefixed "$STUB_DOCKER_DIR/log" "-p obeya-"
run "$P" stop
has stop-other-project-says-not-running "$T/out" "obeya: not running"
ck stop-other-project-leaves-running "$(echo "$nameB" | sed 's/^-p //')" "$(cat "$STUB_DOCKER_DIR/running")"
run "$PT" stop
ck stop-own-project-stops "" "$(ls "$STUB_DOCKER_DIR/running" 2>/dev/null)"

# release check: the pinned tag must exist in the registry
reset
( PATH="$SD:$PATH" STUB_DOCKER_TAGS="9.9.9" bash "$OB" check-pin >"$T/out" 2>"$T/err"; echo $? >"$T/rc" )
ck pin-missing-exit 1 "$(cat "$T/rc")"
has pin-missing-line "$T/err" "obeya: pinned image ghcr.io/wimsuenens/obeya:$V does not exist in the registry"
( PATH="$SD:$PATH" STUB_DOCKER_TAGS="9.9.9 $V" bash "$OB" check-pin >"$T/out" 2>"$T/err"; echo $? >"$T/rc" )
ck pin-ok-exit 0 "$(cat "$T/rc")"
has runbook-pin-check "$REPO/docs/factory/release-runbook.md" "obeya.sh check-pin"

# docs and skill
has skill-exists "$PLUGIN/skills/obeya/SKILL.md" "obeya.sh"
has template-optin "$PLUGIN/skills/setup-factory-skill/assets/factory.md" "obeya: off"
has readme-optin "$REPO/README.md" "obeya: on"
has changelog-entry "$REPO/CHANGELOG.md" "#125"
done_
