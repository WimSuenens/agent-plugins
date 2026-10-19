# Prototyping candidates

Reached from `direction` phase 4, after the user has asked for prototypes.
Build one landing-page mockup per chosen candidate, for the user's actual
product, implementing that candidate's counted commitments literally: the
counted colours, the type roles, the named shape/elevation device, the
motion rules, the voice rules.

- **Artifact tool available this session** → load the `artifact-design`
  skill first (its own contract requires this), then publish one artifact
  per candidate.
- **Artifact tool not available** → write a self-contained static
  HTML+CSS file per candidate (inline `<style>`, no build step, no
  external assets) to `design/prototypes/<candidate-slug>.html` in the
  user's project. Ask before writing outside the current project, and
  offer a different folder if the user prefers. Tell the user to open it
  in a browser themselves.

**Done when** every candidate the user asked for has one prototype, and
each prototype's palette, type, device, motion and copy can be traced to
a line in its brief.
