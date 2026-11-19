module Gcweb
  module Form
    # Shared GCWeb / WET-BOEW form-group markup: label, "(required)" marker,
    # hint and inline error. Subclasses render the control itself.
    #
    #   <div class="form-group has-error">
    #     <label for="email" class="required">
    #       <span class="field-name">Email</span> (yourname@domain.com)
    #       <strong class="required" aria-hidden="true">(required)</strong>
    #       <strong id="email-error" class="error"><span class="label label-danger">
    #         <span class="prefix">Error&nbsp;1: </span>Please enter a valid email address.
    #       </span></strong>
    #     </label>
    #     <input class="form-control error" id="email" name="email" required aria-invalid="true" …>
    #   </div>
    #
    # This is the markup wet-boew's form validation (wb-frmvld) produces on
    # GCWeb v20.0.1, so server-side errors look the same as client-side ones.
    # The hint and the error sit inside the <label>, as in GCWeb, so they are
    # part of the field's accessible name without extra ARIA.
    #
    # Inputs are built with tag helpers rather than FormBuilder field methods,
    # so Rails' field_error_proc never wraps them in div.field_with_errors.
    #
    # @abstract Subclasses implement #control.
    class FieldComponent < ViewComponent::Base
      attr_reader :name, :id, :label, :hint, :error, :error_number

      # @param name [String, Symbol] the control's name attribute
      # @param label [String] visible label text
      # @param id [String, nil] defaults to a sanitized version of name
      # @param value [Object, nil] current value
      # @param required [Boolean] adds GCWeb's required marker and the required attribute
      # @param hint [String, nil] format help shown after the label text, e.g. "(yourname@domain.com)"
      # @param error [String, Array<String>, nil] error message(s); the first one is shown
      # @param error_number [Integer, nil] position in the form's error list ("Error 3: …")
      # @param group_html [Hash] extra attributes for the .form-group wrapper
      # @param control_attributes [Hash] extra attributes for the control (maxlength, autocomplete, data, …)
      def initialize(name:, label:, id: nil, value: nil, required: false, hint: nil, error: nil, error_number: nil, group_html: {}, **control_attributes)
        @name = name.to_s
        @id = (id.presence || self.class.id_for(@name)).to_s
        @label = label
        @value = value
        @required = required
        @hint = hint.presence
        @error = Array(error).compact_blank.first
        @error_number = error_number
        @group_html = group_html
        @control_attributes = control_attributes
      end

      # Same id Rails derives from a field name: "user[email]" -> "user_email".
      def self.id_for(name)
        name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").delete_suffix("_")
      end

      def required? = @required
      def error? = !@error.nil?
      def error_id = "#{id}-error"

      def group_attributes
        @group_html.merge(class: class_names("form-group", { "has-error" => error? }, @group_html[:class]))
      end

      def label_attributes
        { for: id, class: class_names(required: required?).presence }
      end

      def label_content
        parts = [ tag.span(label, class: "field-name") ]
        parts << hint if hint
        parts << tag.strong(t("gcweb.form.required"), class: "required", aria: { hidden: true }) if required?
        parts << error_tag if error?
        safe_join(parts, " ")
      end

      def call
        tag.div(**group_attributes) do
          safe_join([ tag.label(label_content, **label_attributes), control ])
        end
      end

      private

      attr_reader :value

      def control
        raise NotImplementedError, "#{self.class} must implement #control"
      end

      # Attributes shared by every control. Explicit class/aria/data entries in
      # control_attributes are merged, not replaced.
      def base_control_attributes
        attrs = @control_attributes.except(:class, :aria)
        aria = (@control_attributes[:aria] || {}).dup
        aria[:invalid] = true if error?

        attrs.merge(
          id: id,
          name: name,
          required: required? || nil,
          class: class_names("form-control", { "error" => error? }, @control_attributes[:class]),
          aria: aria.presence
        ).compact
      end

      def error_tag
        tag.strong(id: error_id, class: "error") do
          tag.span(class: "label label-danger") do
            safe_join([ tag.span(error_prefix, class: "prefix"), error ])
          end
        end
      end

      def error_prefix
        if error_number
          t("gcweb.form.error_prefix_numbered", number: error_number)
        else
          t("gcweb.form.error_prefix")
        end
      end
    end
  end
end
