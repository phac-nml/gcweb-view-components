module Gcweb
  # GCWeb featured link (components/gc-featured-link).
  #
  #   <%= render Gcweb::FeaturedLinkComponent.new(href: "/promo", link_text: "[Promotion title]") %>
  #
  # `background_color` is rendered as GCWeb's `data-bg-color` attribute and
  # painted by the `gcweb--featured-link` Stimulus controller, which also picks
  # an accessible text colour. Nothing is written to a style="" attribute, so
  # the component works under a strict Content-Security-Policy.
  class FeaturedLinkComponent < ViewComponent::Base
    HEX_COLOR = /\A#\h{6}\z/
    HEADING_LEVELS = (2..6).freeze

    attr_reader :href, :link_text, :description, :background_color, :heading_level

    # @param href [String] link target
    # @param link_text [String] visible link text
    # @param heading [String, nil] visually hidden section heading; defaults to "Spotlight on" / "Pleins feux sur"
    # @param heading_level [Integer] 2–6
    # @param description [String, nil] optional text below the link
    # @param background_color [String, nil] custom band colour as 6-digit hex, e.g. "#005B61"
    # @param html_attributes [Hash] extra attributes for the <section> (class is appended)
    def initialize(href:, link_text:, heading: nil, heading_level: 2, description: nil, background_color: nil, **html_attributes)
      @href = href.to_s
      @link_text = link_text.to_s
      @heading = heading.presence
      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 6" unless HEADING_LEVELS.cover?(@heading_level)

      @description = description.presence
      @background_color = background_color.presence
      if @background_color && !@background_color.match?(HEX_COLOR)
        raise ArgumentError, "background_color must be a 6-digit hex colour like \"#005B61\", got #{background_color.inspect}"
      end

      @html_attributes = html_attributes
    end

    def heading
      @heading || t("gcweb.featured_link.heading")
    end

    def section_attributes
      data = (@html_attributes[:data] || {}).dup
      if background_color
        data[:bg_color] = background_color
        data[:controller] = [ data[:controller], "gcweb--featured-link" ].compact.join(" ")
      end

      @html_attributes.merge(
        class: class_names("gc-featured-link", @html_attributes[:class]),
        data: data.presence
      ).compact
    end
  end
end
