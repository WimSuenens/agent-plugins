// AC-24, AC-25: the accessibility check script and the build command (contracts 156-a11y-check, 156-site-skeleton s1).
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { BASE, SITE, npm, node, realBuild, htmlFiles, scratch } from "./lib.mjs";

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
  assert.equal(n, 3);
  assert.equal(lastLine(r.stdout), `a11y: ${n} pages checked, 0 violations`);
});

test("AC-25 an image without alt on one page fails the check, naming route and rule; the original still passes", () => {
  const copy = copyDist();
  edit(copy, "nl/index.html", (h) => h.replace("</main>", '<img src="x.png"></main>'));
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.equal(r.status, 1, r.out);
  assert.match(r.out, /a11y: FAIL \/agent-plugins\/nl\/ image-alt \(\w+\) .* :: .*img/);
  assert.match(lastLine(r.stdout), /^a11y: 3 pages checked, [1-9]\d* violations$/);
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
  assert.match(lastLine(r.stdout), /^a11y: 3 pages checked, 0 violations$/);
});

test("check ignores dotfiles and counts every *.html (a copy with an extra page reports 4)", () => {
  const copy = copyDist();
  fs.mkdirSync(path.join(copy, "extra"));
  fs.copyFileSync(path.join(copy, "reference/index.html"), path.join(copy, "extra/index.html"));
  fs.writeFileSync(path.join(copy, ".hidden.html"), "<html><img src=x></html>");
  const r = node([CHECK, "--dist", copy, "--base", BASE]);
  assert.match(lastLine(r.stdout), /^a11y: 4 pages checked, \d+ violations?$/);
});
