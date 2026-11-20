module Gcweb
  module Form
    # @label Radio buttons
    #
    # GCWeb's large radio buttons (`gc-chckbxrdio`) in a fieldset. The legend
    # holds the question, the required marker and any error. Inside a form,
    # use `f.radio_buttons_group`.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-en.html
    # - Canada.ca design system: https://design.canada.ca/common-design-patterns/radio-buttons.html
    class RadiosComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param label text
      # @param required toggle
      # @param inline toggle
      # @param error text "Error message; leave empty for none"
      def playground(label: "Which is your favorite pet?", required: true, inline: false, error: "")
        render RadiosComponent.new(
          name: "pet", label: label, required: required, inline: inline,
          choices: pet_choices, error: error.presence
        )
      end

      # @label Default example
      def default
        render RadiosComponent.new(
          name: "pet", label: I18n.t("activemodel.attributes.preference_survey.pet"), choices: pet_choices
        )
      end

      # @label Inline
      #
      # `inline: true` puts the options in a row (GCWeb's `form-inline` variant).
      def inline
        render RadiosComponent.new(
          name: "option", label: I18n.t("previews.form.option_legend"), inline: true,
          choices: (1..3).map { |n| [ I18n.t("previews.form.option", number: n), n ] }
        )
      end

      # @label With an error
      #
      # A required group after a failed submit. The error sits in the legend,
      # where wet-boew's validation puts it, so it is read with the question.
      def with_error
        render RadiosComponent.new(
          name: "pet", label: I18n.t("activemodel.attributes.preference_survey.pet"), required: true,
          choices: pet_choices, error: I18n.t("activemodel.errors.messages.blank"), error_number: 1
        )
      end

      private

      def pet_choices
        PreferenceSurvey::PETS.map { |pet| [ I18n.t("previews.form.pets.#{pet}"), pet ] }
      end
    end
  end
end
