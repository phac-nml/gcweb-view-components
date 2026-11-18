require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "uses english by default" do
    get root_path

    assert_response :success
    assert_select "h1", "GCWeb View Components"
  end

  test "renders french content when locale is fr" do
    get root_path(locale: :fr)

    assert_response :success
    assert_select "h1", "Composants de vue GCWeb"
  end
end
