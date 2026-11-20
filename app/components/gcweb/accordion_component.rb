module Gcweb
  # Accordion (wet-boew wb-toggle's grouped details) as on GCWeb v20.0.1.
  #
  #   <%= render Gcweb::AccordionComponent.new(id: "faq") do |accordion| %>
  #     <% accordion.with_section(title: "Who can apply?") do %>
  #       <p>…</p>
  #     <% end %>
  #     <% accordion.with_section(title: "How long does it take?", open: true) do %>
  #       <p>…</p>
  #     <% end %>
  #   <% end %>
  #
  # Each section is a <details> whose summary toggles it; opening one closes
  # the others, and the open one can be closed. The summaries carry GCWeb's
  # wb-toggle markup for the `gcweb--toggle` Stimulus controller, and the
  # sections share a `name`, so browsers keep one open even without
  # JavaScript.
  class AccordionComponent < ViewComponent::Base
    # One section: the summary is its heading, the content its panel.
    class SectionComponent < ViewComponent::Base
      attr_reader :title
      attr_writer :open, :name, :summary_id, :toggle

      # @param title [String] the summary text; an html_safe string keeps markup
      # @param open [Boolean] open this section on page load (the first one marked open)
      def initialize(title:, open: false)
        @title = title
        @open = open
      end

      def open? = @open

      def call
        tag.details(class: "acc-group", name: @name, open: @open || nil) do
          safe_join([
            tag.summary(title, id: @summary_id, class: "wb-toggle tgl-tab", data: { controller: "gcweb--toggle", toggle: @toggle }),
            tag.div(content, class: "tgl-panel")
          ])
        end
      end
    end

    renders_many :sections, SectionComponent

    attr_reader :id

    # @param id [String] the accordion's id (it groups the sections)
    # @param persist [Symbol, nil] :session or :local keeps the open section across page loads
    # @param html_attributes [Hash] extra attributes for the container (class is appended)
    def initialize(id:, persist: nil, **html_attributes)
      @id = id.to_s
      raise ArgumentError, "id can't be blank" if @id.empty?

      @persist = persist&.to_s
      raise ArgumentError, "persist must be :session or :local" if @persist && !%w[session local].include?(@persist)

      @html_attributes = html_attributes
    end

    def render? = sections?

    def call
      tag.div(**@html_attributes, id: id, class: class_names("accordion", @html_attributes[:class])) do
        safe_join(prepared_sections)
      end
    end

    private

    def prepared_sections
      toggle = { parent: "##{id}", group: ".acc-group", persist: @persist }.compact.to_json
      open_section = sections.find(&:open?)
      sections.each.with_index(1) do |section, number|
        section.open = section.equal?(open_section)
        section.name = "#{id}-grp"
        section.summary_id = "#{id}-#{number}"
        section.toggle = toggle
      end
    end
  end
end
