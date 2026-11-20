module Gcweb
  # GCWeb button (common/button).
  #
  #   <%= render Gcweb::ButtonComponent.new(variant: :primary, type: :submit).with_content("Submit") %>
  #   <%= render Gcweb::ButtonComponent.new(href: "/apply", variant: :call_to_action) do %>Apply now<% end %>
  #
  # Renders `<button class="btn btn-…">`, or `<a class="btn btn-…">` when
  # given an `href`. Use a link only to go somewhere; use a button to act on
  # the page.
  class ButtonComponent < ViewComponent::Base
    VARIANTS = %i[default primary success info warning danger link call_to_action].freeze
    SIZES = %i[xs sm lg].freeze
    TYPES = %i[button submit reset].freeze

    # @param variant [Symbol] :default, :primary, :success, :info, :warning, :danger, :link or :call_to_action
    # @param size [Symbol, nil] :xs, :sm or :lg
    # @param href [String, nil] render a link styled as a button
    # @param type [Symbol] button type (ignored for links): :button, :submit or :reset
    # @param block [Boolean] full width (btn-block)
    # @param active [Boolean] always show the pressed state (adds .active)
    # @param disabled [Boolean] buttons get the disabled attribute; links get .disabled and aria-disabled
    # @param html_attributes [Hash] extra attributes (class is appended)
    def initialize(variant: :default, size: nil, href: nil, type: :button, block: false, active: false, disabled: false, **html_attributes)
      @variant = variant.to_sym
      raise ArgumentError, "Unsupported button variant: #{variant.inspect} (use #{VARIANTS.join(', ')})" unless VARIANTS.include?(@variant)

      @size = size&.to_sym
      raise ArgumentError, "Unsupported button size: #{size.inspect} (use #{SIZES.join(', ')})" if @size && !SIZES.include?(@size)

      @type = type.to_sym
      raise ArgumentError, "Unsupported button type: #{type.inspect} (use #{TYPES.join(', ')})" unless TYPES.include?(@type)

      @href = href
      @block = block
      @active = active
      @disabled = disabled
      @html_attributes = html_attributes
    end

    def call
      if @href
        attrs = @html_attributes.merge(class: classes(link_disabled: @disabled))
        attrs[:aria] = { disabled: true }.merge(attrs.fetch(:aria, {})) if @disabled
        link_to(content, @href, **attrs)
      else
        tag.button(content, **@html_attributes, type: @type, disabled: @disabled, class: classes)
      end
    end

    private

    def classes(link_disabled: false)
      class_names(
        "btn",
        "btn-#{@variant.to_s.dasherize}",
        @size && "btn-#{@size}",
        @html_attributes[:class],
        "btn-block" => @block,
        "active" => @active,
        "disabled" => link_disabled
      )
    end
  end
end
