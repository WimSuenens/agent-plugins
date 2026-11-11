---
name: idea
description: File an idea, a reference or any piece of input for the factory to triage later. Creates a tracker issue with the label idea; the lead triages it at the next run start.
argument-hint: "<title> [-- details]"
disable-model-invocation: true
---

# File an idea

Capture input now; the factory decides what to do with it later. Nothing is built, decided or ranked here.

1. Take the title from the argument (everything before ` -- `) and the details after it. When there is no argument, ask the person for one line, and for the details if they have any. A URL, a path or a pasted passage is a legitimate detail: write it into the details file as it is.
2. Write the details to a scratch file in the scratchpad (not the repo). Leave it out when there are none.
3. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" file "<title>" <details-file>`. It scans the text first (exit 6: a home path or a secret; tell the person which kind and file nothing), creates the issue with the label `idea` and prints its URL.
4. Tell the person the URL and that the lead triages it at the next `/factory:run`, with an outcome and a reason on the issue. Nothing more.

Plugin root: ${CLAUDE_PLUGIN_ROOT}. The script call uses this substituted path; the variable is not in the Bash environment.

The same can be done without the factory: a plain tracker issue carrying the label `idea` is an idea. A file dropped in the inbox folder (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" dir` prints it) becomes one at the next run start.
