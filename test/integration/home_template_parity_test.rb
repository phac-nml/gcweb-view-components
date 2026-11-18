require "test_helper"

class HomeTemplateParityTest < ActionDispatch::IntegrationTest
  test "renders key english home sections" do
    get root_path

    assert_response :success
    assert_select "section.home-featured-link", count: 1
    assert_select "section.home-most-requested li", minimum: 8
    assert_select "section.home-services article", minimum: 9
    assert_select "a.home-services__all", "All services"
  end

  test "renders key french home sections" do
    get root_path(locale: :fr)

    assert_response :success
    assert_select "section.home-featured-link", count: 1
    assert_select "section.home-most-requested h2", "En demande"
    assert_select "section.home-services article", minimum: 9
    assert_select "a.home-services__all", "Tous les services"
  end
end
