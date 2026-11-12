---
status: proposed
---

# The Obeya is a Nuxt 4 application shipped as a container image on GHCR

Issue [#122](https://github.com/WimSuenens/agent-plugins/issues/122), under spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121).

## Context

The Obeya must start with one command on a project owner's machine, on Apple silicon and Intel, without the owner building anything. The factory plugin is installed into a user's plugin cache, so anything inside the plugin folder is copied to every user.

## Decision

- The app is a **Nuxt 4** application with server rendering and minimal client script, shipped as a **multi-architecture container image** built by CI and published to **GHCR**.
- The app's source lives **outside the plugin folder**. The plugin carries only the compose file, the start script and the skill.
- The app is **versioned on its own** (its own semver). The plugin's compose file pins that version, and the release check fails when the pinned tag does not exist.
- **Image visibility: public GHCR package.** Decision card to the person: public package, or private package with a pull token. The image holds only the app, never project data, so a public package costs nothing in secrecy and spares every user a pull token. This answer is the spec's stated default; the session that wrote this ADR could not ask the person, so the person confirms or overturns it by amending this section (see the way back).

## Consequences

- A plugin install runs a known app version; a typo fix in a skill does not rebuild the image.
- Users need Docker, and a start failure (Docker missing, image not found, port taken) must be reported in one line.
- The first CI workflow of the repo is created for this image.
- A public package is world-pullable; nothing project-specific may ever be baked into the image.

## Way back

Switching the package to private later requires a pull token in the start script and the skill's documentation; the app and the compose pin do not change. Moving off GHCR changes the image reference in the compose file and the workflow only. Dropping Nuxt means rewriting the app behind the read-model schemas, which stay.
