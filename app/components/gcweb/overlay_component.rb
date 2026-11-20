module Gcweb
  # Overlay (wet-boew wb-overlay) as on GCWeb v20.0.1: side panels, top and
  # bottom bars, and middle or full-screen popups.
  #
  #   <%= gcweb_overlay_link_to "Left panel", "left-panel" %>
  #
  #   <%= render Gcweb::OverlayComponent.new(id: "left-panel", title: "Left panel", variant: :panel_left) do %>
  #     <ul class="list-unstyled">…</ul>
  #   <% end %>
  #
  # The `gcweb--overlay` Stimulus controller opens it from links to its id
  # (`a.overlay-lnk`, which `gcweb_overlay_link_to` renders), keeps Tab
  # inside it, and closes it on Escape, on its close buttons, or on a click
  # or focus outside it (unless `close_outside: false`). It renders the close
  # buttons wet-boew adds: the × in the corner, and a "Close" button in the
  # footer of panels and popups.
  class OverlayComponent < ViewComponent::Base
    VARIANTS = {
      panel_left: "wb-panel-l",
      panel_right: "wb-panel-r",
      bar_top: "wb-bar-t",
      bar_bottom: "wb-bar-b",
      popup_mid: "wb-popup-mid",
      popup_full: "wb-popup-full"
    }.freeze
    HEADING_LEVELS = (2..6).freeze

    # Footer content. wet-boew adds its "Close" button to it unless it has
    # an `.overlay-close` button of its own.
    renders_one :footer

    attr_reader :id, :title, :variant

    # @param id [String] the overlay's id, which links open it by (#id)
    # @param title [String] the heading, also used in the × button's label
    # @param variant [Symbol] :panel_left, :panel_right, :bar_top, :bar_bottom, :popup_mid or :popup_full
    # @param hidden_header [Boolean] keep the heading for screen readers only (GCWeb's hidden-hd)
    # @param background [Boolean] darken the page behind a middle popup (overlay-bg)
    # @param close_outside [Boolean] false keeps it open on outside clicks and lets Tab leave it (outside-off)
    # @param open [Boolean] open it when the page loads, without moving focus
    # @param heading_level [Integer] 2–6
    # @param html_attributes [Hash] extra attributes for the <section> (class is appended)
    def initialize(id:, title:, variant: :popup_mid, hidden_header: false, background: false, close_outside: true,
                   open: false, heading_level: 2, **html_attributes)
      @id = id.to_s
      raise ArgumentError, "id can't be blank" if @id.empty?

      @title = title.to_s
      raise ArgumentError, "title can't be blank" if @title.empty?

      @variant = variant.to_sym
      raise ArgumentError, "Unsupported overlay variant: #{variant.inspect} (use #{VARIANTS.keys.join(', ')})" unless VARIANTS.key?(@variant)

      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 6" unless HEADING_LEVELS.cover?(@heading_level)

      @hidden_header = hidden_header
      @background = background
      @close_outside = close_outside
      @open = open
      @html_attributes = html_attributes
    end

    def bar? = %i[bar_top bar_bottom].include?(variant)
    def hidden_header? = @hidden_header
    def title_id = "#{id}-title"

    def section_attributes
      data = (@html_attributes[:data] || {}).merge(controller: [ @html_attributes.dig(:data, :controller), "gcweb--overlay" ].compact.join(" "))
      data[:"gcweb--overlay-open-value"] = "true" if @open

      @html_attributes.merge(
        id: id,
        class: class_names(
          "wb-overlay", "modal-content",
          "overlay-def" => !hidden_header?,
          VARIANTS.fetch(variant) => true,
          "hidden-hd" => hidden_header?,
          "overlay-bg" => @background,
          "outside-off" => !@close_outside,
          @html_attributes[:class] => @html_attributes[:class].present?
        ),
        aria: (@html_attributes[:aria] || {}).merge(labelledby: title_id),
        data: data
      )
    end

    def header_tag
      heading = content_tag(:"h#{@heading_level}", title, id: title_id, class: hidden_header? ? "wb-inv" : "modal-title")
      tag.header(heading, class: (hidden_header? || bar?) ? nil : "modal-header")
    end

    def footer_tag
      return unless footer? || !bar?

      tag.div(class: "modal-footer") do
        safe_join([ footer, (footer_close_button unless custom_close_button?) ].compact)
      end
    end

    # The × in the corner, labelled "Close: <title> (escape key)".
    def corner_close_button
      label = t("gcweb.overlay.close_title", title: title)
      tag.button(type: "button", class: "mfp-close overlay-close", title: label) do
        safe_join([ "×", tag.span(" #{label}", class: "wb-inv") ])
      end
    end

    private

    def footer_close_button
      tag.button(type: "button", class: [ "btn btn-sm btn-primary", variant == :panel_left ? "pull-right" : "pull-left", "overlay-close" ]) do
        safe_join([ t("gcweb.overlay.close"), tag.span(" #{t('gcweb.overlay.overlay')}", class: "wb-inv") ])
      end
    end

    def custom_close_button?
      footer? && Nokogiri::HTML5.fragment(footer.to_s).at_css(".overlay-close").present?
    end
  end
end
