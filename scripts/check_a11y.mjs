import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";
import { previewRoutes } from "./preview_routes.mjs";

const baseUrl = process.env.PREVIEW_BASE_URL || "http://127.0.0.1:3100";

// Previews are page fragments: they have no <h1> and the example pages repeat
// landmarks on purpose, like GCWeb's own demo pages.
const FRAGMENT_RULES = ["page-has-heading-one", "landmark-unique"];

const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
let failed = false;

for (const route of previewRoutes) {
  const target = `${baseUrl}${route.path}`;
  await page.goto(target, { waitUntil: "networkidle" });

  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .disableRules(FRAGMENT_RULES)
    .analyze();

  if (results.violations.length > 0) {
    failed = true;
    console.error(`\n[a11y] ${route.name} (${target}) violations:`);
    for (const violation of results.violations) {
      console.error(`- ${violation.id}: ${violation.help}`);
      for (const node of violation.nodes) console.error(`  target: ${node.target.join(", ")}`);
    }
  } else {
    console.log(`[a11y] ${route.name} passed`);
  }
}

await browser.close();
if (failed) process.exit(1);
