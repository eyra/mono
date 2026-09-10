import { defineConfig } from "vitest/config";
import { fileURLToPath, URL } from "node:url";

const dependencyPath = (path) =>
  fileURLToPath(new URL(`../deps/${path}`, import.meta.url));

export default defineConfig({
  resolve: {
    alias: {
      phoenix: dependencyPath("phoenix/priv/static/phoenix.js"),
      phoenix_html: dependencyPath("phoenix_html/priv/static/phoenix_html.js"),
      phoenix_live_view: dependencyPath(
        "phoenix_live_view/priv/static/phoenix_live_view.esm.js"
      ),
    },
  },
  test: {
    environment: "jsdom",
    globals: true,
    silent: "passed-only",
  },
});
