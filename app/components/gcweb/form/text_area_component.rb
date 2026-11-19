module Gcweb
  module Form
    # GCWeb multi-line text field with its label (common/form).
    #
    #   <%= render Gcweb::Form::TextAreaComponent.new(name: "message", label: "Message", rows: 5, required: true) %>
    #
    # Inside a form, prefer the builder: `f.text_area_group :message, rows: 5`.
    class TextAreaComponent < FieldComponent
      private

      def control
        # The leading newline is what Rails' text_area emits: browsers drop the
        # first newline in a textarea, so a value starting with one survives.
        tag.textarea("\n#{value}", **base_control_attributes)
      end
    end
  end
end
