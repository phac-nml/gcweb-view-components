module Gcweb
  # Label (GCWeb components/labels): a short piece of text-based (not
  # numeric) information, highlighted.
  #
  #   Some text here <%= render Gcweb::LabelComponent.new(variant: :success).with_content("(Label info)") %>
  #
  # With `href:` it's a link.
  class LabelComponent < ViewComponent::Base
    VARIANTS = %i[default primary success info warning danger].freeze

    attr_reader :variant

    # @param variant [Symbol] :default, :primary, :success, :info, :warning or :danger
    # @param href [String, nil] make the label a link
    # @param html_attributes [Hash] extra attributes (class is appended)
    def initialize(variant: :default, href: nil, **html_attributes)
      @variant = variant.to_sym
      raise ArgumentError, "Unsupported label variant: #{variant.inspect} (use #{VARIANTS.join(', ')})" unless VARIANTS.include?(@variant)

      @href = href
      @html_attributes = html_attributes
    end

    def call
      attributes = @html_attributes.merge(class: class_names("label", "label-#{variant}", @html_attributes[:class]))
      if @href
        link_to(content, @href, **attributes)
      else
        tag.span(content, **attributes)
      end
    end
  end
end
