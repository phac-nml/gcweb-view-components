module Gcweb
  module Form
    # @label Error summary
    #
    # The list of errors wet-boew's form validation puts at the top of a
    # form when a submit fails, each linking to its field. `gcweb_form_with`
    # adds it for you (see the form builder's "with errors" previews).
    #
    # These previews pass `autofocus: false` so they don't take focus in
    # Lookbook; in a form the summary is focused when the page loads.
    #
    # - GCWeb working example (submit it empty): https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html
    # - wet-boew form validation: https://wet-boew.github.io/wet-boew/docs/ref/formvalid/formvalid-en.html
    class ErrorSummaryComponentPreview < ViewComponent::Preview
      # @label Default example
      #
      # The required fields of GCWeb's "Contact Information" section, empty.
      def default
        render ErrorSummaryComponent.new(autofocus: false, errors: %w[first_name last_name preferred_language email].each_with_index.map { |field, i|
          { number: i + 1, target: "contact_information_#{field}", label: I18n.t("activemodel.attributes.contact_information.#{field}"), message: blank }
        })
      end

      # @label One error
      def one_error
        render ErrorSummaryComponent.new(autofocus: false, errors: [
          { number: 1, target: "contact_information_email", label: I18n.t("activemodel.attributes.contact_information.email"),
            message: I18n.t("activemodel.errors.models.contact_information.attributes.email.invalid") }
        ])
      end

      # @label Errors without a field
      #
      # An error with no target (a model's `:base` errors, or an attribute
      # the form has no field for) is listed without a link, after the
      # others, as wb-frmvld does for errors it can't place.
      def without_links
        render ErrorSummaryComponent.new(autofocus: false, errors: [
          { number: 1, target: "contact_information_first_name", label: I18n.t("activemodel.attributes.contact_information.first_name"), message: blank },
          { number: 2, target: nil, label: nil, message: I18n.t("previews.form.base_error") }
        ])
      end

      private

      def blank = I18n.t("activemodel.errors.messages.blank")
    end
  end
end
