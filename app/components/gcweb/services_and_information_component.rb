module Gcweb
  # Services and information (GCWeb components/gc-srvinfo): doormat links
  # to the most important pages about a topic, each a linked heading and a
  # short description.
  #
  #   <%= render Gcweb::ServicesAndInformationComponent.new do |srvinfo| %>
  #     <% srvinfo.with_item(title: "Apply for benefits", href: "/apply",
  #                          description: "Check if you're eligible and apply online") %>
  #     <% srvinfo.with_item(title: "Report a change", href: "/change") do |item| %>
  #       <% item.with_label(variant: :primary) { "(New)" } %>
  #     <% end %>
  #   <% end %>
  #
  # `layout:` lays the items out in three columns (two on medium screens),
  # two columns, a single column, or a numbered list (`:sequential`). The
  # columns are the grid layer's `.row` and `.col-*`, kept equal in height
  # by `.wb-eqht-grd` (GCWeb's demos use the wb-eqht JavaScript plugin).
  # GCWeb recommends the single-column layouts on pages with a limited
  # content width. It renders nothing without items.
  class ServicesAndInformationComponent < ViewComponent::Base
    LAYOUTS = {
      three_columns: "col-md-6 col-lg-4",
      two_columns: "col-md-6",
      single: nil,
      sequential: nil
    }.freeze
    HEADING_LEVELS = (2..5).freeze

    # One doormat link: a heading with the link (and an optional label),
    # the description, then any content passed in the block.
    class ItemComponent < ViewComponent::Base
      # A label after the link (GCWeb's "with labels" example).
      renders_one :label, Gcweb::LabelComponent

      attr_writer :heading_level

      # @param title [String] the link text
      # @param href [String] where it links to
      # @param description [String, nil] a short summary, in a <p>
      # @param link_attributes [Hash] extra attributes for the link
      def initialize(title:, href:, description: nil, link_attributes: {})
        @title = title.to_s
        raise ArgumentError, "title can't be blank" if @title.empty?

        @href = href
        @description = description
        @link_attributes = link_attributes
        @heading_level = 3
      end

      def call
        heading = content_tag(:"h#{@heading_level}", safe_join([ link_to(@title, @href, **@link_attributes), *([ " ", label ] if label?) ]))
        safe_join([ heading, (tag.p(@description) if @description.present?), content ].compact)
      end
    end

    renders_many :items, ItemComponent

    # Content for the "more information" well after the items (GCWeb's
    # "with more information" example), such as a heading and a paragraph.
    renders_one :more_info

    attr_reader :layout

    # @param layout [Symbol] :three_columns, :two_columns, :single or :sequential
    # @param title [String, nil] the heading; defaults to "Services and information" (gcweb.services_and_information.title)
    # @param hidden_title [Boolean] keep the heading for screen readers only
    # @param heading_level [Integer] 2–5; the items' headings are one level lower
    # @param html_attributes [Hash] extra attributes for the <section> (class is appended)
    def initialize(layout: :three_columns, title: nil, hidden_title: false, heading_level: 2, **html_attributes)
      @layout = layout.to_sym
      raise ArgumentError, "Unsupported layout: #{layout.inspect} (use #{LAYOUTS.keys.join(', ')})" unless LAYOUTS.key?(@layout)

      @title = title.presence&.to_s
      @hidden_title = hidden_title
      @heading_level = Integer(heading_level)
      raise ArgumentError, "heading_level must be between 2 and 5" unless HEADING_LEVELS.cover?(@heading_level)

      @html_attributes = html_attributes
    end

    def title = @title || t("gcweb.services_and_information.title")

    def render? = items?

    def call
      tag.section(**@html_attributes, class: class_names("gc-srvinfo", @html_attributes[:class])) do
        safe_join([ heading, body, (tag.div(more_info, class: "well") if more_info?) ].compact)
      end
    end

    private

    def heading
      content_tag(:"h#{@heading_level}", title, class: ("wb-inv" if @hidden_title))
    end

    def body
      items.each { |item| item.heading_level = @heading_level + 1 }

      case layout
      when :single then safe_join(items)
      when :sequential then tag.ol(safe_join(items.map { |item| tag.li(item) }))
      else tag.div(safe_join(items.map { |item| tag.div(item, class: LAYOUTS.fetch(layout)) }), class: "wb-eqht-grd row")
      end
    end
  end
end
