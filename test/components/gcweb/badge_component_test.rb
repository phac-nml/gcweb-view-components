require "test_helper"

module Gcweb
  class BadgeComponentTest < ComponentTestCase
    test "renders the number with its description for screen readers" do
      render_inline(BadgeComponent.new(description: "unread emails").with_content("42"))

      assert_selector "span.badge", text: "42 unread emails"
      assert_equal " unread emails", page.find("span.badge > span.wb-inv").text(normalize_ws: false)
    end

    test "without a description it's just the number" do
      render_inline(BadgeComponent.new.with_content("7"))

      assert_selector "span.badge", exact_text: "7"
      assert_no_selector ".wb-inv"
    end

    test "without content it renders empty, so GCWeb's styles hide it" do
      render_inline(BadgeComponent.new(description: "unread emails"))

      assert_equal "", page.find("span.badge", visible: :all).native.inner_html
    end

    test "href makes it a link" do
      render_inline(BadgeComponent.new(href: "/inbox").with_content("3"))

      assert_selector "a.badge[href='/inbox']", text: "3"
    end

    test "keeps extra attributes and classes" do
      render_inline(BadgeComponent.new(class: "pull-right", data: { count: 3 }).with_content("3"))

      assert_selector "span.badge.pull-right[data-count='3']"
    end
  end
end
