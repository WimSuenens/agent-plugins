# Contract 130 — Obeya pending decisions and andon

Issue [#130](https://github.com/WimSuenens/agent-plugins/issues/130) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · builds on [contract 126](126-obeya-read-model.md)

Paths:
- contracts/obeya/pending-decision.schema.json
- contracts/obeya/andon.schema.json
- apps/obeya/server/source/work-artifacts.ts
- apps/obeya/app/
- apps/obeya/shared/
- plugins/factory/references/decision-card.md
- plugins/factory/skills/run/SKILL.md

Decision cards and andon files get a small front matter block, so the app reads them without guessing. The block is not posted to the tracker.

## 1. Where the files are

Both live under `work/<id>/` and are read from the main checkout and every worktree (a copy that equals the main one is not repeated; a copy is `in-flight` on that worktree's branch only when the branch changed the file since its merge-base with main, or main lacks the file. A worktree cut before main moved is stale, not in flight: main's copy is used).

| Artifact | File | Object |
|---|---|---|
| Decision card | `work/<id>/NN-decision-<slug>.md` (the name the product-owner and `/factory:run` use); `NN-decision-card-<role>.md` is read too | `pending-decision.schema.json`, `GET .../pending-decisions` |
| Andon (abnormality list entry) | `work/<id>/NN-andon-lead.md` | `andon.schema.json`, `GET .../andon` |

A numeric `<id>` is the item number; `frontier-<n>` and `settle-<n>` give `item: null`.

## 2. Front matter

The YAML subset the reader accepts: `key: value`, `key: [a, b]`, `key:` followed by `  - item` lines, and a trailing ` # comment` (a `#` after whitespace and followed by a space or the end of the line; `#45` inside a value is part of the value).

Decision card: `door` (`one-way` or `two-way`), `asked` (who is asked), `since` (date and time, UTC), `options` (at least two). The title is the `## Decision:` line.

Andon: `andon` (`A<n>`), `owner` (a role or `lead`), `status` (`open` or `resolved`), `reason`; `item` (a number, default from the folder), `since` (optional), `countermeasure` (required when `resolved`).

## 3. Visible degradation

A card or andon file with no block, a missing or invalid field, is one parse-failure object (path, reason, provenance) from `GET .../parse-failures`, and no pending-decision or andon object. It is never dropped.

## 4. Needs you

The "needs you" slot (`PageView.needsYou`) lists pending decisions and board items whose `Factory status` is `Waiting on you`, together, oldest wait first and newest last. A waiting item has no known start, so it sorts before dated waits. The entry carries `waitingSeconds` at the last refresh; themes only present it.
