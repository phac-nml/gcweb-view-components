require "test_helper"

module Gcweb
  class MostRequestedComponentTest < ComponentTestCase
    def render_most_requested(**options)
      render_inline(MostRequestedComponent.new(**options)) do |most_requested|
        most_requested.with_link("Apply for benefits", href: "/apply")
        most_requested.with_link("Report a change", href: "/change", class: "x")
      end
    end

    test "renders GCWeb's section.gc-most-requested with a container, a heading and a list of links" do
      render_most_requested

      assert_selector "section.gc-most-requested > div.container > h2", exact_text: "Most requested"
      assert_selector "section.gc-most-requested > div.container > h2 + ul > li", count: 2
      assert_selector "li:nth-child(1) > a[href='/apply']", exact_text: "Apply for benefits"
      assert_selector "li:nth-child(2) > a.x[href='/change']", exact_text: "Report a change"
      assert_no_selector ".label"
    end

    test "the heading is translated" do
      I18n.with_locale(:fr) { render_most_requested }

      assert_selector "section.gc-most-requested h2", exact_text: "En demande"
    end

    test "takes a title, heading level and section attributes" do
      render_most_requested(title: "Popular tasks", heading_level: 3, class: "mrgn-tp-lg", id: "popular")

      assert_selector "section#popular.gc-most-requested.mrgn-tp-lg h3", exact_text: "Popular tasks"
      assert_no_selector "h2"
    end

    test "a link can have a label after it" do
      render_inline(MostRequestedComponent.new) do |most_requested|
        most_requested.with_link("Apply", href: "#") do |link|
          link.with_label(variant: :primary) { "(New)" }
        end
      end

      assert_selector "li > a + span.label.label-primary", exact_text: "(New)"
      assert_equal "Apply (New)", page.find("li").text
    end

    test "renders nothing without links" do
      render_inline(MostRequestedComponent.new)

      assert_no_selector "section"
    end

    test "rejects bad arguments" do
      assert_raises(ArgumentError) { MostRequestedComponent.new(heading_level: 1) }
      assert_raises(ArgumentError) { MostRequestedComponent::LinkComponent.new("", href: "#") }
    end
  end
end
