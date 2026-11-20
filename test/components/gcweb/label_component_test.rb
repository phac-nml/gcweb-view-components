require "test_helper"

module Gcweb
  class LabelComponentTest < ComponentTestCase
    test "renders GCWeb's label markup for each variant" do
      LabelComponent::VARIANTS.each do |variant|
        render_inline(LabelComponent.new(variant: variant).with_content("(Label info)"))

        assert_selector "span.label.label-#{variant}", text: "(Label info)"
      end
    end

    test "defaults to the default variant" do
      render_inline(LabelComponent.new.with_content("Info"))

      assert_selector "span.label.label-default"
    end

    test "href makes it a link" do
      render_inline(LabelComponent.new(variant: :primary, href: "/updates").with_content("New"))

      assert_selector "a.label.label-primary[href='/updates']", text: "New"
    end

    test "keeps extra attributes and classes" do
      render_inline(LabelComponent.new(class: "mrgn-lft-sm", id: "status").with_content("Info"))

      assert_selector "span#status.label.label-default.mrgn-lft-sm"
    end

    test "rejects unknown variants" do
      assert_raises(ArgumentError) { LabelComponent.new(variant: :purple) }
    end
  end
end
