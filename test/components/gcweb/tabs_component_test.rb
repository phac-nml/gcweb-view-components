require "test_helper"

module Gcweb
  class TabsComponentTest < ComponentTestCase
    def render_tabs(**options, &block)
      render_inline(TabsComponent.new(**options)) do |tabs|
        block ? block.call(tabs) : default_panels(tabs)
      end
    end

    def default_panels(tabs)
      tabs.with_panel(id: "panel1", title: "Example 1") { "One" }
      tabs.with_panel(id: "panel2", title: "Example 2") { "Two" }
    end

    test "renders the markup GCWeb authors write, for the gcweb--tabs controller" do
      render_tabs

      assert_selector "div.wb-tabs#panel1-tabs[data-controller='gcweb--tabs'] > div.tabpanels > details", count: 2
      assert_selector "details#panel1 > summary + div.tgl-panel", text: "One"
      assert_selector "details#panel1 > summary", text: "Example 1"
      assert_no_selector "ul"
    end

    test "opens the first panel unless another is marked open" do
      render_tabs
      assert_selector "details[open]", count: 1
      assert_selector "details#panel1[open]"

      render_tabs do |tabs|
        tabs.with_panel(id: "a", title: "A") { "A" }
        tabs.with_panel(id: "b", title: "B", open: true) { "B" }
        tabs.with_panel(id: "c", title: "C", open: true) { "C" }
      end
      assert_selector "details[open]", count: 1
      assert_selector "details#b[open]"
    end

    test "keeps markup in an html_safe title" do
      render_tabs do |tabs|
        tabs.with_panel(id: "p3", title: "Example 3<br>(line 2)".html_safe) { "Three" }
        tabs.with_panel(id: "p4", title: "<b>escaped</b>") { "Four" }
      end

      assert_selector "details#p3 > summary br"
      assert_no_selector "details#p4 > summary b"
      assert_selector "details#p4 > summary", text: "<b>escaped</b>"
    end

    test "ignore_session and update_hash become wb-tabs classes" do
      render_tabs(ignore_session: true, update_hash: true)

      assert_selector "div.wb-tabs.ignore-session.update-hash"
    end

    test "uses a given id and keeps caller attributes and controllers" do
      render_tabs(id: "news", class: "mrgn-bttm-lg", data: { controller: "tracking", testid: "tabs" })

      assert_selector "div#news.wb-tabs.mrgn-bttm-lg[data-controller='tracking gcweb--tabs'][data-testid='tabs']"
    end

    test "renders nothing without panels" do
      render_inline(TabsComponent.new)

      assert_no_selector "div"
    end

    test "panels need an id" do
      assert_raises(ArgumentError) { TabsComponent::PanelComponent.new(id: "", title: "A") }
    end
  end
end
