require "test_helper"

module Gcweb
  class BreadcrumbsComponentTest < ComponentTestCase
    test "renders GCWeb's breadcrumb trail, starting at Canada.ca" do
      render_inline(BreadcrumbsComponent.new) do |trail|
        trail.with_item("Health", "/health")
        trail.with_item("Diseases", "/diseases")
      end

      assert_selector "nav#wb-bc[property=breadcrumb] > h2", text: "You are here:"
      assert_selector "nav#wb-bc > .container > ol.breadcrumb[typeof=BreadcrumbList] > li[property=itemListElement]", count: 3
      assert_selector "li:first-child a[href='https://www.canada.ca/en.html'] span[property=name]", text: "Canada.ca"
      assert_selector "li:nth-child(2) a[property=item][typeof=WebPage][href='/health']", text: "Health"
      assert_selector "li:nth-child(3) meta[property=position][content='3']", visible: :all
    end

    test "in French" do
      with_locale(:fr) { render_inline(BreadcrumbsComponent.new) { |trail| trail.with_item("Santé", "/sante") } }

      assert_selector "h2", text: "Vous êtes ici :"
      assert_selector "li:first-child a[href='https://www.canada.ca/fr.html']"
    end

    test "canada_ca: false starts with the first item" do
      render_inline(BreadcrumbsComponent.new(canada_ca: false)) { |trail| trail.with_item("Home", "/") }

      assert_selector "li", count: 1
      assert_selector "li:first-child a[href='/']", text: "Home"
    end

    test "renders nothing without links, rejects blank text" do
      render_inline(BreadcrumbsComponent.new(canada_ca: false))
      assert_no_selector "nav"

      assert_raises(ArgumentError) { render_inline(BreadcrumbsComponent.new) { |trail| trail.with_item("", "/") } }
    end

    private

    def with_locale(locale, &) = I18n.with_locale(locale, &)
  end
end
