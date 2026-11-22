module Gcweb
  # @label Table
  #
  # Bootstrap 3 tables with GCWeb's caption and colours. Build one from
  # rows and columns (`with_column`), or write the `<thead>` and `<tbody>`
  # yourself; the variants (striped, bordered, hover, condensed) combine.
  #
  # Not shown: GCWeb's collapse classes example (Bootstrap's `.collapse`
  # utility), the provisional `gc-table` responsive cards, and `wb-tables`
  # (sorting, filtering, pagination).
  #
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/common/tables/table-en.html
  # - WET style guide: https://wet-boew.github.io/wet-boew-styleguide/design/tables-en
  class TableComponentPreview < ViewComponent::Preview
    # The people in GCWeb's examples.
    PEOPLE = [
      { number: 1, first_name: "Mark", last_name: "Otto", username: "@mdo" },
      { number: 2, first_name: "Jacob", last_name: "Thornton", username: "@fat" },
      { number: 3, first_name: "Larry", last_name: "the Bird", username: "@twitter" }
    ].freeze

    PEOPLE_TEMPLATE = "gcweb/table_component_preview/people".freeze

    # @label Playground
    # @param caption text
    # @param striped toggle
    # @param bordered toggle
    # @param hover toggle
    # @param condensed toggle
    # @param responsive toggle "Scrolls sideways below 768px"
    def playground(caption: "Optional table caption.", striped: false, bordered: false, hover: false, condensed: false, responsive: false)
      render_with_template(template: PEOPLE_TEMPLATE, locals: {
        options: { caption: caption, striped: striped, bordered: bordered, hover: hover, condensed: condensed, responsive: responsive }
      })
    end

    # @label Basic example
    #
    # A table with a caption; the number column holds row headings.
    def basic
      render_with_template(template: PEOPLE_TEMPLATE, locals: { options: { caption: I18n.t("previews.tables.caption") } })
    end

    # @label Striped rows
    def striped
      render_with_template(template: PEOPLE_TEMPLATE, locals: { options: { striped: true } })
    end

    # @label Bordered table
    def bordered
      render_with_template(template: PEOPLE_TEMPLATE, locals: { options: { bordered: true } })
    end

    # @label Hover rows
    #
    # The row under the pointer is highlighted.
    def hover
      render_with_template(template: PEOPLE_TEMPLATE, locals: { options: { hover: true } })
    end

    # @label Condensed table
    #
    # Half the cell padding. Written as markup, for the cell that spans two
    # columns.
    def condensed
      render_with_template
    end

    # @label Contextual classes
    #
    # `active`, `success`, `info`, `warning` and `danger` on rows (first
    # body) and on single cells (second body).
    def contextual
      render_with_template
    end

    # @label Responsive table
    #
    # Below 768px the table scrolls sideways inside a bordered box.
    def responsive
      render_with_template
    end

    # @label Table grid
    #
    # `gridify: true` stacks every cell on its own line and hides the
    # headings.
    def gridify
      render_with_template
    end

    # @label Tables in panels
    #
    # A table in a panel's body (GCWeb's example), and a full-width table
    # straight in the panel (`body: false`).
    def in_panels
      render_with_template
    end
  end
end
