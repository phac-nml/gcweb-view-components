module Gcweb
  # Tabbed interface (wet-boew wb-tabs) as on GCWeb v20.0.1.
  #
  #   <%= render Gcweb::TabsComponent.new do |tabs| %>
  #     <% tabs.with_panel(id: "panel-overview", title: "Overview") do %>
  #       <p>…</p>
  #     <% end %>
  #     <% tabs.with_panel(id: "panel-details", title: "Details", open: true) do %>
  #       <p>…</p>
  #     <% end %>
  #   <% end %>
  #
  # It renders the markup GCWeb authors write: a <details> per panel inside
  # `div.wb-tabs > div.tabpanels`. Without JavaScript those are plain
  # expand/collapse sections. The `gcweb--tabs` Stimulus controller builds
  # the tab list on wide screens and turns the panels into an accordion on
  # screens under 992px, as wb-tabs does.
  #
  # The last tab chosen is remembered for the browser session (by page path
  # and the component's id) unless `ignore_session: true`. A link with the
  # class `wb-tabs-ext` and `href="#panel-id"` anywhere on the page opens
  # that panel.
  class TabsComponent < ViewComponent::Base
    # One panel: the summary is the tab's label, the content its panel.
    class PanelComponent < ViewComponent::Base
      attr_reader :id, :title
      attr_writer :open

      # @param id [String] the panel's id (links to "#id" open it)
      # @param title [String] tab label; an html_safe string keeps markup such as <br>
      # @param open [Boolean] open this panel first (else the first panel)
      def initialize(id:, title:, open: false)
        @id = id.to_s
        @title = title
        @open = open
        raise ArgumentError, "panel id can't be blank" if @id.empty?
      end

      def open? = @open

      def call
        tag.details(id: id, open: @open || nil) do
          safe_join([ tag.summary(title), tag.div(content, class: "tgl-panel") ])
        end
      end
    end

    renders_many :panels, PanelComponent

    # @param id [String, nil] the container's id, part of the session storage
    #   key; defaults to the first panel's id plus "-tabs"
    # @param ignore_session [Boolean] don't remember the last tab chosen
    # @param update_hash [Boolean] put the open panel's id in the URL
    # @param html_attributes [Hash] extra attributes for the container (class is appended)
    def initialize(id: nil, ignore_session: false, update_hash: false, **html_attributes)
      @id = id
      @ignore_session = ignore_session
      @update_hash = update_hash
      @html_attributes = html_attributes
    end

    def render? = panels?

    def call
      tag.div(**container_attributes) do
        tag.div(safe_join(panels_with_one_open), class: "tabpanels")
      end
    end

    private

    def container_attributes
      data = (@html_attributes[:data] || {}).dup
      data[:controller] = [ data[:controller], "gcweb--tabs" ].compact.join(" ")

      @html_attributes.merge(
        id: @id.presence || "#{panels.first.id}-tabs",
        class: class_names("wb-tabs", @html_attributes[:class], "ignore-session": @ignore_session, "update-hash": @update_hash),
        data: data
      )
    end

    # wb-tabs opens one panel: the first marked open, else the first.
    def panels_with_one_open
      open_panel = panels.find(&:open?) || panels.first
      panels.each { |panel| panel.open = panel.equal?(open_panel) }
    end
  end
end
