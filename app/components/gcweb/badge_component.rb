module Gcweb
  # Badge (GCWeb components/badges): a number that highlights new, updated
  # or unread items, usually inside a link or button.
  #
  #   <a href="/inbox">Inbox <%= render Gcweb::BadgeComponent.new(description: "unread emails").with_content("42") %></a>
  #
  # `description` is read by screen readers after the number. Without
  # content the badge renders empty, and GCWeb's styles hide it, so a count
  # of nothing needs no special case (pass `nil`, not 0).
  class BadgeComponent < ViewComponent::Base
    # @param description [String, nil] what the number counts, for screen readers only
    # @param href [String, nil] make the badge a link
    # @param html_attributes [Hash] extra attributes (class is appended)
    def initialize(description: nil, href: nil, **html_attributes)
      @description = description.presence
      @href = href
      @html_attributes = html_attributes
    end

    def call
      attributes = @html_attributes.merge(class: class_names("badge", @html_attributes[:class]))
      body = content.present? ? safe_join([ content, description_tag ].compact) : nil
      @href ? link_to(body, @href, **attributes) : tag.span(body, **attributes)
    end

    private

    def description_tag
      tag.span(" #{@description}", class: "wb-inv") if @description
    end
  end
end
