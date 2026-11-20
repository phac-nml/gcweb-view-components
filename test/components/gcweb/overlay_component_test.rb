require "test_helper"

module Gcweb
  class OverlayComponentTest < ComponentTestCase
    def render_overlay(content = "Body", **options, &block)
      render_inline(OverlayComponent.new(id: "panel", title: "Left panel", **options), &(block || proc { content }))
    end

    test "renders GCWeb's panel markup for the gcweb--overlay controller" do
      render_overlay(variant: :panel_left)

      section = page.find("section#panel.wb-overlay.modal-content.overlay-def.wb-panel-l", visible: :all)
      assert_equal "gcweb--overlay", section["data-controller"]
      assert_equal "panel-title", section["aria-labelledby"]
      assert_selector "section > header.modal-header > h2.modal-title#panel-title", text: "Left panel", visible: :all
      assert_selector "section > div.modal-body", text: "Body", visible: :all
    end

    test "renders the close buttons wet-boew adds" do
      render_overlay(variant: :panel_left)

      assert_selector "section > div.modal-footer > button.btn.btn-sm.btn-primary.pull-right.overlay-close[type=button]", text: "Close overlay", visible: :all
      corner = page.find("section > div.modal-footer + button.mfp-close.overlay-close[type=button]", visible: :all)
      assert_equal "Close: Left panel (escape key)", corner["title"]
      assert_includes corner.text(:all), "×"
      assert_selector "button.mfp-close > span.wb-inv", text: "Close: Left panel (escape key)", visible: :all
    end

    test "the footer button floats left except on left panels" do
      render_overlay(variant: :popup_mid)

      assert_selector ".modal-footer > button.pull-left", visible: :all
    end

    test "bars have no modal-body, modal-header or footer" do
      render_overlay(variant: :bar_top)

      assert_selector "section.wb-bar-t > header:not(.modal-header) > h2.modal-title", visible: :all
      assert_no_selector ".modal-body, .modal-footer", visible: :all
      assert_selector "section.wb-bar-t > button.mfp-close", visible: :all
    end

    test "hidden_header keeps the heading for screen readers only" do
      render_overlay(variant: :popup_full, hidden_header: true)

      assert_selector "section.wb-popup-full.hidden-hd:not(.overlay-def)", visible: :all
      assert_selector "section > header:not(.modal-header) > h2.wb-inv#panel-title", visible: :all
      assert_equal "Close: Left panel (escape key)", page.find("button.mfp-close", visible: :all)["title"]
    end

    test "background, close_outside and open" do
      render_overlay(variant: :popup_mid, background: true, close_outside: false, open: true)

      section = page.find("section", visible: :all)
      assert_includes section[:class].split, "overlay-bg"
      assert_includes section[:class].split, "outside-off"
      assert_equal "true", section["data-gcweb--overlay-open-value"]
    end

    test "a footer with its own close button replaces wet-boew's" do
      render_inline(OverlayComponent.new(id: "panel", title: "Popup")) do |overlay|
        overlay.with_footer { '<button class="btn btn-primary overlay-close" type="button">Done</button>'.html_safe }
        "Body"
      end

      assert_selector ".modal-footer > button.overlay-close", count: 1, text: "Done", visible: :all
    end

    test "a footer without one keeps wet-boew's close button" do
      render_inline(OverlayComponent.new(id: "panel", title: "Popup")) do |overlay|
        overlay.with_footer { "Footer note" }
        "Body"
      end

      assert_selector ".modal-footer", text: "Footer note", visible: :all
      assert_selector ".modal-footer > button.btn.overlay-close", visible: :all
    end

    test "uses French labels" do
      I18n.with_locale(:fr) { render_overlay(variant: :panel_right) }

      assert_equal "Fermer : Left panel (touche d'échappement)", page.find("button.mfp-close", visible: :all)["title"]
      assert_selector ".modal-footer > button", text: "Fermer la fenêtre superposée", visible: :all
    end

    test "keeps extra attributes and classes" do
      render_overlay(class: "no-print", data: { controller: "other", test: "x" })

      section = page.find("section", visible: :all)
      assert_includes section[:class].split, "no-print"
      assert_equal "other gcweb--overlay", section["data-controller"]
      assert_equal "x", section["data-test"]
    end

    test "heading_level" do
      render_overlay(heading_level: 3)

      assert_selector "header > h3.modal-title", visible: :all
    end

    test "rejects bad options" do
      assert_raises(ArgumentError) { OverlayComponent.new(id: "", title: "T") }
      assert_raises(ArgumentError) { OverlayComponent.new(id: "a", title: "") }
      assert_raises(ArgumentError) { OverlayComponent.new(id: "a", title: "T", variant: :lightbox) }
      assert_raises(ArgumentError) { OverlayComponent.new(id: "a", title: "T", heading_level: 1) }
    end
  end
end
