// Shared helpers for the site acceptance suite (slice 156). Run from the repo root:
//   (cd apps/site && npm ci && npx playwright install chromium) && node --test tests/site/
// Playwright and yaml come from apps/site/node_modules (devDependencies / dependencies of the site).
import { createRequire } from "node:module";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
export const REPO = path.resolve(here, "../..");
export const SITE = path.join(REPO, "apps/site");
export const PLUGINS = path.join(REPO, "plugins");
export const BASE = "/agent-plugins";

const req = createRequire(path.join(SITE, "package.json"));
export const loadPlaywright = () => req("playwright");
export const loadYaml = () => req("yaml");

export function scratch(prefix = "site-qa-") {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

// Astro keeps temp files in the shared apps/site/.astro, so builds from parallel test files must not overlap.
// A cross-process lock (an atomic mkdir) serialises every npm run; a lock older than 15 minutes is stale.
const LOCK = path.join(os.tmpdir(), "site-qa-npm.lock");
function withLock(fn) {
  const sleep = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
  for (;;) {
    try { fs.mkdirSync(LOCK); break; } catch (e) {
      if (e.code !== "EEXIST") throw e;
      try { if (Date.now() - fs.statSync(LOCK).mtimeMs > 900000) fs.rmSync(LOCK, { recursive: true, force: true }); } catch {}
      sleep(200);
    }
  }
  try { return fn(); } finally { fs.rmSync(LOCK, { recursive: true, force: true }); }
}

// Runs an npm script in apps/site with extra env. Returns {status, out}.
export function npm(args, env = {}, timeout = 300000) {
  return withLock(() => npmUnlocked(args, env, timeout));
}
function npmUnlocked(args, env, timeout) {
  const r = spawnSync("npm", args, {
    cwd: SITE,
    env: { ...process.env, ...env },
    encoding: "utf8",
    timeout,
  });
  return { status: r.status, out: `${r.stdout ?? ""}${r.stderr ?? ""}`, stdout: r.stdout ?? "" };
}

export function node(args, env = {}, timeout = 120000) {
  const r = spawnSync("node", args, {
    cwd: SITE,
    env: { ...process.env, ...env },
    encoding: "utf8",
    timeout,
  });
  return { status: r.status, out: `${r.stdout ?? ""}${r.stderr ?? ""}`, stdout: r.stdout ?? "" };
}

// astro build only. Returns {dist, status, out}.
export function buildSite({ base = BASE, plugins, dist } = {}) {
  dist ??= path.join(scratch(), "dist");
  const env = { SITE_BASE: base, SITE_OUT_DIR: dist };
  if (plugins) env.PLUGINS_DIR = plugins;
  else delete process.env.PLUGINS_DIR;
  const r = npm(["run", "build:site"], env);
  return { dist, ...r };
}

let realBuildCache;
export function realBuild() {
  realBuildCache ??= buildSite();
  if (realBuildCache.status !== 0) {
    throw new Error(`npm run build:site failed:\n${realBuildCache.out.slice(-2000)}`);
  }
  return realBuildCache.dist;
}

// The cached result of the real build: {dist, status, out}.
export function realBuildResult() {
  realBuild();
  return realBuildCache;
}

export function htmlFiles(dist) {
  const out = [];
  (function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      if (e.name.startsWith(".")) continue;
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith(".html")) out.push(path.relative(dist, p).split(path.sep).join("/"));
    }
  })(dist);
  return out.sort();
}

export function allFiles(dist) {
  const out = [];
  (function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else out.push(path.relative(dist, p).split(path.sep).join("/"));
    }
  })(dist);
  return out.sort();
}

// Static server over a build folder, mounted under `base` ("" = served at the root).
export function serve(dist, base = BASE) {
  const types = { ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript", ".svg": "image/svg+xml" };
  const server = http.createServer((rq, rs) => {
    let p = decodeURIComponent(new URL(rq.url, "http://x").pathname);
    if (base && !(p === base || p.startsWith(base + "/"))) { rs.writeHead(404); return rs.end("outside base"); }
    p = p.slice(base.length) || "/";
    let f = path.join(dist, p);
    if (!f.startsWith(dist)) { rs.writeHead(403); return rs.end(); }
    if (fs.existsSync(f) && fs.statSync(f).isDirectory()) f = path.join(f, "index.html");
    if (!fs.existsSync(f)) { rs.writeHead(404); return rs.end("not found"); }
    rs.writeHead(200, { "content-type": types[path.extname(f)] ?? "application/octet-stream" });
    fs.createReadStream(f).pipe(rs);
  });
  return new Promise((resolve) => {
    server.listen(0, "127.0.0.1", () => {
      const origin = `http://127.0.0.1:${server.address().port}`;
      resolve({ origin, close: () => new Promise((r) => server.close(r)) });
    });
  });
}

export async function launch() {
  const { chromium } = loadPlaywright();
  return chromium.launch();
}

// The five pages of the real site (188 AC-3: the URL scheme names them). Counts that depend on the page tree are computed
// from the build output (htmlFiles), never from this list; a test cross-checks the two.
export const EN_ROUTES = [`${BASE}/`, `${BASE}/getting-started/`, `${BASE}/reference/`];
export const NL_ROUTES = [`${BASE}/nl/`, `${BASE}/nl/getting-started/`];
export const ROUTES = [...EN_ROUTES, ...NL_ROUTES];
export const routeOf = (file, base = BASE) => `${base}/${file.replace(/index\.html$/, "")}`;
export const langOf = (route, base = BASE) => (route === `${base}/nl/` || route.startsWith(`${base}/nl/`) ? "nl" : "en");

// ---- fixtures: a copy of the site source (the real pages are never touched) ----
// The copy shares apps/site/node_modules by symlink; the build runs through the same cross-process lock as every npm run.
export function siteCopy() {
  const dir = path.join(scratch("site-copy-"), "site");
  fs.cpSync(SITE, dir, {
    recursive: true,
    filter: (src) => !["node_modules", "dist", ".astro"].includes(path.basename(src)) || path.dirname(src) !== SITE,
  });
  fs.symlinkSync(path.join(SITE, "node_modules"), path.join(dir, "node_modules"));
  return dir;
}
// Edits a file of the copy; `fn` gets the old text (or "" for a new file) and returns the new text.
export function editIn(copy, rel, fn) {
  const f = path.join(copy, rel);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, fn(fs.existsSync(f) ? fs.readFileSync(f, "utf8") : ""));
}
// Adds entries (JS object literal text) to the page tree data file: one edit to the array.
export function addPageEntry(copy, entryJs) {
  editIn(copy, "src/data/pages.mjs", (t) => {
    const i = t.lastIndexOf("];");
    if (i < 0) throw new Error("src/data/pages.mjs has no closing ];");
    return `${t.slice(0, i)}  ${entryJs},\n${t.slice(i)}`;
  });
}
// astro build of a copy. Returns {dist, status, out}.
export function buildCopy(copy, { base = BASE, plugins = PLUGINS, script = "build:site" } = {}) {
  const dist = path.join(scratch("dist-fx-"), "dist");
  const r = withLock(() => spawnSync("npm", ["run", script], {
    cwd: copy, env: { ...process.env, SITE_BASE: base, SITE_OUT_DIR: dist, PLUGINS_DIR: plugins }, encoding: "utf8", timeout: 300000,
  }));
  return { dist, status: r.status, out: `${r.stdout ?? ""}${r.stderr ?? ""}`, stdout: r.stdout ?? "" };
}

// Reads one built page in a browser context (scripts as the caller's context allows) and returns the facts the wiki tests need.
export async function readPage(ctx, origin, route) {
  const page = await ctx.newPage();
  const resp = await page.goto(origin + route);
  const status = resp.status();
  const d = await page.evaluate(() => {
    const t = (e) => e.textContent.trim().replace(/\s+/g, " ");
    const link = (a) => ({ text: t(a), href: a.getAttribute("href"), lang: a.getAttribute("lang"), hreflang: a.getAttribute("hreflang"), current: a.getAttribute("aria-current") });
    const navs = [...document.querySelectorAll("nav")].map((n) => ({
      hook: n.dataset.nav ?? null, name: n.getAttribute("aria-label"), labelledby: n.getAttribute("aria-labelledby"),
      links: [...n.querySelectorAll("a[href]")].map(link),
    }));
    const nav = (h) => document.querySelector(`nav[data-nav="${h}"]`);
    const items = (h) => [...(nav(h)?.querySelectorAll("li") ?? [])].map((li) => ({
      own: t([...li.childNodes].filter((c) => c.nodeType === 3 || (c.nodeType === 1 && c.tagName !== "UL" && c.tagName !== "OL")).map((c) => c.textContent).join(" ")),
      a: li.querySelector(":scope > a") ? link(li.querySelector(":scope > a")) : null,
      current: li.getAttribute("aria-current"),
      depth: (() => { let d = 0; for (let e = li.parentElement; e && e !== nav(h); e = e.parentElement) if (e.tagName === "UL" || e.tagName === "OL") d++; return d; })(),
    }));
    const main = document.querySelector("main");
    return {
      lang: document.documentElement.lang, title: document.title,
      h1: [...document.querySelectorAll("h1")].map(t),
      headings: [...(main?.querySelectorAll("h2, h3") ?? [])].map((h) => ({ level: Number(h.tagName[1]), id: h.id, text: t(h) })),
      navs, treeItems: items("pages"), crumbItems: items("breadcrumb"), contentsItems: items("contents"), seeAlsoItems: items("see-also"),
      hasNav: Object.fromEntries(["site", "language", "pages", "breadcrumb", "contents", "see-also"].map((h) => [h, document.querySelectorAll(`nav[data-nav="${h}"]`).length])),
      treeCurrent: [...(nav("pages")?.querySelectorAll('[aria-current="page"]') ?? [])].map(t),
      mains: document.querySelectorAll("main").length,
      draftNotices: [...document.querySelectorAll("[data-draft-notice]")].map(t),
      switcher: [...document.querySelectorAll("nav[data-lang-switcher] a")].map((a) => ({ ...link(a), dataLang: a.dataset.lang })),
      topLinks: [...document.querySelectorAll("header[data-test=topbar] a")].map(link),
      mainParas: [...(main?.querySelectorAll("p") ?? [])].map(t),
      mainLinks: [...(main?.querySelectorAll("a[href]") ?? [])].map((a) => a.getAttribute("href")),
      codeBlocks: [...(main?.querySelectorAll("pre") ?? [])].map((p) => p.textContent.replace(/\s+$/, "")),
      preTabindex: [...(main?.querySelectorAll("pre") ?? [])].map((p) => p.getAttribute("tabindex")),
      alternates: [...document.querySelectorAll('link[rel="alternate"][hreflang]')].map((l) => [l.getAttribute("hreflang"), l.getAttribute("href")]),
      scripts: document.querySelectorAll("script").length,
      details: document.querySelectorAll("details").length,
      // source order: indexes of the landmarks in document order
      order: (() => {
        const all = [...document.querySelectorAll("a.skip-link, header[data-test=topbar], nav[data-nav=pages], main, footer")];
        return all.map((e) => (e.matches("a.skip-link") ? "skip" : e.matches("header") ? "topbar" : e.matches("nav") ? "tree" : e.tagName.toLowerCase()));
      })(),
      mainContains: { crumb: !!main?.querySelector("nav[data-nav=breadcrumb]"), contents: !!main?.querySelector("nav[data-nav=contents]"), seeAlso: !!main?.querySelector("nav[data-nav=see-also]"), tree: !!main?.querySelector("nav[data-nav=pages]") },
      html: document.documentElement.outerHTML,
    };
  });
  await page.close();
  return { status, ...d };
}

// Skill sources the way the requirement defines them: plugins/*/skills/*/SKILL.md, nothing under .claude/worktrees.
export function skillSources(pluginsDir = PLUGINS) {
  const out = [];
  for (const plugin of fs.readdirSync(pluginsDir)) {
    if (plugin.startsWith(".")) continue;
    const sk = path.join(pluginsDir, plugin, "skills");
    if (!fs.existsSync(sk) || !fs.statSync(sk).isDirectory()) continue;
    for (const skill of fs.readdirSync(sk)) {
      if (skill.startsWith(".")) continue;
      const f = path.join(sk, skill, "SKILL.md");
      if (fs.existsSync(f)) out.push({ plugin, folder: skill, file: f });
    }
  }
  return out;
}

export function parseFrontmatter(file) {
  const lines = fs.readFileSync(file, "utf8").split("\n");
  const end = lines.indexOf("---", 1);
  return loadYaml().parse(lines.slice(1, end).join("\n"));
}

// Colour maths (WCAG 2.x).
export function parseColor(s) {
  let m = s.match(/^rgba?\(([^)]+)\)$/);
  if (m) {
    const p = m[1].split(/[\s,/]+/).filter(Boolean).map(Number);
    return { r: p[0], g: p[1], b: p[2], a: p[3] ?? 1 };
  }
  m = s.match(/^color\(srgb ([^)]+)\)$/);
  if (m) {
    const p = m[1].split(/[\s/]+/).filter(Boolean).map(Number);
    return { r: p[0] * 255, g: p[1] * 255, b: p[2] * 255, a: p[3] ?? 1 };
  }
  throw new Error(`cannot parse computed colour: ${s}`);
}
export function blend(fg, bg) {
  const a = fg.a;
  return { r: fg.r * a + bg.r * (1 - a), g: fg.g * a + bg.g * (1 - a), b: fg.b * a + bg.b * (1 - a), a: 1 };
}
export function luminance({ r, g, b }) {
  const f = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}
export function ratio(a, b) {
  const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
}

// Runs in the page: effective background colour of an element (nearest opaque ancestor, white default).
export const PAGE_HELPERS = `
  window.__bg = (el) => {
    const layers = [];
    for (let e = el; e; e = e.parentElement) {
      const c = getComputedStyle(e).backgroundColor;
      layers.push(c);
      const m = c.match(/[\\d.]+/g);
      if (m && (m.length < 4 || Number(m[3]) === 1) && c !== 'rgba(0, 0, 0, 0)') break;
    }
    return layers;
  };
`;

export function bgFromLayers(layers) {
  let bg = { r: 255, g: 255, b: 255, a: 1 };
  for (const c of [...layers].reverse()) {
    if (c === "rgba(0, 0, 0, 0)" || c === "transparent") continue;
    bg = blend(parseColor(c), bg);
  }
  return bg;
}
