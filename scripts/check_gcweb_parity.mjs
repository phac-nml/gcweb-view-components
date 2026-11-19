// Compare our Lookbook previews against GCWeb's own demo pages, element by
// element, using fully-cascaded computed styles. Computed styles do not depend
// on the OS or font rasteriser, so this is stable across macOS and Linux CI.
//
//   pnpm parity:check     compare previews with test/gcweb_reference/<version>.json
//   pnpm parity:capture   re-read GCWeb's demo pages and rewrite that JSON
//                         (do this when bumping GcwebViewComponents::GCWEB_VERSION)
//   pnpm parity:live      compare previews with the live GCWeb demo site
//
// PREVIEW_BASE_URL defaults to http://127.0.0.1:3100 (the demo server).
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import { computedStyles } from "./computed_styles.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const gcwebVersion = fs
  .readFileSync(path.join(root, "lib/gcweb_view_components/version.rb"), "utf8")
  .match(/GCWEB_VERSION = "([^"]+)"/)[1];
const referenceFile = path.join(root, "test/gcweb_reference", `gcweb-${gcwebVersion}.json`);
const mode = process.argv.includes("--capture") ? "capture" : process.argv.includes("--live") ? "live" : "reference";

const previewBase = process.env.PREVIEW_BASE_URL || "http://127.0.0.1:3100";
const gcwebBase = process.env.GCWEB_BASE_URL || "https://wet-boew.github.io/GCWeb";

// Properties that define the look. Layout-dependent values (width, height,
// top, left) are left out because the surrounding pages differ.
const PROPS = [
  "display", "position", "box-sizing",
  "margin-top", "margin-right", "margin-bottom", "margin-left",
  "padding-top", "padding-right", "padding-bottom", "padding-left",
  "border-top-width", "border-right-width", "border-bottom-width", "border-left-width",
  "border-left-style", "border-left-color", "border-top-color",
  "border-image-source", "border-image-slice",
  "background-color", "background-clip", "color", "opacity",
  "font-family", "font-size", "font-weight", "line-height", "font-variant-ligatures",
  "text-decoration-line", "text-decoration-thickness", "list-style-type", "content",
  "min-height", "clip-path", "overflow"
];

// Extra properties for form controls (borders, shadows, focus rings).
const FORM_PROPS = [
  ...PROPS,
  "border-top-style", "border-right-color", "border-bottom-color",
  "border-top-left-radius", "border-bottom-right-radius",
  "box-shadow", "outline-style", "outline-width", "background-image",
  "max-width", "vertical-align", "white-space", "text-align", "font-style", "text-transform"
];

// GCWeb's form demo (common/form/complex-structure-form-en.html) lays fields
// out with .form-horizontal and the Bootstrap grid. The components render
// GCWeb's stacked layout (as in wet-boew's form validation demo), so before
// reading styles the reference page drops the grid classes.
const stackGcwebForm = (page) =>
  page.evaluate(() => {
    document.querySelectorAll(".form-horizontal").forEach((el) => el.classList.remove("form-horizontal"));
    document.querySelectorAll("[class*='col-sm-'], .control-label").forEach((el) => {
      el.className = el.className.replace(/\b(col-sm-\d+|control-label|mrgn-tp-0)\b/g, "").replace(/\s+/g, " ").trim();
    });
  });

// Submit GCWeb's form so wet-boew's validation (wb-frmvld) adds its error
// markup. Wait until wb-frmvld has moved focus to its error summary (it does
// so asynchronously, and would steal focus from a field focused earlier) and
// the 0.15s border transition to the error colour has finished.
const submitGcwebForm = async (page) => {
  await page.click(".wb-frmvld form [type=submit]");
  await page.waitForSelector(".wb-frmvld section[id^='errors-']");
  await page.waitForFunction(() => document.activeElement?.matches("section[id^='errors-']"));
  await page.waitForTimeout(400);
};

// Focus a control and let the 0.15s border/box-shadow transition finish.
const focus = async (page, selector) => {
  await page.focus(selector);
  await page.waitForTimeout(400);
};

// Field ids on GCWeb's form demo, and the matching ids in our previews.
const GCWEB_FIELDS = {
  rank: "00NMm000005m2W5",
  post_nominals: "00NMm000005m2Kn",
  first_name: "00N4t000000PQXs",
  preferred_language: "00NMm000002JlRt",
  email: "00NMm000000W5e5"
};
const theirs = (field) => `[id='${GCWEB_FIELDS[field]}']`;
const ours = (field) => `#contact_information_${field}`;
const fieldPair = (field, suffix = "") => [`${theirs(field)}${suffix}`, `${ours(field)}${suffix}`];
const labelPair = (field, suffix = "") => [
  `label[for='${GCWEB_FIELDS[field]}']${suffix}`,
  `label[for='contact_information_${field}']${suffix}`
];
const groupPair = (field) => [
  `.form-group:has(> label[for='${GCWEB_FIELDS[field]}'])`,
  `.form-group:has(> label[for='contact_information_${field}'])`
];
const GCWEB_FORM = "/common/form/complex-structure-form-en.html";
const FORM_PREVIEW = "/rails/view_components/gcweb/form_builder/contact_information";

const alertPairs = (variant, scope) => [
  [`${scope}.alert-${variant}`, `${scope}.alert-${variant}`],
  [`${scope}.alert-${variant}::before`, `${scope}.alert-${variant}::before`],
  [`${scope}.alert-${variant} > :first-child`, `${scope}.alert-${variant} > :first-child`],
  [`${scope}.alert-${variant} > :last-child`, `${scope}.alert-${variant} > :last-child`]
];

const CHECKS = [
  {
    name: "alert / with headings",
    gcweb: "/common/alert/alerts-en.html",
    preview: "/rails/view_components/gcweb/alert_component/with_headings",
    pairs: ["danger", "warning", "success", "info"].flatMap((v) => alertPairs(v, "section"))
  },
  {
    name: "alert / links",
    gcweb: "/common/alert/alerts-en.html",
    preview: "/rails/view_components/gcweb/alert_component/with_links",
    pairs: ["success", "info", "warning", "danger"].map((v) => [
      `section.alert-${v} a.alert-link`, `section.alert-${v} a.alert-link`
    ])
  },
  {
    name: "alert / without headings",
    gcweb: "/common/alert/alerts-en.html",
    preview: "/rails/view_components/gcweb/alert_component/without_headings",
    pairs: ["danger", "warning", "success", "info"].flatMap((v) => alertPairs(v, "div"))
  },
  {
    name: "alert / expand-collapse",
    gcweb: "/common/alert/alerts-en.html",
    preview: "/rails/view_components/gcweb/alert_component/expand_collapse",
    pairs: [
      ["section.alert-warning > details", "section.alert-warning > details"],
      ["section.alert-warning > details > summary", "section.alert-warning > details > summary"],
      ["section.alert-warning > details > summary > h3", "section.alert-warning > details > summary > h3"],
      ["section.alert-danger > details[open]", "section.alert-danger > details[open]"],
      ["section.alert-danger > details[open] > summary", "section.alert-danger > details[open] > summary"],
      ["section.alert-danger > details[open] > p", "section.alert-danger > details[open] > p"]
    ]
  },
  {
    name: "featured link / default",
    gcweb: "/components/gc-featured-link/gc-featured-link-en.html",
    preview: "/rails/view_components/gcweb/featured_link_component/default",
    pairs: [
      ["section.gc-featured-link:not([data-bg-color])", "section.gc-featured-link"],
      ["section.gc-featured-link:not([data-bg-color]) > .container", "section.gc-featured-link > .container"],
      ["section.gc-featured-link:not([data-bg-color]) h2.wb-inv", "section.gc-featured-link h2.wb-inv"],
      ["section.gc-featured-link:not([data-bg-color]) p", "section.gc-featured-link p"],
      ["section.gc-featured-link:not([data-bg-color]) a.stretched-link", "section.gc-featured-link a.stretched-link"],
      ["section.gc-featured-link:not([data-bg-color]) a.stretched-link::after", "section.gc-featured-link a.stretched-link::after"]
    ]
  },
  {
    name: "featured link / custom backgrounds",
    gcweb: "/components/gc-featured-link/gc-featured-link-en.html",
    preview: "/rails/view_components/gcweb/featured_link_component/custom_background",
    pairs: ["#005B61", "#99dade", "#8F8F8F"].flatMap((c) => [
      [`section[data-bg-color='${c}']`, `section[data-bg-color='${c}']`],
      [`section[data-bg-color='${c}'] a`, `section[data-bg-color='${c}'] a`]
    ])
  },
  {
    name: "form / fields",
    gcweb: GCWEB_FORM,
    gcwebSetup: stackGcwebForm,
    preview: FORM_PREVIEW,
    props: FORM_PROPS,
    pairs: [
      groupPair("rank"),
      labelPair("rank"),
      labelPair("rank", " > .field-name"),
      fieldPair("rank"),
      fieldPair("post_nominals"),
      labelPair("first_name"),
      labelPair("first_name", "::before"),
      labelPair("first_name", " > strong.required"),
      fieldPair("first_name"),
      fieldPair("preferred_language"),
      fieldPair("email")
    ]
  },
  {
    name: "form / errors",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await submitGcwebForm(page);
    },
    preview: `${FORM_PREVIEW}_with_errors`,
    props: FORM_PROPS,
    pairs: [
      groupPair("first_name"),
      labelPair("first_name"),
      labelPair("first_name", " > strong.error"),
      labelPair("first_name", " .label-danger"),
      labelPair("first_name", " .prefix"),
      fieldPair("first_name"),
      fieldPair("preferred_language"),
      labelPair("email", " .label-danger"),
      fieldPair("email")
    ]
  },
  {
    name: "form / focus",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await focus(page, theirs("rank"));
    },
    preview: FORM_PREVIEW,
    previewSetup: (page) => focus(page, ours("rank")),
    props: FORM_PROPS,
    pairs: [fieldPair("rank")]
  },
  {
    name: "form / error focus",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await submitGcwebForm(page);
      await focus(page, theirs("first_name"));
    },
    preview: `${FORM_PREVIEW}_with_errors`,
    previewSetup: (page) => focus(page, ours("first_name")),
    props: FORM_PROPS,
    pairs: [fieldPair("first_name")]
  }
];

const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const page = await context.newPage();

const load = async (url) => {
  await page.goto(url, { waitUntil: "networkidle" });
  await page.evaluate(() => document.fonts.ready);
};

const propsFor = (check) => check.props || PROPS;

const readGcweb = async (check) => {
  await load(gcwebBase + check.gcweb);
  if (check.gcwebSetup) await check.gcwebSetup(page);
  return computedStyles(page, check.pairs.map(([ref]) => ref), propsFor(check));
};

if (mode === "capture") {
  const reference = { gcwebVersion, capturedFrom: gcwebBase, viewport: "1280x900", checks: {} };
  for (const check of CHECKS) reference.checks[check.name] = await readGcweb(check);
  fs.mkdirSync(path.dirname(referenceFile), { recursive: true });
  fs.writeFileSync(referenceFile, JSON.stringify(reference, null, 2) + "\n");
  console.log(`[parity] wrote ${path.relative(root, referenceFile)} from ${gcwebBase}`);
  console.log("[parity] check the live site really serves GCWeb v" + gcwebVersion + " before committing it.");
  await browser.close();
  process.exit(0);
}

let reference = null;
if (mode === "reference") {
  if (!fs.existsSync(referenceFile)) {
    console.error(`[parity] missing ${path.relative(root, referenceFile)}; run \`pnpm parity:capture\``);
    process.exit(1);
  }
  reference = JSON.parse(fs.readFileSync(referenceFile, "utf8"));
}

let mismatches = 0;
let compared = 0;

for (const check of CHECKS) {
  const expectedStyles = reference ? reference.checks[check.name] || {} : await readGcweb(check);
  await load(previewBase + check.preview);
  if (check.previewSetup) await check.previewSetup(page);
  const actualStyles = await computedStyles(page, check.pairs.map(([, mine]) => mine), propsFor(check));
  const problems = [];

  for (const [ref, mine] of check.pairs) {
    const expected = expectedStyles[ref];
    const actual = actualStyles[mine];
    if (!expected) {
      problems.push(`  ? ${ref}: not found in GCWeb reference`);
      continue;
    }
    if (!actual) {
      problems.push(`  ✗ ${mine}: not found in preview`);
      continue;
    }
    for (const prop of propsFor(check)) {
      compared++;
      if (expected[prop] !== actual[prop]) {
        problems.push(`  ✗ ${mine} { ${prop} } gcweb=${expected[prop]} ours=${actual[prop]}`);
      }
    }
  }

  if (problems.length) {
    mismatches += problems.length;
    console.error(`[parity] ${check.name}: ${problems.length} difference(s)`);
    for (const line of problems) console.error(line);
  } else {
    console.log(`[parity] ${check.name}: matches GCWeb ${reference ? "v" + gcwebVersion : "(live)"}`);
  }
}

await browser.close();
console.log(`[parity] ${compared} property values compared, ${mismatches} difference(s)`);
if (mismatches) process.exit(1);
