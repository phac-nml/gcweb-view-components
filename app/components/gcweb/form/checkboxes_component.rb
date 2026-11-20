module Gcweb
  module Form
    # GCWeb large checkboxes in a fieldset (components/gc-chckbxrdio).
    #
    #   <%= render Gcweb::Form::CheckboxesComponent.new(
    #         name: "condiments", label: "Choose your condiments:",
    #         choices: [ [ "Ketchup", "ketchup" ], [ "Relish", "relish" ] ],
    #         value: [ "relish" ]) %>
    #
    # Inside a form, prefer the builder: `f.check_boxes_group :condiments, choices`.
    #
    # The inputs are named `name[]`, so the chosen values arrive as an array.
    #
    # On a checkbox the required attribute means "this box must be ticked",
    # not "tick at least one", so a required group only shows GCWeb's
    # marker. The "(required)" text is then not aria-hidden: it is how
    # screen readers learn the group is required.
    #
    # @see ChoicesComponent for the markup and the options
    class CheckboxesComponent < ChoicesComponent
      INPUT_TYPE = "checkbox".freeze

      private

      def required_attribute? = false

      def input_name
        name.end_with?("[]") ? name : "#{name}[]"
      end

      def checked?(option_value)
        Array(value).map(&:to_s).include?(option_value.to_s)
      end
    end
  end
end
