module Gcweb
  module Form
    # Shared markup for GCWeb's large checkboxes and radio buttons
    # (components/gc-chckbxrdio) as a group with a legend:
    #
    #   <fieldset class="gc-chckbxrdio">
    #     <legend class="required">
    #       <span class="field-name">Which is your favorite pet?</span>
    #       <strong class="required" aria-hidden="true">(required)</strong>
    #       <strong id="pet-error" class="error">…</strong>
    #     </legend>
    #     <ul class="list-unstyled lst-spcd-2">
    #       <li class="radio">
    #         <input type="radio" id="pet_dog" name="pet" value="dog" required>
    #         <label for="pet_dog">Dog</label>
    #       </li>
    #     </ul>
    #   </fieldset>
    #
    # The legend holds the field name, hint, required marker and error,
    # which is where wet-boew's validation (wb-frmvld) puts a group's error
    # on GCWeb v20.0.1. The legend is the group's accessible name, so the
    # error is announced when focus enters the group.
    #
    # `inline: true` renders GCWeb's inline variant
    # (fieldset.gc-chckbxrdio.form-inline > div.label-inline).
    #
    # @abstract Subclasses set INPUT_TYPE and implement #checked?.
    class ChoicesComponent < FieldComponent
      # @param choices [Array, Hash] the options, like options_for_select:
      #   ["Dog", "Cat"], [["Dog", "dog"], ["Cat", "cat"]], { "Dog" => "dog" },
      #   or [text, value, { html attributes for that input }]
      # @param inline [Boolean] lay the options out in a row
      # @param disabled [Array] values whose inputs are disabled
      # @param include_hidden [Boolean] add an empty hidden input first, so the
      #   param is sent even when nothing is chosen (as Rails' collection helpers do)
      # @see FieldComponent#initialize for the other options; value is the
      #   chosen value (radios) or values (checkboxes)
      def initialize(choices:, inline: false, disabled: [], include_hidden: true, **options)
        @choices = choices
        @inline = inline
        @disabled_values = Array(disabled).map(&:to_s)
        @include_hidden = include_hidden
        super(**options)
      end

      def inline? = @inline

      def call
        tag.fieldset(**fieldset_attributes) do
          safe_join([ tag.legend(label_content, **legend_attributes), hidden_input, options_markup ].compact)
        end
      end

      # Id of one option's input: the group id plus the value, as Rails'
      # field_id(method, value) builds it ("pet" + "Dog" -> "pet_dog").
      def option_id(option_value)
        "#{id}_#{option_value.to_s.gsub(/[\s.]/, "_").gsub(/[^-[[:word:]]]/, "").downcase}"
      end

      # The first input's id, which an error summary links to.
      def first_option_id
        option_id(normalized_choices.first&.dig(1))
      end

      private

      def input_type = self.class::INPUT_TYPE

      def fieldset_attributes
        @group_html.merge(class: class_names("gc-chckbxrdio", { "form-inline" => inline? }, @group_html[:class]))
      end

      def legend_attributes
        { class: class_names(required: required?).presence }
      end

      def input_name = name

      def hidden_input
        tag.input(type: "hidden", name: input_name, value: "", autocomplete: "off") if @include_hidden
      end

      def options_markup
        items = normalized_choices.map { |text, option_value, attributes| option_item(text, option_value, attributes) }

        inline? ? safe_join(items) : tag.ul(safe_join(items), class: "list-unstyled lst-spcd-2")
      end

      def option_item(text, option_value, attributes)
        wrapper = inline? ? :div : :li

        content_tag(wrapper, class: class_names(input_type, "label-inline" => inline?)) do
          safe_join([
            tag.input(**input_attributes(option_value, attributes)),
            tag.label(text, for: option_id(option_value))
          ])
        end
      end

      def input_attributes(option_value, attributes)
        merged = @control_attributes.merge(attributes)
        aria = (merged[:aria] || {}).dup
        aria[:invalid] = true if error?

        merged.except(:class, :aria).merge(
          type: input_type,
          id: option_id(option_value),
          name: input_name,
          value: option_value,
          checked: checked?(option_value) || nil,
          disabled: (@disabled_values.include?(option_value.to_s) || merged[:disabled]) || nil,
          required: (required_attribute? || nil),
          class: class_names({ "error" => error? }, merged[:class]).presence,
          aria: aria.presence
        ).compact
      end

      def normalized_choices
        @normalized_choices ||= @choices.map do |choice|
          if choice.is_a?(Array)
            [ choice[0], choice.fetch(1, choice[0]), choice[2] || {} ]
          else
            [ choice, choice, {} ]
          end
        end
      end

      def checked?(_option_value)
        raise NotImplementedError, "#{self.class} must implement #checked?"
      end
    end
  end
end
