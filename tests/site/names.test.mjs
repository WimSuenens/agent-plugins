// Slice 244: every backticked name and path on a hand-written page is verified (widens AC-19 of 188).
// Files only, no browser; AC-7 reads the built HTML of the two pages and so needs a site build.
// Run: node --test tests/site/names.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { PLUGINS, realBuild, scratch, skillSources } from "./lib.mjs";
import {
  CONTENT, fencedBlocks, inlineSpans, backtickedTokens, agentPathsIn, skillText, unknownAgentPaths,
  unknownNames, handWrittenPages, pageFaults, unknownCommands,
} from "./names.mjs";

const page = (text, label = "en/p.md") => [{ label, text }];
const faults = (text, opts, label) => pageFaults(page(text, label), opts);
const read = (rel) => fs.readFileSync(path.join(CONTENT, rel), "utf8");
const AG = "docs/agents";

// ---- The tokenizer (contract section 1)

test("tokenizer: inline spans, fenced blocks and their order; text outside backticks is no token", () => {
  const md = "Run `a b` now, then `c`.\n\n```sh\nx y\nz\n```\n\nAfter `d`.\n\nplain /x:y here\n";
  assert.deepEqual(inlineSpans(md), ["a b", "c", "d"]);
  assert.deepEqual(fencedBlocks(md), ["x y\nz"]);
  assert.deepEqual(backtickedTokens(md), ["a b", "c", "x y\nz", "d"]);
});

test("tokenizer edges: link text, double backtick, escaped backtick, wrapped line, space strip, unmatched run", () => {
  assert.deepEqual(inlineSpans("[`factory:idea`](/x:y/) and [a](/b:c/)"), ["factory:idea"]);
  assert.deepEqual(inlineSpans("``a `b` c`` after"), ["a `b` c"]);
  assert.deepEqual(inlineSpans("\\`/x:y\\` nothing"), []);
  assert.deepEqual(inlineSpans("`a\\` then `b`"), ["a\\", "b"], "a backslash inside a span is literal");
  assert.deepEqual(inlineSpans("`one\ntwo` end"), ["one two"], "a span wrapped over a line is one token with a single space");
  assert.deepEqual(inlineSpans("`` `x` `` end"), ["`x`"], "one leading and one trailing space are stripped");
  assert.deepEqual(inlineSpans("a ``` b `c`"), ["c"], "a run with no closer is literal text");
  assert.deepEqual(inlineSpans("a `unclosed\n\nb `ok`"), ["ok"], "a span does not cross a blank line");
});

test("tokenizer fences: ``` and ~~~, any indent, info string ignored, closing length, unclosed to the end, spans inside a fence are not read again", () => {
  assert.deepEqual(fencedBlocks("```sh\na\n```\n~~~\nb\n~~~\n   ```\nc\n   ```"), ["a", "b", "c"]);
  assert.deepEqual(fencedBlocks("````\n```\ninner\n```\n````\n"), ["```\ninner\n```"], "a shorter run does not close");
  assert.deepEqual(fencedBlocks("```\n~~~\nx\n```"), ["~~~\nx"], "another character does not close");
  assert.deepEqual(fencedBlocks("```\nno end\nstill"), ["no end\nstill"]);
  assert.deepEqual(inlineSpans("```\nuse `/x:y` here\n```\n"), []);
  assert.deepEqual(backtickedTokens("```\nuse `/x:y` here\n```\n"), ["use `/x:y` here"]);
});

test("tokenizer: front matter is skipped", () => {
  assert.deepEqual(backtickedTokens("---\ntitle: `/x:y`\n---\nbody `a`\n"), ["a"]);
});

test("tokenizer: indented code, HTML blocks, autolinks and link destinations are not tokens", () => {
  assert.deepEqual(backtickedTokens("    /x:y indented\n\n<https://e.org/a:b> [t](/x:y/ \"title\")\n"), []);
});

// ---- The path rule

test("agentPathsIn: single segment docs/agents/<name>.md with a left boundary", () => {
  assert.deepEqual(agentPathsIn([`${AG}/factory.md`, `see ${AG}/a_b-c.md and (${AG}/d.md)`]), [`${AG}/factory.md`, `${AG}/a_b-c.md`, `${AG}/d.md`]);
  for (const t of [`${AG}/sub/x.md`, `${AG}/sub/`, "docs/adr/0001.md", "apps/site/x.md", `x${AG}/f.md`, `./${AG}/f.md`, `/${AG}/f.md`, `a-${AG}/f.md`, `${AG}/f.txt`]) {
    assert.deepEqual(agentPathsIn([t]), [], t);
  }
});

test("skillText: reads SKILL.md files only, skips dot folders and node_modules, joins with NUL; unknownAgentPaths asks it", () => {
  const dir = scratch("names-skill-");
  const w = (rel, s) => { const f = path.join(dir, rel); fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, s); };
  w("p/skills/a/SKILL.md", `ALPHA ${AG}/in-skill.md`);
  w("q/skills/b/SKILL.md", "BETA");
  w("p/README.md", `${AG}/in-readme.md`);
  w("p/references/x.md", `${AG}/in-reference.md`);
  w("p/agents/ag.md", `${AG}/in-agent.md`);
  w(".hidden/skills/c/SKILL.md", `${AG}/in-hidden.md`);
  w("p/node_modules/m/SKILL.md", `${AG}/in-modules.md`);
  const t = skillText(dir);
  assert.deepEqual(t.split("\0").sort(), [`ALPHA ${AG}/in-skill.md`, "BETA"]);
  const all = ["in-skill", "in-readme", "in-reference", "in-agent", "in-hidden", "in-modules", "nope"].map((n) => `${AG}/${n}.md`);
  assert.deepEqual(unknownAgentPaths(all, t), all.slice(1), "only a SKILL.md counts");
  assert.deepEqual(unknownAgentPaths([`${AG}/x.md`], ""), [`${AG}/x.md`]);
});

test("the real skills hold docs/agents/factory.md (the path rule's source is the real SKILL.md files)", () => {
  assert.ok(skillText().includes(`${AG}/factory.md`));
});

// ---- Control tests per rule (AC-4), AC-1 to AC-3, AC-8, AC-9

test("AC-1/4a control: a nonexistent /plugin:skill in an inline span is reported with the page; an existing one is not", () => {
  assert.deepEqual(faults("Run `/factory:no-such-skill` now."), ["en/p.md: /factory:no-such-skill"]);
  assert.deepEqual(faults("Run `/factory:idea` now."), []);
  assert.deepEqual(faults("Use `/nosuch:idea`."), ["en/p.md: /nosuch:idea"]);
  assert.deepEqual(faults("Run `/factory:idea`, `/factory:gone` and `/wayfinding:wayfinder`."), ["en/p.md: /factory:gone"]);
});

test("AC-2/4b control: an install target in an inline span: unknown plugin, wrong marketplace, listed plugin", () => {
  assert.deepEqual(faults("`claude plugin install nosuch@wimsuenens`"), ["en/p.md: install nosuch"]);
  assert.deepEqual(faults("`claude plugin install factory@other`"), ["en/p.md: marketplace other"]);
  assert.deepEqual(faults("`claude plugin install wayfinding@wimsuenens`"), []);
  assert.deepEqual(faults("`claude plugin install mattpocock-skills@wimsuenens`"), [], "an upstream plugin listed in marketplace.json passes");
  assert.deepEqual(faults("`claude plugin install mattpocock-skills@wimsuenens`", { listed: new Set() }), ["en/p.md: install mattpocock-skills"]);
});

test("AC-3/4c control: a nonexistent docs/agents/<name>.md is reported in an inline span and in a code block; factory.md is not", () => {
  assert.deepEqual(faults(`See \`${AG}/nope.md\`.`), [`en/p.md: ${AG}/nope.md`]);
  assert.deepEqual(faults(`\`\`\`\ncat ${AG}/nope.md\n\`\`\`\n`), [`en/p.md: ${AG}/nope.md`]);
  assert.deepEqual(faults(`\`\`\`\ncat ${AG}/factory.md\n\`\`\`\n`), []);
  assert.deepEqual(faults(`\`${AG}/factory.md\``), []);
});

test("AC-3 a command, an install and a path in a code block are all reported (command, install, path order)", () => {
  assert.deepEqual(
    faults(`\`\`\`\n/factory:gone\nclaude plugin install nosuch@wimsuenens\ncat ${AG}/nope.md\n\`\`\`\n`),
    ["en/p.md: /factory:gone", "en/p.md: install nosuch", `en/p.md: ${AG}/nope.md`],
  );
});

test("AC-8 look-alikes are not reported: no-plugin commands, tool sentences, env vars, shell commands, bare names, other paths, URLs", () => {
  const spans = [
    "/reload-plugins", "/plugin marketplace add x/y", "Run /reload-plugins to activate.", "CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1",
    "claude plugin marketplace add WimSuenens/agent-plugins", "wayfinding", "mattpocock-skills", "wimsuenens", "gh",
    "https://example.org/a:b", "docs/adr/0001.md", "apps/site/x.md", `${AG}/sub/x.md`,
  ];
  assert.deepEqual(faults(spans.map((s) => `\`${s}\``).join(" and ")), []);
});

test("AC-1 only backticked text is a token: the same look-alikes as plain text with a bad /x:y report nothing", () => {
  assert.deepEqual(faults(`Plain /x:y and install nosuch@other and ${AG}/nope.md, Run /reload-plugins. [t](/x:y/) <https://e.org/a:b>\n`), []);
  assert.deepEqual(faults("Plain \\`/x:y\\` escaped."), []);
});

test("AC-4d control: a bad token only in the Dutch page is reported with nl/getting-started.md named (command, install, path)", () => {
  const nl = read("nl/getting-started.md");
  const label = "nl/getting-started.md";
  assert.deepEqual(pageFaults([{ label, text: nl }]), [], "the unchanged page is clean");
  for (const [from, to, fault] of [
    ["/wayfinding:wayfinder", "/wayfinding:no-such", "/wayfinding:no-such"],
    ["install wayfinding@wimsuenens", "install nosuch@wimsuenens", "install nosuch"],
    ["install factory@wimsuenens", "install factory@other", "marketplace other"],
    [`${AG}/factory.md`, `${AG}/nope.md`, `${AG}/nope.md`],
  ]) {
    assert.ok(nl.includes(from), `the Dutch page holds ${from}`);
    assert.deepEqual(pageFaults([{ label, text: nl.replace(from, to) }]), [`${label}: ${fault}`]);
  }
  const en = read("en/getting-started.md");
  assert.deepEqual(pageFaults([{ label, text: en.replace("/wayfinding:wayfinder", "/wayfinding:no-such") }]), [`${label}: /wayfinding:no-such`]);
});

test("AC-9 worked example: three faults in order, each naming the page and the token", () => {
  const text = `Het tweede schrijft \`${AG}/setup.md\`. Draai \`/factory:run-everything\`.\n\n\`\`\`\nclaude plugin install factory@other\n\`\`\`\n`;
  assert.deepEqual(backtickedTokens(text), [`${AG}/setup.md`, "/factory:run-everything", "claude plugin install factory@other"]);
  assert.deepEqual(pageFaults([{ label: "nl/getting-started.md", text }]), [
    "nl/getting-started.md: /factory:run-everything",
    "nl/getting-started.md: marketplace other",
    `nl/getting-started.md: ${AG}/setup.md`,
  ]);
});

test("AC-9 pageFaults keeps page order and token order and does not de-duplicate", () => {
  const pages = [{ label: "en/b.md", text: "`/x:one` `/x:one`" }, { label: "nl/a.md", text: "`/x:two`" }];
  assert.deepEqual(pageFaults(pages), ["en/b.md: /x:one", "en/b.md: /x:one", "nl/a.md: /x:two"]);
});

test("AC-10 control: the path rule asks the SKILL.md files of a copy, not a list", () => {
  const copy = scratch("names-plugins-");
  fs.cpSync(PLUGINS, copy, { recursive: true });
  const skills = [];
  (function walk(d) { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name === "SKILL.md") skills.push(p); } })(copy);
  assert.ok(skills.length > 0);
  const target = `${AG}/factory.md`;
  let held = 0;
  for (const f of skills) { const s = fs.readFileSync(f, "utf8"); if (s.includes(target)) { held++; fs.writeFileSync(f, s.split(target).join(`${AG}/moved.md`)); } }
  assert.ok(held > 0, "the real skills mention the path");
  const opts = { pluginsDir: copy };
  assert.deepEqual(unknownNames([target], opts), [target], "reported once no SKILL.md mentions it");
  assert.deepEqual(faults(`\`${target}\``, opts), [`en/p.md: ${target}`]);
  // only a README or a reference file holds it: still reported
  fs.writeFileSync(path.join(copy, "README.md"), target);
  const plug = fs.readdirSync(copy).find((n) => fs.existsSync(path.join(copy, n, "skills")));
  fs.mkdirSync(path.join(copy, plug, "references"), { recursive: true });
  fs.writeFileSync(path.join(copy, plug, "references", "x.md"), target);
  fs.writeFileSync(path.join(copy, plug, "README.md"), target);
  assert.deepEqual(unknownNames([target], opts), [target]);
  // one SKILL.md mentions it again: cleared
  fs.appendFileSync(skills[0], `\nwrites ${target}\n`);
  assert.deepEqual(unknownNames([target], opts), []);
  assert.deepEqual(faults(`\`${target}\``, opts), []);
});

test("unknownNames: the command and install results are those of unknownCommands, then the paths", () => {
  const tok = ["/factory:no-such-skill\n/nosuch:idea\nclaude plugin install nosuch@wimsuenens\nclaude plugin install factory@other", `${AG}/nope.md`];
  assert.deepEqual(unknownNames(tok), [...unknownCommands([tok[0]]), `${AG}/nope.md`]);
  assert.deepEqual(unknownNames(tok).sort(), ["/factory:no-such-skill", "/nosuch:idea", "install nosuch", "marketplace other", `${AG}/nope.md`].sort());
  assert.deepEqual(unknownNames(["/factory:idea"]), []);
  assert.deepEqual(unknownNames(["claude plugin install mattpocock-skills@wimsuenens"]), []);
  assert.deepEqual(unknownNames(["claude plugin install mattpocock-skills@wimsuenens"], { listed: new Set() }), ["install mattpocock-skills"]);
});

// ---- AC-5: the set of pages comes from the folder

test("AC-5 handWrittenPages: every .md at any depth under each language folder, sorted, no list in the check", () => {
  const tmp = scratch("names-pages-");
  const w = (rel) => { const f = path.join(tmp, rel); fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, "x"); };
  w("nl/a.md"); w("en/a.md"); w("de/sub/b.md"); w("de/sub/skip.txt");
  const got = handWrittenPages(tmp);
  assert.deepEqual(got.map((p) => p.label), ["de/sub/b.md", "en/a.md", "nl/a.md"]);
  assert.deepEqual(got.map((p) => [p.lang, p.file]), [["de", "sub/b.md"], ["en", "a.md"], ["nl", "a.md"]]);
  assert.ok(got.every((p) => fs.existsSync(p.path)));
  w("fr/new.md");
  assert.ok(handWrittenPages(tmp).some((p) => p.label === "fr/new.md"), "a page added later is read without an edit");
});

test("AC-5 handWrittenPages of an empty folder is empty", () => {
  assert.deepEqual(handWrittenPages(scratch("names-empty-")), []);
});

// ---- AC-5, AC-6: the real pages

test("AC-5/6 the real pages: a non-empty set from the folder, both Getting started pages, and no fault", () => {
  const pages = handWrittenPages();
  assert.ok(pages.length > 0, "the set of hand-written pages is not empty");
  const labels = pages.map((p) => p.label);
  assert.ok(labels.includes("en/getting-started.md") && labels.includes("nl/getting-started.md"), labels.join(", "));
  const f = pageFaults(pages.map((p) => ({ label: p.label, text: fs.readFileSync(p.path, "utf8") })));
  assert.deepEqual(f, [], `hand-written pages name something that does not exist:\n${f.join("\n")}`);
});

test("AC-6 the real pages hold tokens of every kind the rules cover (the check is not passing for lack of input)", () => {
  const tokens = backtickedTokens(read("en/getting-started.md"));
  assert.ok(tokens.some((t) => /\/[a-z-]+:[a-z-]+/.test(t)), "a /plugin:skill");
  assert.ok(tokens.some((t) => /\binstall\s+\S+@\S+/.test(t)), "an install target");
  assert.ok(tokens.some((t) => agentPathsIn([t]).length), "a docs/agents path");
  assert.ok(tokens.some((t) => t.includes("/reload-plugins")), "a look-alike the rules must not report");
  assert.ok(skillSources(PLUGINS).length > 0);
});

test("AC-6 the check holds no page, language, token or path list and no skip", () => {
  const src = fs.readFileSync(new URL("./names.mjs", import.meta.url), "utf8").replace(/^\s*\/\/.*$/gm, "");
  assert.ok(!/getting-started/.test(src), "no page name");
  assert.ok(!/["'`](en|nl)["'`]/.test(src), "no language name");
  assert.ok(!/\.skip\b|skip\s*:|allow|except|ignore/i.test(src), "no skip, allow or exception list");
  assert.deepEqual([...src.matchAll(/["'`]docs\/agents\/[A-Za-z0-9_-]+\.md["'`]/g)], [], "no path list");
});

// ---- AC-7: code blocks give the same result as before

test("AC-7 the AC-19 control input gives the same result through unknownNames as through unknownCommands", () => {
  const input = ["/factory:no-such-skill\n/nosuch:idea\nclaude plugin install nosuch@wimsuenens\nclaude plugin install factory@other", "/factory:idea", "claude plugin install mattpocock-skills@wimsuenens"];
  for (const t of input) assert.deepEqual(unknownNames([t]), unknownCommands([t]), t);
  assert.deepEqual(unknownNames([input[0]]).sort(), ["/factory:no-such-skill", "/nosuch:idea", "install nosuch", "marketplace other"].sort());
  assert.deepEqual(unknownNames([input[2]], { listed: new Set() }), unknownCommands([input[2]], undefined, undefined, new Set()));
});

test("AC-7 every fenced block of the real pages equals the rendered pre text, so the code-block result is identical", () => {
  const dist = realBuild();
  const decode = (s) => s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#x?27;|&#39;/g, "'").replace(/&amp;/g, "&");
  for (const [lang, route] of [["en", "getting-started"], ["nl", "nl/getting-started"]]) {
    const html = fs.readFileSync(path.join(dist, route, "index.html"), "utf8");
    const main = html.slice(html.indexOf("<main"), html.indexOf("</main>"));
    const pres = [...main.matchAll(/<pre\b[\s\S]*?<\/pre>/g)].map((m) => decode(m[0].replace(/<[^>]+>/g, "")).replace(/\s+$/, ""));
    const blocks = fencedBlocks(read(`${lang}/getting-started.md`)).map((b) => b.replace(/\s+$/, ""));
    assert.ok(blocks.length > 0, `${lang} has code blocks`);
    assert.deepEqual(blocks, pres, `${lang}: fenced blocks equal the rendered pre text`);
    assert.deepEqual(unknownCommands(blocks), unknownCommands(pres));
    assert.deepEqual(unknownCommands(blocks), []);
    assert.deepEqual(agentPathsIn(blocks), [], "no current code block holds a docs/agents path");
  }
});
