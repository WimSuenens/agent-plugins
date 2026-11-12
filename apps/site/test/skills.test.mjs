import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { loadSkills } from "../src/lib/skills.mjs";

function tree(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "skills-"));
  for (const [rel, text] of Object.entries(files)) {
    const f = path.join(root, rel);
    fs.mkdirSync(path.dirname(f), { recursive: true });
    fs.writeFileSync(f, text);
  }
  return root;
}
const skill = (fm) => `---\n${fm}\n---\n# body\n`;

test("maps the worked example", () => {
  const root = tree({
    "factory/skills/run/SKILL.md": skill('name: run\ndescription: "Run it: now - `x` / \\"q\\" … — end"\nargument-hint: "[idea | #map]"\ndisable-model-invocation: true'),
  });
  assert.deepEqual(loadSkills(root), [
    { plugin: "factory", command: "/factory:run", name: "run", description: 'Run it: now - `x` / "q" … — end', argumentHint: "[idea | #map]", manual: true },
  ]);
});

test("optional fields absent give null and not manual; other values are not manual", () => {
  const root = tree({
    "a/skills/x/SKILL.md": skill("name: x\ndescription: d"),
    "a/skills/y/SKILL.md": skill('name: y\ndescription: d\ndisable-model-invocation: "true"\nlicense: MIT'),
  });
  const [x, y] = loadSkills(root);
  assert.deepEqual([x.argumentHint, x.manual, y.manual], [null, false, false]);
});

test("sorted by plugin then name; dotfiles and folders without SKILL.md are ignored", () => {
  const root = tree({
    "b/skills/z/SKILL.md": skill("name: z\ndescription: d"),
    "a/skills/m/SKILL.md": skill("name: m\ndescription: d"),
    "a/skills/c/SKILL.md": skill("name: c\ndescription: d"),
    "a/skills/empty/README.md": "x",
    "c/nothing/file": "x",
    ".hidden/skills/h/SKILL.md": skill("name: h\ndescription: d"),
  });
  assert.deepEqual(loadSkills(root).map((s) => s.command), ["/a:c", "/a:m", "/b:z"]);
});

test("frontmatter name wins over the folder name", () => {
  const root = tree({ "a/skills/folder/SKILL.md": skill("name: other\ndescription: d") });
  assert.equal(loadSkills(root)[0].command, "/a:other");
});

for (const [label, text, reason] of [
  ["missing description", skill("name: x"), 'missing required field "description"'],
  ["missing name", skill("description: d"), 'missing required field "name"'],
  ["empty description", skill('name: x\ndescription: ""'), 'missing required field "description"'],
  ["non-string name", skill("name: 5\ndescription: d"), 'field "name" must be a string'],
  ["non-string hint", skill("name: x\ndescription: d\nargument-hint: [a]"), 'field "argument-hint" must be a string'],
  ["no frontmatter", "# hi", "no frontmatter"],
  ["bad YAML", skill("name: x\ndescription: a: b"), "bad YAML"],
]) {
  test(`fails naming the file: ${label}`, () => {
    const root = tree({ "p/skills/s/SKILL.md": text });
    assert.throws(() => loadSkills(root), (e) => e.message.includes("p/skills/s/SKILL.md") && e.message.includes(reason));
  });
}

test("zero sources is an error", () => {
  assert.throws(() => loadSkills(tree({ "p/readme": "x" })), /no SKILL\.md files found/);
});
