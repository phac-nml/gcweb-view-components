module Gcweb
  module Form
    # The error summary wet-boew's form validation (wb-frmvld) puts at the
    # top of a form on GCWeb v20.0.1 when a submit fails:
    #
    #   <section id="errors-default" class="alert alert-danger" tabindex="-1">
    #     <h2>The form could not be submitted because 2 errors were found.</h2>
    #     <ul>
    #       <li><a href="#first_name"><span class="prefix">Error&nbsp;1: </span>First Name - This field is required.</a></li>
    #       …
    #     </ul>
    #   </section>
    #
    # `gcweb_form_with` adds one for you, listing the errors its fields
    # rendered. Use the component directly for forms built another way:
    #
    #   <%= render Gcweb::Form::ErrorSummaryComponent.new(errors: [
    #     { number: 1, target: "first_name", label: "First Name", message: "This field is required." }
    #   ]) %>
    #
    # wb-frmvld moves focus to the summary. After a server round trip the
    # `autofocus` attribute does the same (Turbo also honours it), so screen
    # reader users hear how many errors there are first.
    class ErrorSummaryComponent < ViewComponent::Base
      HEADING_LEVELS = (2..6)

      # One entry. target is the id the link points to (nil for an error with
      # no field, which is listed without a link as wb-frmvld does).
      Error = Data.define(:number, :target, :label, :message)

      attr_reader :id, :errors

      # @param errors [Array<Hash, Error>] number:, target:, label: and message:
      # @param id [String] "errors-" plus the form's id, as wb-frmvld names it
      # @param heading_level [Integer] 2 (wb-frmvld's default hdLvl) to 6
      # @param autofocus [Boolean] focus the summary when the page loads
      def initialize(errors:, id: "errors-default", heading_level: 2, autofocus: true)
        @errors = errors.map { |error| error.is_a?(Error) ? error : Error.new(**error.to_h.slice(:number, :target, :label, :message)) }
        @id = id
        @heading_level = Integer(heading_level)
        @autofocus = autofocus
        raise ArgumentError, "heading_level must be 2 to 6" unless HEADING_LEVELS.cover?(@heading_level)
      end

      def render? = errors.any?

      def call
        tag.section(id: id, class: "alert alert-danger", tabindex: "-1", autofocus: @autofocus || nil) do
          safe_join([
            content_tag(:"h#{@heading_level}", t("gcweb.form.error_summary.heading", count: errors.size)),
            tag.ul(safe_join(errors.map { |error| tag.li(link(error)) }))
          ])
        end
      end

      private

      def link(error)
        text = safe_join([
          tag.span(t("gcweb.form.error_prefix_numbered", number: error.number), class: "prefix"),
          [ error.label.presence, error.message ].compact.join(t("gcweb.form.error_summary.separator"))
        ])

        tag.a(text, href: (error.target.presence && "##{error.target}"))
      end
    end
  end
end
