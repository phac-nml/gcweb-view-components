require "test_helper"

module Gcweb
  class WellComponentTest < ComponentTestCase
    test "renders a well" do
      render_inline(WellComponent.new) { "Content" }

      assert_selector "div.well", exact_text: "Content"
      assert_equal "well", page.find("div")[:class]
    end

    test "sizes and bold" do
      render_inline(WellComponent.new(size: :lg, bold: true, class: "mrgn-tp-lg")) { "Content" }

      assert_equal %w[well well-lg well-bold mrgn-tp-lg], page.find("div")[:class].split
    end

    test "rejects unknown sizes" do
      assert_raises(ArgumentError) { WellComponent.new(size: :xl) }
    end
  end
end
