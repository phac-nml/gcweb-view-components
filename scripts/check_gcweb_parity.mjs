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

// Checkboxes and radio buttons (gc-chckbxrdio) also compare cursor and
// stacking; their drawn boxes (label ::before/::after) have fixed sizes and
// offsets, so those checks compare geometry too.
const CHOICE_PROPS = [...FORM_PROPS, "cursor", "z-index", "float", "outline-offset", "border-top-right-radius"];
const BOX_PROPS = [...CHOICE_PROPS, "width", "height", "top", "left", "transform"];

const GCWEB_CHOICES = "/components/gc-chckbxrdio/gc-chckbxrdio-en.html";
const CHOICES_PREVIEW = "/rails/view_components/gcweb/form";

// Tick or select inputs without clicking (GCWeb hides them with opacity: 0).
const check = (...selectors) => (page) =>
  page.evaluate((list) => list.forEach((s) => { document.querySelector(s).checked = true; }), selectors);

// GCWeb has no validated checkbox or radio example, so the error checks add
// gc-chckbxrdio groups (GCWeb's documented markup) to the validated form
// demo, submit it, and let wb-frmvld add its error markup. GCWeb's own CSS
// and JavaScript render the result.
const addGcwebChoices = (page) =>
  page.evaluate(() => {
    const options = (type, name, values, required) =>
      values.map((v, i) => `<li class="${type}"><input type="${type}" name="${name}" id="${name}-${i + 1}" value="${v}"${required && (type === "radio" || i === 0) ? " required" : ""}><label for="${name}-${i + 1}">${v}</label></li>`).join("");
    const group = (type, name, legend, values) => `
      <fieldset class="gc-chckbxrdio">
        <legend class="required"><span class="field-name">${legend}</span> <strong class="required">(required)</strong></legend>
        <ul class="list-unstyled lst-spcd-2">${options(type, name, values, true)}</ul>
      </fieldset>`;
    document.querySelector(".wb-frmvld form [type=submit]").insertAdjacentHTML("beforebegin",
      group("radio", "animal", "Which is your favorite pet?", ["Dog", "Cat", "Rat"]) +
      group("checkbox", "cond", "Choose your condiments:", ["Ketchup", "Relish", "Mustard"]) +
      `<div class="checkbox gc-chckbxrdio required"><input id="terms" name="terms" type="checkbox" value="1" required><label for="terms"><span class="field-name">I agree</span> <strong class="required" aria-hidden="true">(required)</strong></label></div>`);
  });

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

// Submit from the keyboard instead, so the summary wb-frmvld focuses gets
// the same :focus-visible ring as ours, which autofocus focuses on load
// (Chrome shows no ring for script focus after a mouse click).
const submitGcwebFormByKeyboard = async (page) => {
  await page.focus(".wb-frmvld form [type=submit]");
  await page.keyboard.press("Enter");
  await page.waitForSelector(".wb-frmvld section[id^='errors-']");
  await page.waitForFunction(() => document.activeElement?.matches("section[id^='errors-']"));
  await page.waitForTimeout(400);
};

// Submit one of our previews in the browser, as a user would, so the
// gcweb--form-validation controller renders its errors and focuses the
// summary. requestSubmit() fires the submit event the controller handles.
const submitPreviewForm = async (page) => {
  await page.evaluate(() => document.querySelector("form").requestSubmit());
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

// Fieldsets. GCWeb's form demo has section fieldsets (legend > h2); the
// "Contact Address" one holds City/Town. It has no fieldset with a required
// marker or error outside gc-chckbxrdio, and no legend-brdr-bttm example,
// so those checks add them to the demo: the error check inserts the markup
// FieldsetComponent renders, and GCWeb's CSS styles it.
const GCWEB_ADDRESS = "fieldset:has([id='00N4t000000PQba'])";
const FIELDSET_PREVIEW = "/rails/view_components/gcweb/form_builder/personal_details";
const OUR_DATE = "fieldset:has(#personal_details_birth_year)";
const addGcwebFieldset = (page) =>
  page.evaluate((address) => {
    // After a section, so (like ours) it is not a first child.
    document.querySelector(address).insertAdjacentHTML("afterend", `
      <fieldset id="dob">
        <legend class="required"><span class="field-name">Date of birth</span> (for example, 1990 07 25) <strong class="required">(required)</strong> <strong id="dob-error" class="error"><span class="label label-danger"><span class="prefix">Error&nbsp;1: </span>This field is required.</span></strong></legend>
        <div class="form-group"><label for="dob-year"><span class="field-name">Year</span></label> <input class="form-control" id="dob-year" type="text" size="4" maxlength="4"></div>
      </fieldset>`);
  }, GCWEB_ADDRESS);

const alertPairs = (variant, scope) => [
  [`${scope}.alert-${variant}`, `${scope}.alert-${variant}`],
  [`${scope}.alert-${variant}::before`, `${scope}.alert-${variant}::before`],
  [`${scope}.alert-${variant} > :first-child`, `${scope}.alert-${variant} > :first-child`],
  [`${scope}.alert-${variant} > :last-child`, `${scope}.alert-${variant} > :last-child`]
];

// Pairs shared by the server-rendered and client-side error checks.
const FORM_ERROR_PAIRS = [
      groupPair("first_name"),
      labelPair("first_name"),
      labelPair("first_name", " > strong.error"),
      labelPair("first_name", " .label-danger"),
      labelPair("first_name", " .prefix"),
      fieldPair("first_name"),
      fieldPair("preferred_language"),
      labelPair("email", " .label-danger"),
      fieldPair("email")
    ];

const SUMMARY_PAIRS = [
      ["section#errors-default", "section#errors-default"],
      ["section#errors-default::before", "section#errors-default::before"],
      ["section#errors-default > h2", "section#errors-default > h2"],
      ["section#errors-default > ul", "section#errors-default > ul"],
      ["section#errors-default li:first-child", "section#errors-default li:first-child"],
      ["section#errors-default li:first-child > a", "section#errors-default li:first-child > a"],
      ["section#errors-default li:first-child .prefix", "section#errors-default li:first-child .prefix"],
      ["section#errors-default li:last-child", "section#errors-default li:last-child"]
    ];

const CHOICE_ERROR_PAIRS = [
      ["fieldset:has(#animal-1)", "fieldset:has(#preference_survey_pet_dog)"],
      ["fieldset:has(#animal-1) > legend", "fieldset:has(#preference_survey_pet_dog) > legend"],
      ["fieldset:has(#animal-1) > legend::before", "fieldset:has(#preference_survey_pet_dog) > legend::before"],
      ["fieldset:has(#animal-1) > legend > strong.required", "fieldset:has(#preference_survey_pet_dog) > legend > strong.required"],
      ["#animal-error", "#preference_survey_pet-error"],
      ["#animal-error .label-danger", "#preference_survey_pet-error .label-danger"],
      ["#animal-error .prefix", "#preference_survey_pet-error .prefix"],
      ["#animal-1", "#preference_survey_pet_dog"],
      ["#cond-error .label-danger", "#preference_survey_condiments-error .label-danger"],
      ["#cond-1", "#preference_survey_condiments_ketchup"],
      ["div.checkbox:has(#terms)", "div.checkbox:has(#preference_survey_terms)"],
      ["div.checkbox:has(#terms)::before", "div.checkbox:has(#preference_survey_terms)::before"],
      ["label[for=terms]", "label[for=preference_survey_terms]"],
      ["label[for=terms]::before", "label[for=preference_survey_terms]::before"],
      ["label[for=terms] > strong.required", "label[for=preference_survey_terms] > strong.required"],
      ["#terms-error .label-danger", "#preference_survey_terms-error .label-danger"]
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
    pairs: FORM_ERROR_PAIRS
  },
  {
    // wb-frmvld focuses its summary after the submit; ours has autofocus.
    name: "form / error summary",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await submitGcwebFormByKeyboard(page);
    },
    preview: `${FORM_PREVIEW}_with_errors`,
    props: FORM_PROPS,
    pairs: SUMMARY_PAIRS
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
  },
  {
    name: "checkboxes / group",
    gcweb: GCWEB_CHOICES,
    preview: `${CHOICES_PREVIEW}/checkboxes_component/default`,
    props: CHOICE_PROPS,
    pairs: [
      ["fieldset.gc-chckbxrdio:has(#cond1)", "fieldset.gc-chckbxrdio"],
      ["fieldset:has(#cond1) > legend", "fieldset.gc-chckbxrdio > legend"],
      ["fieldset:has(#cond1) > ul", "fieldset.gc-chckbxrdio > ul"],
      ["li:has(> #cond1)", "li:has(> #condiments_ketchup)"],
      ["li:has(> #cond2)", "li:has(> #condiments_relish)"],
      ["#cond1", "#condiments_ketchup"],
      ["label[for=cond1]", "label[for=condiments_ketchup]"]
    ]
  },
  {
    name: "checkboxes / boxes",
    gcweb: GCWEB_CHOICES,
    gcwebSetup: check("#cond1"),
    preview: `${CHOICES_PREVIEW}/checkboxes_component/default`,
    previewSetup: check("#condiments_ketchup"),
    props: BOX_PROPS,
    pairs: [
      ["label[for=cond1]::before", "label[for=condiments_ketchup]::before"],
      ["label[for=cond1]::after", "label[for=condiments_ketchup]::after"],
      ["label[for=cond2]::before", "label[for=condiments_relish]::before"],
      ["label[for=cond2]::after", "label[for=condiments_relish]::after"]
    ]
  },
  {
    name: "checkboxes / focus",
    gcweb: GCWEB_CHOICES,
    gcwebSetup: (page) => focus(page, "#cond2"),
    preview: `${CHOICES_PREVIEW}/checkboxes_component/default`,
    previewSetup: (page) => focus(page, "#condiments_relish"),
    props: BOX_PROPS,
    pairs: [["label[for=cond2]::before", "label[for=condiments_relish]::before"]]
  },
  {
    name: "checkboxes / disabled",
    gcweb: GCWEB_CHOICES,
    preview: `${CHOICES_PREVIEW}/checkboxes_component/disabled`,
    props: BOX_PROPS,
    pairs: [["label[for=cond5]::before", "label[for=condiments_relish]::before"]]
  },
  {
    name: "checkboxes / disabled label",
    gcweb: GCWEB_CHOICES,
    preview: `${CHOICES_PREVIEW}/checkboxes_component/disabled`,
    props: CHOICE_PROPS,
    pairs: [
      ["#cond5", "#condiments_relish"],
      ["label[for=cond5]", "label[for=condiments_relish]"]
    ]
  },
  {
    name: "checkboxes / inline",
    gcweb: GCWEB_CHOICES,
    preview: `${CHOICES_PREVIEW}/checkboxes_component/inline`,
    props: CHOICE_PROPS,
    pairs: [
      ["fieldset.form-inline:has(#inlineCheckbox1)", "fieldset.gc-chckbxrdio.form-inline"],
      ["fieldset.form-inline:has(#inlineCheckbox1) > legend", "fieldset.gc-chckbxrdio.form-inline > legend"],
      [".label-inline:has(> #inlineCheckbox1)", ".label-inline:has(> #condiments_ketchup)"],
      [".label-inline:has(> #inlineCheckbox3)", ".label-inline:has(> #condiments_mustard)"],
      ["#inlineCheckbox1", "#condiments_ketchup"],
      ["label[for=inlineCheckbox1]", "label[for=condiments_ketchup]"]
    ]
  },
  {
    name: "radios / boxes",
    gcweb: GCWEB_CHOICES,
    gcwebSetup: check("#animal-1"),
    preview: `${CHOICES_PREVIEW}/radios_component/default`,
    previewSetup: check("#pet_dog"),
    props: BOX_PROPS,
    pairs: [
      ["label[for=animal-1]::before", "label[for=pet_dog]::before"],
      ["label[for=animal-2]::before", "label[for=pet_cat]::before"]
    ]
  },
  {
    name: "radios / group",
    gcweb: GCWEB_CHOICES,
    preview: `${CHOICES_PREVIEW}/radios_component/default`,
    props: CHOICE_PROPS,
    pairs: [
      ["fieldset:has(#animal-1) > legend", "fieldset.gc-chckbxrdio > legend"],
      ["li:has(> #animal-2)", "li:has(> #pet_cat)"],
      ["#animal-1", "#pet_dog"]
    ]
  },
  {
    name: "radios / inline",
    gcweb: GCWEB_CHOICES,
    preview: `${CHOICES_PREVIEW}/radios_component/inline`,
    props: CHOICE_PROPS,
    pairs: [
      [".label-inline:has(> #inlineRadio1)", ".label-inline:has(> #option_1)"],
      [".label-inline:has(> #inlineRadio3)", ".label-inline:has(> #option_3)"],
      ["#inlineRadio1", "#option_1"],
      ["label[for=inlineRadio1]", "label[for=option_1]"]
    ]
  },
  // GCWeb's standalone tickbox (#remember2) sits in a .form-inline that
  // changes its padding, so compare the one in its filter box. That one is
  // in a ul.list-unstyled, hence no list-style-type (inherited, invisible
  // on these elements).
  {
    name: "checkbox / tickbox",
    gcweb: GCWEB_CHOICES,
    gcwebSetup: check("#dt_audience1"),
    preview: `${CHOICES_PREVIEW}/checkbox_component/default`,
    previewSetup: check("#remember_me"),
    props: CHOICE_PROPS.filter((p) => p !== "list-style-type"),
    pairs: [
      ["#dt_audience1", "#remember_me"],
      ["label[for=dt_audience1]", "label[for=remember_me]"]
    ]
  },
  {
    name: "checkbox / tickbox box",
    gcweb: GCWEB_CHOICES,
    gcwebSetup: check("#dt_audience1"),
    preview: `${CHOICES_PREVIEW}/checkbox_component/default`,
    previewSetup: check("#remember_me"),
    props: BOX_PROPS.filter((p) => p !== "list-style-type"),
    pairs: [
      ["label[for=dt_audience1]::before", "label[for=remember_me]::before"],
      ["label[for=dt_audience1]::after", "label[for=remember_me]::after"]
    ]
  },
  {
    name: "checkboxes and radios / errors",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await addGcwebChoices(page);
      await submitGcwebForm(page);
    },
    preview: "/rails/view_components/gcweb/form_builder/preferences_with_errors",
    props: CHOICE_PROPS,
    pairs: CHOICE_ERROR_PAIRS
  },
  {
    name: "fieldset / section",
    gcweb: GCWEB_FORM,
    gcwebSetup: stackGcwebForm,
    preview: FIELDSET_PREVIEW,
    props: FORM_PROPS,
    pairs: [
      // Neither is its form's first child, so both have the rule above.
      [GCWEB_ADDRESS, OUR_DATE],
      [`${GCWEB_ADDRESS} > legend`, "fieldset:has(#personal_details_city) > legend"],
      [`${GCWEB_ADDRESS} > legend > h2`, "fieldset:has(#personal_details_city) > legend > h2"]
    ]
  },
  {
    name: "fieldset / legend-brdr-bttm",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await page.evaluate((s) => document.querySelector(s).classList.add("legend-brdr-bttm"), GCWEB_ADDRESS);
    },
    preview: "/rails/view_components/gcweb/form/fieldset_component/border_bottom",
    props: FORM_PROPS,
    pairs: [
      [GCWEB_ADDRESS, "fieldset.legend-brdr-bttm"],
      [`${GCWEB_ADDRESS} > legend`, "fieldset.legend-brdr-bttm > legend"]
    ]
  },
  {
    name: "fieldset / errors",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await addGcwebFieldset(page);
    },
    preview: `${FIELDSET_PREVIEW}_with_errors`,
    props: FORM_PROPS,
    pairs: [
      ["#dob", OUR_DATE],
      ["#dob > legend", `${OUR_DATE} > legend`],
      ["#dob > legend > .field-name", `${OUR_DATE} > legend > .field-name`],
      ["#dob > legend::before", `${OUR_DATE} > legend::before`],
      ["#dob > legend > strong.required", `${OUR_DATE} > legend > strong.required`],
      ["#dob-error", "#personal_details_date_of_birth-error"],
      ["#dob-error .label-danger", "#personal_details_date_of_birth-error .label-danger"],
      ["#dob-error .prefix", "#personal_details_date_of_birth-error .prefix"]
    ]
  },
  // Client-side validation: our empty forms, submitted in the browser, next
  // to GCWeb's submitted the same way.
  {
    name: "client validation / errors",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await submitGcwebFormByKeyboard(page);
    },
    preview: FORM_PREVIEW,
    previewSetup: submitPreviewForm,
    props: FORM_PROPS,
    pairs: [...FORM_ERROR_PAIRS, ...SUMMARY_PAIRS]
  },
  {
    name: "client validation / checkboxes and radios",
    gcweb: GCWEB_FORM,
    gcwebSetup: async (page) => {
      await stackGcwebForm(page);
      await addGcwebChoices(page);
      await submitGcwebForm(page);
    },
    preview: "/rails/view_components/gcweb/form_builder/preferences",
    previewSetup: submitPreviewForm,
    props: CHOICE_PROPS,
    pairs: CHOICE_ERROR_PAIRS
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
