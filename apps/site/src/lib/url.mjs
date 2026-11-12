// The one helper that prefixes the base path. `path` is site-relative, e.g. "nl/" or "".
export function url(path = "") {
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  return `${base}/${path.replace(/^\//, "")}`;
}
