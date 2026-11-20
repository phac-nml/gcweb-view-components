module GcwebViewComponents
  # Included into every view by the engine.
  module FormHelper
    # form_with using Gcweb::FormBuilder. Takes the same options as form_with.
    #
    #   <%= gcweb_form_with model: @applicant do |f| %>
    #     <%= f.text_field_group :email, type: :email %>
    #   <% end %>
    #
    # When the fields show errors, an error summary
    # (Gcweb::Form::ErrorSummaryComponent) is added as the form's first
    # child, where wet-boew's form validation puts it. The fields are
    # rendered first, so the summary's numbers and links match them.
    #
    # The form also gets the gcweb--form-validation Stimulus controller,
    # which checks fields in the browser before submitting and shows errors
    # with the same markup, in the page's language. It sets novalidate
    # itself, so without the controllers registered the browser's own
    # validation still applies.
    #
    # @param error_summary [Boolean, Hash] false leaves it out; a Hash is
    #   passed to Gcweb::FormBuilder#error_summary (heading_level:, autofocus:)
    # @param validate [Boolean] false leaves out client-side validation
    def gcweb_form_with(error_summary: true, validate: true, **options, &block)
      summary_options = error_summary.is_a?(Hash) ? error_summary : {}
      options = gcweb_validation_options(options, heading_level: summary_options.fetch(:heading_level, 2)) if validate

      form_with(**options, builder: Gcweb::FormBuilder) do |f|
        f.form_id = options[:id] || options.dig(:html, :id)
        body = capture(f, &block)
        next body unless error_summary

        safe_join([ f.error_summary(**summary_options), body ].compact)
      end
    end

    private

    def gcweb_validation_options(options, heading_level:)
      data = (options[:data] || {}).to_h.transform_keys(&:to_sym)
      controllers = [ data[:controller], "gcweb--form-validation" ].compact_blank.join(" ")

      options.merge(data: data.merge(
        controller: controllers,
        "gcweb--form-validation-messages-value": gcweb_validation_messages.to_json,
        "gcweb--form-validation-heading-level-value": heading_level
      ))
    end

    # The strings the controller needs, from the gem's locale files, with
    # their %{…} placeholders kept for the controller to fill in.
    def gcweb_validation_messages
      heading = I18n.t("gcweb.form.error_summary.heading")

      I18n.t("gcweb.form.validation").merge(
        prefix: I18n.t("gcweb.form.error_prefix_numbered", number: "%{number}"),
        summaryOne: heading[:one],
        summaryOther: heading[:other],
        separator: I18n.t("gcweb.form.error_summary.separator")
      )
    end
  end
end
