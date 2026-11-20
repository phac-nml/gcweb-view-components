module GcwebViewComponents
  # Included into every view by the engine.
  module ToggleHelper
    OPTIONS = %i[selector parent group type state persist print].freeze

    # Data attributes that make an element a wet-boew toggle, for the
    # gcweb--toggle Stimulus controller. Pass them as `data:`.
    #
    #   <%= render Gcweb::ButtonComponent.new(class: "wb-toggle",
    #         data: gcweb_toggle_data(selector: "details", parent: "#faq", type: :on)) do %>
    #     Expand all
    #   <% end %>
    #
    # @param selector [String, nil] the elements it toggles (default: itself)
    # @param parent [String, nil] only toggle elements inside this
    # @param group [String, nil] only one element matching it is on at a time
    # @param type [Symbol, nil] :on or :off to only turn elements on or off
    # @param state [Symbol, nil] the initial state (:off by default)
    # @param persist [Symbol, nil] :session or :local keeps the state across page loads
    # @param print [Symbol, nil] :on or :off sets the state before printing
    # @param state_on [String, nil] class for the on state ("on")
    # @param state_off [String, nil] class for the off state ("off")
    # @param data [Hash] other data attributes to keep (controller is joined)
    def gcweb_toggle_data(state_on: nil, state_off: nil, data: {}, **options)
      unknown = options.keys - OPTIONS
      raise ArgumentError, "Unknown toggle option(s): #{unknown.join(', ')}" if unknown.any?

      toggle = options.compact.transform_values(&:to_s)
      toggle[:stateOn] = state_on if state_on
      toggle[:stateOff] = state_off if state_off

      data.merge(
        controller: [ data[:controller], "gcweb--toggle" ].compact.join(" "),
        toggle: toggle.to_json
      )
    end
  end
end
