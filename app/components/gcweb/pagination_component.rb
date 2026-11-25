module Gcweb
  # Pagination (GCWeb's `.pagination`, as in its search results template and
  # its data tables): links to the previous page, numbered pages and the next.
  #
  # With Pagy (43 or later; Pagy isn't a dependency of the gem):
  #
  #   <%= render Gcweb::PaginationComponent.new(pagy: @pagy) %>
  #
  # Or with any pager, given the page, the number of pages and a page's URL:
  #
  #   <%= render Gcweb::PaginationComponent.new(page: 2, pages: 12, url: ->(page) { samples_path(page:) }) %>
  #
  # It shows up to seven pages, as GCWeb's data tables do: the first, the
  # last and those around the current one. It renders nothing for a single
  # page. DataTableComponent renders one itself when it's given `pagy:`.
  class PaginationComponent < ViewComponent::Base
    SLOTS = 7

    # Whether a Pagy object knows its number of pages (countless and keyset ones don't).
    def self.counted?(pagy) = pagy.respond_to?(:count) && pagy.respond_to?(:last) && !pagy.count.nil?

    # @param pagy [Pagy, nil] a Pagy object that has counted its records
    # @param page [Integer, nil] the current page, without pagy
    # @param pages [Integer, nil] the number of pages, without pagy
    # @param url [#call, nil] given a page number, returns its URL; defaults to pagy's
    # @param label [String, nil] the navigation's name; defaults to "Pagination"
    # @param controls [String, nil] the id of the element the pages are of
    # @param list_attributes [Hash] extra attributes for the <ol>
    # @param link_attributes [Hash] extra attributes for the links
    # @param html_attributes [Hash] extra attributes for the <nav>
    def initialize(pagy: nil, page: nil, pages: nil, url: nil, label: nil, controls: nil, list_attributes: {}, link_attributes: {}, **html_attributes)
      raise ArgumentError, "pagy: needs a Pagy object that counts its records (pagy(:offset, …))" if pagy && !self.class.counted?(pagy)
      raise ArgumentError, "give pagy:, or page:, pages: and url:" unless pagy || (page && pages && url)

      @page = (pagy ? pagy.page : page).to_i
      @pages = (pagy ? pagy.last : pages).to_i
      @url = url || pagy.method(:page_url)
      @label = label
      @controls = controls
      @list_attributes = list_attributes
      @link_attributes = link_attributes
      @html_attributes = html_attributes
    end

    def render? = @pages > 1

    def call
      tag.nav("aria-label": @label || t("gcweb.pagination.label"), **@html_attributes) do
        tag.ol(safe_join([ previous_item, *series.map { |number| page_item(number) }, next_item ].compact),
               **@list_attributes, class: class_names("pagination", @list_attributes[:class]))
      end
    end

    private

    # GCWeb's data tables (DataTables' simple_numbers) without its ellipses,
    # which GCWeb drops.
    def series
      return (1..@pages).to_a if @pages <= SLOTS

      edge = SLOTS - 3
      if @page <= edge then [ *1..(edge + 1), @pages ]
      elsif @page > @pages - edge then [ 1, *(@pages - edge)..@pages ]
      else [ 1, *(@page - 1)..(@page + 1), @pages ]
      end
    end

    # Beyond the last page (a stale link), Previous goes to the last page.
    def previous_item
      item([ @page - 1, @pages ].min, t("gcweb.pagination.previous"), class: "previous", rel: "prev") if @page > 1
    end

    def next_item
      item(@page + 1, t("gcweb.pagination.next"), class: "next", rel: "next") if @page < @pages
    end

    def page_item(number)
      current = number == @page
      text = safe_join([ tag.span("#{t('gcweb.pagination.page')} ", class: "wb-inv"), number ])
      item(number, text, active: current, class: ("current" if current), "aria-current": ("page" if current))
    end

    def item(number, text, active: false, **attributes)
      link = tag.a(text, **@link_attributes, href: @url.call(number), "aria-controls": @controls, **attributes,
                   class: class_names("paginate_button", @link_attributes[:class], attributes[:class]))
      tag.li(link, class: ("active" if active))
    end
  end
end
