# agent-plugins

A personal Claude Code marketplace. Its main plugins:

- **`mattpocock-skills`** — upstream, unmodified, fetched straight from `mattpocock/skills`.
- **`wayfinding`** — the planning overlay: `wayfinder`, `beachhead`, `reversibility`, `setup-wayfinding-skill`, `ask-me`.
- **`design`** — the design overlay: `ux-psychology`, `ux-review`, `design-system`, `direction`, `setup-design-skill`. See [The design overlay](#the-design-overlay).
- **`factory`** — a lead and seven role agents that take an idea to a destination, slice by slice: `run`, `setup-factory-skill`. See [The factory](#the-factory).

It also lists `toolkit` (`source-to-pptx`) and `discover` (`debrief`).

**Nothing is forked.** A marketplace catalog and a plugin source are independent, so this repo can list a plugin that lives in someone else's repo alongside one that lives in its own. The overlay sits *beside* upstream instead of on top of it: upstream ships, you pull, there is never a merge to resolve.

## What the overlay changes

Upstream `/wayfinder` is plan-only by construction — it resolves every question in the map before anyone builds, using instruments that are all conversational. Its own metaphor argues against that: fog of war clears by *moving units*. And the cost lands on the scarcest input, your attention, because grilling is human-in-the-loop and declared the default.

The overlay keeps the map and changes four things:

1. **Reversibility triage.** Only **one-way doors** — decisions whose reversal costs a rewrite — become tickets before code. Two-way doors are **deferred with a trigger**.
2. **A `slice` ticket type.** A thin vertical cut, shipped to main, whose purpose is to *teach*. Where `task` does in order to unblock a decision, `slice` ships in order to produce one.
3. **Provisional vs locked decisions.** A decision reached by reasoning and never exercised by running code is marked as such, so downstream work knows how much weight it bears.
4. **An incremental exit.** No big-bang collapse of the map into one spec. Each slice carries its own; the map **dissolves** mid-build when no one-way doors remain ahead.

Upstream `/wayfinder` stays installed and stays useful — reach for it when the destination genuinely is a document rather than running software.

## The design overlay

Upstream has no design vocabulary: `/prototype` can generate UI variations and `/code-review` can check code against standards, but neither knows *why* a screen works. The design overlay adds that layer the same way `wayfinding` does — beside upstream, never forked.

| Skill | Invocation | What it does |
|---|---|---|
| `ux-psychology` | model | Glossary by **mechanism** (perception, memory, interaction cost, decisions, motivation, trust, accessibility). Every principle carries an evidence grade — *replicated*, *contested* or *folklore* — never a statistic. Ends with the **three-check test** for dark patterns: truthful framing, symmetric exit, endorsement. |
| `ux-review` | model | Six-pass review of a screenshot, URL or component code. Findings carry severity, principle, evidence, fix, and a dark-pattern flag. Optional outputs: `design/reviews/` and the issue tracker. |
| `design-system` | user | Builds `design/system.md` plus tokens in the repo's stack (DTCG on request), from scratch or extracted from existing UI. Asks the one-way doors, chooses the two-way doors. Reads a `direction` brief when one exists. |
| `direction` | user | Interviews a project into one design direction of counted commitments and writes a reusable brief. |
| `setup-design-skill` | user | Writes `docs/agents/design.md` and its `AGENTS.md` pointer once per repo. |

It reaches upstream two ways:

1. **Vocabulary hook.** `ux-psychology`'s description ends "…or when another skill needs the UX-psychology vocabulary", the same hook `codebase-design` and `reversibility` use.
2. **Upstream artefacts.** `setup-design-skill` adds `docs/agents/design.md`, which every upstream skill reads through `AGENTS.md`: build UI from `design/system.md`, name findings with the vocabulary, record one-way design decisions as ADRs and UI terms in `CONTEXT.md`, file review findings as issues.

The research behind it — every principle traced to primary sources and graded, with corrections to the popular claims (the jam study, "70–90% never change defaults", "losses weigh 2x") — is in [docs/research/ux-psychology.md](docs/research/ux-psychology.md).

```
/design:setup-design-skill    once per repo
/design:direction             optional — when the visual identity is still open
/design:design-system         writes design/system.md + tokens
/design:ux-review             on any screen, flow or component
```

## The factory

The factory decides *what* the destination is and cuts the slices; wayfinding charts *how* to get there. `/factory:run` makes the main session a **lead** that grills the person briefly about the destination, has wayfinding chart the route, then takes slice after slice through seven role agents — product owner, architect, developer, QA engineer, security reviewer, DevOps, docs writer — to merged PRs, resurveying after each. Every two-way decision a role takes comes back to the lead and to the person at the next stage boundary; overturning one becomes feedback to that role, and the work never stops for it. Long sessions stop filling their context windows because the roles are subagents that report summaries, and every message between them is a file.

| Piece | What it does |
|---|---|
| `run` (user) | The lead. Clarifies the destination, has wayfinding chart the map, clears its one-way doors (research and prototypes AFK, the decision to the person), cuts each slice, starts a branch and worktree per item, briefs each role, reviews their two-way decisions, moves the item across a `Factory status` board, and resurveys after each merge until the map dissolves. |
| `setup-factory-skill` (user) | Writes `docs/agents/factory.md` (decision-maker level, path ownership, worktree location, tracker ids), patches the tracker doc, and prepares the GitHub Project field. |
| 7 role agents | `factory:<role>`, each with checkable *Inputs needed* and *Done* lists, sharing one [protocol](plugins/factory/references/protocol.md). |
| Private role memory | Each role keeps craft notes in its own memory; a plugin hook stops one role reading another's. |
| Decision cards | A one-way door never gets decided by an agent. The product owner writes a [card](plugins/factory/references/decision-card.md) in everyday words — consequences, cost, effort to undo, a recommendation — and the lead offers ways to dig deeper (`/research`, `/prototype`, `/grilling`). |

```
/wayfinding:setup-wayfinding-skill   once per repo (setup-factory-skill runs it if needed)
/factory:setup-factory-skill         once per repo — GitHub trackers only for now
/factory:run [idea | #map]           per destination; #map resumes
```

**Status: drafted, not yet run end to end.** The design, what has been verified, and the extension points are in [docs/research/software-factory.md](docs/research/software-factory.md); the decisions are ADRs 0001–0008 (0006 superseded by 0007) in [docs/adr/](docs/adr/), all provisional.

**Feedback goes to this repo's issues** with the `plugin:factory` label — use the *Factory feedback* template, or let `/factory:run` draft the issue at the end of an item. It posts only what you approve, and leaves your project's code and names out.

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
/wayfinding:setup-wayfinding-skill
```

It runs upstream's `/setup-matt-pocock-skills` interview first if the repo isn't configured yet (issue tracker, triage labels, doc layout), then deterministically wires the wayfinding conventions into the tracker doc's `## Wayfinding operations` section — the `slice` type, locked/provisional tagging, the Deferred list — and creates the `wayfinder:slice` label on GitHub and GitLab trackers. No manual file patch, no separate `gh label create` step.

Use `/wayfinding:ask-me` in this repo instead of `/ask-matt` — it's the same router, with the one flow this overlay changes (the wayfinder on-ramp) pointed at `/wayfinding:wayfinder`.

---

## Use it in a project

Invoke by namespaced name, since plugin skills are registered as `<plugin>:<skill>`:

```
/wayfinding:wayfinder
```

Both wayfinders coexist. `/mattpocock-skills:wayfinder` is upstream's plan-only original; `/wayfinding:wayfinder` is this one. That's why the overlay skill kept the plain name — the namespace already does the disambiguating a `my-` prefix would have done.

`beachhead`, `reversibility`, `setup-wayfinding-skill`, and `ask-me` don't collide with anything, so `/beachhead`, `/reversibility`, `/setup-wayfinding-skill`, and `/ask-me` resolve fine on their own. Use `/ask-me` in place of `/ask-matt` in a repo running this overlay — same router, with the wayfinder on-ramp pointed here.

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
| `claude plugin validate ./plugins/wayfinding/skills` | passed — all five SKILL.md frontmatter blocks parse |
| `claude plugin marketplace add ./agent-plugins` | registered |
| `claude plugin install wayfinding@wimsuenens` | installed, all five skill directories present in cache |
| `claude plugin install mattpocock-skills@wimsuenens` | installed at 1.2.3 after forcing HTTPS |
| Both plugins enabled together | no collision error; both `wayfinder` skills present under separate namespaces |
| Uninstall → marketplace update → reinstall | clean |

**Not tested, because it needs an interactive session against a real repo:** whether the skills fire correctly end to end, and whether bare cross-references inside the skill bodies (`/grill-with-docs`, `/to-tickets`, `/implement`) resolve across the plugin boundary. Upstream's own skills reference each other bare and ship as a plugin, so the convention is proven — but proven *within* one plugin, not across two. If a cross-plugin reference doesn't resolve, prefix it: `/mattpocock-skills:grill-with-docs`.

The `factory` plugin, on macOS with gh `2.94.0`:

| Check | Result |
| --- | --- |
| `claude plugin validate .` and `./plugins/factory` | passed (version warnings, intentional) |
| `claude plugin validate ./plugins/factory/skills` | passed |
| `guard-memory.sh` against twelve sample inputs, with and without `jq` | every input allowed or blocked as intended |
| `gh project` flags used by the setup and the tracker patch | present in `--help` |

**Not tested yet:** a factory item end to end. The open questions are `plugin:factory` issues on this repo; the first validation run, on a project with real application code, closes them or turns them into findings.

## Known costs

- **Triage quality is the whole mechanism.** Mis-sort a one-way door as a two-way door and you get the failure this layer exists to avoid, arriving later and more expensively than upstream's version would have. The `~5–7` count check during charting is a smoke alarm, not a guarantee.
- **The tracker patches are a fork of one section each.** `setup-wayfinding-skill/references/issue-tracker-{github,gitlab,local}.wayfinding.md` each fork one upstream "Wayfinding operations" section; re-check them after a major upstream release, since upstream could change the mechanics they're built on. Applying them is automatic now — only the content itself still needs re-checking.
- **`reversibility`, `wayfinder`, and `beachhead` are model-invoked**, so their descriptions carry permanent context load. `reversibility` pays it for shared vocabulary; `wayfinder` and `beachhead` pay it so `/factory:run` can chart, frame, and resurvey on its own ([ADR 0006](docs/adr/0006-factory-builds-wayfinder-slices.md)).
- **Deferred rots without discipline.** The trigger is the only thing between a deferral and an abandonment. If resurvey step 3 gets skipped, the section becomes a graveyard within a month.

## Lighter alternatives

If the plugin still isn't worth it, the ideas survive without any of this. Put the triage in the map's `## Notes` block, which upstream `/wayfinder` already loads every session:

> Triage every question one-way / two-way. Ticket only the one-way doors; the rest go to a Deferred list, each with an observable trigger. Between tickets, ship a thin slice against real infrastructure and resurvey the map against what it taught.

Roughly 80% of the behaviour change, zero install. Run that on a real effort first, and build the plugin only if you find yourself retyping it.
