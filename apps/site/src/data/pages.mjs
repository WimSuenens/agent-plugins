// The page tree: the one source for slugs, routes, navigation, breadcrumbs, see-also links and language counterparts.
// Data only. Contract: contracts/188-page-tree.md. Adding a hand-written page is one entry here plus its content file
// under src/content/pages/<lang>/<slug>.md. A Dutch page is a draft until its review is set to "reviewed".
export const pages = [
  {
    slug: "",
    parent: null,
    title: { en: "Home", nl: "Thuis" },
    heading: { en: "Agent plugins", nl: "Agent plugins" },
    source: "component",
    component: "home",
    seeAlso: ["getting-started", "reference"],
    review: { nl: "draft" },
  },
  {
    slug: "getting-started",
    parent: "",
    title: { en: "Getting started", nl: "Aan de slag" },
    source: "markdown",
    seeAlso: ["reference", ""],
    review: { nl: "draft" },
  },
  {
    slug: "reference",
    parent: "",
    title: { en: "Reference", nl: "Naslag" },
    source: "component",
    component: "reference",
    seeAlso: ["getting-started"],
    review: { nl: "draft" },
  },
  {
    slug: "skills",
    parent: "reference",
    title: { en: "Skills", nl: "Vaardigheden" },
    source: "component",
    component: "skills",
    seeAlso: ["agents", "reference"],
    review: { nl: "draft" },
  },
  {
    slug: "agents",
    parent: "reference",
    title: { en: "Agents", nl: "Agenten" },
    source: "component",
    component: "agents",
    seeAlso: ["skills", "reference"],
    review: { nl: "draft" },
  },
];
