// Preview routes covered by the a11y and visual-regression checks.
// Each scenario is checked in English and French (?locale=fr).
const SCENARIOS = {
  "gcweb/alert_component": ["with_headings", "with_links", "without_headings", "expand_collapse"],
  "gcweb/button_component": ["default", "colours", "call_to_action", "sizing", "full_width", "states"],
  "gcweb/featured_link_component": ["default", "custom_background", "with_description"],
  "gcweb/most_requested_component": ["default", "two_items", "highlight", "with_labels"],
  "gcweb/tabs_component": ["default", "ignore_session", "many_tabs"],
  "gcweb/accordion_component": ["default", "persist"],
  "gcweb/toggle": ["details_elements", "print_states", "grouped", "persist"],
  "gcweb/label_component": ["default"],
  "gcweb/badge_component": ["default", "self_collapsing"],
  "gcweb/panel_component": ["stacking", "appearances"],
  "gcweb/well_component": ["default"],
  "gcweb/header_component": ["canada_ca", "application", "application_search"],
  "gcweb/table_component": ["basic", "striped", "bordered", "hover", "condensed", "contextual", "responsive", "gridify", "in_panels"],
  "gcweb/data_table_component": ["default", "descending", "paged", "turbo_frame", "filtered", "no_matches"],
  "gcweb/pagination_component": ["first_page", "second_page", "middle_page", "last_page"],
  "gcweb/table_of_contents_component": ["default"],
  "gcweb/services_and_information_component": ["three_columns", "two_columns", "single_column", "sequential", "grouped", "with_labels", "more_information"],
  "gcweb/overlay_component": ["panels", "bars", "popups", "full_screen", "custom_footer", "open_on_load"],
  "gcweb/form/text_field_component": ["optional_and_required", "with_hint", "with_error"],
  "gcweb/form/text_area_component": ["default"],
  "gcweb/form/select_component": ["default"],
  "gcweb/form/radios_component": ["default", "inline", "with_error"],
  "gcweb/form/checkboxes_component": ["default", "disabled", "inline", "with_error"],
  "gcweb/form/checkbox_component": ["default", "required_with_error"],
  "gcweb/form/fieldset_component": ["default", "heading", "border_bottom", "with_error"],
  "gcweb/form/error_summary_component": ["default", "one_error", "without_links"],
  "gcweb/form_builder": [
    "contact_information", "contact_information_with_errors", "client_validation",
    "preferences", "preferences_with_errors",
    "personal_details", "personal_details_with_errors"
  ]
};

export const previewRoutes = Object.entries(SCENARIOS).flatMap(([preview, scenarios]) =>
  scenarios.flatMap((scenario) =>
    ["en", "fr"].map((locale) => ({
      name: `${preview.split("/").slice(1).join("-").replace(/_component$/, "").replace(/_/g, "-")}--${scenario.replace(/_/g, "-")}--${locale}`,
      path: `/rails/view_components/${preview}/${scenario}?locale=${locale}`
    }))
  )
);
