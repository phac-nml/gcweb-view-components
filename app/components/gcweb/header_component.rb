require "base64"

module Gcweb
  # Page header (GCWeb sites/header): the skip links, then the banner with
  # the language toggle, the Government of Canada signature and an
  # optional site search, then optional breadcrumbs, and an optional
  # application bar under the header (GCWeb's Application template).
  #
  # A Canada.ca page:
  #
  #   <%= render Gcweb::HeaderComponent.new(language_href: "/fr/sante") do |header| %>
  #     <% header.with_search %>
  #     <% header.with_breadcrumbs do |breadcrumbs| %>
  #       <% breadcrumbs.with_item("Health", "https://www.canada.ca/en/services/health.html") %>
  #     <% end %>
  #   <% end %>
  #
  # A signed-in application (no search or breadcrumbs, an application bar):
  #
  #   <%= render Gcweb::HeaderComponent.new(language_href: url_for(locale: :fr)) do |header| %>
  #     <% header.with_application_bar("Lab results portal", href: root_path) %>
  #   <% end %>
  #
  # Render it first in <body>, before <main>. The skip link goes to
  # `#wb-cont`, the id GCWeb puts on the page's <h1>. The language and
  # signature follow I18n.locale. With a search and no application bar, the
  # banner gets GCWeb's dark rule underneath (the theme menu, a later
  # component, sits under it).
  class HeaderComponent < ViewComponent::Base
    CANADA_CA = { en: "https://www.canada.ca/en.html", fr: "https://www.canada.ca/fr.html" }.freeze
    SEARCH_ACTION = { en: "https://www.canada.ca/en/sr/srb.html", fr: "https://www.canada.ca/fr/sr/srb.html" }.freeze

    # GCWeb's signatures (assets/sig-blk-{en,fr}.svg), inlined as data: URIs
    # so host apps don't have to serve them. A content security policy
    # needs `img-src data:` for these (Rails' default policy has it);
    # otherwise pass signature_src: with the copies in
    # app/assets/images/gcweb_view_components.
    SIGNATURES = %i[en fr].to_h do |language|
      svg = File.read(File.expand_path("../../assets/images/gcweb_view_components/sig-blk-#{language}.svg", __dir__))
      [ language, "data:image/svg+xml;base64,#{Base64.strict_encode64(svg.gsub(/>\s+</, '><').strip)}" ]
    end.freeze

    # The site search form (#wb-srch). Searches Canada.ca unless given an
    # action and labels for the app's own search.
    class SearchComponent < ViewComponent::Base
      # @param action [String, nil] where the form goes; defaults to Canada.ca search
      # @param label [String, nil] the field's (hidden) label and placeholder; defaults to "Search Canada.ca"
      # @param name [String] the query parameter
      # @param value [String, nil] the current query
      def initialize(action: nil, label: nil, name: "q", value: nil)
        @action = action
        @label = label
        @name = name
        @value = value
      end

      def call
        tag.section(id: "wb-srch", class: "col-lg-offset-4 col-md-offset-4 col-sm-offset-2 col-xs-12 col-sm-5 col-md-4") do
          safe_join([ tag.h2(t("gcweb.header.search")), form ])
        end
      end

      private

      def language = I18n.locale.to_s.start_with?("fr") ? :fr : :en

      def label = @label || t("gcweb.header.search_canada_ca")

      def form
        tag.form(action: @action || SEARCH_ACTION.fetch(language), method: "get", name: "cse-search-box", role: "search") do
          safe_join([
            tag.div(class: "form-group wb-srch-qry") do
              safe_join([
                tag.label(label, for: "wb-srch-q", class: "wb-inv"),
                tag.input(id: "wb-srch-q", class: "wb-srch-q form-control", name: @name, type: "search", value: @value,
                          size: 34, maxlength: 170, placeholder: label)
              ])
            end,
            tag.div(class: "form-group submit") do
              tag.button(type: "submit", id: "wb-srch-sub", class: "btn btn-primary btn-small") do
                safe_join([ tag.span(class: "glyphicon-search glyphicon"), tag.span(t("gcweb.header.search"), class: "wb-inv") ])
              end
            end
          ])
        end
      end
    end

    # The application bar (templates/application): the application's name,
    # linking to its home, in a dark band under the header.
    class ApplicationBarComponent < ViewComponent::Base
      # @param title [String] the application's name
      # @param href [String] the application's home
      def initialize(title, href:)
        @title = title.to_s
        raise ArgumentError, "the application bar needs a title" if @title.empty?

        @href = href
      end

      def call
        tag.section(class: "application-bar") do
          tag.div(tag.h2(link_to(@title, @href)), class: "container")
        end
      end
    end

    # The site search, in the banner.
    renders_one :search, SearchComponent

    # The breadcrumb trail, under the banner.
    renders_one :breadcrumbs, BreadcrumbsComponent

    # The application bar, after the header.
    renders_one :application_bar, ApplicationBarComponent

    # @param language_href [String, nil] the page in the other language; nil hides the language toggle
    # @param home_href [String, nil] where the signature links; defaults to Canada.ca
    # @param skip_to_about [Boolean] add the "Skip to About this site" link (to the footer's #wb-info)
    # @param signature_src [String, nil] the signature image's URL, in the page's language; defaults to the inlined SVG
    # @param html_attributes [Hash] extra attributes for the <header>
    def initialize(language_href: nil, home_href: nil, skip_to_about: false, signature_src: nil, **html_attributes)
      @language_href = language_href
      @home_href = home_href
      @signature_src = signature_src
      @skip_to_about = skip_to_about
      @html_attributes = html_attributes
    end

    def language = I18n.locale.to_s.start_with?("fr") ? :fr : :en

    def other_language = language == :fr ? :en : :fr

    def home_href = @home_href || CANADA_CA.fetch(language)

    def signature_src = @signature_src || SIGNATURES.fetch(language)

    def language_href = @language_href

    def skip_to_about? = @skip_to_about

    # GCWeb's dark rule under the banner, on Canada.ca pages (with a
    # search). An application bar takes its place.
    def rule? = search? && !application_bar?

    # The other language's name and code, in that language (GCWeb doesn't
    # translate these).
    def other_language_name = other_language == :fr ? "Français" : "English"

    def government_of_canada(lang) = lang == :fr ? "Gouvernement du Canada" : "Government of Canada"

    def html_attributes = @html_attributes
  end
end
