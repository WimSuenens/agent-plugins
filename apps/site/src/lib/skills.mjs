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
  const hint = data["argument-hint"];
  if (hint !== undefined && hint !== null && typeof hint !== "string") throw fail('field "argument-hint" must be a string');
  return {
    name: data.name,
    description: data.description,
    argumentHint: typeof hint === "string" && hint.trim() !== "" ? hint : null,
    manual: data["disable-model-invocation"] === true,
  };
}

export function loadSkills(pluginsDir = process.env.PLUGINS_DIR ?? path.resolve(process.cwd(), "../../plugins")) {
  const out = [];
  for (const p of fs.readdirSync(pluginsDir, { withFileTypes: true }).filter((e) => e.isDirectory() && visible(e))) {
    const skillsDir = path.join(pluginsDir, p.name, "skills");
    if (!fs.existsSync(skillsDir)) continue;
    for (const s of fs.readdirSync(skillsDir, { withFileTypes: true }).filter((e) => e.isDirectory() && visible(e))) {
      const file = path.join(skillsDir, s.name, "SKILL.md");
      if (!fs.existsSync(file)) continue;
      const entry = readSource(file, `${p.name}/skills/${s.name}/SKILL.md`);
      out.push({ plugin: p.name, command: `/${p.name}:${entry.name}`, ...entry });
    }
  }
  if (out.length === 0) throw new Error(`reference: no SKILL.md files found under ${pluginsDir}`);
  const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
  return out.sort((a, b) => cmp(a.plugin, b.plugin) || cmp(a.name, b.name));
}
