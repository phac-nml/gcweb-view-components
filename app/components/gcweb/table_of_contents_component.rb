module Gcweb
  # In-page table of contents (GCWeb components/gc-toc): links to the
  # sections of the page.
  #
  #   <%= render Gcweb::TableOfContentsComponent.new do |toc| %>
  #     <% toc.with_link("First section heading", href: "#section1") %>
  #     <% toc.with_link(href: "#section2") { "Second section heading" } %>
  #   <% end %>
  #
  # It renders GCWeb's `nav.gc-toc`: a heading ("On this page" unless
  # `title:` is given) and a list of links. GCWeb v20.0.1 has no styles of
  # its own for it, so it looks like any heading and bulleted list. It
  # renders nothing without links.
  class TableOfContentsComponent < ViewComponent::Base
    HEADING_LEVELS = (2..6).freeze

    # One link, in a list item.
    class LinkComponent < ViewComponent::Base
      # @param text [String, nil] the link text (or pass a block)
      # @param href [String] the section's anchor, such as "#section1"
      # @param html_attributes [Hash] extra attributes for the link
      def initialize(text = nil, href:, **html_attributes)
        @text = text
        @href = href.to_s
        raise ArgumentError, "href can't be blank" if @href.empty?

        @html_attributes = html_attributes
      end

      def call
        tag.li(link_to(@text || content, @href, **@html_attributes))
      end
    end

    renders_many :links, LinkComponent

    # @param title [String, nil] the heading; defaults to "On this page" (gcweb.table_of_contents.title)
    # @param heading_level [Integer] 2–6; GCWeb's example uses h2
    # @param html_attributes [Hash] extra attributes for the <nav> (class is appended)
    def initialize(title: nil, heading_level: 2, **html_attributes)
      @title = title.presence&.to_s
      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 6" unless HEADING_LEVELS.cover?(@heading_level)

      @html_attributes = html_attributes
    end

    def title = @title || t("gcweb.table_of_contents.title")

    def render? = links?

    def call
      tag.nav(**@html_attributes, class: class_names("gc-toc", @html_attributes[:class])) do
        safe_join([ content_tag(:"h#{@heading_level}", title), tag.ul(safe_join(links)) ])
      end
    end
  end
end
