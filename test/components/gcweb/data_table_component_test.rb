require "test_helper"

module Gcweb
  class DataTableComponentTest < ComponentTestCase
    ROWS = [ { name: "Alpha", count: 3, status: "ok" }, { name: "Beta", count: 1, status: "late" } ].freeze

    # The page's URL, without needing a route for it (with_request_url does).
    def request_url(path, query = {})
      vc_test_request.set_header("PATH_INFO", path)
      vc_test_request.set_header("QUERY_STRING", query.to_query)
    end

    def render_table(rows: ROWS, query: {}, **options)
      request_url("/samples", query)
      render_inline(DataTableComponent.new(rows: rows, id: "samples", **options)) do |table|
        table.with_column("Name", :name, sortable: true, row_header: true)
        table.with_column("Count", :count, sortable: "sample_count")
        table.with_column("Status", :status)
      end
    end

    def sort_link(heading) = page.find("thead th:nth-child(#{heading}) > a")

    test "renders GCWeb's data table markup" do
      render_table(caption: "Samples")

      assert_selector "div.dataTables_wrapper.no-footer#samples_wrapper > div.top + table.wb-tables.table.dataTable.no-footer#samples"
      assert_selector "table > caption", text: "Samples"
      assert_selector "thead th[scope=col]", count: 3
      assert_selector "tbody > tr", count: 2
      assert_selector "tbody > tr:first-child > th[scope=row]", text: "Alpha"
    end

    test "sortable headings are links with GCWeb's icons; others are sorting_disabled" do
      render_table

      assert_selector "thead th.sorting", count: 2
      assert_selector "thead th:nth-child(1) > a > span.sorting-cnt > span.sorting-icons[aria-hidden=true]"
      assert_selector "thead th:nth-child(3).sorting_disabled", text: "Status"
      assert_no_selector "thead th:nth-child(3) a"
      assert_no_selector "thead th[aria-sort]"
      assert_equal "Name: activate for ascending sort", sort_link(1)[:title]
      assert_equal "/samples?sort=name&direction=asc", sort_link(1)[:href]
      assert_equal "/samples?sort=sample_count&direction=asc", sort_link(2)[:href]
    end

    test "the sorted column shows its direction, and its link flips it" do
      render_table(sort: "name", direction: "asc")

      assert_selector "thead th:nth-child(1).sorting.sorting_asc[aria-sort=ascending]"
      assert_equal "Name: activate for descending sort", sort_link(1)[:title]
      assert_includes sort_link(1)[:href], "direction=desc"
      assert_selector "tbody th.sorting_1", count: 2
      assert_no_selector "tbody td.sorting_1"

      render_table(sort: "sample_count", direction: "desc")

      assert_selector "thead th:nth-child(2).sorting_desc[aria-sort=descending]"
      assert_includes sort_link(2)[:href], "direction=asc"
      assert_selector "tbody td.sorting_1", count: 2
    end

    test "an unknown sort value or direction is ignored" do
      render_table(sort: "status", direction: "sideways")

      assert_no_selector "thead th[aria-sort]"
      assert_no_selector ".sorting_1"

      render_table(sort: "name", direction: "sideways")

      assert_selector "thead th:nth-child(1)[aria-sort=ascending]"
    end

    test "sort links keep other query parameters and drop the page" do
      render_table(query: { locale: "fr", page: 3, q: "al", filters: { status: "ok" } }, sort: "name")

      href = sort_link(1)[:href]
      assert_includes href, "locale=fr"
      assert_includes href, "q=al"
      assert_includes href, "filters%5Bstatus%5D=ok"
      assert_not_includes href, "page="
    end

    test "the filter box is a GET form that keeps the sort but not the page" do
      render_table(query: { sort: "name", direction: "desc", page: 2, q: "old" }, filter: "al")

      assert_selector "div.top > div.dataTables_filter#samples_filter > form[action='/samples'][method=get] > label", text: "Filter items"
      assert_selector "label > input[type=search][name=q][value=al][aria-controls=samples]"
      assert_selector "form input[type=hidden][name=sort][value=name]", visible: :hidden
      assert_selector "form input[type=hidden][name=direction][value=desc]", visible: :hidden
      assert_no_selector "form input[type=hidden][name=page]", visible: :hidden
      assert_no_selector "form input[type=hidden][name=q]", visible: :hidden
    end

    test "the info line counts the rows, and what the filter left out" do
      render_table

      assert_selector "div.dataTables_info#samples_info[role=status][aria-live=polite]", text: "Showing 1 to 2 of 2 entries"

      render_table(filter: "a", unfiltered_count: 1500)

      assert_selector ".dataTables_info", text: "Showing 1 to 2 of 2 entries (filtered from 1,500 total entries)"

      render_table(unfiltered_count: 1500)

      assert_selector ".dataTables_info", exact_text: "Showing 1 to 2 of 2 entries"
    end

    test "no rows: the info line and an empty body row" do
      render_table(rows: [], filter: "zzz")

      assert_selector ".dataTables_info", text: "Showing 0 to 0 of 0 entries"
      assert_selector "tbody > tr > td.dataTables_empty[colspan='3']", text: "No data is available in the table"
    end

    test "the filter box and info line can be left out" do
      render_table(filterable: false, info: false)

      assert_no_selector ".top"
      assert_selector "div.dataTables_wrapper > table.dataTable"

      render_table(filterable: false)

      assert_no_selector ".dataTables_filter"
      assert_selector ".top > .dataTables_info"
    end

    test "url:, params: and parameter names can be set" do
      render_table(url: "/lab/samples", params: ActionController::Parameters.new(tab: "all"), sort_param: :order, direction_param: :dir, filter_param: :search)

      assert_equal "/lab/samples?tab=all&order=name&dir=asc", sort_link(1)[:href]
      assert_selector "form[action='/lab/samples'] input[type=search][name=search]"
      assert_selector "form input[type=hidden][name=tab][value=all]", visible: :hidden
    end

    test "French strings" do
      I18n.with_locale(:fr) { render_table(sort: "name", filter: "a", unfiltered_count: 1500) }

      assert_selector ".dataTables_filter label", text: "Filtrer les articles"
      assert_selector ".dataTables_info", text: "Affiche 1 à 2 de 2 entrées (filtré de 1 500 entrées totales)"
      assert_equal "Name : activer pour tri descendant", sort_link(1)[:title]
    end

    test "table variants and attributes still apply" do
      render_table(striped: true, hover: true, class: "mrgn-bttm-0", data: { turbo_frame: "samples" })

      assert_selector "table.wb-tables.table.table-striped.table-hover.dataTable.mrgn-bttm-0[data-turbo-frame=samples]"
    end

    test "an id is generated when none is given" do
      render_inline(DataTableComponent.new(rows: ROWS)) { |table| table.with_column("Name", :name) }

      id = page.find("table")[:id]
      assert_match(/\Agcweb-data-table-\h{8}\z/, id)
      assert_selector "##{id}_wrapper input[aria-controls='#{id}']"
    end

    test "needs rows and a column; a sortable column needs a key or a sort value" do
      assert_raises(ArgumentError) { DataTableComponent.new(rows: nil) }
      assert_raises(ArgumentError) { render_inline(DataTableComponent.new(rows: ROWS)) { "" } }
      assert_raises(ArgumentError) do
        render_inline(DataTableComponent.new(rows: ROWS)) { |table| table.with_column("Name", sortable: true) { "x" } }
      end
    end
  end
end
