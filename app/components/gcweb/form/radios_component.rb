module Gcweb
  module Form
    # GCWeb large radio buttons in a fieldset (components/gc-chckbxrdio).
    #
    #   <%= render Gcweb::Form::RadiosComponent.new(
    #         name: "pet", label: "Which is your favorite pet?", required: true,
    #         choices: [ [ "Dog", "dog" ], [ "Cat", "cat" ] ], value: "cat") %>
    #
    # Inside a form, prefer the builder: `f.radio_buttons_group :pet, choices`.
    #
    # A required group puts the required attribute on every radio, which is
    # how HTML says "one of these must be chosen".
    #
    # @see ChoicesComponent for the markup and the options
    class RadiosComponent < ChoicesComponent
      INPUT_TYPE = "radio".freeze

      private

      def checked?(option_value)
        !value.nil? && value.to_s == option_value.to_s
      end
    end
  end
end
