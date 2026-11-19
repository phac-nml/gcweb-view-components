module Gcweb
  module Form
    # @label Select
    #
    # GCWeb select. `prompt: true` adds GCWeb's empty first option
    # ("Make your selection" / "Faites votre choix"), so a required select
    # starts with nothing chosen. Inside a form, use `f.select_group`.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html
    class SelectComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param label text
      # @param required toggle
      # @param prompt toggle
      # @param error text "Error message; leave empty for none"
      def playground(label: "Preferred Language", required: true, prompt: true, error: "")
        render SelectComponent.new(
          name: "preferred_language", label: label, required: required,
          prompt: prompt, choices: language_choices, error: error.presence
        )
      end

      # @label Default example
      def default
        render SelectComponent.new(
          name: "participation", label: I18n.t("previews.form.participation"), required: true, prompt: true,
          choices: %w[In-person Virtual].map { |v| [ I18n.t("previews.form.participation_choices.#{v}"), v ] }
        )
      end

      private

      def language_choices
        ContactInformation::LANGUAGES.map { |l| [ I18n.t("previews.form.languages.#{l}"), l ] }
      end
    end
  end
end
