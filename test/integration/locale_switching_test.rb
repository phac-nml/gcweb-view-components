require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "uses english by default" do
    get root_path

    assert_response :success
    assert_select "h1", "Component workbench"
    assert_select "main p", "Build and review WET/GCWeb components in isolation."
  end

  test "renders french content when locale is fr" do
    get root_path(locale: :fr)

    assert_response :success
    assert_select "h1", "Atelier des composants"
    assert_select "main p", "Créer et revoir les composants WET/GCWeb de façon isolée."
  end
end
