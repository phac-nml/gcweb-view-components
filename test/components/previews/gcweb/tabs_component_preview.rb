module Gcweb
  # @label Tabs
  #
  # wet-boew's tabbed interface (`wb-tabs`). Each panel is a `<details>`
  # whose summary is the tab's label. The `gcweb--tabs` Stimulus controller
  # builds the tab list on screens 992px and wider, and turns the panels
  # into an accordion on narrower screens (try a mobile viewport). Arrow
  # keys move between tabs, Enter or Space moves into the panel, and
  # Ctrl+Up moves back to the tab.
  #
  # The carousel variant (`carousel-s1`/`-s2`) isn't part of the gem yet.
  #
  # - GCWeb working examples: https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/tabs/tabs-en.html
  # - wet-boew documentation: https://wet-boew.github.io/wet-boew/docs/ref/tabs/tabs-en.html
  class TabsComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param tabs number
    # @param open_tab number "Which tab is open first (1 = first)"
    # @param ignore_session toggle "Don't remember the last tab chosen"
    def playground(tabs: 3, open_tab: 1, ignore_session: true)
      render_with_template(locals: { count: tabs.to_i.clamp(1, 14), open_tab: open_tab.to_i, ignore_session: ignore_session })
    end

    # @label Default example
    #
    # GCWeb's "Example 1": the last tab chosen is remembered for the
    # session. The link in the first panel opens the third, and so does the
    # `wb-tabs-ext` link below the tabs.
    def default
      render_with_template
    end

    # @label Without session storage
    #
    # GCWeb's "Example 2": `ignore_session: true` (the `ignore-session`
    # class) always opens the first panel on page load. Panels can hold
    # their own expand/collapse sections.
    def ignore_session
      render_with_template
    end

    # @label Many tabs
    #
    # GCWeb's "Example 3": more tabs than fit scroll sideways.
    def many_tabs
      render_with_template
    end
  end
end
