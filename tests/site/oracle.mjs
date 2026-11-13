// Independent model of the page tree (contracts/188-page-tree.md sections 1 and 2) for the acceptance suite, and the
// per-page check of a built page against it. It reads only the data file (apps/site/src/data/pages.mjs, "data only"),
// never the application's own derivation code. Not a test file: the runner glob is tests/site/*.test.mjs.
import path from "node:path";
import { pathToFileURL } from "node:url";
import assert from "node:assert/strict";
import { BASE, SITE, htmlFiles, routeOf, serve, readPage } from "./lib.mjs";

export async function loadEntries(siteDir = SITE) {
  const m = await import(`${pathToFileURL(path.join(siteDir, "src/data/pages.mjs")).href}?q=${Math.random()}`);
  return m.pages;
}

export function oracle(entries, base = BASE) {
  const by = new Map(entries.map((e) => [e.slug, e]));
  const exists = (s, l) => Boolean(by.get(s)?.title?.[l]);
  const href = (s, l) => `${base}/${l === "nl" ? "nl/" : ""}${s ? `${s}/` : ""}`;
  const listed = (s, l) => exists(s, l) || Boolean(by.get(s)?.alsoListedIn?.includes(l));
  const label = (s, l) => by.get(s).title[l];
  const heading = (s, l) => by.get(s).heading?.[l] ?? label(s, l);
  const children = (s) => entries.filter((e) => e.parent === s && e.slug !== "");
  const crumb = (s, l) => {
    const chain = [];
    for (let c = s; c !== null && c !== undefined; c = by.get(c).parent) chain.unshift(c);
    return chain.map((x) => ({ slug: x, label: label(x, l), href: href(x, l) }));
  };
  const tree = (l) => {
    const rows = [];
    (function walk(s, depth) {
      if (!listed(s, l)) return;
      const own = exists(s, l);
      rows.push(own
        ? { slug: s, label: label(s, l), href: href(s, l), depth, foreign: false }
        : { slug: s, label: label(s, "en"), href: href(s, "en"), depth, foreign: true });
      for (const c of children(s)) walk(c.slug, depth + 1);
    })("", 1);
    return rows;
  };
  const seeAlso = (s, l) => (by.get(s).seeAlso ?? []).filter((x) => exists(x, l)).map((x) => ({ slug: x, label: label(x, l), href: href(x, l) }));
  const pages = [];
  for (const e of entries) for (const l of ["en", "nl"]) if (exists(e.slug, l)) pages.push({ slug: e.slug, lang: l, route: href(e.slug, l) });
  const drafts = () => pages.filter((p) => p.lang === "nl" && by.get(p.slug).review?.nl !== "reviewed").map((p) => p.route).sort();
  const isDraft = (s) => by.get(s).review?.nl !== "reviewed";
  return { by, exists, href, listed, label, heading, crumb, tree, seeAlso, pages, drafts, isDraft, home: (l) => href("", l) };
}

export const pageOfRoute = (route, base = BASE) => {
  let p = route.slice(base.length + 1);
  const lang = p === "nl/" || p.startsWith("nl/") ? "nl" : "en";
  if (lang === "nl") p = p.slice(3);
  return { lang, slug: p.replace(/\/$/, "") };
};

// Checks one page read with readPage() against the model: AC-1, AC-5, AC-6, AC-9, AC-10, AC-11, AC-13, AC-14, AC-15, AC-16, AC-21, AC-25 (source order).
export function checkPage(d, route, o) {
  const { lang, slug } = pageOfRoute(route);
  const at = (what) => `${route}: ${what}`;
  assert.equal(d.status, 200, at("status"));
  assert.equal(d.lang, lang, at("html lang"));
  assert.deepEqual(d.h1, [o.heading(slug, lang)], at("one h1 from the page tree"));
  if (slug !== "") assert.equal(d.title, `${o.heading(slug, lang)} - Agent plugins`, at("title element"));

  // AC-5 / AC-1: navigation tree = model.tree(lang)
  const want = o.tree(lang);
  assert.deepEqual(d.treeItems.map((i) => [i.a?.text, i.a?.href, i.depth]), want.map((r) => [r.label, r.href, r.depth]), at("navigation tree"));
  want.forEach((r, i) => {
    const a = d.treeItems[i].a;
    if (r.foreign) { assert.equal(a.lang, "en", at(`${r.label}: lang=en`)); assert.equal(a.hreflang, "en", at(`${r.label}: hreflang=en`)); }
    else assert.ok(a.lang === null || a.lang === lang, at(`${r.label}: no misdeclared lang ${a.lang}`));
  });
  // AC-6: exactly one current entry, the page itself
  assert.deepEqual(d.treeCurrent, [o.label(slug, lang)], at("exactly one aria-current=page in the tree"));
  const cur = d.treeItems.find((i) => i.a.current === "page");
  assert.equal(cur?.a.href, route, at("the current tree entry is this page"));

  // AC-9: landmarks
  for (const h of ["site", "language", "pages", "breadcrumb"]) assert.equal(d.hasNav[h], 1, at(`nav[data-nav=${h}] occurs once`));
  assert.equal(d.mains, 1, at("one main"));
  const names = d.navs.map((n) => (n.name ?? "").trim().toLowerCase());
  assert.ok(d.navs.every((n) => (n.name ?? "").trim() !== "" || n.labelledby), at("every nav has a name"));
  assert.equal(new Set(names).size, names.length, at(`nav names are distinct: ${names}`));
  // AC-25 source order: skip link, top bar, tree, main, footer; the tree is not inside main
  assert.deepEqual(d.order, ["skip", "topbar", "tree", "main", "footer"], at("source order"));
  assert.equal(d.mainContains.tree, false, at("tree outside main"));
  assert.equal(d.mainContains.crumb, true, at("breadcrumb inside main"));

  // AC-10: breadcrumb
  const trail = o.crumb(slug, lang);
  assert.deepEqual(d.crumbItems.map((i) => i.own), trail.map((t) => t.label), at("breadcrumb labels"));
  trail.forEach((t, i) => {
    const it = d.crumbItems[i];
    if (i < trail.length - 1) { assert.equal(it.a?.href, t.href, at(`breadcrumb link ${t.label}`)); assert.equal(it.current, null, at("ancestor not current")); }
    else { assert.equal(it.a, null, at("last breadcrumb item is plain text")); assert.equal(it.current, "page", at("last breadcrumb item is current")); }
  });
  if (slug === "") assert.equal(d.crumbItems.length, 1, at("Home breadcrumb shows only itself"));

  // AC-11: contents from the headings of main
  const ids = d.headings.map((h) => h.id);
  assert.ok(ids.every(Boolean) && new Set(ids).size === ids.length, at("every h2/h3 has a unique id"));
  const hasH2 = d.headings.some((h) => h.level === 2);
  if (!hasH2) assert.equal(d.hasNav.contents, 0, at("no contents list without an h2"));
  else {
    assert.equal(d.hasNav.contents, 1, at("contents list present"));
    let seenH2 = false;
    const exp = d.headings.map((h) => { if (h.level === 2) seenH2 = true; return [h.text, `#${h.id}`, h.level === 2 || !seenH2 ? 1 : 2]; });
    assert.deepEqual(d.contentsItems.map((i) => [i.a?.text, i.a?.href, i.depth]), exp, at("contents list = the h2/h3 of main, in order, h3 nested"));
  }

  // AC-13: see-also
  const sa = o.seeAlso(slug, lang);
  if (sa.length === 0) assert.equal(d.hasNav["see-also"], 0, at("no empty see-also"));
  else {
    assert.equal(d.hasNav["see-also"], 1, at("see-also present"));
    assert.deepEqual(d.seeAlsoItems.map((i) => [i.a?.text, i.a?.href]), sa.map((x) => [x.label, x.href]), at("see-also from the page tree, existing pages of this language only"));
    assert.equal(d.mainContains.seeAlso, true, at("see-also inside main"));
  }

  // AC-14 / AC-15 / AC-16: switcher = counterpart, else the other language's Home
  const own = o.href(slug, lang);
  for (const l of ["en", "nl"]) {
    const opt = d.switcher.find((s) => s.dataLang === l);
    assert.ok(opt, at(`switcher option ${l}`));
    const want = l === lang ? own : o.exists(slug, l) ? o.href(slug, l) : o.home(l);
    assert.equal(opt.href, want, at(`switcher ${l} option`));
    assert.equal(opt.current, l === lang ? "true" : null, at(`switcher ${l} marking`));
    assert.equal(opt.hreflang, l, at("switcher hreflang"));
  }
  const alt = new Map(d.alternates.map(([l, h]) => [l, h]));
  if (o.exists(slug, "en") && o.exists(slug, "nl")) {
    assert.ok(alt.get("en")?.endsWith(o.href(slug, "en")) && alt.get("nl")?.endsWith(o.href(slug, "nl")), at("alternates on a page in both languages"));
  } else assert.equal(d.alternates.length, 0, at("no alternates on a one-language page"));

  // Top bar: Reference link from the same data; Dutch pages get the English one
  const refTop = d.topLinks.find((l) => l.href === o.href("reference", "en"));
  if (o.by.has("reference")) {
    assert.ok(refTop, at("top bar Reference link"));
    assert.equal(refTop.text, o.label("reference", "en"), at("top bar Reference label is the English one"));
    if (lang === "nl") { assert.equal(refTop.lang, "en"); assert.equal(refTop.hreflang, "en"); }
  }
  assert.ok(d.topLinks.some((l) => l.href === o.home(lang)), at("site name goes to the Home of the page's language"));

  // AC-21: draft notice
  const draft = lang === "nl" && o.isDraft(slug);
  assert.equal(d.draftNotices.length, draft ? 1 : 0, at(`draft notice ${draft ? "shown" : "absent"}`));
  assert.equal(d.scripts, 1, at("one script only"));
  assert.equal(d.details, 0, at("no details element"));
}

// Reads and checks every page of a build against the model of its page tree. Returns the pages read, by route.
export async function verifyBuild(browser, dist, o, { checks = true } = {}) {
  const srv = await serve(dist);
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  try {
    const files = htmlFiles(dist);
    assert.deepEqual(files.map((f) => routeOf(f)).sort(), o.pages.map((p) => p.route).sort(), "the built pages are exactly the pages of the page tree");
    const pages = {};
    for (const f of files) {
      const route = routeOf(f);
      pages[route] = await readPage(ctx, srv.origin, route);
      if (checks) checkPage(pages[route], route, o);
    }
    return pages;
  } finally { await ctx.close(); await srv.close(); }
}
