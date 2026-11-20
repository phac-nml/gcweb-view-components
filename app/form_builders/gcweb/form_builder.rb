module Gcweb
  # Form builder that renders GCWeb form groups from a model.
  #
  #   <%= gcweb_form_with model: @applicant do |f| %>
  #     <%= f.text_field_group :email, type: :email, hint: "(yourname@domain.com)" %>
  #     <%= f.text_area_group :message, rows: 5 %>
  #     <%= f.select_group :language, [ [ "English", "en" ], [ "French", "fr" ] ], prompt: true %>
  #     <%= f.radio_buttons_group :contact_method, [ [ "Email", "email" ], [ "Phone", "phone" ] ] %>
  #     <%= f.check_boxes_group :topics, [ [ "Health", "health" ], [ "Science", "science" ] ] %>
  #     <%= f.check_box_group :terms %>
  #     <%= f.text_field :internal_ref %>   <%# plain Rails, unchanged %>
  #   <% end %>
  #
  # Opt-in: use `builder: Gcweb::FormBuilder` or `gcweb_form_with`. The gem
  # never replaces ActionView::Base.default_form_builder, so it can sit next
  # to another component library's builder (e.g. Pathogen in irida-next).
  #
  # The *_group methods add GCWeb's label, required marker, hint and inline
  # error around the control. Rails' own field methods are not overridden.
  #
  # For each attribute the builder works out:
  # - name and id: Rails' field_name / field_id
  # - value: the attribute before type cast, as Rails' text_field does
  # - label: helpers.label translations, then human_attribute_name
  # - required: an unconditional presence or acceptance validator (override with required:)
  # - error: the attribute's first error message, numbered in render order
  #   like wet-boew's "Error 1: …" prefixes
  #
  # Any option can be passed explicitly to override what the builder infers.
  class FormBuilder < ActionView::Helpers::FormBuilder
    REQUIRED_VALIDATORS = %i[presence acceptance].freeze
    private_constant :REQUIRED_VALIDATORS

    # @param method [Symbol] attribute
    # @param type [Symbol] input type, see Gcweb::Form::TextFieldComponent::TYPES
    def text_field_group(method, type: :text, **options)
      render_group(Gcweb::Form::TextFieldComponent, method, type: type, **options)
    end

    def text_area_group(method, **options)
      render_group(Gcweb::Form::TextAreaComponent, method, **options)
    end

    # @param choices [Array, Hash, String] see Gcweb::Form::SelectComponent
    def select_group(method, choices, **options)
      render_group(Gcweb::Form::SelectComponent, method, choices: choices, **options)
    end

    # GCWeb large radio buttons in a fieldset.
    # @param choices [Array, Hash] see Gcweb::Form::ChoicesComponent
    def radio_buttons_group(method, choices, **options)
      render_group(Gcweb::Form::RadiosComponent, method, choices: choices, **options)
    end

    # GCWeb large checkboxes in a fieldset; the values arrive as an array.
    # @param choices [Array, Hash] see Gcweb::Form::ChoicesComponent
    def check_boxes_group(method, choices, **options)
      render_group(Gcweb::Form::CheckboxesComponent, method, choices: choices, **options)
    end

    # A single GCWeb checkbox ("tickbox"), with Rails' hidden "0" input.
    def check_box_group(method, **options)
      render_group(Gcweb::Form::CheckboxComponent, method, **options)
    end

    private

    def render_group(component_class, method, **options)
      error = options.key?(:error) ? options.delete(:error) : field_errors(method).first

      @template.render(component_class.new(
        name: options.delete(:name) || field_name(method),
        id: options.delete(:id) || field_id(method),
        value: options.key?(:value) ? options.delete(:value) : field_value(method),
        label: options.delete(:label) || label_text(method),
        required: options.key?(:required) ? options.delete(:required) : presence_required?(method),
        error: error,
        error_number: (options.delete(:error_number) || next_error_number if error.present?),
        **options
      ))
    end

    def field_errors(method)
      return [] unless @object.respond_to?(:errors)

      @object.errors[method]
    end

    def next_error_number
      @gcweb_error_count = (@gcweb_error_count || 0) + 1
    end

    def field_value(method)
      return if @object.nil?

      before_type_cast = "#{method}_before_type_cast"
      if @object.respond_to?(before_type_cast)
        @object.public_send(before_type_cast)
      elsif @object.respond_to?(method)
        @object.public_send(method)
      end
    end

    # Same lookup as `f.label`: helpers.label.<object>.<method>, then
    # human_attribute_name, then the humanized method name.
    def label_text(method)
      ActionView::Helpers::Tags::Translator.new(@object, @object_name.to_s, method.to_s, scope: "helpers.label").translate ||
        method.to_s.humanize
    end

    # Presence and acceptance ("tick to agree") validators make a field
    # required. Only unconditional ones count; a validator with
    # if/unless/on may not apply to this render.
    def presence_required?(method)
      return false unless @object.class.respond_to?(:validators_on)

      @object.class.validators_on(method).any? do |validator|
        REQUIRED_VALIDATORS.include?(validator.kind) && validator.options.slice(:if, :unless, :on).empty?
      end
    end
  end
end
