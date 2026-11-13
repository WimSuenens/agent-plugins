Four steps take you from nothing to a first command. You need Claude Code. The factory also needs a GitHub repository and the `gh` command-line tool.

## Add the marketplace

Inside a Claude Code session:

```
/plugin marketplace add WimSuenens/agent-plugins
```

Or from a terminal: `claude plugin marketplace add WimSuenens/agent-plugins`.

## Install the plugins you want

The marketplace is named `wimsuenens`. Each plugin installs on its own.

```
claude plugin install mattpocock-skills@wimsuenens
claude plugin install wayfinding@wimsuenens
claude plugin install factory@wimsuenens
```

The factory builds on wayfinding and on `mattpocock-skills`, so install those two with it. The other plugins are optional; the [Reference](/reference/) lists every skill of every plugin.

If the install says `Run /reload-plugins to activate.`, run it, then start a new session. A session keeps the skill text it read when it started, so an old session runs the old text.

If the upstream install fails with an SSH error, GitHub shorthand sources clone over SSH by default. Set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` before the install command to use HTTPS.

## Set up your repository, once

```
/wayfinding:setup-wayfinding-skill
/factory:setup-factory-skill
```

The first wires the planning conventions into your issue tracker doc. The second writes `docs/agents/factory.md` and prepares the GitHub Project board. Only GitHub trackers are supported for the factory for now.

## Run your first command

To plan something large, start with the map:

```
/wayfinding:wayfinder
```

To have the factory take an idea all the way to merged pull requests:

```
/factory:run "your idea in a sentence"
```

The factory asks a few questions about the destination, then works. It comes back to you only for the one-way doors.
