// Dump the computed styles of selected elements on any page.
//
// Used to read GCWeb's real, fully-cascaded values off its demo pages so the
// hand-written SCSS can match them, and to compare our previews against them.
//
//   node scripts/computed_styles.mjs <url> <selector> [<selector> ...]
//   node scripts/computed_styles.mjs <url> --props=color,margin-left <selector>
//
// Pseudo-elements: append "::before" or "::after" to a selector.
import { chromium } from "playwright";

const DEFAULT_PROPS = [
  "display", "position", "box-sizing", "width", "height", "min-height",
  "margin-top", "margin-right", "margin-bottom", "margin-left",
  "padding-top", "padding-right", "padding-bottom", "padding-left",
  "border-top-width", "border-left-width", "border-left-style", "border-left-color",
  "border-image-source", "border-image-slice", "border-image-width",
  "background-color", "background-clip", "color", "opacity",
  "font-family", "font-size", "font-weight", "line-height",
  "text-decoration-line", "text-decoration-thickness", "text-underline-offset",
  "content", "top", "left", "list-style-type"
];

export async function computedStyles(page, selectors, props = DEFAULT_PROPS) {
  return page.evaluate(
    ({ selectors, props }) => {
      const out = {};
      for (const raw of selectors) {
        const match = raw.match(/^(.*?)(::?(?:before|after))?$/);
        const selector = match[1];
        const pseudo = match[2] ? match[2].replace(/^:+/, "::") : null;
        const el = document.querySelector(selector);
        if (!el) {
          out[raw] = null;
          continue;
        }
        const style = getComputedStyle(el, pseudo);
        out[raw] = Object.fromEntries(props.map((p) => [p, style.getPropertyValue(p)]));
      }
      return out;
    },
    { selectors, props }
  );
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const url = args.shift();
  const propsArg = args.find((a) => a.startsWith("--props="));
  const props = propsArg ? propsArg.slice(8).split(",") : DEFAULT_PROPS;
  const selectors = args.filter((a) => !a.startsWith("--"));

  if (!url || selectors.length === 0) {
    console.error("usage: node scripts/computed_styles.mjs <url> [--props=a,b] <selector>...");
    process.exit(2);
  }

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  await page.goto(url, { waitUntil: "networkidle" });
  await page.evaluate(() => document.fonts.ready);
  console.log(JSON.stringify(await computedStyles(page, selectors, props), null, 2));
  await browser.close();
}
