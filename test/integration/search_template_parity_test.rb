require "test_helper"

class SearchTemplateParityTest < ActionDispatch::IntegrationTest
  test "renders english search template sections" do
    get search_page_path

    assert_response :success
    assert_select "h1", "Search results"
    assert_select "form[action='#{search_page_path}'] input[name='q'][value='jobs']", count: 1
    assert_select "section#wb-land h2", /4 search results/
    assert_select "div.search-page__results article.search-result", minimum: 4
    assert_select "ul.search-page__pagination li.active", count: 1
    assert_select "p.search-page__advanced a", "Perform an advanced search"
  end

  test "renders french search template sections" do
    get search_page_path(locale: :fr)

    assert_response :success
    assert_select "h1", "Résultats de la recherche"
    assert_select "form[action='#{search_page_path(locale: :fr)}'] input[name='q'][value='emploi']", count: 1
    assert_select "section#wb-land h2", /4 résultats de recherche/
    assert_select "div.search-page__results article.search-result", minimum: 4
    assert_select "ul.search-page__pagination li.active", count: 1
    assert_select "p.search-page__advanced a", "Effectuer une recherche avancée"
  end
end
