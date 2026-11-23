#!/usr/bin/env bash
# The artefact kind of a slice and the proof it takes (#187 decision 7, #207 slice 5).
# Usage: bash proof-kind.sh resolve [--kind <kind>] [--plan <plan file>] [--table <factory.md>]
# Kinds and the proof each takes (a proof item of the QA verdict has one of these kinds):
#   web-app               screenshot
#   cli, library          run-log
#   instruction-markdown  scenario-transcript (and the verdict's Human-only criteria list)
#   docs                  render-log or link-check-log
# The kind is read from, in this order: --kind, the plan's `- artefact:` line, the table's `project-type:` line (a markdown/LLM plugin is
# instruction-markdown, a static site is web-app; a project that holds several kinds says it per slice in the plan).
# Output: `kind: <kind>` and `proof: <kind>[, <kind>]`. Exit: 0 resolved; 2 an unknown kind, or a file that is unreadable;
# 3 no way to tell (the message names the two ways out: --kind and the plan's `artefact:` line).
usage() { echo "usage: proof-kind.sh resolve [--kind <kind>] [--plan <plan file>] [--table <factory.md>]" >&2; exit 2; }
[ "${1:-}" = resolve ] || usage
shift
kind=""; plan=""; table=""
while [ $# -gt 0 ]; do
  case "$1" in
    --kind) [ $# -ge 2 ] || usage; kind="$2" ;;
    --plan) [ $# -ge 2 ] || usage; plan="$2" ;;
    --table) [ $# -ge 2 ] || usage; table="$2" ;;
    *) usage ;;
  esac
  shift 2
done
if [ -z "$kind" ] && [ -n "$plan" ]; then
  [ -r "$plan" ] || { echo "proof-kind: $plan: unreadable" >&2; exit 2; }
  kind="$(grep -m 1 '^- artefact:' "$plan" | sed 's/^- artefact:[[:space:]]*//' | tr -d '\r' | sed 's/[[:space:]]*$//')"
fi
if [ -z "$kind" ] && [ -n "$table" ]; then
  [ -r "$table" ] || { echo "proof-kind: $table: unreadable" >&2; exit 2; }
  pt="$(grep -m 1 '^project-type:' "$table" | sed 's/^project-type:[[:space:]]*//' | tr -d '\r' | tr '[:upper:]' '[:lower:]')"
  case "$pt" in
    *markdown* | *llm*) kind=instruction-markdown ;;
    *"static site"* | *web*) kind=web-app ;;
    *cli* | *"command"*) kind=cli ;;
    *library*) kind=library ;;
    *docs* | *documentation*) kind=docs ;;
  esac
fi
if [ -z "$kind" ]; then
  echo "proof-kind: the artefact kind is not known: pass --kind <web-app|cli|library|instruction-markdown|docs>, or write an \`artefact:\` line in the plan" >&2
  exit 3
fi
case "$kind" in
  web-app) proof="screenshot" ;;
  cli | library) proof="run-log" ;;
  instruction-markdown) proof="scenario-transcript" ;;
  docs) proof="render-log, link-check-log" ;;
  *) echo "proof-kind: unknown kind \"$kind\" (web-app, cli, library, instruction-markdown, docs)" >&2; exit 2 ;;
esac
echo "kind: $kind"
echo "proof: $proof"
