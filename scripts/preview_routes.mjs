// Preview routes covered by the a11y and visual-regression checks.
// Each scenario is checked in English and French (?locale=fr).
const SCENARIOS = {
  "gcweb/alert_component": ["with_headings", "with_links", "without_headings", "expand_collapse"],
  "gcweb/featured_link_component": ["default", "custom_background", "with_description"]
};

export const previewRoutes = Object.entries(SCENARIOS).flatMap(([preview, scenarios]) =>
  scenarios.flatMap((scenario) =>
    ["en", "fr"].map((locale) => ({
      name: `${preview.split("/")[1].replace(/_component$/, "").replace(/_/g, "-")}--${scenario.replace(/_/g, "-")}--${locale}`,
      path: `/rails/view_components/${preview}/${scenario}?locale=${locale}`
    }))
  )
);
