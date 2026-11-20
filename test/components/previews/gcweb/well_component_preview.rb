module Gcweb
  # @label Well
  #
  # A grey, inset box that sets content apart (Bootstrap's well, as GCWeb
  # styles it), in three paddings, and GCWeb's bold variant.
  #
  # GCWeb has no well demo page; GCWeb's own components use wells, for
  # example service information (gc-srvinfo).
  class WellComponentPreview < ViewComponent::Preview
    # @label Playground
    # @param size select { choices: ["", sm, lg] }
    # @param bold toggle "Bold text (well-bold)"
    def playground(size: "", bold: false)
      render_with_template(locals: { size: size.presence&.to_sym, bold: bold })
    end

    # @label Sizes and bold
    #
    # Small, normal and large wells, and a bold well (`<strong>` text is set
    # back to normal weight).
    def default
      render_with_template
    end
  end
end
