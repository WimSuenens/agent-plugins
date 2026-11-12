// Slice 188, sections B, C and F on the real build: navigation tree (AC-5 to AC-9), breadcrumb (AC-10), contents (AC-11),
// see-also (AC-13), draft notice (AC-21), the single reading column and the source order (AC-25), code blocks (AC-23), AC-24 parts.
// The per-page agreement with the page tree (labels, links, nesting, current, breadcrumb, contents, see-also, switcher) is
// checked for every page in pages.test.mjs through oracle.checkPage; this file adds the behaviour in a browser.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { BASE, ROUTES, realBuild, htmlFiles, routeOf, serve, launch, readPage, parseColor, blend, ratio, bgFromLayers, PAGE_HELPERS } from "./lib.mjs";
import { loadEntries, oracle, checkPage, pageOfRoute } from "./oracle.mjs";

let dist, srv, browser, o;
before(async () => { dist = realBuild(); srv = await serve(dist); browser = await launch(); o = oracle(await loadEntries()); });
after(async () => { await browser?.close(); await srv?.close(); });

const routes = () => htmlFiles(dist).map((f) => routeOf(f));
async function open(route, opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, ...opts });
  const page = await ctx.newPage();
  await page.goto(srv.origin + route);
  await page.evaluate(PAGE_HELPERS);
  return { ctx, page };
}

test("the routes the browser tests walk are the pages of the build (computed), and include the five pages of the requirement", () => {
  assert.deepEqual(routes().sort(), [...ROUTES].sort());
});

// ---------- AC-9 ----------
test("AC-9 each nav has its own name in the page's language: the Dutch names differ from the English ones, hooks are the six stable data-nav values", async () => {
  const ctx = await browser.newContext();
  try {
    const en = await readPage(ctx, srv.origin, `${BASE}/getting-started/`);
    const nl = await readPage(ctx, srv.origin, `${BASE}/nl/getting-started/`);
    const names = (d) => Object.fromEntries(d.navs.map((n) => [n.hook, n.name]));
    const [a, b] = [names(en), names(nl)];
    assert.deepEqual(Object.keys(a).sort(), ["breadcrumb", "contents", "language", "pages", "see-also", "site"]);
    assert.deepEqual(Object.keys(b).sort(), Object.keys(a).sort());
    for (const k of Object.keys(a)) assert.notEqual(a[k].toLowerCase(), b[k].toLowerCase(), `${k}: the Dutch name must be Dutch`);
    // The names that 156 fixed stay: English "Language"; the contents list is "On this page" (reference.test relies on it)
    assert.equal(a.language, "Language");
    assert.equal(a.contents, "On this page");
    assert.equal(a.breadcrumb, "Breadcrumb");
  } finally { await ctx.close(); }
});

// ---------- AC-6: marked by more than colour (AC-24) ----------
test("AC-6 / AC-24 the current tree entry differs from the others by more than colour", async () => {
  for (const route of routes()) {
    const { ctx, page } = await open(route);
    const m = await page.evaluate(() => {
      const st = (a) => {
        const cs = getComputedStyle(a), b = getComputedStyle(a, "::before"), af = getComputedStyle(a, "::after");
        const li = getComputedStyle(a.closest("li"));
        return [cs.fontWeight, cs.textDecorationLine, cs.textDecorationStyle, cs.fontStyle, cs.borderTopWidth, cs.borderBottomWidth, cs.borderLeftWidth, cs.boxShadow, cs.outlineStyle, b.content, af.content, li.borderLeftWidth].join("|");
      };
      const cur = document.querySelector('nav[data-nav=pages] a[aria-current=page]');
      const others = [...document.querySelectorAll('nav[data-nav=pages] a:not([aria-current])')];
      return { cur: st(cur), others: others.map(st), links: others.length };
    });
    await ctx.close();
    assert.ok(m.links >= 1);
    assert.ok(m.others.some((x) => x !== m.cur), `${route}: current entry is distinguished by weight, rule, underline or marker, not by colour alone`);
  }
});

// ---------- AC-7: keyboard, no script ----------
for (const route of ["/getting-started/", "/nl/getting-started/", "/reference/"].map((r) => BASE + r)) {
  test(`AC-7 ${route}: with scripts off every tree entry is reachable by Tab in reading order, shows a focus indicator, Enter follows it, no trap`, async () => {
    const { ctx, page } = await open(route, { javaScriptEnabled: false });
    const want = await page.evaluate(() => [...document.querySelectorAll("nav[data-nav=pages] a")].map((a) => a.getAttribute("href")));
    const focusables = await page.evaluate(() => [...document.querySelectorAll("a[href], button, [tabindex]")].filter((e) => e.tabIndex >= 0).length);
    const seen = [], outlines = [];
    for (let i = 0; i < focusables + 2; i++) {
      await page.keyboard.press("Tab");
      const f = await page.evaluate(() => {
        const e = document.activeElement, cs = getComputedStyle(e);
        return { inTree: !!e.closest("nav[data-nav=pages]"), href: e.getAttribute("href"), ow: parseFloat(cs.outlineWidth), os: cs.outlineStyle };
      });
      if (f.inTree) { seen.push(f.href); outlines.push(f.os !== "none" && f.ow > 0); }
    }
    assert.deepEqual(seen, want, "every tree entry, once, in tree (reading) order");
    assert.ok(outlines.every(Boolean), "visible focus indicator on every entry");
    const target = want.find((h) => h !== route) ?? want[0];
    await page.focus(`nav[data-nav=pages] a[href="${target}"]`);
    await page.keyboard.press("Enter");
    await page.waitForURL((u) => u.pathname === target);
    await ctx.close();
  });
}

test("AC-7 the tree adds no client script: still one inline script per page, no script file, no details/summary, no tabindex on the tree", async () => {
  for (const route of routes()) {
    const { ctx, page } = await open(route);
    const m = await page.evaluate(() => ({ scripts: document.querySelectorAll("script").length, details: document.querySelectorAll("details, summary").length, tab: document.querySelectorAll("nav[data-nav=pages] [tabindex], nav[data-nav=pages] button").length }));
    await ctx.close();
    assert.deepEqual(m, { scripts: 1, details: 0, tab: 0 }, route);
  }
});

// ---------- AC-8, AC-25: 320px and the column beside the reading column from 48rem ----------
for (const route of ROUTES) {
  test(`AC-8 / AC-25 320px ${route}: the tree is open in the flow above main, nothing clipped or overlapping, no horizontal scroll`, async () => {
    const { ctx, page } = await open(route, { viewport: { width: 320, height: 640 } });
    const m = await page.evaluate(() => {
      const links = [...document.querySelectorAll("nav[data-nav=pages] a")].map((a) => {
        const r = a.getBoundingClientRect(), cs = getComputedStyle(a);
        return { t: a.textContent.trim(), x: r.left, y: r.top, r: r.right, b: r.bottom, w: r.width, h: r.height, vis: cs.visibility === "visible" && cs.display !== "none", clipped: a.scrollWidth > a.clientWidth + 1 };
      });
      const tree = document.querySelector("nav[data-nav=pages]").getBoundingClientRect();
      const main = document.querySelector("main").getBoundingClientRect();
      return { links, treeBottom: tree.bottom, treeVisible: getComputedStyle(document.querySelector("nav[data-nav=pages]")).display !== "none", mainTop: main.top, docW: document.documentElement.scrollWidth, bodyW: document.body.scrollWidth, vw: innerWidth, details: document.querySelectorAll("details").length };
    });
    await ctx.close();
    assert.ok(m.docW <= m.vw && m.bodyW <= m.vw, `document ${m.docW}/${m.bodyW} wider than the viewport ${m.vw}`);
    assert.ok(m.treeVisible && m.details === 0, "always open, no details");
    assert.ok(m.treeBottom <= m.mainTop + 1, `below 48rem the tree sits above main (tree bottom ${m.treeBottom}, main top ${m.mainTop})`);
    assert.equal(m.links.length, o.tree(pageOfRoute(route).lang).length);
    for (const l of m.links) {
      assert.ok(l.vis && l.w > 0 && l.h > 0, `${l.t} visible`);
      assert.ok(l.x >= -0.5 && l.r <= m.vw + 0.5, `${l.t} inside the viewport (${l.x}..${l.r})`);
      assert.ok(!l.clipped, `${l.t} clipped`);
    }
    for (let i = 0; i < m.links.length; i++) for (let j = i + 1; j < m.links.length; j++) {
      const p = m.links[i], q = m.links[j];
      assert.ok(!(p.x < q.r - 0.5 && q.x < p.r - 0.5 && p.y < q.b - 0.5 && q.y < p.b - 0.5), `${p.t} overlaps ${q.t}`);
    }
  });
}

for (const [width, side] of [[768, true], [1280, true], [767, false]]) {
  test(`AC-25 at ${width}px the tree is ${side ? "a column beside" : "above"} the reading column (48rem = 768px)`, async () => {
    const { ctx, page } = await open(`${BASE}/getting-started/`, { viewport: { width, height: 900 } });
    const m = await page.evaluate(() => {
      const t = document.querySelector("nav[data-nav=pages]").getBoundingClientRect();
      const mn = document.querySelector("main").getBoundingClientRect();
      const p = document.querySelector("main p");
      return { t: { l: t.left, r: t.right, top: t.top, b: t.bottom }, m: { l: mn.left, r: mn.right, top: mn.top, b: mn.bottom }, para: p.getBoundingClientRect().width, fs: parseFloat(getComputedStyle(p).fontSize), docW: document.documentElement.scrollWidth, vw: innerWidth };
    });
    await ctx.close();
    assert.ok(m.docW <= m.vw);
    if (side) {
      assert.ok(m.t.r <= m.m.l + 1, `tree (right ${m.t.r}) left of main (left ${m.m.l})`);
      assert.ok(m.t.top < m.m.b && m.m.top < m.t.b, "side by side: the vertical ranges overlap");
    } else assert.ok(m.t.b <= m.m.top + 1, "stacked: tree above main");
    assert.ok(m.para / (m.fs * 0.5) <= 95, `one reading column of about 70 characters (${m.para}px at ${m.fs}px); the tree column is outside the measure`);
  });
}

test("AC-25 the skip link is the first focusable and, activated, puts focus on main so the next Tab is inside main (past the tree)", async () => {
  for (const route of routes()) {
    const { ctx, page } = await open(route);
    await page.keyboard.press("Tab");
    assert.equal(await page.evaluate(() => document.activeElement.className.includes("skip-link") && document.activeElement.getAttribute("href")), "#main", route);
    await page.keyboard.press("Enter");
    assert.equal(await page.evaluate(() => document.activeElement.id), "main", route);
    await page.keyboard.press("Tab");
    assert.ok(await page.evaluate(() => !!document.activeElement.closest("main") && document.activeElement.id !== "main"), `${route}: the next Tab is inside main, not back in the tree or top bar`);
    await ctx.close();
  }
});

test("AC-25 inside main the order is breadcrumb, draft notice, h1, contents, text, see-also", async () => {
  for (const route of routes()) {
    const { lang, slug } = pageOfRoute(route);
    const { ctx, page } = await open(route);
    const seq = await page.evaluate(() => [...document.querySelectorAll("main nav[data-nav=breadcrumb], main [data-draft-notice], main h1, main nav[data-nav=contents], main nav[data-nav=see-also]")].map((e) => e.matches("nav") ? e.dataset.nav : e.matches("h1") ? "h1" : "draft"));
    const body = await page.evaluate(() => { const m = document.querySelector("main"); const first = m.querySelector("h2"); const last = m.querySelector("nav[data-nav=see-also]"); return { h2After: !first || !!(m.querySelector("h1").compareDocumentPosition(first) & Node.DOCUMENT_POSITION_FOLLOWING), seeAfter: !last || [...m.querySelectorAll("h2,h3,p,pre,li")].filter((x) => !x.closest("nav")).every((x) => !!(x.compareDocumentPosition(last) & Node.DOCUMENT_POSITION_FOLLOWING)) }; });
    await ctx.close();
    const want = ["breadcrumb", ...(lang === "nl" && o.isDraft(slug) ? ["draft"] : []), "h1", ...(seq.includes("contents") ? ["contents"] : []), ...(o.seeAlso(slug, lang).length ? ["see-also"] : [])];
    assert.deepEqual(seq, want, route);
    assert.ok(body.h2After && body.seeAfter, `${route}: body between h1 and see-also`);
  }
});

// ---------- AC-13: Home and Getting started show see-also in both languages ----------
test("AC-13 Home and Getting started each show at least one see-also link in each language, all inside the page's language", async () => {
  const ctx = await browser.newContext();
  try {
    for (const route of routes().filter((r) => ["", "getting-started"].includes(pageOfRoute(r).slug))) {
      const d = await readPage(ctx, srv.origin, route);
      assert.ok(d.seeAlsoItems.length >= 1, `${route}: see-also`);
      for (const i of d.seeAlsoItems) assert.ok(i.a.href.startsWith(`${BASE}/nl/`) === (d.lang === "nl"), `${route}: ${i.a.href} stays in the language`);
    }
  } finally { await ctx.close(); }
});

// ---------- AC-21: the notice ----------
test("AC-21 the draft notice is a plain paragraph in Dutch before the h1, distinguished by a rule or border, not an alert", async () => {
  for (const route of routes().filter((r) => pageOfRoute(r).lang === "nl" && o.isDraft(pageOfRoute(r).slug))) {
    const { ctx, page } = await open(route);
    const m = await page.evaluate(() => {
      const n = document.querySelector("[data-draft-notice]"), cs = getComputedStyle(n);
      const lang = n.closest("[lang]")?.getAttribute("lang");
      return { tag: n.tagName, role: n.getAttribute("role"), text: n.textContent.trim(), lang, border: ["Top", "Bottom", "Left", "Right"].some((s) => cs[`border${s}Style`] !== "none" && parseFloat(cs[`border${s}Width`]) > 0), words: n.textContent.trim().split(/\s+/).length };
    });
    await ctx.close();
    assert.equal(m.tag, "P"); assert.notEqual(m.role, "alert"); assert.equal(m.lang, "nl");
    assert.ok(m.words >= 4 && m.words <= 40, "one short notice");
    assert.ok(/concept|vertaling|controle/i.test(m.text), `a Dutch draft notice: ${m.text}`);
    assert.ok(m.border, `${route}: distinguished by a rule or border`);
  }
});

// ---------- AC-23 on the real Getting started pages ----------
for (const route of [`${BASE}/getting-started/`, `${BASE}/nl/getting-started/`]) {
  test(`AC-23 320px ${route}: no horizontal scroll, every code block inside the viewport, focusable when it scrolls, text at least 4.5:1`, async () => {
    const { ctx, page } = await open(route, { viewport: { width: 320, height: 640 } });
    const m = await page.evaluate(() => {
      const pres = [...document.querySelectorAll("main pre")].map((p) => {
        const cs = getComputedStyle(p), code = p.querySelector("code") ?? p;
        p.focus();
        return { right: p.getBoundingClientRect().right, scrolls: p.scrollWidth > p.clientWidth, tab: p.getAttribute("tabindex"), focused: document.activeElement === p, ox: cs.overflowX, color: getComputedStyle(code).color, layers: window.__bg(code) };
      });
      return { pres, docW: document.documentElement.scrollWidth, vw: innerWidth };
    });
    await ctx.close();
    assert.ok(m.pres.length >= 4, "every step has a code block");
    assert.ok(m.docW <= m.vw, `document ${m.docW} wider than ${m.vw}`);
    for (const p of m.pres) {
      assert.ok(p.right <= m.vw + 0.5, "inside the viewport");
      assert.ok(p.tab === "0" || !p.scrolls, "a block that scrolls is focusable (tabindex=0)");
      if (p.scrolls) assert.ok(p.focused && ["auto", "scroll"].includes(p.ox));
      const bg = bgFromLayers(p.layers), r = ratio(blend(parseColor(p.color), bg), bg);
      assert.ok(r >= 4.5, `code text contrast ${r.toFixed(2)}`);
    }
  });
}

test("AC-22 / AC-24 no inline style attribute, no highlighter class and no layout element in the built content of Getting started and Reference", async () => {
  for (const route of [`${BASE}/getting-started/`, `${BASE}/nl/getting-started/`, `${BASE}/reference/`]) {
    const { ctx, page } = await open(route);
    const m = await page.evaluate(() => {
      const els = [...document.querySelectorAll("main *")].filter((e) => !e.closest("nav") && !e.closest("[data-draft-notice]"));
      return { styled: els.filter((e) => e.hasAttribute("style")).length, classed: els.filter((e) => e.hasAttribute("class")).map((e) => e.tagName + "." + e.className), divs: els.filter((e) => e.tagName === "DIV").length, anyStyle: document.querySelectorAll("main [style]").length };
    });
    await ctx.close();
    assert.equal(m.anyStyle, 0, `${route}: inline style in main`);
    assert.deepEqual([m.styled, m.classed, m.divs], [0, [], 0], `${route}`);
  }
});
