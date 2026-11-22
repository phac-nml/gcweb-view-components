require "test_helper"

module Gcweb
  class TableComponentTest < ComponentTestCase
    Person = Struct.new(:name, :age)

    test "builds the head and body from rows and columns" do
      render_inline(TableComponent.new(caption: "People", rows: [ { name: "Mark", age: 30 }, { "name" => "Jacob", "age" => 41 } ])) do |table|
        table.with_column("Name", :name, row_header: true)
        table.with_column("Age", :age)
      end

      assert_selector "table.table > caption", text: "People"
      assert_selector "table > caption + thead > tr > th[scope=col]", count: 2
      assert_selector "thead th:first-child", text: "Name"
      assert_selector "tbody > tr", count: 2
      assert_selector "tbody > tr:first-child > th[scope=row]", text: "Mark"
      assert_selector "tbody > tr:first-child > th + td", text: "30"
      assert_selector "tbody > tr:last-child > th", text: "Jacob"
    end

    test "a column reads a method from objects, or what its block returns" do
      render_inline(TableComponent.new(rows: [ Person.new("Larry", 52) ])) do |table|
        table.with_column("Name", :name)
        table.with_column("Next year") { |person| person.age + 1 }
        table.with_column("Shout", class: "success") { |person| person.name.upcase }
      end

      assert_selector "tbody td", text: "Larry"
      assert_selector "tbody td", text: "53"
      assert_selector "tbody td.success", text: "LARRY"
    end

    test "cell content is escaped" do
      render_inline(TableComponent.new(rows: [ { name: "<b>bold</b>" } ])) { |table| table.with_column("Name", :name) }

      assert_selector "td", text: "<b>bold</b>"
      assert_no_selector "td b"
    end

    test "row_attributes adds attributes to each body row" do
      rows = [ { name: "A", ok: true }, { name: "B", ok: false } ]
      render_inline(TableComponent.new(rows: rows, row_attributes: ->(row) { { class: row[:ok] ? "success" : "danger" } })) do |table|
        table.with_column("Name", :name)
      end

      assert_selector "tbody tr.success", text: "A"
      assert_selector "tbody tr.danger", text: "B"
    end

    test "without columns the content is the table's inside" do
      render_inline(TableComponent.new(caption: "C")) { "<thead><tr><th>H</th></tr></thead><tbody><tr><td>D</td></tr></tbody>".html_safe }

      assert_selector "table.table > caption + thead > tr > th", text: "H"
      assert_selector "table > tbody > tr > td", text: "D"
    end

    test "variants become GCWeb's classes" do
      render_inline(TableComponent.new(striped: true, bordered: true, hover: true, condensed: true, gridify: true, id: "t", class: "mrgn-bttm-0")) { "" }

      assert_selector "table#t.table.table-striped.table-bordered.table-hover.table-condensed.tbl-gridify.mrgn-bttm-0", visible: :all
    end

    test "responsive wraps the table" do
      render_inline(TableComponent.new(responsive: true)) { "" }

      assert_selector "div.table-responsive > table.table", visible: :all
    end

    test "no caption, no caption element" do
      render_inline(TableComponent.new(rows: [])) { |table| table.with_column("Name", :name) }

      assert_no_selector "caption"
      assert_selector "thead th", text: "Name"
      assert_no_selector "tbody tr"
    end

    test "rejects rows without columns, and columns without a key or block" do
      assert_raises(ArgumentError) { render_inline(TableComponent.new(rows: [ 1 ])) }
      assert_raises(ArgumentError) { render_inline(TableComponent.new(rows: [ 1 ])) { |table| table.with_column("Name") } }
    end
  end
end
