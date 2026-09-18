#!/usr/bin/env bash
# POSIX counterpart of run.ps1. Same resolution order: docker, .venv, host python.
#   run.sh <work-dir> <script.py> [args...]
set -euo pipefail

skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="source-to-pptx:latest"
workdir="${1:?usage: run.sh <work-dir> <script.py> [args...]}"; shift
script="${1:?no script given}"; shift
workdir="$(cd "$workdir" && pwd)"

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        [ -n "$(docker images -q "$image")" ] || docker build -t "$image" "$skill/assets/docker"
        exec docker run --rm -v "$workdir:/work" -v "$skill:/skill:ro" \
            -e PAGE2PPTX_SKILL=/skill "$image" python "/skill/scripts/$script" "$@"
    fi
    echo "Docker is installed but its daemon is not responding." >&2
    echo "Start Docker, or make a local Python available, then re-run." >&2
    exit 3
fi

venv="$workdir/.venv/bin/python"
if [ ! -x "$venv" ]; then
    python3 -m venv "$workdir/.venv"
    "$venv" -m pip install --quiet -r "$skill/assets/docker/requirements.txt"
fi
PAGE2PPTX_SKILL="$skill" exec "$venv" "$skill/scripts/$script" "$@"
