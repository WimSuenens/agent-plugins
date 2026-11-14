import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { loadAgents } from "../src/lib/agents.mjs";

const tree = (files) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "agents-unit-"));
  for (const [rel, text] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.writeFileSync(path.join(dir, rel), text);
  }
  return dir;
};

test("reads name, description, model and tools; a string and a list of tools agree", () => {
  const dir = tree({
    "p/agents/a.md": "---\nname: a\ndescription: Does a.\ntools: Read, Grep\nmodel: sonnet\n---\nbody\n",
    "p/agents/b.md": "---\nname: b\ndescription: Does b.\ntools: [Read, Grep]\n---\n",
  });
  assert.deepEqual(loadAgents(dir), [
    { plugin: "p", name: "a", description: "Does a.", model: "sonnet", tools: ["Read", "Grep"] },
    { plugin: "p", name: "b", description: "Does b.", model: null, tools: ["Read", "Grep"] },
  ]);
});

test("a missing description names the source; no agent files at all is an error", () => {
  assert.throws(() => loadAgents(tree({ "p/agents/x.md": "---\nname: x\n---\n" })), { message: 'reference: p/agents/x.md: missing required field "description"' });
  const empty = tree({ "p/skills/s/SKILL.md": "x" });
  assert.throws(() => loadAgents(empty), { message: `reference: no agent files found under ${empty}` });
});
