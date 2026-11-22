module Gcweb
  # @label Panel
  #
  # A self-contained box that spotlights information or actions: an
  # optional heading, the content (padded in a `panel-body`), and an
  # optional footer.
  #
  # For tables in panels, see the Table component's "Tables in panels".
  #
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/components/panels/panels-en.html
  # - WET style guide: https://wet-boew.github.io/wet-boew-styleguide/design/panels-en
  class PanelComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param variant select { choices: [default, primary, success, info, warning, danger] }
    # @param title text
    # @param footer toggle "Add a footer"
    def playground(variant: :default, title: "Panel title", footer: false)
      render_with_template(locals: { variant: variant.to_sym, title: title, footer: footer })
    end

    # @label Stacking options
    #
    # Padded content, and a footer (GCWeb's "Stacking options").
    def stacking
      render_with_template
    end

    # @label Panel appearances
    #
    # The six variants.
    def appearances
      render_with_template
    end
  end
end
