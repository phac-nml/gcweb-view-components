module Gcweb
  # @label Button
  #
  # GCWeb buttons: Bootstrap 3 `.btn` with GCWeb's outset border, Lato
  # text and 36px minimum target. Give an `href` to render a link styled as
  # a button. Use the toolbar's **lang** option to switch between English
  # and French.
  #
  # A button acts on the current page; a link takes the user somewhere.
  # Don't put `role="button"` on a link.
  #
  # - GCWeb documentation: https://wet-boew.github.io/GCWeb/common/button/button-en.html
  class ButtonComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param label text
    # @param variant select { choices: [default, primary, success, info, warning, danger, link, call_to_action] }
    # @param size select { choices: ["", xs, sm, lg] }
    # @param block toggle
    # @param active toggle
    # @param disabled toggle
    # @param as_link toggle "Render a link (href) instead of a button"
    def playground(label: "Button", variant: :default, size: "", block: false, active: false, disabled: false, as_link: false)
      render Gcweb::ButtonComponent.new(
        variant: variant,
        size: size.presence,
        block: block,
        active: active,
        disabled: disabled,
        href: (as_link ? "#" : nil)
      ).with_content(label)
    end

    # @label Basic use (default)
    #
    # `btn btn-default` on a `<button>`, on `<input>` buttons and on a link.
    def default
      render_with_template
    end

    # @label Colours/Styles
    #
    # Colours signal meaning (a warning button links to warning
    # information), so the button text should say it too.
    def colours
      render_with_template(locals: { variants: %i[default primary success info warning danger link] })
    end

    # @label Supertask (call to action)
    #
    # `variant: :call_to_action`: the green button for a page's main task.
    # Use at most one per page.
    def call_to_action
      render Gcweb::ButtonComponent.new(variant: :call_to_action).with_content(I18n.t("previews.button.call_to_action"))
    end

    # @label Sizing
    def sizing
      render_with_template
    end

    # @label Full width
    #
    # `block: true` spans the parent's width.
    def full_width
      render Gcweb::ButtonComponent.new(block: true).with_content(I18n.t("previews.button.block"))
    end

    # @label Active and disabled states
    #
    # `active: true` always shows the pressed state. `disabled: true` sets
    # the `disabled` attribute on a button; on a link it adds `.disabled`
    # (no pointer events) and `aria-disabled="true"`.
    def states
      render_with_template
    end
  end
end
