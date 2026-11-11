# Contract 131 — Obeya intake queue

Issue [#131](https://github.com/WimSuenens/agent-plugins/issues/131) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · Reads [contract 110](110-idea-intake.md) · Read model [contract 126](126-obeya-read-model.md)

Paths:
- contracts/obeya/intake-entry.schema.json
- apps/obeya/server/source/intake.ts
- apps/obeya/app/components/
- apps/obeya/test/intake.test.mjs

The queue only reads. It defines no intake behaviour and writes to neither the intake nor the tracker (the gh adapter allows `issue list` and `api user`, both read).

## 1. Entries

`GET /api/projects/<id>/intake` returns one `IntakeEntry` per `idea` issue (open and closed) and per file waiting in an inbox folder. New field `channel`: `slack`, `mail`, `teams`, `inbox`, `terminal` or `unknown`.

- **Outcome and reason** come from the lead's last `<!-- factory:triage v1 -->` comment (`**Outcome:**`, `**Reason:**`). Comments by other logins are ignored. No triage comment: outcome `untriaged`, reason `null`.
- **Waiting on a human**: no triage comment and an open `<!-- factory:needs-you v1 -->` comment of the lead without `Answered:`. The page shows these in the needs-you slot too.
- **Channel** is read from front matter in the idea body (`channel: slack`), asked for only because nothing else records it. Without it: the `factory:inbox` marker means `inbox`, the `factory:idea` marker means `terminal`, else `unknown`. Slack, mail and Teams adapters feed #108's intake and need no Obeya change.
- **In flight**: a file in the `.claude/factory-inbox` of a live worktree is `untriaged`, channel `inbox`, provenance `in-flight` on that worktree's branch.

## 2. Degradation

A triage comment with an unrecognised outcome or an empty reason is a parse-failure (path is the issue url), never an entry with "no reason".
