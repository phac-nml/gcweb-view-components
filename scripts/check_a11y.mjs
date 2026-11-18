import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";

const baseUrl = process.env.PREVIEW_BASE_URL || "http://127.0.0.1:3000";
const routes = [
  { name: "home-en", path: "/" },
  { name: "home-fr", path: "/fr" },
  { name: "content-en", path: "/content" },
  { name: "content-fr", path: "/fr/content" }
];

const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();

let failed = false;

for (const route of routes) {
  const target = `${baseUrl}${route.path}`;
  await page.goto(target, { waitUntil: "networkidle" });

  const results = await new AxeBuilder({ page }).analyze();
  if (results.violations.length > 0) {
    failed = true;
    console.error(`\n[a11y] ${route.name} (${target}) violations:`);
    for (const violation of results.violations) {
      console.error(`- ${violation.id}: ${violation.help}`);
      for (const node of violation.nodes) {
        console.error(`  target: ${node.target.join(", ")}`);
      }
    }
  } else {
    console.log(`[a11y] ${route.name} passed`);
  }
}

await context.close();
await browser.close();

if (failed) {
  process.exit(1);
}
