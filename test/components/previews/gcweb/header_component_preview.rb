module Gcweb
  # @label Header
  #
  # The page header: skip links, the banner with the language toggle, the
  # Government of Canada signature and an optional site search, then
  # optional breadcrumbs, and an optional application bar for signed-in
  # applications (GCWeb's Application template). The language and the
  # signature follow the page's locale (use the EN/FR toggle).
  #
  # Press Tab on a preview to see the skip link. Not shown yet: the theme
  # and topic menu (gcweb-menu) and the sign-in button, which come in
  # later page-shell components (#52).
  #
  # - GCWeb header: https://wet-boew.github.io/GCWeb/sites/header/header-docs-en.html
  # - GCWeb Application template: https://wet-boew.github.io/GCWeb/templates/application/application-docs-en.html
  # - Canada.ca global header: https://design.canada.ca/common-design-patterns/global-header.html
  class HeaderComponentPreview < ViewComponent::Preview
    layout "component_preview_page"

    # @label Playground
    # @param language_toggle toggle
    # @param search toggle
    # @param breadcrumbs toggle
    # @param application_bar toggle
    def playground(language_toggle: true, search: true, breadcrumbs: true, application_bar: false)
      render_with_template(locals: { language_toggle: language_toggle, search: search, breadcrumbs: breadcrumbs, application_bar: application_bar })
    end

    # @label Canada.ca page
    #
    # Language toggle, Canada.ca search and breadcrumbs, as on a Canada.ca
    # content page.
    def canada_ca
      render_with_template
    end

    # @label Application
    #
    # GCWeb's Application template: no search or breadcrumbs, and the
    # application's name in a bar under the header.
    def application
      render_with_template
    end

    # @label Application with its own search
    #
    # A search form that goes to the application's own search page.
    def application_search
      render_with_template
    end
  end
end
