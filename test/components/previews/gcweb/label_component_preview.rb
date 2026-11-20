module Gcweb
  # @label Label
  #
  # Highlights a short piece of text-based (not numeric) information next
  # to other text. For numbers, such as unread items, use a badge.
  #
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/components/labels/labels-en.html
  # - WET style guide: https://wet-boew.github.io/wet-boew-styleguide/design/labels-en
  class LabelComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param variant select { choices: [default, primary, success, info, warning, danger] }
    # @param text text
    # @param link toggle "Make the label a link"
    def playground(variant: :default, text: "(Label info)", link: false)
      render_with_template(locals: { variant: variant.to_sym, text: text, link: link })
    end

    # @label Labels with text
    #
    # GCWeb's example: each variant after some text, and a label as a link.
    def default
      render_with_template
    end
  end
end
