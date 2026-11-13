// Component pages of the page tree: per key, the body component, the headings its contents list shows and its props.
// Contract: contracts/188-page-tree.md section 4. The headings and the body read the same data, so they cannot drift.
import Home from "./Home.astro";
import ReferenceBody from "./ReferenceBody.astro";
import { ui } from "../i18n/ui.mjs";
import { loadSkills } from "../lib/skills.mjs";

function referenceGroups() {
  const groups = new Map();
  for (const s of loadSkills()) groups.set(s.plugin, [...(groups.get(s.plugin) ?? []), s]);
  return [...groups].map(([plugin, skills]) => ({
    plugin,
    id: plugin,
    skills: skills.map((s) => ({ ...s, id: `${plugin}-${s.name}` })),
  }));
}

export const registry = {
  home: {
    body: Home,
    props: () => ({}),
    headings: (lang) => [
      { depth: 2, id: "what", text: ui[lang].whatH },
      { depth: 2, id: "reference", text: ui[lang].referenceH },
    ],
  },
  reference: {
    body: ReferenceBody,
    props: () => ({ groups: referenceGroups() }),
    headings: () =>
      referenceGroups().flatMap((g) => [
        { depth: 2, id: g.id, text: g.plugin },
        ...g.skills.map((s) => ({ depth: 3, id: s.id, text: s.name })),
      ]),
  },
};
