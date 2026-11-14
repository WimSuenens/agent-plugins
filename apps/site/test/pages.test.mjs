import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { loadPages, layoutFaults, headingIdFaults, slugOfHeading } from "../src/lib/pages.mjs";
import { rehypePage } from "../src/lib/rehypePage.mjs";

const content = (files) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pages-unit-"));
  for (const [rel, text] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.writeFileSync(path.join(dir, rel), text);
  }
  return dir;
};
const home = { slug: "", parent: null, title: { en: "Home", nl: "Thuis" }, source: "component", component: "home", seeAlso: ["a", "ref"] };
const a = { slug: "a", parent: "", title: { en: "A", nl: "Aa" }, source: "markdown", seeAlso: ["ref", ""], review: { nl: "draft" } };
const ref = { slug: "ref", parent: "", title: { en: "Ref" }, source: "component", component: "reference", alsoListedIn: ["nl"] };
const dir = () => content({ "en/a.md": "## One\n\ntext\n", "nl/a.md": "## Een\n\ntekst\n" });
const load = (entries, files) => loadPages(entries, { contentDir: files ? content(files) : dir(), base: "/b" });

test("derives urls, tree, breadcrumb, see-also and counterpart from the entries", () => {
  const m = load([home, a, ref]);
  assert.equal(m.href("", "nl"), "/b/nl/");
  assert.equal(m.href("a", "en"), "/b/a/");
  assert.deepEqual(m.routes("nl"), ["", "a"]);
  assert.deepEqual(m.tree("nl")[0].children.map((c) => [c.label, c.href, c.lang]), [["Aa", "/b/nl/a/", undefined], ["Ref", "/b/ref/", "en"]]);
  assert.deepEqual(m.breadcrumb("a", "nl").map((c) => c.label), ["Thuis", "Aa"]);
  assert.deepEqual(m.seeAlso("a", "nl").map((c) => c.href), ["/b/nl/"], "a slug with no Dutch page is left out");
  assert.equal(m.switchHref("ref", "en", "nl"), "/b/nl/");
  assert.equal(m.switchHref("a", "en", "nl"), "/b/nl/a/");
  assert.equal(m.counterpart("ref", "en"), null);
});

test("drafts: a Dutch page is a draft unless reviewed", () => {
  assert.deepEqual(load([home, a, ref]).drafts(), ["/b/nl/", "/b/nl/a/"]);
  assert.equal(load([home, { ...a, review: { nl: "reviewed" } }, ref]).draftLine(), "pages: dutch drafts: /b/nl/");
  assert.equal(load([{ ...home, review: { nl: "reviewed" } }, { ...a, review: { nl: "reviewed" } }, ref]).draftLine(), "pages: dutch drafts: none");
});

test("faults name the entry", () => {
  assert.throws(() => load([home, a, a, ref]), /pages: a: duplicate slug/);
  assert.throws(() => load([home, { ...a, parent: "zz" }, ref]), /pages: a: parent "zz" does not exist/);
  assert.throws(() => load([home, { ...a, seeAlso: ["zz"] }, ref]), /pages: a: see-also "zz" does not exist/);
  assert.throws(() => load([home, { ...a, slug: "nl" }, ref]), /reserved slug/);
  assert.throws(() => load([home, a, ref], { "en/a.md": "## x\n" }), /missing content file src\/content\/pages\/nl\/a\.md/);
  assert.throws(() => load([home, a, ref], { "en/a.md": "## x\n", "nl/a.md": "## x\n", "en/z.md": "## x\n" }), /content file src\/content\/pages\/en\/z\.md has no page tree entry/);
});

test("content faults name the file; code is exempt", () => {
  assert.throws(() => load([home, a, ref], { "en/a.md": "# T\n", "nl/a.md": "## x\n" }), /src\/content\/pages\/en\/a\.md: holds a level-1 heading/);
  assert.throws(() => load([home, a, ref], { "en/a.md": "[x](/nope/)\n", "nl/a.md": "## x\n" }), /body link "\/nope\/"/);
  assert.deepEqual(layoutFaults("```\n<div style=\"color:#fff\">\n```\nand `class=x`\n[l](#abc)\n"), []);
  assert.deepEqual(layoutFaults("<p style=\"x\">"), ["holds a style attribute"]);
});

test("heading ids", () => {
  assert.equal(slugOfHeading("Set up your repository, once"), "set-up-your-repository-once");
  assert.deepEqual(headingIdFaults(["a", "b", "a", "a"]), ["a"]);
});

test("the hast step prefixes site-root links and focuses pre blocks", () => {
  const calls = [];
  const ctx = { setProperty: (n, k, v) => calls.push([n.tagName, k, v]) };
  const { element } = rehypePage({ base: "/b/" });
  element.visit({ tagName: "pre" }, ctx);
  element.visit({ tagName: "a", properties: { href: "/x/" } }, ctx);
  element.visit({ tagName: "a", properties: { href: "https://e.org/" } }, ctx);
  element.visit({ tagName: "a", properties: { href: "#h" } }, ctx);
  assert.deepEqual(calls, [["pre", "tabIndex", 0], ["a", "href", "/b/x/"]]);
});

test("the real page tree: Reference has Dutch Skills and Agents children, in that order, all Dutch drafts", async () => {
  const { pages } = await import("../src/data/pages.mjs");
  const m = loadPages(pages, { base: "/b", componentKeys: ["home", "reference", "skills", "agents"] });
  const ref = m.tree("nl")[0].children.find((c) => c.slug === "reference");
  assert.equal(ref.label, "Naslag");
  assert.equal(ref.lang, undefined, "a real Dutch link, not an English one");
  assert.deepEqual(ref.children.map((c) => [c.slug, c.label, c.lang]), [["skills", "Vaardigheden", undefined], ["agents", "Agenten", undefined]]);
  assert.deepEqual(m.tree("en")[0].children.find((c) => c.slug === "reference").children.map((c) => c.slug), ["skills", "agents"]);
  assert.deepEqual(m.breadcrumb("skills", "nl").map((c) => c.label), ["Thuis", "Naslag", "Vaardigheden"]);
  assert.equal(m.switchHref("agents", "en", "nl"), "/b/nl/agents/");
  for (const slug of ["reference", "skills", "agents"]) assert.ok(m.drafts().includes(`/b/nl/${slug}/`), slug);
});
