module GcwebViewComponents
  # Included into every view by the engine.
  module FormHelper
    # form_with using Gcweb::FormBuilder. Takes the same options as form_with.
    #
    #   <%= gcweb_form_with model: @applicant do |f| %>
    #     <%= f.text_field_group :email, type: :email %>
    #   <% end %>
    def gcweb_form_with(**options, &block)
      form_with(**options, builder: Gcweb::FormBuilder, &block)
    end
  end
end
