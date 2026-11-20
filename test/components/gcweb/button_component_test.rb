require "test_helper"

module Gcweb
  class ButtonComponentTest < ComponentTestCase
    test "renders a default GCWeb button" do
      render_inline(ButtonComponent.new.with_content("Button"))

      assert_selector "button.btn.btn-default[type='button']", text: "Button"
      assert_no_selector "button[disabled]"
    end

    test "supports every GCWeb variant" do
      ButtonComponent::VARIANTS.each do |variant|
        render_inline(ButtonComponent.new(variant: variant).with_content("x"))
        assert_selector "button.btn.btn-#{variant.to_s.dasherize}"
      end
    end

    test "sizes, block and active add GCWeb's classes" do
      render_inline(ButtonComponent.new(variant: :primary, size: :lg, block: true, active: true, type: :submit).with_content("Go"))

      assert_selector "button.btn.btn-primary.btn-lg.btn-block.active[type='submit']", text: "Go"
    end

    test "disabled buttons get the disabled attribute" do
      render_inline(ButtonComponent.new(disabled: true).with_content("No"))

      assert_selector "button.btn[disabled]:not(.disabled)"
    end

    test "renders a link styled as a button when given an href" do
      render_inline(ButtonComponent.new(href: "/apply", variant: :call_to_action).with_content("Apply"))

      assert_selector "a.btn.btn-call-to-action[href='/apply']:not([type])", text: "Apply"
      assert_no_selector "button"
    end

    test "disabled links get .disabled and aria-disabled" do
      render_inline(ButtonComponent.new(href: "#", disabled: true).with_content("Link"))

      assert_selector "a.btn.btn-default.disabled[aria-disabled='true']:not([disabled])"
    end

    test "passes extra HTML attributes through and appends classes" do
      render_inline(ButtonComponent.new(id: "save", class: "mrgn-tp-lg", data: { action: "x#y" }).with_content("Save"))

      assert_selector "button#save.btn.btn-default.mrgn-tp-lg[data-action='x#y']"
    end

    test "rejects unknown variants, sizes and types" do
      assert_raises(ArgumentError) { ButtonComponent.new(variant: :secondary) }
      assert_raises(ArgumentError) { ButtonComponent.new(size: :xl) }
      assert_raises(ArgumentError) { ButtonComponent.new(type: :image) }
    end
  end
end
