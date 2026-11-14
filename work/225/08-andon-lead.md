---
andon: A1
item: 225
owner: architect
status: resolved
countermeasure: none: needs a plugin change
reason: docs-writer found three stale README lines the architect's contract list did not name
since: 2026-11-14T19:38:40Z
---

## Andon A1: blocked or defective input (#225)

- kind: 1 blocked or defective input
- raised by: docs-writer
- seen: the contract's list of README text made stale named four lines; three more (a page count in the intro, a page count in the build output line, a line describing only the skill file source) were found only by the docs-writer searching the README; the work finished with that extra search
- where to look: section 8 of the Reference-section contract; the README at the docs-writer's commit 81dab11
- 5 Whys:
  1. Why did the docs-writer need a search beyond its input? — the contract's section 8 was its only list of stale README text and it was incomplete — evidence: contracts/225-reference-section.md section 8; README.md lines 221, 263, 294 at 81dab11
  2. Why was the list incomplete? — its search terms covered the word form of a changed figure ("five pages") but not the digit form ("5 pages"), and a statement worded around one file kind (skills only) matched no term — evidence: contracts/225-reference-section.md section 8 first line (the terms searched)
  3. Why did nothing catch it before documentation? — the rule that a contract lists every text stating a changed figure or rule (protocol, the architect's section) names no spelling variants and has no check beside it, and the lead's Done check reads the contract's own list, not the repository — evidence: references/protocol.md line 56; skills/run/SKILL.md step 6 item 4
  process item to change: the protocol's search rule for texts a contract makes stale: it should require the digit and the word form of a changed figure, and a search for statements that name only one of the things the change now covers
- fence check: not run: no override proposed
- countermeasure: none: needs a plugin change
- supersedes: none
- standard change proposed: in the protocol's search rule for stale texts, add that a changed figure is searched in digit and word form, and that statements naming only part of what the change widens are searched too
- carried on: 2026-11-14T19:38:40Z

## Refused drafts

none
