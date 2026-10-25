# Factory operations patch: GitHub

**Applies to**: `docs/agents/issue-tracker.md` whose first heading is `# Issue tracker: GitHub`.

**Change**: add (or replace) the `## Factory operations` section at the end of the file with the section below, verbatim.

---

## Factory operations

Used by `/factory:run`. Only the lead touches the tracker. A factory **item** is one `wayfinder:slice` ticket; `<id>` is its issue number. Ids for the Project, the `Factory status` field, and its options are cached in `docs/agents/factory.md`.

- **Add to board**: `gh project item-add <project-number> --owner <owner> --url <issue-url> --format json --jq .id`. The output is the item's project id, `<item>`; write it into the item's lead state.
- **Set status**: `gh project item-edit --id <item> --project-id <project-id> --field-id <field-id> --single-select-option-id <option-id>`.
- **Stage summary**: `gh issue comment <id> --body "<stage>: <summary>"`, at most five lines, after every stage.
- **Decision card**: `gh issue comment <id> --body-file work/<id>/<card>.md`. Record the person's choice as a reply comment: `Decision: <option>. Reason: <their words>.`
- **Open PR**: `gh pr create --head item/<id> --title "<slice title>" --body "Closes #<id>"`. Merging it closes the slice ticket, which is the moment `/wayfinding:wayfinder` resurveys.
- **Commit reference**: every commit message on `item/<id>` starts with `#<id>`.
