// Component pages of the page tree: per key, the body component, the headings its contents list shows and its props.
// Contracts: contracts/188-page-tree.md section 4, contracts/225-reference-section.md section 2. The headings and the body
// read the same data, so they cannot drift.
import Home from "./Home.astro";
import ReferenceOverview from "./ReferenceOverview.astro";
import SkillsBody from "./SkillsBody.astro";
import AgentsBody from "./AgentsBody.astro";
import { ui } from "../i18n/ui.mjs";
import { getModel } from "../lib/pages.mjs";
import { loadSkills } from "../lib/skills.mjs";
import { loadAgents } from "../lib/agents.mjs";

function group(items, key) {
  const groups = new Map();
  for (const item of items) groups.set(item.plugin, [...(groups.get(item.plugin) ?? []), item]);
  return [...groups].map(([plugin, list]) => ({
    plugin,
    id: plugin,
    [key]: list.map((item) => ({ ...item, id: `${plugin}-${item.name}` })),
  }));
}

const skillGroups = () => group(loadSkills(), "skills");
const agentGroups = () => group(loadAgents(), "entries");

// The one place the counts are computed: array lengths and distinct plugins, never typed.
function referenceCounts() {
  const skills = loadSkills();
  const agents = loadAgents();
  return {
    skills: skills.length,
    skillPlugins: new Set(skills.map((s) => s.plugin)).size,
    agents: agents.length,
    agentPlugins: new Set(agents.map((a) => a.plugin)).size,
  };
}

const headingsOf = (groups, key) =>
  groups.flatMap((g) => [{ depth: 2, id: g.id, text: g.plugin }, ...g[key].map((e) => ({ depth: 3, id: e.id, text: e.name }))]);

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
    body: ReferenceOverview,
    props: () => ({ counts: referenceCounts() }),
    headings: (lang) => [
      { depth: 2, id: "skills", text: getModel().title("skills", lang) },
      { depth: 2, id: "agents", text: getModel().title("agents", lang) },
    ],
  },
  skills: {
    body: SkillsBody,
    props: () => ({ groups: skillGroups(), counts: referenceCounts() }),
    headings: () => headingsOf(skillGroups(), "skills"),
  },
  agents: {
    body: AgentsBody,
    props: () => ({ groups: agentGroups(), counts: referenceCounts() }),
    headings: () => headingsOf(agentGroups(), "entries"),
  },
};
