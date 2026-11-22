module Gcweb
  # Table (GCWeb common/tables): a Bootstrap 3 `.table` with GCWeb's
  # caption and colours.
  #
  # Give it rows and columns, and it builds the head and body:
  #
  #   <%= render Gcweb::TableComponent.new(caption: "Population", rows: @cities, striped: true) do |table| %>
  #     <% table.with_column("City", :name, row_header: true) %>
  #     <% table.with_column("Population") { |city| number_with_delimiter(city.population) } %>
  #   <% end %>
  #
  # Or write the <thead>/<tbody> yourself (for column groups, a <tfoot>,
  # several bodies or cells that span):
  #
  #   <%= render Gcweb::TableComponent.new(bordered: true) do %>
  #     <thead>…</thead>
  #     <tbody>…</tbody>
  #   <% end %>
  #
  # Column headings get scope="col" and row headings scope="row". For
  # GCWeb's contextual colours, give rows a class with `row_attributes:`
  # (`->(row) { { class: "success" } }`) or put one on a cell with the
  # column's attributes. The variants combine like GCWeb's classes.
  class TableComponent < ViewComponent::Base
    # GCWeb's contextual classes, for rows (row_attributes:) and cells.
    CONTEXTS = %i[active success info warning danger].freeze

    # One column of a table built from rows.
    class Column
      attr_reader :header, :row_header, :html_attributes

      def initialize(header, key, row_header, html_attributes, block)
        @header = header
        @key = key
        @row_header = row_header
        @html_attributes = html_attributes
        @block = block
        raise ArgumentError, "a column needs a key or a block" unless key || block
      end

      # The cell's content for a row. An ERB block's output wins; otherwise
      # the block's return value (so `{ |row| row.count }` works for numbers).
      def value(row, view_context)
        return row.is_a?(Hash) ? row.fetch(@key) { row[@key.to_s] } : row.public_send(@key) unless @block

        result = nil
        output = view_context.with_output_buffer { result = @block.call(row) }
        output.presence || result
      end
    end

    attr_reader :caption, :columns

    # @param caption [String, nil] the table's caption
    # @param rows [Enumerable, nil] one item per body row; needs columns (with_column)
    # @param striped [Boolean] stripe alternate body rows (table-striped)
    # @param bordered [Boolean] borders on every cell (table-bordered)
    # @param hover [Boolean] highlight the row under the pointer (table-hover)
    # @param condensed [Boolean] halve the cell padding (table-condensed)
    # @param responsive [Boolean] scroll sideways below 768px (in a div.table-responsive)
    # @param gridify [Boolean] stack every cell on its own line, headings hidden (tbl-gridify)
    # @param row_attributes [#call, nil] given a row, returns extra attributes for its <tr>
    # @param html_attributes [Hash] extra attributes for the <table> (class is appended)
    def initialize(caption: nil, rows: nil, striped: false, bordered: false, hover: false, condensed: false,
                   responsive: false, gridify: false, row_attributes: nil, **html_attributes)
      @caption = caption.presence
      @rows = rows
      @variants = { striped:, bordered:, hover:, condensed: }
      @responsive = responsive
      @gridify = gridify
      @row_attributes = row_attributes
      @html_attributes = html_attributes
      @columns = []
    end

    # Adds a column. The cell shows `key` read from each row (a hash key or
    # a method name), or what the block returns for the row.
    #
    # @param header [String] the column heading
    # @param key [Symbol, String, nil] the row's value to show
    # @param row_header [Boolean] make this column's cells row headings (<th scope="row">)
    # @param html_attributes [Hash] extra attributes for this column's body cells
    def with_column(header, key = nil, row_header: false, **html_attributes, &block)
      @columns << Column.new(header, key, row_header, html_attributes, block)
      nil
    end

    def before_render
      content # runs the block, which adds the columns
      raise ArgumentError, "rows: needs at least one column (with_column)" if @rows && @columns.empty?
    end

    def call
      table = tag.table(**@html_attributes, class: classes) do
        safe_join([ (tag.caption(caption) if caption), *(@columns.any? ? [ head, body ] : [ content ]) ].compact)
      end

      @responsive ? tag.div(table, class: "table-responsive") : table
    end

    private

    def classes
      class_names("table", *@variants.filter_map { |name, on| "table-#{name}" if on }, { "tbl-gridify" => @gridify }, @html_attributes[:class])
    end

    def head
      tag.thead(tag.tr(safe_join(@columns.map { |column| tag.th(column.header, scope: "col") })))
    end

    def body
      tag.tbody(safe_join((@rows || []).map { |row| body_row(row) }))
    end

    def body_row(row)
      tag.tr(**(@row_attributes&.call(row) || {})) do
        safe_join(@columns.map do |column|
          value = column.value(row, @view_context)
          column.row_header ? tag.th(value, scope: "row", **column.html_attributes) : tag.td(value, **column.html_attributes)
        end)
      end
    end
  end
end
