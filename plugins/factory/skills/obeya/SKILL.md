---
name: obeya
description: "Start or stop the Obeya, the read-only browser view of this project's factory, in a container on loopback. Needs `obeya: on` in docs/agents/factory.md."
argument-hint: "[start | stop] [--login-token]"
disable-model-invocation: true
---

# Start or stop the Obeya

The Obeya is a lens over the project (ADR 0019): it shows what the tracker and the repo already hold and writes nothing. It runs from a published container image pinned in the plugin's compose file.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/obeya.sh" <arguments>` with the person's arguments, from the project folder. With no argument it stops the Obeya when it runs and starts it otherwise.
2. On success tell the person the loopback URL it printed (or that it stopped). On failure the script printed one line on stderr naming what to fix (opt-in missing, Docker missing, no token, port in use, image not pullable): relay that line and nothing more.
3. The opt-in is one line, `obeya: on`, in the `## Obeya` section of `docs/agents/factory.md`. Without it the script refuses. Never edit that file for the person.
4. Token. The documented path is a read-only GitHub token as `GH_TOKEN=<token>` in the untracked file `~/.config/obeya/env` (or the file named by `OBEYA_ENV_FILE`). `--login-token` uses the person's own `gh auth token` instead and prints a warning that it is broader than needed. Either way the token goes to the container through the environment and is never written to disk.
5. The project is mounted read-only at its own absolute path, and the port (default 4777, `OBEYA_PORT` to change) is published on `127.0.0.1` only.

Plugin root: ${CLAUDE_PLUGIN_ROOT}. The script call uses this substituted path; the variable is not in the Bash environment.
