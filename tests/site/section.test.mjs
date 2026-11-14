// Slice 225, sections C and E (AC-9 to AC-13, AC-18): the Reference section in the wiki shell. AC-16 is a11y.test.mjs (the real
// `npm run build` checks every page, now ten); AC-17 and the content of the pages are agents.test.mjs and reference.test.mjs.
// The independent page-tree model (oracle.mjs) checks every page against pages.mjs; this file adds pinned facts the model cannot
// check about itself (order, parents, Dutch labels), the overview markup, the frozen shell and the drafts line.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { BASE, REPO, SITE, realBuild, realBuildResult, htmlFiles, serve, launch, readPage, siteCopy, editIn, buildCopy } from "./lib.mjs";
import { loadEntries, oracle, verifyBuild as verifyBuildIn } from "./oracle.mjs";
import { expectedCounts } from "./oracle-agents.mjs";

let browser;
before(async () => { browser = await launch(); });
after(async () => { await browser?.close(); });

const git = (...args) => spawnSync("git", args, { cwd: REPO, encoding: "utf8" });

// ---------- AC-9: the section is added by data and page content only ----------
function pathsBlock(file) {
  const t = fs.readFileSync(path.join(REPO, "contracts", file), "utf8");
  const m = t.match(/^Paths:\n((?:- .+\n)+)/m);
  assert.ok(m, `${file} has a Paths block`);
  return m[1].trim().split("\n").map((l) => l.slice(2).trim());
}
test("AC-9 the branch changes under apps/site/ only the contracts' Paths (shell code frozen); nothing under plugins/ or .github/", () => {
  const allowed = [...pathsBlock("225-agents-loader.md"), ...pathsBlock("225-reference-section.md"), "apps/site/src/lib/agents.mjs", "apps/site/test/agents.test.mjs"];
  const mb = git("merge-base", "main", "HEAD");
  assert.equal(mb.status, 0, "main is reachable from the branch");
  const changed = git("diff", mb.stdout.trim(), "--name-only").stdout.split("\n").filter(Boolean);
  const under = changed.filter((f) => f.startsWith("apps/site/"));
  const ok = (f) => allowed.some((a) => (a.endsWith("/") ? f.startsWith(a) : f === a));
  assert.deepEqual(under.filter((f) => !ok(f)), [], "apps/site paths outside the contracts' Paths blocks");
  assert.deepEqual(changed.filter((f) => f.startsWith("plugins/") || f.startsWith(".github/")), [], "the slice touches no plugins/ or .github/ path");
  // the named shell files, explicitly (the requirement's list), so a loosened Paths block cannot hide a change
  const frozen = ["lib/pages.mjs", "lib/skills.mjs", "lib/langScript.mjs", "lib/rehypePage.mjs", "layouts/Base.astro", "layouts/Page.astro", "pages/[...slug].astro", "pages/nl/[...slug].astro",
    "components/PageTree.astro", "components/Breadcrumb.astro", "components/Contents.astro", "components/SeeAlso.astro", "components/TopBar.astro", "components/LangSwitcher.astro", "components/DraftNotice.astro", "components/Home.astro"]
    .map((f) => `apps/site/src/${f}`).concat(["apps/site/astro.config.mjs", "apps/site/package.json", "apps/site/package-lock.json"]);
  for (const f of frozen) assert.ok(!changed.includes(f), `${f} is shell code or a dependency list and must not change`);
  assert.ok(!changed.some((f) => f.startsWith("apps/site/scripts/")), "no change to the a11y script");
});

// ---------- AC-10, AC-12, AC-13: the page tree data, pinned independently of the model ----------
test("AC-10/12/13 page tree data: Reference translated, no alsoListedIn, Skills then Agents children of Reference, all three Dutch pages drafts", async () => {
  const entries = await loadEntries();
  const by = Object.fromEntries(entries.map((e) => [e.slug, e]));
  assert.equal(by.reference.title.nl, "Naslag", "decided: the Dutch title is Naslag");
  assert.equal(by.reference.alsoListedIn, undefined, "Reference no longer lists itself in Dutch through alsoListedIn");
  assert.equal(by.reference.parent, "");
  for (const s of ["skills", "agents"]) {
    assert.equal(by[s].parent, "reference", `${s} nests under Reference`);
    assert.ok(by[s].title.en && by[s].title.nl, `${s} has both titles`);
    assert.equal(by[s].source, "component");
  }
  assert.equal(by.skills.title.en, "Skills"); assert.equal(by.agents.title.en, "Agents");
  assert.ok(entries.findIndex((e) => e.slug === "skills") < entries.findIndex((e) => e.slug === "agents"), "Skills before Agents in the array, so the tree lists them in that order");
  for (const s of ["reference", "skills", "agents"]) assert.equal(by[s].review?.nl, "draft", `${s}: the Dutch page ships as a draft`);
  assert.deepEqual(entries.filter((e) => e.slug).map((e) => e.slug).sort(), ["agents", "getting-started", "reference", "skills"]);
});

// ---------- every page of the build against the model (AC-10, AC-11 see-also, AC-12, AC-13, AC-18) ----------
test("AC-10/11/12/13/18 every built page agrees with the page tree: tree, breadcrumb, contents, see-also, switcher, drafts, one script", async () => {
  const dist = realBuild();
  const o = oracle(await loadEntries());
  await verifyBuildIn(browser, dist, o);
});

async function readAll(dist, routes) {
  const srv = await serve(dist);
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  try { const out = {}; for (const r of routes) out[r] = await readPage(ctx, srv.origin, r); return out; } finally { await ctx.close(); await srv.close(); }
}

test("AC-10 explicit: the tree nests Skills then Agents under Reference under Home, breadcrumbs and current entries per language", async () => {
  const dist = realBuild();
  const want = { en: { home: "Home", ref: "Reference", skills: "Skills", agents: "Agents", pre: "" }, nl: { home: "Thuis", ref: "Naslag", skills: "Vaardigheden", agents: "Agenten", pre: "nl/" } };
  const pages = await readAll(dist, ["", "nl/"].flatMap((p) => ["reference/", "skills/", "agents/"].map((s) => `${BASE}/${p}${s}`)));
  for (const [route, d] of Object.entries(pages)) {
    const l = route.startsWith(`${BASE}/nl/`) ? "nl" : "en", w = want[l];
    const slug = route.replace(`${BASE}/${w.pre}`, "").replace(/\/$/, "");
    assert.equal(d.lang, l);
    const rows = d.treeItems.map((i) => [i.a.text, i.a.href, i.depth]);
    const ref = rows.findIndex((r) => r[0] === w.ref);
    assert.ok(ref >= 0, `${route}: tree lists ${w.ref}`);
    assert.equal(rows[ref][1], `${BASE}/${w.pre}reference/`, `${route}: a real link to the page of this language`);
    assert.deepEqual(rows.slice(ref + 1, ref + 3), [[w.skills, `${BASE}/${w.pre}skills/`, rows[ref][2] + 1], [w.agents, `${BASE}/${w.pre}agents/`, rows[ref][2] + 1]], `${route}: Skills then Agents directly under Reference`);
    assert.ok(d.treeItems.every((i) => i.a.hreflang === null && i.a.lang === null), `${route}: no tree link is marked as foreign (no lang or hreflang)`);
    assert.deepEqual(d.treeCurrent, [{ reference: w.ref, skills: w.skills, agents: w.agents }[slug]], `${route}: aria-current on exactly the page read`);
    assert.deepEqual(d.crumbItems.map((i) => i.own), slug === "reference" ? [w.home, w.ref] : [w.home, w.ref, w[slug]], `${route}: breadcrumb`);
    if (slug !== "reference") assert.equal(d.crumbItems[1].a.href, `${BASE}/${w.pre}reference/`, `${route}: the Reference crumb is a link in this language`);
    assert.equal(d.crumbItems[0].a.href, `${BASE}/${w.pre}`);
    const other = l === "en" ? "nl/" : "";
    assert.equal(d.switcher.find((s) => s.dataLang !== l).href, `${BASE}/${other}${slug}/`, `${route}: the switcher goes to the same slug in the other language`);
    assert.deepEqual(d.h1.length, 1);
  }
});

// ---------- AC-11: the overview ----------
async function readOverview(dist, route) {
  const srv = await serve(dist);
  const ctx = await browser.newContext();
  try {
    const page = await ctx.newPage();
    await page.goto(srv.origin + route);
    return await page.evaluate(() => {
      const main = document.querySelector("main");
      const own = [...main.querySelectorAll("*")].filter((e) => !e.closest("nav") && !e.closest("[data-draft-notice]"));
      // walk the page body in document order and attribute links, counts and paragraphs to the current h2
      const secs = []; let cur = { id: "(intro)", links: [], counts: [], paras: [], h2: null };
      secs.push(cur);
      for (const e of own) {
        if (e.tagName === "H2") { cur = { id: e.id, links: [], counts: [], paras: [], h2: e.textContent.trim() }; secs.push(cur); }
        else if (e.tagName === "A") cur.links.push({ href: e.getAttribute("href"), lang: e.getAttribute("lang"), hreflang: e.getAttribute("hreflang"), text: e.textContent.trim() });
        else if (e.hasAttribute("data-count")) cur.counts.push(e.dataset.count);
        else if (e.tagName === "P" && !e.querySelector("p")) cur.paras.push(e.textContent.trim());
      }
      return { secs, hasScripts: main.querySelectorAll("script").length, counts: Object.fromEntries([...main.querySelectorAll("[data-count]")].map((e) => [e.dataset.count, e.textContent])) };
    });
  } finally { await ctx.close(); await srv.close(); }
}

for (const [lang, pre, h2] of [["en", "", { skills: "Skills", agents: "Agents" }], ["nl", "nl/", { skills: "Vaardigheden", agents: "Agenten" }]]) {
  test(`AC-11 the ${lang} Reference overview: an intro, then a Skills and an Agents section in that order, each with a one-line description, a link to its own-language page and its derived counts`, async () => {
    const dist = realBuild();
    const ov = await readOverview(dist, `${BASE}/${pre}reference/`);
    assert.deepEqual(ov.secs.map((s) => s.id), ["(intro)", "skills", "agents"], "intro, then the two sections");
    assert.ok(ov.secs[0].paras.some((p) => p.length > 20), "an intro paragraph");
    const exp = expectedCounts();
    for (const [id, link, names] of [["skills", `${BASE}/${pre}skills/`, ["skills", "skill-plugins"]], ["agents", `${BASE}/${pre}agents/`, ["agents", "agent-plugins"]]]) {
      const s = ov.secs.find((x) => x.id === id);
      assert.equal(s.h2, h2[id]);
      assert.deepEqual(s.links.map((l) => l.href), [link], `${id}: one link, to the page of this language`);
      assert.ok(s.links[0].lang === null && s.links[0].hreflang === null, `${id}: no lang or hreflang attribute on the link`);
      assert.ok(s.paras.some((p) => p.length > 5), `${id}: a description`);
      assert.deepEqual([...s.counts].sort(), [...names].sort(), `${id}: its own derived counts, in its own section`);
    }
    for (const n of ["skills", "skill-plugins", "agents", "agent-plugins"]) assert.equal(Number(ov.counts[n]), exp[n], `${n}`);
    assert.ok(!ov.secs.some((s) => s.links.some((l) => /#/.test(l.href))), "the overview links to pages, not anchors");
  });
}

// ---------- AC-12: the drafts line and the one edit that removes a draft ----------
test("AC-12 the build's single drafts line names the three new Dutch pages, in the line's old form", () => {
  const { out } = realBuildResult();
  const lines = out.split("\n").filter((l) => l.includes("pages: dutch drafts:"));
  assert.equal(lines.length, 1);
  const list = lines[0].slice(lines[0].indexOf("pages: dutch drafts:") + "pages: dutch drafts:".length).trim().split(/\s+/);
  for (const r of ["reference", "skills", "agents"]) assert.ok(list.includes(`${BASE}/nl/${r}/`), `${r} is listed`);
  assert.ok(list.includes(`${BASE}/nl/`) && list.includes(`${BASE}/nl/getting-started/`), "the earlier drafts are still listed");
  assert.deepEqual(list, [...list].sort(), "sorted, as before");
  assert.ok(list.every((h) => h.startsWith(`${BASE}/nl/`)));
});

test("AC-12 each Dutch section page shows the draft notice and the English ones do not", async () => {
  const dist = realBuild();
  const pages = await readAll(dist, ["", "nl/"].flatMap((p) => ["reference/", "skills/", "agents/"].map((s) => `${BASE}/${p}${s}`)));
  for (const [route, d] of Object.entries(pages)) assert.equal(d.draftNotices.length, route.startsWith(`${BASE}/nl/`) ? 1 : 0, route);
});

test("AC-12 setting one page's review to reviewed is the one edit that removes it from the line and its notice", async () => {
  const copy = siteCopy();
  editIn(copy, "src/data/pages.mjs", (t) => `${t}\npages.find((p) => p.slug === "agents").review = { nl: "reviewed" };\n`);
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
  const line = b.out.split("\n").find((l) => l.includes("pages: dutch drafts:")) ?? "";
  assert.ok(!line.includes(`${BASE}/nl/agents/`), line);
  assert.ok(line.includes(`${BASE}/nl/skills/`) && line.includes(`${BASE}/nl/reference/`), line);
  const pages = await readAll(b.dist, [`${BASE}/nl/agents/`, `${BASE}/nl/skills/`]);
  assert.equal(pages[`${BASE}/nl/agents/`].draftNotices.length, 0);
  assert.equal(pages[`${BASE}/nl/skills/`].draftNotices.length, 1);
});

// ---------- AC-13: Dutch pages exist and are navigable ----------
test("AC-13 the Dutch Reference, Skills and Agents pages exist with lang nl; the Dutch Home's Reference link and the English switchers reach them", async () => {
  const dist = realBuild();
  const files = htmlFiles(dist);
  for (const s of ["reference", "skills", "agents"]) assert.ok(files.includes(`nl/${s}/index.html`) && files.includes(`${s}/index.html`), s);
  const pages = await readAll(dist, [`${BASE}/nl/`, `${BASE}/nl/reference/`, `${BASE}/nl/skills/`, `${BASE}/nl/agents/`, `${BASE}/reference/`, `${BASE}/skills/`, `${BASE}/agents/`]);
  for (const s of ["reference", "skills", "agents"]) {
    assert.equal(pages[`${BASE}/nl/${s}/`].lang, "nl");
    assert.equal(pages[`${BASE}/${s}/`].switcher.find((x) => x.dataLang === "nl").href, `${BASE}/nl/${s}/`);
  }
  const homeLink = pages[`${BASE}/nl/`].mainLinks.find((h) => /reference\/$/.test(h));
  assert.equal(homeLink, `${BASE}/nl/reference/`, "the Dutch Home's Reference link goes to the Dutch Reference page");
  const top = pages[`${BASE}/nl/`].topLinks.find((l) => /reference\/$/.test(l.href));
  assert.equal(top.href, `${BASE}/nl/reference/`, "the top bar's link likewise");
  assert.ok(top.hreflang === null && top.lang === null, "no hreflang=en or lang=en on it");
  for (const d of Object.values(pages).filter((x) => x.lang === "nl")) assert.ok(!d.treeItems.some((i) => i.a.hreflang === "en"), "no English link in the Dutch tree");
});

// ---------- AC-18: no new client script ----------
test("AC-18 every built page holds the one language script and no other, no external script", async () => {
  const dist = realBuild();
  const home = fs.readFileSync(path.join(dist, "index.html"), "utf8");
  const scriptOf = (h) => [...h.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)].map((m) => m[0]);
  const base = scriptOf(home);
  assert.equal(base.length, 1);
  for (const f of htmlFiles(dist)) {
    const s = scriptOf(fs.readFileSync(path.join(dist, f), "utf8"));
    assert.equal(s.length, 1, `${f}: one script`);
    assert.ok(!/\bsrc=/.test(s[0]), `${f}: inline, no external script`);
  }
  assert.ok(!fs.readdirSync(dist, { recursive: true }).some((f) => String(f).endsWith(".js")), "no built .js file");
});
