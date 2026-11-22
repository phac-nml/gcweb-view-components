module Gcweb
  # Breadcrumb trail (GCWeb sites/breadcrumbs): where the page sits in the
  # site, from Canada.ca down to the page's parent (not the page itself).
  #
  #   <%= render Gcweb::BreadcrumbsComponent.new do |breadcrumbs| %>
  #     <% breadcrumbs.with_item("Health", "https://www.canada.ca/en/services/health.html") %>
  #     <% breadcrumbs.with_item("Diseases and conditions", diseases_path) %>
  #   <% end %>
  #
  # It renders GCWeb's `nav#wb-bc` with a hidden "You are here:" heading
  # and schema.org BreadcrumbList markup. The first link is Canada.ca
  # (in the page's language) unless `canada_ca: false`. Usually it goes in
  # the header (Gcweb::HeaderComponent#with_breadcrumbs); on its own it
  # needs no wrapper. It renders nothing without links.
  class BreadcrumbsComponent < ViewComponent::Base
    CANADA_CA = { en: "https://www.canada.ca/en.html", fr: "https://www.canada.ca/fr.html" }.freeze

    # @param canada_ca [Boolean] start the trail with a link to Canada.ca
    # @param html_attributes [Hash] extra attributes for the <nav>
    def initialize(canada_ca: true, **html_attributes)
      @canada_ca = canada_ca
      @html_attributes = html_attributes
      @items = []
    end

    # Adds a link to the trail.
    #
    # @param text [String] the link text
    # @param href [String] where it links to
    def with_item(text, href)
      raise ArgumentError, "breadcrumb text can't be blank" if text.blank?

      @items << [ text.to_s, href ]
      nil
    end

    def before_render
      content # runs the block, which adds the items
    end

    def render? = items.any?

    def call
      tag.nav(id: "wb-bc", property: "breadcrumb", **@html_attributes) do
        safe_join([
          tag.h2(t("gcweb.breadcrumbs.title")),
          tag.div(class: "container") do
            tag.ol(safe_join(items.each_with_index.map { |(text, href), index| item(text, href, index + 1) }),
                   class: "breadcrumb", typeof: "BreadcrumbList")
          end
        ])
      end
    end

    private

    def items
      @canada_ca ? [ [ "Canada.ca", CANADA_CA.fetch(language) ], *@items ] : @items
    end

    def language = I18n.locale.to_s.start_with?("fr") ? :fr : :en

    def item(text, href, position)
      tag.li(property: "itemListElement", typeof: "ListItem") do
        safe_join([
          tag.a(tag.span(text, property: "name"), href: href, property: "item", typeof: "WebPage"),
          tag.meta(property: "position", content: position)
        ])
      end
    end
  end
end
