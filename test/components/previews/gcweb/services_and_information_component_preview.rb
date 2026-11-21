module Gcweb
  # @label Services and information
  #
  # Doormat links to the most important pages about a topic: a heading, then
  # a linked heading and a short description for each page, in columns, a
  # single column or a numbered list.
  #
  # GCWeb's demos keep the columns equal in height with the wb-eqht
  # JavaScript plugin; the gem uses wet-boew's CSS-only `.wb-eqht-grd`.
  # GCWeb's FieldFlow example isn't shown: the gem has no FieldFlow yet.
  #
  # - GCWeb working examples: https://wet-boew.github.io/GCWeb/components/gc-srvinfo/gc-srvinfo-en.html
  # - GCWeb documentation: https://wet-boew.github.io/GCWeb/components/gc-srvinfo/gc-srvinfo-doc-en.html
  class ServicesAndInformationComponentPreview < ViewComponent::Preview
    TEMPLATE = "gcweb/services_and_information_component_preview/items".freeze

    # @label Playground
    # @param layout select { choices: [three_columns, two_columns, single, sequential] }
    # @param count number
    # @param title text "Leave blank for the default heading"
    # @param hidden_title toggle "Screen readers only"
    # @param more_info toggle "Add the more information well"
    def playground(layout: :three_columns, count: 6, title: "", hidden_title: false, more_info: false)
      render_with_template(template: TEMPLATE, locals: { layout: layout.to_sym, count: count.to_i, title: title, hidden_title: hidden_title, more_info: more_info })
    end

    # @label Three columns
    #
    # Three columns on large screens, two on medium screens, one on small
    # screens (GCWeb's example 1).
    def three_columns
      render_with_template(template: TEMPLATE, locals: { layout: :three_columns, count: 6 })
    end

    # @label Two columns
    #
    # GCWeb's example 2.
    def two_columns
      render_with_template(template: TEMPLATE, locals: { layout: :two_columns, count: 4 })
    end

    # @label Single column
    #
    # GCWeb's example 3. GCWeb recommends it on pages with a limited content
    # width.
    def single_column
      render_with_template(template: TEMPLATE, locals: { layout: :single, count: 3 })
    end

    # @label Sequential
    #
    # A numbered list, for steps taken in order (GCWeb's example 4).
    def sequential
      render_with_template(template: TEMPLATE, locals: { layout: :sequential, count: 3 })
    end

    # @label Grouped with headings
    #
    # One component per group, each with its own heading (GCWeb's
    # example 5).
    def grouped
      render_with_template
    end

    # @label With labels
    #
    # A label after each link (GCWeb's "with labels" example).
    def with_labels
      render_with_template
    end

    # @label With more information
    #
    # A well after the links (GCWeb's "with more information" example).
    def more_information
      render_with_template(template: TEMPLATE, locals: { layout: :two_columns, count: 4, more_info: true })
    end
  end
end
