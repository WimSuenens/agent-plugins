// Accessibility check on built pages: axe-core in headless Chromium. Contract: contracts/156-a11y-check.md.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";

const TYPES = { ".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".svg": "image/svg+xml", ".png": "image/png", ".ico": "image/x-icon", ".txt": "text/plain; charset=utf-8" };

function parseArgs(argv) {
  const opts = { dist: process.env.SITE_OUT_DIR || "dist", base: process.env.SITE_BASE || "/agent-plugins" };
  for (let i = 0; i < argv.length; i += 2) {
    const k = argv[i];
    if ((k !== "--dist" && k !== "--base") || argv[i + 1] === undefined) return null;
    opts[k.slice(2)] = argv[i + 1];
  }
  return opts;
}

function htmlFiles(dir, rel = "") {
  return fs.readdirSync(path.join(dir, rel), { withFileTypes: true }).flatMap((e) => {
    if (e.name.startsWith(".")) return [];
    const r = path.join(rel, e.name);
    return e.isDirectory() ? htmlFiles(dir, r) : e.name.endsWith(".html") ? [r] : [];
  });
}

function serve(dist, base) {
  const root = path.resolve(dist);
  const server = http.createServer((req, res) => {
    let p;
    try { p = decodeURIComponent(new URL(req.url, "http://x").pathname); } catch { p = ""; }
    if (!p.startsWith(`${base}/`)) { res.writeHead(404).end("not found"); return; }
    let file = path.resolve(root, `.${p.slice(base.length)}`);
    if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(404).end("not found"); return; }
    if (p.endsWith("/")) file = path.join(file, "index.html");
    fs.readFile(file, (err, data) => {
      if (err) { res.writeHead(404).end("not found"); return; }
      res.writeHead(200, { "content-type": TYPES[path.extname(file)] ?? "application/octet-stream" }).end(data);
    });
  });
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (!opts) { console.error("usage: a11y-check.mjs [--dist <dir>] [--base <path>]"); return 2; }
  const { dist, base } = opts;
  if (!fs.existsSync(dist) || !fs.statSync(dist).isDirectory()) { console.error(`a11y: ERROR dist folder not found: ${dist}`); return 2; }
  const files = htmlFiles(dist).sort();
  if (files.length === 0) { console.error("a11y: ERROR no *.html files under the dist folder"); return 2; }
  const routes = files.map((f) => `${base}/${f.replace(/index\.html$/, "").split(path.sep).join("/")}`);

  let server, browser;
  try {
    server = await serve(dist, base);
    const origin = `http://127.0.0.1:${server.address().port}`;
    try {
      browser = await chromium.launch();
    } catch {
      console.error("a11y: ERROR Chromium is not available; run `npx playwright install chromium`");
      return 2;
    }
    let violations = 0;
    for (const route of routes) {
      const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
      const page = await context.newPage();
      try {
        await page.goto(origin + route, { waitUntil: "load" });
        const final = new URL(page.url());
        if (final.pathname !== route) { console.log(`a11y: ERROR ${route} navigated to ${final.pathname}`); return 2; }
        const result = await new AxeBuilder({ page })
          .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa", "best-practice"])
          .options({ rules: { "color-contrast": { enabled: true } } })
          .analyze();
        for (const v of result.violations)
          for (const n of v.nodes) { violations++; console.log(`a11y: FAIL ${route} ${v.id} (${v.impact}) ${v.help} :: ${n.target.join(" ")}`); }
        for (const i of result.incomplete.filter((x) => x.id === "color-contrast"))
          for (const n of i.nodes) { violations++; console.log(`a11y: WARN ${route} color-contrast could not be decided :: ${n.target.join(" ")}`); }
      } catch (e) {
        console.log(`a11y: ERROR ${route} ${String(e.message).split("\n")[0].replaceAll(origin, "")}`);
        return 2;
      } finally {
        await context.close();
      }
    }
    console.log(`a11y: ${routes.length} pages checked, ${violations} violations`);
    return violations > 0 ? 1 : 0;
  } finally {
    await browser?.close();
    await new Promise((r) => (server ? server.close(r) : r()));
  }
}

process.exitCode = await main();
