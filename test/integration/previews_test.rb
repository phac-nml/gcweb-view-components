require "test_helper"

# Every Lookbook scenario must render, in both languages, through the same
# controller Lookbook uses.
class PreviewsTest < ActionDispatch::IntegrationTest
  SCENARIOS = {
    "gcweb/alert_component" => %w[playground with_headings with_links without_headings expand_collapse],
    "gcweb/button_component" => %w[playground default colours call_to_action sizing full_width states],
    "gcweb/featured_link_component" => %w[playground default custom_background with_description],
    "gcweb/most_requested_component" => %w[playground default two_items highlight with_labels],
    "gcweb/label_component" => %w[playground default],
    "gcweb/badge_component" => %w[playground default self_collapsing],
    "gcweb/panel_component" => %w[playground stacking appearances],
    "gcweb/well_component" => %w[playground default],
    "gcweb/header_component" => %w[playground canada_ca application application_search],
    "gcweb/table_component" => %w[playground basic striped bordered hover condensed contextual responsive gridify in_panels],
    "gcweb/data_table_component" => %w[playground default descending paged turbo_frame filtered no_matches],
    "gcweb/pagination_component" => %w[playground first_page second_page middle_page last_page],
    "gcweb/table_of_contents_component" => %w[playground default],
    "gcweb/services_and_information_component" => %w[playground three_columns two_columns single_column sequential grouped with_labels more_information],
    "gcweb/overlay_component" => %w[playground panels bars popups full_screen custom_footer open_on_load],
    "gcweb/form/text_field_component" => %w[playground optional_and_required with_hint with_error],
    "gcweb/form/text_area_component" => %w[playground default],
    "gcweb/form/select_component" => %w[playground default],
    "gcweb/form/radios_component" => %w[playground default inline with_error],
    "gcweb/form/checkboxes_component" => %w[playground default disabled inline with_error],
    "gcweb/form/checkbox_component" => %w[playground default required_with_error],
    "gcweb/form/fieldset_component" => %w[playground default heading border_bottom with_error],
    "gcweb/form/error_summary_component" => %w[default one_error without_links],
    "gcweb/form_builder" => %w[
      contact_information contact_information_with_errors client_validation
      preferences preferences_with_errors
      personal_details personal_details_with_errors
    ]
  }.freeze

  SCENARIOS.each do |preview, scenarios|
    scenarios.each do |scenario|
      %w[en fr].each do |locale|
        test "#{preview}/#{scenario} renders in #{locale}" do
          get "/rails/view_components/#{preview}/#{scenario}", params: { locale: locale }

          assert_response :success
          assert_select "html[lang=?]", locale
          assert_select "main"
          # The skip link's target: <main> in most layouts, the <h1> in the page-shell one.
          assert_select "#wb-cont"
        end
      end
    end
  end

  test "the data table preview sorts and filters from the URL" do
    get "/rails/view_components/gcweb/data_table_component/default", params: { sort: "browser", direction: "desc", q: "Opera" }

    assert_select "thead th.sorting_desc[aria-sort=descending]", "Browser"
    assert_select "tbody tr", 8
    assert_select "tbody tr:first-child td.sorting_1", "Opera for Wii"
    assert_select ".dataTables_info", "Showing 1 to 8 of 8 entries (filtered from 57 total entries)"
    assert_select "thead th:nth-child(1) a[href*='q=Opera']"
  end

  test "the data table preview pages with Pagy" do
    get "/rails/view_components/gcweb/data_table_component/paged", params: { page: 6, sort: "browser", locale: "en" }

    assert_select "tbody tr", 7
    assert_select ".dataTables_info", "Showing 51 to 57 of 57 entries"
    assert_select ".pagination li.active a[aria-current=page]", /6/
    assert_select ".pagination a[rel=prev][href*='page=5'][href*='sort=browser']"
    assert_select ".pagination a[rel=next]", 0

    get "/rails/view_components/gcweb/data_table_component/paged", params: { page: 2, limit: 25, locale: "en" }

    assert_select "tbody tr", 25
    assert_select "select[name=limit] option[selected]", "25"
    assert_select ".pagination a[rel=next][href*='limit=25']"
  end

  test "alert previews use GCWeb's demo text per locale" do
    get "/rails/view_components/gcweb/alert_component/with_headings", params: { locale: "fr" }
    assert_select "section.alert.alert-danger > h3", "Alerte de danger"

    get "/rails/view_components/gcweb/alert_component/expand_collapse"
    assert_select "section.alert.alert-danger > details[open] > summary > h3.h5", "Danger alert (expanded by default)"
    assert_select "section.alert > details", count: 4
  end

  test "featured link previews render full width (no container on main)" do
    get "/rails/view_components/gcweb/featured_link_component/custom_background"

    assert_select "main.container", count: 0
    assert_select "section.gc-featured-link[data-bg-color]", count: 3
  end

  test "form builder previews show the model's errors per locale" do
    get "/rails/view_components/gcweb/form_builder/contact_information"
    assert_select ".form-group", 7
    assert_select ".has-error", 0

    get "/rails/view_components/gcweb/form_builder/contact_information_with_errors", params: { locale: "fr" }
    assert_select ".form-group.has-error", 4
    assert_select "#contact_information_first_name-error .label-danger", "Erreur\u00A01\u00A0: Ce champ est obligatoire."
    assert_select ".field_with_errors", 0
    assert_select "form > section#errors-default[autofocus] > h2", "Le formulaire n'a pu être soumis car 4 erreurs ont été trouvées."

    get "/rails/view_components/gcweb/form_builder/preferences_with_errors", params: { locale: "fr" }
    assert_select "fieldset.gc-chckbxrdio legend strong.error", 2
    assert_select "#preference_survey_terms-error .label-danger", "Erreur\u00A03\u00A0: Ce champ est obligatoire."

    get "/rails/view_components/gcweb/form_builder/personal_details_with_errors", params: { locale: "fr" }
    assert_select "fieldset > legend > h2", "Adresse de contact"
    assert_select "fieldset > legend.required #personal_details_date_of_birth-error .label-danger", "Erreur\u00A01\u00A0: Ce champ est obligatoire."
    assert_select ".has-error", 0
  end

  test "preview pages send a CSP header without unsafe-inline scripts" do
    get "/rails/view_components/gcweb/featured_link_component/custom_background"

    csp = response.headers["Content-Security-Policy"]
    assert csp.present?
    assert_includes csp, "object-src 'none'"
    assert_match(/script-src [^;]*'nonce-/, csp)
    assert_no_match(/script-src [^;]*'unsafe-inline'/, csp)
  end

  test "mounts Lookbook" do
    get "/lookbook"
    assert_response :success
  end
end
