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

      {
        class: "gc-featured-link",
        data: { bg_color: background_color },
        style: "background-color: #{background_color}; color: #{text_color(background_color)};"
      }
    end

    private

    def text_color(hex_color)
      value = hex_color.delete_prefix("#")
      return "#000" unless value.match?(/\A\h{6}\z/)

      red = value[0, 2].to_i(16)
      green = value[2, 2].to_i(16)
      blue = value[4, 2].to_i(16)

      luminance = [red, green, blue].map do |channel|
        value = channel / 255.0
        value <= 0.03928 ? (value / 12.92) : (((value + 0.055) / 1.055)**2.4)
      end

      relative_luminance = (0.2126 * luminance[0]) + (0.7152 * luminance[1]) + (0.0722 * luminance[2])
      contrast_with_black = (relative_luminance + 0.05) / 0.05
      contrast_with_white = 1.05 / (relative_luminance + 0.05)
      contrast_with_black >= contrast_with_white ? "#000" : "#fff"
    end
  end
end
