// Agent loader: reads plugins/<plugin>/agents/<file>.md. Contract: contracts/225-agents-loader.md.
// Built in memory at build time; nothing generated is written or committed.
import fs from "node:fs";
import path from "node:path";
import { parse } from "yaml";

const visible = (e) => !e.name.startsWith(".");

function readSource(file, rel) {
  const fail = (why) => new Error(`reference: ${rel}: ${why}`);
  const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
  if (lines[0] !== "---") throw fail("no frontmatter");
  const end = lines.indexOf("---", 1);
  if (end < 0) throw fail("no frontmatter");
  let data;
  try {
    data = parse(lines.slice(1, end).join("\n"));
  } catch (e) {
    throw fail(`bad YAML: ${e.message.split("\n")[0]}`);
  }
  if (data === null || typeof data !== "object" || Array.isArray(data)) throw fail("no frontmatter");
  for (const key of ["name", "description"]) {
    if (data[key] === undefined || data[key] === null || data[key] === "") throw fail(`missing required field "${key}"`);
    if (typeof data[key] !== "string") throw fail(`field "${key}" must be a string`);
    if (data[key].trim() === "") throw fail(`missing required field "${key}"`);
  }
  const model = data.model;
  if (model !== undefined && model !== null && typeof model !== "string") throw fail('field "model" must be a string');
  const raw = data.tools;
  let tools = [];
  if (typeof raw === "string") tools = raw.split(",");
  else if (Array.isArray(raw) && raw.every((t) => typeof t === "string")) tools = raw;
  else if (raw !== undefined && raw !== null) throw fail('field "tools" must be a string or a list of strings');
  return {
    name: data.name,
    description: data.description,
    model: typeof model === "string" && model.trim() !== "" ? model : null,
    tools: tools.map((t) => t.trim()).filter((t) => t !== ""),
  };
}

export function loadAgents(pluginsDir = process.env.PLUGINS_DIR ?? path.resolve(process.cwd(), "../../plugins")) {
  const out = [];
  for (const p of fs.readdirSync(pluginsDir, { withFileTypes: true }).filter((e) => e.isDirectory() && visible(e))) {
    const agentsDir = path.join(pluginsDir, p.name, "agents");
    if (!fs.existsSync(agentsDir) || !fs.statSync(agentsDir).isDirectory()) continue;
    for (const f of fs.readdirSync(agentsDir, { withFileTypes: true }).filter((e) => e.isFile() && visible(e) && e.name.endsWith(".md"))) {
      const entry = readSource(path.join(agentsDir, f.name), `${p.name}/agents/${f.name}`);
      out.push({ plugin: p.name, ...entry });
    }
  }
  if (out.length === 0) throw new Error(`reference: no agent files found under ${pluginsDir}`);
  const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
  return out.sort((a, b) => cmp(a.plugin, b.plugin) || cmp(a.name, b.name));
}
