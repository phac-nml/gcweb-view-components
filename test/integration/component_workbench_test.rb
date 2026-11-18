require "test_helper"

class ComponentWorkbenchTest < ActionDispatch::IntegrationTest
  test "renders component backlog and preview links" do
    get root_path

    assert_response :success
    assert_select "h1", "Component workbench"
    assert_select "table.workbench__table tbody tr", minimum: 1
    assert_select "a[href='/rails/view_components']", "Open Rails component previews"
    assert_select "a[href='/rails/view_components/gcweb/featured_link_component/en']", "Open featured link preview (EN)"
  end

  test "renders alert component preview route" do
    get "/rails/view_components/gcweb/alert_component/en"

    assert_response :success
    assert_select "h1", "GCWeb Alert examples"
    assert_select "section.alert.alert-warning h3", "Warning alert"
    assert_select "a.alert-link", text: "link text", count: 4
    assert_select "div.alert.alert-success p", "(Success content here.)"
    assert_select "h2#expand-collapse", "Alert with expand/collapse"
    assert_select "section.alert.alert-danger details[open] h3.h5", "Danger alert (expanded by default)"
  end

  test "mounts lookbook" do
    skip "Lookbook not loaded in this bundle" unless defined?(Lookbook::Engine)

    get "/lookbook"

    assert_response :success
  end

  test "renders featured link component preview route" do
    get "/rails/view_components/gcweb/featured_link_component/en"

    assert_response :success
    assert_select "h1", "Featured link"
    assert_select "section.gc-featured-link", minimum: 5
    assert_select "section.gc-featured-link[data-bg-color='#005B61']", count: 1
    assert_select "a.stretched-link", text: "[Promotion title]", count: 5
  end
end
