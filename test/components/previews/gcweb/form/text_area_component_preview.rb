module Gcweb
  module Form
    # @label Text area
    #
    # GCWeb multi-line text field. Inside a form, use `f.text_area_group`.
    #
    # - GCWeb working example: https://wet-boew.github.io/GCWeb/common/form/complex-structure-form-en.html
    class TextAreaComponentPreview < ViewComponent::Preview
      # @label Playground
      # @param label text
      # @param required toggle
      # @param rows number
      # @param error text "Error message; leave empty for none"
      def playground(label: "Post Nominals", required: false, rows: 4, error: "")
        render TextAreaComponent.new(
          name: "post_nominals", label: label, required: required,
          rows: rows.to_i, cols: 51, error: error.presence
        )
      end

      # @label Default example
      def default
        render TextAreaComponent.new(
          name: "post_nominals", label: I18n.t("activemodel.attributes.contact_information.post_nominals"),
          maxlength: 100, cols: 51, rows: 4
        )
      end
    end
  end
end
