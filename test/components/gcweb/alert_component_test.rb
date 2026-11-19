require "test_helper"

module Gcweb
  class AlertComponentTest < ComponentTestCase
    test "renders GCWeb markup for an alert with a heading" do
      render_inline(AlertComponent.new(variant: :danger, heading: "Danger alert")) { "<p>Alert details.</p>".html_safe }

      assert_selector "section.alert.alert-danger > h3", text: "Danger alert"
      assert_selector "section.alert.alert-danger > p", text: "Alert details."
    end

    test "uses a div when there is no heading" do
      render_inline(AlertComponent.new(variant: :success)) { "<p>Done.</p>".html_safe }

      assert_selector "div.alert.alert-success > p", text: "Done."
      assert_no_selector "section"
      assert_no_selector "h3"
    end

    test "supports every GCWeb variant" do
      AlertComponent::VARIANTS.each do |variant|
        render_inline(AlertComponent.new(variant: variant))
        assert_selector "div.alert.alert-#{variant}"
      end
    end

    test "heading level and class are configurable" do
      render_inline(AlertComponent.new(variant: :info, heading: "Notice", heading_level: 2, heading_class: "h3"))

      assert_selector "section.alert > h2.h3", text: "Notice"
    end

    test "collapsible alert renders details with the heading in the summary" do
      render_inline(AlertComponent.new(variant: :warning, heading: "Beware", collapsible: true)) { "<p>Body</p>".html_safe }

      assert_selector "section.alert.alert-warning > details:not([open]) > summary > h3.h5", text: "Beware"
      assert_selector "section.alert > details > p", text: "Body", visible: :all
    end

    test "collapsible alert can start open" do
      render_inline(AlertComponent.new(variant: :danger, heading: "Open", collapsible: true, open: true))

      assert_selector "section.alert > details[open]"
    end

    test "passes extra HTML attributes through and appends classes" do
      render_inline(AlertComponent.new(variant: :info, id: "notice", class: "mrgn-tp-lg", data: { testid: "a" }))

      assert_selector "div#notice.alert.alert-info.mrgn-tp-lg[data-testid='a']"
    end

    test "rejects unknown variants, tags and heading levels" do
      assert_raises(ArgumentError) { AlertComponent.new(variant: :primary) }
      assert_raises(ArgumentError) { AlertComponent.new(variant: :info, tag: :aside) }
      assert_raises(ArgumentError) { AlertComponent.new(variant: :info, heading: "x", heading_level: 1) }
      assert_raises(ArgumentError) { AlertComponent.new(variant: :info, collapsible: true) }
    end
  end
end
