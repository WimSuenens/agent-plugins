// 156 AC-13 to AC-18, now on the Skills page (225 AC-15): the generated skills list at /skills/ and /nl/skills/. Expected values are computed
// from the files, never hard-coded. The Reference overview is checked in section.test.mjs. Fixtures carry one agent (225: zero agents fails the build).
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { BASE, REPO, realBuild, buildSite, serve, launch, scratch, skillSources, parseFrontmatter } from "./lib.mjs";

let browser;
before(async () => { browser = await launch(); });
after(async () => { await browser?.close(); });

// Reads the Reference page of a build folder with a fresh browser context.
async function readReference(dist, route = `${BASE}/skills/`) {
  const srv = await serve(dist);
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  try {
    const r = await page.goto(srv.origin + route);
    assert.equal(r.status(), 200);
    return await page.evaluate(() => ({
      lang: document.documentElement.lang,
      langOnPluginText: [...document.querySelectorAll("main section > h2, main article > h3, main [data-field=description], main code")].every((e) => e.getAttribute("lang") === "en"),
      noLangOnPluginText: [...document.querySelectorAll("main section > h2, main article > h3, main [data-field=description], main code")].every((e) => !e.hasAttribute("lang")),
      text: document.body.innerText,
      html: document.documentElement.outerHTML,
      entries: [...document.querySelectorAll("[data-skill-entry]")].map((e) => {
        const f = (n) => e.querySelector(`[data-field="${n}"]`);
        return {
          plugin: e.dataset.plugin, name: e.dataset.name,
          h3: e.querySelector("h3")?.textContent.trim(),
          command: f("command")?.textContent.trim() ?? null,
          description: f("description")?.textContent.trim() ?? null,
          manual: f("manual") ? f("manual").textContent.trim() : null,
          hint: f("argument-hint") ? f("argument-hint").querySelector("code")?.textContent.trim() ?? "(no code)" : null,
          hintFull: f("argument-hint")?.textContent.trim() ?? null,
          fields: [...e.querySelectorAll("[data-field]")].map((x) => [x.dataset.field, x.textContent.trim()]),
          group: e.closest("section")?.querySelector("h2")?.id ?? null,
        };
      }),
    }));
  } finally { await ctx.close(); await srv.close(); }
}

function expectedFrom(pluginsDir) {
  return skillSources(pluginsDir).map(({ plugin, file }) => {
    const fm = parseFrontmatter(file);
    return { plugin, name: fm.name, description: String(fm.description).trim(), hint: fm["argument-hint"] ? String(fm["argument-hint"]).trim() : null, manual: fm["disable-model-invocation"] === true };
  });
}

const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

test("AC-13/14/15 real plugins: one entry per SKILL.md, each carrying its parsed frontmatter", async () => {
  const dist = realBuild();
  const exp = expectedFrom(path.join(REPO, "plugins"));
  assert.ok(exp.length > 0);
  const page = await readReference(dist);
  assert.equal(page.lang, "en");
  assert.ok(page.noLangOnPluginText, "on the English page no plugin-text element carries lang");
  assert.equal(page.entries.length, exp.length, "entry count equals the number of plugins/*/skills/*/SKILL.md");
  const key = (e) => `${e.plugin}/${e.name}`;
  assert.deepEqual(page.entries.map(key).sort(), exp.map(key).sort(), "no entry more or fewer, none from elsewhere");
  assert.equal(new Set(page.entries.map(key)).size, page.entries.length, "each source once");
  for (const e of exp) {
    const got = page.entries.find((x) => key(x) === key(e));
    assert.equal(got.h3, e.name);
    assert.equal(got.command, `/${e.plugin}:${e.name}`);
    assert.equal(got.description, e.description, `${key(e)} description equals the parsed frontmatter`);
    assert.equal(got.manual !== null, e.manual, `${key(e)} manual marker iff disable-model-invocation is true`);
    if (e.manual) assert.match(got.manual, /manual command/i);
    if (e.hint) assert.equal(got.hint, e.hint, `${key(e)} argument hint`);
    else assert.equal(got.hintFull, null, `${key(e)} must show no argument-hint label when it has none`);
    for (const [f, t] of got.fields) assert.ok(t.length > 0, `${key(e)} empty ${f} placeholder`);
  }
});

test("225 AC-14/15 the Dutch Skills page has the same entries, order and ids as the English one, plugin text marked lang=en, labels Dutch", async () => {
  const dist = realBuild();
  const en = await readReference(dist);
  const nl = await readReference(dist, `${BASE}/nl/skills/`);
  assert.equal(nl.lang, "nl");
  assert.ok(nl.langOnPluginText, "every plugin-text element (plugin h2, entry h3, description, every code) carries lang=en");
  const sig = (p) => p.entries.map((e) => [e.plugin, e.name, e.group, e.command, e.description, e.hint, e.manual !== null]);
  assert.deepEqual(sig(nl), sig(en), "same entries, same order, same plugin text");
  const manual = nl.entries.find((e) => e.manual !== null);
  if (manual) assert.doesNotMatch(manual.manual, /manual command/i, "the manual marker is Dutch");
  const hinted = nl.entries.find((e) => e.hintFull);
  if (hinted) assert.doesNotMatch(hinted.hintFull, /argument hint/i, "the argument hint label is Dutch");
  assert.equal(await (async () => { const srv = await serve(dist); const ctx = await browser.newContext(); try { const pg = await ctx.newPage(); await pg.goto(srv.origin + `${BASE}/nl/skills/`); return pg.evaluate(() => document.querySelectorAll("p[data-field=english-note]").length); } finally { await ctx.close(); await srv.close(); } })(), 1, "one visible Dutch sentence saying the entries are English");
});

test("AC-15 odd characters survive on the real page: no mojibake or visible entities, backticks literal", async () => {
  const dist = realBuild();
  const page = await readReference(dist);
  assert.ok(!/â€|Ã.|&amp;|&lt;|&gt;|&#\d+;|&quot;/.test(page.text), "visible mojibake or entity");
  const exp = expectedFrom(path.join(REPO, "plugins"));
  const withTick = exp.filter((e) => e.description.includes("`"));
  assert.ok(withTick.length > 0, "the real plugins have backtick descriptions (factory run)");
  for (const e of withTick) {
    const got = page.entries.find((x) => x.plugin === e.plugin && x.name === e.name);
    assert.ok(got.description.includes("`"), `${e.plugin}:${e.name} backticks stay literal`);
  }
  assert.ok(exp.some((e) => e.description.includes("—")), "em dash present in the sources");
});

test("AC-13 sorted by plugin then name (code-point order), one h2 group per plugin", async () => {
  const dist = realBuild();
  const page = await readReference(dist);
  const order = page.entries.map((e) => [e.plugin, e.name]);
  const sorted = [...order].sort((a, b) => cmp(a[0], b[0]) || cmp(a[1], b[1]));
  assert.deepEqual(order, sorted);
  for (const e of page.entries) assert.equal(e.group, e.plugin, "entry sits under its plugin's heading");
});

test("AC-16 no generated data is left in the work tree by a build", () => {
  const status = () => spawnSync("git", ["status", "--porcelain", "--untracked-files=all"], { cwd: REPO, encoding: "utf8" }).stdout;
  const before = status();
  const b = buildSite();
  assert.equal(b.status, 0, b.out.slice(-1500));
  assert.equal(status(), before, "a build changes no tracked or untracked non-ignored file");
});

// ---- fixture-driven rebuild cases ----
function skill(dir, plugin, folder, fm, body = "# body ignored\n") {
  const d = path.join(dir, plugin, "skills", folder);
  fs.mkdirSync(d, { recursive: true });
  fs.writeFileSync(path.join(d, "SKILL.md"), `---\n${fm}\n---\n${body}`);
}
const TRICKY = `Run it — now: "quoted" and 'single', a - b, ellipsis…, \`code\`, /slash/path, #hash, a: b, <b>not markup</b> & amp`;

function fixture() {
  const dir = scratch("plugins-");
  skill(dir, "alpha", "one", `name: one\ndescription: ${JSON.stringify(TRICKY)}\nargument-hint: "[idea | #map]"\ndisable-model-invocation: true`);
  skill(dir, "alpha", "two", `name: two\ndescription: Plain description only.`);
  skill(dir, "beta", "folder-name", `name: renamed\ndescription: Frontmatter name wins over the folder name.\nlicense: MIT\nversion: 1.2.3\nextra-key: ignored`);
  skill(dir, "alpha", "str-flag", `name: str-flag\ndescription: A string flag is not manual.\ndisable-model-invocation: "true"\nargument-hint: ""`);
  // things that must be ignored
  fs.mkdirSync(path.join(dir, "alpha", "skills", ".hidden"), { recursive: true });
  fs.writeFileSync(path.join(dir, "alpha", "skills", ".hidden", "SKILL.md"), "---\nname: hidden\ndescription: no\n---\n");
  fs.mkdirSync(path.join(dir, "alpha", "skills", "no-skill-file"), { recursive: true });
  fs.mkdirSync(path.join(dir, "gamma", "agents"), { recursive: true }); // plugin without skills/
  fs.writeFileSync(path.join(dir, "gamma", "agents", "g.md"), "---\nname: g\ndescription: The one agent every fixture needs.\n---\nbody\n");
  fs.writeFileSync(path.join(dir, ".DS_Store"), "x");
  skill(dir, "alpha", "two/nested", `name: nested\ndescription: Deeper than two levels is not a source.`);
  return dir;
}

test("AC-14/15/16/17 fixture: odd characters, optional fields, name override, ignored files", async () => {
  const dir = fixture();
  const b = buildSite({ plugins: dir });
  assert.equal(b.status, 0, b.out.slice(-1500));
  const page = await readReference(b.dist);
  assert.deepEqual(page.entries.map((e) => `${e.plugin}/${e.name}`), ["alpha/one", "alpha/str-flag", "alpha/two", "beta/renamed"]);
  const one = page.entries[0];
  assert.equal(one.description, TRICKY);
  assert.equal(one.command, "/alpha:one");
  assert.ok(one.manual !== null);
  assert.equal(one.hint, "[idea | #map]");
  assert.ok(!/<b>not markup<\/b>/.test(page.html.replace(/&lt;b&gt;not markup&lt;\/b&gt;/g, "")), "description markup must be escaped, not injected");
  const sf = page.entries[1];
  assert.equal(sf.manual, null, "string value is not manual");
  assert.equal(sf.hintFull, null, "empty argument-hint shows no label");
  const two = page.entries[2];
  assert.equal(two.manual, null);
  assert.equal(two.hintFull, null);
  assert.equal(page.entries[3].command, "/beta:renamed");
});

test("AC-16 rebuild: a changed description, an added skill and a removed skill show up with no other edit", async () => {
  const dir = fixture();
  let b = buildSite({ plugins: dir });
  assert.equal(b.status, 0, b.out.slice(-1500));
  let page = await readReference(b.dist);
  assert.equal(page.entries.length, 4);
  // change
  skill(dir, "alpha", "two", `name: two\ndescription: A brand new description.`);
  // add
  skill(dir, "delta", "fresh", `name: fresh\ndescription: Newly added skill.`);
  // remove
  fs.rmSync(path.join(dir, "beta", "skills", "folder-name"), { recursive: true });
  b = buildSite({ plugins: dir });
  assert.equal(b.status, 0, b.out.slice(-1500));
  page = await readReference(b.dist);
  const by = (p, n) => page.entries.find((e) => e.plugin === p && e.name === n);
  assert.equal(by("alpha", "two").description, "A brand new description.");
  assert.ok(by("delta", "fresh"));
  assert.equal(by("beta", "renamed"), undefined, "removed skill is gone");
  assert.equal(page.entries.length, 4);
  assert.ok(!page.text.includes("Plain description only."));
});

const BROKEN = {
  "no description": ["name: broken", "description"],
  "empty description": ['name: broken\ndescription: ""', "description"],
  "no name": ["description: has no name", "name"],
  "empty name": ['name: ""\ndescription: x', "name"],
  "non-string description": ["name: broken\ndescription: [a, b]", "description"],
  "non-string argument-hint": ["name: broken\ndescription: x\nargument-hint: [a, b]", "argument-hint"],
  "bad yaml": ["name: broken\ndescription: [unclosed", null],
};
for (const [label, [fm, field]] of Object.entries(BROKEN)) {
  test(`AC-17 a source with ${label} fails the build and names the file`, () => {
    const dir = fixture();
    skill(dir, "factory", "broken", fm);
    const b = buildSite({ plugins: dir });
    assert.notEqual(b.status, 0, "build must fail");
    assert.ok(b.out.includes("factory/skills/broken/SKILL.md"), `output names the source:\n${b.out.slice(-1200)}`);
    if (field) assert.ok(b.out.includes(field), `output names the field ${field}`);
  });
}

test("AC-17 a source with no frontmatter fails the build and names the file", () => {
  const dir = fixture();
  const d = path.join(dir, "factory", "skills", "broken");
  fs.mkdirSync(d, { recursive: true });
  fs.writeFileSync(path.join(d, "SKILL.md"), "# just a body\n");
  const b = buildSite({ plugins: dir });
  assert.notEqual(b.status, 0);
  assert.ok(b.out.includes("factory/skills/broken/SKILL.md"));
});

test("AC-17 zero sources is an error, so a moved folder cannot give an empty page", () => {
  const dir = scratch("plugins-empty-");
  fs.mkdirSync(path.join(dir, "p", "skills"), { recursive: true });
  const b = buildSite({ plugins: dir });
  assert.notEqual(b.status, 0);
  assert.match(b.out, /no SKILL\.md files found/);
});

test("AC-18 breadcrumb back to Home and an on-page contents list that jumps to each plugin group", async () => {
  const dist = realBuild();
  const srv = await serve(dist);
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  try {
    await page.goto(srv.origin + `${BASE}/skills/`);
    const crumb = await page.evaluate(() => {
      const n = document.querySelector('nav[aria-label="Breadcrumb"]');
      return n && { items: [...n.querySelectorAll("ol > li")].map((li) => ({ text: li.textContent.trim(), href: li.querySelector("a")?.getAttribute("href") ?? null, cur: (li.querySelector("[aria-current]") ?? li).getAttribute("aria-current") })) };
    });
    assert.ok(crumb, "nav[aria-label=Breadcrumb] exists");
    assert.equal(crumb.items.length, 3, "225: Home > Reference > Skills");
    assert.equal(crumb.items[0].href, `${BASE}/`);
    assert.equal(crumb.items[1].text, "Reference");
    assert.equal(crumb.items[1].href, `${BASE}/reference/`);
    assert.equal(crumb.items[2].text, "Skills");
    assert.equal(crumb.items[2].cur, "page");
    const plugins = [...new Set(skillSources().map((s) => s.plugin))].sort(cmp);
    const toc = await page.evaluate(() => [...document.querySelectorAll('nav[aria-label="On this page"] > ol > li > a, nav[aria-label="On this page"] > ul > li > a')].map((a) => a.getAttribute("href")));
    assert.deepEqual(toc, plugins.map((p) => `#${p}`), "one top-level contents link per plugin, alphabetical (the skills are nested h3 entries since 188)");
    const nested = await page.evaluate(() => [...document.querySelectorAll('nav[aria-label="On this page"] li li > a')].map((a) => a.getAttribute("href")));
    const wantNested = skillSources().map((s) => `#${s.plugin}-${parseFrontmatter(s.file).name}`).sort(cmp);
    assert.deepEqual([...nested].sort(cmp), wantNested, "one nested contents link per skill, from the generator's output (188 AC-12)");
    for (const id of [...plugins, ...wantNested.map((h) => h.slice(1))]) assert.ok(await page.evaluate((i) => !!document.getElementById(i), id), `${id} exists on the page`);
    for (const p of plugins) {
      await page.click(`nav[aria-label="On this page"] a[href="#${p}"]`);
      assert.equal(new URL(page.url()).hash, `#${p}`);
      const h = await page.evaluate((id) => { const e = document.getElementById(id); const r = e.getBoundingClientRect(); return { tag: e.tagName, text: e.textContent.trim(), top: r.top, h: innerHeight, n: e.closest("section").querySelectorAll("[data-skill-entry]").length }; }, p);
      assert.equal(h.tag, "H2");
      assert.equal(h.text, p);
      assert.ok(h.top >= -2 && h.top < h.h, `${p} heading scrolled into view`);
      assert.equal(h.n, skillSources().filter((s) => s.plugin === p).length, `${p} group holds its skills`);
    }
  } finally { await ctx.close(); await srv.close(); }
});

// ---------- 188 AC-12: the generated Reference needs no hand-kept list anywhere ----------
test("AC-12 a skill under a plugin with no skills yet adds its group to the Reference contents list on rebuild, touching only that plugin folder; the tree and the breadcrumb do not change", async () => {
  const plugins = path.join(scratch("plugins-newgroup-"), "plugins");
  fs.cpSync(path.join(REPO, "plugins"), plugins, { recursive: true });
  fs.mkdirSync(path.join(plugins, "zz-newgroup", "skills", "hello"), { recursive: true });
  fs.writeFileSync(path.join(plugins, "zz-newgroup", "skills", "hello", "SKILL.md"), "---\nname: hello\ndescription: A skill of a new plugin group.\n---\n\nBody.\n");
  const real = realBuild();
  const b = buildSite({ plugins });
  assert.equal(b.status, 0, b.out.slice(-1500));
  const read = async (dist) => {
    const srv = await serve(dist);
    const ctx = await browser.newContext();
    try {
      const page = await ctx.newPage();
      await page.goto(srv.origin + `${BASE}/skills/`);
      return await page.evaluate(() => {
        const t = (e) => e.textContent.trim().replace(/\s+/g, " ");
        return {
          contents: [...document.querySelectorAll('nav[aria-label="On this page"] a')].map((a) => a.getAttribute("href")),
          tree: [...document.querySelectorAll("nav[data-nav=pages] a")].map((a) => [t(a), a.getAttribute("href"), a.getAttribute("aria-current")]),
          crumb: [...document.querySelectorAll("nav[data-nav=breadcrumb] li")].map(t),
          h2: document.getElementById("zz-newgroup")?.tagName ?? null,
          h3: document.getElementById("zz-newgroup-hello")?.tagName ?? null,
        };
      });
    } finally { await ctx.close(); await srv.close(); }
  };
  const [before, after] = [await read(real), await read(b.dist)];
  assert.ok(!before.contents.includes("#zz-newgroup"));
  assert.ok(after.contents.includes("#zz-newgroup") && after.contents.includes("#zz-newgroup-hello"), "the new group and its skill are in the contents list");
  assert.deepEqual([after.h2, after.h3], ["H2", "H3"], "the heading ids work");
  assert.deepEqual(after.tree, before.tree, "the navigation tree lists the page, not its skills");
  assert.deepEqual(after.crumb, before.crumb);
  assert.equal(after.contents.length, before.contents.length + 2);
});
