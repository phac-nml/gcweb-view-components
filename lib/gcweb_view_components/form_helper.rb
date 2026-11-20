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
    # @param error_summary [Boolean, Hash] false leaves it out; a Hash is
    #   passed to Gcweb::FormBuilder#error_summary (heading_level:, autofocus:)
    def gcweb_form_with(error_summary: true, **options, &block)
      form_with(**options, builder: Gcweb::FormBuilder) do |f|
        f.form_id = options[:id] || options.dig(:html, :id)
        body = capture(f, &block)
        next body unless error_summary

        summary = f.error_summary(**(error_summary.is_a?(Hash) ? error_summary : {}))
        safe_join([ summary, body ].compact)
      end
    end
  end
end
