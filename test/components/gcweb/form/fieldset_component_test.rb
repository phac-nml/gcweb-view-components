require "test_helper"

module Gcweb
  module Form
    class FieldsetComponentTest < ComponentTestCase
      test "renders a fieldset with a plain legend and the block's content" do
        render_inline(FieldsetComponent.new(legend: "Contact information")) { "<p>Fields</p>".html_safe }

        assert_selector "fieldset:not([class]) > legend:first-child:not([class])", exact_text: "Contact information"
        assert_no_selector "legend span.field-name"
        assert_selector "fieldset > legend + p", text: "Fields"
      end

      test "heading: wraps the legend text in a heading" do
        render_inline(FieldsetComponent.new(legend: "Contact Address", heading: :h2))

        assert_selector "fieldset > legend > h2", exact_text: "Contact Address"
      end

      test "border: :bottom adds legend-brdr-bttm" do
        render_inline(FieldsetComponent.new(legend: "Address", border: :bottom))

        assert_selector "fieldset.legend-brdr-bttm"
      end

      test "a required group marks the legend and leaves (required) for screen readers" do
        render_inline(FieldsetComponent.new(legend: "Date of birth", name: "dob", required: true, hint: "(YYYY MM DD)"))

        assert_selector "legend.required > span.field-name", text: "Date of birth"
        assert_selector "legend", text: "Date of birth (YYYY MM DD) (required)"
        assert_selector "legend > strong.required:not([aria-hidden])"
      end

      test "an error goes in the legend, with the group's id" do
        render_inline(FieldsetComponent.new(legend: "Date of birth", name: "person[dob]", error: "Enter a date", error_number: 2))

        assert_selector "legend > strong#person_dob-error.error > span.label.label-danger", text: "Error 2: Enter a date"
        assert_no_selector "fieldset[aria-invalid]"
      end

      test "the error and required markers can sit in a heading" do
        render_inline(FieldsetComponent.new(legend: "Date of birth", name: "dob", heading: :h3, required: true, error: "Enter a date"))

        assert_selector "legend.required > h3 > span.field-name", text: "Date of birth"
        assert_selector "legend > h3 > strong.error"
      end

      test "other options become fieldset attributes" do
        render_inline(FieldsetComponent.new(legend: "Dates", id: "dates", class: "mrgn-tp-lg", data: { step: "1" }, group_html: { class: "extra" }))

        assert_selector "fieldset.mrgn-tp-lg.extra[data-step='1']"
        assert_no_selector "fieldset#dates"
      end

      test "rejects an unknown heading or border, and an error without a name or id" do
        assert_raises(ArgumentError) { FieldsetComponent.new(legend: "X", heading: :h1) }
        assert_raises(ArgumentError) { FieldsetComponent.new(legend: "X", border: :left) }
        assert_raises(ArgumentError) { FieldsetComponent.new(legend: "X", error: "Bad") }
      end
    end
  end
end
