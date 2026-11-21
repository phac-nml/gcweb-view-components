// Compare our Lookbook previews against GCWeb's own demo pages, element by
// element, using fully-cascaded computed styles. Computed styles do not depend
// on the OS or font rasteriser, so this is stable across macOS and Linux CI.
//
//   pnpm parity:check     compare previews with test/gcweb_reference/<version>.json
//   pnpm parity:capture   re-read GCWeb's demo pages and rewrite that JSON
//                         (do this when bumping GcwebViewComponents::GCWEB_VERSION)
//   pnpm parity:live      compare previews with the live GCWeb demo site
//
// PARITY_ONLY=<text> runs only the checks whose names contain it (not with
// --capture, which rewrites the whole reference).
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

// Buttons. GCWeb's button page has no ids, so selectors pick the first
// match in <main>, which is the example in the section our preview copies.
// Bootstrap 3 buttons have no transitions, so states apply at once.
const GCWEB_BUTTONS = "/common/button/button-en.html";
const BUTTON_PREVIEW = "/rails/view_components/gcweb/button_component";
// No outline-color: both sides draw the focus ring with
// -webkit-focus-ring-color, which Chrome resolves per OS (blue on macOS,
// near-black on Linux), so a reference captured on one fails on the other.
// Outside focus it is currentColor, which color already covers.
const BUTTON_PROPS = [
  ...FORM_PROPS,
  "cursor", "min-width", "text-shadow", "outline-offset",
  "border-top-right-radius", "border-bottom-left-radius", "touch-action", "user-select"
];
const BUTTON_COLOURS = ["default", "primary", "success", "info", "warning", "danger", "link"];
const hover = (selector) => (page) => page.hover(selector);
// Press and hold: :active, :hover and :focus at once.
const press = (selector) => async (page) => {
  await page.hover(selector);
  await page.mouse.down();
};
const buttonCheck = (name, preview, pairs, extra = {}) => ({
  name: `button / ${name}`,
  gcweb: GCWEB_BUTTONS,
  preview: `${BUTTON_PREVIEW}/${preview}`,
  props: BUTTON_PROPS,
  pairs: pairs.map((p) => (typeof p === "string" ? [`main ${p}`, `main ${p}`] : p)),
  ...extra
});
// One check per state, each on a freshly loaded page.
const buttonStateChecks = (state, setup, selectors, preview) =>
  selectors.map(([label, selector]) =>
    buttonCheck(`${label} ${state}`, preview, [selector], {
      gcwebSetup: setup(`main ${selector}`),
      previewSetup: setup(`main ${selector}`)
    }));
const colourButtons = [
  ...BUTTON_COLOURS.map((v) => [v, `button.btn-${v}`]),
  ["call to action", "button.btn-call-to-action"]
];
const previewFor = (label) => (label === "call to action" ? "call_to_action" : "colours");

const BUTTON_CHECKS = [
  buttonCheck("basic use", "default", [
    "button.btn-default[type=submit]",
    "input.btn-default[type=button]",
    "input.btn-default[type=submit]",
    "a.btn-default"
  ]),
  buttonCheck("colours", "colours", BUTTON_COLOURS.map((v) => `button.btn-${v}`)),
  buttonCheck("call to action", "call_to_action", ["button.btn-call-to-action"]),
  buttonCheck("sizing", "sizing", ["button.btn-xs", "button.btn-sm", "button.btn-lg"]),
  buttonCheck("full width", "full_width", ["button.btn-block"]),
  buttonCheck("active", "states", ["button.btn-default.active", "a.btn-default.active"]),
  // GCWeb's example uses class="disabled"; ButtonComponent sets the
  // disabled attribute on buttons. Both match the same rules.
  buttonCheck("disabled", "states", [
    ["main button.btn-default.disabled", "main button.btn-default[disabled]"],
    ["main a.btn-default.disabled", "main a.btn-default.disabled"]
  ]),
  ...colourButtons.flatMap(([label, selector]) =>
    buttonStateChecks("hover", hover, [[label, selector]], previewFor(label))),
  ...colourButtons.flatMap(([label, selector]) =>
    buttonStateChecks("focus", (s) => (page) => focus(page, s), [[label, selector]], previewFor(label))),
  ...buttonStateChecks("pressed", press, [["default", "button.btn-default[type=submit]"]], "default"),
  ...buttonStateChecks("pressed", press, [["primary", "button.btn-primary"], ["link", "button.btn-link"]], "colours")
];

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

// Tabs (wb-tabs). GCWeb's demo is on the compiled-demos site, not under
// gcwebBase. Its first example has panels details-panel1..3 (2 open), the
// second details-panel10..30; the previews use the same ids.
const GCWEB_TABS = "https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/tabs/tabs-en.html";
const TABS_PREVIEW = "/rails/view_components/gcweb/tabs_component";
const TABS_PROPS = [...FORM_PROPS, "cursor", "z-index", "top", "overflow-x", "overflow-y", "visibility", "max-height", "text-indent", "list-style-type"];
const tabsPairs = (gcwebRoot, ourRoot, suffixes) => suffixes.map((suffix) => [`${gcwebRoot}${suffix}`, `${ourRoot}${suffix}`]);
const EXAMPLE_1 = ".wb-tabs:has(> .tabpanels > [id='details-panel2'])";
const EXAMPLE_2 = ".wb-tabs:has(> .tabpanels > [id='details-panel20'])";
const clickTab = (id) => async (page) => {
  await page.click(`[id='${id}-lnk']`);
  await page.waitForTimeout(400);
};
const focusTab = (id) => (page) => page.focus(`[id='${id}-lnk']`);

// Toggle (wb-toggle). wet-boew wraps each accordion <details> in a
// div.tgl-tab[role=tab]; the gem keeps the <details> as the accordion's
// children, so the selectors differ by that level.
const GCWEB_TOGGLE = "https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/toggle/toggle-en.html";
const GCWEB_SECTION = (n) => `.accordion > div:nth-child(${n}) > details`;
const OUR_SECTION = (n) => `#accordion > details:nth-child(${n})`;
const clickSummary = (selector) => async (page) => {
  await page.click(`${selector} > summary`);
  await page.waitForTimeout(300);
};
const focusSummary = (selector) => (page) => page.focus(`${selector} > summary`);
const GCWEB_PERSISTED = "section:has(> #persist) > details";
const GCWEB_PRINT_ON = "section:has(> #print) li:first-child > details";

// Overlay (wb-overlay). The previews use GCWeb's ids and markup, so the
// selectors are the same on both sides. Each check opens an overlay from
// the keyboard (Enter on its link), as GCWeb's script then focuses it the
// same way ours does, and the mouse stays off it.
const GCWEB_OVERLAY = "https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/overlay/overlay-en.html";
const OVERLAY_PREVIEW = "/rails/view_components/gcweb/overlay_component";
// Like the other checks, no width, height, top or left: they follow the
// rendered text, which differs between macOS and Linux.
const OVERLAY_PROPS = [
  ...FORM_PROPS, "cursor", "z-index", "float", "outline-offset", "transform", "overflow-y", "max-height",
  "border-top-right-radius", "border-bottom-left-radius", "user-select"
];
const openOverlay = (id) => async (page) => {
  await page.focus(`a.overlay-lnk[href='#${id}']`);
  await page.keyboard.press("Enter");
  await page.waitForTimeout(400);
};
const focusOverlayClose = (id) => async (page) => {
  await openOverlay(id)(page);
  await page.keyboard.press("Shift+Tab");
  await page.waitForTimeout(100);
};
const overlayParts = (id, parts) => parts.map((part) => `#${id}${part}`).map((s) => [s, s]);
const PANEL_PARTS = [
  "", " > header", " .modal-title", " > .modal-body", " .modal-body li:first-child > a",
  " > .modal-footer", " > .modal-footer > .overlay-close", " > .mfp-close"
];
const BAR_PARTS = ["", " > header", " .modal-title", " > .list-inline", " > .list-inline > li:first-child", " .btn", " > .mfp-close"];
const POPUP_PARTS = [
  "", " > header", " .modal-title", " > .modal-body", " .modal-body > ol", " .modal-body > ol > li:first-child",
  " .modal-body code", " > .modal-footer", " > .modal-footer > .overlay-close", " > .mfp-close"
];
const overlayCheck = (name, id, parts, scenario, setup = openOverlay) => ({
  name: `overlay / ${name}`,
  gcweb: GCWEB_OVERLAY,
  gcwebSetup: setup(id),
  preview: `${OVERLAY_PREVIEW}/${scenario}`,
  previewSetup: setup(id),
  props: OVERLAY_PROPS,
  pairs: overlayParts(id, parts)
});

// Labels and badges (components/labels, components/badges). The previews
// use GCWeb's demo markup (a <dl> of examples), so the selectors are the
// same on both sides. GCWeb's "label as a link" has no href (so it isn't a
// link); the checks give it one, as the component renders.
const LABEL_PROPS = [...FORM_PROPS, "cursor", "border-image-width"];
const LABEL = (n) => `dl:has(.label) > dd:nth-of-type(${n}) .label`;
const addLabelHref = (page) => page.evaluate(() => document.querySelector("dl:has(.label) > dd:nth-of-type(7) a.label").setAttribute("href", "#"));
const hoverLabelLink = async (page) => {
  await page.hover("dl:has(.label) > dd:nth-of-type(7) a.label");
  await page.waitForTimeout(100);
};
const BADGE_GREY = "a:not(.btn) > .badge:not(:empty)";
const BADGE_BUTTON = "a.btn-primary > .badge";

// Panels and wells (components/panels). GCWeb lays the stacking examples
// out in grid columns, which the preview doesn't, so widths aren't
// compared (as everywhere). GCWeb has no wells demo: the wells check adds
// GCWeb's documented well markup to its panels page and lets GCWeb's CSS
// render it.
const GCWEB_PANELS = "/components/panels/panels-en.html";
const PANELS_PREVIEW = "/rails/view_components/gcweb/panel_component";
const PANEL_PROPS = [...FORM_PROPS, "border-top-right-radius", "border-bottom-left-radius"];
const PANEL_BOX_PARTS = ["", " > .panel-heading", " .panel-title", " > .panel-body", " > .panel-body > p"];
const panelPairs = (gcwebPanel, ourPanel, parts) => parts.map((part) => [`${gcwebPanel}${part}`, `${ourPanel}${part}`]);
const APPEARANCE = (n) => `dl:has(.panel) > dd:nth-of-type(${n}) > .panel`;
const WELL_PARTS = [".well-sm", ".well:not(.well-sm, .well-lg, .well-bold)", ".well-lg", ".well-bold", ".well-bold > p", ".well-bold strong"];
const addGcwebWells = (page) =>
  page.evaluate(() => {
    document.querySelector("main h1").insertAdjacentHTML("afterend", `
      <div class="parity-wells">
        <div class="well well-sm"><p>Small well</p></div>
        <div class="well"><p>Well</p></div>
        <div class="well well-lg"><p>Large well</p></div>
        <div class="well well-bold"><p>Bold well with <strong>strong text</strong></p></div>
      </div>`);
  });

// In-page table of contents (components/gc-toc). GCWeb v20.0.1 has no
// gc-toc styles, so this checks that the base layer renders its heading,
// list and links, and the sections they point to, as GCWeb does.
const TOC_PARTS = [
  "nav.gc-toc", "nav.gc-toc > h2", "nav.gc-toc > ul",
  "nav.gc-toc > ul > li:nth-child(1)", "nav.gc-toc > ul > li:nth-child(3)",
  "nav.gc-toc > ul > li:nth-child(1) > a",
  "section:has(> #section1) > h2", "section:has(> #section1) > p"
];

// Services and information (components/gc-srvinfo). GCWeb's demos keep
// the columns equal in height with the wb-eqht plugin, which writes inline
// min-heights that depend on the viewport; the gem uses wet-boew's CSS-only
// .wb-eqht-grd. The GCWeb side swaps the plugin for that class (which
// GCWeb's CSS has) before comparing, so both sides lay out the same grid.
// GCWeb's demo pages also limit the content width (body.cnt-wdth-lmtd,
// which caps heading and paragraph widths); the gem doesn't have that page
// option yet, and widths aren't compared (as everywhere).
const GCWEB_SRVINFO = "/components/gc-srvinfo/gc-srvinfo-en.html";
const SRVINFO_PREVIEW = "/rails/view_components/gcweb/services_and_information_component";
const SRVINFO_PROPS = [...PROPS, "float", "flex-direction", "align-items", "flex-wrap", "vertical-align"];
const useEqhtGrid = (page) =>
  page.evaluate(() => {
    for (const row of document.querySelectorAll(".gc-srvinfo .wb-eqht")) {
      row.classList.remove("wb-eqht", "wb-init", "wb-eqht-inited");
      row.classList.add("wb-eqht-grd");
      for (const column of row.children) column.removeAttribute("style");
    }
  });
const COLUMN_PARTS = (n) => [` > .row > div:nth-child(${n})`, ` > .row > div:nth-child(${n}) > h3`, ` > .row > div:nth-child(${n}) > h3 > a`, ` > .row > div:nth-child(${n}) > p`];
const srvinfoPairs = (gcwebSection, ourSection, parts) => parts.map((part) => [`${gcwebSection}${part}`, `${ourSection}${part}`]);
// `~`: some examples have a note between their heading and the section.
const SRVINFO = (example) => `#${example} ~ section.gc-srvinfo`;
const srvinfoCheck = (name, example, preview, parts, extra = {}) => ({
  name: `services and information / ${name}`,
  gcweb: GCWEB_SRVINFO,
  gcwebSetup: useEqhtGrid,
  preview: `${SRVINFO_PREVIEW}/${preview}`,
  props: SRVINFO_PROPS,
  pairs: srvinfoPairs(SRVINFO(example), "main section.gc-srvinfo", ["", " > h2", ...parts]),
  ...extra
});
const THREE_COLUMN_PARTS = [" > .row", ...COLUMN_PARTS(1), ...COLUMN_PARTS(4)];

// Most requested (components/gc-most-requested): a full-width band, so the
// previews use the full-width layout like GCWeb's "no-container" demos.
// From 992px the heading floats beside a two-column list, so the checks
// also compare floats, columns and widths (both sides have the same fixed
// container width at each viewport).
const GCWEB_MOST_REQUESTED = "/components/gc-most-requested/gc-most-requested";
const MOST_REQUESTED_PREVIEW = "/rails/view_components/gcweb/most_requested_component";
const MOST_REQUESTED_PROPS = [...PROPS, "float", "clear", "width", "column-count", "column-gap", "vertical-align"];
const MOST_REQUESTED_PARTS = (items) => [
  "", " > .container", " > .container::after", " > .container > h2", " > .container > ul",
  ...items.flatMap((n) => [` li:nth-child(${n})`, ` li:nth-child(${n}) > a`, ` li:nth-child(${n})::before`])
];
const mostRequestedCheck = (name, page, preview, sections, extra = {}) => ({
  name: `most requested / ${name}`,
  gcweb: `${GCWEB_MOST_REQUESTED}${page}-en.html`,
  preview: `${MOST_REQUESTED_PREVIEW}/${preview}`,
  props: MOST_REQUESTED_PROPS,
  pairs: sections.flatMap(([section, parts]) => parts.map((part) => [`${section}${part}`, `${section}${part}`])),
  ...extra
});
const MOST_REQUESTED = "main section.gc-most-requested";
const SIX_ITEMS = [[MOST_REQUESTED, MOST_REQUESTED_PARTS([1, 2, 6])]];

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
  mostRequestedCheck("default", "", "default", SIX_ITEMS),
  mostRequestedCheck("medium screens", "", "default", SIX_ITEMS, { viewport: { width: 1000, height: 900 } }),
  mostRequestedCheck("small screens", "", "default", SIX_ITEMS, { viewport: { width: 375, height: 812 } }),
  mostRequestedCheck("two items", "-two-items", "two_items", [[MOST_REQUESTED, MOST_REQUESTED_PARTS([1, 2])]]),
  mostRequestedCheck("highlight", "-highlight", "highlight", [
    [`${MOST_REQUESTED}:has(~ .gc-most-requested)`, MOST_REQUESTED_PARTS([1])],
    [`${MOST_REQUESTED} ~ section.gc-most-requested`, MOST_REQUESTED_PARTS([1])]
  ]),
  mostRequestedCheck("with labels", "-labels", "with_labels", [
    [MOST_REQUESTED, [...MOST_REQUESTED_PARTS([1]), ...[1, 2, 3, 4, 5, 6].map((n) => ` li:nth-child(${n}) > .label`)]]
  ]),
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
  },
  ...BUTTON_CHECKS,
  {
    name: "tabs / default",
    gcweb: GCWEB_TABS,
    preview: `${TABS_PREVIEW}/default`,
    props: TABS_PROPS,
    pairs: tabsPairs(EXAMPLE_1, ".wb-tabs", [
      "",
      " > ul[role=tablist]",
      " > ul[role=tablist] > li:first-child",
      " > ul[role=tablist] > li:first-child > a",
      " > ul[role=tablist] > li.active",
      " > ul[role=tablist] > li.active > a",
      " > ul[role=tablist] > li:last-child > a",
      " > .tabpanels",
      " > .tabpanels > [id='details-panel2']",
      " > .tabpanels > [id='details-panel2'] > summary",
      " > .tabpanels > [id='details-panel2'] > .tgl-panel",
      " > .tabpanels > [id='details-panel2'] > .tgl-panel > p",
      " > .tabpanels > [id='details-panel1']"
    ])
  },
  {
    name: "tabs / focused tab",
    gcweb: GCWEB_TABS,
    gcwebSetup: focusTab("details-panel1"),
    preview: `${TABS_PREVIEW}/default`,
    previewSetup: focusTab("details-panel1"),
    props: TABS_PROPS,
    pairs: [["[id='details-panel1-lnk']", "[id='details-panel1-lnk']"]]
  },
  {
    name: "tabs / details inside a panel",
    gcweb: GCWEB_TABS,
    gcwebSetup: clickTab("details-panel20"),
    preview: `${TABS_PREVIEW}/ignore_session`,
    previewSetup: clickTab("details-panel20"),
    props: TABS_PROPS,
    pairs: tabsPairs(EXAMPLE_2, ".wb-tabs", [
      " > ul[role=tablist] > li.active > a",
      " > .tabpanels > [id='details-panel20']",
      " > .tabpanels > [id='details-panel20'] details",
      " > .tabpanels > [id='details-panel20'] details > summary",
      " > .tabpanels > [id='details-panel10']"
    ])
  },
  {
    name: "tabs / small screen accordion",
    gcweb: GCWEB_TABS,
    preview: `${TABS_PREVIEW}/default`,
    viewport: { width: 375, height: 812 },
    props: TABS_PROPS,
    pairs: tabsPairs(EXAMPLE_1, ".wb-tabs", [
      "",
      " > ul[role=tablist]",
      " > .tabpanels",
      " > .tabpanels > [id='details-panel1']",
      " > .tabpanels > [id='details-panel1'] > summary",
      " > .tabpanels > [id='details-panel2']",
      " > .tabpanels > [id='details-panel2'] > summary",
      " > .tabpanels > [id='details-panel2'] > .tgl-panel",
      " > .tabpanels > [id='details-panel3']",
      " > .tabpanels > [id='details-panel3'] > summary"
    ])
  },
  {
    name: "accordion / open section",
    gcweb: GCWEB_TOGGLE,
    gcwebSetup: clickSummary(GCWEB_SECTION(2)),
    preview: "/rails/view_components/gcweb/accordion_component/default",
    previewSetup: clickSummary(OUR_SECTION(2)),
    props: TABS_PROPS,
    pairs: [
      [".accordion", "#accordion"],
      [GCWEB_SECTION(1), OUR_SECTION(1)],
      [`${GCWEB_SECTION(1)} > summary`, `${OUR_SECTION(1)} > summary`],
      [GCWEB_SECTION(2), OUR_SECTION(2)],
      [`${GCWEB_SECTION(2)} > summary`, `${OUR_SECTION(2)} > summary`],
      [`${GCWEB_SECTION(2)} > .tgl-panel`, `${OUR_SECTION(2)} > .tgl-panel`],
      [`${GCWEB_SECTION(2)} > .tgl-panel > p`, `${OUR_SECTION(2)} > .tgl-panel > p`]
    ]
  },
  {
    name: "accordion / focused summary",
    gcweb: GCWEB_TOGGLE,
    gcwebSetup: focusSummary(GCWEB_SECTION(1)),
    preview: "/rails/view_components/gcweb/accordion_component/default",
    previewSetup: focusSummary(OUR_SECTION(1)),
    props: TABS_PROPS,
    pairs: [[`${GCWEB_SECTION(1)} > summary`, `${OUR_SECTION(1)} > summary`]]
  },
  {
    name: "toggle / print states",
    gcweb: GCWEB_TOGGLE,
    preview: "/rails/view_components/gcweb/toggle/print_states",
    props: TABS_PROPS,
    pairs: [
      [GCWEB_PRINT_ON, "ul.list-unstyled li:first-child > details"],
      [`${GCWEB_PRINT_ON} > summary`, "ul.list-unstyled li:first-child > details > summary"],
      [`${GCWEB_PRINT_ON} > summary > code`, "ul.list-unstyled li:first-child > details > summary > code"]
    ]
  },
  {
    name: "toggle / persisted details, opened",
    gcweb: GCWEB_TOGGLE,
    gcwebSetup: clickSummary(GCWEB_PERSISTED),
    preview: "/rails/view_components/gcweb/toggle/persist",
    previewSetup: clickSummary("details:has(> #persisted-summary)"),
    props: TABS_PROPS,
    pairs: [
      [GCWEB_PERSISTED, "details:has(> #persisted-summary)"],
      [`${GCWEB_PERSISTED} > summary`, "#persisted-summary"],
      [`${GCWEB_PERSISTED} > p`, "details:has(> #persisted-summary) > p"]
    ]
  },
  {
    name: "labels / with text",
    gcweb: "/components/labels/labels-en.html",
    gcwebSetup: addLabelHref,
    preview: "/rails/view_components/gcweb/label_component/default",
    props: LABEL_PROPS,
    pairs: [1, 2, 3, 4, 5, 6, 7].map((n) => [LABEL(n), LABEL(n)])
  },
  {
    name: "labels / link, hovered",
    gcweb: "/components/labels/labels-en.html",
    gcwebSetup: async (page) => { await addLabelHref(page); await hoverLabelLink(page); },
    preview: "/rails/view_components/gcweb/label_component/default",
    previewSetup: hoverLabelLink,
    props: LABEL_PROPS,
    pairs: [[LABEL(7), LABEL(7)]]
  },
  {
    name: "badges / default",
    gcweb: "/components/badges/badges-en.html",
    preview: "/rails/view_components/gcweb/badge_component/default",
    props: [...FORM_PROPS, "top", "min-width", "border-bottom-left-radius"],
    pairs: [[BADGE_GREY, BADGE_GREY], [BADGE_BUTTON, BADGE_BUTTON]]
  },
  {
    name: "badges / self collapsing",
    gcweb: "/components/badges/badges-en.html",
    preview: "/rails/view_components/gcweb/badge_component/self_collapsing",
    props: FORM_PROPS,
    pairs: [["a > .badge:empty", "a > .badge:empty"]]
  },
  {
    name: "panels / stacking options",
    gcweb: GCWEB_PANELS,
    preview: `${PANELS_PREVIEW}/stacking`,
    props: PANEL_PROPS,
    pairs: [
      ...panelPairs("main .row > div:nth-child(1) > .panel", ".panel-examples > div:nth-child(1) > .panel", PANEL_BOX_PARTS),
      ...panelPairs("main .row > div:nth-child(4) > .panel", ".panel-examples > div:nth-child(2) > .panel", [...PANEL_BOX_PARTS, " > .panel-footer"])
    ]
  },
  {
    name: "panels / appearances",
    gcweb: GCWEB_PANELS,
    preview: `${PANELS_PREVIEW}/appearances`,
    props: PANEL_PROPS,
    pairs: [1, 2, 3, 4, 5, 6].flatMap((n) => panelPairs(APPEARANCE(n), APPEARANCE(n), PANEL_BOX_PARTS))
  },
  {
    name: "wells / sizes and bold",
    gcweb: GCWEB_PANELS,
    gcwebSetup: addGcwebWells,
    preview: "/rails/view_components/gcweb/well_component/default",
    props: PANEL_PROPS,
    pairs: WELL_PARTS.map((part) => [`.parity-wells ${part}`, `main ${part}`])
  },
  {
    name: "table of contents / default",
    gcweb: "/components/gc-toc/toc-en.html",
    preview: "/rails/view_components/gcweb/table_of_contents_component/default",
    pairs: TOC_PARTS.map((part) => [part, part])
  },
  srvinfoCheck("three columns", "eg1", "three_columns", THREE_COLUMN_PARTS),
  srvinfoCheck("three columns, medium screens", "eg1", "three_columns", THREE_COLUMN_PARTS, { viewport: { width: 1000, height: 900 } }),
  srvinfoCheck("three columns, small screens", "eg1", "three_columns", THREE_COLUMN_PARTS, { viewport: { width: 375, height: 812 } }),
  srvinfoCheck("two columns", "eg2", "two_columns", [" > .row", ...COLUMN_PARTS(1), ...COLUMN_PARTS(3)]),
  srvinfoCheck("single column", "eg3", "single_column", [" > h3:nth-of-type(1)", " > h3:nth-of-type(1) > a", " > p:nth-of-type(1)", " > h3:nth-of-type(3)", " > p:nth-of-type(3)"]),
  srvinfoCheck("sequential", "eg4", "sequential", [" > ol", " > ol > li:nth-child(1)", " > ol > li:nth-child(1) > h3", " > ol > li:nth-child(1) > h3 > a", " > ol > li:nth-child(1) > p", " > ol > li:nth-child(3)"]),
  {
    name: "services and information / grouped with headings",
    gcweb: GCWEB_SRVINFO,
    gcwebSetup: useEqhtGrid,
    preview: `${SRVINFO_PREVIEW}/grouped`,
    props: SRVINFO_PROPS,
    pairs: [
      ...srvinfoPairs(SRVINFO("eg5"), "main section.gc-srvinfo:nth-of-type(1)", ["", " > h2", " > .row", ...COLUMN_PARTS(1)]),
      ...srvinfoPairs(`${SRVINFO("eg5")} + section.gc-srvinfo`, "main section.gc-srvinfo:nth-of-type(2)", ["", " > h2", " > .row", ...COLUMN_PARTS(3)])
    ]
  },
  {
    name: "services and information / with labels",
    gcweb: "/components/gc-srvinfo/gc-srvinfo-labels-en.html",
    gcwebSetup: useEqhtGrid,
    preview: `${SRVINFO_PREVIEW}/with_labels`,
    props: SRVINFO_PROPS,
    pairs: srvinfoPairs("main section.gc-srvinfo", "main section.gc-srvinfo", [
      "", " > h2", " > .row", ...COLUMN_PARTS(1),
      ...[1, 2, 3, 4, 5, 6].map((n) => ` > .row > div:nth-child(${n}) > h3 > .label`)
    ])
  },
  {
    name: "services and information / with more information",
    gcweb: "/components/gc-srvinfo/gc-srvinfo-more-info-en.html",
    gcwebSetup: useEqhtGrid,
    preview: `${SRVINFO_PREVIEW}/more_information`,
    props: SRVINFO_PROPS,
    pairs: srvinfoPairs("main section.gc-srvinfo", "main section.gc-srvinfo", [
      "", " > h2", " > .row", ...COLUMN_PARTS(1), " > .well", " > .well > h3", " > .well > p"
    ])
  },
  overlayCheck("left panel", "left-panel", PANEL_PARTS, "panels"),
  overlayCheck("right panel", "right-panel", PANEL_PARTS, "panels"),
  overlayCheck("top bar", "top-bar", BAR_PARTS, "bars"),
  overlayCheck("bottom bar", "bottom-bar", BAR_PARTS, "bars"),
  overlayCheck("middle screen", "mid-screen", POPUP_PARTS, "popups"),
  overlayCheck("middle screen with background", "mid-screen-bg", POPUP_PARTS, "popups"),
  overlayCheck("full screen", "full-screen", POPUP_PARTS, "full_screen"),
  overlayCheck("full screen, hidden header", "hidden-header", [...POPUP_PARTS.filter((part) => part !== " .modal-title"), " > header > h2"], "full_screen"),
  overlayCheck("focused close button", "left-panel", [" > .mfp-close"], "panels", focusOverlayClose),
  {
    name: "overlay / closed",
    gcweb: GCWEB_OVERLAY,
    preview: `${OVERLAY_PREVIEW}/panels`,
    props: OVERLAY_PROPS,
    pairs: [["#left-panel", "#left-panel"], ["a.overlay-lnk[href='#left-panel']", "a.overlay-lnk[href='#left-panel']"]]
  }
];

const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const page = await context.newPage();

const DEFAULT_VIEWPORT = { width: 1280, height: 900 };
const gcwebUrl = (location) => (/^https?:/.test(location) ? location : gcwebBase + location);

const load = async (url, viewport = DEFAULT_VIEWPORT) => {
  await page.setViewportSize(viewport);
  await page.mouse.up(); // release a press left by the previous check
  await page.goto(url, { waitUntil: "networkidle" });
  await page.evaluate(() => document.fonts.ready);
};

const propsFor = (check) => check.props || PROPS;

const readGcweb = async (check) => {
  await load(gcwebUrl(check.gcweb), check.viewport);
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
const only = process.env.PARITY_ONLY;

for (const check of CHECKS.filter((c) => !only || c.name.includes(only))) {
  const expectedStyles = reference ? reference.checks[check.name] || {} : await readGcweb(check);
  await load(previewBase + check.preview, check.viewport);
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
