require "yaml"
require "pagy"

module Gcweb
  # `include Pagy::Method`, as a controller would.
  module PagyPreviewHelper
    extend Pagy::Method

    def self.paginate(rows, **options) = pagy(:offset, rows, **options)
  end
end

module Gcweb
  # @label Data table
  #
  # GCWeb's data table (wet-boew `wb-tables`) with sortable headings, a
  # filter box and the "Showing 1 to 57 of 57 entries" line. Sorting and
  # filtering happen on the server: the headings are links and the filter
  # is a GET form, and here the preview plays the controller, sorting and
  # filtering GCWeb's demo rows from the URL's `sort`, `direction` and `q`.
  # Click a heading or type in the filter box and press Enter.
  #
  # - wet-boew data tables: https://wet-boew.github.io/gcweb-compiled-demos/wetboew-demos/tables/tables-en.html
  # - WET style guide: https://wet-boew.github.io/wet-boew-styleguide/design/tables-en
  class DataTableComponentPreview < ViewComponent::Preview
    # The browsers in GCWeb's data tables demo.
    BROWSERS = YAML.load_file(File.join(__dir__, "data_table_component_preview", "browsers.yml")).map do |engine, browser, platforms, version, grade|
      { engine:, browser:, platforms:, version:, grade: }.freeze
    end.freeze

    COLUMNS = %i[engine browser platforms version].freeze
    TEMPLATE = "gcweb/data_table_component_preview/browsers".freeze

    # What a controller would do: filter on every column, then sort (stable,
    # like DataTables).
    def self.query(sort:, direction:, filter:)
      rows = BROWSERS
      if filter.present?
        needle = filter.downcase
        rows = rows.select { |row| row.values.any? { |value| value.downcase.include?(needle) } }
      end
      key = COLUMNS.find { |column| column.to_s == sort }
      return rows unless key

      rows = rows.each_with_index.sort_by { |row, index| [ row[key].downcase, index ] }.map(&:first)
      direction == "desc" ? rows.reverse : rows
    end

    # @label Playground
    # @param striped toggle
    # @param bordered toggle
    # @param hover toggle
    # @param condensed toggle
    # @param filterable toggle "Show the filter box"
    # @param info toggle "Show the entries line"
    def playground(striped: false, bordered: false, hover: false, condensed: false, filterable: true, info: true)
      render_with_template(template: TEMPLATE, locals: {
        defaults: { sort: "engine", direction: "asc" },
        options: { striped:, bordered:, hover:, condensed:, filterable:, info: }
      })
    end

    # @label Default
    #
    # Sorted by the first column, ascending, as GCWeb's data tables start.
    # The CSS grade column can't be sorted.
    def default
      render_with_template(template: TEMPLATE, locals: { defaults: { sort: "engine", direction: "asc" } })
    end

    # @label Sorted descending
    #
    # Sorted by browser, descending: the heading's link sorts ascending again.
    def descending
      render_with_template(template: TEMPLATE, locals: { defaults: { sort: "browser", direction: "desc" } })
    end

    # @label Paged
    #
    # Ten rows a page, with Pagy (`pagy:`). `client_limit:` lets people choose
    # the page size.
    def paged
      render_with_template(template: TEMPLATE, locals: { defaults: { sort: "engine", direction: "asc" }, paged: true })
    end

    # @label Filtered
    #
    # The filter "Opera" matches 8 of the 57 rows. Pass the count before
    # filtering (`unfiltered_count:`) for "(filtered from 57 total entries)".
    def filtered
      render_with_template(template: TEMPLATE, locals: { defaults: { sort: "engine", direction: "asc", q: "Opera" } })
    end

    # @label No matching rows
    #
    # A filter that matches nothing: the body says no data is available.
    def no_matches
      render_with_template(template: TEMPLATE, locals: { defaults: { sort: "engine", direction: "asc", q: "Netscape Navigator 10" } })
    end
  end
end
