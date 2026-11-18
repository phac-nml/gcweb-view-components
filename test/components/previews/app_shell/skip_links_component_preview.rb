module AppShell
  class SkipLinksComponentPreview < ViewComponent::Preview
    def en
      I18n.with_locale(:en) { render(AppShell::SkipLinksComponent.new) }
    end

    def fr
      I18n.with_locale(:fr) { render(AppShell::SkipLinksComponent.new) }
    end
  end
end
