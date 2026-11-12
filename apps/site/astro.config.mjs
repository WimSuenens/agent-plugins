import { defineConfig } from "astro/config";

const base = process.env.SITE_BASE ?? "/agent-plugins";
if (!base.startsWith("/") || (base.length > 1 && base.endsWith("/"))) {
  throw new Error(`SITE_BASE must start with "/" and must not end with "/" (got "${base}")`);
}

export default defineConfig({
  site: "https://wimsuenens.github.io",
  base,
  outDir: process.env.SITE_OUT_DIR ?? "dist",
  trailingSlash: "always",
  build: { format: "directory", inlineStylesheets: "never" },
});
