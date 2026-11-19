module Gcweb
  module Form
    # GCWeb select with its label (common/form).
    #
    #   <%= render Gcweb::Form::SelectComponent.new(
    #         name: "language", label: "Preferred language", required: true,
    #         choices: [ [ "English", "en" ], [ "French", "fr" ] ], prompt: true) %>
    #
    # Inside a form, prefer the builder: `f.select_group :language, choices, prompt: true`.
    class SelectComponent < FieldComponent
      # @param choices [Array, Hash, String] anything options_for_select accepts, or
      #   prebuilt <option> HTML (e.g. from grouped_options_for_select)
      # @param prompt [Boolean, String, nil] first, empty option; true uses GCWeb's
      #   "Make your selection" / "Faites votre choix"
      # @see FieldComponent#initialize for the other options
      def initialize(choices:, prompt: nil, **options)
        @choices = choices
        @prompt = prompt
        super(**options)
      end

      private

      def control
        attrs = base_control_attributes
        attrs[:name] = "#{attrs[:name]}[]" if attrs[:multiple] && !attrs[:name].end_with?("[]")

        tag.select(**attrs) { safe_join([ prompt_option, option_tags ].compact) }
      end

      def prompt_option
        return if @prompt.blank?

        text = @prompt == true ? t("gcweb.form.select_prompt") : @prompt
        tag.option(text, value: "")
      end

      def option_tags
        return @choices if @choices.is_a?(ActiveSupport::SafeBuffer)

        options_for_select(@choices, value)
      end
    end
  end
end
