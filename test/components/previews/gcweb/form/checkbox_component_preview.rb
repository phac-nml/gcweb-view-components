module Gcweb
  module Form
    # @label Checkbox (tickbox)
    #
    # A single, smaller checkbox: GCWeb's "tickbox" variant of
    # `gc-chckbxrdio`, for one yes/no choice. It sends Rails' hidden "0"
    # when unticked. Inside a form, use `f.check_box_group`.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/components/gc-chckbxrdio/gc-chckbxrdio-en.html
    class CheckboxComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param label text
      # @param required toggle
      # @param checked toggle
      # @param error text "Error message; leave empty for none"
      def playground(label: "Remember me", required: false, checked: false, error: "")
        render CheckboxComponent.new(
          name: "remember_me", label: label, required: required, checked: checked, error: error.presence
        )
      end

      # @label Default example
      def default
        render CheckboxComponent.new(name: "remember_me", label: I18n.t("previews.form.remember_me"))
      end

      # @label Required, with an error
      #
      # A box that must be ticked, such as agreeing to terms. It has the
      # `required` attribute, and the error goes in its label.
      def required_with_error
        render CheckboxComponent.new(
          name: "terms", label: I18n.t("activemodel.attributes.preference_survey.terms"), required: true,
          error: I18n.t("activemodel.errors.messages.blank"), error_number: 1
        )
      end
    end
  end
end
