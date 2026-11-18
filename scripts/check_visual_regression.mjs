import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import { PNG } from "pngjs";
import pixelmatch from "pixelmatch";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, "..");

const baseUrl = process.env.PREVIEW_BASE_URL || "http://127.0.0.1:3000";
const updateBaseline = process.argv.includes("--update-baseline");
const baselineDir = path.join(root, "test", "visual_baselines");
const currentDir = path.join(root, "tmp", "visual-current");
const diffDir = path.join(root, "tmp", "visual-diffs");

const routes = [
  { name: "home-en", path: "/" },
  { name: "home-fr", path: "/fr" }
];

const maxDiffRatio = 0.005;

fs.mkdirSync(baselineDir, { recursive: true });
fs.mkdirSync(currentDir, { recursive: true });
fs.mkdirSync(diffDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 1800 } });

let failed = false;

for (const route of routes) {
  const target = `${baseUrl}${route.path}`;
  const baselineFile = path.join(baselineDir, `${route.name}.png`);
  const currentFile = path.join(currentDir, `${route.name}.png`);
  const diffFile = path.join(diffDir, `${route.name}.png`);

  await page.goto(target, { waitUntil: "networkidle" });
  await page.screenshot({ path: currentFile, fullPage: true });

  if (updateBaseline || !fs.existsSync(baselineFile)) {
    fs.copyFileSync(currentFile, baselineFile);
    console.log(`[visual] baseline updated: ${route.name}`);
    continue;
  }

  const baselinePng = PNG.sync.read(fs.readFileSync(baselineFile));
  const currentPng = PNG.sync.read(fs.readFileSync(currentFile));

  if (baselinePng.width !== currentPng.width || baselinePng.height !== currentPng.height) {
    console.error(
      `[visual] size mismatch for ${route.name} baseline=${baselinePng.width}x${baselinePng.height} current=${currentPng.width}x${currentPng.height}`
    );
    failed = true;
    continue;
  }

  const { width, height } = baselinePng;
  const diff = new PNG({ width, height });
  const diffPixels = pixelmatch(
    baselinePng.data,
    currentPng.data,
    diff.data,
    width,
    height,
    { threshold: 0.1 }
  );
  const ratio = diffPixels / (width * height);

  if (ratio > maxDiffRatio) {
    fs.writeFileSync(diffFile, PNG.sync.write(diff));
    console.error(`[visual] ${route.name} failed ratio=${ratio.toFixed(4)} diff_pixels=${diffPixels}`);
    failed = true;
  } else {
    console.log(`[visual] ${route.name} passed ratio=${ratio.toFixed(4)}`);
  }
}

await browser.close();

if (failed) {
  process.exit(1);
}
