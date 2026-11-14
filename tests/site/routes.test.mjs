// AC-1, AC-2, AC-3, AC-4, AC-5, AC-12 (static facts) and the site layout. Slice 156; updated for slice 188 (five pages, page-tree routes,
// counterpart switcher): the pages are computed from the page tree, never counted by hand.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BASE, ROUTES, SITE, realBuild, buildSite, htmlFiles, routeOf, allFiles, serve, launch, scratch } from "./lib.mjs";
import { loadEntries, oracle } from "./oracle.mjs";

let dist, srv, browser, ctx;
before(async () => {
  dist = realBuild();
  srv = await serve(dist);
  browser = await launch();
  ctx = await browser.newContext({ javaScriptEnabled: false });
});
after(async () => { await ctx?.close(); await browser?.close(); await srv?.close(); });

async function read(route) {
  const page = await ctx.newPage();
  const resp = await page.goto(srv.origin + route);
  assert.equal(resp.status(), 200, route);
  const data = await page.evaluate(() => ({
    lang: document.documentElement.lang,
    title: document.title,
    h1: [...document.querySelectorAll("h1")].map((e) => e.textContent.trim()),
    h2: [...document.querySelectorAll("h2")].map((e) => e.textContent.trim()),
    lede: document.querySelector("p.lede")?.textContent.trim() ?? null,
    // body text and body links only: the breadcrumb, contents, see-also (navs) and the draft notice are checked in wiki.test.mjs
    mainParas: [...document.querySelectorAll("main p")].filter((e) => !e.closest("nav") && !e.hasAttribute("data-draft-notice")).map((e) => e.textContent.trim()),
    mainLinks: [...document.querySelectorAll("main a[href]")].filter((e) => !e.closest("nav")).map((e) => e.getAttribute("href")),
    mainText: document.querySelector("main")?.innerText ?? "",
    switcher: [...document.querySelectorAll("nav[data-lang-switcher] a")].map((a) => ({
      href: a.getAttribute("href"), text: a.textContent.trim(), hreflang: a.getAttribute("hreflang"),
      lang: a.getAttribute("lang"), current: a.getAttribute("aria-current"), dataLang: a.dataset.lang,
    })),
    switcherNav: document.querySelector("nav[data-lang-switcher]")?.getAttribute("aria-label"),
    switcherInTopbar: !!document.querySelector("header[data-test=topbar] nav[data-lang-switcher]"),
    scripts: [...document.querySelectorAll("script")].map((s) => ({ src: s.getAttribute("src"), inHead: !!s.closest("head"), len: s.textContent.length })),
    alternates: [...document.querySelectorAll('link[rel="alternate"][hreflang]')].map((l) => [l.getAttribute("hreflang"), l.getAttribute("href")]),
  }));
  await page.close();
  return data;
}

test("site lives in apps/site as a private npm project with a lockfile and ignores build output", () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(SITE, "package.json"), "utf8"));
  assert.equal(pkg.private, true);
  assert.ok(fs.existsSync(path.join(SITE, "package-lock.json")));
  const gi = fs.readFileSync(path.join(SITE, ".gitignore"), "utf8");
  for (const e of ["dist/", ".astro/", "node_modules/"]) assert.ok(gi.split("\n").map((l) => l.trim()).includes(e), `.gitignore lacks ${e}`);
  for (const s of ["build:site", "build", "check:a11y", "test"]) assert.ok(pkg.scripts?.[s], `script ${s}`);
});

test("only the pages of the page tree are built (188 AC-3, 225 AC-13: Skills and Agents and the Dutch Reference section exist; no 404 page)", async () => {
  const o = oracle(await loadEntries());
  assert.deepEqual(htmlFiles(dist).map((f) => routeOf(f)).sort(), o.pages.map((p) => p.route).sort());
  for (const f of ["reference", "skills", "agents"].flatMap((s) => [`${s}/index.html`, `nl/${s}/index.html`])) assert.ok(htmlFiles(dist).includes(f), `${f} is built`);
  assert.deepEqual(htmlFiles(dist).filter((f) => /404/.test(f)), []);
});

test("AC-1 English Home at the base path", async () => {
  const d = await read(`${BASE}/`);
  assert.equal(d.lang, "en");
  assert.equal(d.h1.length, 1);
  assert.ok(d.lede && d.lede.length > 10, "one lede sentence");
  assert.match(d.lede, /undone|can.?t be (undone|reversed)|irreversible/i, "the hook's meaning");
  assert.ok(d.mainLinks.includes(`${BASE}/reference/`), "link to Reference");
});

test("AC-2 Dutch Home mirrors English and is Dutch throughout", async () => {
  const en = await read(`${BASE}/`);
  const nl = await read(`${BASE}/nl/`);
  assert.equal(nl.lang, "nl");
  assert.equal(nl.h1.length, 1);
  assert.equal(nl.h2.length, en.h2.length);
  assert.ok(nl.h2.length >= 2);
  assert.deepEqual(nl.mainLinks.map((h) => h.replace(`${BASE}/nl/`, `${BASE}/`)), en.mainLinks.map((h) => h.replace(`${BASE}/nl/`, `${BASE}/`)), "same links in the same order (225: each Dutch link may point at the Dutch page)");
  assert.ok(nl.mainLinks.includes(`${BASE}/nl/reference/`), "225 AC-13: the Dutch Home Reference link goes to the Dutch Reference page");
  assert.notEqual(nl.lede, en.lede);
  for (let i = 0; i < en.h2.length; i++) assert.notEqual(nl.h2[i], en.h2[i], `h2 #${i} still English`);
  assert.equal(nl.mainParas.length, en.mainParas.length, "same sections, same paragraph count");
  for (let i = 0; i < en.mainParas.length; i++) assert.notEqual(nl.mainParas[i], en.mainParas[i], `paragraph #${i} not translated`);
  assert.ok(nl.title.length > 0);
});

test("AC-2 each Home declares the other as an alternate", async () => {
  const en = await read(`${BASE}/`);
  const nl = await read(`${BASE}/nl/`);
  assert.ok(en.alternates.some(([l, h]) => l === "nl" && h.endsWith(`${BASE}/nl/`)));
  assert.ok(nl.alternates.some(([l, h]) => l === "en" && h.endsWith(`${BASE}/`)));
});

test("AC-3 every internal reference starts with the base and resolves; an un-based request is 404", async () => {
  const refs = new Set();
  for (const route of ROUTES) {
    const page = await ctx.newPage();
    await page.goto(srv.origin + route);
    const hrefs = await page.evaluate(() =>
      [...document.querySelectorAll("[href],[src]")].map((e) => ({ tag: e.tagName, v: e.getAttribute("href") ?? e.getAttribute("src") })));
    await page.close();
    for (const { tag, v } of hrefs) {
      if (/^(https?:|mailto:|data:)/.test(v) || v.startsWith("#")) continue;
      assert.ok(v.startsWith(`${BASE}/`), `${route}: <${tag}> ${v} lacks the base path`);
      refs.add(v);
    }
  }
  assert.ok(refs.size >= 4);
  assert.ok([...refs].some((r) => r.endsWith(".css") || r.includes("/_astro/")), "a stylesheet reference exists");
  for (const r of refs) {
    const res = await fetch(srv.origin + r.split("#")[0]);
    assert.equal(res.status, 200, `${r} must resolve under the base`);
  }
  for (const bad of ["/", "/nl/", "/reference/", "/skills/", "/agents/", "/nl/agents/", "/getting-started/", "/nl/getting-started/"]) {
    assert.equal((await fetch(srv.origin + bad)).status, 404, `${bad} (no base) must not be served`);
  }
  // Served at the root instead: the based references no longer resolve, so the check above cannot pass by accident.
  const root = await serve(dist, "");
  try {
    let resolved = 0;
    for (const r of refs) if ((await fetch(root.origin + r.split("#")[0])).status === 200) resolved++;
    assert.equal(resolved, 0, "served at the root, no based reference may resolve");
  } finally { await root.close(); }
});

test("AC-3 the base is configurable: a build with SITE_BASE=/zz-qa prefixes every reference with it and never writes the literal base", async () => {
  const b = buildSite({ base: "/zz-qa" });
  assert.equal(b.status, 0, b.out.slice(-1500));
  for (const f of htmlFiles(b.dist)) {
    const html = fs.readFileSync(path.join(b.dist, f), "utf8");
    assert.ok(!/(?<!WimSuenens)\/agent-plugins\//.test(html), `${f} hard-codes /agent-plugins/`);
    const refs = [...html.matchAll(/\s(?:href|src)="([^"]+)"/g)].map((m) => m[1]).filter((v) => !/^(https?:|#|mailto:)/.test(v));
    assert.ok(refs.length > 0);
    for (const v of refs) assert.ok(v.startsWith("/zz-qa/"), `${f}: ${v}`);
  }
});

test("SITE_BASE without a leading slash or with a trailing slash is a build error naming the variable", () => {
  for (const bad of ["agent-plugins", "/agent-plugins/"]) {
    const b = buildSite({ base: bad });
    assert.notEqual(b.status, 0, `SITE_BASE=${bad} must fail`);
    assert.match(b.out, /SITE_BASE/);
  }
});

test("AC-4 (225) Home, Reference, Skills and Agents are translated: each has a Dutch twin and its switcher goes there; an English-only page (fixture, pages.test) still sends Dutch to Dutch Home", async () => {
  for (const slug of ["reference", "skills", "agents"]) {
    const en = await read(`${BASE}/${slug}/`);
    assert.equal(en.lang, "en");
    assert.ok(fs.existsSync(path.join(dist, "nl", slug, "index.html")), `nl/${slug} is built`);
    assert.equal((await fetch(`${srv.origin}${BASE}/nl/${slug}/`)).status, 200);
    assert.equal(en.switcher.find((s) => s.dataLang === "nl").href, `${BASE}/nl/${slug}/`);
    const nl = await read(`${BASE}/nl/${slug}/`);
    assert.equal(nl.lang, "nl");
    assert.equal(nl.switcher.find((s) => s.dataLang === "en").href, `${BASE}/${slug}/`);
  }
});

test("AC-5 every page: switcher in the top bar, two real links, own-language labels, current marked, works without script; hrefs follow the counterpart rule (188 AC-14, AC-15)", async () => {
  const o = oracle(await loadEntries());
  for (const route of ROUTES) {
    const d = await read(route);
    const here = o.pages.find((p) => p.route === route);
    assert.ok(d.switcherInTopbar, `${route}: switcher inside header[data-test=topbar]`);
    assert.equal(d.switcher.length, 2, route);
    const [en, nl] = d.switcher;
    const wantEn = here.lang === "en" ? route : o.exists(here.slug, "en") ? o.href(here.slug, "en") : o.home("en");
    const wantNl = here.lang === "nl" ? route : o.exists(here.slug, "nl") ? o.href(here.slug, "nl") : o.home("nl");
    assert.deepEqual([en.text, en.href, en.hreflang, en.lang, en.dataLang], ["English", wantEn, "en", "en", "en"], route);
    assert.deepEqual([nl.text, nl.href, nl.hreflang, nl.lang, nl.dataLang], ["Nederlands", wantNl, "nl", "nl", "nl"], route);
    const wantCurrent = here.lang;
    for (const s of d.switcher) {
      if (s.dataLang === wantCurrent) assert.equal(s.current, "true", `${route}: ${s.text} current`);
      else assert.equal(s.current, null, `${route}: ${s.text} must not be current`);
    }
    assert.equal(d.switcherNav, here.lang === "nl" ? "Taal" : "Language");
  }
});

test("AC-12 exactly one inline head script per page, short, no framework, no script files", async () => {
  for (const route of ROUTES) {
    const d = await read(route);
    assert.equal(d.scripts.length, 1, `${route}: scripts ${JSON.stringify(d.scripts)}`);
    assert.equal(d.scripts[0].src, null);
    assert.ok(d.scripts[0].inHead);
    assert.ok(d.scripts[0].len > 20 && d.scripts[0].len < 1500, `script length ${d.scripts[0].len}`);
  }
  assert.deepEqual(allFiles(dist).filter((f) => /\.(m?js|ts)$/.test(f)), [], "no script file in the output");
  for (const f of htmlFiles(dist)) assert.ok(!/astro-island|<script[^>]+src=/.test(fs.readFileSync(path.join(dist, f), "utf8")), f);
});

test("AC-12 scripts disabled: all content and working links remain", async () => {
  for (const route of ROUTES) {
    const d = await read(route);
    assert.ok(d.h1.length === 1 && d.mainText.length > 80, route);
  }
  const page = await ctx.newPage();
  await page.goto(`${srv.origin}${BASE}/`);
  await page.click("nav[data-lang-switcher] a[data-lang=nl]");
  assert.equal(new URL(page.url()).pathname, `${BASE}/nl/`);
  await page.close();
});
