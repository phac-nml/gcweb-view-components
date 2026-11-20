module Gcweb
  # Well (Bootstrap 3 .well, as GCWeb styles it): a grey, inset box that
  # sets content apart.
  #
  #   <%= render Gcweb::WellComponent.new(size: :lg) do %>
  #     <p>Content</p>
  #   <% end %>
  class WellComponent < ViewComponent::Base
    SIZES = %i[sm lg].freeze

    # @param size [Symbol, nil] :sm or :lg padding (default: normal)
    # @param bold [Boolean] bold text, with <strong> at normal weight (GCWeb's well-bold)
    # @param html_attributes [Hash] extra attributes (class is appended)
    def initialize(size: nil, bold: false, **html_attributes)
      @size = size&.to_sym
      raise ArgumentError, "Unsupported well size: #{size.inspect} (use #{SIZES.join(', ')})" if @size && !SIZES.include?(@size)

      @bold = bold
      @html_attributes = html_attributes
    end

    def call
      classes = class_names("well", "well-#{@size}" => @size, "well-bold" => @bold)
      tag.div(content, **@html_attributes, class: class_names(classes, @html_attributes[:class]))
    end
  end
end
