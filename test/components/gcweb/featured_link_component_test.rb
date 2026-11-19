require "test_helper"

module Gcweb
  class FeaturedLinkComponentTest < ComponentTestCase
    test "renders GCWeb featured link markup" do
      render_inline(FeaturedLinkComponent.new(href: "/promo", link_text: "[Promotion title]"))

      assert_selector "section.gc-featured-link > div.container > h2.wb-inv", text: "Spotlight on"
      assert_selector "section.gc-featured-link p > a.stretched-link[href='/promo']", text: "[Promotion title]"
      assert_no_selector "section[data-bg-color]"
      assert_no_selector "section[data-controller]"
    end

    test "translates the default heading" do
      I18n.with_locale(:fr) do
        render_inline(FeaturedLinkComponent.new(href: "#", link_text: "[Titre]"))
      end

      assert_selector "h2.wb-inv", text: "Pleins feux sur"
    end

    test "renders the optional description" do
      render_inline(FeaturedLinkComponent.new(href: "#", link_text: "Link", description: "Long description"))

      assert_selector ".container > p", count: 2
      assert_selector ".container > p:last-child", text: "Long description"
    end

    test "custom background is a data attribute for the Stimulus controller, never an inline style" do
      render_inline(FeaturedLinkComponent.new(href: "#", link_text: "Link", background_color: "#005B61"))

      assert_selector "section.gc-featured-link[data-bg-color='#005B61'][data-controller='gcweb--featured-link']"
      assert_no_selector "[style]"
    end

    test "keeps caller data attributes and controllers" do
      render_inline(
        FeaturedLinkComponent.new(href: "#", link_text: "Link", background_color: "#99dade", data: { controller: "tracking", testid: "promo" })
      )

      assert_selector "section[data-controller='tracking gcweb--featured-link'][data-testid='promo']"
    end

    test "rejects colours GCWeb's script cannot use" do
      assert_raises(ArgumentError) { FeaturedLinkComponent.new(href: "#", link_text: "x", background_color: "red") }
      assert_raises(ArgumentError) { FeaturedLinkComponent.new(href: "#", link_text: "x", background_color: "#abc") }
    end
  end
end
