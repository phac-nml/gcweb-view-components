require "test_helper"

module Gcweb
  class AccordionComponentTest < ComponentTestCase
    def render_accordion(**options)
      render_inline(AccordionComponent.new(id: "faq", **options)) do |accordion|
        accordion.with_section(title: "One") { "First" }
        accordion.with_section(title: "Two", open: true) { "Second" }
        accordion.with_section(title: "Three", open: true) { "Third" }
      end
    end

    test "renders GCWeb's accordion markup for the gcweb--toggle controller" do
      render_accordion

      assert_selector "div.accordion#faq > details.acc-group[name='faq-grp']", count: 3
      assert_selector "details.acc-group > summary.wb-toggle.tgl-tab#faq-1[data-controller='gcweb--toggle'] + div.tgl-panel", text: "First", visible: :all
      toggle = JSON.parse(page.find("#faq-1")["data-toggle"])
      assert_equal({ "parent" => "#faq", "group" => ".acc-group" }, toggle)
    end

    test "opens only the first section marked open" do
      render_accordion

      assert_selector "details[open]", count: 1
      assert_selector "details[open] > summary#faq-2"
    end

    test "persist is passed to the toggle" do
      render_accordion(persist: :session)

      assert_equal "session", JSON.parse(page.find("#faq-1")["data-toggle"])["persist"]
    end

    test "keeps caller attributes" do
      render_accordion(class: "mrgn-bttm-lg", data: { testid: "faq" })

      assert_selector "div#faq.accordion.mrgn-bttm-lg[data-testid='faq']"
    end

    test "checks its options" do
      assert_raises(ArgumentError) { AccordionComponent.new(id: "") }
      assert_raises(ArgumentError) { AccordionComponent.new(id: "faq", persist: :forever) }
    end

    test "renders nothing without sections" do
      render_inline(AccordionComponent.new(id: "faq"))

      assert_no_selector "div"
    end
  end
end
