require "test_helper"

module Gcweb
  class PanelComponentTest < ComponentTestCase
    test "renders GCWeb's panel markup" do
      render_inline(PanelComponent.new(variant: :info, title: "Panel title")) { "Panel content" }

      assert_selector "section.panel.panel-info > header.panel-heading > h3.panel-title", text: "Panel title"
      assert_selector "section.panel > header.panel-heading + div.panel-body", text: "Panel content"
      assert_no_selector ".panel-footer"
    end

    test "each variant" do
      PanelComponent::VARIANTS.each do |variant|
        render_inline(PanelComponent.new(variant: variant, title: "T")) { "C" }

        assert_selector ".panel.panel-#{variant}"
      end
    end

    test "a footer" do
      render_inline(PanelComponent.new(title: "Panel title")) do |panel|
        panel.with_footer { "Panel footer" }
        "Content"
      end

      assert_selector ".panel-body + footer.panel-footer", text: "Panel footer"
    end

    test "without a title it's a div with no heading" do
      render_inline(PanelComponent.new) { "Content" }

      assert_selector "div.panel.panel-default > div.panel-body", text: "Content"
      assert_no_selector ".panel-heading"
    end

    test "body: false puts the content straight in the panel" do
      render_inline(PanelComponent.new(title: "T", body: false)) { "<ul class='list-group'></ul>".html_safe }

      assert_selector ".panel > .panel-heading + ul.list-group", visible: :all
      assert_no_selector ".panel-body"
    end

    test "heading_level, tag and extra attributes" do
      render_inline(PanelComponent.new(title: "T", heading_level: 2, tag: :div, id: "p", class: "mrgn-bttm-0")) { "C" }

      assert_selector "div#p.panel.panel-default.mrgn-bttm-0 > header > h2.panel-title"
    end

    test "rejects bad options" do
      assert_raises(ArgumentError) { PanelComponent.new(variant: :purple) }
      assert_raises(ArgumentError) { PanelComponent.new(heading_level: 7) }
      assert_raises(ArgumentError) { PanelComponent.new(tag: :aside) }
    end
  end
end
