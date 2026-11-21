module Gcweb
  # Most requested (GCWeb components/gc-most-requested): a full-width band
  # of links to a topic's most requested tasks.
  #
  #   <%= render Gcweb::MostRequestedComponent.new do |most_requested| %>
  #     <% most_requested.with_link("Apply for benefits", href: "/apply") %>
  #     <% most_requested.with_link("Report a change", href: "/change") do |link| %>
  #       <% link.with_label(variant: :primary) { "(New)" } %>
  #     <% end %>
  #   <% end %>
  #
  # It renders GCWeb's `section.gc-most-requested` with its own
  # `.container`, so put it straight in `<main>`, not inside another
  # `.container` (GCWeb then drops the background and the columns, as in
  # its "bad implementation" example). From 992px the heading sits on the
  # left and the links flow into two columns; exactly two links sit side by
  # side. Two components in a row highlight the first one with a blue
  # background (GCWeb's "highlight" example). The heading is "Most
  # requested" unless `title:` is given. It renders nothing without links.
  class MostRequestedComponent < ViewComponent::Base
    HEADING_LEVELS = (2..6).freeze

    # One link, in a list item, with an optional label after it.
    class LinkComponent < ViewComponent::Base
      # A label after the link (GCWeb's "with labels" example).
      renders_one :label, Gcweb::LabelComponent

      # @param text [String] the link text
      # @param href [String] where it links to
      # @param html_attributes [Hash] extra attributes for the link
      def initialize(text, href:, **html_attributes)
        @text = text.to_s
        raise ArgumentError, "text can't be blank" if @text.empty?

        @href = href
        @html_attributes = html_attributes
      end

      def call
        tag.li(safe_join([ link_to(@text, @href, **@html_attributes), *([ " ", label ] if label?) ]))
      end
    end

    renders_many :links, LinkComponent

    # @param title [String, nil] the heading; defaults to "Most requested" (gcweb.most_requested.title)
    # @param heading_level [Integer] 2–6; GCWeb's examples use h2
    # @param html_attributes [Hash] extra attributes for the <section> (class is appended)
    def initialize(title: nil, heading_level: 2, **html_attributes)
      @title = title.presence&.to_s
      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 6" unless HEADING_LEVELS.cover?(@heading_level)

      @html_attributes = html_attributes
    end

    def title = @title || t("gcweb.most_requested.title")

    def render? = links?

    def call
      tag.section(**@html_attributes, class: class_names("gc-most-requested", @html_attributes[:class])) do
        tag.div(class: "container") do
          safe_join([ content_tag(:"h#{@heading_level}", title), tag.ul(safe_join(links)) ])
        end
      end
    end
  end
end
