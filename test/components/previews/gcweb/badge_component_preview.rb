module Gcweb
  # @label Badge
  #
  # A number that highlights new, updated or unread items, usually inside a
  # link or button. `description` tells screen reader users what the number
  # counts. A badge with no content hides itself.
  #
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/components/badges/badges-en.html
  # - WET style guide: https://wet-boew.github.io/wet-boew-styleguide/design/badges-en
  class BadgeComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param count text "Leave empty to see the badge hide itself"
    # @param description text "Read by screen readers after the number"
    # @param in_button toggle "Inside a primary button"
    def playground(count: "42", description: "unread emails", in_button: false)
      render_with_template(locals: { count: count, description: description, in_button: in_button })
    end

    # @label Default
    #
    # GCWeb's grey badge in a link, and the badge in a primary button.
    def default
      render_with_template
    end

    # @label Self collapsing
    #
    # A badge with no content isn't shown.
    def self_collapsing
      render_with_template
    end
  end
end
