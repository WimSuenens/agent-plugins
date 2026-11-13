import { defineConfig } from "astro/config";
import { satteri } from "@astrojs/markdown-satteri";
import { loadPages } from "./src/lib/pages.mjs";
import { rehypePage } from "./src/lib/rehypePage.mjs";

const base = process.env.SITE_BASE ?? "/agent-plugins";
if (!base.startsWith("/") || (base.length > 1 && base.endsWith("/"))) {
  throw new Error(`SITE_BASE must start with "/" and must not end with "/" (got "${base}")`);
}

// Validates the page tree before the build starts (a fault fails the build, naming the entry) and prints the Dutch drafts once.
const pageTree = {
  name: "page-tree",
  hooks: {
    "astro:build:start": () => {
      const model = loadPages(undefined, { base });
      console.log(model.draftLine());
    },
  },
};

export default defineConfig({
  site: "https://wimsuenens.github.io",
  base,
  outDir: process.env.SITE_OUT_DIR ?? "dist",
  trailingSlash: "always",
  build: { format: "directory", inlineStylesheets: "never" },
  markdown: { syntaxHighlight: false, processor: satteri({ hastPlugins: [rehypePage({ base })] }) },
  integrations: [pageTree],
});
