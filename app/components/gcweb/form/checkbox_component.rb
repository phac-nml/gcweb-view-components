module Gcweb
  module Form
    # A single GCWeb checkbox, the "tickbox" variant of gc-chckbxrdio
    # (a smaller box for one yes/no choice such as "Remember me").
    #
    #   <div class="checkbox gc-chckbxrdio">
    #     <input name="remember" type="hidden" value="0" autocomplete="off">
    #     <input type="checkbox" id="remember" name="remember" value="1">
    #     <label for="remember"><span class="field-name">Remember me</span></label>
    #   </div>
    #
    #   <%= render Gcweb::Form::CheckboxComponent.new(name: "remember", label: "Remember me") %>
    #
    # Inside a form, prefer the builder: `f.check_box_group :remember`.
    #
    # `required: true` adds the required attribute, so the box must be
    # ticked (e.g. agreeing to terms), and `required` on the wrapper for
    # the asterisk. Errors go in the label, as wb-frmvld does on GCWeb.
    class CheckboxComponent < FieldComponent
      # @param checked_value [String] value sent when ticked
      # @param unchecked_value [String] value of the hidden input sent when not ticked
      # @param include_hidden [Boolean] add the hidden unchecked_value input (Rails' check_box convention)
      # @param checked [Boolean, nil] overrides the state worked out from value
      # @see FieldComponent#initialize for the other options; value is the
      #   current value, and the box is ticked when it equals checked_value or is true
      def initialize(checked_value: "1", unchecked_value: "0", include_hidden: true, checked: nil, **options)
        @checked_value = checked_value
        @unchecked_value = unchecked_value
        @include_hidden = include_hidden
        @checked = checked
        super(**options)
      end

      def checked?
        return @checked unless @checked.nil?

        value == true || (!value.nil? && value.to_s == @checked_value.to_s)
      end

      def call
        tag.div(**wrapper_attributes) do
          safe_join([ hidden_input, control, tag.label(label_content, **label_attributes) ].compact)
        end
      end

      private

      # A required tickbox marks the wrapper (div.checkbox.required), as
      # wet-boew does for single checkboxes. label.required would put the
      # asterisk in label::before, which gc-chckbxrdio uses to draw the box.
      def wrapper_attributes
        @group_html.merge(class: class_names("checkbox gc-chckbxrdio", { "required" => required? }, @group_html[:class]))
      end

      def label_attributes = { for: id }

      def hidden_input
        tag.input(type: "hidden", name: name, value: @unchecked_value, autocomplete: "off") if @include_hidden
      end

      def control
        attrs = base_control_attributes
        attrs[:class] = class_names({ "error" => error? }, @control_attributes[:class]).presence
        tag.input(**attrs.merge(type: "checkbox", value: @checked_value, checked: checked? || nil).compact)
      end
    end
  end
end
