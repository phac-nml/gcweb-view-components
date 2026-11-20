module Gcweb
  # @label Overlay
  #
  # wet-boew's overlay plugin (`wb-overlay`): side panels, top and bottom
  # bars, and middle or full-screen popups, opened by links to the
  # overlay's id (`gcweb_overlay_link_to`). The `gcweb--overlay` Stimulus
  # controller opens them, keeps Tab inside, and closes them on Escape, on
  # the close buttons, or on a click outside. Without JavaScript the
  # overlays are shown in the page.
  #
  # wet-boew's Lightbox popups (`wb-lbx`) aren't part of the gem yet.
  #
  # - GCWeb working examples: https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/overlay/overlay-en.html
  # - wet-boew documentation: https://wet-boew.github.io/wet-boew/docs/ref/overlay/overlay-en.html
  class OverlayComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param variant select { choices: [panel_left, panel_right, bar_top, bar_bottom, popup_mid, popup_full] }
    # @param hidden_header toggle "Heading for screen readers only"
    # @param background toggle "Darken the page behind a middle popup"
    # @param close_outside toggle "Close on a click or focus outside"
    # @param open toggle "Open on page load"
    def playground(variant: :popup_mid, hidden_header: false, background: false, close_outside: true, open: true)
      render_with_template(locals: {
        options: { variant: variant.to_sym, hidden_header: hidden_header, background: background, close_outside: close_outside, open: open }
      })
    end

    # @label Side panels
    #
    # GCWeb's left and right panels (`wb-panel-l`, `wb-panel-r`).
    def panels
      render_with_template
    end

    # @label Top and bottom bars
    #
    # GCWeb's bars (`wb-bar-t`, `wb-bar-b`). Their content isn't wrapped in
    # a `modal-body`, and they have no footer.
    def bars
      render_with_template
    end

    # @label Middle screen popups
    #
    # GCWeb's middle screen overlays (`wb-popup-mid`): plain, beginning with
    # a hidden link (Tab skips it), and with a dark background
    # (`background: true`, GCWeb's `overlay-bg`).
    def popups
      render_with_template
    end

    # @label Full-screen popups
    #
    # GCWeb's full-screen overlays (`wb-popup-full`), with and without a
    # visible heading (`hidden_header: true`, GCWeb's `hidden-hd`).
    def full_screen
      render_with_template
    end

    # @label Custom close button
    #
    # A `footer` with its own `.overlay-close` button replaces the "Close"
    # button wet-boew adds.
    def custom_footer
      render_with_template
    end

    # @label Open on page load
    #
    # `open: true` opens the overlay when the page loads, without moving
    # focus to it.
    def open_on_load
      render_with_template
    end
  end
end
