module Gcweb
  # @label Accordion
  #
  # Sections that open one at a time (wet-boew's toggle plugin, `wb-toggle`,
  # with a group). Opening a section closes the others; the open one can be
  # closed too. The `gcweb--toggle` Stimulus controller runs it, and the
  # sections share a `name`, so it works the same without JavaScript.
  #
  # - GCWeb working examples: https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/toggle/toggle-en.html#accordion
  # - wet-boew documentation: https://wet-boew.github.io/wet-boew/docs/ref/toggle/toggle-en.html
  class AccordionComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param sections number
    # @param open_section number "Which section is open on load (0 = none)"
    def playground(sections: 3, open_section: 0)
      render_with_template(locals: { count: sections.to_i.clamp(1, 10), open_section: open_section.to_i })
    end

    # @label Default example
    #
    # GCWeb's accordion example.
    def default
      render_with_template
    end

    # @label Remembered across page loads
    #
    # `persist: :session` reopens the section that was open when the page
    # is reloaded in the same tab.
    def persist
      render_with_template
    end
  end
end
