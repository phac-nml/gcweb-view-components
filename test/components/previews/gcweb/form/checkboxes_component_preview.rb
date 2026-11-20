module Gcweb
  module Form
    # @label Checkboxes
    #
    # GCWeb's large checkboxes (`gc-chckbxrdio`) in a fieldset. The inputs
    # are named `name[]`, so the chosen values arrive as an array. Inside a
    # form, use `f.check_boxes_group`.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-en.html
    # - Canada.ca design system: https://design.canada.ca/common-design-patterns/checkboxes.html
    class CheckboxesComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param label text
      # @param required toggle
      # @param inline toggle
      # @param error text "Error message; leave empty for none"
      def playground(label: "Choose your condiments:", required: false, inline: false, error: "")
        render CheckboxesComponent.new(
          name: "condiments", label: label, required: required, inline: inline,
          choices: condiment_choices, error: error.presence
        )
      end

      # @label Default example
      def default
        render CheckboxesComponent.new(name: "condiments", label: label, choices: condiment_choices)
      end

      # @label Disabled options
      #
      # `disabled:` takes the values to disable; their labels dim to 50%.
      def disabled
        render CheckboxesComponent.new(
          name: "condiments", label: label, choices: condiment_choices, disabled: %w[relish mustard]
        )
      end

      # @label Inline
      #
      # `inline: true` puts the options in a row (GCWeb's `form-inline` variant).
      def inline
        render CheckboxesComponent.new(name: "condiments", label: label, inline: true, choices: condiment_choices)
      end

      # @label With an error
      #
      # A required group after a failed submit. A checkbox's `required`
      # attribute would mean "tick this box", so the group only shows the
      # visible "(required)", which screen readers also read.
      def with_error
        render CheckboxesComponent.new(
          name: "condiments", label: label, required: true, choices: condiment_choices,
          error: I18n.t("activemodel.errors.messages.blank"), error_number: 1
        )
      end

      private

      def label = I18n.t("activemodel.attributes.preference_survey.condiments")

      def condiment_choices
        PreferenceSurvey::CONDIMENTS.map { |c| [ I18n.t("previews.form.condiments.#{c}"), c ] }
      end
    end
  end
end
