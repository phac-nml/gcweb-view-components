module Gcweb
  class AlertComponent < ViewComponent::Base
    VALID_VARIANTS = %i[danger warning success info].freeze
    VALID_TAGS = %i[section div].freeze

    attr_reader :heading, :tag, :variant

    def initialize(variant:, heading: nil, tag: nil)
      @variant = variant.to_sym
      raise ArgumentError, "Unsupported alert variant: #{variant}" unless VALID_VARIANTS.include?(@variant)

      @heading = heading&.to_s
      @tag = (tag || default_tag).to_sym
      raise ArgumentError, "Unsupported alert tag: #{@tag}" unless VALID_TAGS.include?(@tag)
    end

    def css_classes
      "alert alert-#{variant}"
    end

    private

    def default_tag
      heading.present? ? :section : :div
    end
  end
end
