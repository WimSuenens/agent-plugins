---
name: session-recap
description: Reviews the current conversation and produces a comprehensive Markdown guide summarizing the topics covered, insights, decisions, and code snippets exchanged during the session. Trigger this on the explicit command /session-recap AND on natural requests anywhere in the conversation — "review our conversation," "recap this session," "summarize what we discussed/learned," "wrap up this session," "document what we covered," "turn this chat into notes I can keep," "write up everything we went over today," and similar phrasing — even when the user doesn't say "Markdown" or name the skill directly. Use this whenever the user wants a keepable, standalone record of a working session, not just a quick verbal summary in the chat.
---
 
# Session Recap
 
Turns the conversation so far into a standalone Markdown document the user can keep, search, and refer back to later — the kind of thing that's still useful weeks after the chat itself is gone. That's the whole point: the guide has to work as a reference on its own, without the original conversation sitting next to it.
 
## How to review the conversation
 
Read back through the entire conversation from the start, not just the last few exchanges — the most useful material is often buried in the middle of a session, not just at the end.
 
As you go, group what you find **by topic, not by chronology**. A real working session often loops back to the same problem two or three times with a correction each round; the guide should present the final, settled version of that thread as one coherent section, not several separate entries in time order. If earlier information turned out to be wrong or was later superseded, keep only the corrected version — don't reproduce the back-and-forth that got there.
 
Skip pleasantries, false starts, and purely mechanical exchanges (acknowledgements, "yes that works," clarifying questions that don't carry their own information). Keep anything that changed the user's understanding, that they'll want to look up again, or that took real effort to work out — including reasoning or trade-offs behind a decision, not just the decision itself.
 
## Adapt the depth to the session
 
Let the actual content decide how long the guide is — don't force a fixed shape onto a short or narrow conversation, and don't compress a long, multi-topic session down to a paragraph.
 
- **A short or single-topic session** (a quick question, one code fix, one focused explanation) needs only a brief overview and maybe one section — skip empty headers for sections that would otherwise have nothing in them.
- **A long or multi-topic session** (several distinct problems worked through, many decisions made, various pieces of code produced) earns the full structure below, with one subsection per topic.
If a section genuinely has nothing to put in it, leave it out entirely rather than writing "N/A" or "nothing to report."
 
## Guide structure
 
Use this as a starting template, not a rigid form — add, merge, or drop sections based on what the session actually contained.
 
```markdown
# [Descriptive title for the session]
 
**Date:** [date of the conversation]
 
## Overview
[2-4 sentences: what this session was about, and what came out of it]
 
## [Topic 1 name]
[What was discussed, the key insight or decision, and why it matters — written so
it stands on its own without the original chat]
 
\u{200b}```[language]
[any code that belongs to this topic, with enough surrounding comments/context
to be usable later]
\u{200b}```
 
## [Topic 2 name]
...
 
## Open questions / follow-ups
[Anything left unresolved, decided against, or flagged for later — only include
this section if something genuine is still open]
```
 
Give each topic its own heading with a descriptive name (never "Topic 1") — that's what makes the guide skimmable and searchable later. Code snippets go inside the topic they belong to, immediately after the explanation that motivates them, not collected in one dump at the end — that's what makes each snippet make sense on its own without re-reading the whole document.
 
## Saving the guide
 
Always save the result as a Markdown file — don't just print the guide into the chat. Create the file, then present it with the file-presentation tool so the user gets a proper file card, not the raw text pasted into the reply as well.
 
- File name: `session-recap-[YYYY-MM-DD]-[short-topic-slug].md` — e.g. `session-recap-2026-09-19-invoice-validation-engine.md`. If the session covered several unrelated topics, pick the dominant one or use a short combined slug.
- After presenting the file, a short one-line reply is enough (e.g. "Here's the recap.") — the file card carries the content, so don't also repeat the guide's contents in the chat.
 