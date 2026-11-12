// AC-19 (machine part), AC-20, AC-21, AC-22, AC-23: look, contrast, keyboard, motion, semantics.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BASE, ROUTES, SITE, realBuild, serve, launch, allFiles, parseColor, blend, ratio, bgFromLayers, PAGE_HELPERS } from "./lib.mjs";

let dist, srv, browser;
before(async () => { dist = realBuild(); srv = await serve(dist); browser = await launch(); });
after(async () => { await browser?.close(); await srv?.close(); });

async function open(route, opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, ...opts });
  const page = await ctx.newPage();
  await page.goto(srv.origin + route);
  await page.evaluate(PAGE_HELPERS);
  return { ctx, page };
}

// ---------- AC-19 machine part ----------
const SRC = path.join(SITE, "src");
function srcFiles(dir = SRC) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? srcFiles(path.join(dir, e.name)) : [path.join(dir, e.name)]));
}
const NAMED = "aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgrey darkgreen darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray grey green greenyellow honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgrey lightgreen lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke yellow yellowgreen".split(" ");
function styleText(file) {
  const t = fs.readFileSync(file, "utf8");
  if (file.endsWith(".css")) return [t];
  const blocks = [...t.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)].map((m) => m[1]);
  const inline = [...t.matchAll(/\sstyle=(?:"([^"]*)"|'([^']*)')/g)].map((m) => m[1] ?? m[2]);
  const setVars = [...t.matchAll(/define:vars=\{[^}]*\}/g)].map((m) => m[0]);
  return [...blocks, ...inline, ...setVars];
}
function colourLiterals(css) {
  const c = css.replace(/\/\*[\s\S]*?\*\//g, "").replace(/var\([^)]*\)/g, "var()");
  const hits = [];
  for (const m of c.matchAll(/#[0-9a-fA-F]{3,8}\b/g)) hits.push(m[0]);
  for (const m of c.matchAll(/\b(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch|color|color-mix)\(/g)) hits.push(m[0]);
  for (const m of c.matchAll(/[\w-]+\s*:\s*([^;{}]+)/g)) {
    for (const w of m[1].toLowerCase().split(/[^a-z]+/)) if (NAMED.includes(w)) hits.push(w);
  }
  return hits;
}

test("AC-19 tokens: :root custom properties for colour, font, size, space and measure", () => {
  const f = path.join(SRC, "styles/tokens.css");
  const css = fs.readFileSync(f, "utf8");
  assert.match(css, /:root\s*\{/);
  for (const p of ["--color-", "--font-", "--size-", "--space-", "--measure"]) assert.ok(css.includes(p), `tokens.css defines ${p}*`);
  assert.match(css, /--measure\s*:\s*(6\d|7\d)ch/, "reading column of about 70 characters");
  assert.match(css, /color-scheme\s*:\s*light/);
});

test("AC-19 no colour literal under apps/site/src outside tokens.css (transparent, currentColor, inherit allowed)", () => {
  const offenders = [];
  for (const f of srcFiles().filter((x) => /\.(css|astro|mjs|ts|jsx?)$/.test(x))) {
    if (f.endsWith(path.join("styles", "tokens.css"))) continue;
    for (const css of styleText(f)) for (const h of colourLiterals(css)) offenders.push(`${path.relative(SITE, f)}: ${h}`);
    if (/\.(mjs|ts|jsx?)$/.test(f)) {
      const t = fs.readFileSync(f, "utf8");
      for (const m of t.matchAll(/["'`](#[0-9a-fA-F]{3,8}|(?:rgba?|hsla?)\([^)]*\))["'`]/g)) offenders.push(`${path.relative(SITE, f)}: ${m[1]}`);
    }
  }
  assert.deepEqual(offenders, []);
});

test("AC-19 rendered: serif headings, one reading column capped by the measure, rules (border-top) between sections, no boxes", async () => {
  for (const route of ROUTES) {
    const { ctx, page } = await open(route);
    const m = await page.evaluate(() => {
      const cs = (e) => getComputedStyle(e);
      const h2 = document.querySelector("main h2");
      const main = document.querySelector("main");
      const col = [...document.querySelectorAll("main p")].map((p) => p.getBoundingClientRect().width);
      const fs0 = parseFloat(cs(document.querySelector("main p")).fontSize);
      return {
        h1: cs(document.querySelector("h1")).fontFamily,
        body: cs(document.body).fontFamily,
        h2Border: h2 ? [cs(h2).borderTopStyle, cs(h2).borderTopWidth] : null,
        sectionBorder: [...document.querySelectorAll("main section")].some((s) => cs(s).borderTopStyle !== "none" && parseFloat(cs(s).borderTopWidth) > 0),
        maxPara: Math.max(...col), fs0,
        cards: [...document.querySelectorAll("main article, main section")].filter((e) => cs(e).boxShadow !== "none" || parseFloat(cs(e).borderTopLeftRadius) > 0 || (cs(e).borderLeftStyle !== "none" && parseFloat(cs(e).borderLeftWidth) > 0 && cs(e).borderRightStyle !== "none" && parseFloat(cs(e).borderRightWidth) > 0)).length,
        scheme: cs(document.documentElement).colorScheme,
      };
    });
    await ctx.close();
    assert.match(m.h1, /serif|Georgia|Charter|Iowan/i, `${route} heading font ${m.h1}`);
    assert.match(m.body, /serif|Georgia|Charter|Iowan/i, `${route} body font ${m.body}`);
    assert.ok(m.h2Border ? m.h2Border[0] !== "none" && parseFloat(m.h2Border[1]) > 0 || m.sectionBorder : m.sectionBorder, `${route} sections separated by rules`);
    assert.ok(m.maxPara / (m.fs0 * 0.5) <= 95, `${route} one reading column: ${m.maxPara}px at ${m.fs0}px font`);
    assert.equal(m.cards, 0, `${route} no boxes or cards`);
  }
});

test("AC-19 no font file in the output (no font request)", () => {
  assert.deepEqual(allFiles(dist).filter((f) => /\.(woff2?|ttf|otf|eot)$/.test(f)), []);
});

// ---------- AC-20 contrast on the rendered pages ----------
const COLLECT_TEXT = `() => {
  const out = [];
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const seen = new Set();
  for (let n = walker.nextNode(); n; n = walker.nextNode()) {
    if (!n.textContent.trim()) continue;
    const el = n.parentElement;
    if (seen.has(el)) continue;
    seen.add(el);
    const cs = getComputedStyle(el);
    if (cs.visibility === 'hidden' || cs.display === 'none') continue;
    const r = el.getBoundingClientRect();
    out.push({ sel: el.tagName.toLowerCase() + (el.className ? '.' + String(el.className).split(' ')[0] : ''), color: cs.color, opacity: cs.opacity, layers: window.__bg(el), w: r.width, h: r.height, text: el.textContent.trim().slice(0, 30) });
  }
  return out;
}`;
function textRatio(t) {
  const bg = bgFromLayers(t.layers);
  const fg = blend(parseColor(t.color), bg);
  return ratio(fg, bg);
}

test("AC-20 every rendered text/background pair is at least 4.5:1 (normal, hover, focus states included)", async () => {
  const fails = [];
  let pairs = 0;
  for (const route of ROUTES) {
    const { ctx, page } = await open(route);
    const check = async (state) => {
      for (const t of await page.evaluate(`(${COLLECT_TEXT})()`)) {
        if (t.w === 0 && t.h === 0) continue;
        pairs++;
        const r = textRatio(t);
        if (r < 4.5) fails.push(`${route} [${state}] ${t.sel} "${t.text}" ${r.toFixed(2)}`);
      }
    };
    await check("normal");
    for (const sel of ["header[data-test=topbar] a", "nav[data-lang-switcher] a", "main a"]) {
      for (const h of await page.locator(sel).all()) {
        if (!(await h.isVisible())) continue;
        await h.hover();
        await check(`hover ${sel}`);
      }
    }
    await page.mouse.move(0, 0);
    await page.keyboard.press("Tab"); // skip link takes focus and becomes visible
    await check("skip link focused");
    await ctx.close();
  }
  assert.ok(pairs > 20, `only ${pairs} pairs inspected`);
  assert.deepEqual(fails, []);
});

test("AC-20 interface parts: focus ring and a visible switcher border are at least 3:1 against their neighbour", async () => {
  const fails = [];
  for (const route of ROUTES) {
    const { ctx, page } = await open(route);
    const focusables = await page.locator("a[href], button").count();
    for (let i = 0; i < focusables; i++) {
      await page.keyboard.press("Tab");
      const f = await page.evaluate(() => {
        const e = document.activeElement, cs = getComputedStyle(e);
        return { tag: e.tagName, text: e.textContent.trim().slice(0, 25), outline: cs.outlineStyle, ow: parseFloat(cs.outlineWidth), oc: cs.outlineColor, layers: window.__bg(e.parentElement ?? e) };
      });
      if (f.outline === "none" || !(f.ow > 0)) { fails.push(`${route} "${f.text}" no outline`); continue; }
      const bg = bgFromLayers(f.layers);
      const r = ratio(blend(parseColor(f.oc), bg), bg);
      if (r < 3) fails.push(`${route} "${f.text}" focus ring ${r.toFixed(2)}`);
    }
    const borders = await page.evaluate(() => [...document.querySelectorAll("nav[data-lang-switcher], nav[data-lang-switcher] a")].map((e) => {
      const cs = getComputedStyle(e);
      return { style: cs.borderTopStyle, w: parseFloat(cs.borderTopWidth), c: cs.borderTopColor, layers: window.__bg(e.parentElement) };
    }).filter((b) => b.style !== "none" && b.w > 0));
    for (const b of borders) {
      const bg = bgFromLayers(b.layers);
      const r = ratio(blend(parseColor(b.c), bg), bg);
      if (r < 3) fails.push(`${route} switcher border ${r.toFixed(2)}`);
    }
    await ctx.close();
  }
  assert.deepEqual(fails, []);
});

// ---------- AC-21 keyboard ----------
for (const route of ROUTES) {
  test(`AC-21 keyboard on ${route}: skip link first, all controls reachable in DOM order, no trap`, async () => {
    const { ctx, page } = await open(route);
    const expected = await page.evaluate(() =>
      [...document.querySelectorAll("a[href], button, input, select, textarea, [tabindex]")].filter((e) => e.tabIndex >= 0 && getComputedStyle(e).display !== "none")
        .map((e) => (e.getAttribute("href") ?? "") + "|" + e.textContent.trim().slice(0, 20)));
    await page.keyboard.press("Tab");
    const first = await page.evaluate(() => {
      const e = document.activeElement, r = e.getBoundingClientRect(), cs = getComputedStyle(e);
      return { cls: e.className, href: e.getAttribute("href"), text: e.textContent.trim(), inView: r.width > 0 && r.height > 0 && r.top >= 0 && r.left >= 0 && r.bottom <= innerHeight && r.right <= innerWidth, vis: cs.visibility, op: cs.opacity };
    });
    assert.match(String(first.cls), /skip-link/);
    assert.equal(first.href, "#main");
    assert.match(first.text, /^(Skip to content|Naar de inhoud)$/);
    assert.ok(first.inView && first.vis === "visible" && first.op !== "0", "skip link visible when focused");
    await page.keyboard.press("Enter");
    assert.equal(await page.evaluate(() => document.activeElement.id), "main", "activating the skip link moves focus to main");
    // reload and walk the whole order
    await page.goto(srv.origin + route);
    const seen = [];
    for (let i = 0; i < expected.length; i++) {
      await page.keyboard.press("Tab");
      const f = await page.evaluate(() => {
        const e = document.activeElement, cs = getComputedStyle(e);
        return { id: (e.getAttribute("href") ?? "") + "|" + e.textContent.trim().slice(0, 20), outline: cs.outlineStyle, ow: parseFloat(cs.outlineWidth) };
      });
      assert.ok(f.outline !== "none" && f.ow > 0, `${f.id}: visible focus indicator`);
      seen.push(f.id);
    }
    assert.deepEqual(seen.filter((s) => expected.includes(s)), expected.filter((s) => seen.includes(s)), "logical (DOM) order");
    assert.deepEqual(new Set(seen), new Set(expected), "every link and both switcher options are reachable (no trap before the last)");
    const sw = ["English", "Nederlands"].map((t) => seen.findIndex((s) => s.endsWith("|" + t)));
    const navLink = seen.findIndex((s) => s.includes(`${BASE}/reference/|`));
    assert.ok(sw.every((i) => i >= 0) && navLink >= 0 && sw[0] > navLink && sw[1] > sw[0], "switcher after the main nav");
    await ctx.close();
  });
}

// ---------- AC-22 reduced motion ----------
const MOTION = () => [...document.querySelectorAll("*")].map((e) => {
  const cs = getComputedStyle(e);
  return { sel: e.tagName, td: cs.transitionDuration, ad: cs.animationDuration, an: cs.animationName, sb: cs.scrollBehavior };
});
const secs = (v) => v.split(",").map((x) => (x.trim().endsWith("ms") ? parseFloat(x) / 1000 : parseFloat(x)));

for (const route of ROUTES) {
  test(`AC-22 ${route}: reduce gives no transition, animation or smooth scroll`, async () => {
    const { ctx, page } = await open(route, { reducedMotion: "reduce" });
    for (const m of await page.evaluate(MOTION)) {
      assert.ok(secs(m.td).every((s) => s === 0), `${m.sel} transition-duration ${m.td}`);
      assert.ok(m.an === "none" || secs(m.ad).every((s) => s === 0), `${m.sel} animation ${m.an} ${m.ad}`);
      assert.notEqual(m.sb, "smooth");
    }
    await ctx.close();
  });
  test(`AC-22 ${route}: with no preference, any motion is short and never smooth scrolling`, async () => {
    const { ctx, page } = await open(route, { reducedMotion: "no-preference" });
    for (const m of await page.evaluate(MOTION)) {
      assert.ok(secs(m.td).every((s) => s <= 0.3), `${m.sel} transition-duration ${m.td}`);
      assert.ok(m.an === "none" || secs(m.ad).every((s) => s <= 0.3), `${m.sel} animation ${m.ad}`);
      assert.notEqual(m.sb, "smooth", "smooth scroll runs only under a guard, and never for reduce");
    }
    await ctx.close();
  });
}

test("AC-22 source: motion properties appear only inside a prefers-reduced-motion: no-preference block", () => {
  const files = allFiles(dist).filter((f) => f.endsWith(".css")).map((f) => path.join(dist, f));
  for (const f of files) {
    const css = fs.readFileSync(f, "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
    const re = /(^|[;{}\s])(transition|animation|animation-name|scroll-behavior)\s*:\s*([^;}]+)/g;
    for (const m of css.matchAll(re)) {
      if (/^(none|auto|0s?|0ms|initial|unset)\b/.test(m[3].trim())) continue;
      // walk the braces before the match; require an open @media (prefers-reduced-motion: no-preference)
      let depth = 0; const stack = [];
      const head = css.slice(0, m.index);
      for (let i = 0, last = 0; i < head.length; i++) {
        if (head[i] === "{") { stack.push(head.slice(last, i)); last = i + 1; }
        else if (head[i] === "}") { stack.pop(); last = i + 1; }
        else if (head[i] === ";") last = i + 1;
      }
      assert.ok(stack.some((s) => /prefers-reduced-motion\s*:\s*no-preference/.test(s)), `${path.basename(f)}: unguarded ${m[2]}: ${m[3].trim()}`);
    }
  }
});

// ---------- AC-23 semantics ----------
test("AC-23 every page: lang, unique title, one h1, one main, labelled nav, no skipped heading, real controls", async () => {
  const titles = [];
  for (const route of ROUTES) {
    const { ctx, page } = await open(route);
    const d = await page.evaluate(() => ({
      lang: document.documentElement.lang, title: document.title,
      h1: document.querySelectorAll("h1").length, mains: document.querySelectorAll("main, [role=main]").length,
      levels: [...document.querySelectorAll("h1,h2,h3,h4,h5,h6")].map((h) => Number(h.tagName[1])),
      navs: [...document.querySelectorAll("nav")].map((n) => n.getAttribute("aria-label") ?? n.getAttribute("aria-labelledby")),
      topNav: document.querySelector("header nav")?.getAttribute("aria-label"),
      click: document.querySelectorAll("[onclick]").length,
      fakeButtons: [...document.querySelectorAll("[role=button],[role=link]")].filter((e) => !["A", "BUTTON"].includes(e.tagName)).length,
      imgNoAlt: [...document.querySelectorAll("img")].filter((i) => !i.hasAttribute("alt")).length,
      order: [...document.body.children].map((c) => c.tagName.toLowerCase()),
      skipFirst: document.querySelector("a.skip-link") === document.body.querySelector("a, button, input"),
      mainTabindex: document.querySelector("main")?.getAttribute("tabindex"), mainId: document.querySelector("main")?.id,
      sw: [...document.querySelectorAll("nav[data-lang-switcher] a")].map((a) => [a.textContent.trim(), a.getAttribute("hreflang"), a.getAttribute("lang")]),
    }));
    await ctx.close();
    assert.ok(["en", "nl"].includes(d.lang), route);
    assert.ok(d.title.length > 0); titles.push(d.title);
    assert.equal(d.h1, 1, route);
    assert.equal(d.mains, 1, route);
    assert.equal(d.levels[0], 1);
    for (let i = 1; i < d.levels.length; i++) assert.ok(d.levels[i] - d.levels[i - 1] <= 1, `${route}: heading jumps ${d.levels.join(",")}`);
    assert.ok(d.navs.length >= 2 && d.navs.every(Boolean), `${route}: every nav labelled ${JSON.stringify(d.navs)}`);
    assert.ok(d.topNav, `${route}: top bar nav labelled`);
    assert.equal(d.click, 0);
    assert.equal(d.fakeButtons, 0);
    assert.equal(d.imgNoAlt, 0);
    assert.ok(d.skipFirst, "skip link is the first focusable");
    assert.equal(d.mainTabindex, "-1"); assert.equal(d.mainId, "main");
    assert.deepEqual(d.order.filter((t) => ["a", "header", "main", "footer"].includes(t)), ["a", "header", "main", "footer"], `${route}: body order skip link, header, main, footer`);
    assert.deepEqual(d.sw, [["English", "en", "en"], ["Nederlands", "nl", "nl"]]);
  }
  assert.equal(new Set(titles).size, titles.length, "titles are unique");
});
