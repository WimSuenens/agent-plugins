// AC-26: .github/workflows/site.yml (contract 156-deploy-workflow). No run needed; AC-27 is proven by the first run on main.
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { REPO, loadYaml } from "./lib.mjs";

const FILE = path.join(REPO, ".github/workflows/site.yml");
const wf = () => loadYaml().parse(fs.readFileSync(FILE, "utf8"));
const steps = (j) => wf().jobs[j].steps;
const usesOf = (s) => (s.uses ?? "").split("@")[0];

test("AC-26 workflow is named site and triggers on push to main, pull_request and workflow_dispatch with the path filters", () => {
  const w = wf();
  assert.equal(w.name, "site");
  const on = w.on ?? w[true];
  const want = ["apps/site/**", "plugins/**", ".github/workflows/site.yml"];
  assert.deepEqual(on.push.branches, ["main"]);
  for (const p of want) { assert.ok(on.push.paths.includes(p), `push paths ${p}`); assert.ok(on.pull_request.paths.includes(p), `pr paths ${p}`); }
  assert.ok("workflow_dispatch" in on);
});

test("AC-26 permissions: union is exactly contents:read, pages:write, id-token:write; pages and id-token only on deploy", () => {
  const w = wf();
  assert.deepEqual(w.permissions, { contents: "read" });
  const union = { ...w.permissions };
  for (const [name, job] of Object.entries(w.jobs)) {
    for (const [k, v] of Object.entries(job.permissions ?? {})) {
      union[k] = v;
      if (k === "pages" || k === "id-token") assert.equal(name, "deploy", `${k} on ${name}`);
    }
  }
  assert.deepEqual(union, { contents: "read", pages: "write", "id-token": "write" });
  assert.equal(w.jobs.deploy.permissions.pages, "write");
  assert.equal(w.jobs.deploy.permissions["id-token"], "write");
  assert.ok(!w.jobs.build.permissions || Object.keys(w.jobs.build.permissions).every((k) => k === "contents"));
});

test("AC-26 build job: checkout, node 22 with npm cache on the lockfile, npm ci, playwright chromium, npm test, npm run build with SITE_BASE, then upload", () => {
  const s = steps("build");
  const text = JSON.stringify(wf());
  const idx = (f) => s.findIndex(f);
  const co = idx((x) => usesOf(x) === "actions/checkout");
  const sn = idx((x) => usesOf(x) === "actions/setup-node");
  const ci = idx((x) => /^npm ci\b/.test(x.run ?? ""));
  const pw = idx((x) => /npx playwright install --with-deps chromium/.test(x.run ?? ""));
  const nt = idx((x) => /^npm test\b/.test(x.run ?? ""));
  const bd = idx((x) => /^npm run build\s*$/.test((x.run ?? "").trim()));
  const up = idx((x) => usesOf(x) === "actions/upload-pages-artifact");
  for (const [n, i] of Object.entries({ co, sn, ci, pw, nt, bd, up })) assert.ok(i >= 0, `step ${n} missing`);
  assert.ok(co < sn && sn < ci && ci < pw && pw < nt && nt < bd && bd < up, "step order");
  assert.equal(String(s[sn].with["node-version"]), "22");
  assert.equal(s[sn].with.cache, "npm");
  assert.match(String(s[sn].with["cache-dependency-path"]), /apps\/site\/package-lock\.json/);
  assert.equal(s[bd].env.SITE_BASE, "/agent-plugins");
  assert.match(String(s[up].with.path), /apps\/site\/dist/);
  assert.match(String(s[up].if), /github\.event_name\s*!=\s*'pull_request'/);
  const wfJson = wf();
  const wd = (x) => x["working-directory"] ?? wfJson.jobs.build.defaults?.run?.["working-directory"] ?? wfJson.defaults?.run?.["working-directory"];
  for (const i of [ci, pw, nt, bd]) assert.equal(wd(s[i]), "apps/site", `step ${i} runs in apps/site`);
  assert.ok(text.includes("ubuntu-24.04"));
});

test("AC-26 deploy job: needs build, only off pull requests and on main, github-pages environment, actions/deploy-pages with id deployment", () => {
  const d = wf().jobs.deploy;
  assert.ok([].concat(d.needs).includes("build"));
  assert.match(String(d.if), /github\.event_name\s*!=\s*'pull_request'/);
  assert.match(String(d.if), /github\.ref\s*==\s*'refs\/heads\/main'/);
  assert.equal(d.environment.name, "github-pages");
  assert.match(String(d.environment.url), /steps\.deployment\.outputs\.page_url/);
  const dp = d.steps.filter((s) => usesOf(s) === "actions/deploy-pages");
  assert.equal(dp.length, 1);
  assert.equal(dp[0].id, "deployment");
  assert.equal(d.steps.length, 1, "deploy has one step");
});

test("AC-26 concurrency group is per ref and a deploy in flight on main is not cancelled", () => {
  const w = wf();
  const c = w.concurrency ?? w.jobs.build.concurrency;
  assert.ok(c, "concurrency declared");
  assert.match(String(c.group), /site-\$\{\{\s*github\.ref\s*\}\}/);
  assert.notEqual(c["cancel-in-progress"], true, "must not cancel a main deploy unconditionally");
});

test("AC-26 every action is pinned by a 40-hex commit sha with a version comment", () => {
  const raw = fs.readFileSync(FILE, "utf8");
  const uses = [...raw.matchAll(/^\s*-?\s*uses:\s*(\S+)(.*)$/gm)];
  // The contract names exactly these four actions (156-deploy-workflow s1).
  const CONTRACT_ACTIONS = ["actions/checkout", "actions/setup-node", "actions/upload-pages-artifact", "actions/deploy-pages"];
  for (const a of CONTRACT_ACTIONS) assert.ok(uses.some(([, ref]) => ref.startsWith(a + "@")), `${a} used`);
  assert.ok(uses.length >= CONTRACT_ACTIONS.length);
  for (const [, ref, rest] of uses) {
    assert.match(ref, /@[0-9a-f]{40}$/, `${ref} not pinned by sha`);
    assert.match(rest, /#\s*v?\d/, `${ref} lacks a version comment`);
  }
});

test("AC-26 no secrets or tokens are referenced", () => {
  assert.ok(!/secrets\./.test(fs.readFileSync(FILE, "utf8")));
});

test("AC-26 actionlint passes (skipped when actionlint is not installed)", (t) => {
  const r = spawnSync("actionlint", [FILE], { encoding: "utf8" });
  if (r.error?.code === "ENOENT") return t.skip("actionlint not installed");
  assert.equal(r.status, 0, r.stdout + r.stderr);
});
