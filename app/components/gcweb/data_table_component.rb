require "securerandom"

module Gcweb
  # Data table (wet-boew tables / wb-tables): a table with GCWeb's sortable
  # headings, filter box and "Showing 1 to 10 of 57 entries" line, sorted and
  # filtered by your app on the server.
  #
  # The headings are links and the filter is a GET form, so sorting and
  # filtering are plain requests with `sort`, `direction` and `q` in the URL:
  # your controller reads them, queries the database and passes the rows in.
  # Inside a Turbo Frame only the frame is replaced.
  #
  #   # samples_controller.rb
  #   sort = %w[name collected_on].include?(params[:sort]) ? params[:sort] : "name"
  #   direction = params[:direction] == "desc" ? :desc : :asc
  #   @samples = Sample.where("name ILIKE ?", "%#{Sample.sanitize_sql_like(params[:q].to_s)}%").order(sort => direction)
  #
  #   <%= render Gcweb::DataTableComponent.new(rows: @samples, caption: "Samples",
  #         sort: params[:sort], direction: params[:direction], filter: params[:q]) do |table| %>
  #     <% table.with_column("Name", :name, sortable: true, row_header: true) %>
  #     <% table.with_column("Collected", :collected_on, sortable: true) %>
  #     <% table.with_column("Status") { |sample| sample.status.humanize } %>
  #   <% end %>
  #
  # The component never sorts or filters the rows itself; it shows which
  # column is sorted (aria-sort, GCWeb's arrows) and builds the links. A sort
  # link keeps the page's other query parameters, drops `page` (a new order
  # starts again at page 1) and flips the direction of the current column.
  # Only the `sort` values of sortable columns count: anything else shows
  # as unsorted, so check them in the controller too.
  #
  # With `pagy:` (Pagy 43 or later, which your app adds) it shows one page:
  # the info line counts all the rows, and the page links go under the table.
  # If Pagy lets the client choose the page size (client_limit:), a page-size
  # menu is shown too.
  #
  #   @pagy, @samples = pagy(@samples, limit: 10, client_limit: 100)
  #
  #   <%= render Gcweb::DataTableComponent.new(rows: @samples, pagy: @pagy, …) do |table| %>
  #
  # Everything TableComponent takes (striped:, bordered:, row_attributes:, …)
  # works here too.
  class DataTableComponent < TableComponent
    DIRECTIONS = %w[asc desc].freeze
    PAGE_SIZES = [ 10, 25, 50, 100 ].freeze

    # A column that may sort the table.
    class Column < TableComponent::Column
      attr_reader :sort_key

      # sortable is true (sort by the column's key), or the `sort` value to use.
      def initialize(header, key, row_header, html_attributes, block, sortable:)
        super(header, key, row_header, html_attributes, block)
        @sort_key = (sortable == true ? key : sortable).presence&.to_s
        raise ArgumentError, "a sortable column without a key needs sortable: \"<sort value>\"" if sortable && !@sort_key
      end
    end

    # @param rows [Enumerable] the rows to show, already sorted and filtered
    # @param sort [String, nil] the current sort value (params[:sort])
    # @param direction [String, nil] "asc" or "desc" (params[:direction]); anything else is "asc"
    # @param filter [String, nil] the current filter text (params[:q]), shown in the filter box
    # @param filterable [Boolean] show the filter box
    # @param info [Boolean] show the "Showing 1 to 10 of 57 entries" line
    # @param unfiltered_count [Integer, nil] the number of rows before filtering, for
    #   "(filtered from 1,234 total entries)" while a filter is applied
    # @param pagy [Pagy, nil] the Pagy object rows is a page of (one that counts its records)
    # @param page_sizes [Array<Integer>] the page-size menu's choices, up to Pagy's client_limit
    # @param url [String, nil] where the links and the form go; defaults to the current path
    # @param params [Hash, nil] the query parameters links keep; defaults to the current ones
    # @param sort_param [String, Symbol] the query parameter for the sort value
    # @param direction_param [String, Symbol] the query parameter for the direction
    # @param filter_param [String, Symbol] the query parameter for the filter text
    # @param page_param [String, Symbol] the page parameter, dropped when sorting or filtering; with pagy, its page_key
    # @param table_options [Hash] TableComponent's options and the <table>'s attributes
    def initialize(rows:, sort: nil, direction: nil, filter: nil, filterable: true, info: true,
                   unfiltered_count: nil, pagy: nil, page_sizes: PAGE_SIZES, url: nil, params: nil, sort_param: :sort,
                   direction_param: :direction, filter_param: :q, page_param: :page, **table_options)
      raise ArgumentError, "rows: is required" if rows.nil?

      raise ArgumentError, "pagy: needs a Pagy object that counts its records (pagy(:offset, …))" if pagy && !PaginationComponent.counted?(pagy)

      super(rows:, **table_options)
      @pagy = pagy
      @page_sizes = page_sizes
      page_param = pagy.options[:page_key] if pagy
      @sort = sort.presence&.to_s
      @direction = DIRECTIONS.include?(direction.to_s) ? direction.to_s : "asc"
      @filter = filter.to_s
      @filterable = filterable
      @info = info
      @unfiltered_count = unfiltered_count
      @url = url
      @params = params
      @param_names = { sort: sort_param, direction: direction_param, filter: filter_param, page: page_param }.transform_values(&:to_s)
      @html_attributes[:id] ||= "gcweb-data-table-#{SecureRandom.hex(4)}"
    end

    # Adds a column (see TableComponent#with_column).
    #
    # @param sortable [Boolean, String] true to sort by `key`, or the `sort` value for this column
    def with_column(header, key = nil, row_header: false, sortable: false, **html_attributes, &block)
      @columns << Column.new(header, key, row_header, html_attributes, block, sortable:)
      nil
    end

    def before_render
      super
      raise ArgumentError, "a data table needs at least one column (with_column)" if @columns.empty?

      @sorted_column = @columns.find { |column| column.sort_key && column.sort_key == @sort }
    end

    def call
      tag.div(class: "dataTables_wrapper no-footer", id: "#{id}_wrapper") do
        safe_join([ top, super, bottom ].compact)
      end
    end

    # The <table>'s id; the filter box and info line point at it.
    def id = @html_attributes[:id]

    # The sorted column, if the sort value names a sortable one (after rendering starts).
    attr_reader :sorted_column

    private

    def classes
      class_names("wb-tables", super, "dataTable", "no-footer")
    end

    def top
      parts = [ (filter_box if @filterable), (info_line if @info), (page_size if page_size?) ].compact
      tag.div(safe_join(parts), class: "top") if parts.any?
    end

    def filter_box
      tag.div(class: "dataTables_filter", id: "#{id}_filter") do
        tag.form(action: base_url, method: "get", "accept-charset": "UTF-8") do
          safe_join([
            tag.label do
              safe_join([ t("gcweb.data_table.filter"),
                          tag.input(type: "search", name: @param_names[:filter], value: @filter.presence, "aria-controls": id) ])
            end,
            *hidden_fields(query_params.except(@param_names[:filter], @param_names[:page]))
          ])
        end
      end
    end

    def bottom
      return unless @pagy && @pagy.last > 1

      url = ->(page) { url_with(query_params.merge(@param_names[:page] => page)) }
      tag.div(class: "bottom") do
        render PaginationComponent.new(pagy: @pagy, url: (url if @url || @params), controls: id, id: "#{id}_paginate",
                                       label: (t("gcweb.data_table.pagination", caption: strip_tags(caption.to_s)) if caption),
                                       class: "dataTables_paginate paging_simple_numbers",
                                       list_attributes: { class: "mrgn-tp-0 mrgn-bttm-0" })
      end
    end

    def page_size? = @pagy && @pagy.options[:client_limit]

    def page_size
      name = @pagy.options[:limit_key]
      select = tag.select(page_size_options, name:, "aria-controls": id)

      tag.div(class: "dataTables_length", id: "#{id}_length") do
        tag.form(action: base_url, method: "get", "accept-charset": "UTF-8") do
          safe_join([
            tag.label(t("gcweb.data_table.length_html", menu: select)),
            tag.button(t("gcweb.data_table.length_apply"), type: "submit", class: "btn btn-default btn-xs"),
            *hidden_fields(query_params.except(name, @param_names[:page]))
          ])
        end
      end
    end

    # The choices Pagy accepts, and the current size if it isn't one of them.
    def page_size_options
      sizes = [ *@page_sizes.select { |size| size <= @pagy.options[:client_limit] }, @pagy.limit ].uniq.sort
      safe_join(sizes.map { |size| tag.option(size, value: size, selected: size == @pagy.limit) })
    end

    # Hidden inputs that carry the other query parameters through the form.
    def hidden_fields(query)
      Rack::Utils.build_nested_query(query).split("&").filter_map do |pair|
        name, value = pair.split("=", 2).map { |part| Rack::Utils.unescape(part.to_s) }
        tag.input(type: "hidden", name:, value:) if name.present?
      end
    end

    def info_line
      tag.div(info_text, class: "dataTables_info", id: "#{id}_info", role: "status", "aria-live": "polite")
    end

    def info_text
      first, last, count = @pagy ? [ @pagy.from, @pagy.to, @pagy.count ] : [ 1, row_count, row_count ]
      text = count.zero? ? t("gcweb.data_table.info_empty") : t("gcweb.data_table.info", first: number(first), last: number(last), total: number(count))
      return text unless @filter.present? && @unfiltered_count && @unfiltered_count != count

      "#{text} #{t('gcweb.data_table.info_filtered', max: number(@unfiltered_count))}"
    end

    def number(value)
      number_with_delimiter(value, delimiter: t("gcweb.data_table.thousands_delimiter"))
    end

    def head
      tag.thead(tag.tr(safe_join(@columns.map { |column| heading(column, column.equal?(sorted_column)) })))
    end

    def heading(column, sorted)
      return tag.th(column.header, scope: "col", class: "sorting_disabled") unless column.sort_key

      next_direction = sorted && @direction == "asc" ? "desc" : "asc"
      classes = class_names("sorting", "sorting_#{@direction}" => sorted)
      aria_sort = ({ "asc" => "ascending", "desc" => "descending" }[@direction] if sorted)
      title = t("gcweb.data_table.sort_#{next_direction}", column: strip_tags(column.header.to_s))

      tag.th(scope: "col", class: classes, "aria-sort": aria_sort) do
        link_to(sort_url(column, next_direction), title:) do
          safe_join([ column.header, tag.span(tag.span(class: "sorting-icons", "aria-hidden": "true"), class: "sorting-cnt") ])
        end
      end
    end

    def sort_url(column, direction)
      query = query_params.except(@param_names[:page])
                          .merge(@param_names[:sort] => column.sort_key, @param_names[:direction] => direction)
      url_with(query)
    end

    def url_with(query) = "#{base_url}?#{Rack::Utils.build_nested_query(query)}"

    def body
      return super if row_count.positive?

      tag.tbody(tag.tr(tag.td(t("gcweb.data_table.empty"), class: "dataTables_empty", colspan: @columns.size)))
    end

    # Marks the sorted column's cells, as DataTables does (td.sorting_1).
    def cell_attributes(column)
      attributes = super
      return attributes unless column.equal?(sorted_column)

      attributes.merge(class: class_names("sorting_1", attributes[:class]))
    end

    # Loads a relation once (to_a), rather than counting it with a query.
    def row_count = @row_count ||= @rows.to_a.size

    def base_url = @url || request.path

    def query_params
      @query_params ||= begin
        query = @params || request.query_parameters
        (query.respond_to?(:to_unsafe_h) ? query.to_unsafe_h : query.to_h).stringify_keys
      end
    end
  end
end
