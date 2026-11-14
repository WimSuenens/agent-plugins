// AC-6 to AC-11 (156) and AC-14, AC-15, AC-17 (188): remembered language switcher in a real browser. Storage key `site-lang` (contract 156-site-skeleton s5).
import { test, before, after, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BASE, ROUTES, realBuild, serve, launch, htmlFiles } from "./lib.mjs";

const KEY = "site-lang";
let dist, srv, browser, ctx, page, navs;
before(async () => { dist = realBuild(); srv = await serve(dist); browser = await launch(); });
after(async () => { await browser?.close(); await srv?.close(); });
beforeEach(async () => {
  ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  page = await ctx.newPage();
  navs = [];
  page.on("framenavigated", (f) => { if (f === page.mainFrame()) navs.push(new URL(f.url()).pathname); });
});
afterEach(async () => { await ctx.close(); });

const go = (p) => page.goto(srv.origin + p);
const stored = () => page.evaluate((k) => localStorage.getItem(k), KEY);
const setStored = (v) => page.evaluate(([k, v]) => localStorage.setItem(k, v), [KEY, v]);
const pathname = () => new URL(page.url()).pathname;
const settle = () => page.waitForTimeout(600);

test("AC-6 first visit: English, no redirect, nothing stored", async () => {
  await go(`${BASE}/`);
  await settle();
  assert.equal(pathname(), `${BASE}/`);
  assert.equal(await page.evaluate(() => document.documentElement.lang), "en");
  assert.equal(navs.length, 1, `navigations: ${navs}`);
  assert.equal(await stored(), null);
  assert.equal(await page.evaluate(() => localStorage.length), 0, "nothing at all stored on load");
});

test("AC-6 a Dutch first visit directly at /nl/ stores nothing either", async () => {
  await go(`${BASE}/nl/`);
  await settle();
  assert.equal(await page.evaluate(() => localStorage.length), 0);
});

test("AC-7 choosing Dutch stores nl and lands on /nl/; choosing English stores en and lands on the root", async () => {
  await go(`${BASE}/`);
  await page.click("nav[data-lang-switcher] a[data-lang=nl]");
  await page.waitForURL(`**${BASE}/nl/`);
  await settle();
  assert.equal(pathname(), `${BASE}/nl/`);
  assert.equal(await stored(), "nl");
  await page.click("nav[data-lang-switcher] a[data-lang=en]");
  await page.waitForURL((u) => u.pathname === `${BASE}/`);
  await settle();
  assert.equal(pathname(), `${BASE}/`, "explicit English choice is not sent back to Dutch");
  assert.equal(await stored(), "en");
});

test("AC-7 the choice made with the keyboard (Enter) is stored too", async () => {
  await go(`${BASE}/`);
  await page.focus("nav[data-lang-switcher] a[data-lang=nl]");
  await page.keyboard.press("Enter");
  await page.waitForURL(`**${BASE}/nl/`);
  assert.equal(await stored(), "nl");
});

test("AC-4 (225) Dutch chosen on a Reference section page lands on its Dutch counterpart and is stored; no page in the section is English-only", async () => {
  for (const slug of ["reference", "skills", "agents"]) {
    await go(`${BASE}/${slug}/`);
    await page.click("nav[data-lang-switcher] a[data-lang=nl]");
    await page.waitForURL(`**${BASE}/nl/${slug}/`);
    assert.equal(await stored(), "nl", slug);
    await page.evaluate(() => localStorage.clear());
  }
});

test("AC-8 returning visitor with nl: ends on /nl/, at most 2 navigations, history entry replaced", async () => {
  await go(`${BASE}/reference/`);
  await setStored("nl");
  navs.length = 0;
  await go(`${BASE}/`);
  await page.waitForURL(`**${BASE}/nl/`);
  await settle();
  assert.equal(pathname(), `${BASE}/nl/`);
  assert.ok(navs.length <= 2, `navigations from request to final page: ${navs}`);
  assert.equal(await page.evaluate(() => document.documentElement.lang), "nl");
  await page.goBack();
  await settle();
  assert.equal(pathname(), `${BASE}/reference/`, "Back goes to the previous page, never to the English root");
});

test("AC-8 returning visitor with nl as the very first page: Back leaves the site, no root/nl loop", async () => {
  const seed = await ctx.newPage();
  await seed.goto(srv.origin + `${BASE}/reference/`);
  await seed.evaluate(([k]) => localStorage.setItem(k, "nl"), [KEY]);
  await seed.close();
  await page.goto("about:blank");
  await go(`${BASE}/`);
  await page.waitForURL(`**${BASE}/nl/`);
  await page.goBack();
  await settle();
  assert.equal(page.url(), "about:blank");
});

test("AC-8 stored en: a direct link to /nl/ stays Dutch", async () => {
  await go(`${BASE}/reference/`);
  await setStored("en");
  await go(`${BASE}/nl/`);
  await settle();
  assert.equal(pathname(), `${BASE}/nl/`);
  assert.equal(await page.evaluate(() => document.documentElement.lang), "nl");
});

test("AC-8 stored nl: a direct link to /nl/ stays too (no loop)", async () => {
  await go(`${BASE}/reference/`);
  await setStored("nl");
  navs.length = 0;
  await go(`${BASE}/nl/`);
  await settle();
  assert.equal(pathname(), `${BASE}/nl/`);
  assert.equal(navs.length, 1);
});

test("AC-8 stored nl, visitor chooses English: stays on English Home, stored value becomes en", async () => {
  await go(`${BASE}/reference/`);
  await setStored("nl");
  await go(`${BASE}/nl/`);
  await page.click("nav[data-lang-switcher] a[data-lang=en]");
  await page.waitForURL((u) => u.pathname === `${BASE}/`);
  await settle();
  assert.equal(pathname(), `${BASE}/`);
  assert.equal(await stored(), "en");
  // and a later fresh load of the root stays English
  await go(`${BASE}/`);
  await settle();
  assert.equal(pathname(), `${BASE}/`);
});

test("AC-8 an invalid stored value is treated as absent", async () => {
  await go(`${BASE}/reference/`);
  for (const v of ["fr", "", "NL", "nl ", "true"]) {
    await setStored(v);
    await go(`${BASE}/`);
    await settle();
    assert.equal(pathname(), `${BASE}/`, `stored ${JSON.stringify(v)}`);
  }
});

test("AC-8 a storage error (private mode) is swallowed: the page still renders and the switcher works", async () => {
  await ctx.addInitScript(() => {
    const boom = () => { throw new DOMException("denied", "SecurityError"); };
    Object.defineProperty(window, "localStorage", { get: boom, configurable: true });
  });
  const errors = [];
  page.on("pageerror", (e) => errors.push(String(e)));
  await go(`${BASE}/`);
  await settle();
  assert.equal(pathname(), `${BASE}/`);
  await page.click("nav[data-lang-switcher] a[data-lang=nl]");
  await page.waitForURL(`**${BASE}/nl/`);
  assert.deepEqual(errors, [], "no uncaught error from the language script");
});

test("AC-9 stored nl: other pages are shown as requested, without a redirect", async () => {
  await go(`${BASE}/nl/`);
  await setStored("nl");
  navs.length = 0;
  await go(`${BASE}/reference/`);
  await settle();
  assert.equal(pathname(), `${BASE}/reference/`);
  assert.equal(navs.length, 1);
  assert.equal(await page.evaluate(() => document.documentElement.lang), "en");
});

test("AC-9 only the exact English Home path redirects: /agent-plugins/index.html style or query variants are not required to, and Reference with a hash stays", async () => {
  await go(`${BASE}/nl/`);
  await setStored("nl");
  await go(`${BASE}/reference/#factory`);
  await settle();
  assert.equal(pathname(), `${BASE}/reference/`);
});

test("AC-10 proxy: the script is inline in head before body; the body stays hidden while a Dutch return is pending", async () => {
  for (const f of htmlFiles(dist)) {
    const html = fs.readFileSync(path.join(dist, f), "utf8");
    const s = html.indexOf("<script");
    assert.ok(s > -1 && s < html.indexOf("<body"), `${f}: script before body`);
    assert.ok(s < html.indexOf("</head>"), `${f}: script in head`);
  }
  // Behaviour: hold the Dutch Home back and look at the English page while it is pending.
  await go(`${BASE}/reference/`);
  await setStored("nl");
  await page.route(`**${BASE}/nl/`, async (route) => { await new Promise((r) => setTimeout(r, 1500)); await route.continue(); });
  const nav = page.goto(srv.origin + `${BASE}/`, { waitUntil: "commit" }).catch(() => {});
  await page.waitForFunction(() => document.documentElement.hasAttribute("data-lang-pending") || location.pathname.endsWith("/nl/"), null, { timeout: 5000 });
  const seen = await page.evaluate(() => ({
    pending: document.documentElement.hasAttribute("data-lang-pending"),
    path: location.pathname,
    visibility: document.body ? getComputedStyle(document.body).visibility : "no-body",
  }));
  if (seen.path.endsWith("/")) {
    if (!seen.path.endsWith("/nl/")) {
      assert.equal(seen.pending, true, "html[data-lang-pending] set before the redirect");
      assert.ok(seen.visibility === "hidden" || seen.visibility === "no-body", `body visibility: ${seen.visibility}`);
    }
  }
  await nav;
  await page.waitForURL(`**${BASE}/nl/`);
});

test("AC-10 proxy: with no stored choice the root is visible at once", async () => {
  await go(`${BASE}/`);
  const v = await page.evaluate(() => [document.documentElement.hasAttribute("data-lang-pending"), getComputedStyle(document.body).visibility]);
  assert.deepEqual(v, [false, "visible"]);
});

for (const route of ROUTES) {
  test(`AC-11 320px wide, ${route}: no horizontal scroll, top bar items visible, inside the viewport, not overlapping`, async () => {
    await page.setViewportSize({ width: 320, height: 640 });
    await go(route);
    await settle();
    const m = await page.evaluate(() => {
      const items = [
        ...document.querySelectorAll("header[data-test=topbar] a"),
      ].map((a) => {
        const r = a.getBoundingClientRect();
        const cs = getComputedStyle(a);
        return { text: a.textContent.trim(), x: r.left, y: r.top, r: r.right, b: r.bottom, w: r.width, h: r.height,
          visible: cs.visibility === "visible" && cs.display !== "none", clipped: a.scrollWidth > a.clientWidth + 1 };
      });
      return { docW: document.documentElement.scrollWidth, bodyW: document.body.scrollWidth, vw: window.innerWidth, items };
    });
    assert.ok(m.docW <= m.vw && m.bodyW <= m.vw, `document ${m.docW}/${m.bodyW} wider than viewport ${m.vw}`);
    assert.ok(m.items.length >= 4, "site name, Reference and two switcher options");
    if (route.startsWith(`${BASE}/nl/`)) assert.ok(m.items.some((i) => i.text === "Naslag"), "Dutch pages show the Dutch label Naslag (225: Reference is translated)");
    for (const i of m.items) {
      assert.ok(i.visible && i.w > 0 && i.h > 0, `${i.text} visible`);
      assert.ok(i.x >= -0.5 && i.r <= m.vw + 0.5, `${i.text} inside the viewport (${i.x}..${i.r})`);
      assert.ok(!i.clipped, `${i.text} clipped`);
    }
    for (let a = 0; a < m.items.length; a++) for (let b = a + 1; b < m.items.length; b++) {
      const p = m.items[a], q = m.items[b];
      const overlap = p.x < q.r - 0.5 && q.x < p.r - 0.5 && p.y < q.b - 0.5 && q.y < p.b - 0.5;
      assert.ok(!overlap, `${p.text} overlaps ${q.text}`);
    }
  });
}

// ---------- 188: counterpart, Home fallback, direct links ----------
test("AC-14 Getting started: choosing the other language lands on the counterpart, stores the choice, and the marking follows", async () => {
  await go(`${BASE}/getting-started/`);
  await page.click("nav[data-lang-switcher] a[data-lang=nl]");
  await page.waitForURL(`**${BASE}/nl/getting-started/`);
  await settle();
  assert.equal(pathname(), `${BASE}/nl/getting-started/`);
  assert.equal(await stored(), "nl");
  assert.equal(await page.evaluate(() => document.documentElement.lang), "nl");
  assert.equal(await page.evaluate(() => document.querySelector("nav[data-lang-switcher] a[aria-current=true]").dataset.lang), "nl");
  await page.click("nav[data-lang-switcher] a[data-lang=en]");
  await page.waitForURL((u) => u.pathname === `${BASE}/getting-started/`);
  await settle();
  assert.equal(pathname(), `${BASE}/getting-started/`, "an explicit English choice stays English (no redirect back)");
  assert.equal(await stored(), "en");
  assert.equal(await page.evaluate(() => document.querySelector("nav[data-lang-switcher] a[aria-current=true]").dataset.lang), "en");
});

test("AC-14 Home and Getting started each lead to the counterpart with the keyboard too", async () => {
  await go(`${BASE}/nl/getting-started/`);
  await page.focus("nav[data-lang-switcher] a[data-lang=en]");
  await page.keyboard.press("Enter");
  await page.waitForURL((u) => u.pathname === `${BASE}/getting-started/`);
  assert.equal(await stored(), "en");
});

test("AC-15 / 225 AC-13 the Dutch Reference link is a real Dutch link, in the top bar and the tree; the switcher of every section page finds its counterpart, never a 404", async () => {
  for (const slug of ["reference", "skills", "agents"]) {
    await go(`${BASE}/${slug}/`);
    await page.click("nav[data-lang-switcher] a[data-lang=nl]");
    await page.waitForURL(`**${BASE}/nl/${slug}/`);
    assert.equal((await fetch(srv.origin + `${BASE}/nl/${slug}/`)).status, 200, `${slug}: the Dutch page exists`);
  }
  for (const nlRoute of [`${BASE}/nl/`, `${BASE}/nl/getting-started/`]) {
    await go(nlRoute);
    const links = await page.evaluate(() => [...document.querySelectorAll("header[data-test=topbar] a[href$='/reference/'], nav[data-nav=pages] a[href$='/reference/']")].map((a) => [a.textContent.trim(), a.getAttribute("href"), a.getAttribute("hreflang")]));
    assert.ok(links.length >= 2, `${nlRoute}: Reference in the top bar and in the tree`);
    for (const l of links) assert.deepEqual(l, ["Naslag", `${BASE}/nl/reference/`, null], `${nlRoute}: the Dutch Reference link is the Dutch page: no hreflang=en`);
  }
});

test("AC-17 stored nl: Getting started opened directly is shown as requested, with no redirect; the redirect stays at the English Home", async () => {
  await go(`${BASE}/nl/`);
  await setStored("nl");
  navs.length = 0;
  await go(`${BASE}/getting-started/`);
  await settle();
  assert.equal(pathname(), `${BASE}/getting-started/`);
  assert.equal(navs.length, 1, `navigations: ${navs}`);
  assert.equal(await page.evaluate(() => document.documentElement.lang), "en");
  navs.length = 0;
  await go(`${BASE}/`);
  await page.waitForURL(`**${BASE}/nl/`);
});

test("AC-17 a first visit to Getting started stores nothing and the page is English", async () => {
  await go(`${BASE}/getting-started/`);
  await settle();
  assert.equal(await page.evaluate(() => localStorage.length), 0);
  await go(`${BASE}/nl/getting-started/`);
  await settle();
  assert.equal(await page.evaluate(() => localStorage.length), 0);
  assert.equal(pathname(), `${BASE}/nl/getting-started/`);
});
