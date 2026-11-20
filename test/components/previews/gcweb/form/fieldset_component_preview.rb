module Gcweb
  module Form
    # @label Fieldset
    #
    # A group of fields under a legend: a section of a form, or one answer
    # split over several fields with the required marker and error on the
    # group. Inside a form, use `f.fieldset_group`.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html
    # - wet-boew form validation: https://wet-boew.github.io/wet-boew/demos/formvalid/formvalid-en.html
    class FieldsetComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param legend text
      # @param heading select { choices: [none, h2, h3, h4] }
      # @param border select { choices: [top, bottom] }
      # @param required toggle
      # @param error text "Error message; leave empty for none"
      def playground(legend: "Date of birth", heading: "none", border: "top", required: true, error: "")
        fieldset(
          { legend: legend, heading: (heading.to_sym unless heading == "none"), border: border.to_sym,
            name: "date_of_birth", required: required, error: error.presence },
          date_fields
        )
      end

      # @label Default example
      #
      # A plain legend, as in wet-boew's form validation demo.
      def default
        fieldset(
          { legend: I18n.t("previews.form.contact_legend") },
          [
            [ "first_name", I18n.t("activemodel.attributes.contact_information.first_name"), { size: 50 } ],
            [ "last_name", I18n.t("activemodel.attributes.contact_information.last_name"), { size: 50 } ]
          ]
        )
      end

      # @label Heading in the legend
      #
      # `heading: :h2` wraps the legend in a heading, as GCWeb's complex
      # structure form does for each section.
      def heading
        fieldset({ legend: I18n.t("previews.form.address_heading"), heading: :h2 }, address_fields)
      end

      # @label Rule under the legend
      #
      # `border: :bottom` (GCWeb's `legend-brdr-bttm`) draws the rule under
      # the legend instead of above the fieldset.
      def border_bottom
        fieldset({ legend: I18n.t("previews.form.address_heading"), border: :bottom }, address_fields)
      end

      # @label With an error
      #
      # A date entered as three fields but validated as one. The required
      # marker and the error are on the legend, so they are read with
      # whichever field gets focus.
      def with_error
        fieldset(
          { legend: I18n.t("activemodel.attributes.personal_details.date_of_birth"), name: "date_of_birth",
            hint: I18n.t("previews.form.date_hint"), required: true,
            error: I18n.t("activemodel.errors.messages.blank"), error_number: 1 },
          date_fields
        )
      end

      private

      def fieldset(options, fields)
        render_with_template(template: "gcweb/form/fieldset_component_preview/fieldset", locals: { fieldset: options, fields: fields })
      end

      def address_fields
        [
          [ "address", I18n.t("activemodel.attributes.personal_details.address"), { maxlength: 100, size: 50 } ],
          [ "city", I18n.t("activemodel.attributes.personal_details.city"), { maxlength: 50, size: 50 } ],
          [ "postal_code", I18n.t("activemodel.attributes.personal_details.postal_code"), { maxlength: 7, size: 7 } ]
        ]
      end

      def date_fields
        %w[year month day].map do |part|
          [ "birth_#{part}", I18n.t("activemodel.attributes.personal_details.birth_#{part}"),
            { size: part == "year" ? 4 : 2, maxlength: part == "year" ? 4 : 2, inputmode: "numeric" } ]
        end
      end
    end
  end
end
