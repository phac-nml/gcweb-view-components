// Preview routes covered by the a11y and visual-regression checks.
// Each scenario is checked in English and French (?locale=fr).
const SCENARIOS = {
  "gcweb/alert_component": ["with_headings", "with_links", "without_headings", "expand_collapse"],
  "gcweb/featured_link_component": ["default", "custom_background", "with_description"],
  "gcweb/form/text_field_component": ["optional_and_required", "with_hint", "with_error"],
  "gcweb/form/text_area_component": ["default"],
  "gcweb/form/select_component": ["default"],
  "gcweb/form/radios_component": ["default", "inline", "with_error"],
  "gcweb/form/checkboxes_component": ["default", "disabled", "inline", "with_error"],
  "gcweb/form/checkbox_component": ["default", "required_with_error"],
  "gcweb/form_builder": ["contact_information", "contact_information_with_errors", "preferences", "preferences_with_errors"]
};

export const previewRoutes = Object.entries(SCENARIOS).flatMap(([preview, scenarios]) =>
  scenarios.flatMap((scenario) =>
    ["en", "fr"].map((locale) => ({
      name: `${preview.split("/").slice(1).join("-").replace(/_component$/, "").replace(/_/g, "-")}--${scenario.replace(/_/g, "-")}--${locale}`,
      path: `/rails/view_components/${preview}/${scenario}?locale=${locale}`
    }))
  )
);
