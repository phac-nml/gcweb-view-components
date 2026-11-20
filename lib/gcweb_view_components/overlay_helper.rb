module GcwebViewComponents
  # Included into every view by the engine.
  module OverlayHelper
    # A link that opens a Gcweb::OverlayComponent (GCWeb's a.overlay-lnk).
    # Without JavaScript it's a link to the overlay, which is shown in the
    # page.
    #
    #   <%= gcweb_overlay_link_to "Left panel", "left-panel" %>
    #   <%= gcweb_overlay_link_to "left-panel", class: "btn btn-default" do %>
    #     Left panel
    #   <% end %>
    #
    # @param name [String] the link text (or pass a block)
    # @param overlay_id [String] the overlay's id
    # @param html_attributes [Hash] extra attributes (class is appended)
    def gcweb_overlay_link_to(name = nil, overlay_id = nil, **html_attributes, &block)
      name, overlay_id = capture(&block), name if block
      overlay_id = overlay_id.to_s
      raise ArgumentError, "overlay_id can't be blank" if overlay_id.empty?

      link_to(
        name, "##{overlay_id}",
        **html_attributes,
        class: class_names("overlay-lnk", html_attributes[:class]),
        role: "button",
        aria: (html_attributes[:aria] || {}).merge(controls: overlay_id)
      )
    end
  end
end
