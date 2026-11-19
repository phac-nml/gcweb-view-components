module Gcweb
  module Form
    # GCWeb text input with its label (common/form).
    #
    #   <%= render Gcweb::Form::TextFieldComponent.new(
    #         name: "email", label: "Email", type: :email, required: true,
    #         hint: "(yourname@domain.com)", autocomplete: "email") %>
    #
    # Inside a form, prefer the builder: `f.text_field_group :email, type: :email`.
    class TextFieldComponent < FieldComponent
      TYPES = %i[text email tel url password number search date time datetime-local month week].freeze

      attr_reader :type

      # @param type [Symbol] input type (see TYPES)
      # @see FieldComponent#initialize for the other options
      def initialize(type: :text, **options)
        @type = type.to_s.tr("_", "-").to_sym
        raise ArgumentError, "Unsupported input type: #{type.inspect} (use #{TYPES.join(', ')})" unless TYPES.include?(@type)

        super(**options)
      end

      private

      def control
        # Like Rails' password_field, never echo a password back into the page.
        tag.input(type: type, value: (type == :password ? nil : value), **base_control_attributes)
      end
    end
  end
end
