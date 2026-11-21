require "test_helper"

module Gcweb
  class ServicesAndInformationComponentTest < ComponentTestCase
    def render_srvinfo(count: 2, **options, &block)
      render_inline(ServicesAndInformationComponent.new(**options)) do |srvinfo|
        count.times { |n| srvinfo.with_item(title: "Link #{n + 1}", href: "/page#{n + 1}", description: "Summary #{n + 1}") }
        block&.call(srvinfo)
      end
    end

    test "renders three columns by default, kept equal in height" do
      render_srvinfo

      assert_selector "section.gc-srvinfo > h2", exact_text: "Services and information"
      assert_nil page.find("h2")[:class]
      assert_selector "section.gc-srvinfo > div.wb-eqht-grd.row > div.col-md-6.col-lg-4", count: 2
      assert_selector ".row > div:nth-child(1) > h3 > a[href='/page1']", exact_text: "Link 1"
      assert_selector ".row > div:nth-child(1) > h3 + p", exact_text: "Summary 1"
    end

    test "two columns" do
      render_srvinfo(layout: :two_columns)

      assert_selector ".row > div", count: 2
      assert_equal "col-md-6", page.find(".row > div", match: :first)[:class]
    end

    test "a single column puts the items straight in the section" do
      render_srvinfo(layout: :single)

      assert_no_selector ".row"
      assert_selector "section.gc-srvinfo > h3", count: 2
      assert_selector "section.gc-srvinfo > h3 + p", count: 2
    end

    test "sequential items are a numbered list" do
      render_srvinfo(layout: :sequential)

      assert_selector "section.gc-srvinfo > ol > li", count: 2
      assert_selector "ol > li:nth-child(2) > h3 > a", exact_text: "Link 2"
      assert_selector "ol > li:nth-child(2) > p", exact_text: "Summary 2"
    end

    test "the heading is translated, can be replaced or hidden" do
      I18n.with_locale(:fr) { render_srvinfo }
      assert_selector "h2", exact_text: "Services et renseignements"

      render_srvinfo(title: "Services for Canadians abroad", hidden_title: true, class: "mrgn-tp-lg", id: "abroad")
      assert_selector "section#abroad.gc-srvinfo.mrgn-tp-lg > h2.wb-inv", exact_text: "Services for Canadians abroad"
    end

    test "heading levels" do
      render_srvinfo(heading_level: 3)

      assert_selector "section > h3", text: "Services and information"
      assert_selector ".row h4 > a", count: 2
      assert_no_selector "h2"
    end

    test "an item can have a label and more content, and the component a more information well" do
      render_inline(ServicesAndInformationComponent.new) do |srvinfo|
        srvinfo.with_item(title: "Link", href: "/page", link_attributes: { class: "x" }) do |item|
          item.with_label(variant: :primary) { "(New)" }
          "<p class='extra'>More</p>".html_safe
        end
        srvinfo.with_more_info { "<h3>More information</h3><p>Text</p>".html_safe }
      end

      assert_selector "h3 > a.x + span.label.label-primary", exact_text: "(New)"
      assert_equal "Link (New)", page.find("h3", match: :first).text
      assert_no_selector ".row p:not(.extra)"
      assert_selector ".row p.extra", exact_text: "More"
      assert_selector "section.gc-srvinfo > .row + div.well > h3", exact_text: "More information"
    end

    test "renders nothing without items" do
      render_inline(ServicesAndInformationComponent.new)

      assert_no_selector "section"
    end

    test "rejects bad arguments" do
      assert_raises(ArgumentError) { ServicesAndInformationComponent.new(layout: :four_columns) }
      assert_raises(ArgumentError) { ServicesAndInformationComponent.new(heading_level: 6) }
      assert_raises(ArgumentError) { ServicesAndInformationComponent::ItemComponent.new(title: "", href: "/") }
    end
  end
end
