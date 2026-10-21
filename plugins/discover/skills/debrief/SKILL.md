---
name: debrief
description: Debrief the whole session into a short course — one lesson per topic, plus the documents that belong to it — so the human can pick up the work later. Use when the user asks to debrief, wrap up, or hand over the session as a whole.
---

# Debrief

A session wanders: one question opens related threads, some settle, some stay open. A **debrief** turns it into a short **course** the human can study cold, weeks later, without the chat: one **lesson** per topic, in teaching order, with the session's documents filed beside the lesson that explains them, and every open question gathered where the work resumes.

The human decides what goes in. You propose; three check-ins confirm. Ask each with your multiple-choice question tool if you have one, otherwise as a numbered list in chat, and wait for the answer before moving on.

## 1. Map the topics

Read the whole session from the first message. Group it **by topic**: a thread the session returned to three times is one topic, told in its final, corrected form.

**Done when** every user message belongs to a listed topic or is marked as chatter or a side-track.

## 2. Check-in: topics

List every topic with a one-line summary of where it landed. Preselect the ones that carry real learning; leave side-tracks listed but unselected. The human can keep, drop, merge ("2 and 4 are one thing"), or rename.

## 3. Check-in: documents

Gather the session's **documents**: files the user uploaded, and files you generated (outputs, artifacts) in their latest version only. Offer them for inclusion, each tagged with the topic it belongs to.

Pages and links cited in the session become *Further reading* in the lesson, not copied files. Repo files edited during the session are named by path in the lesson; git already keeps them.

Skip this check-in when there are no documents.

## 4. Check-in: the tree

Order the lessons in **teaching order**: foundations first, lessons that build on them after. Propose the tree, with each document placed:

```
debrief-YYYY-MM-DD-<slug>/
  README.md             course outline
  01-<topic>/
    lesson.md
    <documents for this topic only>
  02-<topic>/...
  shared/               documents several lessons use
```

The human can reorder lessons and move documents.

With one topic and no documents, the course collapses to a single file, `debrief-YYYY-MM-DD-<slug>.md`, holding one lesson and no outline; confirm the file name.

## 5. Write and deliver

Write each lesson and the outline (see below), and copy the documents into place.

- **claude.ai** (uploads in `/mnt/user-data/uploads`, outputs in `/mnt/user-data/outputs`): zip the folder into outputs, then present the zip and `README.md` with the file-presentation tool. Close with one line; the files carry the content.
- **Claude Code, Cowork, or any local workspace**: ask where to write, suggesting `./debriefs/`, then write the folder there.

**Done when** every selected topic has its lesson, every selected document sits where the tree put it, and every lesson's open questions appear in the outline.

## The lesson

Write for the human as they were at the **start** of the session: the lesson teaches what the session taught them. Rebuild each topic as a teaching sequence, from concepts up to conclusion, in the order a learner needs it rather than the order the chat found it. Drop any section with nothing in it.

1. **What you'll learn**: 2–4 learning objectives.
2. **Key concepts**: the terms and ideas the rest builds on, briefly defined.
3. **The explanation**: from those concepts to where the session landed, with the reasoning and trade-offs behind each decision.
4. **Worked examples**: the session's code and concrete cases, each placed after the explanation it illustrates and annotated enough to reuse.
5. **Pitfalls**: the instructive dead ends, as "you might think X; here's why it fails."
6. **Recap**: 3–5 key points.
7. **Check yourself**: a few questions that test understanding, answers in a collapsed `<details>` block.
8. **Further reading**: cited sources and links, and the documents in this lesson's folder.
9. **Open questions and next steps**: what is unresolved, and what to do next.

## The course outline

`README.md` is where the human picks the work back up:

- a title and the session date
- an overview: 2–4 sentences on what the session set out to learn and where it ended up
- the lessons in teaching order, one line each, noting which earlier lesson a lesson builds on
- every open question and next step from the lessons, each linked to its lesson
