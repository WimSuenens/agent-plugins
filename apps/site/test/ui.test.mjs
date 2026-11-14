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

test("the visible heading is separate from the document title", () => {
  for (const lang of ["en", "nl"]) {
    assert.equal(ui[lang].heading, "Agent plugins");
    assert.notEqual(ui[lang].heading, ui[lang].title);
  }
});

test("count sentences are templates with a slot and no digit", () => {
  for (const lang of ["en", "nl"]) {
    assert.match(ui[lang].skillsCountSentence, /\{skills\}.*\{plugins\}/);
    assert.match(ui[lang].agentsCountSentence, /\{agents\}.*\{plugins\}/);
    for (const [k, v] of Object.entries(ui[lang])) assert.doesNotMatch(v, /\d/, `${lang}.${k}`);
  }
});
