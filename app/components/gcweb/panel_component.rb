module Gcweb
  # Panel (GCWeb components/panels): a self-contained box that spotlights
  # information or actions.
  #
  #   <%= render Gcweb::PanelComponent.new(variant: :info, title: "Panel title") do %>
  #     <p>Panel content</p>
  #   <% end %>
  #
  # The content goes in the padded `panel-body`; `body: false` puts it
  # straight in the panel instead (for content that fills the width).
  class PanelComponent < ViewComponent::Base
    VARIANTS = %i[default primary success info warning danger].freeze
    TAGS = %i[section div].freeze
    HEADING_LEVELS = (2..6).freeze

    # Footer content, in a <footer class="panel-footer">.
    renders_one :footer

    attr_reader :variant, :title

    # @param variant [Symbol] :default, :primary, :success, :info, :warning or :danger
    # @param title [String, nil] the heading (panel-title)
    # @param heading_level [Integer] 2–6; GCWeb's examples use h3
    # @param body [Boolean] wrap the content in the padded panel-body
    # @param tag [Symbol, nil] :section or :div; defaults to section when there is a title
    # @param html_attributes [Hash] extra attributes for the panel (class is appended)
    def initialize(variant: :default, title: nil, heading_level: 3, body: true, tag: nil, **html_attributes)
      @variant = variant.to_sym
      raise ArgumentError, "Unsupported panel variant: #{variant.inspect} (use #{VARIANTS.join(', ')})" unless VARIANTS.include?(@variant)

      @title = title.presence&.to_s
      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 6" unless HEADING_LEVELS.cover?(@heading_level)

      @body = body
      @tag = (tag || (@title ? :section : :div)).to_sym
      raise ArgumentError, "Unsupported panel tag: #{tag.inspect} (use #{TAGS.join(', ')})" unless TAGS.include?(@tag)

      @html_attributes = html_attributes
    end

    def call
      content_tag(@tag, **@html_attributes, class: class_names("panel", "panel-#{variant}", @html_attributes[:class])) do
        safe_join([ heading, body, (tag.footer(footer, class: "panel-footer") if footer?) ].compact)
      end
    end

    private

    def heading
      return unless title

      tag.header(content_tag(:"h#{@heading_level}", title, class: "panel-title"), class: "panel-heading")
    end

    def body
      return unless content.present?

      @body ? tag.div(content, class: "panel-body") : content
    end
  end
end
