module Gcweb
  module Form
    # A GCWeb fieldset: a group of fields under a legend.
    #
    # A section of a form, as in GCWeb's complex structure form:
    #
    #   <fieldset>
    #     <legend><h2>Contact Address</h2></legend>
    #     … form groups …
    #   </fieldset>
    #
    #   <%= render Gcweb::Form::FieldsetComponent.new(legend: "Contact Address", heading: :h2) do %>
    #     …
    #   <% end %>
    #
    # Or one answer split over several fields (a date as year, month and
    # day), with the required marker and error on the group:
    #
    #   <fieldset>
    #     <legend class="required">
    #       <span class="field-name">Date of birth</span>
    #       <strong class="required">(required)</strong>
    #       <strong id="date_of_birth-error" class="error">…</strong>
    #     </legend>
    #     …
    #   </fieldset>
    #
    # The group markup is the legend wb-frmvld renders for a checkbox or
    # radio group on GCWeb v20.0.1. The legend is the group's accessible
    # name, so the error is read when focus enters any of its fields. With
    # an error the legend also gets the group's id, which the error summary
    # links to (wb-frmvld links group errors to the legend the same way).
    # Without required, hint or error the legend is plain text, as in GCWeb.
    #
    # Inside a form, prefer the builder: `f.fieldset_group :date_of_birth do … end`.
    class FieldsetComponent < FieldComponent
      HEADINGS = %i[h2 h3 h4 h5 h6].freeze
      BORDERS = %i[top bottom].freeze

      # @param legend [String] the legend text (or pass label:, as the builder does)
      # @param heading [Symbol, nil] wrap the legend text in a heading (:h2..:h6)
      # @param border [Symbol] :top (GCWeb's default rule above the fieldset)
      #   or :bottom (fieldset.legend-brdr-bttm, a rule under the legend)
      # @param name [String, nil] the group's name; its id is the error's id
      #   prefix, so an error needs a name or id
      # @see FieldComponent#initialize for required, hint, error and
      #   error_number. Other keyword options become fieldset attributes.
      def initialize(legend: nil, heading: nil, border: :top, name: nil, **options)
        @heading = heading&.to_sym
        @border = border.to_sym
        raise ArgumentError, "heading must be one of #{HEADINGS.join(", ")}" if @heading && !HEADINGS.include?(@heading)
        raise ArgumentError, "border must be one of #{BORDERS.join(", ")}" unless BORDERS.include?(@border)

        super(name: name.to_s, label: options.delete(:label) || legend, **options)
        raise ArgumentError, "an error needs a name or id for its element id" if error? && id.blank?
      end

      def call
        tag.fieldset(**fieldset_attributes) do
          safe_join([ tag.legend(legend_content, **legend_attributes), content ].compact)
        end
      end

      private

      # A fieldset has no control of its own to carry the required
      # attribute, so the "(required)" text is left for screen readers.
      def required_attribute? = false

      def legend_content
        text = plain_legend? ? label : label_content
        @heading ? content_tag(@heading, text) : text
      end

      def plain_legend? = !required? && hint.nil? && !error?

      def legend_attributes
        { id: (id if error?), class: class_names(required: required?).presence }.compact
      end

      def fieldset_attributes
        html = @group_html.merge(@control_attributes)
        classes = class_names({ "legend-brdr-bttm" => @border == :bottom }, @group_html[:class], @control_attributes[:class])
        html.merge(class: classes.presence).compact
      end
    end
  end
end
