// The requirement's definition of an agent source and the expected values computed from the files (never typed in), written
// independently of the loader. Not a test file: the runner glob is tests/site/*.test.mjs.
import fs from "node:fs";
import path from "node:path";
import { PLUGINS, skillSources, parseFrontmatter } from "./lib.mjs";

const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

export function agentSources(dir = PLUGINS) {
  const out = [];
  for (const plugin of fs.readdirSync(dir)) {
    if (plugin.startsWith(".") || !fs.statSync(path.join(dir, plugin)).isDirectory()) continue;
    const ad = path.join(dir, plugin, "agents");
    if (!fs.existsSync(ad) || !fs.statSync(ad).isDirectory()) continue;
    for (const f of fs.readdirSync(ad)) {
      if (f.startsWith(".") || !f.endsWith(".md") || !fs.statSync(path.join(ad, f)).isFile()) continue;
      out.push({ plugin, rel: `${plugin}/agents/${f}`, file: path.join(ad, f) });
    }
  }
  return out;
}
const toolList = (v) => (typeof v === "string" ? v.split(",") : Array.isArray(v) ? v.map(String) : []).map((s) => s.trim()).filter(Boolean);
export function expectedAgents(dir = PLUGINS) {
  return agentSources(dir).map(({ plugin, file }) => {
    const fm = parseFrontmatter(file);
    const model = typeof fm.model === "string" && fm.model.trim() !== "" ? fm.model.trim() : null;
    return { plugin, name: fm.name, description: String(fm.description).trim(), model, tools: toolList(fm.tools) };
  }).sort((a, b) => cmp(a.plugin, b.plugin) || cmp(a.name, b.name));
}
export function expectedCounts(dir = PLUGINS) {
  const a = expectedAgents(dir), s = skillSources(dir);
  return { skills: s.length, "skill-plugins": new Set(s.map((x) => x.plugin)).size, agents: a.length, "agent-plugins": new Set(a.map((x) => x.plugin)).size };
}

