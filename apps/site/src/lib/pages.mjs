// The page tree model: the only module that reads src/data/pages.mjs, validates it and derives from it.
// Contract: contracts/188-page-tree.md. Plain Node, no Astro imports, so it can be unit tested and run from the config.
import fs from "node:fs";
import path from "node:path";
import { pages as defaultPages } from "../data/pages.mjs";

export const LANGS = ["en", "nl"];
const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const viteEnv = import.meta.env;
const CONTENT_ROOT = "src/content/pages";

const label = (slug) => (slug === "" ? "(home)" : String(slug));

// Heading ids the way the Markdown renderer slugs them (lower case, punctuation dropped, spaces to hyphens).
export function slugOfHeading(text) {
  return text
    .replace(/`([^`]*)`/g, "$1")
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/[*_]/g, "")
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{M}\p{N}\p{Pc} -]/gu, "")
    .replace(/ /g, "-");
}

// Text of a content file with fenced code blocks and inline code removed.
function outsideCode(text) {
  return text.replace(/^(```|~~~)[\s\S]*?^\1[^\n]*$/gm, "").replace(/`[^`\n]*`/g, "");
}

export function layoutFaults(text) {
  const t = outsideCode(text);
  const faults = [];
  if (/(^|[\s<"'])style\s*=/i.test(t)) faults.push("holds a style attribute");
  if (/(^|[\s<"'])class\s*=/i.test(t)) faults.push("holds a class attribute");
  if (/<\s*(div|span|style)\b/i.test(t)) faults.push("holds a layout tag (div, span or style)");
  if (/(^|[^&\w])#[0-9a-fA-F]{3,8}\b|\b(rgb|hsl)a?\(/.test(t.replace(/\]\(#[^)]*\)/g, ""))) faults.push("holds a colour literal");
  if (/^# /m.test(t)) faults.push("holds a level-1 heading (the layout renders the one h1)");
  return faults;
}

export function headingIdFaults(ids) {
  const seen = new Set();
  const out = [];
  for (const id of ids) {
    if (seen.has(id) && !out.includes(id)) out.push(id);
    seen.add(id);
  }
  return out;
}

function listMarkdown(dir) {
  try {
    return fs.readdirSync(dir).filter((f) => f.endsWith(".md")).sort();
  } catch {
    return [];
  }
}

export function loadPages(entries = defaultPages, opts = {}) {
  const contentDir = opts.contentDir ?? path.resolve(process.cwd(), CONTENT_ROOT);
  const base = String(opts.base ?? viteEnv?.BASE_URL ?? "").replace(/\/+$/, "");
  const componentKeys = opts.componentKeys ?? null;
  const faults = [];
  const fail = (slug, why) => faults.push(`pages: ${label(slug)}: ${why}`);
  const failFile = (rel, why) => faults.push(`pages: ${rel}: ${why}`);

  // Phase 1: each entry on its own.
  const by = new Map();
  for (const e of entries) {
    if (by.has(e.slug)) { fail(e.slug, "duplicate slug"); continue; }
    by.set(e.slug, e);
    if (e.slug === "nl") fail(e.slug, "reserved slug");
    else if (e.slug !== "" && !SLUG.test(e.slug)) fail(e.slug, "invalid slug");
    if (!e.title?.en) fail(e.slug, "missing English title");
    if (e.source !== "markdown" && e.source !== "component") fail(e.slug, `invalid source "${e.source}"`);
  }
  if (faults.length) throw new Error(faults.join("\n"));

  const exists = (slug, lang) => Boolean(by.get(slug)?.title?.[lang]);

  // Phase 2: the tree as a whole.
  for (const e of by.values()) {
    if (e.slug === "") {
      if (e.parent !== null) fail(e.slug, `Home must have parent null`);
    } else if (typeof e.parent !== "string" || !by.has(e.parent)) {
      fail(e.slug, `parent "${e.parent}" does not exist`);
    } else {
      const chain = new Set([e.slug]);
      for (let p = e.parent; p !== null && p !== undefined; p = by.get(p)?.parent) {
        if (chain.has(p)) { fail(e.slug, "parent cycle"); break; }
        chain.add(p);
      }
    }
    for (const s of e.seeAlso ?? []) if (!by.has(s)) fail(e.slug, `see-also "${s}" does not exist`);
    for (const l of LANGS) {
      if (exists(e.slug, l) && e.slug !== "" && typeof e.parent === "string" && by.has(e.parent) && !exists(e.parent, l)) {
        fail(e.slug, `parent "${e.parent}" has no ${l} page`);
      }
    }
    if (e.source === "component") {
      if (!e.component || (componentKeys && !componentKeys.includes(e.component))) fail(e.slug, `unknown component "${e.component}"`);
    }
    for (const l of e.alsoListedIn ?? []) if (exists(e.slug, l)) fail(e.slug, `alsoListedIn conflicts with title.${l}`);
    if (e.review !== undefined) {
      if (!exists(e.slug, "nl")) fail(e.slug, "review status on a page with no Dutch title");
      const v = e.review?.nl;
      if (v !== undefined && v !== "draft" && v !== "reviewed") fail(e.slug, `review.nl "${v}" must be "draft" or "reviewed"`);
    }
  }
  if (faults.length) throw new Error(faults.join("\n"));

  // Phase 3: content files of the hand-written pages.
  const inTree = (p) => {
    const m = /^\/(nl\/)?([a-z0-9-]*)\/?$/.exec(p);
    if (!m || !p.endsWith("/")) return false;
    const target = m[1] ? "nl" : "en";
    return exists(m[2], target);
  };
  for (const l of LANGS) {
    const want = new Set();
    for (const e of by.values()) {
      if (e.source !== "markdown" || !exists(e.slug, l)) continue;
      const rel = `${CONTENT_ROOT}/${l}/${e.slug}.md`;
      want.add(`${e.slug}.md`);
      const file = path.join(contentDir, l, `${e.slug}.md`);
      if (!fs.existsSync(file)) { fail(e.slug, `missing content file ${rel}`); continue; }
      const text = fs.readFileSync(file, "utf8");
      for (const f of layoutFaults(text)) failFile(rel, f);
      const body = outsideCode(text);
      const ids = [...body.matchAll(/^#{2,3}[ \t]+(.+?)[ \t#]*$/gm)].map((m) => slugOfHeading(m[1]));
      for (const id of headingIdFaults(ids)) fail(e.slug, `duplicate heading id "${id}"`);
      for (const m of body.matchAll(/\]\((\/[^)\s]*)\)/g)) {
        const p = m[1].split(/[#?]/)[0];
        if (!p.startsWith("//") && !inTree(p)) failFile(rel, `body link "${m[1]}" is not a page of the page tree`);
      }
    }
    for (const f of listMarkdown(path.join(contentDir, l))) {
      if (!want.has(f)) faults.push(`pages: content file ${CONTENT_ROOT}/${l}/${f} has no page tree entry`);
    }
  }
  if (faults.length) throw new Error(faults.join("\n"));

  // ---- derived structures ----
  const href = (slug, lang) => `${base}/${lang === "nl" ? "nl/" : ""}${slug === "" ? "" : `${slug}/`}`;
  const listed = (slug, lang) => exists(slug, lang) || Boolean(by.get(slug)?.alsoListedIn?.includes(lang));
  const title = (slug, lang) => by.get(slug).title[lang];
  const heading = (slug, lang) => by.get(slug).heading?.[lang] || title(slug, lang);
  // A link to a page listed in `lang`: the page itself, or (listed, not built) the English page, marked as English.
  const link = (slug, lang) =>
    exists(slug, lang)
      ? { slug, href: href(slug, lang), label: title(slug, lang) }
      : { slug, href: href(slug, "en"), label: title(slug, "en"), lang: "en", hreflang: "en" };
  const children = (slug) => [...by.values()].filter((e) => e.parent === slug && e.slug !== "");
  const tree = (lang) => {
    const node = (slug) => ({ ...link(slug, lang), children: children(slug).filter((c) => listed(c.slug, lang)).map((c) => node(c.slug)) });
    return listed("", lang) ? [node("")] : [];
  };
  const breadcrumb = (slug, lang) => {
    const chain = [];
    for (let s = slug; s !== null && s !== undefined; s = by.get(s).parent) chain.unshift(s);
    return chain.map((s) => ({ slug: s, href: href(s, lang), label: title(s, lang) }));
  };
  const seeAlso = (slug, lang) => (by.get(slug).seeAlso ?? []).filter((s) => exists(s, lang)).map((s) => ({ slug: s, href: href(s, lang), label: title(s, lang) }));
  const counterpart = (slug, lang) => {
    const other = lang === "en" ? "nl" : "en";
    return exists(slug, other) ? slug : null;
  };
  const switchHref = (slug, from, to) => (from === to ? href(slug, to) : exists(slug, to) ? href(slug, to) : href("", to));
  const isDraft = (slug) => exists(slug, "nl") && by.get(slug).review?.nl !== "reviewed";
  const drafts = () => [...by.values()].filter((e) => isDraft(e.slug)).map((e) => href(e.slug, "nl")).sort();

  return {
    base,
    entry: (slug) => by.get(slug),
    exists,
    href,
    title,
    heading,
    link,
    tree,
    breadcrumb,
    seeAlso,
    counterpart,
    switchHref,
    isDraft,
    drafts,
    routes: (lang) => [...by.values()].filter((e) => exists(e.slug, lang)).map((e) => e.slug),
    draftLine: () => `pages: dutch drafts: ${drafts().join(" ") || "none"}`,
  };
}

let memo;
export function getModel(opts) {
  memo ??= loadPages(undefined, opts);
  return memo;
}
