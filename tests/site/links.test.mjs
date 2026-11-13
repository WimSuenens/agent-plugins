// AC-18 (and AC-3's link shape): no dead internal link in the built site, with a control that proves the crawl can fail.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BASE, realBuild, htmlFiles, routeOf, scratch, serve, launch } from "./lib.mjs";

let browser;
before(async () => { browser = await launch(); });
after(async () => { await browser?.close(); });

// Follows every a[href] of every page of a build folder. Returns the list of problems (empty when none) and how many links it followed.
async function crawl(dist, base = BASE) {
  const srv = await serve(dist, base);
  const ctx = await browser.newContext();
  const problems = [];
  let followed = 0;
  try {
    const pages = new Map(); // route -> { ids:Set, hrefs:[] }
    for (const f of htmlFiles(dist)) {
      const route = routeOf(f, base);
      const page = await ctx.newPage();
      await page.goto(srv.origin + route);
      pages.set(route, await page.evaluate(() => ({ ids: [...document.querySelectorAll("[id]")].map((e) => e.id), hrefs: [...document.querySelectorAll("a[href]")].map((a) => a.getAttribute("href")) })));
      await page.close();
    }
    for (const [route, d] of pages) {
      for (const href of d.hrefs) {
        if (/^(https?:|mailto:|tel:)/i.test(href)) continue;
        followed++;
        const [pathPart, frag] = [href.split("#")[0], href.includes("#") ? href.slice(href.indexOf("#") + 1) : null];
        let target = route;
        if (pathPart !== "") {
          if (!pathPart.startsWith(`${base}/`)) { problems.push(`${route}: ${href} is not under ${base}/`); continue; }
          if (!pathPart.endsWith("/")) { problems.push(`${route}: ${href} does not end in /`); continue; }
          if (!pages.has(pathPart)) { problems.push(`${route}: ${href} resolves to no page of the build`); continue; }
          target = pathPart;
        }
        if (frag !== null && frag !== "" && !pages.get(target).ids.includes(decodeURIComponent(frag))) problems.push(`${route}: ${href} points at a missing id`);
      }
    }
    return { problems, followed, pages: pages.size };
  } finally { await ctx.close(); await srv.close(); }
}

function copyDist() {
  const copy = path.join(scratch("dist-links-"), "dist");
  fs.cpSync(realBuild(), copy, { recursive: true });
  return copy;
}

test("AC-18 every internal link and fragment of every page in both languages resolves inside the build", async () => {
  const r = await crawl(realBuild());
  assert.deepEqual(r.problems, []);
  assert.ok(r.pages >= 5 && r.followed > r.pages * 4, `crawled ${r.followed} links over ${r.pages} pages: the crawl did look at the tree, breadcrumb, switcher and body`);
});

test("AC-18 control: a link to a page that does not exist is found", async () => {
  const copy = copyDist();
  const f = path.join(copy, "getting-started/index.html");
  const html = fs.readFileSync(f, "utf8");
  const bent = html.replace(/href=("?)\/agent-plugins\/reference\/\1/, `href=$1/agent-plugins/no-such-page/$1`);
  assert.notEqual(bent, html, "the fixture edit applied");
  fs.writeFileSync(f, bent);
  const r = await crawl(copy);
  assert.ok(r.problems.some((p) => p.includes("no-such-page")), JSON.stringify(r.problems));
});

test("AC-18 control: a fragment link to an id that does not exist is found", async () => {
  const copy = copyDist();
  const f = path.join(copy, "reference/index.html");
  const html = fs.readFileSync(f, "utf8");
  const bent = html.replace(/href=("?)#([a-z0-9-]+)\1/, `href=$1#missing-id-xyz$1`);
  assert.notEqual(bent, html, "the Reference page has a contents list with fragment links");
  fs.writeFileSync(f, bent);
  const r = await crawl(copy);
  assert.ok(r.problems.some((p) => p.includes("missing-id-xyz")), JSON.stringify(r.problems));
});

test("AC-18 control: a cross-language link to a missing Dutch page is found", async () => {
  const copy = copyDist();
  const f = path.join(copy, "nl/index.html");
  const html = fs.readFileSync(f, "utf8");
  const bent = html.replace(/href=("?)\/agent-plugins\/nl\/getting-started\/\1/, `href=$1/agent-plugins/nl/reference/$1`);
  assert.notEqual(bent, html);
  fs.writeFileSync(f, bent);
  const r = await crawl(copy);
  assert.ok(r.problems.some((p) => p.includes("/nl/reference/")), JSON.stringify(r.problems));
});
