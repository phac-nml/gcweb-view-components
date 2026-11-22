require "test_helper"

module Gcweb
  class HeaderComponentTest < ComponentTestCase
    test "the skip link, banner and signature" do
      render_inline(HeaderComponent.new)

      assert_selector "nav > ul#wb-tphp > li.wb-slc > a.wb-sl[href='#wb-cont']", text: "Skip to main content", visible: :all
      assert_no_selector "a[href='#wb-info']", visible: :all
      assert_selector "header > #wb-bnr.container > .row > .brand.col-xs-9.col-sm-5.col-md-4[property=publisher]"
      assert_selector ".brand > a[href='https://www.canada.ca/en.html'] > img[alt='Government of Canada'][src^='data:image/svg+xml;base64,']"
      assert_selector ".brand .wb-inv > span[lang=fr]", text: "Gouvernement du Canada", visible: :all
      assert_no_selector "#wb-lng"
      assert_no_selector "#wb-srch"
      assert_no_selector "hr"
    end

    test "the signature is GCWeb's, in the page's language" do
      render_inline(HeaderComponent.new)
      english = page.find(".brand img")[:src]
      I18n.with_locale(:fr) { render_inline(HeaderComponent.new) }

      assert_selector ".brand img[alt='Gouvernement du Canada']"
      assert_not_equal english, page.find(".brand img")[:src]
      assert_includes Base64.decode64(english.split(",").last), "Symbol of the Government of Canada"
    end

    test "signature_src replaces the inlined signature" do
      render_inline(HeaderComponent.new(signature_src: "/assets/gcweb_view_components/sig-blk-en.svg"))

      assert_selector ".brand img[src='/assets/gcweb_view_components/sig-blk-en.svg'][alt='Government of Canada']"
    end

    test "the language toggle links to the other language" do
      render_inline(HeaderComponent.new(language_href: "/fr/page"))

      assert_selector "#wb-lng.col-xs-3.col-sm-12.pull-right.text-right > h2.wb-inv", text: "Language selection", visible: :all
      assert_selector "#wb-lng a[lang=fr][hreflang=fr][href='/fr/page'] > span.hidden-xs[translate=no]", text: "Français"
      assert_selector "#wb-lng abbr.visible-xs.h3[title='Français']", text: "fr", visible: :all

      I18n.with_locale(:fr) { render_inline(HeaderComponent.new(language_href: "/en/page")) }
      assert_selector "#wb-lng a[lang=en][href='/en/page'] > span", text: "English"
      assert_selector "a.wb-sl", text: "Passer au contenu principal", visible: :all
    end

    test "Canada.ca search, with the rule under the banner" do
      render_inline(HeaderComponent.new) { |header| header.with_search }

      assert_selector "#wb-bnr > .row > section#wb-srch > form[action='https://www.canada.ca/en/sr/srb.html'][method=get][role=search]"
      assert_selector "#wb-srch label.wb-inv[for=wb-srch-q]", text: "Search Canada.ca", visible: :all
      assert_selector "input#wb-srch-q.form-control[type=search][name=q][placeholder='Search Canada.ca']"
      assert_selector "button#wb-srch-sub.btn.btn-primary > span.glyphicon-search"
      assert_selector "#wb-bnr + hr", visible: :all
    end

    test "the application's own search" do
      render_inline(HeaderComponent.new) { |header| header.with_search(action: "/search", label: "Search the portal", name: "query", value: "flu") }

      assert_selector "form[action='/search'] input[name=query][value=flu][placeholder='Search the portal']"
    end

    test "an application bar replaces the rule under the banner" do
      render_inline(HeaderComponent.new) do |header|
        header.with_search
        header.with_application_bar("Lab results portal", href: "/")
      end

      assert_no_selector "hr", visible: :all
      assert_selector "section.application-bar"
    end

    test "breadcrumbs go in the header, the application bar after it" do
      render_inline(HeaderComponent.new) do |header|
        header.with_breadcrumbs { |trail| trail.with_item("Health", "/health") }
        header.with_application_bar("Lab results portal", href: "/")
      end

      assert_selector "header > nav#wb-bc li", count: 2
      assert_selector "header + section.application-bar > .container > h2 > a[href='/']", text: "Lab results portal"
    end

    test "skip_to_about, home_href and header attributes" do
      render_inline(HeaderComponent.new(skip_to_about: true, home_href: "/", class: "custom"))

      assert_selector "li.wb-slc.visible-sm a[href='#wb-info']", text: "Skip to About this site", visible: :all
      assert_selector "header.custom .brand a[href='/']"
    end

    test "the application bar needs a title" do
      assert_raises(ArgumentError) { HeaderComponent::ApplicationBarComponent.new("", href: "/") }
    end
  end
end
