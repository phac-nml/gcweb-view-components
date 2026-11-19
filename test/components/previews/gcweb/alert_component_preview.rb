module Gcweb
  # @label Alert
  #
  # GCWeb alert: a left border in the variant colour with an icon, no tinted
  # background. Use the toolbar's **lang** option to switch between English
  # and French.
  #
  # - GCWeb documentation: https://wet-boew.github.io/GCWeb/common/alert/alert-docs-en.html
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/common/alert/alerts-en.html
  class AlertComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param variant select { choices: [danger, warning, success, info] }
    # @param heading text
    # @param heading_level select { choices: [2, 3, 4, 5, 6] }
    # @param collapsible toggle
    # @param open toggle "Start expanded (collapsible only)"
    def playground(variant: :warning, heading: "Warning alert", heading_level: 3, collapsible: false, open: false)
      render Gcweb::AlertComponent.new(
        variant: variant,
        heading: heading,
        heading_level: heading_level.to_i,
        collapsible: collapsible,
        open: open
      ) do
        tag.p(I18n.t("previews.alert.details"))
      end
    end

    # @label Alert with headings
    #
    # Renders `<section class="alert alert-…">` with an `<h3>` title.
    def with_headings
      render_with_template(locals: { variants: %i[danger warning success info] })
    end

    # @label Links inside alerts
    #
    # Give links inside an alert the `alert-link` class so they are bold and
    # use the variant's darker link colour.
    def with_links
      render_with_template(locals: { variants: %i[success info warning danger] })
    end

    # @label Alerts without headings
    #
    # Without a heading the wrapper defaults to `<div>`.
    def without_headings
      render_with_template(locals: { variants: %i[success info warning danger] })
    end

    # @label Alert with expand/collapse
    #
    # `collapsible: true` wraps the content in `<details>` and puts the heading
    # in its `<summary>` (styled `.h5`). Use it when several alerts share a
    # page. `open: true` starts it expanded.
    def expand_collapse
      render_with_template
    end
  end
end
