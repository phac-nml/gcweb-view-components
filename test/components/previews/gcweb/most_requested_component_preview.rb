module Gcweb
  # @label Most requested
  #
  # A full-width band of links to a topic's most requested tasks. From
  # 992px the heading sits on the left and the links flow into two
  # columns; exactly two links sit side by side. The heading defaults to
  # "Most requested" / "En demande".
  #
  # Put it straight in `<main>`, not inside another `.container`: GCWeb
  # then drops the background and the columns. GCWeb's "provisional"
  # (pre-v14.8) and "bad implementation" examples aren't shown.
  #
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/components/gc-most-requested/gc-most-requested-en.html
  # - GCWeb documentation: https://wet-boew.github.io/GCWeb/components/gc-most-requested/gc-most-requested-doc-en.html
  class MostRequestedComponentPreview < ViewComponent::Preview
    layout "component_preview_full_width"

    TEMPLATE = "gcweb/most_requested_component_preview/links".freeze

    # @label Playground
    # @param count number
    # @param title text "Leave blank for the default heading"
    def playground(count: 6, title: "")
      render_with_template(template: TEMPLATE, locals: { count: count.to_i.clamp(1, 20), title: title, long: false })
    end

    # @label Default example
    #
    # Six links; the first and last have long names that wrap.
    def default
      render_with_template(template: TEMPLATE, locals: { count: 6 })
    end

    # @label Two items
    #
    # Exactly two links sit side by side from 992px.
    def two_items
      render_with_template(template: TEMPLATE, locals: { count: 2, long: false })
    end

    # @label Highlight
    #
    # Two in a row: the first gets a blue background (GCWeb's "highlight"
    # example).
    def highlight
      render_with_template
    end

    # @label With labels
    #
    # A label after each link.
    def with_labels
      render_with_template
    end
  end
end
