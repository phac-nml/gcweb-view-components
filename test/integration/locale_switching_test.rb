require "test_helper"

class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "uses english by default" do
    get root_path

    assert_response :success
    assert_select "h1", "Canada.ca"
    assert_select "main p", "The official website of the Government of Canada"
  end

  test "renders french content when locale is fr" do
    get root_path(locale: :fr)

    assert_response :success
    assert_select "h1", "Canada.ca"
    assert_select "main p", "Le site officiel du gouvernement du Canada"
  end
end
