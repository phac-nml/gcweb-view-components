module Gcweb
  # @label Featured link
  #
  # Full-width promotional band with one stretched link. The section heading
  # is visually hidden (`wb-inv`) and defaults to "Spotlight on" /
  # "Pleins feux sur".
  #
  # A custom `background_color` is painted by the `gcweb--featured-link`
  # Stimulus controller, which also picks white, dark grey or black text to
  # keep a 4.5:1 contrast ratio (same logic as GCWeb's gc-featured-link.js).
  #
  # - GCWeb documentation: https://wet-boew.github.io/GCWeb/components/gc-featured-link/gc-featured-link-doc-en.html
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/components/gc-featured-link/gc-featured-link-en.html
  class FeaturedLinkComponentPreview < ViewComponent::Preview
    layout "component_preview_full_width"

    # @label Playground
    # @param link_text text
    # @param description text
    # @param background_color color
    def playground(link_text: "[Promotion title]", description: "", background_color: "")
      render Gcweb::FeaturedLinkComponent.new(
        href: "#",
        link_text: link_text,
        description: description,
        background_color: background_color
      )
    end

    # @label Default example
    def default
      render Gcweb::FeaturedLinkComponent.new(href: "#", link_text: I18n.t("previews.featured_link.link_text"))
    end

    # @label Customized background color examples
    #
    # Dark, light and medium backgrounds from the GCWeb examples. The text
    # colour changes to stay readable on each.
    def custom_background
      render_with_template
    end

    # @label Description below the link
    def with_description
      render Gcweb::FeaturedLinkComponent.new(
        href: "#",
        link_text: I18n.t("previews.featured_link.link_text"),
        description: I18n.t("previews.featured_link.description")
      )
    end
  end
end
