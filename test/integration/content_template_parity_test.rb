require "test_helper"

class ContentTemplateParityTest < ActionDispatch::IntegrationTest
  test "renders english content template sections" do
    get content_page_path

    assert_response :success
    assert_select "nav.content-page__breadcrumbs", count: 1
    assert_select "h1", "Jobs"
    assert_select "section.content-page__alert h2", "Danger alert"
    assert_select "section.content-page__most-requested li", minimum: 4
    assert_select "section.content-page__services article", minimum: 8
    assert_select "dl#wb-dtmd dt", "Date modified:"
  end

  test "renders french content template sections" do
    get content_page_path(locale: :fr)

    assert_response :success
    assert_select "h1", "Emplois"
    assert_select "section.content-page__alert h2", "Alerte de danger"
    assert_select "section.content-page__most-requested h2", "En demande"
    assert_select "section.content-page__services article", minimum: 8
    assert_select "dl#wb-dtmd dt", "Date de modification :"
  end
end
