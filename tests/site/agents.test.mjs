// Slice 225, sections A, B, D (AC-1 to AC-8, AC-14, AC-15 agents half, AC-17): the generated Agents page, the loader, the derived counts.
// Contracts: contracts/225-agents-loader.md and contracts/225-reference-section.md (markup in section 3).
// Expected values are computed from the files under the plugins folder (the real one, or a fixture through PLUGINS_DIR), never typed in.
// Fixtures build the real site source against a fixture plugins tree; no site file is touched.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { BASE, SITE, PLUGINS, realBuild, buildSite, serve, launch, scratch, skillSources } from "./lib.mjs";
import { agentSources, expectedAgents, expectedCounts } from "./oracle-agents.mjs";

let browser;
before(async () => { browser = await launch(); });
after(async () => { await browser?.close(); });

// ---------- reading a built page ----------
async function read(dist, route, { width = 1280 } = {}) {
  const srv = await serve(dist);
  const ctx = await browser.newContext({ viewport: { width, height: 800 } });
  try {
    const page = await ctx.newPage();
    const r = await page.goto(srv.origin + route);
    assert.equal(r.status(), 200, route);
    return await page.evaluate(() => {
      const t = (e) => e.textContent.trim();
      const main = document.querySelector("main");
      const sel = (e, s) => e.querySelector(s);
      return {
        lang: document.documentElement.lang,
        text: main.innerText,
        mainHtml: main.innerHTML,
        counts: Object.fromEntries([...main.querySelectorAll("[data-count]")].map((e) => [e.dataset.count, e.textContent])),
        countEls: [...main.querySelectorAll("[data-count]")].map((e) => e.dataset.count),
        groups: [...main.querySelectorAll("section")].map((s) => ({ id: s.querySelector("h2")?.id ?? null, text: s.querySelector("h2")?.textContent.trim() ?? null, lang: s.querySelector("h2")?.getAttribute("lang") ?? null, entries: s.querySelectorAll("[data-agent-entry]").length })),
        englishNote: [...main.querySelectorAll('p[data-field="english-note"]')].map(t),
        entries: [...main.querySelectorAll("[data-agent-entry]")].map((e) => {
          const model = sel(e, '[data-field="model"]'), tools = sel(e, '[data-field="tools"]'), d = sel(e, '[data-field="description"]');
          return {
            plugin: e.dataset.plugin, name: e.dataset.name,
            h3: { id: sel(e, "h3")?.id, text: sel(e, "h3") ? t(sel(e, "h3")) : null, lang: sel(e, "h3")?.getAttribute("lang") ?? null },
            group: e.closest("section")?.querySelector("h2")?.id ?? null,
            description: d ? t(d) : null, descriptionLang: d?.getAttribute("lang") ?? null,
            model: model ? t(sel(model, "[data-value]")) : null,
            modelLabel: model ? t(sel(model, "span")) : null,
            modelCodeLang: model ? sel(model, "[data-value]")?.getAttribute("lang") ?? null : null,
            tools: tools ? [...tools.querySelectorAll("li code[data-value]")].map(t) : null,
            toolsLabel: tools ? t(sel(tools, "span")) : null,
            toolLis: tools ? tools.querySelectorAll("li").length : 0,
            toolLangs: tools ? [...tools.querySelectorAll("li code")].map((c) => c.getAttribute("lang")) : [],
            text: t(e),
            fields: [...e.querySelectorAll("[data-field]")].map((x) => [x.dataset.field, t(x)]),
          };
        }),
        contents: [...document.querySelectorAll("nav[data-nav=contents] a")].map((a) => a.getAttribute("href")),
        overflow: { sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth },
        toolBoxes: [...main.querySelectorAll('[data-field="tools"]')].map((x) => ({ right: x.getBoundingClientRect().right, h: x.getBoundingClientRect().height, items: [...x.querySelectorAll("li")].map((li) => li.getBoundingClientRect().right), tops: [...x.querySelectorAll("li")].map((li) => Math.round(li.getBoundingClientRect().top)) })),
      };
    });
  } finally { await ctx.close(); await srv.close(); }
}

// The page agrees with the files: entries (one per source, in order), grouping, fields, ids.
function assertAgentsPage(p, dir, where) {
  const exp = expectedAgents(dir);
  const key = (e) => `${e.plugin}/${e.name}`;
  assert.deepEqual(p.entries.map(key), exp.map(key), `${where}: one entry per agent source, ordered by plugin then name`);
  exp.forEach((e, i) => {
    const g = p.entries[i], at = `${where} ${key(e)}`;
    assert.equal(g.group, e.plugin, `${at}: under its plugin's heading`);
    assert.equal(g.h3.text, e.name, `${at}: h3 is the frontmatter name`);
    assert.equal(g.h3.id, `${e.plugin}-${e.name}`, `${at}: id`);
    assert.equal(g.description, e.description, `${at}: description equals the parsed frontmatter`);
    assert.equal(g.model, e.model, `${at}: model as written, no Model line when absent`);
    assert.deepEqual(g.tools ?? [], e.tools, `${at}: tools in file order, no Tools block when empty`);
    assert.equal(g.tools === null, e.tools.length === 0, `${at}: tools block present iff there are tools`);
    assert.equal(g.toolLis, e.tools.length, `${at}: one li per tool`);
    assert.doesNotMatch(g.text, /\bundefined\b|\bnull\b|\[object/, `${at}: no placeholder text`);
    for (const [f, text] of g.fields) assert.ok(text.length > 0, `${at}: empty ${f}`);
    if (g.model !== null) assert.ok(g.modelLabel.length > 0);
    if (g.tools !== null) assert.ok(g.toolsLabel.length > 0);
  });
  const plugins = [...new Set(exp.map((e) => e.plugin))];
  assert.deepEqual(p.groups.map((g) => g.id), plugins, `${where}: one group per plugin that has agents, none empty, none for others`);
  assert.deepEqual(p.groups.map((g) => g.entries), plugins.map((x) => exp.filter((e) => e.plugin === x).length));
  const ids = [...p.groups.map((g) => g.id), ...p.entries.map((e) => e.h3.id)];
  assert.equal(new Set(ids).size, ids.length, `${where}: ids unique`);
  for (const id of ids) assert.ok(p.contents.includes(`#${id}`), `${where}: #${id} reachable from the contents list`);
  assert.doesNotMatch(p.text, /â€|Ã.|&amp;|&lt;|&gt;|&#\d+;|&quot;/, `${where}: no mojibake or visible entity`);
}

function assertCounts(p, dir, names, where) {
  const exp = expectedCounts(dir);
  assert.deepEqual([...p.countEls].sort(), [...names].sort(), `${where}: each count shown once, no others`);
  for (const n of names) {
    assert.match(p.counts[n], /^\d+$/, `${where}: data-count=${n} holds only the number`);
    assert.equal(Number(p.counts[n]), exp[n], `${where}: ${n} equals the number computed from the files`);
  }
}

const ROUTE = { en: { agents: `${BASE}/agents/`, skills: `${BASE}/skills/`, reference: `${BASE}/reference/` }, nl: { agents: `${BASE}/nl/agents/`, skills: `${BASE}/nl/skills/`, reference: `${BASE}/nl/reference/` } };
const COUNTS = { agents: ["agents", "agent-plugins"], skills: ["skills", "skill-plugins"], reference: ["skills", "skill-plugins", "agents", "agent-plugins"] };

// ---------- the real repository: AC-1 to AC-4, AC-6, AC-8, AC-14, AC-15 ----------
test("AC-1/2/3/4 real plugins: the build succeeds and the Agents page lists every plugins/*/agents/*.md once, with its parsed fields, in order", async () => {
  const dist = realBuild();
  const exp = expectedAgents();
  assert.ok(exp.length >= 8, "the factory plugin's role agents are sources");
  for (const lang of ["en", "nl"]) assertAgentsPage(await read(dist, ROUTE[lang].agents), PLUGINS, lang);
});

test("AC-1 / AC-6 real plugins: plugins without an agents folder have no group on Agents and still appear on Skills; no copy from .claude/worktrees", async () => {
  const dist = realBuild();
  const without = fs.readdirSync(PLUGINS).filter((p) => !p.startsWith(".") && !fs.existsSync(path.join(PLUGINS, p, "agents")));
  assert.ok(without.length >= 1, "at least one real plugin has no agents folder");
  const agents = await read(dist, ROUTE.en.agents), skills = await read(dist, ROUTE.en.skills);
  const skillPlugins = new Set(skillSources().map((s) => s.plugin));
  for (const p of without) {
    assert.ok(!agents.groups.some((g) => g.id === p), `${p}: no group on the Agents page`);
    if (skillPlugins.has(p)) assert.ok(skills.groups.some((g) => g.id === p), `${p}: still a group on the Skills page`);
  }
  assert.ok(agents.groups.every((g) => g.entries > 0), "no empty heading");
  assert.equal(agents.entries.length, expectedAgents().length, "worktree copies of agent files are not counted");
});

test("AC-2/3 real plugins: odd characters survive (commas, parentheses, slashes) and the English page carries no lang on plugin text", async () => {
  const dist = realBuild();
  const p = await read(dist, ROUTE.en.agents);
  for (const e of p.entries) {
    assert.equal(e.descriptionLang, null, `${e.name}: no lang on the English page`);
    assert.equal(e.h3.lang, null);
    assert.equal(e.modelCodeLang, null);
    assert.ok(e.toolLangs.every((l) => l === null));
  }
  assert.ok(p.groups.every((g) => g.lang === null));
  assert.deepEqual(p.englishNote, [], "the English page has no english-note sentence");
  assert.ok(expectedAgents().some((e) => /[(),/]/.test(e.description)), "the real descriptions hold punctuation");
});

test("AC-8 real plugins: every count on Reference, Skills and Agents is computed from the files, in English and Dutch", async () => {
  const dist = realBuild();
  for (const lang of ["en", "nl"]) for (const page of ["reference", "skills", "agents"]) {
    assertCounts(await read(dist, ROUTE[lang][page]), PLUGINS, COUNTS[page], `${lang}/${page}`);
  }
});

test("AC-14 real plugins: the Dutch Agents page has Dutch labels, plugin text marked lang=en, one Dutch note, the same entries and ids as English", async () => {
  const dist = realBuild();
  const en = await read(dist, ROUTE.en.agents), nl = await read(dist, ROUTE.nl.agents);
  assert.equal(nl.lang, "nl");
  const sig = (p) => p.entries.map((e) => [e.plugin, e.name, e.group, e.h3.id, e.description, e.model, e.tools]);
  assert.deepEqual(sig(nl), sig(en), "same entries, order, ids and plugin text");
  assert.equal(nl.englishNote.length, 1, "exactly one visible sentence saying the entries are English");
  assert.ok(nl.englishNote[0].length > 10);
  assert.notEqual(nl.englishNote[0], en.text);
  assert.ok(nl.groups.every((g) => g.lang === "en"), "plugin h2 is English text: lang=en");
  for (const e of nl.entries) {
    assert.equal(e.h3.lang, "en", `${e.name}: h3`);
    assert.equal(e.descriptionLang, "en", `${e.name}: description`);
    if (e.model !== null) assert.equal(e.modelCodeLang, "en", `${e.name}: model value`);
    assert.ok(e.toolLangs.every((l) => l === "en"), `${e.name}: every tool name`);
    if (e.tools) assert.match(e.toolsLabel, /hulpmiddel/i, "the tools label is Dutch");
  }
  assert.ok(en.entries.some((e) => /^tools/i.test(e.toolsLabel ?? "")), "the English label is Tools");
});

test("AC-15 real plugins: Skills and Agents pages use the id scheme <plugin> and <plugin>-<name>", async () => {
  const dist = realBuild();
  const p = await read(dist, ROUTE.en.agents);
  for (const e of p.entries) assert.equal(e.h3.id, `${e.plugin}-${e.name}`);
  for (const g of p.groups) assert.ok(p.entries.some((e) => e.plugin === g.id));
});

// ---------- AC-17: a narrow phone ----------
test("AC-17 the Agents page, English and Dutch, has no horizontal scroll at 320px and the longest tools list stays inside the viewport", async () => {
  const dist = realBuild();
  const longest = Math.max(...expectedAgents().map((e) => e.tools.length));
  for (const route of [ROUTE.en.agents, ROUTE.nl.agents]) {
    const p = await read(dist, route, { width: 320 });
    assert.ok(p.overflow.sw <= p.overflow.cw, `${route}: scrollWidth ${p.overflow.sw} > clientWidth ${p.overflow.cw}`);
    const box = p.toolBoxes.find((b) => b.items.length === longest);
    assert.ok(box, "the longest list is on the page");
    assert.ok(box.right <= 320.5 && box.items.every((r) => r <= 320.5), `${route}: the tools list stays inside the viewport`);
  }
});

// ---------- loader, called directly: exact messages of the contract (section 4) ----------
const loader = async () => (await import(`${pathToFileURL(path.join(SITE, "src/lib/agents.mjs")).href}?q=${Math.random()}`)).loadAgents;

function plugins(files) { // { "plugin/agents/file.md": text | null (dir) }
  const dir = scratch("plugins-ag-");
  for (const [rel, text] of Object.entries(files)) {
    const f = path.join(dir, rel);
    if (text === null) fs.mkdirSync(f, { recursive: true });
    else { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, text); }
  }
  return dir;
}
const fmOf = (fm, body = "body ignored\n") => `---\n${fm}\n---\n${body}`;

test("loader: the shape, tools as a string and as a list give the same array, model null and tools [] when absent or blank, extra keys ignored", async () => {
  const loadAgents = await loader();
  const dir = plugins({
    "factory/agents/integrator.md": fmOf("name: integrator\ndescription: Merge train. Use to merge approved slices (rebase, bump, merge, tag, clean up).\ntools: Read, Grep, Glob, Bash\nmodel: sonnet\nskills:\n  - a:b\ncolor: red"),
    "factory/agents/listy.md": fmOf("name: listy\ndescription: Same names as a list.\ntools: [Read, Grep, Glob, Bash]\nmodel: sonnet"),
    "factory/agents/neither.md": fmOf("name: neither\ndescription: No model, no tools."),
    "factory/agents/blank.md": fmOf('name: blank\ndescription: Blank values.\nmodel: "  "\ntools: ""'),
    "factory/agents/spaced.md": fmOf('name: spaced\ndescription: Empty pieces dropped, order and duplicates kept.\ntools: " Read , ,Write,Read,"'),
  });
  const got = loadAgents(dir);
  const by = Object.fromEntries(got.map((a) => [a.name, a]));
  assert.deepEqual(by.integrator, { plugin: "factory", name: "integrator", description: "Merge train. Use to merge approved slices (rebase, bump, merge, tag, clean up).", model: "sonnet", tools: ["Read", "Grep", "Glob", "Bash"] });
  assert.deepEqual(by.listy.tools, by.integrator.tools);
  assert.deepEqual([by.neither.model, by.neither.tools], [null, []]);
  assert.deepEqual([by.blank.model, by.blank.tools], [null, []]);
  assert.deepEqual(by.spaced.tools, ["Read", "Write", "Read"]);
  assert.deepEqual(got.map((a) => a.name), ["blank", "integrator", "listy", "neither", "spaced"], "sorted by plugin then name");
  assert.deepEqual(Object.keys(by.integrator).sort(), ["description", "model", "name", "plugin", "tools"], "nothing else is carried");
});

test("loader: discovery reads exactly plugins/<plugin>/agents/<file>.md; hidden names, non-.md files, directories and deeper levels are ignored; empty agents folders are skipped", async () => {
  const loadAgents = await loader();
  const ok = (n) => fmOf(`name: ${n}\ndescription: d ${n}`);
  const dir = plugins({
    "alpha/agents/one.md": ok("one"),
    "alpha/agents/.hidden.md": ok("hidden"),
    "alpha/agents/notes.txt": "x",
    "alpha/agents/README": "x",
    "alpha/agents/sub/deeper.md": ok("deeper"),
    "alpha/agents/dir.md": null,
    "alpha/skills/s/SKILL.md": fmOf("name: s\ndescription: d"),
    "beta/skills/s/SKILL.md": fmOf("name: s\ndescription: d"),
    "gamma/agents/.gitkeep": "",
    "gamma/agents/notes.txt": "x",
    ".claude/worktrees/copy/agents/copy.md": ok("copy"),
    ".hid/agents/h.md": ok("h"),
    "alpha.md": ok("outside"),
    "alpha/other/x.md": ok("other"),
  });
  assert.deepEqual(loadAgents(dir).map((a) => `${a.plugin}/${a.name}`), ["alpha/one"]);
});

const FAULT = {
  "no description": ["name: broken", 'missing required field "description"'],
  "empty description": ['name: broken\ndescription: ""', 'missing required field "description"'],
  "blank description": ['name: broken\ndescription: "   "', 'missing required field "description"'],
  "no name": ["description: has no name", 'missing required field "name"'],
  "empty name": ['name: ""\ndescription: x', 'missing required field "name"'],
  "non-string name": ["name: 5\ndescription: x", 'field "name" must be a string'],
  "non-string description": ["name: broken\ndescription: [a, b]", 'field "description" must be a string'],
  "non-string model": ["name: broken\ndescription: x\nmodel: [a]", 'field "model" must be a string'],
  "tools that is a mapping": ["name: broken\ndescription: x\ntools:\n  a: b", 'field "tools" must be a string or a list of strings'],
  "tools list with a non-string": ["name: broken\ndescription: x\ntools: [Read, {a: b}]", 'field "tools" must be a string or a list of strings'],
  "bad YAML": ["name: broken\ndescription: [unclosed", "bad YAML: "],
};
for (const [label, [fm, msg]] of Object.entries(FAULT)) {
  test(`AC-5 loader: an agent with ${label} throws, naming the source and the reason, with the reference: prefix`, async () => {
    const loadAgents = await loader();
    const dir = plugins({ "factory/agents/ok.md": fmOf("name: ok\ndescription: fine"), "factory/agents/broken.md": fmOf(fm) });
    assert.throws(() => loadAgents(dir), (e) => e.message.startsWith("reference: factory/agents/broken.md: ") && e.message.includes(msg), `message: ${label}`);
  });
}
for (const [label, text] of [["no frontmatter", "# just a body\n"], ["an unterminated frontmatter", "---\nname: x\ndescription: y\n"], ["frontmatter that is a list", "---\n- a\n- b\n---\nbody\n"], ["frontmatter that is a scalar", "---\njust text\n---\nbody\n"], ["empty frontmatter", "---\n---\nbody\n"]]) {
  test(`AC-5 loader: ${label} throws naming the source`, async () => {
    const loadAgents = await loader();
    const dir = plugins({ "factory/agents/broken.md": text });
    assert.throws(() => loadAgents(dir), (e) => e.message.startsWith("reference: factory/agents/broken.md: "), label);
  });
}
test("AC-5 loader: the contract's own example line, and no agent is skipped to hide a broken one", async () => {
  const loadAgents = await loader();
  const dir = plugins({ "factory/agents/integrator.md": fmOf("name: integrator\ntools: Read") });
  assert.throws(() => loadAgents(dir), { message: 'reference: factory/agents/integrator.md: missing required field "description"' });
  const dir2 = plugins({ "factory/agents/integrator.md": "no frontmatter at all\n" });
  assert.throws(() => loadAgents(dir2), { message: "reference: factory/agents/integrator.md: no frontmatter" });
});
test("loader: zero agent sources anywhere is an error, with the contract's message", async () => {
  const loadAgents = await loader();
  const dir = plugins({ "alpha/agents/notes.txt": "x", "beta/skills/s/SKILL.md": fmOf("name: s\ndescription: d"), "gamma/agents": null });
  assert.throws(() => loadAgents(dir), { message: `reference: no agent files found under ${dir}` });
});
test("loader: PLUGINS_DIR is the default root, the same override as the skills loader", async () => {
  const loadAgents = await loader();
  const dir = plugins({ "alpha/agents/a.md": fmOf("name: a\ndescription: d") });
  const old = process.env.PLUGINS_DIR;
  process.env.PLUGINS_DIR = dir;
  try { assert.deepEqual(loadAgents().map((a) => a.name), ["a"]); } finally { if (old === undefined) delete process.env.PLUGINS_DIR; else process.env.PLUGINS_DIR = old; }
});

// ---------- built fixtures: AC-3, AC-5, AC-6, AC-7, AC-8, AC-14, AC-15, AC-17 ----------
const TRICKY = `Draws, sketches (fast, rough) and/or many - "quoted" and 'single', a: b, #hash, ellipsis…, \`code\`, /slash/path, <b>not markup</b> & amp, ünïcode — dash`;
const skill = (dir, plugin, folder, extra = "") => {
  const d = path.join(dir, plugin, "skills", folder);
  fs.mkdirSync(d, { recursive: true });
  fs.writeFileSync(path.join(d, "SKILL.md"), `---\nname: ${folder}\ndescription: Skill ${folder}.${extra}\n---\n# body\n`);
};
const agent = (dir, plugin, file, fm) => {
  const d = path.join(dir, plugin, "agents");
  fs.mkdirSync(d, { recursive: true });
  fs.writeFileSync(path.join(d, file), fmOf(fm));
};
const LONGTOOL = `mcp__plugin_some_very_long_server_name__${"averylongtoolnamewithoutanybreak".repeat(4)}`;
function fixture() {
  const dir = scratch("plugins-ag-fx-");
  skill(dir, "alpha", "one"); skill(dir, "alpha", "two"); skill(dir, "beta", "solo");
  agent(dir, "alpha", "zeta.md", `name: zeta\ndescription: ${JSON.stringify(TRICKY)}\nmodel: haiku\ntools: "Read, Grep,  Glob , ,Bash"`);
  agent(dir, "alpha", "file-name.md", "name: bravo\ndescription: The frontmatter name wins over the file name.\nmodel: inherit\ntools: Read, Grep, Glob, Bash");
  agent(dir, "alpha", "list-form.md", `name: charlie\ndescription: Tools as a YAML list.\nmodel: sonnet\ntools:\n  - Read\n  - " Grep "\n  - Glob\n  - Bash\n  - ${LONGTOOL}\nskills:\n  - a:b\ncolor: red`);
  agent(dir, "alpha", "no-model.md", "name: nomodel\ndescription: Has tools, no model.\ntools: Read");
  agent(dir, "alpha", "no-tools.md", "name: notools\ndescription: Has a model, no tools.\nmodel: inherit");
  agent(dir, "alpha", "neither.md", "name: neither\ndescription: Neither model nor tools.");
  agent(dir, "alpha", "blank.md", 'name: blank\ndescription: Blank optional values.\nmodel: "  "\ntools: ""');
  // must be ignored
  const ad = path.join(dir, "alpha", "agents");
  fs.writeFileSync(path.join(ad, ".hidden.md"), fmOf("name: hidden\ndescription: no"));
  fs.writeFileSync(path.join(ad, "notes.txt"), "x");
  fs.mkdirSync(path.join(ad, "sub"), { recursive: true });
  fs.writeFileSync(path.join(ad, "sub", "deeper.md"), fmOf("name: deeper\ndescription: no"));
  fs.mkdirSync(path.join(dir, "gamma", "agents"), { recursive: true }); // empty agents folder
  fs.writeFileSync(path.join(dir, "gamma", "agents", ".gitkeep"), "");
  skill(dir, "gamma", "g");
  fs.mkdirSync(path.join(dir, ".hid", "agents"), { recursive: true });
  fs.writeFileSync(path.join(dir, ".hid", "agents", "h.md"), fmOf("name: h\ndescription: no"));
  return dir;
}

let base; // the built fixture, shared by the tests below
function built() {
  if (!base) {
    const dir = fixture();
    const b = buildSite({ plugins: dir });
    assert.equal(b.status, 0, b.out.slice(-1500));
    base = { dir, ...b };
  }
  return base;
}

test("AC-2/3/5/6 fixture: odd characters, tools as string or list, optional fields absent or blank, names from frontmatter, ignored files; no group for a plugin with an empty agents folder", async () => {
  const { dir, dist } = built();
  for (const lang of ["en", "nl"]) {
    const p = await read(dist, ROUTE[lang].agents);
    assertAgentsPage(p, dir, `fixture ${lang}`);
    assert.deepEqual(p.groups.map((g) => g.id), ["alpha"], "only alpha has agents: gamma (empty folder), beta (none), .hid (hidden) have no group");
    const by = Object.fromEntries(p.entries.map((e) => [e.name, e]));
    assert.equal(by.zeta.description, TRICKY, "description equals the YAML-parsed text");
    assert.deepEqual(by.zeta.tools, ["Read", "Grep", "Glob", "Bash"], "comma string: pieces trimmed, empties dropped");
    assert.deepEqual(by.charlie.tools, ["Read", "Grep", "Glob", "Bash", LONGTOOL], "YAML list form, trimmed");
    assert.deepEqual(by.bravo.tools, by.charlie.tools.slice(0, 4), "string and list give the same names");
    assert.equal(by.nomodel.model, null); assert.equal(by.nomodel.modelLabel, null);
    assert.equal(by.notools.tools, null); assert.equal(by.notools.toolsLabel, null);
    for (const n of ["neither", "blank"]) assert.deepEqual([by[n].model, by[n].tools, by[n].modelLabel, by[n].toolsLabel], [null, null, null, null], `${n}: complete without the missing fields`);
    assert.ok(!/<b>not markup<\/b>/.test(p.mainHtml.replace(/&lt;b&gt;not markup&lt;\/b&gt;/g, "")), "description markup escaped, not injected");
    assert.ok(!p.entries.some((e) => ["hidden", "deeper", "h"].includes(e.name)));
  }
});

test("AC-8 fixture: counts on the three pages equal the fixture, in both languages", async () => {
  const { dir, dist } = built();
  for (const lang of ["en", "nl"]) for (const page of ["reference", "skills", "agents"]) assertCounts(await read(dist, ROUTE[lang][page]), dir, COUNTS[page], `fixture ${lang}/${page}`);
});

test("AC-14 / AC-15 fixture: Dutch marks the English text, ids come from the frontmatter name, and the Dutch entries equal the English ones", async () => {
  const { dist } = built();
  const en = await read(dist, ROUTE.en.agents), nl = await read(dist, ROUTE.nl.agents);
  assert.deepEqual(nl.entries.map((e) => [e.h3.id, e.description, e.tools]), en.entries.map((e) => [e.h3.id, e.description, e.tools]));
  assert.ok(nl.entries.every((e) => e.descriptionLang === "en" && e.h3.lang === "en"));
  assert.ok(en.entries.some((e) => e.h3.id === "alpha-bravo"), "the entry id uses the frontmatter name, not the file name (file-name.md)");
  assert.equal(nl.englishNote.length, 1);
});

test("AC-17 fixture: a tools list with a very long unbreakable name still fits a 320px phone, English and Dutch", async () => {
  const { dist } = built();
  for (const route of [ROUTE.en.agents, ROUTE.nl.agents]) {
    const p = await read(dist, route, { width: 320 });
    assert.ok(p.overflow.sw <= p.overflow.cw, `${route}: scrollWidth ${p.overflow.sw} > clientWidth ${p.overflow.cw}`);
    assert.ok(p.toolBoxes.every((b) => b.items.every((r) => r <= 320.5)), `${route}: every tool item inside the viewport`);
  }
});

const BROKEN_BUILD = {
  "no description": ["name: broken", "description"],
  "empty description": ['name: broken\ndescription: ""', "description"],
  "no name": ["description: has no name", "name"],
  "empty name": ['name: ""\ndescription: x', "name"],
  "non-string model": ["name: broken\ndescription: x\nmodel: [a]", "model"],
  "bad YAML": ["name: broken\ndescription: [unclosed", "YAML"],
};
for (const [label, [fm, word]] of Object.entries(BROKEN_BUILD)) {
  test(`AC-5 build: an agent with ${label} fails the build, naming the file and the fault`, () => {
    const dir = fixture();
    agent(dir, "factory", "broken.md", fm);
    const b = buildSite({ plugins: dir });
    assert.notEqual(b.status, 0, "the build must fail");
    assert.ok(b.out.includes("factory/agents/broken.md"), `output names the source:\n${b.out.slice(-1200)}`);
    assert.ok(b.out.includes(word), `output names the fault ${word}`);
  });
}
test("AC-5 build: an agent with no frontmatter fails the build and names the file", () => {
  const dir = fixture();
  fs.mkdirSync(path.join(dir, "factory", "agents"), { recursive: true });
  fs.writeFileSync(path.join(dir, "factory", "agents", "broken.md"), "# just a body\n");
  const b = buildSite({ plugins: dir });
  assert.notEqual(b.status, 0);
  assert.ok(b.out.includes("factory/agents/broken.md"));
});
test("AC-5 build: zero agent files anywhere fails the build with the contract's message", () => {
  const dir = scratch("plugins-noagents-");
  skill(dir, "alpha", "one");
  fs.mkdirSync(path.join(dir, "alpha", "agents"), { recursive: true });
  fs.writeFileSync(path.join(dir, "alpha", "agents", "notes.txt"), "x");
  const b = buildSite({ plugins: dir });
  assert.notEqual(b.status, 0);
  assert.match(b.out, /reference: no agent files found under /);
});

test("AC-7 / AC-8 rebuild: a changed description, model and tools, an added agent (existing plugin and first agent of another plugin) and a removed one show up in English and Dutch with no other edit; every count follows", async () => {
  const { dir: d0, dist: dist0 } = built();
  const dir = scratch("plugins-ag-fx2-");
  fs.cpSync(d0, dir, { recursive: true });
  const before = expectedCounts(dir);
  agent(dir, "alpha", "file-name.md", "name: bravo\ndescription: A brand new description for bravo.\nmodel: haiku\ntools: [Write, Edit]");   // change
  agent(dir, "alpha", "added.md", "name: added\ndescription: Newly added to an existing plugin.\ntools: Read");                                     // add, existing plugin
  agent(dir, "beta", "first.md", "name: first\ndescription: First agent of a plugin that had no agents folder.\nmodel: sonnet\ntools: Bash");      // add, new group
  fs.rmSync(path.join(dir, "alpha", "agents", "neither.md"));                                                                                      // remove
  skill(dir, "beta", "extra"); fs.rmSync(path.join(dir, "alpha", "skills", "two"), { recursive: true });                                           // skill folder added and removed
  skill(dir, "delta", "newplugin");                                                                                                                // a skill in a new plugin
  const after = expectedCounts(dir);
  assert.equal(after.agents, before.agents + 1, "fixture sanity: +2 added, -1 removed");
  assert.equal(after["agent-plugins"], before["agent-plugins"] + 1);
  assert.equal(after["skill-plugins"], before["skill-plugins"] + 1);
  const b = buildSite({ plugins: dir });
  assert.equal(b.status, 0, b.out.slice(-1500));
  for (const lang of ["en", "nl"]) {
    const p = await read(b.dist, ROUTE[lang].agents);
    assertAgentsPage(p, dir, `rebuilt ${lang}`);
    const by = Object.fromEntries(p.entries.map((e) => [e.name, e]));
    assert.equal(by.bravo.description, "A brand new description for bravo.");
    assert.equal(by.bravo.model, "haiku");
    assert.deepEqual(by.bravo.tools, ["Write", "Edit"]);
    assert.ok(by.added && by.first, "added agents are listed");
    assert.equal(by.first.group, "beta", "the new agent under its plugin");
    assert.ok(p.groups.some((g) => g.id === "beta"), "a new plugin group appears with its first agent");
    assert.ok(!by.neither, "the removed agent is gone");
    assert.ok(p.contents.includes("#beta") && p.contents.includes("#beta-first"), "the contents list follows");
    for (const page of ["reference", "skills", "agents"]) assertCounts(await read(b.dist, ROUTE[lang][page]), dir, COUNTS[page], `rebuilt ${lang}/${page}`);
  }
  // the original build is untouched evidence that the numbers moved
  const o0 = await read(dist0, ROUTE.en.reference);
  assert.equal(Number(o0.counts.agents), before.agents);
  const o1 = await read(b.dist, ROUTE.en.reference);
  assert.equal(Number(o1.counts.agents), before.agents + 1);
  assert.equal(Number(o1.counts["agent-plugins"]), before["agent-plugins"] + 1);
  assert.equal(Number(o1.counts["skill-plugins"]), before["skill-plugins"] + 1);
  // and back: removing the added files returns the counts
  fs.rmSync(path.join(dir, "beta", "agents"), { recursive: true });
  fs.rmSync(path.join(dir, "alpha", "agents", "added.md"));
  const b2 = buildSite({ plugins: dir });
  assert.equal(b2.status, 0, b2.out.slice(-1500));
  assertCounts(await read(b2.dist, ROUTE.en.agents), dir, COUNTS.agents, "after removal");
  assert.ok(!(await read(b2.dist, ROUTE.en.agents)).groups.some((g) => g.id === "beta"), "the group disappears with its last agent");
});

// ---------- AC-8: no typed count in any page source ----------
const COUNT_WORDS = /\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s+(skills?|agents?|plugins?|agenten|vaardigheden|plugins)\b/i;
test("AC-8 control: the typed-count scan can fail", () => {
  assert.ok(COUNT_WORDS.test("Eight agents from 1 plugin"));
  assert.ok(COUNT_WORDS.test("27 skills"));
  assert.ok(!COUNT_WORDS.test("{agents} agents from {plugins} plugins"));
});
test("AC-8 no page source (pages.mjs, a content file, a UI string) holds a typed count of skills, agents or plugins", async () => {
  const src = path.join(SITE, "src");
  const files = ["data/pages.mjs", "i18n/ui.mjs"];
  for (const lang of ["en", "nl"]) for (const f of fs.readdirSync(path.join(src, "content/pages", lang))) files.push(`content/pages/${lang}/${f}`);
  for (const f of files) {
    const text = fs.readFileSync(path.join(src, f), "utf8");
    assert.ok(!COUNT_WORDS.test(text), `${f}: a count typed next to skills, agents or plugins`);
  }
  const { ui } = await import(`${pathToFileURL(path.join(src, "i18n/ui.mjs")).href}?q=${Math.random()}`);
  for (const lang of ["en", "nl"]) for (const k of ["referenceOverviewIntro", "skillsIntro", "agentsIntro", "skillsDesc", "agentsDesc", "skillsCountSentence", "agentsCountSentence", "referenceP"]) {
    assert.equal(typeof ui[lang][k], "string", `ui.${lang}.${k} exists`);
    assert.doesNotMatch(ui[lang][k], /\d/, `ui.${lang}.${k} carries no digit`);
  }
  for (const k of ["modelLabel", "toolsLabel", "englishNote"]) for (const lang of ["en", "nl"]) assert.ok(ui[lang][k]?.length > 0, `ui.${lang}.${k}`);
  assert.deepEqual(Object.keys(ui.en).sort(), Object.keys(ui.nl).sort(), "both languages keep equal key sets");
});

test("AC-7 no generated agent data is committed: no tracked file other than the agent sources and the loader holds an agent list", () => {
  const files = fs.readdirSync(path.join(SITE, "src"), { recursive: true }).map(String).filter((f) => /\.(json|mjs|ts|js|md|astro|yaml|yml)$/.test(f) && !f.includes("node_modules"));
  const names = expectedAgents().map((a) => a.name);
  for (const f of files) {
    if (["lib/agents.mjs", "data/pages.mjs"].includes(f) || f.startsWith("content/")) continue;
    const text = fs.readFileSync(path.join(SITE, "src", f), "utf8");
    const hits = names.filter((n) => text.includes(`"${n}"`) || text.includes(`'${n}'`));
    assert.ok(hits.length < 3, `${f} lists agent names (${hits}): generated data must not be committed`);
  }
});
