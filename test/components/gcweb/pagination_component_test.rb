require "test_helper"
require "pagy"

module Gcweb
  class PaginationComponentTest < ComponentTestCase
    def render_pages(page, pages, **options)
      render_inline(PaginationComponent.new(page:, pages:, url: ->(number) { "/list?page=#{number}" }, **options))
    end

    def numbers = page.all("li > a:not([rel])").map { |link| link[:href][/\d+\z/].to_i }

    test "renders GCWeb's pagination" do
      render_pages(2, 3)

      assert_selector "nav[aria-label=Pagination] > ol.pagination > li", count: 5
      assert_selector "li:first-child > a[rel=prev][href='/list?page=1']", text: "Previous"
      assert_selector "li.active", count: 1
      assert_selector "li.active > a.current[aria-current=page][href='/list?page=2']", text: "Jump to: Page 2"
      assert_selector "li:last-child > a[rel=next][href='/list?page=3']", text: "Next"
    end

    test "leaves out previous on the first page and next on the last" do
      render_pages(1, 3)
      assert_no_selector "[rel=prev]"
      assert_selector "[rel=next]"

      render_pages(3, 3)
      assert_selector "[rel=prev]"
      assert_no_selector "[rel=next]"
    end

    test "shows the pages GCWeb's data tables show" do
      { 1 => [ 1, 2, 3, 4, 5, 12 ], 4 => [ 1, 2, 3, 4, 5, 12 ], 5 => [ 1, 4, 5, 6, 12 ],
        8 => [ 1, 7, 8, 9, 12 ], 9 => [ 1, 8, 9, 10, 11, 12 ], 11 => [ 1, 8, 9, 10, 11, 12 ] }.each do |current, expected|
        render_pages(current, 12)
        assert_equal expected, numbers, "page #{current}"
      end

      render_pages(4, 7)
      assert_equal (1..7).to_a, numbers
    end

    test "beyond the last page, previous goes to the last page" do
      render_pages(20, 12)

      assert_selector "[rel=prev][href='/list?page=12']"
      assert_no_selector "[rel=next]"
      assert_no_selector ".active"
    end

    test "renders nothing for one page" do
      render_pages(1, 1)
      assert_no_selector "nav"
    end

    test "attributes and French strings" do
      I18n.with_locale(:fr) { render_pages(2, 3, label: "Résultats", controls: "list", class: "text-center", list_attributes: { class: "mrgn-tp-0" }) }

      assert_selector "nav.text-center[aria-label='Résultats'] > ol.pagination.mrgn-tp-0"
      assert_selector "a[aria-controls=list]", text: "Précédent"
      assert_selector "a[aria-current]", text: "Aller à: Page 2"
    end

    test "reads a Pagy object" do
      request = Pagy::Request.new(request: { base_url: "http://test.host", path: "/samples", params: { "page" => "2", "q" => "a" }, cookie: nil })
      render_inline(PaginationComponent.new(pagy: Pagy::Offset.new(count: 57, page: 2, limit: 10, request:)))

      assert_equal (1..6).to_a, numbers_from_query
      assert_selector "a[rel=next][href='/samples?page=3&q=a']"
    end

    test "needs a counted Pagy, or a page, pages and url" do
      assert_raises(ArgumentError) { PaginationComponent.new(page: 1, pages: 2) }
      assert_raises(ArgumentError) { PaginationComponent.new(pagy: Pagy::Offset::Countless.new(page: 1, limit: 10)) }
    end

    private

    def numbers_from_query = page.all("li > a:not([rel])").map { |link| link[:href][/page=(\d+)/, 1].to_i }
  end
end
