// Rules for slice 244: every backticked name and path on a hand-written page is verified against the repository.
// Files only: no build, no browser. The three AC-19 rules (commandsIn, marketplaceNames, unknownCommands) live here
// so getting-started.test.mjs and names.test.mjs share them without one test file importing the other.
import fs from "node:fs";
import path from "node:path";
import { REPO, SITE, PLUGINS, skillSources, parseFrontmatter } from "./lib.mjs";

export const CONTENT = path.join(SITE, "src/content/pages");

// Commands: what the page names must exist in the repository.
export function commandsIn(codeBlocks) {
  const text = codeBlocks.join("\n");
  return {
    slash: [...text.matchAll(/(?:^|[\s`"'(])\/([a-z][a-z0-9-]*):([a-z][a-z0-9-]*)/gm)].map((m) => ({ plugin: m[1], skill: m[2] })),
    installs: [...text.matchAll(/\binstall\s+([a-z][a-z0-9-]*)@([a-z][a-z0-9-]*)/g)].map((m) => ({ plugin: m[1], marketplace: m[2] })),
    text,
  };
}
// Plugin names the marketplace lists (upstream plugins are fetched, so they have no folder here).
export const marketplaceNames = (file = path.join(REPO, ".claude-plugin", "marketplace.json")) => new Set((JSON.parse(fs.readFileSync(file, "utf8")).plugins ?? []).map((p) => p.name));
export function unknownCommands(codeBlocks, sources = skillSources(PLUGINS), pluginsDir = PLUGINS, listed = marketplaceNames()) {
  const c = commandsIn(codeBlocks);
  const bad = [];
  const names = new Set(sources.map((s) => `${s.plugin}:${s.folder}`));
  for (const s of sources) { try { names.add(`${s.plugin}:${parseFrontmatter(s.file).name}`); } catch {} }
  for (const { plugin, skill } of c.slash) if (!names.has(`${plugin}:${skill}`)) bad.push(`/${plugin}:${skill}`);
  for (const { plugin, marketplace } of c.installs) {
    if (!listed.has(plugin) && !fs.existsSync(path.join(pluginsDir, plugin))) bad.push(`install ${plugin}`);
    if (marketplace !== "wimsuenens") bad.push(`marketplace ${marketplace}`);
  }
  return bad;
}

// ---- Tokenizer: the raw Markdown, CommonMark rules for code spans and fences (contract 244, section 1).

// Items {kind: "span" | "fence", text} in order of appearance.
function scan(markdown) {
  let lines = String(markdown).split("\n");
  if (lines[0]?.trim() === "---") {
    const end = lines.findIndex((l, i) => i > 0 && l.trim() === "---");
    if (end > 0) lines = lines.slice(end + 1);
  }
  const items = [];
  let para = [];
  const flush = () => { if (para.length) { spansOf(para.join("\n"), items); para = []; } };
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const open = /^\s*(`{3,}|~{3,})(.*)$/.exec(line);
    if (open && !(open[1][0] === "`" && open[2].includes("`"))) {
      flush();
      const ch = open[1][0], len = open[1].length;
      const body = [];
      i++;
      for (; i < lines.length; i++) {
        const m = /^\s*(`+|~+)\s*$/.exec(lines[i]);
        if (m && m[1][0] === ch && m[1].length >= len) break;
        body.push(lines[i]);
      }
      items.push({ kind: "fence", text: body.join("\n") });
      continue;
    }
    if (line.trim() === "") flush(); else para.push(line);
  }
  flush();
  return items;
}
function spansOf(text, items) {
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c === "\\" && (text[i + 1] === "`" || text[i + 1] === "\\")) { i += 2; continue; }
    if (c !== "`") { i++; continue; }
    let n = 0;
    while (text[i + n] === "`") n++;
    let j = i + n, close = -1;
    while (j < text.length) {
      if (text[j] !== "`") { j++; continue; }
      let m = 0;
      while (text[j + m] === "`") m++;
      if (m === n) { close = j; break; }
      j += m;
    }
    if (close < 0) { i += n; continue; }
    let s = text.slice(i + n, close).replace(/\n/g, " ");
    if (s.length > 2 && s.startsWith(" ") && s.endsWith(" ") && s.trim() !== "") s = s.slice(1, -1);
    items.push({ kind: "span", text: s });
    i = close + n;
  }
}
export const fencedBlocks = (markdown) => scan(markdown).filter((x) => x.kind === "fence").map((x) => x.text);
export const inlineSpans = (markdown) => scan(markdown).filter((x) => x.kind === "span").map((x) => x.text);
export const backtickedTokens = (markdown) => scan(markdown).map((x) => x.text);

// ---- The path rule: docs/agents/<name>.md must appear verbatim in some plugins/**/SKILL.md.
export function agentPathsIn(tokens) {
  return tokens.flatMap((t) => [...t.matchAll(/(?<![\w./-])docs\/agents\/[A-Za-z0-9_-]+\.md/g)].map((m) => m[0]));
}
export function skillText(pluginsDir = PLUGINS) {
  const out = [];
  (function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true }).sort((a, b) => (a.name < b.name ? -1 : 1))) {
      if (e.name.startsWith(".") || e.name === "node_modules") continue;
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name === "SKILL.md") out.push(fs.readFileSync(p, "utf8"));
    }
  })(pluginsDir);
  return out.join("\0");
}
export function unknownAgentPaths(tokens, text = skillText()) {
  return agentPathsIn(tokens).filter((p) => !text.includes(p));
}
export function unknownNames(tokens, opts = {}) {
  const pluginsDir = opts.pluginsDir ?? PLUGINS;
  const sources = opts.sources ?? skillSources(pluginsDir);
  const listed = opts.listed ?? marketplaceNames();
  const text = opts.skillText ?? skillText(pluginsDir);
  return [...unknownCommands(tokens, sources, pluginsDir, listed), ...unknownAgentPaths(tokens, text)];
}

// ---- The pages: every *.md under <contentDir>/<lang>/, computed from the folder.
export function handWrittenPages(contentDir = CONTENT) {
  const out = [];
  if (!fs.existsSync(contentDir)) return out;
  for (const lang of fs.readdirSync(contentDir, { withFileTypes: true })) {
    if (!lang.isDirectory()) continue;
    (function walk(d, rel) {
      for (const e of fs.readdirSync(d, { withFileTypes: true })) {
        const p = path.join(d, e.name);
        if (e.isDirectory()) walk(p, [...rel, e.name]);
        else if (e.name.endsWith(".md")) out.push({ lang: lang.name, file: [...rel, e.name].join("/"), label: `${lang.name}/${[...rel, e.name].join("/")}`, path: p });
      }
    })(path.join(contentDir, lang.name), []);
  }
  return out.sort((a, b) => (a.label < b.label ? -1 : a.label > b.label ? 1 : 0));
}
export function pageFaults(pages, opts = {}) {
  return pages.flatMap((pg) => unknownNames(backtickedTokens(pg.text), opts).map((f) => `${pg.label}: ${f}`));
}
