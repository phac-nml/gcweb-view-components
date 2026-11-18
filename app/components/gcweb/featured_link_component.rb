module Gcweb
  class FeaturedLinkComponent < ViewComponent::Base
    attr_reader :heading, :href, :link_text, :description, :background_color

    def initialize(heading:, href:, link_text:, description: nil, background_color: nil)
      @heading = heading.to_s
      @href = href.to_s
      @link_text = link_text.to_s
      @description = description
      @background_color = background_color
    end

    def section_attributes
      return { class: "gc-featured-link" } if background_color.blank?

      { class: "gc-featured-link", data: { bg_color: background_color } }
    end
  end
end
