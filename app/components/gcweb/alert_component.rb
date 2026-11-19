module Gcweb
  # GCWeb alert (common/alert).
  #
  #   <%= render Gcweb::AlertComponent.new(variant: :warning, heading: "Warning alert") do %>
  #     <p>Alert details.</p>
  #   <% end %>
  #
  # With `collapsible: true` it renders GCWeb's expand/collapse alert: the
  # heading becomes the <summary> of a <details> element (styled as .h5 by
  # default, as on Canada.ca).
  class AlertComponent < ViewComponent::Base
    VARIANTS = %i[danger warning success info].freeze
    TAGS = %i[section div].freeze
    HEADING_LEVELS = (2..6).freeze

    attr_reader :variant, :heading, :heading_level, :heading_class

    # @param variant [Symbol] :danger, :warning, :success or :info
    # @param heading [String, nil] alert title
    # @param heading_level [Integer] 2–6; GCWeb examples use h3
    # @param heading_class [String, nil] visual size override, e.g. "h5"
    # @param collapsible [Boolean] render the expand/collapse pattern (needs a heading)
    # @param open [Boolean] start expanded (collapsible only)
    # @param tag [Symbol, nil] :section or :div; defaults to section when there is a heading
    # @param html_attributes [Hash] extra attributes for the wrapper (class is appended)
    def initialize(variant:, heading: nil, heading_level: 3, heading_class: nil, collapsible: false, open: false, tag: nil, **html_attributes)
      @variant = variant.to_sym
      raise ArgumentError, "Unsupported alert variant: #{variant.inspect} (use #{VARIANTS.join(', ')})" unless VARIANTS.include?(@variant)

      @heading = heading.presence&.to_s
      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 6" unless HEADING_LEVELS.cover?(@heading_level)

      @collapsible = collapsible
      raise ArgumentError, "A collapsible alert needs a heading" if @collapsible && @heading.nil?

      @open = open
      @heading_class = heading_class || (@collapsible ? "h5" : nil)

      @tag = (tag || (@heading ? :section : :div)).to_sym
      raise ArgumentError, "Unsupported alert tag: #{tag.inspect} (use #{TAGS.join(', ')})" unless TAGS.include?(@tag)

      @html_attributes = html_attributes
    end

    def collapsible? = @collapsible
    def open? = @open

    def wrapper_attributes
      @html_attributes.merge(class: class_names("alert", "alert-#{variant}", @html_attributes[:class]))
    end

    def heading_tag
      content_tag(:"h#{heading_level}", heading, class: heading_class)
    end

    def wrapper_tag = @tag
  end
end
