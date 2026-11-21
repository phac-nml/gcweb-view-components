module Gcweb
  # @label Table of contents
  #
  # An in-page table of contents: a heading and links to the sections of
  # the page. GCWeb v20.0.1 has no styles of its own for it, so it looks
  # like any heading and bulleted list.
  #
  # - GCWeb working example: https://wet-boew.github.io/GCWeb/components/gc-toc/toc-en.html
  # - Canada.ca design guidance: https://design.canada.ca/common-design-patterns/in-page-toc.html
  class TableOfContentsComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param title text "Leave blank for the default heading"
    # @param heading_level select { choices: [2, 3, 4, 5, 6] }
    def playground(title: "", heading_level: 2)
      render_with_template(locals: { title: title, heading_level: heading_level.to_i })
    end

    # @label In-page table of contents
    #
    # GCWeb's example: the table of contents and the sections it links to.
    def default
      render_with_template
    end
  end
end
