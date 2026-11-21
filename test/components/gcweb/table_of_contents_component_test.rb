require "test_helper"

module Gcweb
  class TableOfContentsComponentTest < ComponentTestCase
    def render_toc(**options)
      render_inline(TableOfContentsComponent.new(**options)) do |toc|
        toc.with_link("First section heading", href: "#section1")
        toc.with_link(href: "#section2", class: "x") { "Second section heading" }
      end
    end

    test "renders GCWeb's nav.gc-toc with a heading and a list of links" do
      render_toc

      assert_selector "nav.gc-toc > h2", exact_text: "On this page"
      assert_selector "nav.gc-toc > ul > li", count: 2
      assert_selector "nav.gc-toc > ul > li:nth-child(1) > a[href='#section1']", exact_text: "First section heading"
      assert_selector "nav.gc-toc > ul > li:nth-child(2) > a.x[href='#section2']", exact_text: "Second section heading"
      assert_nil page.find("h2")[:class]
    end

    test "the heading is translated" do
      I18n.with_locale(:fr) { render_toc }

      assert_selector "nav.gc-toc > h2", exact_text: "Sur cette page"
    end

    test "takes a title, heading level and nav attributes" do
      render_toc(title: "Contents", heading_level: 3, class: "mrgn-bttm-lg", id: "toc")

      assert_selector "nav#toc.gc-toc.mrgn-bttm-lg > h3", exact_text: "Contents"
      assert_no_selector "h2"
    end

    test "renders nothing without links" do
      render_inline(TableOfContentsComponent.new)

      assert_no_selector "nav"
    end

    test "rejects bad arguments" do
      assert_raises(ArgumentError) { TableOfContentsComponent.new(heading_level: 1) }
      assert_raises(ArgumentError) { TableOfContentsComponent::LinkComponent.new("Text", href: "") }
    end
  end
end
