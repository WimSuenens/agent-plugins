# agent-plugins

A personal Claude Code marketplace. It lists two plugins:

- **`mattpocock-skills`** — upstream, unmodified, fetched straight from `mattpocock/skills`.
- **`wayfinding`** — the overlay: `wayfinder`, `beachhead`, `reversibility`.

**Nothing is forked.** A marketplace catalog and a plugin source are independent, so this repo can list a plugin that lives in someone else's repo alongside one that lives in its own. The overlay sits *beside* upstream instead of on top of it: upstream ships, you pull, there is never a merge to resolve.

## What the overlay changes

Upstream `/wayfinder` is plan-only by construction — it resolves every question in the map before anyone builds, using instruments that are all conversational. Its own metaphor argues against that: fog of war clears by *moving units*. And the cost lands on the scarcest input, your attention, because grilling is human-in-the-loop and declared the default.

The overlay keeps the map and changes four things:

1. **Reversibility triage.** Only **one-way doors** — decisions whose reversal costs a rewrite — become tickets before code. Two-way doors are **deferred with a trigger**.
2. **A `slice` ticket type.** A thin vertical cut, shipped to main, whose purpose is to *teach*. Where `task` does in order to unblock a decision, `slice` ships in order to produce one.
3. **Provisional vs locked decisions.** A decision reached by reasoning and never exercised by running code is marked as such, so downstream work knows how much weight it bears.
4. **An incremental exit.** No big-bang collapse of the map into one spec. Each slice carries its own; the map **dissolves** mid-build when no one-way doors remain ahead.

Upstream `/wayfinder` stays installed and stays useful — reach for it when the destination genuinely is a document rather than running software.

---

## Deploy

### 1. Push this directory to a public GitHub repo

The repo root must be the directory containing `.claude-plugin/`. Public is simplest; private works but complicates background auto-updates.

```bash
cd agent-plugins
git init && git add -A && git commit -m "wayfinding overlay"
gh repo create WimSuenens/agent-plugins --public --source=. --push
```

### 2. Register the marketplace and install both plugins

```bash
claude plugin marketplace add WimSuenens/agent-plugins
claude plugin install mattpocock-skills@wimsuenens
claude plugin install wayfinding@wimsuenens
```

Or inside a session: `/plugin marketplace add WimSuenens/agent-plugins`, then the two installs. If the install summary says `Run /reload-plugins to activate.`, run it.

> **If the upstream install fails with an SSH error** — `ssh: not found`, or `Could not read from remote repository` — GitHub `owner/repo` shorthand sources clone over SSH by default. Force HTTPS:
>
> ```bash
> CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1 claude plugin install mattpocock-skills@wimsuenens
> ```
>
> This bit me during testing. It affects the `mattpocock-skills` entry only, because that's the one with a `github` source; the overlay uses a relative path and is already local.

### 3. Configure the target repo

Once per repo you want to use this in:

```
/setup-matt-pocock-skills
```

Answer its questions (issue tracker, triage labels, doc layout). Then apply the tracker patch from `patches/` that matches the tracker you chose — `issue-tracker-github.wayfinding.md` or `issue-tracker-local.wayfinding.md`. It replaces the `## Wayfinding operations` section in the tracker doc that setup just wrote.

**This step is not optional.** `/wayfinding:wayfinder` reads that section for the `slice` label and the Deferred conventions, and silently falls back to upstream behaviour without it.

### 4. Add the `wayfinder:slice` label

On GitHub trackers only:

```bash
gh label create wayfinder:slice --description "Wayfinder: a thin slice shipped to teach"
```

### 5. Add the routing block

Append the block from `patches/CLAUDE-md-routing-snippet.md` to the repo's `CLAUDE.md` or `AGENTS.md` — the same file `/setup-matt-pocock-skills` writes its `### Issue tracker` block into.

This replaces the `ask-matt` edit from the earlier draft. You **cannot** patch `ask-matt` under this layout: Claude Code copies plugins into a read-only cache and overwrites edits on update. The routing has to live in the project, and the project's agent file is where it belongs.

---

## Use it in a project

Invoke by namespaced name, since plugin skills are registered as `<plugin>:<skill>`:

```
/wayfinding:wayfinder
```

Both wayfinders coexist. `/mattpocock-skills:wayfinder` is upstream's plan-only original; `/wayfinding:wayfinder` is this one. That's why the overlay skill kept the plain name — the namespace already does the disambiguating a `my-` prefix would have done.

`beachhead` and `reversibility` don't collide with anything, so `/beachhead` and `/reversibility` resolve fine on their own.

### The loop

```
1  chart      /wayfinding:wayfinder → grill breadth-first → triage       ~5–7 one-way-door tickets
2  clear      research subagents in parallel, then the rest              each → an ADR
3  beachhead  /beachhead → /to-spec → /to-tickets → /implement           ships to main
4  resurvey   taught / invalidated / triggers / fog / destination        the map moves
5  advance    loop 3–4 until no one-way doors remain ahead
6  dissolve   close the map, drop into the plain main flow
```

Every third slice, run `/improve-codebase-architecture` before picking the next beachhead. Slices accrete; this is what stops the walking skeleton from calcifying into the architecture by default.

### Where the rest of the engineering skills land

**Promoted.** `/domain-modeling` becomes the spine — `CONTEXT.md` and the ADRs are the durable artifacts, the map is scaffolding. `/research` fires generously and in parallel; it's AFK and free. `/improve-codebase-architecture` moves from "when you have a spare moment" to a scheduled step. `/to-questionnaire` becomes load-bearing: a deferred decision whose trigger is "ask a design partner" is exactly what it's for.

**Repositioned.** `/grilling` demoted from default to preference-questions-only — routing is now by *what kind of answer would settle it*. `/grill-with-docs` over `/grill-me` during charting, because the paper trail is the point. `/to-spec` runs per slice, not per map. `/prototype` competes with `slice`: prototype when the fake is much cheaper than the real thing, slice when they cost about the same. `/to-tickets`' expand–contract guidance gets more load-bearing, because deferring decisions means migrating shapes later.

**Unchanged.** `/implement` → `/tdd` → `/code-review` is the per-slice engine. `/triage` stays for inbound work only, never map tickets. `/diagnosing-bugs` stays an on-ramp, with one addition: a post-mortem that contradicts a `[locked]` decision is a resurvey trigger. `/wizard` serves `task` tickets. `/resolving-merge-conflicts` gets more use with parallel slices.

---

## Iterating on the overlay

Skip the push entirely while developing — `marketplace add` accepts a local path:

```bash
claude plugin validate .                       # marketplace catalog
claude plugin validate ./plugins/wayfinding    # plugin manifest
claude plugin validate ./plugins/wayfinding/skills   # every SKILL.md frontmatter

claude plugin marketplace add ./agent-plugins
claude plugin install wayfinding@wimsuenens
```

After editing a skill, reinstall to pick it up:

```bash
claude plugin uninstall wayfinding@wimsuenens
claude plugin marketplace update wimsuenens
claude plugin install wayfinding@wimsuenens
```

A directory-sourced marketplace has no commit SHA, so `plugin list` reports `Version: unknown` and update detection doesn't work — hence the uninstall. Once it's on GitHub, `claude plugin marketplace update wimsuenens` is enough.

### Why `plugin.json` has no `version`

Deliberate. With `version` omitted, a git-sourced plugin's version resolves to the commit SHA, so every push propagates. With `version` pinned, Claude Code serves the cached copy until the string changes — and forgetting to bump it produces a silent, confusing staleness. `claude plugin validate` emits a non-blocking warning about the missing version; that warning is the cost, and it's the cheaper of the two failure modes.

To pin upstream so its updates arrive on your schedule rather than Matt's, add a `ref` to the `mattpocock-skills` entry in `marketplace.json`:

```json
"source": { "source": "github", "repo": "mattpocock/skills", "ref": "v1.2.3" }
```

### Sharing with a team or across your machines

Commit this to the project's `.claude/settings.json` and the marketplace registers itself for anyone who trusts the folder:

```json
{
  "extraKnownMarketplaces": {
    "agent-plugins": { "source": { "source": "github", "repo": "WimSuenens/agent-plugins" } }
  },
  "enabledPlugins": {
    "mattpocock-skills@wimsuenens": true,
    "wayfinding@wimsuenens": true
  }
}
```

---

## What was tested

Run against Claude Code `2.1.237` on Linux:

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed |
| `claude plugin validate ./plugins/wayfinding` | passed (version warning, intentional) |
| `claude plugin validate ./plugins/wayfinding/skills` | passed — all three SKILL.md frontmatter blocks parse |
| `claude plugin marketplace add ./agent-plugins` | registered |
| `claude plugin install wayfinding@wimsuenens` | installed, all three skill directories present in cache |
| `claude plugin install mattpocock-skills@wimsuenens` | installed at 1.2.3 after forcing HTTPS |
| Both plugins enabled together | no collision error; both `wayfinder` skills present under separate namespaces |
| Uninstall → marketplace update → reinstall | clean |

**Not tested, because it needs an interactive session against a real repo:** whether the skills fire correctly end to end, and whether bare cross-references inside the skill bodies (`/grill-with-docs`, `/to-tickets`, `/implement`) resolve across the plugin boundary. Upstream's own skills reference each other bare and ship as a plugin, so the convention is proven — but proven *within* one plugin, not across two. If a cross-plugin reference doesn't resolve, prefix it: `/mattpocock-skills:grill-with-docs`.

## Known costs

- **Triage quality is the whole mechanism.** Mis-sort a one-way door as a two-way door and you get the failure this layer exists to avoid, arriving later and more expensively than upstream's version would have. The `~5–7` count check during charting is a smoke alarm, not a guarantee.
- **The tracker patch is a fork of one file.** Re-check it after a major upstream release; everything else updates cleanly.
- **`reversibility` is model-invoked**, so its description carries permanent context load. That's the price of shared vocabulary between two user-invoked skills, which can't reach each other.
- **Deferred rots without discipline.** The trigger is the only thing between a deferral and an abandonment. If resurvey step 3 gets skipped, the section becomes a graveyard within a month.

## Lighter alternatives

If the plugin still isn't worth it, the ideas survive without any of this. Put the triage in the map's `## Notes` block, which upstream `/wayfinder` already loads every session:

> Triage every question one-way / two-way. Ticket only the one-way doors; the rest go to a Deferred list, each with an observable trigger. Between tickets, ship a thin slice against real infrastructure and resurvey the map against what it taught.

Roughly 80% of the behaviour change, zero install. Run that on a real effort first, and build the plugin only if you find yourself retyping it.
