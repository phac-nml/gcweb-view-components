module Gcweb
  # @label Form builder
  #
  # `Gcweb::FormBuilder` renders GCWeb form groups from a model. It is
  # opt-in: use `gcweb_form_with` or `form_with(builder: Gcweb::FormBuilder)`.
  #
  # ```erb
  # <%= gcweb_form_with model: @contact, url: contacts_path do |f| %>
  #   <%= f.text_field_group :first_name %>
  #   <%= f.text_area_group :post_nominals, rows: 4 %>
  #   <%= f.select_group :preferred_language, choices, prompt: true %>
  #   <%= f.text_field_group :email, type: :email %>
  # <% end %>
  # ```
  #
  # Labels come from `human_attribute_name`, the required marker from
  # presence validators, and errors from `model.errors`, numbered like
  # wet-boew's "Error 1: …".
  #
  # The example is the "Contact Information" section of GCWeb's
  # [complex structure form](https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html).
  class FormBuilderPreview < ViewComponent::Preview
    # @label Contact information
    def contact_information
      render_with_template(template: "gcweb/form_builder_preview/contact_information", locals: { contact: ContactInformation.new })
    end

    # @label Contact information with errors
    #
    # The same form after a failed submit: the model's validation errors,
    # rendered server-side with the markup wet-boew's validation uses.
    def contact_information_with_errors
      render_with_template(template: "gcweb/form_builder_preview/contact_information", locals: { contact: ContactInformation.with_errors })
    end
  end
end
