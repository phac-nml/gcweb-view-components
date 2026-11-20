module Gcweb
  # @label Toggle
  #
  # wet-boew's toggle plugin (`wb-toggle`) as the `gcweb--toggle` Stimulus
  # controller. Put it on the element people click, with GCWeb's
  # `data-toggle` options, or build the attributes with
  # `gcweb_toggle_data`:
  #
  # ```erb
  # <%= render Gcweb::ButtonComponent.new(class: "wb-toggle",
  #       data: gcweb_toggle_data(selector: "details", parent: "#faq", type: :on)) do %>
  #   Expand all
  # <% end %>
  # ```
  #
  # For sections that open one at a time, use `Gcweb::AccordionComponent`.
  #
  # - GCWeb working examples: https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/toggle/toggle-en.html
  # - wet-boew documentation: https://wet-boew.github.io/wet-boew/docs/ref/toggle/toggle-en.html
  class TogglePreview < ViewComponent::Preview
    # @label Details elements
    #
    # Buttons that toggle, open and close every `<details>` inside a parent.
    # "Toggle" opens them all if any is closed, and also opens them for
    # printing (`print: :on`).
    def details_elements
      render_with_template
    end

    # @label Print states
    #
    # `print: :on` opens a section when the page is printed; `print: :off`
    # closes it.
    def print_states
      render_with_template
    end

    # @label Grouped toggle
    #
    # Each button opens its section and closes the others in the group.
    def grouped
      render_with_template
    end

    # @label Remembered across page loads
    #
    # `persist: :session` keeps this section open or closed when the page is
    # reloaded in the same tab. The summary needs an id.
    def persist
      render_with_template
    end
  end
end
