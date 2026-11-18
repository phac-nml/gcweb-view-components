import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";

const baseUrl = process.env.PREVIEW_BASE_URL || "http://127.0.0.1:3100";
const routes = [
  { name: "workbench-en", path: "/" },
  { name: "workbench-fr", path: "/fr" },
  { name: "header-preview-en", path: "/rails/view_components/app_shell/header_component/en", componentPreview: true },
  { name: "skip-links-preview-en", path: "/rails/view_components/app_shell/skip_links_component/en", componentPreview: true },
  { name: "footer-preview-en", path: "/rails/view_components/app_shell/footer_component/en", componentPreview: true },
  { name: "alert-preview-en", path: "/rails/view_components/gcweb/alert_component/en", componentPreview: true },
  { name: "alert-preview-fr", path: "/rails/view_components/gcweb/alert_component/fr", componentPreview: true }
];

const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();

let failed = false;

for (const route of routes) {
  const target = `${baseUrl}${route.path}`;
  await page.goto(target, { waitUntil: "networkidle" });

  let axeBuilder = new AxeBuilder({ page });
  if (route.componentPreview) {
    axeBuilder = axeBuilder.disableRules(["page-has-heading-one", "landmark-unique"]);
  }

  const results = await axeBuilder.analyze();
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
