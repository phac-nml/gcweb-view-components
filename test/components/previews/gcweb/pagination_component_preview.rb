module Gcweb
  # @label Pagination
  #
  # Links to the previous page, numbered pages and the next page, for lists
  # and search results. Data tables have their own (see Data table, Paged).
  # Give it a Pagy object (`pagy:`), or `page:`, `pages:` and `url:` as here.
  #
  # - GCWeb search results pagination: https://wet-boew.github.io/GCWeb/templates/search/test-pagination.html
  class PaginationComponentPreview < ViewComponent::Preview
    TEMPLATE = "gcweb/pagination_component_preview/pagination".freeze

    # @label Playground
    # @param page number
    # @param pages number
    def playground(page: 2, pages: 12)
      render_with_template(template: TEMPLATE, locals: { page: page.to_i, pages: pages.to_i })
    end

    # @label First page
    def first_page
      render_with_template(template: TEMPLATE, locals: { page: 1, pages: 12 })
    end

    # @label Second page
    def second_page
      render_with_template(template: TEMPLATE, locals: { page: 2, pages: 12 })
    end

    # @label Middle page
    #
    # The first and last pages, and those around the current one.
    def middle_page
      render_with_template(template: TEMPLATE, locals: { page: 6, pages: 12 })
    end

    # @label Last page
    def last_page
      render_with_template(template: TEMPLATE, locals: { page: 12, pages: 12 })
    end
  end
end
