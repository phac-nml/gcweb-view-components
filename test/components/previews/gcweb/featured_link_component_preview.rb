module Gcweb
  class FeaturedLinkComponentPreview < ViewComponent::Preview
    def en
      I18n.with_locale(:en) { render_with_template }
    end

    def fr
      I18n.with_locale(:fr) { render_with_template }
    end
  end
end
