// AC-19, AC-20, AC-22: Getting started in English and Dutch, checked against the repository's real names.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { BASE, REPO, SITE, PLUGINS, realBuild, serve, launch, skillSources, parseFrontmatter } from "./lib.mjs";

let srv, browser, ctx, en, nl;
const READ = () => {
  const main = document.querySelector("main");
  const t = (e) => e.textContent.trim().replace(/\s+/g, " ");
  const steps = [];
  let cur = null;
  for (const e of main.querySelectorAll("h2, pre")) {
    if (e.tagName === "H2") { cur = { h2: t(e), code: [] }; steps.push(cur); } else if (cur && !e.closest("nav")) cur.code.push(e.textContent.replace(/\s+$/, ""));
  }
  const body = [...main.querySelectorAll("p, h2, h3, li")].filter((e) => !e.closest("nav") && !e.hasAttribute("data-draft-notice"));
  return {
    lang: document.documentElement.lang,
    h1: [...document.querySelectorAll("h1")].map(t),
    steps,
    paras: [...main.querySelectorAll("p")].filter((e) => !e.closest("nav") && !e.hasAttribute("data-draft-notice")).map(t),
    bodyLinks: [...main.querySelectorAll("a[href]")].filter((a) => !a.closest("nav")).map((a) => a.getAttribute("href")),
    headings: [...main.querySelectorAll("h2, h3")].map(t),
    notes: body.length,
  };
};
before(async () => {
  const dist = realBuild();
  srv = await serve(dist);
  browser = await launch();
  ctx = await browser.newContext();
  const read = async (route) => { const p = await ctx.newPage(); await p.goto(srv.origin + route); const d = await p.evaluate(READ); await p.close(); return d; };
  en = await read(`${BASE}/getting-started/`);
  nl = await read(`${BASE}/nl/getting-started/`);
});
after(async () => { await ctx?.close(); await browser?.close(); await srv?.close(); });

// Commands: what the page names must exist in the repository.
export function commandsIn(codeBlocks) {
  const text = codeBlocks.join("\n");
  return {
    slash: [...text.matchAll(/(?:^|[\s`"'(])\/([a-z][a-z0-9-]*):([a-z][a-z0-9-]*)/gm)].map((m) => ({ plugin: m[1], skill: m[2] })),
    installs: [...text.matchAll(/\binstall\s+([a-z][a-z0-9-]*)@([a-z][a-z0-9-]*)/g)].map((m) => ({ plugin: m[1], marketplace: m[2] })),
    text,
  };
}
export function unknownCommands(codeBlocks, sources = skillSources(PLUGINS), pluginsDir = PLUGINS) {
  const c = commandsIn(codeBlocks);
  const bad = [];
  const names = new Set(sources.map((s) => `${s.plugin}:${s.folder}`));
  for (const s of sources) { try { names.add(`${s.plugin}:${parseFrontmatter(s.file).name}`); } catch {} }
  for (const { plugin, skill } of c.slash) if (!names.has(`${plugin}:${skill}`)) bad.push(`/${plugin}:${skill}`);
  for (const { plugin, marketplace } of c.installs) {
    if (!fs.existsSync(path.join(pluginsDir, plugin, ".claude-plugin", "plugin.json")) && !fs.existsSync(path.join(pluginsDir, plugin))) bad.push(`install ${plugin}`);
    if (marketplace !== "wimsuenens") bad.push(`marketplace ${marketplace}`);
  }
  return bad;
}

test("AC-19 English: html lang en, one h1 'Getting started', four h2 steps in the prototype's order, each with code", () => {
  assert.equal(en.lang, "en");
  assert.deepEqual(en.h1, ["Getting started"]);
  assert.equal(en.steps.length, 4);
  const order = [/marketplace/i, /install/i, /repositor|repo\b|set up/i, /first command/i];
  order.forEach((re, i) => assert.match(en.steps[i].h2, re, `step ${i + 1}: ${en.steps[i].h2}`));
  for (const s of en.steps) assert.ok(s.code.length >= 1, `step "${s.h2}" shows its commands in a code block`);
});

test("AC-19 the commands are the prototype's and name the real repository: marketplace source, marketplace name, and every /plugin:skill exists as plugins/<plugin>/skills/<skill>/SKILL.md", () => {
  const code = en.steps.flatMap((s) => s.code);
  const c = commandsIn(code);
  assert.ok(c.text.includes("WimSuenens/agent-plugins"), "the marketplace source");
  assert.ok(/\bmarketplace add\b/.test(c.text), "step one adds the marketplace");
  assert.ok(/@wimsuenens\b/.test(c.text), "plugins are installed from the marketplace named wimsuenens");
  assert.ok(c.installs.length >= 1, "at least one install command");
  assert.ok(c.slash.length >= 1, "step four runs a /plugin:skill command");
  assert.deepEqual(unknownCommands(code), []);
  const nlSteps = nl.steps.flatMap((s) => s.code);
  assert.deepEqual(unknownCommands(nlSteps), [], "the Dutch page names no command that does not exist either");
  assert.ok(skillSources(PLUGINS).length > 0 && fs.existsSync(path.join(REPO, "plugins")));
});

test("AC-19 control: the command check flags a command that does not exist, a plugin that does not exist and a wrong marketplace", () => {
  const bad = unknownCommands(["/factory:no-such-skill\n/nosuch:idea\nclaude plugin install nosuch@wimsuenens\nclaude plugin install factory@other"]);
  assert.deepEqual(bad.sort(), ["/factory:no-such-skill", "/nosuch:idea", "install nosuch", "marketplace other"].sort());
  assert.deepEqual(unknownCommands(["/factory:idea"]), []);
});

test("AC-20 Dutch mirrors English: html lang nl, one h1, same h2 count and order, identical code blocks, same links, Dutch prose", () => {
  assert.equal(nl.lang, "nl");
  assert.equal(nl.h1.length, 1);
  assert.notEqual(nl.h1[0], en.h1[0], "the h1 is Dutch");
  assert.equal(nl.steps.length, en.steps.length);
  assert.deepEqual(nl.steps.map((s) => s.code), en.steps.map((s) => s.code), "code blocks are identical to the English ones");
  nl.steps.forEach((s, i) => assert.notEqual(s.h2, en.steps[i].h2, `h2 #${i + 1} is Dutch`));
  assert.equal(nl.bodyLinks.length, en.bodyLinks.length, "the same number of links");
  assert.equal(nl.paras.length, en.paras.length, "the same paragraphs");
  nl.paras.forEach((p, i) => { if (p.split(" ").length >= 3) assert.notEqual(p, en.paras[i], `paragraph #${i + 1} is still English`); });
});

test("AC-20 the Dutch body links point at Dutch pages where a Dutch page exists, and never at a missing one", () => {
  for (const h of nl.bodyLinks) assert.ok(h.startsWith(`${BASE}/`) && h.endsWith("/") || h.startsWith("#") || /^https?:/.test(h), h);
  assert.ok(!nl.bodyLinks.includes(`${BASE}/nl/reference/`));
});

// AC-22: the content files hold no layout markup.
const CONTENT = path.join(SITE, "src/content/pages");
export function layoutFaults(text) {
  const noCode = text.replace(/^(```|~~~)[\s\S]*?^\1/gm, "").replace(/`[^`\n]*`/g, "");
  const f = [];
  if (/(^|[\s<"'])style\s*=/i.test(noCode)) f.push("style attribute");
  if (/(^|[\s<"'])class\s*=/i.test(noCode)) f.push("class attribute");
  if (/<\s*(div|span|style)\b/i.test(noCode)) f.push("layout tag");
  if (/(^|[^&\w])#[0-9a-fA-F]{3,8}\b|\b(rgb|hsl)a?\(/.test(noCode.replace(/\]\(#[^)]*\)/g, ""))) f.push("colour literal");
  if (/^# /m.test(noCode)) f.push("level-1 heading");
  return f;
}
for (const lang of ["en", "nl"]) {
  test(`AC-22 content/pages/${lang}/getting-started.md holds prose, headings, lists, code and links only`, () => {
    const file = path.join(CONTENT, lang, "getting-started.md");
    assert.ok(fs.existsSync(file), "the content file exists where the contract says");
    assert.deepEqual(layoutFaults(fs.readFileSync(file, "utf8")), []);
  });
}
test("AC-22 control: the layout lint flags each kind of layout markup and ignores the same text inside code", () => {
  for (const [text, kind] of [['<p style="x">', "style attribute"], ['<p class="x">', "class attribute"], ["<div>x</div>", "layout tag"], ["colour #c0ffee", "colour literal"], ["rgb(1,2,3)", "colour literal"], ["# Title", "level-1 heading"]]) {
    assert.ok(layoutFaults(text).includes(kind), `${text} -> ${kind}`);
  }
  assert.deepEqual(layoutFaults("Use `<div class=\"x\">` and\n\n```html\n<div style=\"color:#fff\">\n```\n[link](#frag)\n"), []);
});
test("AC-22 every content file under content/pages is free of layout markup (any page added later too)", () => {
  const out = [];
  (function walk(d) { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith(".md")) out.push(...layoutFaults(fs.readFileSync(p, "utf8")).map((x) => `${path.relative(CONTENT, p)}: ${x}`)); } })(CONTENT);
  assert.deepEqual(out, []);
});
