// The one hast step of the content pipeline (Astro 7's Markdown processor, Sätteri): `pre` blocks become keyboard-focusable
// because they scroll, and site-root links of the content get the base path. It adds no class, no style, no script.
// Contract: contracts/188-wiki-components.md section 8. Registered in astro.config.mjs.
export function rehypePage({ base = "" } = {}) {
  const prefix = String(base).replace(/\/+$/, "");
  return {
    name: "page-content",
    element: {
      filter: ["pre", "a"],
      visit(node, ctx) {
        if (node.tagName === "pre") {
          ctx.setProperty(node, "tabIndex", 0);
          return;
        }
        const href = node.properties?.href;
        if (typeof href === "string" && href.startsWith("/") && !href.startsWith("//")) ctx.setProperty(node, "href", `${prefix}${href}`);
      },
    },
  };
}
