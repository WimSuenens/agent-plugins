// 156 AC-24, AC-25: the accessibility check script and the build command (contracts 156-a11y-check, 156-site-skeleton s1).
// 188 AC-26, AC-27: it checks every built page of both languages (the count is computed from the output) and fails a missing or
// duplicated navigation landmark (contracts/188-a11y-landmarks.md). Page counts are never written into a test.
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { BASE, SITE, npm, node, realBuild, htmlFiles, scratch, siteCopy, editIn, addPageEntry, buildCopy, ROUTES } from "./lib.mjs";
import { loadEntries, oracle } from "./oracle.mjs";

const CHECK = "scripts/a11y-check.mjs";
const lines = (o) => o.split("\n").map((l) => l.trim()).filter(Boolean);
const lastLine = (o) => lines(o).at(-1);
function copyDist() {
  const copy = path.join(scratch("dist-copy-"), "dist");
  fs.cpSync(realBuild(), copy, { recursive: true });
  return copy;
}
function edit(copy, file, fn) {
  const f = path.join(copy, file);
  fs.writeFileSync(f, fn(fs.readFileSync(f, "utf8")));
}

test("AC-24 package.json: build = astro build then the check, status propagated; the check is also its own script", () => {
  const s = JSON.parse(fs.readFileSync(path.join(SITE, "package.json"), "utf8")).scripts;
  assert.match(s.build, /astro build\s*&&\s*node scripts\/a11y-check\.mjs\s+--dist\s+\$\{?SITE_OUT_DIR/);
  assert.match(s["check:a11y"], /a11y-check\.mjs/);
  assert.match(s["build:site"], /astro build/);
  assert.doesNotMatch(s["build:site"], /a11y/);
  assert.match(s.test, /node --test/);
});

test("AC-24/25 the real build command exits 0 and checks every built page", () => {
  const dist = path.join(scratch("dist-real-"), "dist");
  const r = npm(["run", "build"], { SITE_OUT_DIR: dist, SITE_BASE: BASE }, 600000);
  assert.equal(r.status, 0, r.out.slice(-2000));
  const n = htmlFiles(dist).length;
  assert.equal(n, ROUTES.length, "English Home, Getting started, Reference; Dutch Home, Getting started");
  assert.equal(lastLine(r.stdout), `a11y: ${n} pages checked, 0 violations`);
});

test("AC-25 an image without alt on one page fails the check, naming route and rule; the original still passes", () => {
  const copy = copyDist();
  edit(copy, "nl/index.html", (h) => h.replace("</main>", '<img src="x.png"></main>'));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.equal(r.status, 1, r.out);
  assert.match(r.out, /a11y: FAIL \/agent-plugins\/nl\/ image-alt \(\w+\) .* :: .*img/);
  assert.match(lastLine(r.stdout), new RegExp(`^a11y: ${htmlFiles(copy).length} pages checked, [1-9]\\d* violations$`));
  const ok = node([CHECK, "--dist", realBuild(), "--base", BASE]);
  assert.equal(ok.status, 0, ok.out);
});

test("AC-25 text below 4.5:1 fails the check with color-contrast named on the route", () => {
  const copy = copyDist();
  edit(copy, "reference/index.html", (h) => h.replace("</head>", "<style>main p, main h1 { color: #bbbbbb !important; background: #ffffff !important }</style></head>"));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.equal(r.status, 1, r.out);
  assert.match(r.out, /a11y: FAIL \/agent-plugins\/reference\/ color-contrast \(\w+\)/);
});

test("AC-25 the check as the npm script also fails on a faulty build (status propagates)", () => {
  const copy = copyDist();
  edit(copy, "index.html", (h) => h.replace("</main>", '<img src="x.png"></main>'));
  const r = npm(["run", "check:a11y"], { SITE_OUT_DIR: copy, SITE_BASE: BASE });
  assert.notEqual(r.status, 0);
  assert.match(r.out, /image-alt/);
});

test("AC-25 FAIL lines carry no absolute home path", () => {
  const copy = copyDist();
  edit(copy, "index.html", (h) => h.replace("</main>", '<img src="x.png"></main>'));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.ok(!r.out.includes(os.homedir()) && !/\/Users\//.test(r.out));
});

test("check usage errors are exit 2: empty dist, missing dist, unknown option", () => {
  const empty = scratch("empty-");
  for (const args of [["--dist", empty], ["--dist", path.join(empty, "nope")], ["--bogus"], ["--dist", realBuild(), "--bogus", "x"]]) {
    const r = node([CHECK, ...args, ...(args.includes("--base") ? [] : ["--base", BASE])]);
    assert.equal(r.status, 2, `${args.join(" ")}\n${r.out}`);
  }
});

test("a page that navigates away during the run is a setup error: exit 2, a11y: ERROR naming the route", () => {
  const copy = copyDist();
  edit(copy, "reference/index.html", (h) => h.replace("<head>", `<head><script>location.replace("${BASE}/")</script>`));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.equal(r.status, 2, r.out);
  assert.match(r.out, /a11y: ERROR \/agent-plugins\/reference\/ navigated to /);
});

test("check honours SITE_OUT_DIR and SITE_BASE as defaults", () => {
  const r = node([CHECK], { SITE_OUT_DIR: realBuild(), SITE_BASE: BASE });
  assert.equal(r.status, 0, r.out);
  assert.equal(lastLine(r.stdout), `a11y: ${htmlFiles(realBuild()).length} pages checked, 0 violations`);
});

test("check ignores dotfiles and counts every *.html (a copy with an extra page reports one more)", () => {
  const copy = copyDist();
  const before = htmlFiles(copy).length;
  fs.mkdirSync(path.join(copy, "extra"));
  fs.copyFileSync(path.join(copy, "reference/index.html"), path.join(copy, "extra/index.html"));
  fs.writeFileSync(path.join(copy, ".hidden.html"), "<html><img src=x></html>");
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.match(lastLine(r.stdout), new RegExp(`^a11y: ${before + 1} pages checked, \\d+ violations?$`));
});

// ---------- 188 AC-26: new pages are covered, the number comes from the output ----------
test("AC-26 a page added through the page tree is checked too: one more page than the real build, and the build is still green", async () => {
  const copy = siteCopy();
  addPageEntry(copy, `{ slug: "credits", parent: "", title: { en: "Credits", nl: "Dank" }, source: "markdown" }`);
  editIn(copy, "src/content/pages/en/credits.md", () => "## Thanks\n\nThanks.\n");
  editIn(copy, "src/content/pages/nl/credits.md", () => "## Dank\n\nDank.\n");
  const b = buildCopy(copy, { script: "build" });
  assert.equal(b.status, 0, b.out.slice(-2500));
  const want = oracle(await loadEntries(copy)).pages.length;
  assert.equal(htmlFiles(b.dist).length, want);
  assert.equal(want, htmlFiles(realBuild()).length + 2, "an English and a Dutch page more");
  assert.equal(lastLine(b.stdout), `a11y: ${want} pages checked, 0 violations`);
});

test("AC-26 the page count is not written into the check script", () => {
  const src = fs.readFileSync(path.join(SITE, "scripts/a11y-check.mjs"), "utf8").replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
  assert.ok(!/\b(3|5)\s*pages\b/.test(src) && !/(pages|files|routes)\.length\s*[!=]==?\s*\d/.test(src), "no literal page count");
});

// ---------- 188 AC-27: landmark faults ----------
const PAGE = "nl/getting-started/index.html";
const PAGE_ROUTE = `${BASE}/nl/getting-started/`;
const ATTR = (name) => new RegExp(`\\s${name}=(?:"[^"]*"|'[^']*'|[^\\s>]+)`);
function navBlock(html, hook) {
  const start = html.search(new RegExp(`<nav\\b[^>]*\\bdata-nav=["']?${hook}["']?[^>]*>`));
  assert.ok(start >= 0, `nav[data-nav=${hook}] present in the fixture page`);
  const end = html.indexOf("</nav>", start) + "</nav>".length;
  return { start, end, text: html.slice(start, end), open: html.slice(start, html.indexOf(">", start) + 1) };
}
const withBlock = (html, hook, fn) => { const b = navBlock(html, hook); return html.slice(0, b.start) + fn(b) + html.slice(b.end); };
const LANDMARK_FAULTS = [
  ["the pages nav has no accessible name", PAGE, PAGE_ROUTE, "site-nav-name", (h) => withBlock(h, "pages", (b) => b.text.replace(b.open, b.open.replace(ATTR("aria-label"), "")))],
  ["the pages nav has an empty name", PAGE, PAGE_ROUTE, "site-nav-name", (h) => withBlock(h, "pages", (b) => b.text.replace(b.open, b.open.replace(ATTR("aria-label"), ' aria-label=""')))],
  ["the breadcrumb nav shares the name of the pages nav", PAGE, PAGE_ROUTE, "site-nav-unique", (h) => {
    const name = navBlock(h, "pages").open.match(/aria-label=(?:"([^"]*)"|'([^']*)'|([^\s>]+))/);
    const v = name[1] ?? name[2] ?? name[3];
    return withBlock(h, "breadcrumb", (b) => b.text.replace(b.open, b.open.replace(ATTR("aria-label"), ` aria-label="${v}"`)));
  }],
  ["the breadcrumb nav is removed", PAGE, PAGE_ROUTE, "site-nav-required", (h) => withBlock(h, "breadcrumb", () => "")],
  ["main is a div", PAGE, PAGE_ROUTE, "site-main-count", (h) => h.replace(/<main\b/, "<div").replace("</main>", "</div>")],
  ["the tree has no current entry", PAGE, PAGE_ROUTE, "site-current-page", (h) => withBlock(h, "pages", (b) => b.text.replace(/\saria-current=(?:"page"|'page'|page)/g, ""))],
  ["the breadcrumb has no current item", PAGE, PAGE_ROUTE, "site-current-page", (h) => withBlock(h, "breadcrumb", (b) => b.text.replace(/\saria-current=(?:"page"|'page'|page)/g, ""))],
  ["the contents nav holds no link", "getting-started/index.html", `${BASE}/getting-started/`, "site-nav-empty", (h) => withBlock(h, "contents", (b) => b.text.replace(/<a\b[^>]*>/g, "").replace(/<\/a>/g, ""))],
];
for (const [name, file, route, rule, fn] of LANDMARK_FAULTS) {
  test(`AC-27 ${name}: exit 1, names the page and ${rule}; the unedited build exits 0`, () => {
    const copy = copyDist();
    edit(copy, file, fn);
    const r = node([CHECK, "--dist", copy, "--base", BASE]);
    assert.equal(r.status, 1, r.out);
    assert.match(r.out, new RegExp(`a11y: FAIL ${route.replace(/\//g, "\\/")} ${rule} \\(serious\\) .* :: .+`), r.out);
    assert.match(lastLine(r.stdout), new RegExp(`^a11y: ${htmlFiles(copy).length} pages checked, [1-9]\\d* violations?$`));
    assert.ok(!r.out.includes(os.homedir()) && !/\/Users\//.test(r.out), "no absolute path");
    const ok = node([CHECK, "--dist", realBuild(), "--base", BASE]);
    assert.equal(ok.status, 0, ok.out);
  });
}

test("AC-27 a fault on one page leaves the other pages' lines out: only the edited route is named", () => {
  const copy = copyDist();
  edit(copy, PAGE, (h) => withBlock(h, "breadcrumb", () => ""));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  const failed = [...new Set([...r.out.matchAll(/a11y: FAIL (\S+) /g)].map((m) => m[1]))];
  assert.deepEqual(failed, [PAGE_ROUTE]);
});

test("AC-27 a page that is not a tree page (a copy of Reference placed elsewhere) is judged on its own DOM: still exit 0 when its landmarks are right", () => {
  const copy = copyDist();
  fs.mkdirSync(path.join(copy, "extra"));
  fs.copyFileSync(path.join(copy, "reference/index.html"), path.join(copy, "extra/index.html"));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.equal(r.status, 0, r.out);
});
