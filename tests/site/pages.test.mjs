// Slice 188, section A (AC-1 to AC-4), AC-2 fixtures, AC-16, AC-12 (page-tree side), AC-11 fixtures, AC-13 drop rule,
// AC-21 reviewed status, and the build-time faults of the page tree and of content files (contracts/188-page-tree.md sections 3, 5, 6).
// Fixtures work on a copy of the site source (lib.siteCopy); the real pages are never touched. Expected values come from
// the page tree data file through the independent model in oracle.mjs, never from a written-in count.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BASE, SITE, ROUTES, realBuildResult, realBuild, htmlFiles, routeOf, serve, launch, siteCopy, editIn, addPageEntry, buildCopy } from "./lib.mjs";
import { loadEntries, oracle, verifyBuild as verifyBuildIn } from "./oracle.mjs";

let browser;
before(async () => { browser = await launch(); });
after(async () => { await browser?.close(); });

const verifyBuild = (dist, o, opts) => verifyBuildIn(browser, dist, o, opts);

const MD_CREDITS = "## Thanks\n\nThanks to everyone who made the skills.\n";
const MD_CREDITS_NL = "## Dank\n\nDank aan iedereen die de vaardigheden maakte.\n";

// ---------- AC-1, AC-3 on the real build ----------
test("AC-3 the built pages are exactly the pages of the page tree, at the URLs of the scheme", async () => {
  const dist = realBuild();
  const o = oracle(await loadEntries());
  assert.deepEqual(htmlFiles(dist).map((f) => routeOf(f)).sort(), o.pages.map((p) => p.route).sort());
  // the requirement names the five URLs; the data file must agree with them
  assert.deepEqual([...ROUTES].sort(), o.pages.map((p) => p.route).sort(), "the real page tree is Home, Getting started, Reference in English; Home and Getting started in Dutch");
  for (const bad of ["nl/reference", "nl/reference/index.html", "404.html"]) assert.ok(!fs.existsSync(path.join(dist, bad)), `${bad} must not be built`);
  for (const r of ROUTES) assert.ok(r.startsWith(`${BASE}/`) && r.endsWith("/"));
});

test("AC-1 every built page agrees with its page tree entry: tree, breadcrumb, contents, see-also, switcher, drafts", async () => {
  const dist = realBuild();
  const o = oracle(await loadEntries());
  await verifyBuild(dist, o);
});

test("AC-1 the routing is two files and no component or page file keeps its own list of pages or a URL for another page", () => {
  const pagesDir = path.join(SITE, "src/pages");
  const files = [];
  (function walk(d) { for (const e of fs.readdirSync(d, { withFileTypes: true })) (e.isDirectory() ? walk(path.join(d, e.name)) : files.push(path.relative(pagesDir, path.join(d, e.name)).split(path.sep).join("/"))); })(pagesDir);
  assert.deepEqual(files.sort(), ["[...slug].astro", "nl/[...slug].astro"], "the three route files of 156 are gone");
  const allowed = new Set(["data/pages.mjs", "components/registry.mjs"]);
  const offenders = [];
  (function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) { if (e.name !== "content") walk(p); continue; }
      const rel = path.relative(path.join(SITE, "src"), p).split(path.sep).join("/");
      if (allowed.has(rel) || !/\.(astro|mjs|ts|js)$/.test(rel)) continue;
      const t = fs.readFileSync(p, "utf8");
      // a URL written out for another page: a quoted string holding "<slug>/" (url("reference/")), "/<slug>/", or the base path itself.
      // Slugs as data keys (a component key, a model call such as href("reference", "en")) are not URLs and are not flagged.
      if (/["'`]\/?(nl\/)?(getting-started|reference)\//.test(t) || /\/agent-plugins\//.test(t)) offenders.push(rel);
    }
  })(path.join(SITE, "src"));
  assert.deepEqual(offenders, [], "page slugs or page URLs written outside data/pages.mjs and the registry");
});

test("AC-21 the build prints the list of Dutch draft pages once, from the page tree", async () => {
  const o = oracle(await loadEntries());
  const lines = realBuildResult().out.split("\n").filter((l) => l.includes("pages: dutch drafts:"));
  assert.equal(lines.length, 1, "printed once");
  const list = lines[0].slice(lines[0].indexOf("pages: dutch drafts:") + "pages: dutch drafts:".length).trim();
  assert.equal(list, o.drafts().length ? o.drafts().join(" ") : "none");
});

// ---------- AC-2: adding one page is one edit ----------
test("AC-2 / AC-16 an English-only page: one entry and one content file; no Dutch page, no dead Dutch link, Dutch switcher goes to Dutch Home", async () => {
  const copy = siteCopy();
  addPageEntry(copy, `{ slug: "credits", parent: "", title: { en: "Credits" }, source: "markdown" }`);
  editIn(copy, "src/content/pages/en/credits.md", () => MD_CREDITS);
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
  const o = oracle(await loadEntries(copy));
  assert.ok(o.exists("credits", "en") && !o.exists("credits", "nl"));
  const pages = await verifyBuild(b.dist, o);
  assert.ok(fs.existsSync(path.join(b.dist, "credits/index.html")));
  assert.ok(!fs.existsSync(path.join(b.dist, "nl/credits")), "no stub, no redirect for the missing Dutch page");
  const c = pages[`${BASE}/credits/`];
  assert.equal(c.lang, "en");
  assert.deepEqual(c.crumbItems.map((i) => i.own), ["Home", "Credits"]);
  assert.ok(c.treeItems.some((i) => i.a.text === "Credits" && i.a.href === `${BASE}/credits/` && i.depth === 2), "listed in the English tree under Home");
  assert.equal(c.switcher.find((s) => s.dataLang === "nl").href, `${BASE}/nl/`);
  for (const [route, d] of Object.entries(pages)) {
    if (!route.startsWith(`${BASE}/nl/`)) continue;
    assert.ok(!d.treeItems.some((i) => /credits/i.test(i.a.href)), `${route}: Dutch tree links no Credits page`);
    assert.ok(!d.html.includes(`${BASE}/nl/credits`), `${route}: no link to a missing /nl/ page`);
  }
  // no other source file changed: the copy differs from the real source in exactly these two files
  const diff = [];
  (function walk(rel = "src") {
    for (const e of fs.readdirSync(path.join(copy, rel), { withFileTypes: true })) {
      const r = `${rel}/${e.name}`;
      if (e.isDirectory()) { walk(r); continue; }
      const real = path.join(SITE, r);
      if (!fs.existsSync(real) || fs.readFileSync(real, "utf8") !== fs.readFileSync(path.join(copy, r), "utf8")) diff.push(r);
    }
  })();
  assert.deepEqual(diff.sort(), ["src/content/pages/en/credits.md", "src/data/pages.mjs"]);
});

test("AC-2 / AC-13 / AC-21 adding the Dutch content makes /nl/credits/ exist, shows the draft notice, links both switchers; a reviewed page has no notice", async () => {
  const copy = siteCopy();
  addPageEntry(copy, `{ slug: "credits", parent: "", title: { en: "Credits", nl: "Dank" }, source: "markdown" }`);
  addPageEntry(copy, `{ slug: "kudos", parent: "", title: { en: "Kudos", nl: "Lof" }, source: "markdown", review: { nl: "reviewed" } }`);
  for (const [slug, en, nl] of [["credits", MD_CREDITS, MD_CREDITS_NL], ["kudos", "## Praise\n\nWell done.\n", "## Lof\n\nGoed gedaan.\n"]]) {
    editIn(copy, `src/content/pages/en/${slug}.md`, () => en);
    editIn(copy, `src/content/pages/nl/${slug}.md`, () => nl);
  }
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
  const o = oracle(await loadEntries(copy));
  const pages = await verifyBuild(b.dist, o);
  const nl = pages[`${BASE}/nl/credits/`];
  assert.equal(nl.lang, "nl");
  assert.equal(nl.draftNotices.length, 1, "draft by default: the safe default for a new Dutch page");
  assert.equal(nl.switcher.find((s) => s.dataLang === "en").href, `${BASE}/credits/`);
  assert.equal(pages[`${BASE}/credits/`].switcher.find((s) => s.dataLang === "nl").href, `${BASE}/nl/credits/`);
  assert.ok(nl.treeItems.some((i) => i.a.text === "Dank" && i.a.href === `${BASE}/nl/credits/`), "the Dutch tree lists the Dutch label");
  assert.equal(pages[`${BASE}/nl/kudos/`].draftNotices.length, 0, "reviewed: no notice");
  const line = b.out.split("\n").find((l) => l.includes("pages: dutch drafts:")) ?? "";
  assert.ok(line.includes(`${BASE}/nl/credits/`) && !line.includes(`${BASE}/nl/kudos/`), `drafts line: ${line}`);
});

test("AC-13 / AC-16 a see-also slug with no page in the language is left out of that language's list, not an error", async () => {
  const copy = siteCopy();
  addPageEntry(copy, `{ slug: "credits", parent: "", title: { en: "Credits" }, source: "markdown" }`);
  editIn(copy, "src/content/pages/en/credits.md", () => MD_CREDITS);
  editIn(copy, "src/data/pages.mjs", (t) => `${t}\npages.find((p) => p.slug === "getting-started").seeAlso.push("credits");\n`);
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
  const o = oracle(await loadEntries(copy));
  const pages = await verifyBuild(b.dist, o);
  assert.ok(pages[`${BASE}/getting-started/`].seeAlsoItems.some((i) => i.a.href === `${BASE}/credits/`), "English list has Credits");
  assert.ok(!pages[`${BASE}/nl/getting-started/`].html.includes("/credits/"), "Dutch page has no link to Credits");
});

// ---------- AC-11: the contents list follows the headings with no other edit ----------
test("AC-11 a heading added to a content file appears in the contents list on rebuild; a page with no h2 shows no empty contents list; a long command does not widen a phone page", async () => {
  const copy = siteCopy();
  addPageEntry(copy, `{ slug: "credits", parent: "", title: { en: "Credits" }, source: "markdown" }`);
  addPageEntry(copy, `{ slug: "plain", parent: "", title: { en: "Plain" }, source: "markdown" }`);
  const long = `claude plugin install ${"a-very-long-command-token-".repeat(14)}end`;
  editIn(copy, "src/content/pages/en/credits.md", () => `## Thanks\n\nText.\n\n## Second\n\n### Nested one\n\nMore.\n\n### Nested two\n\n\`\`\`\n${long}\n\`\`\`\n`);
  editIn(copy, "src/content/pages/en/plain.md", () => "Just a paragraph with no heading at all.\n");
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
  const o = oracle(await loadEntries(copy));
  const pages = await verifyBuild(b.dist, o);
  const c = pages[`${BASE}/credits/`];
  assert.deepEqual(c.contentsItems.map((i) => [i.a.text, i.depth]), [["Thanks", 1], ["Second", 1], ["Nested one", 2], ["Nested two", 2]]);
  const p = pages[`${BASE}/plain/`];
  assert.equal(p.hasNav.contents, 0);
  assert.ok(!/<nav[^>]*data-nav=["']?contents/.test(p.html), "no contents nav at all");
  // the headline: the same page with one more heading and no other edit
  editIn(copy, "src/content/pages/en/credits.md", (t) => `${t}\n## Added later\n`);
  const b2 = buildCopy(copy);
  assert.equal(b2.status, 0, b2.out.slice(-1500));
  const again = await verifyBuild(b2.dist, o);
  assert.deepEqual(again[`${BASE}/credits/`].contentsItems.map((i) => i.a.text), [...c.contentsItems.map((i) => i.a.text), "Added later"]);
  // AC-23 on the long command, at 320px
  const srv = await serve(b.dist);
  const ctx = await browser.newContext({ viewport: { width: 320, height: 640 } });
  try {
    const page = await ctx.newPage();
    await page.goto(`${srv.origin}${BASE}/credits/`);
    const m = await page.evaluate(() => {
      const pre = [...document.querySelectorAll("main pre")].at(-1);
      const cs = getComputedStyle(pre);
      pre.focus();
      return { docW: document.documentElement.scrollWidth, vw: innerWidth, preW: pre.getBoundingClientRect().right, scrolls: pre.scrollWidth > pre.clientWidth, overflowX: cs.overflowX, tab: pre.getAttribute("tabindex"), focused: document.activeElement === pre, ws: cs.whiteSpace };
    });
    assert.ok(m.docW <= m.vw, `document ${m.docW} wider than viewport ${m.vw}`);
    assert.ok(m.preW <= m.vw + 0.5, "the code block stays inside the viewport");
    if (m.scrolls) assert.ok(m.focused && m.tab !== null, "a scrolling code block is keyboard-focusable");
    assert.ok(m.scrolls || m.ws !== "pre", "the long command is either scrolled or wrapped, never clipped");
  } finally { await ctx.close(); await srv.close(); }
});

// ---------- AC-4 and the contract's section 5: a broken page tree fails the build, naming the entry and the fault ----------
const X = (more = "") => `{ slug: "x", parent: "", title: { en: "X" }, source: "markdown"${more} }`;
const XMD = "## Heading\n\nText.\n";
const FAULTS = [
  ["duplicate slug (AC-4)", `{ slug: "reference", parent: "", title: { en: "Again" }, source: "component", component: "reference" }`, {}, /pages: reference: duplicate slug/],
  ["parent that does not exist (AC-4)", `{ slug: "x", parent: "nowhere", title: { en: "X" }, source: "markdown" }`, { x: XMD }, /pages: x: parent "nowhere" does not exist/],
  ["see-also slug that does not exist (AC-4)", X(`, seeAlso: ["ghost"]`), { x: XMD }, /pages: x: see-also "ghost" does not exist/],
  ["missing English title", `{ slug: "x", parent: "", title: { nl: "X" }, source: "markdown" }`, { nlx: XMD }, /pages: x: missing English title/],
  ["invalid slug", `{ slug: "Bad_Slug", parent: "", title: { en: "X" }, source: "markdown" }`, {}, /pages: Bad_Slug: invalid slug/],
  ["reserved slug nl", `{ slug: "nl", parent: "", title: { en: "X" }, source: "markdown" }`, {}, /pages: nl: reserved slug/],
  ["missing content file", X(), {}, /pages: x: missing content file src\/content\/pages\/en\/x\.md/],
  ["content file with no page tree entry", null, { orphan: XMD }, /content file src\/content\/pages\/en\/orphan\.md has no page tree entry/],
  ["unknown component", `{ slug: "x", parent: "", title: { en: "X" }, source: "component", component: "nope" }`, {}, /pages: x: unknown component "nope"/],
  ["a Dutch page whose parent has no Dutch page", `{ slug: "x", parent: "reference", title: { en: "X", nl: "X" }, source: "markdown" }`, { x: XMD, nlx: XMD }, /pages: x: parent "reference" has no nl page/],
  ["alsoListedIn names a language the page exists in", `{ slug: "x", parent: "", title: { en: "X", nl: "X" }, source: "markdown", alsoListedIn: ["nl"] }`, { x: XMD, nlx: XMD }, /pages: x: alsoListedIn conflicts with title\.nl/],
  ["a review status other than draft or reviewed", `{ slug: "x", parent: "", title: { en: "X", nl: "X" }, source: "markdown", review: { nl: "maybe" } }`, { x: XMD, nlx: XMD }, /pages: x: /],
  ["a review status on a page with no Dutch title", X(`, review: { nl: "reviewed" }`), { x: XMD }, /pages: x: /],
  ["a parent cycle", `{ slug: "a", parent: "b", title: { en: "A" }, source: "markdown" }, { slug: "b", parent: "a", title: { en: "B" }, source: "markdown" }`, { a: XMD, b: XMD }, /pages: (a|b): .*(cycle|does not exist)/],
  ["a second Home", `{ slug: "", parent: null, title: { en: "Again" }, source: "component", component: "home" }`, {}, /pages: \(home\): .*(duplicate slug|second|parent)/i],
  ["two headings with the same id on one page", X(), { x: "## Same\n\ntext\n\n## Same\n\ntext\n" }, /pages: x: duplicate heading id "same"/],
];
for (const [name, entry, files, expect] of FAULTS) {
  test(`AC-4 build fails, naming the entry and the fault: ${name}`, () => {
    const copy = siteCopy();
    if (entry) addPageEntry(copy, entry);
    for (const [k, text] of Object.entries(files)) {
      const nl = k.startsWith("nl");
      editIn(copy, `src/content/pages/${nl ? "nl" : "en"}/${nl ? k.slice(2) : k}.md`, () => text);
    }
    const b = buildCopy(copy);
    assert.notEqual(b.status, 0, "the build must fail");
    assert.match(b.out, expect);
    const msg = b.out.split("\n").find((l) => expect.test(l)) ?? "";
    assert.ok(!/\/(Users|home)\/[^\s]*/.test(msg), `message holds an absolute path: ${msg}`);
  });
}

// ---------- AC-22 / AC-4 content files: layout markup, a level-1 heading and a broken body link fail the build, naming the file ----------
const BAD_CONTENT = [
  ["a level-1 heading", "# Title\n\nText.\n"],
  ["a style attribute", '## A\n\n<p style="color: red">x</p>\n'],
  ["a class attribute", '## A\n\n<p class="wide">x</p>\n'],
  ["a div", "## A\n\n<div>x</div>\n"],
  ["a span", "## A\n\n<span>x</span>\n"],
  ["a style tag", "## A\n\n<style>p{margin:0}</style>\n"],
  ["a hex colour literal", "## A\n\nThe colour is #c0ffee here.\n"],
  ["an rgb colour literal", "## A\n\nUse rgb(1, 2, 3) here.\n"],
  ["a body link to a page that is not in the page tree", "## A\n\nSee [nothing](/nope/).\n"],
];
for (const [name, text] of BAD_CONTENT) {
  test(`AC-22 content with ${name} fails the build and names the file`, () => {
    const copy = siteCopy();
    addPageEntry(copy, X());
    editIn(copy, "src/content/pages/en/x.md", () => text);
    const b = buildCopy(copy);
    assert.notEqual(b.status, 0);
    assert.match(b.out, /src\/content\/pages\/en\/x\.md/);
    assert.ok(!/\/(Users|home)\//.test(b.out.split("\n").filter((l) => l.includes("x.md")).join("\n")), "no absolute path in the message");
  });
}

test("AC-22 the same words inside code are not layout markup: a code block and inline code may hold <div>, style= and #fff", async () => {
  const copy = siteCopy();
  addPageEntry(copy, X());
  editIn(copy, "src/content/pages/en/x.md", () => "## A\n\nInline `<div class=\"x\">` and `#fff`.\n\n```html\n<div style=\"color:#fff\">x</div>\n```\n");
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
});

test("AC-3 a content link written site-root relative is built with the base and ends in /", async () => {
  const copy = siteCopy();
  addPageEntry(copy, X());
  editIn(copy, "src/content/pages/en/x.md", () => "## A\n\nSee [Reference](/reference/) and [Home](/).\n");
  const b = buildCopy(copy);
  assert.equal(b.status, 0, b.out.slice(-1500));
  const html = fs.readFileSync(path.join(b.dist, "x/index.html"), "utf8");
  assert.ok(html.includes(`href="${BASE}/reference/"`) || html.includes(`href=${BASE}/reference/`), "Reference link prefixed with the base");
});
