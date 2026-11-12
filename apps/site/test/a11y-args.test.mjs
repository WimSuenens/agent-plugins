import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const run = (args) => spawnSync("node", ["scripts/a11y-check.mjs", ...args], { encoding: "utf8" });

test("unknown option is exit 2", () => {
  assert.equal(run(["--nope", "x"]).status, 2);
});

test("missing dist folder is exit 2", () => {
  assert.equal(run(["--dist", path.join(os.tmpdir(), "no-such-dist-folder")]).status, 2);
});

test("empty dist folder is exit 2, never 0", () => {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), "a11y-empty-"));
  assert.equal(run(["--dist", d]).status, 2);
});
