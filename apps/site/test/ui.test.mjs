import { test } from "node:test";
import assert from "node:assert/strict";
import { ui } from "../src/i18n/ui.mjs";

test("en and nl have the same keys, all non-empty", () => {
  assert.deepEqual(Object.keys(ui.nl).sort(), Object.keys(ui.en).sort());
  for (const lang of ["en", "nl"]) for (const [k, v] of Object.entries(ui[lang])) assert.ok(v.trim().length > 0, `${lang}.${k}`);
});

test("page titles differ per language", () => {
  assert.notEqual(ui.en.title, ui.nl.title);
});
