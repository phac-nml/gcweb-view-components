module Gcweb
  module Form
    # @label Text field
    #
    # GCWeb text input with its label, required marker, hint and inline
    # error. Inside a form, use `f.text_field_group` (see **Form builder**),
    # which fills in the name, id, value, label, required flag and error
    # from the model.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html
    # - Form validation (error markup): https://wet-boew.github.io/wet-boew/docs/ref/formvalid/formvalid-en.html
    class TextFieldComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param label text
      # @param type select { choices: [text, email, tel, url, password, number, search, date] }
      # @param required toggle
      # @param hint text "Shown after the label, e.g. (yourname@domain.com)"
      # @param error text "Error message; leave empty for none"
      def playground(label: "First Name", type: :text, required: true, hint: "", error: "")
        render TextFieldComponent.new(
          name: "first_name", label: label, type: type, required: required,
          hint: hint, error: error.presence, size: 50
        )
      end

      # @label Optional and required
      #
      # A required field gets `class="required"` on the label (red asterisk),
      # GCWeb's "(required)" text, and the `required` attribute on the input.
      def optional_and_required
        render_with_template
      end

      # @label With a hint
      #
      # wet-boew puts format help inside the label, after the field name, so
      # it is part of the accessible name.
      def with_hint
        render TextFieldComponent.new(
          name: "email", type: :email, label: I18n.t("activemodel.attributes.contact_information.email"),
          hint: I18n.t("previews.form.email_hint"), size: 50, autocomplete: "email"
        )
      end

      # @label With an error
      #
      # The markup wet-boew's form validation adds: `has-error` on the group,
      # the message in a `label-danger` inside the label, and
      # `aria-invalid="true"` on the input.
      def with_error
        render TextFieldComponent.new(
          name: "email", type: :email, label: I18n.t("activemodel.attributes.contact_information.email"),
          required: true, value: "not-an-email", size: 50,
          error: I18n.t("activemodel.errors.models.contact_information.attributes.email.invalid"), error_number: 1
        )
      end
    end
  end
end
